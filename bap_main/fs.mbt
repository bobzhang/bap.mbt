// File-system access used by the `file`, `dir`, and `non_dir_file` types,
// their digests, and by the configuration file reader.
//
// OCaml BAP calls `Sys.file_exists`, `Sys.is_directory`, `Sys.readdir`, and
// `Unix.stat` directly. MoonBit's portable core has no such primitives, so
// the framework goes through a replaceable `FileSystem` record. The default
// implementation is backed by `native_io` (`stat`, `read_dir`, `read_file`)
// and sees the host file system on the native target. Tests that need
// determinism (and hosts without a file system) install their own
// implementation with `set_file_system`.

///|
/// The kind of an existing file-system entry.
pub(all) enum FileKind {
  RegularFile
  Directory
  OtherFile
} derive(Eq, Debug)

///|
pub extend FileKind with Eq::{equal, not_equal}

///|
pub extend FileKind with Debug::{to_repr}

///|
/// Pluggable file-system primitives.
pub(all) struct FileSystem {
  /// `kind(path)` is `None` if nothing exists at `path`.
  kind : (String) -> FileKind?
  /// `read_file(path)` is the contents of the regular file at `path`.
  read_file : (String) -> Bytes?
  /// `read_dir(path)` lists the entry names (not paths) of a directory.
  read_dir : (String) -> Array[String]?
}

///|
/// The default file system, backed by `native_io` (the host file system on
/// the native target; empty on the other targets).
pub fn FileSystem::native() -> FileSystem {
  {
    kind: path => {
      match @native_io.stat(path) {
        Ok({ kind: RegularFile, .. }) => Some(RegularFile)
        Ok({ kind: Directory, .. }) => Some(Directory)
        Ok(_) => Some(OtherFile)
        Err(_) => None
      }
    },
    read_file: path => {
      match @native_io.read_file(path) {
        Ok(bytes) => Some(bytes)
        Err(_) => None
      }
    },
    read_dir: path => {
      match @native_io.read_dir(path) {
        Ok(names) => Some(names)
        Err(_) => None
      }
    },
  }
}

///|
/// An in-memory file system built from `(path, contents)` files and a list
/// of directory paths. Directory listings are derived from the paths.
/// Useful for tests and for embedding.
pub fn FileSystem::in_memory(
  files~ : Array[(String, String)],
  dirs? : Array[String] = [],
) -> FileSystem {
  let file_map : Map[String, Bytes] = Map([])
  for entry in files {
    file_map[entry.0] = @utf8.encode(entry.1)
  }
  let dir_set : Map[String, Unit] = Map([])
  for d in dirs {
    dir_set[d] = ()
  }
  {
    kind: path => {
      if file_map.contains(path) {
        Some(RegularFile)
      } else if dir_set.contains(path) {
        Some(Directory)
      } else {
        None
      }
    },
    read_file: path => file_map.get(path),
    read_dir: path => {
      if dir_set.contains(path) {
        let prefix = if path.has_suffix("/") { path } else { path + "/" }
        let names : Array[String] = []
        let add = (p : String) => {
          if p.has_prefix(prefix) {
            let rest = p[prefix.length():].to_owned()
            if rest != "" && !rest.contains("/") && !names.contains(rest) {
              names.push(rest)
            }
          }
        }
        for p, _ in file_map {
          add(p)
        }
        for p, _ in dir_set {
          add(p)
        }
        Some(names)
      } else {
        None
      }
    },
  }
}

///|
let current_file_system : Ref[FileSystem] = Ref(FileSystem::native())

///|
/// Installs the file system used by the framework.
pub fn set_file_system(fs : FileSystem) -> Unit {
  current_file_system.val = fs
}

///|
/// The file system currently used by the framework.
pub fn file_system() -> FileSystem {
  current_file_system.val
}

///|
fn fs_kind(path : String) -> FileKind? {
  (current_file_system.val.kind)(path)
}

///|
/// OCaml `Filename.concat`.
fn filename_concat(dir : String, file : String) -> String {
  if dir == "" || dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}
