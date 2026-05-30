///|
pub fn Image::of_file(
  path : String,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  match @native_io.read_file(path) {
    Ok(data) => Image::of_bytes(data, backend?)
    Err(reason) => Err(reason)
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
