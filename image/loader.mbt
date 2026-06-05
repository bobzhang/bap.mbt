///|
struct ImageLoader {
  from_data_fn : (Bytes) -> Result[OgreDoc?, String]
  from_file_fn : ((String) -> Result[OgreDoc?, String])?
}

///|
let image_loader_registry : Map[String, ImageLoader] = {}

///|
pub(all) struct KB {}

///|
pub fn ImageLoader::create(
  from_data~ : (Bytes) -> Result[OgreDoc?, String],
  from_file? : (String) -> Result[OgreDoc?, String],
) -> ImageLoader {
  { from_data_fn: from_data, from_file_fn: from_file }
}

///|
pub fn ImageLoader::from_data(
  self : ImageLoader,
  data : Bytes,
) -> Result[OgreDoc?, String] {
  (self.from_data_fn)(data)
}

///|
pub fn ImageLoader::from_file(
  self : ImageLoader,
  path : String,
) -> Result[OgreDoc?, String] {
  match self.from_file_fn {
    Some(load) => load(path)
    None =>
      match @native_io.read_file(path) {
        Ok(data) => self.from_data(data)
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn register_loader(
  name~ : String,
  loader : ImageLoader,
) -> Result[Unit, String] {
  if image_loader_registry.contains(name) || find_backend(name) is Some(_) {
    Err("image loader \{name} is already registered")
  } else {
    image_loader_registry[name] = loader
    Ok(())
  }
}

///|
pub fn KB::register_loader(
  name~ : String,
  from_file~ : (String) -> Result[OgreDoc?, String],
  from_data~ : (Bytes) -> Result[OgreDoc?, String],
) -> Result[Unit, String] {
  register_loader(name~, ImageLoader::create(from_data~, from_file~))
}

///|
pub fn find_loader(name : String) -> ImageLoader? {
  image_loader_registry.get(name)
}

///|
pub fn available_loaders() -> Array[String] {
  let names = []
  image_loader_registry.each((name, _) => names.push(name))
  names
}

///|
fn Image::of_bytes_with_loader(
  data : Bytes,
  name : String,
  loader : ImageLoader,
) -> Result[(Image, Array[String]), String] {
  match loader.from_data(data) {
    Ok(Some(doc)) => Image::from_spec(data, doc)
    Ok(None) => Err("image loader \{name} didn't provide an Ogre document")
    Err(reason) => Err(reason)
  }
}

///|
fn Image::of_file_with_loader(
  path : String,
  name : String,
  loader : ImageLoader,
) -> Result[(Image, Array[String]), String] {
  match @native_io.read_file(path) {
    Err(reason) => Err(reason)
    Ok(data) =>
      match loader.from_file(path) {
        Ok(Some(doc)) => Image::from_spec(data, doc, filename=path)
        Ok(None) => Err("image loader \{name} didn't provide an Ogre document")
        Err(reason) => Err(reason)
      }
  }
}
