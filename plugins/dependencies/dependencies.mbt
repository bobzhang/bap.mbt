///|
/// The plugin and command name.
pub let name : String = "dependencies"

///|
let doc : String =
  #|Outputs program dependencies such as libraries and symbols. The
  #|information is collected recursively with various output options,
  #|including dependency graph, YAML, JSON, and SEXP.
  #|
  #|The information includes the list of imported libraries as well as a set
  #|of imported and exported symbols. The information could be collected
  #|recursively, when the --recursive option is specified. In a recursive
  #|mode, the list of paths where to search for libraries could be specified
  #|with the --library-paths option. It is also possible to use an
  #|ldconfig-like cache via the --ldconfig parameter.

///|
/// The dependency information of one unit (`info`).
pub(all) struct DependencyInfo {
  name : String
  imports : Array[String]
  exports : Array[String]
  libraries : Array[String]
} derive(Eq, Debug)

///|
pub extend DependencyInfo with Eq::{not_equal, equal}

///|
pub extend DependencyInfo with Debug::{to_repr}

///|
fn warning(message : String) -> Unit {
  @main_event.message(MainLogWarning, section=name, message~)
}

///|
fn info(message : String) -> Unit {
  @main_event.message(MainLogInfo, section=name, message~)
}

///|
fn sorted_set(items : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for item in items {
    if !result.contains(item) {
      result.push(item)
    }
  }
  result.sort_by(String::lexical_compare)
  result
}

///|
/// The basename of a path (`Filename.basename`).
pub fn basename(path : String) -> String {
  let mut end = path.length()
  while end > 1 && path[end - 1] == '/' {
    end -= 1
  }
  let trimmed = path.unsafe_substring(start=0, end~)
  match trimmed.rev_find("/") {
    Some(i) if trimmed.length() > 1 =>
      trimmed.unsafe_substring(start=i + 1, end=trimmed.length())
    _ => trimmed
  }
}

///|
/// An empty unit.
pub fn DependencyInfo::empty(unit_name : String) -> DependencyInfo {
  { name: unit_name, imports: [], exports: [], libraries: [], }
}

///|
/// Queries the dependency information from an image specification
/// (`Spec.query`): imports are external references to undefined (zero
/// address) named symbols, exports are defined named symbols, and libraries
/// are the required libraries.
pub fn DependencyInfo::of_spec(
  unit_name : String,
  doc : @ogre.Doc,
) -> DependencyInfo {
  let symbols = doc.get(@image.Scheme::named_symbol())
  let undefined = symbols.filter(s => s.0 == 0L).map(s => s.1)
  let imports = doc
    .get(@image.Scheme::external_reference())
    .filter_map(r => if undefined.contains(r.1) { Some(r.1) } else { None })
  let exports = symbols.filter(s => s.0 != 0L).map(s => s.1)
  {
    name: basename(unit_name),
    imports: sorted_set(imports),
    exports: sorted_set(exports),
    libraries: doc.get(@image.Scheme::require()),
  }
}

///|
/// An ldconfig-like library cache (`Ldconfig.cache`).
pub struct LdconfigCache {
  paths : Map[String, String]
}

///|
/// Parses the output of `ldconfig -p`: lines of the form `... => path`.
pub fn LdconfigCache::parse(text : String) -> LdconfigCache {
  let paths : Map[String, String] = Map([])
  for line in text.split("\n") {
    let parts = line.trim().split(">").collect()
    if parts.length() == 2 {
      let path = parts[1].trim().to_owned()
      paths[basename(path)] = path
    }
  }
  { paths, }
}

///|
/// Looks up a library path by its name.
pub fn LdconfigCache::lookup(self : LdconfigCache, lib : String) -> String? {
  self.paths.get(lib)
}

///|
fn is_absolute(path : String) -> Bool {
  path.has_prefix("/")
}

///|
fn concat(dir : String, file : String) -> String {
  if dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}

///|
fn exists(fs : @bap_main.FileSystem, path : String) -> Bool {
  (fs.kind)(path) is Some(_)
}

///|
/// Finds a unit file (`Unit.search`): absolute paths are prefixed with
/// `root`; relative names are searched in the ldconfig cache and then in the
/// library paths.
pub fn search(
  file : String,
  root? : String,
  ldconfig? : LdconfigCache,
  paths? : Array[String] = [],
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> String? {
  let file = match root {
    // `Filename.concat root file` yields a doubled separator; it is
    // collapsed here so that exact-match file systems resolve the path
    Some(r) if is_absolute(file) => r.trim_end(chars="/").to_owned() + file
    _ => file
  }
  if exists(fs, file) {
    Some(file)
  } else if is_absolute(file) {
    None
  } else {
    match ldconfig.bind(cache => cache.lookup(file)) {
      Some(path) => Some(path)
      None =>
        for folder in paths {
          let path = concat(folder, file)
          if exists(fs, path) {
            break Some(path)
          }
        } nobreak {
          None
        }
    }
  }
}

///|
/// Loads an image, detecting ELF files by their magic number (upstream uses
/// the format-detecting LLVM backend) and other formats by file extension.
fn load_image(
  bytes : Bytes,
  path : String,
) -> Result[(@image.Image, Array[String]), String] {
  match @image.register_builtin_backends() {
    Err(reason) => return Err(reason)
    Ok(_) => ()
  }
  if bytes is [0x7f, b'E', b'L', b'F', ..] {
    @image.Image::of_bytes(bytes, backend="elf")
  } else {
    @image.Image::of_bytes_for_filename(bytes, filename=path)
  }
}

///|
/// Loads the dependency information of an image file (`Unit.of_image`).
pub fn of_image(
  path : String,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> DependencyInfo {
  match (fs.read_file)(path) {
    None => {
      warning("failed to load the file \"\{path}\": cannot read the file")
      DependencyInfo::empty(path)
    }
    Some(bytes) =>
      match load_image(bytes, path) {
        Err(reason) => {
          warning("failed to load the file \"\{path}\": \{reason}")
          DependencyInfo::empty(path)
        }
        Ok((image, _)) => DependencyInfo::of_spec(path, image.spec())
      }
  }
}

///|
/// A memo table standing in for BAP's persistent `Data.Cache` of units.
pub struct DependencyCache {
  entries : Map[String, DependencyInfo]
}

///|
pub fn DependencyCache::new() -> DependencyCache {
  { entries: Map([]), }
}

///|
/// Finds and loads a unit (`Unit.load`); missing units are empty.
pub fn load_unit(
  unit_name : String,
  root? : String,
  ldconfig? : LdconfigCache,
  paths? : Array[String] = [],
  context? : String = "",
  cache? : DependencyCache,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> DependencyInfo {
  match search(unit_name, root?, ldconfig?, paths~, fs~) {
    None => {
      warning("missing dependency: \{unit_name}")
      DependencyInfo::empty(unit_name)
    }
    Some(path) => {
      let key = "dependencies:\{context}\{path}"
      match cache.bind(c => c.entries.get(key)) {
        Some(data) => {
          info("\{path} is cached")
          data
        }
        None => {
          let data = of_image(path, fs~)
          if cache is Some(c) {
            c.entries[key] = data
            info("caching \{path} as \{key}")
          }
          data
        }
      }
    }
  }
}

///|
/// The collected dependencies (`State.t`): the root unit name and the units
/// keyed by name.
pub(all) struct DependencyState {
  root : String
  units : Map[String, DependencyInfo]
}

///|
/// Loads the unit at `path` and, when `recursive`, the closure of its
/// library dependencies (`State.load`).
pub fn DependencyState::load(
  path : String,
  recursive? : Bool = false,
  root? : String,
  ldconfig? : LdconfigCache,
  paths? : Array[String] = [],
  context? : String = "",
  cache? : DependencyCache,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> DependencyState {
  let load = (unit_name : String) => {
    load_unit(unit_name, root?, ldconfig?, paths~, context~, cache?, fs~)
  }
  let unit = load(path)
  let units : Map[String, DependencyInfo] = Map([])
  units[basename(path)] = unit
  fn closure(unit : DependencyInfo) -> Unit {
    for lib in unit.libraries {
      if !units.contains(lib) {
        let dep = load(lib)
        units[lib] = dep
        closure(dep)
      }
    }
  }
  if recursive {
    closure(unit)
  }
  { root: basename(path), units, }
}

///|
/// The units sorted by name.
pub fn DependencyState::sorted_units(
  self : DependencyState,
) -> Array[DependencyInfo] {
  let names = self.units.keys().collect()
  names.sort_by(String::lexical_compare)
  names.map(n => self.units[n])
}
