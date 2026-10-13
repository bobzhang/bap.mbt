// The native C parser provider: the counterpart of upstream
// `plugins/frontc_parser` (a C parser based on FrontC).
//
// Deviation: upstream can run an external preprocessor on the input
// (`--frontc-parser-preprocess`); the port cannot spawn processes and
// uses its own preprocessor subset instead (see `preprocessor.mbt`), with
// the include directories and predefined macros given by the
// `--c-parser-include` and `--c-parser-define` options.

///|
/// The name of the plugin.
pub let name : String = "c-parser"

///|
/// The features provided by the plugin.
pub let provides : Array[String] = ["api", "c", "parser"]

///|
/// Reads a text file through the `bap_main` file system.
pub fn default_read_file(path : String) -> String? {
  match (@bap_main.file_system().read_file)(path) {
    Some(bytes) => Some(@utf8.decode_lossy(bytes))
    None => None
  }
}

///|
/// Preprocesses and parses `text` (the contents of `file`) and returns
/// its declarations, whose sizes are computed with the data model `size`.
///
/// ```mbt check
/// test {
///   let decls = @c_parser.parse_string(
///     @c.SizeBase::new(LP64),
///     "typedef unsigned long size_t; size_t strlen(const char *s);",
///   )
///   let strlen = decls.search_by(d => d.0 == "strlen").unwrap()
///   inspect(decls[strlen].1, content="unsigned long (*)( const char* s);")
/// }
/// ```
pub fn parse_string(
  size : &@c.Ruler,
  text : String,
  file~ : String = "<string>",
  read_file~ : (String) -> String? = default_read_file,
  include_dirs~ : Array[String] = [],
  defines~ : Array[(String, String)] = [],
) -> Array[(String, @c.CType)] raise ParseError {
  let pp = Preprocessor::new(read_file~, include_dirs~, defines~)
  let tokens = pp.run(text, file~)
  let types = predefined_types(size).map(p => p.0)
  to_decls(size, parse_definitions(tokens, types~))
}

///|
/// Parses the file `file` read with `read_file` (upstream
/// `C.Parser.run` with the FrontC parser).
pub fn parse_file(
  size : &@c.Ruler,
  file : String,
  read_file~ : (String) -> String? = default_read_file,
  include_dirs~ : Array[String] = [],
  defines~ : Array[(String, String)] = [],
) -> Result[Array[(String, @c.CType)], String] {
  guard read_file(file) is Some(text) else {
    return Err("\{file}: no such file")
  }
  try
    parse_string(size, text, file~, read_file~, include_dirs~, defines~)
  catch {
    ParseError(msg) => Err(msg)
  } noraise {
    decls => Ok(decls)
  }
}

///|
/// A C parser for the `@c` parser registry.
pub fn parser(
  read_file~ : (String) -> String? = default_read_file,
  include_dirs~ : Array[String] = [],
  defines~ : Array[(String, String)] = [],
) -> @c.CParser {
  (size, file) => parse_file(size, file, read_file~, include_dirs~, defines~)
}

///|
/// Provides the parser to the `@c` parser registry (upstream
/// `C.Parser.provide`).
pub fn provide(
  read_file~ : (String) -> String? = default_read_file,
  include_dirs~ : Array[String] = [],
  defines~ : Array[(String, String)] = [],
) -> Unit {
  @c.provide_parser(parser(read_file~, include_dirs~, defines~))
}

///|
fn parse_define(s : String) -> (String, String) {
  match s.find("=") {
    Some(i) =>
      (
        s.unsafe_substring(start=0, end=i),
        s.unsafe_substring(start=i + 1, end=s.length()),
      )
    None => (s, "1")
  }
}

///|
/// Declares the `c-parser` plugin in the `bap_main` registry. Does nothing
/// if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides~,
    doc="provides a C parser for the API specifications",
    () => {
      let include_dirs = @bap_main.Configuration::parameters(
        doc="Searches the included files in the specified directory.",
        @bap_main.Type::string(),
        "include",
      )
      let defines = @bap_main.Configuration::parameters(
        doc="Predefines the macro NAME[=VALUE] (the value defaults to 1).",
        @bap_main.Type::string(),
        "define",
      )
      @bap_main.Extension::register(ctxt => {
        provide(
          include_dirs=ctxt.get(include_dirs),
          defines=ctxt.get(defines).map(parse_define),
        )
      })
    },
  )
}
