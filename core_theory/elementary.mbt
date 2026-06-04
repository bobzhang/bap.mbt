///|
pub(all) struct Elementary {}

///|
pub(all) struct ElementaryScheme {}

///|
fn elementary_parts(ident : String) -> Array[String] {
  ident.split("/").to_array().map(part => part.to_owned())
}

///|
fn elementary_scheme(operation : String, sort : Sort, rank : Int) -> String {
  Elementary::table(operation, sort, rank)
}

///|
pub fn Elementary::table(operation : String, sort : Sort, rank : Int) -> String {
  operation + "/" + sort.to_string() + "/" + rank.to_string()
}

///|
pub fn Elementary::is_table(ident : String) -> Bool {
  elementary_parts(ident).length() == 3
}

///|
pub fn Elementary::operation(ident : String) -> Result[String, String] {
  match elementary_parts(ident) {
    [operation, _, _] => Ok(operation)
    _ => Err("not an elementary table: " + ident)
  }
}

///|
pub fn Elementary::operation_exn(ident : String) -> String {
  match Elementary::operation(ident) {
    Ok(operation) => operation
    Err(reason) => abort(reason)
  }
}

///|
pub fn ElementaryScheme::pow(sort : Sort, rank : Int) -> String {
  elementary_scheme("pow", sort, rank)
}

///|
pub fn ElementaryScheme::compound(sort : Sort, rank : Int) -> String {
  elementary_scheme("compound", sort, rank)
}

///|
pub fn ElementaryScheme::rootn(sort : Sort, rank : Int) -> String {
  elementary_scheme("rootn", sort, rank)
}

///|
pub fn ElementaryScheme::pown(sort : Sort, rank : Int) -> String {
  elementary_scheme("pown", sort, rank)
}

///|
pub fn ElementaryScheme::rsqrt(sort : Sort, rank : Int) -> String {
  elementary_scheme("rsqrt", sort, rank)
}

///|
pub fn ElementaryScheme::hypot(sort : Sort, rank : Int) -> String {
  elementary_scheme("hypot", sort, rank)
}

///|
pub fn ElementaryScheme::exp(sort : Sort, rank : Int) -> String {
  elementary_scheme("exp", sort, rank)
}

///|
pub fn ElementaryScheme::expm1(sort : Sort, rank : Int) -> String {
  elementary_scheme("expm1", sort, rank)
}

///|
pub fn ElementaryScheme::exp2(sort : Sort, rank : Int) -> String {
  elementary_scheme("exp2", sort, rank)
}

///|
pub fn ElementaryScheme::exp2m1(sort : Sort, rank : Int) -> String {
  elementary_scheme("exp2m1", sort, rank)
}

///|
pub fn ElementaryScheme::exp10(sort : Sort, rank : Int) -> String {
  elementary_scheme("exp10", sort, rank)
}

///|
pub fn ElementaryScheme::exp10m1(sort : Sort, rank : Int) -> String {
  elementary_scheme("exp10m1", sort, rank)
}

///|
pub fn ElementaryScheme::log(sort : Sort, rank : Int) -> String {
  elementary_scheme("log", sort, rank)
}

///|
pub fn ElementaryScheme::log2(sort : Sort, rank : Int) -> String {
  elementary_scheme("log2", sort, rank)
}

///|
pub fn ElementaryScheme::log10(sort : Sort, rank : Int) -> String {
  elementary_scheme("log10", sort, rank)
}

///|
pub fn ElementaryScheme::logp1(sort : Sort, rank : Int) -> String {
  elementary_scheme("logp1", sort, rank)
}

///|
pub fn ElementaryScheme::log2p1(sort : Sort, rank : Int) -> String {
  elementary_scheme("log2p1", sort, rank)
}

///|
pub fn ElementaryScheme::log10p1(sort : Sort, rank : Int) -> String {
  elementary_scheme("log10p1", sort, rank)
}

///|
pub fn ElementaryScheme::sin(sort : Sort, rank : Int) -> String {
  elementary_scheme("sin", sort, rank)
}

///|
pub fn ElementaryScheme::cos(sort : Sort, rank : Int) -> String {
  elementary_scheme("cos", sort, rank)
}

///|
pub fn ElementaryScheme::tan(sort : Sort, rank : Int) -> String {
  elementary_scheme("tan", sort, rank)
}

///|
pub fn ElementaryScheme::sinpi(sort : Sort, rank : Int) -> String {
  elementary_scheme("sinpi", sort, rank)
}

///|
pub fn ElementaryScheme::cospi(sort : Sort, rank : Int) -> String {
  elementary_scheme("cospi", sort, rank)
}

///|
pub fn ElementaryScheme::atanpi(sort : Sort, rank : Int) -> String {
  elementary_scheme("atanpi", sort, rank)
}

///|
pub fn ElementaryScheme::atan2pi(sort : Sort, rank : Int) -> String {
  elementary_scheme("atan2pi", sort, rank)
}

///|
pub fn ElementaryScheme::asin(sort : Sort, rank : Int) -> String {
  elementary_scheme("asin", sort, rank)
}

///|
pub fn ElementaryScheme::acos(sort : Sort, rank : Int) -> String {
  elementary_scheme("acos", sort, rank)
}

///|
pub fn ElementaryScheme::atan(sort : Sort, rank : Int) -> String {
  elementary_scheme("atan", sort, rank)
}

///|
pub fn ElementaryScheme::atan2(sort : Sort, rank : Int) -> String {
  elementary_scheme("atan2", sort, rank)
}

///|
pub fn ElementaryScheme::sinh(sort : Sort, rank : Int) -> String {
  elementary_scheme("sinh", sort, rank)
}

///|
pub fn ElementaryScheme::cosh(sort : Sort, rank : Int) -> String {
  elementary_scheme("cosh", sort, rank)
}

///|
pub fn ElementaryScheme::tanh(sort : Sort, rank : Int) -> String {
  elementary_scheme("tanh", sort, rank)
}

///|
pub fn ElementaryScheme::asinh(sort : Sort, rank : Int) -> String {
  elementary_scheme("asinh", sort, rank)
}

///|
pub fn ElementaryScheme::acosh(sort : Sort, rank : Int) -> String {
  elementary_scheme("acosh", sort, rank)
}

///|
pub fn ElementaryScheme::atanh(sort : Sort, rank : Int) -> String {
  elementary_scheme("atanh", sort, rank)
}
