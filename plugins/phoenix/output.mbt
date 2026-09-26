// The phoenix site (upstream `Phoenix_output` and `Phoenix_root`).

///|
/// A JSON value printed like `Ezjsonm.to_string ~minify:false`.
priv enum Json {
  JString(String)
  JBool(Bool)
  JInt(Int)
  JArray(Array[Json])
  JObject(Array[(String, Json)])
}

///|
fn json_string(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      '\b' => buf.write_string("\\b")
      '\u{0c}' => buf.write_string("\\f")
      _ =>
        if c.to_int() < 0x20 || c.to_int() == 0x7f {
          let hex = c.to_int().to_string(radix=16).to_upper()
          buf.write_string("\\u" + String::make(4 - hex.length(), '0') + hex)
        } else {
          buf.write_char(c)
        }
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
fn Json::write(self : Json, buf : StringBuilder, indent : Int) -> Unit {
  let nl = (n : Int) => {
    buf.write_char('\n')
    buf.write_string(String::make(2 * n, ' '))
  }
  match self {
    JString(s) => buf.write_string(json_string(s))
    JBool(b) => buf.write_string(if b { "true" } else { "false" })
    JInt(n) => buf.write_string(n.to_string())
    JArray([]) => buf.write_string("[]")
    JArray(xs) => {
      buf.write_char('[')
      for i, x in xs {
        if i > 0 {
          buf.write_char(',')
        }
        nl(indent + 1)
        x.write(buf, indent + 1)
      }
      nl(indent)
      buf.write_char(']')
    }
    JObject([]) => buf.write_string("{}")
    JObject(fields) => {
      buf.write_char('{')
      for i, field in fields {
        if i > 0 {
          buf.write_char(',')
        }
        nl(indent + 1)
        buf.write_string(json_string(field.0) + ": ")
        field.1.write(buf, indent + 1)
      }
      nl(indent)
      buf.write_char('}')
    }
  }
}

///|
fn Json::to_string(self : Json) -> String {
  let buf = StringBuilder()
  self.write(buf, 0)
  buf.to_string()
}

///|
fn basename(path : String) -> String {
  let trimmed = path.trim_end(chars="/").to_owned()
  match trimmed.rev_find("/") {
    Some(i) => trimmed.unsafe_substring(start=i + 1, end=trimmed.length())
    None => if trimmed == "" && path != "" { "/" } else { trimmed }
  }
}

///|
/// The navigation index of the site (upstream `store_index`).
pub fn Env::index_json(
  self : Env,
  filename~ : String,
  root~ : String,
) -> String {
  let func = (
    children : Array[Json],
    parent : String?,
    is_func : Bool,
    id : String,
  ) => {
    let full_id = match parent {
      Some(p) => p + "*" + id
      None => id
    }
    JObject([
      ("text", JString(id)),
      ("id", JString(full_id)),
      ("expanded", JBool(false)),
      ("function", JBool(is_func)),
      if children.is_empty() {
        ("leaf", JBool(true))
      } else {
        ("children", JArray(children))
      },
    ])
  }
  let funcs = []
  for f in self.symtab.to_sequence() {
    let parent = f.name()
    let children = self
      .function_blocks(f)
      .map(blk => func([], Some(parent), false, self.block_name(blk.addr())))
    funcs.push(func(children, None, true, parent))
  }
  // upstream folds with `::`, which reverses the functions
  funcs.rev_in_place()
  let children = JObject([
    ("text", JString(filename)),
    ("id", JString(root)),
    ("expanded", JBool(true)),
    ("root", JBool(true)),
    ("children", JArray(funcs)),
  ])
  JObject([("text", JString(".")), ("children", JArray([children]))]).to_string()
}

///|
/// The list of functions with their address ranges (upstream
/// `store_functions`).
pub fn Env::functions_json(self : Env, filename~ : String) -> String {
  let functions = []
  let fns = self.symtab.to_sequence()
  for f in fns {
    let span = f.span()
    let entry = f.entry().memory()
    let min = match span.min_binding() {
      Some((mem, _)) => mem
      None => entry
    }
    let max = match span.max_binding() {
      Some((mem, _)) => mem
      None => entry
    }
    functions.push(
      JObject([
        ("name", JString(f.name())),
        ("startAddress", JString(min.min_addr().to_string(radix=16))),
        ("endAddress", JString(max.max_addr().to_string(radix=16))),
        ("hash", JString("0000000000000000000")),
      ]),
    )
  }
  functions.rev_in_place()
  JObject([
    (
      "binary",
      JObject([
        ("name", JString(filename)),
        ("functionNumber", JInt(fns.length())),
        ("functions", JArray(functions)),
      ]),
    ),
  ]).to_string()
}

///|
/// Renders all files of the site as `(path, contents)` pairs, where the
/// paths are relative to the site directory `root` (upstream
/// `Phoenix_output.store`): for every function the CFG (`cfg/<fn>.cfg`,
/// `sacfg/<fn>.sacfg`) and the BIL (`bil/<fn>.html`, `hil/<fn>.html`),
/// and the `<name>.json` index, the `<name>.functionlist`, and the
/// `<name>.html` assembly dump, where `name` defaults to the base name of
/// `root`.
pub fn Env::render(
  self : Env,
  filename~ : String,
  root~ : String,
  name? : String = basename(root),
) -> Array[(String, String)] {
  let files = []
  let cfg = self.cfg_to_dot()
  for f in self.symtab.to_sequence() {
    files.push(("cfg/\{f.name()}.cfg", cfg))
    files.push(("sacfg/\{f.name()}.sacfg", cfg))
    let bil = self.bil_page(f)
    files.push(("bil/\{f.name()}.html", bil))
    files.push(("hil/\{f.name()}.html", bil))
  }
  files.push(("\{name}.json", self.index_json(filename~, root~)))
  files.push(("\{name}.functionlist", self.functions_json(filename~)))
  files.push(("\{name}.html", self.dump_page()))
  files
}

///|
/// The file name shown by the site: the base name of the project file.
fn project_filename(project : @project.Project) -> String {
  match project.filename() {
    Some(name) => basename(name)
    None => "unknown"
  }
}

///|
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.unsafe_substring(start=0, end=i)
    None => "."
  }
}

///|
/// Stores the site on disk and returns its directory (upstream `store`).
/// As upstream (`Phoenix_root.create`), without an explicit `root` the
/// site is created in the current directory under the base name of the
/// output folder; with `root`, the site is created in `root` and the
/// index files are named after the output folder.
pub fn store(
  project : @project.Project,
  options? : Options = Options::new(),
  symtab? : @project.ProjectDisassemblySymtab,
  root? : String,
) -> Result[String, String] {
  let env = Env::new(project, options~, symtab?)
  let cwd = match getcwd() {
    Ok(d) => d
    Err(e) => return Err(e)
  }
  let name = basename(options.output_folder)
  let root = match root {
    Some(r) if r != cwd => r
    _ => cwd + "/" + name
  }
  match mkdir(root) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  for file in env.render(filename=project_filename(project), root~, name~) {
    let path = root + "/" + file.0
    match mkdir(dirname(path)) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
    match @native_io.write_file(path, @utf8.encode(file.1)) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(root)
}
