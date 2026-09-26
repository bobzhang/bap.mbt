///|
/// A scheme describes how values of type `T` are read from and packed into
/// untyped facts, together with the field signature (upstream
/// `('f, 'k) scheme`).
///
/// Upstream encodes the field list in continuation types so that attribute
/// constructors and `provide` become variadic. MoonBit has no such encoding,
/// so a scheme is indexed by the tuple of its field values instead:
/// `scheme(a)` has type `Scheme[A]` and `scheme(a).add(b)` (upstream
/// `scheme a $ b`) has type `Scheme[(A, B)]`. The flat helpers
/// [scheme2] ... [scheme5] build flat tuples directly.
struct Scheme[T] {
  signature : Array[Header]
  read : (Entry) -> T?
  save : (T) -> Entry
}

///|
/// A scheme with one field (upstream `Type.scheme`).
pub fn[T] scheme(field : Field[T]) -> Scheme[T] {
  {
    signature: [field.header()],
    read: entry => field.read(entry),
    save: value => Entry::of_pairs([(field.name, (field.t.pack)(value))]),
  }
}

///|
/// Appends a field to a scheme (upstream `Type.($)`).
pub fn[A, B] Scheme::add(self : Scheme[A], field : Field[B]) -> Scheme[(A, B)] {
  let signature = self.signature.copy()
  signature.push(field.header())
  {
    signature,
    read: entry => {
      match (self.read)(entry) {
        None => None
        Some(a) =>
          match field.read(entry) {
            None => None
            Some(b) => Some((a, b))
          }
      }
    },
    save: value => (self.save)(value.0).set(field.name, (field.t.pack)(value.1)),
  }
}

///|
/// Maps the value type of a scheme through a bijection.
pub fn[A, B] Scheme::iso(
  self : Scheme[A],
  to : (A) -> B,
  from : (B) -> A,
) -> Scheme[B] {
  {
    signature: self.signature,
    read: entry => (self.read)(entry).map(to),
    save: value => (self.save)(from(value)),
  }
}

///|
/// A two-field scheme over a flat tuple.
pub fn[A, B] scheme2(a : Field[A], b : Field[B]) -> Scheme[(A, B)] {
  scheme(a).add(b)
}

///|
/// A three-field scheme over a flat tuple.
pub fn[A, B, C] scheme3(
  a : Field[A],
  b : Field[B],
  c : Field[C],
) -> Scheme[(A, B, C)] {
  scheme(a).add(b).add(c).iso(t => (t.0.0, t.0.1, t.1), t => ((t.0, t.1), t.2))
}

///|
/// A four-field scheme over a flat tuple.
pub fn[A, B, C, D] scheme4(
  a : Field[A],
  b : Field[B],
  c : Field[C],
  d : Field[D],
) -> Scheme[(A, B, C, D)] {
  scheme(a)
  .add(b)
  .add(c)
  .add(d)
  .iso(t => (t.0.0.0, t.0.0.1, t.0.1, t.1), t => (((t.0, t.1), t.2), t.3))
}

///|
/// A five-field scheme over a flat tuple.
pub fn[A, B, C, D, E] scheme5(
  a : Field[A],
  b : Field[B],
  c : Field[C],
  d : Field[D],
  e : Field[E],
) -> Scheme[(A, B, C, D, E)] {
  scheme(a)
  .add(b)
  .add(c)
  .add(d)
  .add(e)
  .iso(t => (t.0.0.0.0, t.0.0.0.1, t.0.0.1, t.0.1, t.1), t => {
    ((((t.0, t.1), t.2), t.3), t.4)
  })
}

///|
/// The untyped signature of the scheme.
pub fn[T] Scheme::signature(self : Scheme[T]) -> Array[Header] {
  self.signature.copy()
}

///|
/// A typed attribute descriptor (upstream `('a, 'k) attribute` /
/// `typeinfo`).
///
/// `A` is the type of attribute values read from documents and `K` is the
/// type of the field tuple that [provide] and [Doc::put] take.
struct Attribute[A, K] {
  name : String
  sign : Array[Header]
  read : (Entry) -> A?
  save : (K) -> Entry
}

///|
/// `declare(name~, scheme, cons)` declares an attribute named `name` whose
/// facts are described by `scheme`; `cons` builds attribute values from the
/// scheme's field tuple (upstream `declare`).
///
/// Unlike upstream, attributes are ordinary values: there is no need to wrap
/// them in a thunk.
pub fn[A, K] Attribute::new(
  name~ : String,
  scheme : Scheme[K],
  cons : (K) -> A,
) -> Attribute[A, K] {
  {
    name,
    sign: scheme.signature,
    read: entry => (scheme.read)(entry).map(cons),
    save: scheme.save,
  }
}

///|
/// The attribute name (upstream `Attribute.name`).
pub fn[A, K] Attribute::name(self : Attribute[A, K]) -> String {
  self.name
}

///|
/// The attribute signature.
pub fn[A, K] Attribute::signature(self : Attribute[A, K]) -> Array[Header] {
  self.sign.copy()
}

///|
/// Packs field values into an untyped fact (upstream `Attribute.pack`).
pub fn[A, K] Attribute::pack(self : Attribute[A, K], value : K) -> Entry {
  (self.save)(value)
}

///|
/// Reads an attribute value from an untyped fact, if all fields are present
/// and well typed.
pub fn[A, K] Attribute::read(self : Attribute[A, K], entry : Entry) -> A? {
  (self.read)(entry)
}
