///|
/// The file system operations used to search and load recipes.
///
/// `FileSystem::native()` accesses the host file system (on the native
/// target), `FileSystem::in_memory` is a read-only file system backed by a
/// map, useful for tests and embedded recipes.
pub(all) struct FileSystem {
  /// true if a file or a directory exists at the path
  file_exists : (String) -> Bool
  /// true if the path is a directory
  is_directory : (String) -> Bool
  /// the names of the entries of a directory
  read_dir : (String) -> Array[String]
  /// the contents of a file
  read_file : (String) -> Result[String, String]
}

///|
fn host_read_file(path : String) -> Result[String, String] {
  match @native_io.read_file(path) {
    Ok(bytes) => Ok(@utf8.decode_lossy(bytes))
    Err(err) => Err(err)
  }
}

///|
/// The file system of the host, backed by `native_io` (on the native
/// target; on other targets it is empty).
pub fn FileSystem::native() -> FileSystem {
  {
    file_exists: @native_io.file_exists,
    is_directory: @native_io.is_directory,
    read_dir: path => @native_io.read_dir(path).unwrap_or([]),
    read_file: host_read_file,
  }
}

///|
/// A read-only file system that contains the given files (path to
/// contents). Directories are all the proper prefixes of the file paths.
pub fn FileSystem::in_memory(files : Map[String, String]) -> FileSystem {
  let dirs : Map[String, Array[String]] = Map([])
  let add_entry = (dir : String, name : String) => {
    match dirs.get(dir) {
      Some(entries) => if !entries.contains(name) { entries.push(name) }
      None => dirs[dir] = [name]
    }
  }
  for path, _ in files {
    let parts = path.split("/").map(part => part.to_owned()).to_array()
    for i in 1..<parts.length() {
      let dir = parts[0:i].join("/")
      add_entry(if dir == "" { "/" } else { dir }, parts[i])
    }
    if parts.length() > 1 && parts[0] != "" {
      add_entry(".", parts[0])
    }
  }
  let is_dir = (path : String) => {
    dirs.contains(path) ||
    (path.has_suffix("/") && dirs.contains(path.trim_end(chars="/").to_owned()))
  }
  {
    file_exists: path => files.contains(path) || is_dir(path),
    is_directory: is_dir,
    read_dir: path => {
      let entries = dirs
        .get(path)
        .unwrap_or_else(() => {
          dirs.get(path.trim_end(chars="/").to_owned()).unwrap_or([])
        })
        .copy()
      sort_names(entries)
      entries
    },
    read_file: path => {
      match files.get(path) {
        Some(contents) => Ok(contents)
        None => Err("\{path}: No such file or directory")
      }
    },
  }
}

///|
/// Sorts names lexicographically by code units (`String::compare` orders
/// by length first).
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

// Path helpers, following OCaml's `Filename` module on Unix.

///|
/// [concat(dir, file)] is `dir/file` (upstream `Filename.concat`).
pub fn concat(dir : String, file : String) -> String {
  if dir == "" || dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}

///|
fn trailing_slashes_end(s : String) -> Int32 {
  let mut n = s.length()
  while n > 1 && s[n - 1] == '/' {
    n -= 1
  }
  n
}

///|
/// The directory part of a path (upstream `Filename.dirname`).
pub fn dirname(path : String) -> String {
  if path == "" {
    return "."
  }
  let mut n = trailing_slashes_end(path)
  if n == 1 && path[0] == '/' {
    return "/"
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

///|
/// The file part of a path (upstream `Filename.basename`).
pub fn basename(path : String) -> String {
  if path == "" {
    return "."
  }
  let n = trailing_slashes_end(path)
  if n == 1 && path[0] == '/' {
    return "/"
  }
  let mut start = n
  while start > 0 && path[start - 1] != '/' {
    start -= 1
  }
  path[start:n].to_owned()
}
