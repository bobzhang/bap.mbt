///|
pub fn Memory::of_file(
  endian~ : @bitvec.Endian,
  start~ : UInt64,
  path : String,
) -> Result[Memory, String] {
  match @native_io.read_file(path) {
    Ok(data) => Memory::create(endian~, start~, data)
    Err(reason) => Err(reason)
  }
}
