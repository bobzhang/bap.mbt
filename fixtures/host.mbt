///|
/// Creates a fresh temporary directory (in `$TMPDIR` or `/tmp`) holding
/// the ELF fixture as `true.elf` on the host file system (native target
/// only). Returns the directory.
pub fn host_temp_dir_with_elf() -> String raise {
  let tmp = match @env.get_env_var("TMPDIR") {
    Some(dir) if dir != "" => dir
    _ => "/tmp"
  }
  match @native_io.make_temp_dir(dir=tmp, prefix="bap-fixture-") {
    Err(msg) => fail(msg)
    Ok(dir) =>
      match @native_io.write_file(dir + "/true.elf", x86_64_elf()) {
        Err(msg) => fail(msg)
        Ok(_) => dir
      }
  }
}

///|
/// Reads a file of the host file system.
pub fn host_read_file(path : String) -> Bytes raise {
  match @native_io.read_file(path) {
    Ok(bytes) => bytes
    Err(msg) => fail(msg)
  }
}

///|
/// Removes the directory created by `host_temp_dir_with_elf`.
pub fn host_remove_dir(dir : String) -> Unit {
  @native_io.remove_tree(dir) |> ignore
}
