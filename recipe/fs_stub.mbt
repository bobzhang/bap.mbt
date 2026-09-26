///|
/// The file system of the host (native target only; on other targets it
/// is empty).
pub fn FileSystem::native() -> FileSystem {
  {
    file_exists: _ => false,
    is_directory: _ => false,
    read_dir: _ => [],
    read_file: host_read_file,
  }
}
