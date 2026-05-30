///|
struct ImageBackend {
  name_value : String
  description_value : String
  extensions_value : Array[String]
  priority_value : Int
  load_fn : (Bytes) -> Result[(Image, Array[String]), String]
}

///|
let backend_registry : Map[String, ImageBackend] = {}

///|
pub fn ImageBackend::create(
  name~ : String,
  description? : String,
  extensions? : Array[String],
  priority? : Int,
  load~ : (Bytes) -> Result[(Image, Array[String]), String],
) -> ImageBackend {
  {
    name_value: name,
    description_value: match description {
      Some(text) => text
      None => ""
    },
    extensions_value: match extensions {
      Some(items) => items.copy()
      None => []
    },
    priority_value: match priority {
      Some(value) => value
      None => 0
    },
    load_fn: load,
  }
}

///|
pub fn ImageBackend::name(self : ImageBackend) -> String {
  self.name_value
}

///|
pub fn ImageBackend::description(self : ImageBackend) -> String {
  self.description_value
}

///|
pub fn ImageBackend::extensions(self : ImageBackend) -> Array[String] {
  self.extensions_value.copy()
}

///|
pub fn ImageBackend::priority(self : ImageBackend) -> Int {
  self.priority_value
}

///|
pub fn ImageBackend::supports_extension(
  self : ImageBackend,
  extension : String,
) -> Bool {
  self.extensions_value.any(item => item == extension)
}

///|
pub fn ImageBackend::load(
  self : ImageBackend,
  data : Bytes,
) -> Result[(Image, Array[String]), String] {
  (self.load_fn)(data)
}

///|
pub fn register_backend(
  name~ : String,
  backend : ImageBackend,
) -> Result[Unit, String] {
  if backend_registry.contains(name) {
    Err("image backend \{name} is already registered")
  } else {
    backend_registry[name] = backend
    Ok(())
  }
}

///|
pub fn find_backend(name : String) -> ImageBackend? {
  backend_registry.get(name)
}

///|
pub fn available_backends() -> Array[String] {
  let names = []
  backend_registry.each((name, _) => names.push(name))
  names
}

///|
pub fn backends_for_extension(extension : String) -> Array[ImageBackend] {
  let result = []
  backend_registry.each((_, backend) => {
    if backend.supports_extension(extension) {
      result.push(backend)
    }
  })
  result.sort_by((left, right) => right.priority().compare(left.priority()))
  result
}

///|
pub fn backend_names_for_extension(extension : String) -> Array[String] {
  backends_for_extension(extension).map(backend => backend.name())
}
