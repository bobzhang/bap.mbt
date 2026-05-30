///|
pub(all) struct FormatInfo {
  name : String
  version : String
  description : String?
} derive(Eq, Debug)

///|
pub fn FormatInfo::new(
  name~ : String,
  version~ : String,
  description? : String,
) -> FormatInfo {
  { name, version, description }
}

///|
pub fn FormatInfo::to_string(self : FormatInfo) -> String {
  match self.description {
    Some(desc) => "\{self.name}@\{self.version}: \{desc}"
    None => "\{self.name}@\{self.version}"
  }
}

///|
pub impl Printable for FormatInfo with fn to_string(self) {
  self.to_string()
}

///|
struct FormatRegistry {
  readers : Array[FormatInfo]
  writers : Array[FormatInfo]
} derive(Debug)

///|
pub fn FormatRegistry::new() -> FormatRegistry {
  { readers: [], writers: [] }
}

///|
pub fn FormatRegistry::add_reader(
  self : FormatRegistry,
  info : FormatInfo,
) -> Unit {
  self.readers.push(info)
}

///|
pub fn FormatRegistry::add_writer(
  self : FormatRegistry,
  info : FormatInfo,
) -> Unit {
  self.writers.push(info)
}

///|
pub fn FormatRegistry::readers(self : FormatRegistry) -> Array[FormatInfo] {
  self.readers.copy()
}

///|
pub fn FormatRegistry::writers(self : FormatRegistry) -> Array[FormatInfo] {
  self.writers.copy()
}

///|
pub fn FormatRegistry::default_reader(self : FormatRegistry) -> FormatInfo? {
  self.readers.get(0)
}

///|
pub fn FormatRegistry::default_writer(self : FormatRegistry) -> FormatInfo? {
  self.writers.get(0)
}

///|
pub fn FormatRegistry::find_reader(
  self : FormatRegistry,
  name : StringView,
  version? : String,
) -> FormatInfo? {
  self.readers
  .search_by(info => {
    name.equal_to_string(info.name) &&
    (version is None || Some(info.version) == version)
  })
  .map(i => self.readers[i])
}

///|
pub fn FormatRegistry::find_writer(
  self : FormatRegistry,
  name : StringView,
  version? : String,
) -> FormatInfo? {
  self.writers
  .search_by(info => {
    name.equal_to_string(info.name) &&
    (version is None || Some(info.version) == version)
  })
  .map(i => self.writers[i])
}
