///|
/// Attaches a typed attribute to a term (upstream `Term.set_attr t tag x`).
///
/// Term attributes are stored as strings keyed by the tag name, so that
/// typed and string attributes interoperate: the payload is written with
/// the tag's encoder (or its printer when the tag isn't serializable) and
/// read back with `Term::get_tag`.
pub fn[T, A] Term::set_tag(self : Term[T], tag : Tag[A], x : A) -> Term[T] {
  let text = match tag.encode(x) {
    Some(text) => text
    None => tag.show(x)
  }
  self.set_attr(Attr::new(key=tag.name(), value=text))
}

///|
/// Reads a typed attribute of a term (upstream `Term.get_attr t tag`).
/// Returns `None` if the attribute is missing or the tag can't decode it.
pub fn[T, A] Term::get_tag(self : Term[T], tag : Tag[A]) -> A? {
  match self.get_attr(tag.name()) {
    Some(text) => tag.decode(text)
    None => None
  }
}

///|
/// Whether the term has the attribute of `tag` (upstream `Term.has_attr`).
pub fn[T, A] Term::has_tag(self : Term[T], tag : Tag[A]) -> Bool {
  self.has_attr(tag.name())
}

///|
/// Removes the attribute of `tag` (upstream `Term.del_attr`).
pub fn[T, A] Term::del_tag(self : Term[T], tag : Tag[A]) -> Term[T] {
  self.del_attr(tag.name())
}
