///|
pub fn[T] seq_of_array(values : ArrayView[T]) -> Array[T] {
  let out = []
  for value in values {
    out.push(value)
  }
  out
}

///|
pub fn[T] seq_of_list(values : @list.List[T]) -> Array[T] {
  values.to_array()
}

///|
pub fn[T] seq_empty() -> Array[T] {
  []
}

///|
pub fn[T] seq_singleton(value : T) -> Array[T] {
  [value]
}

///|
pub fn[T] seq_return(value : T) -> Array[T] {
  seq_singleton(value)
}

///|
pub fn[T] seq_init(length : Int, f : (Int) -> T) -> Array[T] {
  let out = []
  for i in 0..<length {
    out.push(f(i))
  }
  out
}

///|
pub fn seq_range(
  start : Int,
  stop : Int,
  inclusive? : Bool = false,
) -> Array[Int] {
  let out = []
  if inclusive {
    if start > stop {
      return out
    }
    let mut value = start
    while true {
      out.push(value)
      if value == stop {
        return out
      }
      value = value + 1
    }
  } else {
    let mut value = start
    while value < stop {
      out.push(value)
      value = value + 1
    }
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
pub fn[T] seq_length(values : ArrayView[T]) -> Int {
  values.length()
}

///|
pub fn[T] seq_hd(values : ArrayView[T]) -> T? {
  values.get(0)
}

///|
pub fn[T] seq_tl(values : ArrayView[T]) -> Array[T]? {
  if values.length() == 0 {
    None
  } else {
    Some(seq_drop(values, 1))
  }
}

///|
pub fn[T] seq_next(values : ArrayView[T]) -> (T, Array[T])? {
  match seq_hd(values) {
    Some(head) => Some((head, seq_drop(values, 1)))
    None => None
  }
}

///|
pub fn[T] seq_nth(values : ArrayView[T], index : Int) -> T? {
  if index < 0 {
    None
  } else {
    values.get(index)
  }
}

///|
pub fn[T] seq_last(values : ArrayView[T]) -> T? {
  values.last()
}

///|
pub fn[T] seq_take(values : ArrayView[T], n : Int) -> Array[T] {
  let limit = if n <= 0 {
    0
  } else if n > values.length() {
    values.length()
  } else {
    n
  }
  let out = []
  for i in 0..<limit {
    out.push(values[i])
  }
  out
}

///|
pub fn[T] seq_drop(values : ArrayView[T], n : Int) -> Array[T] {
  let start = if n <= 0 {
    0
  } else if n > values.length() {
    values.length()
  } else {
    n
  }
  let out = []
  for i in start..<values.length() {
    out.push(values[i])
  }
  out
}

///|
pub fn[T] seq_drop_eagerly(values : ArrayView[T], n : Int) -> Array[T] {
  seq_drop(values, n)
}

///|
pub fn[T] seq_split_n(values : ArrayView[T], n : Int) -> (Array[T], Array[T]) {
  (seq_take(values, n), seq_drop(values, n))
}

///|
pub fn[T] seq_take_while(values : ArrayView[T], f : (T) -> Bool) -> Array[T] {
  let out = []
  for value in values {
    if !f(value) {
      return out
    }
    out.push(value)
  }
  out
}

///|
pub fn[T] seq_drop_while(values : ArrayView[T], f : (T) -> Bool) -> Array[T] {
  let mut start = 0
  while start < values.length() && f(values[start]) {
    start = start + 1
  }
  seq_drop(values, start)
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
pub fn[A, B] seq_filter_map(values : ArrayView[A], f : (A) -> B?) -> Array[B] {
  let out = []
  for value in values {
    match f(value) {
      Some(mapped) => out.push(mapped)
      None => ()
    }
  }
  out
}

///|
pub fn[A, B] seq_filter_mapi(
  values : ArrayView[A],
  f : (Int, A) -> B?,
) -> Array[B] {
  let out = []
  for i, value in values {
    match f(i, value) {
      Some(mapped) => out.push(mapped)
      None => ()
    }
  }
  out
}

///|
pub fn[T] seq_filter_opt(values : ArrayView[T?]) -> Array[T] {
  let out = []
  for value in values {
    match value {
      Some(inner) => out.push(inner)
      None => ()
    }
  }
  out
}

///|
pub fn[A, B] seq_concat_map(
  values : ArrayView[A],
  f : (A) -> Array[B],
) -> Array[B] {
  let out = []
  for value in values {
    for mapped in f(value) {
      out.push(mapped)
    }
  }
  out
}

///|
pub fn[A, B] seq_concat_mapi(
  values : ArrayView[A],
  f : (Int, A) -> Array[B],
) -> Array[B] {
  let out = []
  for i, value in values {
    for mapped in f(i, value) {
      out.push(mapped)
    }
  }
  out
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
pub fn[A, B] seq_foldi(
  values : ArrayView[A],
  init : B,
  f : (Int, B, A) -> B,
) -> B {
  let mut acc = init
  for i, value in values {
    acc = f(i, acc, value)
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
pub fn[T] seq_iteri(values : ArrayView[T], f : (Int, T) -> Unit) -> Unit {
  for i, value in values {
    f(i, value)
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
pub fn[A, B] seq_find_map(values : ArrayView[A], f : (A) -> B?) -> B? {
  for value in values {
    match f(value) {
      Some(mapped) => return Some(mapped)
      None => ()
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
pub fn[T] seq_to_array(values : ArrayView[T]) -> Array[T] {
  seq_of_array(values)
}

///|
pub fn[T] seq_rev(values : ArrayView[T]) -> Array[T] {
  let out = []
  let mut i = values.length() - 1
  while i >= 0 {
    out.push(values[i])
    if i == 0 {
      return out
    }
    i = i - 1
  }
  out
}

///|
pub fn[T] seq_to_list_rev(values : ArrayView[T]) -> @list.List[T] {
  @list.from_array(seq_rev(values))
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
