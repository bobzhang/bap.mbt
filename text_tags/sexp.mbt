// Tag specifications are s-expressions (upstream uses
// `Sexplib.Sexp.of_string`).

///|
using @sexp {type Sexp}

///|
fn is_sexp_space(c : Char) -> Bool {
  c is (' ' | '\t' | '\n' | '\r' | '\u{0C}')
}
