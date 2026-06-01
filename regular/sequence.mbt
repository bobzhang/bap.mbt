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
pub fn[T] seq_is_empty(values : ArrayView[T]) -> Bool {
  values.length() == 0
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
