///|
#borrow(path)
extern "c" fn stat_ffi(path : Bytes, follow : Bool) -> Bytes = "bap_mbt_fs_stat"

///|
#borrow(path)
extern "c" fn read_dir_ffi(path : Bytes) -> Bytes = "bap_mbt_fs_read_dir"

///|
#borrow(path)
extern "c" fn mkdir_ffi(path : Bytes, perm : Int32) -> Bytes = "bap_mbt_fs_mkdir"

///|
#borrow(path)
extern "c" fn rmdir_ffi(path : Bytes) -> Bytes = "bap_mbt_fs_rmdir"

///|
#borrow(path)
extern "c" fn remove_ffi(path : Bytes) -> Bytes = "bap_mbt_fs_remove"

///|
#borrow(src, dst)
extern "c" fn rename_ffi(src : Bytes, dst : Bytes) -> Bytes = "bap_mbt_fs_rename"

///|
#borrow(path)
extern "c" fn chmod_ffi(path : Bytes, perm : Int32) -> Bytes = "bap_mbt_fs_chmod"

///|
extern "c" fn getcwd_ffi() -> Bytes = "bap_mbt_fs_getcwd"

///|
#borrow(template)
extern "c" fn mkstemp_ffi(template : Bytes) -> Bytes = "bap_mbt_fs_mkstemp"

///|
#borrow(template)
extern "c" fn mkdtemp_ffi(template : Bytes) -> Bytes = "bap_mbt_fs_mkdtemp"

///|
#borrow(path)
extern "c" fn lock_ffi(
  path : Bytes,
  exclusive : Bool,
  blocking : Bool,
) -> Bytes = "bap_mbt_fs_lock"

///|
extern "c" fn unlock_ffi(fd : Int32) -> Int32 = "bap_mbt_fs_unlock"

///|
fn c_path(path : String) -> Bytes {
  string_to_utf8_bytes(path, true)
}

///|
/// Decodes a tagged response of `fs.c`: the payload on success, the error
/// message on failure.
fn fs_response(response : Bytes) -> Result[BytesView, String] {
  if response.length() == 0 {
    Err("file IO returned an empty response")
  } else if response[0] == 0 {
    Ok(response[1:])
  } else {
    Err(utf8_bytes_to_string(response[1:].to_owned()))
  }
}

///|
fn fs_unit_response(response : Bytes) -> Result[Unit, String] {
  match fs_response(response) {
    Ok(_) => Ok(())
    Err(err) => Err(err)
  }
}

///|
fn fs_string_response(response : Bytes) -> Result[String, String] {
  match fs_response(response) {
    Ok(payload) => Ok(utf8_bytes_to_string(payload.to_owned()))
    Err(err) => Err(err)
  }
}

///|
fn get_i64(data : BytesView, pos : Int32) -> Int64 {
  let mut v : UInt64 = 0
  for i in 0..<8 {
    v = v | (data[pos + i].to_uint64() << (8 * i))
  }
  v.reinterpret_as_int64()
}

///|
fn decode_stat(response : Bytes) -> Result[FileStat, String] {
  match fs_response(response) {
    Ok(p) if p.length() >= 33 => {
      let kind = match p[0] {
        1 => RegularFile
        2 => Directory
        3 => Symlink
        _ => OtherFile
      }
      let mtime = get_i64(p, 9).to_double() + get_i64(p, 17).to_double() / 1.0e9
      Ok({ kind, size: get_i64(p, 1), mtime, perm: get_i64(p, 25).to_int(), })
    }
    Ok(_) => Err("stat returned a malformed response")
    Err(err) => Err(err)
  }
}

///|
/// Information about the entry at `path`, following symbolic links
/// (`stat(2)`).
pub fn stat(path : String) -> Result[FileStat, String] {
  decode_stat(stat_ffi(c_path(path), true))
}

///|
/// Information about the entry at `path`, without following a final
/// symbolic link (`lstat(2)`).
pub fn lstat(path : String) -> Result[FileStat, String] {
  decode_stat(stat_ffi(c_path(path), false))
}

///|
/// The names of the entries of the directory `path` (without `.` and
/// `..`), sorted by code units.
pub fn read_dir(path : String) -> Result[Array[String], String] {
  match fs_response(read_dir_ffi(c_path(path))) {
    Ok(data) => {
      let result = []
      let mut start = 0
      for i in 0..<data.length() {
        if data[i] == 0 {
          if i > start {
            result.push(utf8_bytes_to_string(data[start:i].to_owned()))
          }
          start = i + 1
        }
      }
      sort_names(result)
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

///|
/// Creates the directory `path` (`mkdir(2)`); fails if it already exists
/// or if its parent does not exist (see `mkdir_p`).
pub fn mkdir(path : String, perm~ : Int32 = 0o777) -> Result[Unit, String] {
  fs_unit_response(mkdir_ffi(c_path(path), perm))
}

///|
/// Removes the empty directory `path` (`rmdir(2)`).
pub fn remove_dir(path : String) -> Result[Unit, String] {
  fs_unit_response(rmdir_ffi(c_path(path)))
}

///|
/// Removes the (non-directory) file `path` (`unlink(2)`, OCaml
/// `Sys.remove`).
pub fn remove_file(path : String) -> Result[Unit, String] {
  fs_unit_response(remove_ffi(c_path(path)))
}

///|
/// Renames `src` to `dst`, atomically replacing `dst` if it exists
/// (`rename(2)`, OCaml `Sys.rename`).
pub fn rename(src : String, dst : String) -> Result[Unit, String] {
  fs_unit_response(rename_ffi(c_path(src), c_path(dst)))
}

///|
/// Sets the permission bits of `path` (`chmod(2)`).
pub fn chmod(path : String, perm : Int32) -> Result[Unit, String] {
  fs_unit_response(chmod_ffi(c_path(path), perm))
}

///|
/// The current working directory.
pub fn getcwd() -> Result[String, String] {
  fs_string_response(getcwd_ffi())
}

///|
/// Creates a fresh empty file `dir/<prefix>XXXXXX` (`mkstemp(3)`, mode
/// 0600) and returns its path.
pub fn make_temp_file(
  dir~ : String,
  prefix~ : String = "tmp",
) -> Result[String, String] {
  fs_string_response(mkstemp_ffi(c_path(join_path(dir, prefix + "XXXXXX"))))
}

///|
/// Creates a fresh directory `dir/<prefix>XXXXXX` (`mkdtemp(3)`, mode
/// 0700) and returns its path.
pub fn make_temp_dir(
  dir~ : String,
  prefix~ : String = "tmp",
) -> Result[String, String] {
  fs_string_response(mkdtemp_ffi(c_path(join_path(dir, prefix + "XXXXXX"))))
}

///|
/// Opens (creating if needed) the file `path` and places an advisory lock
/// (`flock(2)`) on it: exclusive by default, shared if `exclusive` is
/// `false`. If `blocking` is `false`, fails instead of waiting for a
/// conflicting lock to be released.
pub fn lock_file(
  path : String,
  exclusive~ : Bool = true,
  blocking~ : Bool = true,
) -> Result[FileLock, String] {
  match fs_response(lock_ffi(c_path(path), exclusive, blocking)) {
    Ok(p) if p.length() >= 8 =>
      Ok({ fd: get_i64(p, 0).to_int(), path, held: true, })
    Ok(_) => Err("lock returned a malformed response")
    Err(err) => Err(err)
  }
}

///|
/// Releases the lock and closes its file. Unlocking twice is a no-op.
pub fn FileLock::unlock(self : FileLock) -> Result[Unit, String] {
  if !self.held {
    return Ok(())
  }
  self.held = false
  if unlock_ffi(self.fd) == 0 {
    Ok(())
  } else {
    Err("failed to unlock \{self.path}")
  }
}

///|
/// Sorts names by code units (`String::compare` orders by length first).
fn sort_names(names : Array[String]) -> Unit {
  names.sort_by((a, b) => {
    let n = if a.length() < b.length() { a.length() } else { b.length() }
    for i in 0..<n {
      let c = a[i].compare(b[i])
      if c != 0 {
        return c
      }
    }
    a.length().compare(b.length())
  })
}
