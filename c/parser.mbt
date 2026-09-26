// Port of BAP `lib/bap_c/bap_c_parser.ml` (a parser interface).
//
// The module doesn't provide any parsers by itself; a third-party module
// (upstream, the FrontC-based plugin) provides one with `provide_parser`.

///|
/// A list of declarations: a mapping from identifiers to their types.
pub type Decls = Array[(String, CType)]

///|
/// A C parser: given a data model and a file name, returns the
/// declarations in the file.
pub type CParser = (&Ruler, String) -> Result[Decls, String]

///|
let c_parser : Ref[CParser?] = Ref(None)

///|
/// Called by a plugin that provides a parser (upstream `provide`). A later
/// call replaces the previously provided parser.
pub fn provide_parser(parser : CParser) -> Unit {
  c_parser.val = Some(parser)
}

///|
/// Parses `file` and returns a mapping from identifiers to their types
/// (upstream `run`).
pub fn run_parser(size : &Ruler, file : String) -> Result[Decls, String] {
  match c_parser.val {
    None => Err("C parser is not available")
    Some(parse) => parse(size, file)
  }
}
