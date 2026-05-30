///|
struct ImageBackend {
  name_value : String
  load_fn : (Bytes) -> Result[(Image, Array[String]), String]
}

///|
let backend_registry : Map[String, ImageBackend] = {}

///|
pub fn ImageBackend::create(
  name~ : String,
  load~ : (Bytes) -> Result[(Image, Array[String]), String],
) -> ImageBackend {
  { name_value: name, load_fn: load }
}

///|
pub fn ImageBackend::name(self : ImageBackend) -> String {
  self.name_value
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
