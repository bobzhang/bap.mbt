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
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
  filename? : String,
) -> Result[ProjectInput, String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) =>
      ProjectInput::raw_bytes(
        target~,
        data,
        base~,
        offset~,
        length?,
        entry?,
        filename=selected_filename,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectInput::binary(
  target~ : @core_theory.Target,
  filename~ : String,
  base? : UInt64 = 0UL,
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
) -> Result[ProjectInput, String] {
  ProjectInput::raw_file(filename, target~, base~, offset~, length?, entry?)
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
pub fn ProjectInput::file(
  filename~ : String,
  loader? : String,
) -> Result[ProjectInput, String] {
  match loader {
    Some(name) => ProjectInput::load_file(filename, loader=name)
    None => ProjectInput::load_file_for_filename(filename)
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
