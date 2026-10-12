///|
/// The name of the table-of-contents files.
pub let patternconstraints : String = "patternconstraints.xml"

///|
fn read_text(fs : @bap_main.FileSystem, path : String) -> String? {
  match (fs.read_file)(path) {
    None => None
    Some(bytes) => Some(@utf8.decode_lossy(bytes))
  }
}

///|
/// Finds all `patternconstraints.xml` files under `root` (upstream
/// `collect_patternconstraints`); `root` may itself be such a file.
pub fn find_patternconstraints(
  root : String,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Array[String] {
  let found = []
  fn walk(path : String) -> Unit {
    match (fs.kind)(path) {
      Some(RegularFile) =>
        if basename(path) == patternconstraints {
          found.push(path)
        }
      Some(Directory) => {
        let names = (fs.read_dir)(path).unwrap_or([])
        names.sort_by(lexical_compare)
        for n in names {
          walk(concat_path(path, n))
        }
      }
      _ => ()
    }
  }

  walk(root)
  found
}

///|
fn[A] parse_file(
  fs : @bap_main.FileSystem,
  file : String,
  parse : (String) -> Result[Array[A], String],
) -> Array[A] {
  match read_text(fs, file) {
    None => {
      log.warning(message="failed to read file \{file}")
      []
    }
    Some(text) =>
      match parse(text) {
        Ok(result) => result
        Err(problem) => {
          log.warning(message="failed to parse file \{file}: \{problem}")
          []
        }
      }
  }
}

///|
/// All `(target specification, patterns file)` entries of the tables of
/// contents found under the roots (upstream `Repository.collect`); the
/// file paths are relative to the table of contents. Entries with
/// malformed target specifications are skipped with a warning.
pub fn collect(
  roots : ArrayView[String],
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Array[(TargetSpec, String)] {
  let out = []
  for root in roots {
    for toc in find_patternconstraints(root, fs~) {
      let folder = dirname(toc)
      for entry in parse_file(fs, toc, parse_constraints) {
        let spec = TargetSpec::parse(entry.0) catch {
          e => {
            log.warning(message="\{toc}: bad target \{entry.0}: \{e}")
            continue
          }
        }
        out.push((spec, concat_path(folder, entry.1)))
      }
    }
  }
  out
}

///|
/// The patterns files applicable to the target (upstream
/// `Repository.select`): existing regular files whose specification
/// matches the target, without duplicates (by path or by contents),
/// ordered by path.
pub fn select(
  roots : ArrayView[String],
  target : @core_theory.Target,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Array[String] {
  let digests : Map[String, Unit] = Map([])
  let files : Array[String] = []
  for entry in collect(roots, fs~) {
    let (spec, file) = entry
    if !spec.matches(target) || (fs.kind)(file) != Some(RegularFile) {
      continue
    }
    let digest = match (fs.read_file)(file) {
      Some(bytes) => @digest.md5_hex(bytes)
      None => continue
    }
    if digests.contains(digest) || files.contains(file) {
      continue
    }
    digests[digest] = ()
    files.push(file)
  }
  files.sort_by(lexical_compare)
  files
}

///|
/// Loads and compiles the patterns applicable to the target (upstream
/// `Repository.load`).
pub fn load(
  roots : ArrayView[String],
  target : @core_theory.Target,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Rules {
  let rules = []
  for file in select(roots, target, fs~) {
    rules.append(parse_file(fs, file, parse_patterns))
  }
  Rules::create(rules)
}
