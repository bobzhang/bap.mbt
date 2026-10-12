// Generation of IDA Python scripts from BIR attributes (upstream
// `plugins/emit_ida_script/emit_ida_script_main.ml`).

///|
/// The IDA color code of a BIR color (IDA uses the BGR order).
pub fn idacode_of_color(color : @types.IrColor) -> Int32 {
  match color {
    IrBlack => 0x000000
    IrRed => 0xCCCCFF
    IrGreen => 0x99FF99
    IrYellow => 0xC2FFFF
    IrBlue => 0xFFB2B2
    IrMagenta => 0xFFB2FF
    IrCyan => 0xFFFFB2
    IrWhite => 0xFFFFFF
    IrGray => 0xEAEAEA
  }
}

///|
fn string_of_color(color : @types.IrColor) -> String {
  match color {
    IrBlack => "black"
    IrRed => "red"
    IrGreen => "green"
    IrYellow => "yellow"
    IrBlue => "blue"
    IrMagenta => "magenta"
    IrCyan => "cyan"
    IrWhite => "white"
    IrGray => "gray"
  }
}

///|
/// Emitted at the start of the script.
pub let prologue : String =
  #|
  #|from bap.utils import ida
  #|

///|
/// Emitted at the end of the script.
pub let epilogue : String =
  #|
  #|# eplogue code if needed
  #|

///|
/// Escapes `'`, `\`, and `$` with a backslash (upstream `Py.escape`).
fn py_escape(s : String) -> String {
  let buf = StringBuilder()
  for c in s {
    if c == '\'' || c == '\\' || c == '$' {
      buf.write_char('\\')
    }
    buf.write_char(c)
  }
  buf.to_string()
}

///|
fn hex6(n : Int32) -> String {
  let digits = n.to_string(radix=16)
  if digits.length() >= 6 {
    digits
  } else {
    String::make(6 - digits.length(), '0') + digits
  }
}

///|
/// The Python code for an attribute (upstream `Py.color`, `Py.foreground`,
/// `Py.background`, and `Py.comment`). The code refers to the `$addr` and
/// `$sub_name` substitutions.
pub fn python_of_attr(name : String, value : String) -> String {
  match (name, @types.IrColor::of_string(value)) {
    ("color", Some(c)) => "ida.set_color($addr, 0x\{hex6(idacode_of_color(c))})"
    ("foreground", Some(c)) =>
      "ida.comment.add($addr, 'foreground', '\{string_of_color(c)}')"
    ("background", Some(c)) =>
      "ida.comment.add($addr, 'background', '\{string_of_color(c)}')"
    _ => "ida.comment.add($addr, '\{py_escape(name)}', '\{py_escape(value)}')"
  }
}

///|
fn is_ident_char(c : Char) -> Bool {
  c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '_')
}

///|
/// Implements OCaml's `Buffer.add_substitute`: `$name`, `$(name)`, and
/// `${name}` are replaced by `f(name)`, and `\$` is a literal dollar.
pub fn add_substitute(
  buf : StringBuilder,
  f : (String) -> String,
  s : String,
) -> Unit {
  let chars = s.to_array()
  let lim = chars.length()
  let mut previous = ' '
  let mut i = 0
  while i < lim {
    let current = chars[i]
    if current == '$' && previous == '\\' {
      buf.write_char('$')
      previous = ' '
      i += 1
    } else if current == '$' {
      let j = i + 1
      if j >= lim {
        // upstream raises `Not_found`; keep the dollar
        buf.write_char('$')
        i += 1
        continue
      }
      let (ident, next) = match chars[j] {
        '(' | '{' as opening => {
          let closing = if opening == '(' { ')' } else { '}' }
          let mut depth = 0
          let mut k = j + 1
          while k < lim && !(chars[k] == closing && depth == 0) {
            if chars[k] == opening {
              depth += 1
            } else if chars[k] == closing {
              depth -= 1
            }
            k += 1
          }
          (String::from_array(chars[j + 1:k]), k + 1)
        }
        _ => {
          let mut k = j + 1
          while k < lim && is_ident_char(chars[k]) {
            k += 1
          }
          (String::from_array(chars[j:k]), k)
        }
      }
      buf.write_string(f(ident))
      previous = ' '
      i = next
    } else if previous == '\\' {
      buf.write_char('\\')
      buf.write_char(current)
      previous = ' '
      i += 1
    } else if current == '\\' {
      previous = current
      i += 1
    } else {
      buf.write_char(current)
      previous = current
      i += 1
    }
  }
  if previous == '\\' {
    buf.write_char('\\')
  }
}

///|
/// Prints an address like upstream `Word.pp_hex`.
fn addr_to_hex(addr : UInt64) -> String {
  let digits = addr.to_string(radix=16).to_upper()
  if addr >= 10UL {
    "0x" + digits
  } else {
    digits
  }
}

///|
/// Parses the textual value of an `address` attribute (`0x400000:64u`).
fn parse_address(text : String) -> UInt64? {
  let body = match text.find(":") {
    Some(i) => text.unsafe_substring(start=0, end=i)
    None => text
  }
  let (digits, radix) = if body.has_prefix("0x") || body.has_prefix("0X") {
    (body.unsafe_substring(start=2, end=body.length()), 16UL)
  } else {
    (body, 10UL)
  }
  guard digits.length() > 0 else { None }
  let mut n : UInt64 = 0
  for c in digits {
    let d = match c {
      '0'..<='9' => c.to_int() - '0'.to_int()
      'a'..<='f' => c.to_int() - 'a'.to_int() + 10
      'A'..<='F' => c.to_int() - 'A'.to_int() + 10
      _ => return None
    }
    guard d.to_uint64() < radix else { return None }
    n = n * radix + d.to_uint64()
  }
  Some(n)
}

///|
/// Emits the code of the attribute `(name, value)` of a term in the scope
/// of the subroutine `sub_name` whose instruction is at `addr` (upstream
/// `emit_attr`).
fn emit_attr(
  buf : StringBuilder,
  sub_name : String,
  addr : UInt64,
  name : String,
  value : String,
) -> Unit {
  let substitute = (s : String) => {
    match s {
      "sub_name" => sub_name
      "addr" => addr_to_hex(addr)
      s => s
    }
  }
  add_substitute(buf, substitute, python_of_attr(name, value))
  buf.write_char('\n')
}

///|
/// Generates the IDA Python script (upstream `extract_script`): the
/// prologue, the `python` annotations of the memory, one line per
/// selected attribute of every term that has an address, and the
/// epilogue.
pub fn extract_script(
  memory : @memory.MemMap[String],
  program : @types.Term[@types.Program],
  attrs : Array[String],
) -> String {
  let buf = StringBuilder()
  buf.write_string(prologue)
  for entry in memory.to_sequence() {
    match entry.1.strip_prefix("python=") {
      Some(line) => buf.write_string(line.to_owned())
      None => ()
    }
  }
  // The state is the name of the current subroutine and the address of
  // the most recently entered term, as in the upstream visitor.
  program.fold_program_visit(("", None), (state, event) => {
    let (name, addr) = state
    match event {
      EnterTerm(term) => {
        let addr = match term.get_attr("address") {
          Some(text) => parse_address(text)
          None => None
        }
        match term {
          SubTerm(sub) => (sub.sub_name(), addr)
          _ => (name, addr)
        }
      }
      LeaveTerm(term) => {
        match addr {
          Some(addr) =>
            for key, value in term.attrs() {
              if attrs.contains(key) {
                emit_attr(buf, name, addr, key, value)
              }
            }
          None => ()
        }
        state
      }
      _ => state
    }
  })
  |> ignore
  buf.write_string(epilogue)
  buf.to_string()
}

///|
/// Generates the script for a project.
pub fn project_script(
  project : @project.Project,
  attrs : Array[String],
) -> String {
  extract_script(project.memory(), project.program(), attrs)
}

///|
/// Prints a string to the standard output without adding a newline when
/// the string already ends with one (upstream `print_string`).
fn print_string(s : String) -> Unit {
  match s.strip_suffix("\n") {
    Some(body) => println(body)
    None => println(s)
  }
}

///|
/// Emits the script of the project into `file`, or passes it to `out`
/// when no file is given (upstream `main`).
pub fn emit(
  project : @project.Project,
  attrs~ : Array[String],
  file? : String,
  out~ : (String) -> Unit = print_string,
) -> Result[Unit, String] {
  let data = project_script(project, attrs)
  match file {
    None => {
      out(data)
      Ok(())
    }
    Some(path) => @native_io.write_file(path, @utf8.encode(data))
  }
}

///|
priv struct Config {
  mut file : String?
  mut attrs : Array[String]
  mut out : (String) -> Unit
}

///|
let config : Config = { file: None, attrs: [], out: print_string, }

///|
/// The name of the pass registered by the plugin.
pub let pass_name : String = "emit-ida-script"

///|
/// Registers the `emit-ida-script` project pass (upstream
/// `Project.register_pass'`). Calling it again only updates the
/// configuration of the already registered pass.
pub fn register(
  file? : String,
  attrs~ : Array[String] = [],
  out~ : (String) -> Unit = print_string,
) -> Result[Unit, String] {
  config.file = file
  config.attrs = attrs
  config.out = out
  let pass = @project.ProjectPass::create(name=pass_name, run=project => {
    match emit(project, attrs=config.attrs, file?=config.file, out=config.out) {
      Ok(_) => Ok(project)
      Err(e) => Err(e)
    }
  })
  match @project.register_pass_if_absent(pass) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// Declares the plugin in the `bap_main` framework with the upstream
/// `--emit-ida-script-file` and `--emit-ida-script-attr` parameters.
pub fn declare_plugin() -> Unit raise {
  @bap_main.register_plugin(
    "emit-ida-script",
    provides=["ida", "python", "pass"],
    doc="generates IDA Python scripts",
    () => {
      let file = @bap_main.Configuration::parameter(
        doc="Dump annotations to the specified file NAME. If not specified, then the script will dumped into the standard output",
        @bap_main.Type::some(@bap_main.Type::string()),
        "file",
      )
      let attrs = @bap_main.Configuration::parameters(
        doc="Emit specified BIR attribute. Can be specified multiple times.",
        @bap_main.Type::string(),
        "attr",
      )
      @bap_main.Extension::register(ctxt => {
        match register(file?=ctxt.get(file), attrs=ctxt.get(attrs)) {
          Ok(_) => ()
          Err(e) => fail(e)
        }
      })
    },
  )
}
