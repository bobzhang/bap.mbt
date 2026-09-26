///|
/// S-expressions (`Sexplib.Sexp.t`), shared with the other packages.
pub using @sexp {type Sexp}

///|
/// Parses all S-expressions of a text (`Sexp.load_sexps`).
pub fn parse_sexps(text : String) -> Result[Array[Sexp], String] {
  try @sexp.Sexp::of_string_many(text) catch {
    err => Err(err.to_string())
  } noraise {
    sexps => Ok(sexps)
  }
}
