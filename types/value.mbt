///|
/// A typed tag of a universal value (upstream `Bap.Std.Value.Tag`,
/// `'a tag`).
///
/// A tag names a type: values created with a tag can be projected back
/// with the same tag (and only with it) into their original type. Every
/// registered tag has a unique type identifier `typeid`, formed from its
/// UUID and name as in upstream (`<uuid>:<name>`).
///
/// MoonBit has neither existential types nor a universal `Any`, so a value
/// stores its payload in a type-erased closure that writes the payload into
/// the private cell of its tag (the classic "universal type" embedding, as
/// in `knowledge` records). Projecting a value with a tag runs the closure
/// and reads the cell back, which recovers the typed payload without any
/// unsafe cast.
struct Tag[T] {
  uid : Int
  name_value : String
  uuid_value : String
  package_value : String
  desc_value : String
  cell : Ref[T?]
  show_fn : (T) -> String
  compare_fn : (T, T) -> Int
  encode_fn : ((T) -> String)?
  decode_fn : ((String) -> T?)?
}

///|
/// The type-erased operations of a tag, shared by all of its values.
priv struct ValueInfo {
  uid : Int
  name : String
  typeid : String
  show : (Value) -> String
  compare : (Value, Value) -> Int
  encode : ((Value) -> String)?
}

///|
/// A universal value (upstream `Value.t`): a payload of any type paired
/// with the tag that describes it.
struct Value {
  store : () -> Unit
  info : ValueInfo
}

///|
/// The registered type information used to restore serialized values.
priv struct TagEntry {
  decode : ((String) -> Value?)?
}

///|
let tag_counter : Ref[Int] = { val: 0, }

///|
let tag_registry : Map[String, TagEntry] = Map([])

///|
fn tag_typeid(uuid : String, name : String) -> String {
  "\{uuid}:\{name}"
}

///|
/// Registers a new tag (upstream `Value.Tag.register`) from explicit
/// operations on its payload type.
///
/// - `show` prints a payload (upstream `S.pp`),
/// - `compare` orders payloads of the same tag (upstream `S.compare`),
/// - `encode`/`decode` optionally make the values serializable (upstream
///   `bin_io`); a tag without them yields values that print but that can't
///   be restored with `Value::decode`.
///
/// Aborts if a tag with the same `uuid` and `name` is already registered,
/// like upstream `Hashtbl.add_exn` does, since two different types can't
/// share a type identifier.
pub fn[T] Tag::register_with(
  name~ : String,
  uuid~ : String,
  show~ : (T) -> String,
  compare~ : (T, T) -> Int,
  encode? : (T) -> String,
  decode? : (String) -> T?,
  pkg? : String = "bap",
  desc? : String = "",
) -> Tag[T] {
  let typeid = tag_typeid(uuid, name)
  if tag_registry.contains(typeid) {
    abort("Value.Tag: type \{typeid} is already registered")
  }
  tag_counter.val = tag_counter.val + 1
  let tag : Tag[T] = {
    uid: tag_counter.val,
    name_value: name,
    uuid_value: uuid,
    package_value: pkg,
    desc_value: desc,
    cell: { val: None, },
    show_fn: show,
    compare_fn: compare,
    encode_fn: encode,
    decode_fn: decode,
  }
  tag_registry[typeid] = {
    decode: match decode {
      Some(parse) => Some(text => parse(text).map(x => Value::create(tag, x)))
      None => None
    },
  }
  tag
}

///|
/// Registers a new tag for a type with standard `Show` and `Compare`
/// implementations (upstream `Value.Tag.register (module S)`).
///
/// ```mbt check
/// test {
///   let tag : @types.Tag[Int] = @types.Tag::register(
///     name="doc-example-int",
///     uuid="0e5f5bd2-6a3a-4b43-9c8c-doc000000001",
///   )
///   let value = @types.Value::create(tag, 42)
///   debug_inspect(value.get(tag), content="Some(42)")
///   inspect(value.tagname(), content="doc-example-int")
///   inspect(value, content="42")
/// }
/// ```
pub fn[T : Show + Compare] Tag::register(
  name~ : String,
  uuid~ : String,
  encode? : (T) -> String,
  decode? : (String) -> T?,
  pkg? : String = "bap",
  desc? : String = "",
) -> Tag[T] {
  Tag::register_with(
    name~,
    uuid~,
    show=x => Show::to_string(x),
    compare=(x, y) => Compare::compare(x, y),
    encode?,
    decode?,
    pkg~,
    desc~,
  )
}

///|
/// The name of the tag (upstream `Tag.name`).
pub fn[T] Tag::name(self : Tag[T]) -> String {
  self.name_value
}

///|
/// The UUID the tag was registered with.
pub fn[T] Tag::uuid(self : Tag[T]) -> String {
  self.uuid_value
}

///|
/// The package the tag belongs to (upstream `?package`).
pub fn[T] Tag::pkg(self : Tag[T]) -> String {
  self.package_value
}

///|
/// The description of the tag.
pub fn[T] Tag::desc(self : Tag[T]) -> String {
  self.desc_value
}

///|
/// The type identifier of the tag (upstream `Tag.typeid`).
pub fn[T] Tag::typeid(self : Tag[T]) -> String {
  tag_typeid(self.uuid_value, self.name_value)
}

///|
/// Whether two tags, possibly of different types, denote the same type
/// (upstream `Tag.same`).
pub fn[A, B] Tag::same(self : Tag[A], other : Tag[B]) -> Bool {
  self.uid == other.uid
}

///|
/// Prints a payload with the tag's printer.
pub fn[T] Tag::show(self : Tag[T], x : T) -> String {
  (self.show_fn)(x)
}

///|
/// Serializes a payload, if the tag is serializable.
pub fn[T] Tag::encode(self : Tag[T], x : T) -> String? {
  self.encode_fn.map(encode => encode(x))
}

///|
/// Deserializes a payload, if the tag is serializable and `text` is valid.
pub fn[T] Tag::decode(self : Tag[T], text : String) -> T? {
  match self.decode_fn {
    Some(decode) => decode(text)
    None => None
  }
}

///|
/// Creates a value of the given tag (upstream `Value.create`).
pub fn[T] Value::create(tag : Tag[T], x : T) -> Value {
  let cell = tag.cell
  let info : ValueInfo = {
    uid: tag.uid,
    name: tag.name_value,
    typeid: tag.typeid(),
    show: v => {
      match v.get(tag) {
        Some(x) => (tag.show_fn)(x)
        None => ""
      }
    },
    compare: (a, b) => {
      match (a.get(tag), b.get(tag)) {
        (Some(x), Some(y)) => (tag.compare_fn)(x, y)
        _ => 0
      }
    },
    encode: match tag.encode_fn {
      Some(encode) =>
        Some(v => {
          match v.get(tag) {
            Some(x) => encode(x)
            None => ""
          }
        })
      None => None
    },
  }
  { store: () => cell.val = Some(x), info, }
}

///|
/// Projects a value with a tag (upstream `Value.get`): `Some(x)` if the
/// value was created with `tag`, `None` otherwise.
pub fn[T] Value::get(self : Value, tag : Tag[T]) -> T? {
  if self.info.uid != tag.uid {
    return None
  }
  tag.cell.val = None
  (self.store)()
  let result = tag.cell.val
  tag.cell.val = None
  result
}

///|
/// Projects a value with a tag, aborting if the value has another tag
/// (upstream `Value.get_exn`).
pub fn[T] Value::get_exn(self : Value, tag : Tag[T]) -> T {
  match self.get(tag) {
    Some(x) => x
    None =>
      abort(
        "Value.get_exn: expected a value of type \{tag.name_value}, got \{self.info.name}",
      )
  }
}

///|
/// Whether the value was created with `tag` (upstream `Value.is`; `is`
/// is a MoonBit keyword).
pub fn[T] Value::has_tag(self : Value, tag : Tag[T]) -> Bool {
  self.info.uid == tag.uid
}

///|
/// The name of the value's tag (upstream `Value.tagname`).
pub fn Value::tagname(self : Value) -> String {
  self.info.name
}

///|
/// The type identifier of the value's tag (upstream `Value.typeid`).
pub fn Value::typeid(self : Value) -> String {
  self.info.typeid
}

///|
/// Serializes a value as its type identifier and payload data (upstream
/// `Value.bin_io` representation), if its tag is serializable.
pub fn Value::encode(self : Value) -> (String, String)? {
  self.info.encode.map(encode => (self.info.typeid, encode(self)))
}

///|
/// Restores a value serialized with `Value::encode`, if its type is
/// registered, serializable and the data is valid.
pub fn Value::decode(typeid : String, data : String) -> Value? {
  match tag_registry.get(typeid) {
    Some({ decode: Some(decode), }) => decode(data)
    _ => None
  }
}

///|
/// The type identifiers of all registered tags, in registration order.
pub fn Value::registered_typeids() -> Array[String] {
  tag_registry.keys().collect()
}

///|
/// Values are ordered by their tags first and then by the tag's payload
/// order (upstream `Value.compare`).
pub extend Value with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Value with Eq::{equal, not_equal}

///|
pub extend Value with Show::{to_string, output}

///|
pub impl Compare for Value with fn compare(self, other) {
  if self.info.uid != other.info.uid {
    let by_typeid = self.info.typeid.compare(other.info.typeid)
    if by_typeid != 0 {
      by_typeid
    } else {
      self.info.uid.compare(other.info.uid)
    }
  } else {
    (self.info.compare)(self, other)
  }
}

///|
pub impl Eq for Value with fn equal(self, other) {
  self.compare(other) == 0
}

///|
/// Prints the payload with its tag's printer (upstream `Value.pp`).
pub impl Show for Value with fn output(self, logger) {
  logger.write_string((self.info.show)(self))
}

///|
/// A case analysis over universal values (upstream `Value.Match`).
struct ValueMatch[S] {
  cases : Array[(Value) -> S?]
  default : () -> S
}

///|
/// A match that yields `default()` for every value (upstream
/// `Match.default`).
pub fn[S] ValueMatch::default(default : () -> S) -> ValueMatch[S] {
  { cases: [], default, }
}

///|
/// Adds a case for values of `tag` (upstream `Match.case`). Earlier cases
/// take precedence.
pub fn[T, S] ValueMatch::case(
  self : ValueMatch[S],
  tag : Tag[T],
  f : (T) -> S,
) -> ValueMatch[S] {
  let cases = self.cases.copy()
  cases.push(v => v.get(tag).map(f))
  { cases, default: self.default, }
}

///|
/// Applies the match to a value (upstream `Match.select`).
pub fn[S] ValueMatch::select(self : ValueMatch[S], value : Value) -> S {
  for case in self.cases {
    if case(value) is Some(result) {
      return result
    }
  }
  (self.default)()
}

///|
/// Applies a match to the value (upstream `Match.switch`).
pub fn[S] Value::switch(self : Value, cases : ValueMatch[S]) -> S {
  cases.select(self)
}
