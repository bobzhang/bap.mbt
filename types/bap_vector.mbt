///|
struct BapVector[T] {
  mut size_value : Int
  mut data_value : Array[T]
  default_value : T
}

///|
pub fn[T] BapVector::create(default : T, capacity? : Int = 16) -> BapVector[T] {
  let actual_capacity = if capacity < 1 { 1 } else { capacity }
  {
    size_value: 0,
    data_value: Array::make(actual_capacity, default),
    default_value: default,
  }
}

///|
fn[T] BapVector::resize(self : BapVector[T]) -> Unit {
  let old_capacity = self.data_value.length()
  let new_capacity = if self.size_value <= 0 {
    old_capacity * 2
  } else {
    self.size_value * 2
  }
  let data = Array::make(new_capacity, self.default_value)
  for i in 0..<old_capacity {
    data.unsafe_set(i, self.data_value.unsafe_get(i))
  }
  self.data_value = data
}

///|
pub fn[T] BapVector::append(self : BapVector[T], value : T) -> Unit {
  if self.data_value.length() == self.size_value {
    self.resize()
  }
  self.data_value.unsafe_set(self.size_value, value)
  self.size_value = self.size_value + 1
}

///|
pub fn[T] BapVector::length(self : BapVector[T]) -> Int {
  self.size_value
}

///|
pub fn[T] BapVector::is_empty(self : BapVector[T]) -> Bool {
  self.size_value == 0
}

///|
pub fn[T] BapVector::capacity(self : BapVector[T]) -> Int {
  self.data_value.length()
}

///|
pub fn[T] BapVector::to_array(self : BapVector[T]) -> Array[T] {
  self.data_value[0:self.size_value].to_owned()
}

///|
pub fn[T] BapVector::nth(self : BapVector[T], index : Int) -> T? {
  if index >= 0 && index < self.size_value {
    Some(self.data_value.unsafe_get(index))
  } else {
    None
  }
}

///|
pub fn[T] BapVector::get(self : BapVector[T], index : Int) -> T {
  match self.nth(index) {
    Some(value) => value
    None => abort("Index out of bounds")
  }
}

///|
pub fn[T] BapVector::set(self : BapVector[T], index : Int, value : T) -> Unit {
  if index >= 0 && index < self.size_value {
    self.data_value.unsafe_set(index, value)
  } else {
    abort("Index out of bounds")
  }
}

///|
pub fn[A, B] BapVector::map_to_array(
  self : BapVector[A],
  f : (A) -> B,
) -> Array[B] {
  Array::makei(self.size_value, i => f(self.data_value.unsafe_get(i)))
}

///|
pub fn[T] BapVector::iteri(self : BapVector[T], f : (Int, T) -> Unit) -> Unit {
  for i in 0..<self.size_value {
    f(i, self.data_value.unsafe_get(i))
  }
}

///|
pub fn[T, A] BapVector::foldi(
  self : BapVector[T],
  init : A,
  f : (Int, A, T) -> A,
) -> A {
  let mut acc = init
  for i in 0..<self.size_value {
    acc = f(i, acc, self.data_value.unsafe_get(i))
  }
  acc
}

///|
pub fn[T, A] BapVector::fold(
  self : BapVector[T],
  init : A,
  f : (A, T) -> A,
) -> A {
  self.foldi(init, (_, acc, value) => f(acc, value))
}

///|
pub fn[T] BapVector::findi(
  self : BapVector[T],
  f : (Int, T) -> Bool,
) -> (Int, T)? {
  for i in 0..<self.size_value {
    let value = self.data_value.unsafe_get(i)
    if f(i, value) {
      return Some((i, value))
    }
  }
  None
}

///|
pub fn[T] BapVector::find(self : BapVector[T], f : (T) -> Bool) -> T? {
  match self.findi((_, value) => f(value)) {
    Some((_, value)) => Some(value)
    None => None
  }
}

///|
pub fn[T, A] BapVector::find_map(self : BapVector[T], f : (T) -> A?) -> A? {
  for i in 0..<self.size_value {
    match f(self.data_value.unsafe_get(i)) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
pub fn[T] BapVector::exists(self : BapVector[T], f : (T) -> Bool) -> Bool {
  self.find(f) is Some(_)
}

///|
pub fn[T] BapVector::for_all(self : BapVector[T], f : (T) -> Bool) -> Bool {
  for i in 0..<self.size_value {
    if !f(self.data_value.unsafe_get(i)) {
      return false
    }
  }
  true
}

///|
pub fn[T] BapVector::count(self : BapVector[T], f : (T) -> Bool) -> Int {
  let mut total = 0
  for i in 0..<self.size_value {
    if f(self.data_value.unsafe_get(i)) {
      total = total + 1
    }
  }
  total
}

///|
pub fn[T] BapVector::index_with_by(
  self : BapVector[T],
  value : T,
  default~ : Int,
  equal : (T, T) -> Bool,
) -> Int {
  for i in 0..<self.size_value {
    if equal(value, self.data_value.unsafe_get(i)) {
      return i
    }
  }
  default
}

///|
pub fn[T : Eq] BapVector::index_with(
  self : BapVector[T],
  value : T,
  default~ : Int,
) -> Int {
  self.index_with_by(value, default~, (left, right) => left == right)
}

///|
pub fn[T : Eq] BapVector::index(self : BapVector[T], value : T) -> Int? {
  let index = self.index_with(value, default=-1)
  if index < 0 {
    None
  } else {
    Some(index)
  }
}

///|
pub fn[T : Eq] BapVector::index_exn(self : BapVector[T], value : T) -> Int {
  match self.index(value) {
    Some(index) => index
    None => abort("index out of bounds")
  }
}

///|
pub fn[T : Eq] BapVector::contains(self : BapVector[T], value : T) -> Bool {
  self.index(value) is Some(_)
}

///|
pub fn[T] BapVector::to_string(
  self : BapVector[T],
  render : (T) -> String,
) -> String {
  let parts = self.map_to_array(render)
  "{" + parts.join("; ") + "}"
}
