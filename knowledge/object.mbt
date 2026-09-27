///|
struct Object[K] {
  id : Int
  class_name : Name
  _phantom : K?
}

///|
pub fn[K, S] Object::null(cls : Class[K, S]) -> Object[K] {
  { id: 0, class_name: cls.name(), _phantom: None, }
}

///|
pub fn[K] Object::id(self : Object[K]) -> Int {
  self.id
}

///|
pub fn[K] Object::class_name(self : Object[K]) -> Name {
  self.class_name
}

///|
pub fn[K] Object::is_null(self : Object[K]) -> Bool {
  self.id == 0
}

///|
fn object_read_id(input : String) -> Result[Int, String] {
  if !(input.has_prefix("#<") && input.has_suffix(">")) {
    return Err("invalid object representation: \{input}")
  }
  let inner = input[2:input.length() - 1]
  let mut split = -1
  for i, ch in inner {
    if ch == ' ' {
      split = i
    }
  }
  if split < 0 || split + 1 >= inner.length() {
    return Err("invalid object representation: \{input}")
  }
  try @string.parse_int(inner[split + 1:]) catch {
    _ => Err("invalid object representation: \{input}")
  } noraise {
    id if id >= 0 => Ok(id)
    _ => Err("invalid object representation: \{input}")
  }
}

///|
pub fn[K] Object::equal(self : Object[K], other : Object[K]) -> Bool {
  self.id == other.id && self.class_name == other.class_name
}

///|
pub fn[K] Object::compare(self : Object[K], other : Object[K]) -> Int {
  let class_order = self.class_name.compare(other.class_name)
  if class_order != 0 {
    class_order
  } else {
    self.id.compare(other.id)
  }
}

///|
pub fn[K] Object::repr(self : Object[K]) -> String {
  if self.is_null() {
    "nil"
  } else {
    "#<\{self.class_name.show()} \{self.id}>"
  }
}

///|
pub fn[K, S] Object::read(
  cls : Class[K, S],
  input : String,
) -> Result[Object[K], String] {
  if input == "nil" {
    Ok(Object::null(cls))
  } else {
    match object_read_id(input) {
      Ok(id) => Ok({ id, class_name: cls.name(), _phantom: None, })
      Err(reason) => Err(reason)
    }
  }
}
