///|
fn ProjectInput::with_default_filename(
  self : ProjectInput,
  filename : String,
) -> ProjectInput {
  match self.filename_value {
    Some(_) => self
    None => { ..self, filename_value: Some(filename) }
  }
}

///|
fn project_raw_endian(target : @core_theory.Target) -> @bitvec.Endian {
  match target.endianness() {
    BigEndian => BigEndian
    _ => LittleEndian
  }
}

///|
pub fn ProjectInput::raw_file(
  path : String,
  target~ : @core_theory.Target,
  base? : UInt64 = 0UL,
  filename? : String,
) -> Result[ProjectInput, String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) =>
      ProjectInput::raw_bytes(target~, data, base~, filename=selected_filename)
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectInput::load_file(
  path : String,
  loader~ : String,
) -> Result[ProjectInput, String] {
  match @native_io.read_file(path) {
    Ok(data) =>
      match ProjectInput::load(data, loader~) {
        Ok(input) => Ok(input.with_default_filename(path))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectInput::load_file_for_filename(
  path : String,
  filename? : String,
) -> Result[ProjectInput, String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) =>
      match ProjectInput::load_for_filename(data, filename=selected_filename) {
        Ok(input) => Ok(input.with_default_filename(selected_filename))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}
