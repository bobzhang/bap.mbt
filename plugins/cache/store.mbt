// Port of `Bap_cache`: the layout of the cache folder and the operations
// on it.
//
// The cache root (by default `Configuration::cachedir()`, e.g.,
// `~/.cache/bap`) contains
//
// - `config.3`, the configuration (see `Config::to_bytes`);
// - `data/`, one read-only file per entry, named after the digest of
//   its key;
// - `gc.lock`, the advisory lock that serializes garbage collections
//   (an addition of this port; upstream is lock-free).
//
// Entries are written to a temporary file in `data/` and atomically
// renamed, so that concurrent processes never observe partial entries,
// and the root itself is created atomically by renaming a fully
// initialized temporary folder.

///|
let reporter : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="cache",
)

///|
fn warning(message : String) -> Unit {
  reporter.warning(message~)
}

///|
let default_root : Ref[String?] = Ref(None)

///|
/// Makes `dir/.cache/bap` the cache root (upstream `set_root`, the
/// `--cache-dir` option).
pub fn set_root(dir : String) -> Unit {
  default_root.val = Some(dir)
}

///|
/// Forgets the root set with `set_root`.
pub fn reset_root() -> Unit {
  default_root.val = None
}

///|
/// The cache root: `<dir>/.cache/bap` if a directory was set with
/// `set_root`, the user cache directory otherwise.
pub fn root() -> String {
  match default_root.val {
    Some(dir) => concat(concat(dir, ".cache"), "bap")
    None => @bap_main.Configuration::cachedir()
  }
}

///|
/// The folder with the cache entries.
pub fn data_dir(root? : String = root()) -> String {
  concat(root, "data")
}

///|
/// The configuration file.
pub fn config_file(root? : String = root()) -> String {
  concat(root, config_file_name)
}

///|
/// `dir/name` (OCaml `Filename.concat`).
fn concat(dir : String, name : String) -> String {
  if dir == "" || dir.has_suffix("/") {
    dir + name
  } else {
    dir + "/" + name
  }
}

///|
/// OCaml `Filename.dirname`.
fn dirname(path : String) -> String {
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

///|
/// Writes the configuration file of the cache at `root`.
pub fn write_config(cfg : Config, root? : String = root()) -> Unit {
  match
    @native_io.write_file_atomic(config_file(root~), cfg.to_bytes(), perm=0o444) {
    Ok(_) => ()
    Err(err) => warning("Failed to store config file: \{err}")
  }
}

///|
/// Reads the configuration of the cache at `root`, or the default one if
/// the file is missing or malformed.
pub fn read_config(root? : String = root()) -> Config {
  match @native_io.read_file(config_file(root~)) {
    Ok(data) =>
      match Config::of_bytes(data) {
        Some(cfg) => cfg
        None => {
          warning("Failed to read config file: malformed data")
          Config::default()
        }
      }
    Err(err) => {
      warning("Failed to read config file: \{err}")
      Config::default()
    }
  }
}

///|
/// Creates a fresh temporary folder in `parent`, lets `f` fill it, and
/// renames it to `target` (upstream `mkdir_from_tmp`). If `target`
/// already exists and is not empty, the rename fails and the prepared
/// folder is discarded. The temporary folder never survives.
fn mkdir_from_tmp(
  target~ : String,
  parent : String,
  f : (String) -> Result[Unit, String],
) -> Result[Unit, String] {
  let tmp = match @native_io.make_temp_dir(dir=parent) {
    Ok(tmp) => tmp
    Err(err) => return Err(err)
  }
  defer @native_io.remove_tree(tmp) |> ignore
  match f(tmp) {
    Err(err) => Err(err)
    Ok(_) =>
      match @native_io.rename(tmp, target) {
        Ok(_) => Ok(())
        // another process (or an earlier run) has created it
        Err(_) if @native_io.is_directory(target) => Ok(())
        Err(err) => Err(err)
      }
  }
}

///|
fn init_layout(root : String) -> Result[Unit, String] {
  match @native_io.mkdir_p(data_dir(root~), perm=0o700) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  write_config(Config::default(), root~)
  Ok(())
}

///|
/// Creates the cache folder at `root` unless it exists (upstream
/// `init_cache_dir`). Unlike upstream, a pre-existing root without the
/// `data` folder (e.g., a shared `~/.cache/bap` created by another tool)
/// gets the missing parts instead of being left unusable.
pub fn init_cache_dir(root? : String = root()) -> Result[Unit, String] {
  if @native_io.is_directory(data_dir(root~)) {
    return Ok(())
  }
  let parent = dirname(root)
  match @native_io.mkdir_p(parent) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match mkdir_from_tmp(target=root, parent, init_layout) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if @native_io.is_directory(data_dir(root~)) {
    Ok(())
  } else {
    let has_config = @native_io.file_exists(config_file(root~))
    match @native_io.mkdir_p(data_dir(root~), perm=0o700) {
      Ok(_) => {
        if !has_config {
          write_config(Config::default(), root~)
        }
        Ok(())
      }
      Err(err) => Err(err)
    }
  }
}

///|
/// The index files of the previous cache formats (upstream
/// `Upgrade.index_files`), newest first.
let index_files : Array[String] = ["index.2", "index.1"]

///|
/// Drops the index of a cache created by an older version (upstream
/// `Upgrade.run`). Upstream moves the entries of a version 2 index into
/// the `data` folder; that requires reading the `bin_prot` index, which
/// this port does not implement, so the old entries are dropped with a
/// warning.
fn upgrade(root : String) -> Unit {
  for name in index_files {
    let path = concat(root, name)
    if @native_io.file_exists(path) {
      warning(
        "can't read entries from index version \{name.unsafe_substring(start=6, end=name.length())}, the old cache entries are dropped",
      )
      match @native_io.remove_file(path) {
        Ok(_) => ()
        Err(err) => warning(err)
      }
      return
    }
  }
}

///|
/// Prepares the cache at `root` for use: creates it and upgrades the old
/// layouts (upstream `init`).
pub fn initialize(root? : String = root()) -> Result[Unit, String] {
  match init_cache_dir(root~) {
    Ok(_) => {
      upgrade(root)
      Ok(())
    }
    Err(err) => Err(err)
  }
}

///|
/// The total size of the entries, in megabytes (upstream `size`).
pub fn size(root? : String = root()) -> Int {
  let dir = data_dir(root~)
  let names = @native_io.read_dir(dir).unwrap_or([])
  let mut total : Int64 = 0
  for name in names {
    match @native_io.stat(concat(dir, name)) {
      Ok(st) => total += st.size
      Err(_) => ()
    }
  }
  (total / 1024L / 1024L).to_int()
}

///|
/// The path of the entry stored under `key`.
pub fn entry_path(key : @regular.Digest, root? : String = root()) -> String {
  concat(data_dir(root~), key.to_string())
}

///|
/// Stores an entry (upstream `save`): the data is written to a temporary
/// file in the data folder, made read-only, and renamed to the entry.
pub fn save(
  key : @regular.Digest,
  data : Bytes,
  root? : String = root(),
) -> Unit {
  let dir = data_dir(root~)
  match
    @native_io.write_file_atomic(
      entry_path(key, root~),
      data,
      temp_dir=dir,
      perm=0o444,
    ) {
    Ok(_) => ()
    Err(err) => warning("failed to store a cache entry: \{err}")
  }
}

///|
/// The entry stored under `key`, if any (upstream `load`).
pub fn load(key : @regular.Digest, root? : String = root()) -> Bytes? {
  match @native_io.read_file(entry_path(key, root~)) {
    Ok(data) => Some(data)
    Err(_) => None
  }
}

///|
/// The on-disk caching service: entries are stored in the data folder of
/// the current root (upstream `provide_service`).
pub fn service() -> @regular.CacheService {
  { load: key => load(key), save: (key, data) => save(key, data), }
}
