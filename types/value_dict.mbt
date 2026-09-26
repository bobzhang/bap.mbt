///|
/// A heterogeneous dictionary of universal values indexed by their tags
/// (upstream `Value.Dict`): it holds at most one value per tag.
struct Dict {
  entries : @sorted_map.SortedMap[String, Value]
}

///|
/// The empty dictionary (upstream `Dict.empty`).
pub fn Dict::empty() -> Dict {
  { entries: @sorted_map.SortedMap([]), }
}

///|
pub fn Dict::is_empty(self : Dict) -> Bool {
  self.entries.is_empty()
}

///|
pub fn Dict::length(self : Dict) -> Int {
  self.entries.length()
}

///|
/// Binds `tag` to `x`, replacing a previous binding (upstream `Dict.set`).
pub fn[T] Dict::set(self : Dict, tag : Tag[T], x : T) -> Dict {
  self.set_value(Value::create(tag, x))
}

///|
/// Binds a universal value under its own tag.
pub fn Dict::set_value(self : Dict, value : Value) -> Dict {
  let entries = self.entries.copy()
  entries.set(value.typeid(), value)
  { entries, }
}

///|
/// Removes the binding of `tag` (upstream `Dict.remove`).
pub fn[T] Dict::remove(self : Dict, tag : Tag[T]) -> Dict {
  if !self.mem(tag) {
    return self
  }
  let entries = self.entries.copy()
  entries.remove(tag.typeid())
  { entries, }
}

///|
/// Whether `tag` is bound (upstream `Dict.mem`).
pub fn[T] Dict::mem(self : Dict, tag : Tag[T]) -> Bool {
  match self.entries.get(tag.typeid()) {
    Some(value) => value.has_tag(tag)
    None => false
  }
}

///|
/// The value bound to `tag` (upstream `Dict.find`).
pub fn[T] Dict::find(self : Dict, tag : Tag[T]) -> T? {
  match self.entries.get(tag.typeid()) {
    Some(value) => value.get(tag)
    None => None
  }
}

///|
/// Binds `tag` to `x` unless it is already bound (upstream `Dict.add`,
/// where `None` stands for `Duplicate`).
pub fn[T] Dict::add(self : Dict, tag : Tag[T], x : T) -> Dict? {
  if self.mem(tag) {
    None
  } else {
    Some(self.set(tag, x))
  }
}

///|
/// Updates the binding of `tag` with `f` (upstream `Dict.change`): `f`
/// receives the current binding and returns the new one, `None` removing
/// it.
pub fn[T] Dict::change(self : Dict, tag : Tag[T], f : (T?) -> T?) -> Dict {
  match f(self.find(tag)) {
    Some(x) => self.set(tag, x)
    None => self.remove(tag)
  }
}

///|
/// The bindings of the dictionary as `(typeid, value)` pairs ordered by
/// type identifier (upstream `Dict.to_sequence`).
pub fn Dict::to_array(self : Dict) -> Array[(String, Value)] {
  self.entries.to_array()
}

///|
/// The values of the dictionary (upstream `Dict.data`).
pub fn Dict::data(self : Dict) -> Array[Value] {
  self.entries.values().collect()
}

///|
/// Keeps the values that satisfy `f` (upstream `Dict.filter`).
pub fn Dict::filter(self : Dict, f : (Value) -> Bool) -> Dict {
  let entries = @sorted_map.SortedMap([])
  for typeid, value in self.entries {
    if f(value) {
      entries.set(typeid, value)
    }
  }
  { entries, }
}

///|
pub extend Dict with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Dict with Eq::{equal, not_equal}

///|
pub extend Dict with Show::{to_string, output}

///|
pub impl Eq for Dict with fn equal(self, other) {
  self.compare(other) == 0
}

///|
/// Dictionaries are compared as ordered lists of values (upstream
/// `Dict.compare`).
pub impl Compare for Dict with fn compare(self, other) {
  let xs = self.data()
  let ys = other.data()
  for
    i in 0..<(if xs.length() < ys.length() { xs.length() } else { ys.length() }) {
    let order = xs[i].compare(ys[i])
    if order != 0 {
      return order
    }
  }
  xs.length().compare(ys.length())
}

///|
pub impl Show for Dict with fn output(self, logger) {
  logger.write_string("{")
  let mut first = true
  for _, value in self.entries {
    if !first {
      logger.write_string(", ")
    }
    first = false
    logger.write_string(value.tagname())
    logger.write_string(": ")
    logger.write_string(value.to_string())
  }
  logger.write_string("}")
}
