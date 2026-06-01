///|
struct Persistent[T] {
  encode_fn : (T) -> String
  decode_fn : (String) -> Result[T, String]
}

///|
pub fn[T] Persistent::create(
  to_string~ : (T) -> String,
  of_string~ : (String) -> Result[T, String],
) -> Persistent[T] {
  { encode_fn: to_string, decode_fn: of_string }
}

///|
pub fn[T] Persistent::encode(self : Persistent[T], value : T) -> String {
  (self.encode_fn)(value)
}

///|
pub fn[T] Persistent::decode(
  self : Persistent[T],
  input : String,
) -> Result[T, String] {
  (self.decode_fn)(input)
}

///|
pub fn[A, B] Persistent::convert(
  to_persistent~ : (A) -> B,
  of_persistent~ : (B) -> Result[A, String],
  base : Persistent[B],
) -> Persistent[A] {
  Persistent::create(to_string=value => base.encode(to_persistent(value)), of_string=input => {
    match base.decode(input) {
      Ok(value) => of_persistent(value)
      Err(reason) => Err(reason)
    }
  })
}

///|
pub fn Persistent::string() -> Persistent[String] {
  Persistent::create(to_string=value => value, of_string=input => Ok(input))
}

///|
pub fn Persistent::name() -> Persistent[Name] {
  Persistent::create(to_string=name => name.show(), of_string=input => {
    Ok(Name::read(input))
  })
}

///|
fn[T] persistent_decode_array(
  element : Persistent[T],
  input : String,
) -> Result[Array[T], String] {
  let values = []
  let mut offset = 0
  while offset < input.length() {
    let mut separator = -1
    let mut cursor = offset
    while cursor < input.length() && separator < 0 {
      if input[cursor] == ':' {
        separator = cursor
      }
      cursor = cursor + 1
    }
    if separator < 0 {
      return Err("invalid persistent array encoding: missing length separator")
    }
    let length = try @string.parse_int(input[offset:separator]) catch {
      _ => return Err("invalid persistent array encoding: invalid length")
    } noraise {
      value => value
    }
    if length < 0 {
      return Err("invalid persistent array encoding: negative length")
    }
    let start = separator + 1
    let end = start + length
    if end > input.length() {
      return Err("invalid persistent array encoding: truncated element")
    }
    match element.decode(input[start:end].to_owned()) {
      Ok(value) => values.push(value)
      Err(reason) => return Err(reason)
    }
    offset = end
  }
  Ok(values)
}

///|
pub fn[T] Persistent::array(element : Persistent[T]) -> Persistent[Array[T]] {
  Persistent::create(
    to_string=values => {
      let parts = []
      for value in values {
        let encoded = element.encode(value)
        parts.push("\{encoded.length()}:\{encoded}")
      }
      parts.join("")
    },
    of_string=input => persistent_decode_array(element, input),
  )
}
