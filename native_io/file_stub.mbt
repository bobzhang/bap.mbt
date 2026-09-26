///|
pub fn read_file(path : String) -> Result[Bytes, String] {
  Err("file IO is only available on the native target: \{path}")
}

///|
pub fn write_file(path : String, _data : BytesView) -> Result[Unit, String] {
  Err("file IO is only available on the native target: \{path}")
}

///|
/// The architecture of the host; unknown outside of the native target.
pub fn host_architecture() -> String {
  "unknown"
}
