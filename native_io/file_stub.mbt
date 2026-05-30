///|
pub fn read_file(path : String) -> Result[Bytes, String] {
  Err("file IO is only available on the native target: \{path}")
}
