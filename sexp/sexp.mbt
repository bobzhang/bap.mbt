// S-expressions compatible with OCaml's `Sexplib`.
//
// The reader accepts unquoted and quoted atoms, `;` line comments, nested
// `#| ... |#` block comments and `#;` s-expression comments. Quoted atoms
// support the sexplib escapes `\\ \" \' \n \t \b \r \<space>`, decimal
// `\ddd` and hexadecimal `\xhh` byte escapes (the bytes of a quoted atom
// are decoded as UTF-8), line continuations (a backslash before a newline
// skips the leading blanks of the next line), and keep any other
// backslash verbatim.
//
// The printer produces sexplib's machine format (`Sexp.to_string`): atoms
// are quoted and escaped (OCaml `String.escaped`) only when needed, and
// no space is emitted next to parentheses or quoted atoms.

///|
/// An s-expression (`Sexplib.Sexp.t`).
pub(all) enum Sexp {
  Atom(String)
  List(Array[Sexp])
} derive(Eq, Hash, Debug)

///|
pub extend Sexp with Eq::{not_equal, equal}

///|
pub extend Sexp with Hash::{hash, hash_combine}

///|
pub extend Sexp with Debug::{to_repr}

///|
/// A syntax error at the given line (1-based) and column (0-based,
/// counted in characters).
pub(all) suberror ParseError {
  ParseError(line~ : Int, column~ : Int, String)
} derive(Eq, Debug)

///|
pub extend ParseError with Eq::{not_equal, equal}

///|
pub extend ParseError with Debug::{to_repr}

///|
/// The error message, without the position.
pub fn ParseError::message(self : ParseError) -> String {
  match self {
    ParseError(msg, ..) => msg
  }
}

///|
pub impl Show for ParseError with fn output(self, logger) {
  match self {
    ParseError(line~, column~, msg) =>
      logger.write_string("line \{line}, column \{column}: \{msg}")
  }
}

///|
pub extend ParseError with Show::{to_string, output}

///|
/// The atom, if the s-expression is an atom.
pub fn Sexp::atom(self : Sexp) -> String? {
  match self {
    Atom(s) => Some(s)
    List(_) => None
  }
}

///|
/// The elements, if the s-expression is a list.
pub fn Sexp::list(self : Sexp) -> Array[Sexp]? {
  match self {
    Atom(_) => None
    List(items) => Some(items)
  }
}
