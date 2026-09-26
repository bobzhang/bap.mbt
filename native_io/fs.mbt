// Portable part of the file-system API. The primitives (`stat`, `lstat`,
// `read_dir`, `mkdir`, `remove_file`, `remove_dir`, `rename`, `chmod`,
// `getcwd`, `make_temp_file`, `make_temp_dir`, `lock_file`,
// `FileLock::unlock`) are implemented with POSIX calls on the native
// target (`fs_native.mbt`, `fs.c`) and fail with an error message on the
// other targets (`fs_stub.mbt`). The helpers below are built on top of
// them and behave the same on every target.

///|
/// The kind of a file-system entry.
pub(all) enum FileKind {
  RegularFile
  Directory
  Symlink
  OtherFile
} derive(Eq, Debug)

///|
pub extend FileKind with Eq::{equal, not_equal}

///|
pub extend FileKind with Debug::{to_repr}

///|
/// The subset of `struct stat` used by BAP.
pub(all) struct FileStat {
  /// the kind of the entry
  kind : FileKind
  /// the size in bytes
  size : Int64
  /// the modification time, in seconds since the epoch
  mtime : Double
  /// the permission bits (`st_mode & 0o7777`)
  perm : Int
} derive(Eq, Debug)

///|
pub extend FileStat with Eq::{equal, not_equal}

///|
pub extend FileStat with Debug::{to_repr}

///|
/// An advisory lock (`flock`) held on a file, see `lock_file`.
#warnings("-struct_never_constructed")
pub struct FileLock {
  priv fd : Int
  priv path : String
  priv mut held : Bool
}

///|
/// The path of the locked file.
pub fn FileLock::path(self : FileLock) -> String {
  self.path
}

///|
/// The kind of the entry at `path` (following symbolic links), or `None`
/// if nothing (accessible) exists there.
pub fn file_kind(path : String) -> FileKind? {
  match stat(path) {
    Ok(st) => Some(st.kind)
    Err(_) => None
  }
}

///|
/// `true` if a file, a directory, or any other entry exists at `path`
/// (OCaml `Sys.file_exists`).
pub fn file_exists(path : String) -> Bool {
  file_kind(path) is Some(_)
}

///|
/// `true` if `path` is a directory (OCaml `Sys.is_directory`, but `false`
/// instead of an exception for missing paths).
pub fn is_directory(path : String) -> Bool {
  file_kind(path) is Some(Directory)
}

///|
/// Creates `path` and all its missing parents (`mkdir -p`). Succeeds if
/// the directory already exists; fails if `path` or one of its parents
/// exists and is not a directory.
pub fn mkdir_p(path : String, perm? : Int = 0o777) -> Result[Unit, String] {
  match file_kind(path) {
    Some(Directory) => return Ok(())
    Some(_) => return Err("failed to create directory \{path}: not a directory")
    None => ()
  }
  let parent = parent_dir(path)
  if parent != path {
    match mkdir_p(parent, perm~) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }
  match mkdir(path, perm~) {
    Ok(_) => Ok(())
    // a concurrent process may have created it in the meantime
    Err(_) if is_directory(path) => Ok(())
    Err(err) => Err(err)
  }
}

///|
/// Removes `path` recursively (`rm -rf`). A missing path is not an error.
/// Symbolic links are removed, not followed.
pub fn remove_tree(path : String) -> Result[Unit, String] {
  match lstat(path) {
    Err(_) => Ok(())
    Ok({ kind: Directory, .. }) => {
      match read_dir(path) {
        Ok(entries) =>
          for entry in entries {
            match remove_tree(join_path(path, entry)) {
              Ok(_) => ()
              Err(err) => return Err(err)
            }
          }
        Err(err) => return Err(err)
      }
      remove_dir(path)
    }
    Ok(_) => remove_file(path)
  }
}

///|
/// Atomically replaces the contents of `path` with `data`: the data is
/// written to a fresh temporary file in `temp_dir` (the directory of
/// `path` by default), which is then renamed over `path`. If `perm` is
/// given, it is applied to the file before the rename.
pub fn write_file_atomic(
  path : String,
  data : BytesView,
  temp_dir? : String,
  perm? : Int,
) -> Result[Unit, String] {
  let dir = match temp_dir {
    Some(dir) => dir
    None => parent_dir(path)
  }
  let tmp = match make_temp_file(dir~, prefix="tmp") {
    Ok(tmp) => tmp
    Err(err) => return Err(err)
  }
  let result = match write_file(tmp, data) {
    Err(err) => Err(err)
    Ok(_) =>
      match perm {
        Some(perm) => chmod(tmp, perm)
        None => Ok(())
      }
  }
  match result {
    Ok(_) =>
      match rename(tmp, path) {
        Ok(_) => Ok(())
        Err(err) => {
          remove_file(tmp) |> ignore
          Err(err)
        }
      }
    Err(err) => {
      remove_file(tmp) |> ignore
      Err(err)
    }
  }
}

///|
/// Runs `f` while holding an advisory lock on `path` (see `lock_file`).
/// The lock is released when `f` returns or raises.
pub fn[T] with_lock(
  path : String,
  exclusive? : Bool = true,
  f : () -> T raise?,
) -> Result[T, String] raise? {
  let lock = match lock_file(path, exclusive~) {
    Ok(lock) => lock
    Err(err) => return Err(err)
  }
  defer lock.unlock() |> ignore
  Ok(f())
}

///|
/// `dir/name` (OCaml `Filename.concat`).
fn join_path(dir : String, name : String) -> String {
  if dir == "" || dir.has_suffix("/") {
    dir + name
  } else {
    dir + "/" + name
  }
}

///|
/// The parent directory of `path` (OCaml `Filename.dirname`).
fn parent_dir(path : String) -> String {
  let mut n = path.length()
  while n > 1 && path[n - 1] == '/' {
    n -= 1
  }
  while n > 0 && path[n - 1] != '/' {
    n -= 1
  }
  if n == 0 {
    return "."
  }
  while n > 1 && path[n - 1] == '/' {
    n -= 1
  }
  path[:n].to_owned()
}
