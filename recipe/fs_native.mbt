///|
#borrow(path)
extern "c" fn file_kind_ffi(path : Bytes) -> Int = "bap_recipe_file_kind"

///|
#borrow(path)
extern "c" fn read_dir_ffi(path : Bytes) -> Bytes = "bap_recipe_read_dir"

///|
fn c_path(path : String) -> Bytes {
  @utf8.encode(path + "\u{0}")
}

///|
fn native_file_kind(path : String) -> Int {
  file_kind_ffi(c_path(path))
}

///|
fn native_read_dir(path : String) -> Array[String] {
  let data = read_dir_ffi(c_path(path))
  let result = []
  let mut start = 0
  for i in 0..<data.length() {
    if data[i] == 0 {
      if i > start {
        result.push(@utf8.decode_lossy(data[start:i]))
      }
      start = i + 1
    }
  }
  sort_names(result)
  result
}

///|
/// The file system of the host (native target only; on other targets it
/// is empty).
pub fn FileSystem::native() -> FileSystem {
  {
    file_exists: path => native_file_kind(path) != 0,
    is_directory: path => native_file_kind(path) == 2,
    read_dir: native_read_dir,
    read_file: host_read_file,
  }
}
