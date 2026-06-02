///|
pub fn[T] seq_of_array(values : ArrayView[T]) -> Array[T] {
  let out = []
  for value in values {
    out.push(value)
  }
  out
}

///|
pub fn[T] seq_cons(value : T, values : ArrayView[T]) -> Array[T] {
  let out = [value]
  for item in values {
    out.push(item)
  }
  out
}

///|
pub fn[T] seq_append(left : ArrayView[T], right : ArrayView[T]) -> Array[T] {
  let out = []
  for value in left {
    out.push(value)
  }
  for value in right {
    out.push(value)
  }
  out
}

///|
pub fn[T] seq_concat(chunks : ArrayView[Array[T]]) -> Array[T] {
  let out = []
  for chunk in chunks {
    for value in chunk {
      out.push(value)
    }
  }
  out
}

///|
pub fn[T] seq_is_empty(values : ArrayView[T]) -> Bool {
  values.length() == 0
}

///|
pub fn[A, B] seq_map(values : ArrayView[A], f : (A) -> B) -> Array[B] {
  let out = []
  for value in values {
    out.push(f(value))
  }
  out
}

///|
pub fn[A, B] seq_mapi(values : ArrayView[A], f : (Int, A) -> B) -> Array[B] {
  Array::makei(values.length(), i => f(i, values[i]))
}

///|
pub fn[T] seq_filter(values : ArrayView[T], f : (T) -> Bool) -> Array[T] {
  let out = []
  for value in values {
    if f(value) {
      out.push(value)
    }
  }
  out
}

///|
pub fn[A, B] seq_fold(values : ArrayView[A], init : B, f : (B, A) -> B) -> B {
  let mut acc = init
  for value in values {
    acc = f(acc, value)
  }
  acc
}

///|
pub fn[T] seq_iter(values : ArrayView[T], f : (T) -> Unit) -> Unit {
  for value in values {
    f(value)
  }
}

///|
pub fn[T] seq_find(values : ArrayView[T], f : (T) -> Bool) -> T? {
  for value in values {
    if f(value) {
      return Some(value)
    }
  }
  None
}

///|
pub fn[T] seq_exists(values : ArrayView[T], f : (T) -> Bool) -> Bool {
  seq_find(values, f) is Some(_)
}

///|
pub fn[T] seq_for_all(values : ArrayView[T], f : (T) -> Bool) -> Bool {
  for value in values {
    if !f(value) {
      return false
    }
  }
  true
}

///|
pub fn[T] seq_to_list(values : ArrayView[T]) -> @list.List[T] {
  @list.from_array(seq_of_array(values))
}

///|
pub fn[A, B] seq_compare(
  compare : (A, B) -> Int,
  left : ArrayView[A],
  right : ArrayView[B],
) -> Int {
  let limit = left.length().min(right.length())
  for i in 0..<limit {
    let order = compare(left[i], right[i])
    if order != 0 {
      return order
    }
  }
  if left.length() > right.length() {
    1
  } else if left.length() < right.length() {
    -1
  } else {
    0
  }
}

///|
pub fn[T : Printable] seq_render(
  values : ArrayView[T],
  max? : Int = -1,
) -> String {
  let out = StringBuilder()
  out.write_string("{")
  let limit = if max < 0 || max > values.length() {
    values.length()
  } else {
    max
  }
  for i in 0..<limit {
    if i > 0 {
      out.write_string(", ")
    }
    out.write_string(values[i].to_string())
  }
  if limit < values.length() {
    if limit > 0 {
      out.write_string(", ")
    }
    out.write_string("...")
  }
  out.write_string("}")
  out.to_string()
}
