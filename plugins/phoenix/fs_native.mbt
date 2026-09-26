///|
#borrow(path)
extern "c" fn mkdir_ffi(path : Bytes) -> Int = "bap_mbt_phoenix_mkdir"

///|
extern "c" fn getcwd_ffi() -> Bytes = "bap_mbt_phoenix_getcwd"

///|
/// Creates a directory unless it already exists (upstream
/// `Phoenix_root.mkdir`).
fn mkdir(path : String) -> Result[Unit, String] {
  let bytes = @utf8.encode(path)
  let cstr = Bytes::makei(bytes.length() + 1, i => {
    if i < bytes.length() {
      bytes[i]
    } else {
      0
    }
  })
  match mkdir_ffi(cstr) {
    0 => Ok(())
    1 => Err("target directory is a file: \{path}")
    _ => Err("failed to create directory \{path}")
  }
}

///|
/// The current working directory.
fn getcwd() -> Result[String, String] {
  let bytes = getcwd_ffi()
  if bytes.length() == 0 {
    Err("failed to get the current directory")
  } else {
    Ok(@utf8.decode(bytes)) catch {
      _ => Err("the current directory is not valid UTF-8")
    }
  }
}
