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
  { encode_fn: to_string, decode_fn: of_string, }
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
pub fn Persistent::int() -> Persistent[Int] {
  Persistent::create(to_string=value => value.to_string(), of_string=input => {
    try @string.parse_int(input) catch {
      _ => Err("invalid persistent int")
    } noraise {
      value => Ok(value)
    }
  })
}

///|
pub fn Persistent::bool() -> Persistent[Bool] {
  Persistent::create(to_string=value => value.to_string(), of_string=input => {
    match input {
      "true" => Ok(true)
      "false" => Ok(false)
      _ => Err("invalid persistent bool")
    }
  })
}

///|
pub fn Persistent::bytes() -> Persistent[Bytes] {
  Persistent::create(to_string=bytes => @regular.bytes_to_hex(bytes), of_string=input => {
    @regular.bytes_from_hex(input[:])
  })
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
    let (encoded, next) = match
      persistent_decode_chunk(input, offset, "array") {
      Ok(chunk) => chunk
      Err(reason) => return Err(reason)
    }
    match element.decode(encoded) {
      Ok(value) => values.push(value)
      Err(reason) => return Err(reason)
    }
    offset = next
  }
  Ok(values)
}

///|
fn persistent_decode_chunk(
  input : String,
  offset : Int,
  context : String,
) -> Result[(String, Int), String] {
  let mut separator = -1
  let mut cursor = offset
  while cursor < input.length() && separator < 0 {
    if input[cursor] == ':' {
      separator = cursor
    }
    cursor = cursor + 1
  }
  if separator < 0 {
    return Err(
      "invalid persistent \{context} encoding: missing length separator",
    )
  }
  let length = try @string.parse_int(input[offset:separator]) catch {
    _ => return Err("invalid persistent \{context} encoding: invalid length")
  } noraise {
    value => value
  }
  if length < 0 {
    return Err("invalid persistent \{context} encoding: negative length")
  }
  let start = separator + 1
  let end = start + length
  if end > input.length() {
    return Err("invalid persistent \{context} encoding: truncated element")
  }
  Ok((input[start:end].to_owned(), end))
}

///|
pub fn[T] Persistent::optional(element : Persistent[T]) -> Persistent[T?] {
  Persistent::create(
    to_string=value => {
      match value {
        None => "4:none"
        Some(item) => {
          let encoded = element.encode(item)
          "4:some\{encoded.length()}:\{encoded}"
        }
      }
    },
    of_string=input => {
      let (tag, offset) = match persistent_decode_chunk(input, 0, "optional") {
        Ok(chunk) => chunk
        Err(reason) => return Err(reason)
      }
      match tag {
        "none" =>
          if offset == input.length() {
            Ok(None)
          } else {
            Err("invalid persistent optional encoding: trailing data")
          }
        "some" => {
          let (encoded, end) = match
            persistent_decode_chunk(input, offset, "optional") {
            Ok(chunk) => chunk
            Err(reason) => return Err(reason)
          }
          if end != input.length() {
            return Err("invalid persistent optional encoding: trailing data")
          }
          match element.decode(encoded) {
            Ok(value) => Ok(Some(value))
            Err(reason) => Err(reason)
          }
        }
        _ => Err("invalid persistent optional encoding: invalid tag")
      }
    },
  )
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

///|
pub fn[T] Persistent::list(
  element : Persistent[T],
) -> Persistent[@list.List[T]] {
  Persistent::convert(
    to_persistent=(values : @list.List[T]) => values.to_array(),
    of_persistent=(values : Array[T]) => Ok(@list.List(values)),
    Persistent::array(element),
  )
}

///|
pub fn[K : Eq + Hash, V] Persistent::map(
  key : Persistent[K],
  value : Persistent[V],
) -> Persistent[Map[K, V]] {
  Persistent::create(
    to_string=values => {
      let entries = []
      for entry in values {
        entries.push((key.encode(entry.0), value.encode(entry.1)))
      }
      entries.sort_by((left, right) => left.0.compare(right.0))
      let parts = []
      for entry in entries {
        parts.push(
          "\{entry.0.length()}:\{entry.0}\{entry.1.length()}:\{entry.1}",
        )
      }
      parts.join("")
    },
    of_string=input => {
      let result : Map[K, V] = Map([])
      let mut offset = 0
      while offset < input.length() {
        let (encoded_key, after_key) = match
          persistent_decode_chunk(input, offset, "map") {
          Ok(chunk) => chunk
          Err(reason) => return Err(reason)
        }
        let (encoded_value, after_value) = match
          persistent_decode_chunk(input, after_key, "map") {
          Ok(chunk) => chunk
          Err(reason) => return Err(reason)
        }
        let decoded_key = match key.decode(encoded_key) {
          Ok(decoded) => decoded
          Err(reason) => return Err(reason)
        }
        if result.contains(decoded_key) {
          return Err("invalid persistent map encoding: duplicate key")
        }
        match value.decode(encoded_value) {
          Ok(decoded_value) => result[decoded_key] = decoded_value
          Err(reason) => return Err(reason)
        }
        offset = after_value
      }
      Ok(result)
    },
  )
}

///|
pub fn[T : Eq + Hash] Persistent::set(
  element : Persistent[T],
) -> Persistent[Set[T]] {
  Persistent::create(
    to_string=values => {
      let encoded_values = []
      for item in values {
        encoded_values.push(element.encode(item))
      }
      encoded_values.sort_by((left, right) => left.compare(right))
      let parts = []
      for encoded in encoded_values {
        parts.push("\{encoded.length()}:\{encoded}")
      }
      parts.join("")
    },
    of_string=input => {
      let result : Set[T] = Set([])
      let mut offset = 0
      while offset < input.length() {
        let (encoded, next) = match
          persistent_decode_chunk(input, offset, "set") {
          Ok(chunk) => chunk
          Err(reason) => return Err(reason)
        }
        match element.decode(encoded) {
          Ok(item) => result.add(item)
          Err(reason) => return Err(reason)
        }
        offset = next
      }
      Ok(result)
    },
  )
}
