///|
fn mkdir(path : String) -> Result[Unit, String] {
  Err("file IO is only available on the native target: \{path}")
}

///|
fn getcwd() -> Result[String, String] {
  Err("file IO is only available on the native target")
}
