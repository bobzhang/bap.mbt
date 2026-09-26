///|
fn unsupported(path : String) -> String {
  "file IO is only available on the native target: \{path}"
}

///|
pub fn stat(path : String) -> Result[FileStat, String] {
  Err(unsupported(path))
}

///|
pub fn lstat(path : String) -> Result[FileStat, String] {
  Err(unsupported(path))
}

///|
pub fn read_dir(path : String) -> Result[Array[String], String] {
  Err(unsupported(path))
}

///|
pub fn mkdir(path : String, perm? : Int = 0o777) -> Result[Unit, String] {
  ignore(perm)
  Err(unsupported(path))
}

///|
pub fn remove_dir(path : String) -> Result[Unit, String] {
  Err(unsupported(path))
}

///|
pub fn remove_file(path : String) -> Result[Unit, String] {
  Err(unsupported(path))
}

///|
pub fn rename(src : String, dst : String) -> Result[Unit, String] {
  ignore(dst)
  Err(unsupported(src))
}

///|
pub fn chmod(path : String, perm : Int) -> Result[Unit, String] {
  ignore(perm)
  Err(unsupported(path))
}

///|
pub fn getcwd() -> Result[String, String] {
  Err(unsupported("."))
}

///|
pub fn make_temp_file(
  dir~ : String,
  prefix? : String = "tmp",
) -> Result[String, String] {
  Err(unsupported(join_path(dir, prefix)))
}

///|
pub fn make_temp_dir(
  dir~ : String,
  prefix? : String = "tmp",
) -> Result[String, String] {
  Err(unsupported(join_path(dir, prefix)))
}

///|
pub fn lock_file(
  path : String,
  exclusive? : Bool = true,
  blocking? : Bool = true,
) -> Result[FileLock, String] {
  ignore((exclusive, blocking))
  Err(unsupported(path))
}

///|
pub fn FileLock::unlock(self : FileLock) -> Result[Unit, String] {
  if self.held {
    self.held = false
  }
  ignore(self.fd)
  Ok(())
}
