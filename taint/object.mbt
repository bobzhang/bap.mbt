// Port of `Bap_taint` (lib/bap_taint): the Primus Taint Analysis
// Framework.
//
// Taint analysis is a dynamic data flow analysis that tracks values on
// demand: only values marked as tainted are tracked. A taint represents
// an abstract *object* of some *kind*; a computation is tainted by an
// object if its value depends on (or is influenced by) the value of that
// object. Taints are attached to runtime values (`@primus.Value`) either
// *directly* (the value contains or is computed from the object) or
// *indirectly* (the value is an address of a tainted cell).
//
// Upstream every interface is a functor over `Primus.Machine.S`; here the
// machine is an explicit `@primus.Machine` argument. Objects, kinds and
// policies are Primus values (so that they can be passed to and returned
// from Primus Lisp primitives) and, as upstream (`Primus.Value`
// comparison), they are compared by their words, not by their value
// identifiers.

///|
/// Errors raised by the taint engine (upstream `Primus.exn` extensions).
pub(all) suberror TaintError {
  /// `Object.Bad_object`: the value doesn't denote a known taint object.
  BadObject(@primus.Value)
  /// `Taint.Bad_cast`: the value can't be converted to an integer.
  BadCast(@primus.Value)
}

///|
fn taint_error_to_string(err : Error) -> String? {
  match err {
    BadObject(v) => Some("bad taint object: \{v}")
    BadCast(v) => Some("bad taint cast: \{v} is not an integer")
    _ => None
  }
}

///|
fn init {
  @primus.exn_add_printer(taint_error_to_string)
}

///|
/// The upstream ordering of Primus values (by their words).
fn word_compare(x : @primus.Value, y : @primus.Value) -> Int32 {
  x.to_word().compare(y.to_word())
}

///|
/// A kind of taint objects (upstream `Taint.Kind.t`).
///
/// A kind denotes a class of objects that share the same semantic
/// properties; it lets several analyses run in parallel without
/// interfering with each other's taints. A kind is represented by the
/// Primus symbol value of its name.
pub struct Kind {
  priv value : @primus.Value
}

///|
/// Interns the name of a kind (`Kind.create`): creating a kind with the
/// same name twice yields the same kind.
pub fn Kind::create(m : @primus.Machine, name : String) -> Kind raise {
  { value: @primus.Value::symbol_to_value(m, name), }
}

///|
/// The symbolic name of a kind (`Kind.name`).
pub fn Kind::name(self : Kind, m : @primus.Machine) -> String {
  @primus.Value::symbol_of_value(m, self.value)
}

///|
/// Injects the kind into the value domain (`Kind.to_value`).
pub fn Kind::to_value(self : Kind) -> @primus.Value {
  self.value
}

///|
/// Projects a value to a kind (`Kind.of_value`).
pub fn Kind::of_value(value : @primus.Value) -> Kind {
  { value, }
}

///|
pub impl Eq for Kind with fn equal(self, other) {
  self.value.to_word() == other.value.to_word()
}

///|
pub impl Compare for Kind with fn compare(self, other) {
  word_compare(self.value, other.value)
}

///|
pub impl Show for Kind with fn output(self, logger) {
  logger.write_string(self.value.to_word().to_string())
}

///|
pub extend Kind with Eq::{not_equal, equal}

///|
pub extend Kind with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Kind with Show::{to_string, output}

///|
/// A tracked abstract object: a taint (upstream `Taint.Object.t`).
///
/// Every introduced taint is a fresh object, represented by a 63-bit
/// Primus value that is never equal to any object created before by the
/// same machine (objects are registered in a global table together with
/// their kinds).
pub struct Object {
  priv value : @primus.Value
}

///|
/// Injects the object into the value domain (`Object.to_value`).
pub fn Object::to_value(self : Object) -> @primus.Value {
  self.value
}

///|
/// Projects a value to an object (`Object.of_value`). The value is not
/// checked, use `Object::kind` to validate it.
pub fn Object::of_value(value : @primus.Value) -> Object {
  { value, }
}

///|
/// The decimal representation of the object (`Object.to_string`).
pub fn Object::to_string(self : Object) -> String {
  let w = self.value.to_word()
  w.to_uint64().to_string() catch {
    _ => w.to_string()
  }
}

///|
/// The s-expression representation of the object (`Object.inspect`).
pub fn Object::inspect(self : Object) -> @primus.Sexp {
  Atom(self.to_string())
}

///|
pub impl Eq for Object with fn equal(self, other) {
  self.value.to_word() == other.value.to_word()
}

///|
pub impl Compare for Object with fn compare(self, other) {
  word_compare(self.value, other.value)
}

///|
pub impl Show for Object with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend Object with Eq::{not_equal, equal}

///|
pub extend Object with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Object with Show::{output}

///|
/// The width of object identifiers (upstream `Object.t` Lisp type).
pub let object_width : Int32 = 63

///|
/// The global registry of all ever created objects and their kinds.
priv struct Kinds {
  objects : @sorted_map.SortedMap[Object, Kind]
}

///|
let kinds : @primus.State[Kinds] = @primus.State::declare_(
  name="tainter-object-kinds",
  uuid="a97f9cf6-541a-4127-9eb6-6c24f67ed8b9",
  inspect=s => {
    List(
      s.objects
      .to_array()
      .map(p => @primus.Sexp::List([p.0.inspect(), Atom(p.1.to_string())])),
    )
  },
  _ => { objects: @sorted_map.SortedMap::new(), },
)

///|
fn next_key(m : @primus.Machine, s : Kinds) -> @primus.Value raise {
  match s.objects.rev_keys().head() {
    None => @primus.Value::of_int(m, width=object_width, 1)
    Some(k) => @primus.Value::succ(m, k.value)
  }
}

///|
/// Creates a fresh object of the given kind (`Object.create`).
///
/// The created object is never equal to any object created before in
/// the machine; the same kind may be shared by several objects.
pub fn Object::create(m : @primus.Machine, kind : Kind) -> Object raise {
  let s = m.get_global(kinds)
  let key : Object = { value: next_key(m, s), }
  m.put_global(kinds, { objects: s.objects.add(key, kind), })
  key
}

///|
/// The kind of the object (`Object.kind`), raises `BadObject` if the
/// value doesn't denote an object.
pub fn Object::kind(self : Object, m : @primus.Machine) -> Kind raise {
  match m.get_global(kinds).objects.get(self) {
    Some(k) => k
    None => m.raise_exn(BadObject(self.value))
  }
}

///|
/// The kind of the object, if it is a known object.
fn kind_of(m : @primus.Machine, obj : Object) -> Kind? {
  m.get_global(kinds).objects.get(obj)
}

///|
/// A relation between a value and a tracked object (upstream
/// `Taint.Rel.t`).
pub(all) enum Rel {
  /// The value contains (bits of) the object or is influenced by it.
  Direct
  /// The value is an address of a value that is directly related to the
  /// object.
  Indirect
} derive(Eq, Compare, Debug)

///|
pub extend Rel with Eq::{not_equal, equal}

///|
pub extend Rel with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Rel with Debug::{to_repr}

///|
pub fn Rel::to_string(self : Rel) -> String {
  match self {
    Direct => "Direct"
    Indirect => "Indirect"
  }
}

///|
pub impl Show for Rel with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend Rel with Show::{output}
