///|
struct ProjectStorageTag[T] {
  name_value : String
  encode_fn : (T) -> String
  decode_fn : (String) -> Result[T, String]
}

///|
pub fn[T] ProjectStorageTag::create(
  name~ : String,
  encode~ : (T) -> String,
  decode~ : (String) -> Result[T, String],
) -> ProjectStorageTag[T] {
  { name_value: name, encode_fn: encode, decode_fn: decode }
}

///|
pub fn ProjectStorageTag::string(name : String) -> ProjectStorageTag[String] {
  ProjectStorageTag::create(name~, encode=value => value, decode=value => {
    Ok(value)
  })
}

///|
pub fn ProjectStorageTag::bool(name : String) -> ProjectStorageTag[Bool] {
  ProjectStorageTag::create(name~, encode=value => value.to_string(), decode=value => {
    decode_project_bool(name, value)
  })
}

///|
fn decode_project_bool(name : String, value : String) -> Result[Bool, String] {
  match value {
    "true" => Ok(true)
    "false" => Ok(false)
    _ => Err("can't decode project bool tag \{name}")
  }
}

///|
pub fn ProjectStorageTag::int(name : String) -> ProjectStorageTag[Int] {
  ProjectStorageTag::create(name~, encode=value => value.to_string(), decode=value => {
    decode_project_int(name, value)
  })
}

///|
fn decode_project_int(name : String, value : String) -> Result[Int, String] {
  try @string.parse_int(value) catch {
    _ => Err("can't decode project int tag \{name}")
  } noraise {
    parsed => Ok(parsed)
  }
}

///|
fn encode_string_array(values : Array[String]) -> String {
  let mut encoded = ""
  for value in values {
    encoded = encoded + value.length().to_string() + ":" + value
  }
  encoded
}

///|
fn decode_string_array(
  name : String,
  value : String,
) -> Result[Array[String], String] {
  let values = []
  let mut pos = 0
  while pos < value.length() {
    let len_start = pos
    while pos < value.length() && value[pos] != ':' {
      pos = pos + 1
    }
    if pos >= value.length() {
      return Err("can't decode project string array tag \{name}")
    }
    let len_text = value[len_start:pos].to_owned()
    let item_len = try @string.parse_int(len_text) catch {
      _ => return Err("can't decode project string array tag \{name}")
    } noraise {
      parsed => parsed
    }
    pos = pos + 1
    if item_len < 0 || pos + item_len > value.length() {
      return Err("can't decode project string array tag \{name}")
    }
    values.push(value[pos:pos + item_len].to_owned())
    pos = pos + item_len
  }
  Ok(values)
}

///|
pub fn ProjectStorageTag::string_array(
  name : String,
) -> ProjectStorageTag[Array[String]] {
  ProjectStorageTag::create(
    name~,
    encode=values => encode_string_array(values),
    decode=value => decode_string_array(name, value),
  )
}

///|
fn encode_int_array(values : Array[Int]) -> String {
  encode_string_array([ for value in values => value.to_string() ])
}

///|
fn decode_int_array(
  name : String,
  value : String,
) -> Result[Array[Int], String] {
  match decode_string_array(name, value) {
    Err(_) => Err("can't decode project int array tag \{name}")
    Ok(items) => {
      let values = []
      for item in items {
        match decode_project_int(name, item) {
          Ok(parsed) => values.push(parsed)
          Err(_) => return Err("can't decode project int array tag \{name}")
        }
      }
      Ok(values)
    }
  }
}

///|
pub fn ProjectStorageTag::int_array(
  name : String,
) -> ProjectStorageTag[Array[Int]] {
  ProjectStorageTag::create(name~, encode=values => encode_int_array(values), decode=value => {
    decode_int_array(name, value)
  })
}

///|
fn encode_bool_array(values : Array[Bool]) -> String {
  encode_string_array([ for value in values => value.to_string() ])
}

///|
fn decode_bool_array(
  name : String,
  value : String,
) -> Result[Array[Bool], String] {
  match decode_string_array(name, value) {
    Err(_) => Err("can't decode project bool array tag \{name}")
    Ok(items) => {
      let values = []
      for item in items {
        match decode_project_bool(name, item) {
          Ok(parsed) => values.push(parsed)
          Err(_) => return Err("can't decode project bool array tag \{name}")
        }
      }
      Ok(values)
    }
  }
}

///|
pub fn ProjectStorageTag::bool_array(
  name : String,
) -> ProjectStorageTag[Array[Bool]] {
  ProjectStorageTag::create(name~, encode=values => encode_bool_array(values), decode=value => {
    decode_bool_array(name, value)
  })
}

///|
pub fn[T] ProjectStorageTag::name(self : ProjectStorageTag[T]) -> String {
  self.name_value
}

///|
pub fn[T] ProjectStorageTag::encode(
  self : ProjectStorageTag[T],
  value : T,
) -> String {
  (self.encode_fn)(value)
}

///|
pub fn[T] ProjectStorageTag::decode(
  self : ProjectStorageTag[T],
  value : String,
) -> Result[T, String] {
  (self.decode_fn)(value)
}

///|
pub fn[T] Project::set_tag(
  self : Project,
  storage_tag : ProjectStorageTag[T],
  value : T,
) -> Project {
  self.set(storage_tag.name(), storage_tag.encode(value))
}

///|
pub fn[T] Project::get_tag(
  self : Project,
  storage_tag : ProjectStorageTag[T],
) -> Result[T?, String] {
  match self.get(storage_tag.name()) {
    Some(value) =>
      match storage_tag.decode(value) {
        Ok(decoded) => Ok(Some(decoded))
        Err(reason) => Err(reason)
      }
    None => Ok(None)
  }
}

///|
pub fn[T] Project::has_tag(
  self : Project,
  storage_tag : ProjectStorageTag[T],
) -> Bool {
  self.has(storage_tag.name())
}

///|
pub fn[T] Project::del_tag(
  self : Project,
  storage_tag : ProjectStorageTag[T],
) -> Project {
  self.del(storage_tag.name())
}
