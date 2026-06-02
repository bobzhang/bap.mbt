///|
pub fn Image::of_file(
  path : String,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  match backend {
    Some(name) =>
      match find_backend(name) {
        Some(_) =>
          match @native_io.read_file(path) {
            Ok(data) => Image::of_bytes(data, backend=name)
            Err(reason) => Err(reason)
          }
        None =>
          match find_loader(name) {
            Some(loader) => Image::of_file_with_loader(path, name, loader)
            None => Err("unknown image backend or loader \{name}")
          }
      }
    None =>
      match @native_io.read_file(path) {
        Ok(data) => Image::of_bytes(data)
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn Image::of_file_for_filename(
  path : String,
  filename? : String,
) -> Result[(Image, Array[String]), String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) => Image::of_bytes_for_filename(data, filename=selected_filename)
    Err(reason) => Err(reason)
  }
}
