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
    match value {
      "true" => Ok(true)
      "false" => Ok(false)
      _ => Err("can't decode project bool tag \{name}")
    }
  })
}

///|
pub fn ProjectStorageTag::int(name : String) -> ProjectStorageTag[Int] {
  ProjectStorageTag::create(name~, encode=value => value.to_string(), decode=value => {
    try @string.parse_int(value) catch {
      _ => Err("can't decode project int tag \{name}")
    } noraise {
      parsed => Ok(parsed)
    }
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
