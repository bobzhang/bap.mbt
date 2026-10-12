///|
/// The four Ogre field types (upstream `Type.typ`).
///
/// The constructor order matches upstream, which matters for the derived
/// ordering used when documents are compared.
pub(all) enum Typ {
  Int
  Str
  Bool
  Float
} derive(Eq, Debug)

///|
/// The textual name of a type as used in declarations: `int`, `str`, `bool`,
/// `float`.
pub fn Typ::to_string(self : Typ) -> String {
  match self {
    Int => "int"
    Str => "str"
    Bool => "bool"
    Float => "float"
  }
}

///|
pub impl Show for Typ with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Parses a declaration type name (`int`, `str`, `bool` or `float`).
pub fn Typ::of_string(name : String) -> Typ? {
  match name {
    "int" => Some(Int)
    "str" => Some(Str)
    "bool" => Some(Bool)
    "float" => Some(Float)
    _ => None
  }
}

///|
/// All types in declaration order.
pub fn Typ::all() -> Array[Typ] {
  [Int, Str, Bool, Float]
}

///|
fn Typ::index(self : Typ) -> Int32 {
  match self {
    Int => 0
    Str => 1
    Bool => 2
    Float => 3
  }
}

///|
/// The constructor name used by upstream's derived s-expression converter.
fn Typ::sexp_name(self : Typ) -> String {
  match self {
    Int => "Int"
    Str => "Str"
    Bool => "Bool"
    Float => "Float"
  }
}

///|
/// Whether `value` is in the domain of the type (upstream `Type.check`).
pub fn Typ::check(self : Typ, value : String) -> Bool {
  match self {
    Int => parse_ocaml_int64(value) is Some(_)
    Bool => parse_ocaml_bool(value) is Some(_)
    Float => parse_ocaml_float(value) is Some(_)
    Str => true
  }
}

///|
/// Rewrites a value into its canonical spelling (upstream `Type.normalize`),
/// e.g. `0x10` becomes `16` for `int` and `True` becomes `true` for `bool`.
/// Returns `None` if the value is not in the domain of the type.
pub fn Typ::normalize(self : Typ, value : String) -> String? {
  match self {
    Int => parse_ocaml_int64(value).map(x => x.to_string())
    Bool => parse_ocaml_bool(value).map(x => x.to_string())
    Float => parse_ocaml_float(value).map(sexp_string_of_float)
    Str => Some(value)
  }
}

///|
/// A field header of an attribute signature: a field name and its type
/// (upstream `Type.header`).
pub(all) struct Header {
  name : String
  typ : Typ
} derive(Eq, Debug)

///|
pub fn Header::new(name : String, typ : Typ) -> Header {
  { name, typ, }
}

///|
fn Header::compare(self : Header, other : Header) -> Int32 {
  let c = string_compare(self.name, other.name)
  if c != 0 {
    c
  } else {
    self.typ.index().compare(other.typ.index())
  }
}

///|
/// A type descriptor that knows how to parse and print values of type `T`
/// (upstream `'a Type.t`).
struct Type[T] {
  parse : (String) -> T?
  pack : (T) -> String
  typ : Typ
}

///|
/// The `int` type, represented with `Int64`.
pub fn Type::int() -> Type[Int64] {
  { parse: parse_ocaml_int64, pack: x => x.to_string(), typ: Int, }
}

///|
/// The `bool` type.
pub fn Type::bool() -> Type[Bool] {
  { parse: parse_ocaml_bool, pack: x => x.to_string(), typ: Bool, }
}

///|
/// The `str` type. Any sequence of characters is a valid value.
pub fn Type::str() -> Type[String] {
  { parse: x => Some(x), pack: x => x, typ: Str, }
}

///|
/// The `float` type, represented with `Double`.
pub fn Type::float() -> Type[Double] {
  { parse: parse_ocaml_float, pack: sexp_string_of_float, typ: Float, }
}

///|
/// The underlying untyped type.
pub fn[T] Type::typ(self : Type[T]) -> Typ {
  self.typ
}

///|
/// Parses a textual value.
pub fn[T] Type::parse(self : Type[T], value : String) -> T? {
  (self.parse)(value)
}

///|
/// Prints a value in its canonical textual form.
pub fn[T] Type::pack(self : Type[T], value : T) -> String {
  (self.pack)(value)
}

///|
/// A typed field of an attribute (upstream `'a field`), created with
/// [def].
struct Field[T] {
  name : String
  t : Type[T]
}

///|
/// `def(name, t)` defines a field with the given name and type (upstream
/// `Type.def` and `Type.(%:)`).
pub fn[T] def(name : String, t : Type[T]) -> Field[T] {
  { name, t, }
}

///|
pub fn[T] Field::name(self : Field[T]) -> String {
  self.name
}

///|
pub fn[T] Field::typ(self : Field[T]) -> Type[T] {
  self.t
}

///|
/// The untyped header of the field.
pub fn[T] Field::header(self : Field[T]) -> Header {
  { name: self.name, typ: self.t.typ, }
}

///|
/// An untyped fact: the (normalized) textual values of the fields of one
/// attribute value, keyed by field name (upstream `entry`).
///
/// Fields are kept sorted by name, so entries have a canonical form.
struct Entry {
  fields : Array[(String, String)]
} derive(Eq, Hash, Debug)

///|
fn Entry::of_pairs(pairs : Array[(String, String)]) -> Entry {
  let fields = pairs.copy()
  fields.sort_by((a, b) => string_compare(a.0, b.0))
  { fields, }
}

///|
/// The value of a field, if present.
pub fn Entry::get(self : Entry, name : String) -> String? {
  for field in self.fields {
    if field.0 == name {
      return Some(field.1)
    }
  }
  None
}

///|
/// The `(field, value)` pairs, sorted by field name.
pub fn Entry::fields(self : Entry) -> Array[(String, String)] {
  self.fields.copy()
}

///|
/// The number of fields.
pub fn Entry::length(self : Entry) -> Int32 {
  self.fields.length()
}

///|
fn Entry::set(self : Entry, name : String, value : String) -> Entry {
  let pairs = self.fields.filter(field => field.0 != name)
  pairs.push((name, value))
  Entry::of_pairs(pairs)
}

///|
fn Entry::compare(self : Entry, other : Entry) -> Int32 {
  let n = self.fields.length()
  let m = other.fields.length()
  for i in 0..<(if n < m { n } else { m }) {
    let (k1, v1) = self.fields[i]
    let (k2, v2) = other.fields[i]
    let c = string_compare(k1, k2)
    if c != 0 {
      return c
    }
    let c = string_compare(v1, v2)
    if c != 0 {
      return c
    }
  }
  n.compare(m)
}

///|
fn[T] Field::read(self : Field[T], entry : Entry) -> T? {
  match entry.get(self.name) {
    Some(value) => (self.t.parse)(value)
    None => None
  }
}

///|
pub extend Typ with Eq::{equal, not_equal}

///|
pub extend Header with Eq::{equal, not_equal}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Typ with Debug::{to_repr}

///|
pub extend Typ with Show::{output}

///|
pub extend Header with Debug::{to_repr}

///|
pub extend Entry with Debug::{to_repr}

///|
pub extend Entry with Hash::{hash, hash_combine}
