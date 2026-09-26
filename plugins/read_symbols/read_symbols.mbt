///|
/// The plugin name and the name of the registered rooter/symbolizer sources.
pub let name : String = "read-symbols"

///|
let doc : String =
  #|Provides functions addresses and (optionally) names from a user specified
  #|file(s). The file format is a list of entries, where each entry is either
  #|an address or a delimited with parentheses tuple, e.g., (main 0xDEADBEEF).
  #|If the same name occurs in several entries with different addresses then
  #|the minimal address is chosen as the starting address. If the same address
  #|occurs in entries with different names then an error is reported and the
  #|inconsistent names are ignored. With several files (or with
  #|--read-symbols-when-matches) only files whose basename without extension
  #|matches the unit name are used.

///|
/// The name prefix of nameless entries (function starts only).
pub let anonymous_prefix : String = "__anonymous_sub%"

///|
/// `true` for names generated for nameless entries.
pub fn is_anonymous(s : String) -> Bool {
  s.has_prefix(anonymous_prefix)
}

///|
fn parse_addr(text : String) -> Result[UInt64, String] {
  try @string.parse_uint64(text, base=0) catch {
    _ => Err("failed to read symbols, invalid address \{text}")
  } noraise {
    addr => Ok(addr)
  }
}

///|
/// Interprets an entry: `(<name> <addr> ...)` or `<addr>` (`parse_entry`).
pub fn parse_entry(sexp : Sexp) -> Result[(String, UInt64), String] {
  match sexp {
    List([Atom(fname), Atom(addr), ..]) => parse_addr(addr).map(a => (fname, a))
    Atom(addr) => parse_addr(addr).map(a => (anonymous_prefix + addr, a))
    _ => Err("failed to read symbols, expects (<name> <addr> ...)")
  }
}

///|
/// Parses a symbols file.
pub fn parse_symbols(text : String) -> Result[Array[(String, UInt64)], String] {
  match parse_sexps(text) {
    Err(reason) => Err("failed to read symbols: \{reason}")
    Ok(sexps) => {
      let entries = []
      for sexp in sexps {
        match parse_entry(sexp) {
          Ok(entry) => entries.push(entry)
          Err(reason) => return Err(reason)
        }
      }
      Ok(entries)
    }
  }
}

///|
fn hex(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16)
}

///|
/// Resolves the entries into a map from function starts to names
/// (`build_functions`): names with several addresses keep the minimal one,
/// and addresses with several names are reported and skipped.
pub fn build_functions(
  entries : Array[(String, UInt64)],
  report? : (String) -> Unit = message => {
    @main_event.message(MainLogError, section=name, message~)
  },
) -> Map[UInt64, String] {
  let mut rel : @relation.Relation[UInt64, String] = @relation.empty(
    compare_left=(x, y) => x.compare(y),
    compare_right=String::lexical_compare,
  )
  for entry in entries {
    rel = rel.add(entry.1, entry.0)
  }
  let functions : Map[UInt64, String] = Map([])
  rel.matching(init=(), saturated=(addr, fname, _) => functions[addr] = fname, unmatched=(
    problem,
    _,
  ) => {
    match problem {
      NonInjectiveBwd(names, addr) =>
        report(
          "skipping names (\{names.join(", ")}) that has the same address \{hex(addr)}",
        )
      NonInjectiveFwd(addrs, fname) => {
        let mut min = addrs[0]
        for addr in addrs {
          if addr < min {
            min = addr
          }
        }
        functions[min] = fname
      }
    }
  })
  functions
}

///|
fn basename(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.unsafe_substring(start=i + 1, end=path.length())
    None => path
  }
}

///|
fn chop_extension(base : String) -> String {
  match base.rev_find(".") {
    Some(i) => base.unsafe_substring(start=0, end=i)
    None => base
  }
}

///|
/// Normalizes a path to its basename without the extension.
pub fn normalize(path : String) -> String {
  chop_extension(basename(path))
}

///|
/// `true` if two paths have the same basename without extension.
pub fn name_matches(p1 : String, p2 : String) -> Bool {
  normalize(p1) == normalize(p2)
}

///|
/// The symbol files that apply to the unit at `path`.
///
/// With a single file and no `when_matches` the file always applies;
/// otherwise the file must match `path`, and so must the name passed with
/// `when_matches=Some(name)`. Directories are expanded to their contents.
pub fn select_files(
  path : String,
  files : Array[String],
  when_matches? : String?,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> Array[String] {
  let always_matches = files.length() == 1 && when_matches is None
  let matches = (file : String) => {
    always_matches ||
    (
      name_matches(file, path) &&
      (match when_matches {
        Some(Some(other)) => name_matches(other, path)
        _ => true
      })
    )
  }
  let paths = []
  for file in files {
    match (fs.kind)(file) {
      Some(Directory) => {
        let names = (fs.read_dir)(file).unwrap_or([])
        names.sort_by(String::lexical_compare)
        let prefix = if file.has_suffix("/") { file } else { file + "/" }
        for entry in names {
          paths.push(prefix + entry)
        }
      }
      Some(_) => paths.push(file)
      None => ()
    }
  }
  paths.filter(matches)
}

///|
/// Reads and resolves the functions that apply to the unit at `path`
/// (`collect`).
pub fn collect(
  path : String,
  files : Array[String],
  when_matches? : String?,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
  report? : (String) -> Unit,
) -> Result[Map[UInt64, String], String] {
  let entries = []
  for file in select_files(path, files, when_matches?, fs~) {
    match (fs.read_file)(file) {
      None => return Err("failed to read symbols from \{file}")
      Some(bytes) => {
        let text = @utf8.decode_lossy(bytes)
        match parse_symbols(text) {
          Ok(items) => entries.append(items)
          Err(reason) => return Err("\{file}: \{reason}")
        }
      }
    }
  }
  Ok(build_functions(entries, report?))
}

///|
/// A rooter that provides every function start.
pub fn rooter(
  functions : Map[UInt64, String],
  path? : String,
) -> @project.ProjectRooter {
  let roots = functions.keys().collect()
  roots.sort()
  @project.ProjectRooter::create(roots, path?)
}

///|
/// A symbolizer that names the non-anonymous function starts.
pub fn symbolizer(
  functions : Map[UInt64, String],
  path? : String,
) -> @project.ProjectSymbolizer {
  @project.ProjectSymbolizer::create(
    addr => {
      match functions.get(addr) {
        Some(fname) if !is_anonymous(fname) => Some(fname)
        _ => None
      }
    },
    path?,
  )
}

///|
/// Registers the `read-symbols` rooter and symbolizer sources for the unit at
/// `path` (the empty path when unknown). Registration replaces the previous
/// sources of the same name; returns `false` when no file was given.
pub fn register(
  files~ : Array[String],
  when_matches? : String?,
  path? : String,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> Result[Bool, String] {
  if files.is_empty() {
    return Ok(false)
  }
  match collect(path.unwrap_or(""), files, when_matches?, fs~) {
    Err(reason) => Err(reason)
    Ok(functions) => {
      @project.register_rooter_source_value(name~, rooter(functions, path?))
      @project.register_symbolizer_source_value(
        name~,
        symbolizer(functions, path?),
      )
      Ok(true)
    }
  }
}

///|
/// Declares the `read-symbols` plugin to `bap_main` with its `from` and
/// `when-matches` parameters. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["rooter", "symbolizer"], doc~, () => {
    let files = @bap_main.Configuration::parameters(
      doc="The files with function starts and names.",
      @bap_main.Type::list(@bap_main.Type::string()),
      "from",
    )
    let when_matches = @bap_main.Configuration::parameter(
      doc="Use the symbols only for units whose names match the files.",
      as_flag=Some(None),
      @bap_main.Type::some(@bap_main.Type::some(@bap_main.Type::string())),
      "when-matches",
    )
    @bap_main.Extension::register(ctxt => {
      let files = ctxt.get(files).fold(init=[], (acc, xs) => acc + xs)
      match register(files~, when_matches?=ctxt.get(when_matches)) {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
