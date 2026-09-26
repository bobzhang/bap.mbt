///|
/// A witness that the classes indexed by `A` and `B` are the same class
/// (upstream `('a obj, 'b obj) Type_equal.t` obtained from `Class.equal`).
/// Objects of one class could be cast to the other with it.
struct ClassEq[A, B] {
  name : Name
  _phantom : (A, B)?
}

///|
/// `Class.equal x y`: a witness of the equality of two classes, if they
/// denote the same class (have the same name).
pub fn[A, S, B, T] Class::equal(
  self : Class[A, S],
  other : Class[B, T],
) -> ClassEq[A, B]? {
  if self.name == other.name {
    Some({ name: self.name, _phantom: None, })
  } else {
    None
  }
}

///|
/// `Class.assert_equal x y`: the witness of the equality of two classes
/// that are known to be the same. Aborts if they are different.
pub fn[A, S, B, T] Class::assert_equal(
  self : Class[A, S],
  other : Class[B, T],
) -> ClassEq[A, B] {
  match self.equal(other) {
    Some(witness) => witness
    None =>
      abort(
        "assert_equal: wrong assertion, classes of \{self.name.show()} and \{other.name.show()} are different",
      )
  }
}

///|
/// The witness in the opposite direction (the equality is symmetric).
pub fn[A, B] ClassEq::invert(self : ClassEq[A, B]) -> ClassEq[B, A] {
  { name: self.name, _phantom: None, }
}

///|
/// `Object.cast witness x`: the same object `x` with the other class index.
pub fn[A, B] Object::cast(
  witness : ClassEq[A, B],
  object : Object[A],
) -> Object[B] {
  ignore(witness)
  { id: object.id, class_name: object.class_name, _phantom: None, }
}

///|
/// `Object.derive` (comparable part): objects are ordered by class name,
/// then by identifier, so they can be keys of ordered and hashed
/// collections.
pub impl[K] Eq for Object[K] with fn equal(self, other) {
  self.id == other.id && self.class_name == other.class_name
}

///|
pub impl[K] Compare for Object[K] with fn compare(self, other) {
  let class_order = self.class_name.compare(other.class_name)
  if class_order != 0 {
    class_order
  } else {
    self.id.compare(other.id)
  }
}

///|
pub impl[K] Hash for Object[K] with fn hash_combine(self, hasher) {
  hasher.combine(self.class_name)
  hasher.combine(self.id)
}

///|
/// `Object.derive` (binable part): objects persist as their `repr`
/// (`#<class id>` or `nil`) and are read back into the class `cls`.
pub fn[K, S] Object::persistent(cls : Class[K, S]) -> Persistent[Object[K]] {
  Persistent::create(to_string=object => object.repr(), of_string=input => {
    Object::read(cls, input)
  })
}

///|
pub extend Object with Eq::{not_equal}

///|
pub extend Object with Compare::{op_lt, op_le, op_ge, op_gt}

///|
pub extend Object with Hash::{hash, hash_combine}
