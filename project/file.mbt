///|
fn ProjectInput::with_default_filename(
  self : ProjectInput,
  filename : String,
) -> ProjectInput {
  match self.filename_value {
    Some(_) => self
    None => { ..self, filename_value: Some(filename) }
  }
}

///|
fn ProjectInput::as_library(
  self : ProjectInput,
  default_name : String,
) -> Library {
  let name = match self.filename_value {
    Some(value) => value
    None => default_name
  }
  Library::create(
    name~,
    target=self.target_value,
    memory=self.memory_value,
    symbols=self.symbols_value,
    program?=self.program_value,
  )
}

///|
fn ProjectInput::with_extra_libraries(
  self : ProjectInput,
  libraries : Array[Library],
) -> ProjectInput {
  if libraries.is_empty() {
    self
  } else {
    let next = self.libraries_value.copy()
    for library in libraries {
      next.push(library)
    }
    { ..self, libraries_value: next }
  }
}

///|
fn push_library_path(
  paths : Array[String],
  main_path : String,
  display_name : String,
  path : String,
) -> Unit {
  if path != main_path && path != display_name && !paths.contains(path) {
    paths.push(path)
  }
}

///|
fn project_input_library_paths(
  main_path : String,
  display_name : String,
  libraries : Array[String],
) -> Array[String] {
  let paths = []
  for path in libraries {
    push_library_path(paths, main_path, display_name, path)
  }
  paths
}

///|
fn project_input_load_libraries(
  main_path : String,
  display_name : String,
  libraries : Array[String],
  loader : String?,
  target : @core_theory.Target?,
) -> Result[Array[Library], String] {
  let loaded = []
  for path in project_input_library_paths(main_path, display_name, libraries) {
    let input = match loader {
      Some(name) => ProjectInput::load_file(path, loader=name, target?)
      None => ProjectInput::load_file_for_filename(path, target?)
    }
    match input {
      Ok(value) => loaded.push(value.as_library(path))
      Err(reason) =>
        return Err("failed to load project library \{path}: \{reason}")
    }
  }
  Ok(loaded)
}

///|
fn project_raw_endian(target : @core_theory.Target) -> @bitvec.Endian {
  match target.endianness() {
    BigEndian => BigEndian
    _ => LittleEndian
  }
}

///|
pub fn ProjectInput::raw_file(
  path : String,
  target~ : @core_theory.Target,
  base? : UInt64 = 0UL,
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
  filename? : String,
) -> Result[ProjectInput, String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) =>
      ProjectInput::raw_bytes(
        target~,
        data,
        base~,
        offset~,
        length?,
        entry?,
        filename=selected_filename,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn Project::raw_file(
  path : String,
  target~ : @core_theory.Target,
  base? : UInt64 = 0UL,
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
  filename? : String,
) -> Result[Project, String] {
  project_from_input_result(
    ProjectInput::raw_file(
      path,
      target~,
      base~,
      offset~,
      length?,
      entry?,
      filename?,
    ),
  )
}

///|
pub fn ProjectInput::binary(
  target~ : @core_theory.Target,
  filename~ : String,
  base? : UInt64 = 0UL,
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
) -> Result[ProjectInput, String] {
  ProjectInput::raw_file(filename, target~, base~, offset~, length?, entry?)
}

///|
pub fn Project::binary(
  target~ : @core_theory.Target,
  filename~ : String,
  base? : UInt64 = 0UL,
  offset? : Int = 0,
  length? : Int,
  entry? : UInt64,
) -> Result[Project, String] {
  project_from_input_result(
    ProjectInput::binary(target~, filename~, base~, offset~, length?, entry?),
  )
}

///|
pub fn ProjectInput::load_file(
  path : String,
  loader~ : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[ProjectInput, String] {
  match @native_io.read_file(path) {
    Ok(data) =>
      match ProjectInput::load(data, loader~, target?) {
        Ok(input) =>
          match
            project_input_load_libraries(
              path,
              path,
              libraries,
              Some(loader),
              target,
            ) {
            Ok(loaded_libraries) =>
              Ok(
                input
                .with_default_filename(path)
                .with_extra_libraries(loaded_libraries),
              )
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn Project::load_file(
  path : String,
  loader~ : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[Project, String] {
  project_from_input_result(
    ProjectInput::load_file(path, loader~, libraries~, target?),
  )
}

///|
pub fn ProjectInput::file(
  filename~ : String,
  loader? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[ProjectInput, String] {
  match loader {
    Some(name) =>
      ProjectInput::load_file(filename, loader=name, libraries~, target?)
    None => ProjectInput::load_file_for_filename(filename, libraries~, target?)
  }
}

///|
pub fn Project::file(
  filename~ : String,
  loader? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[Project, String] {
  project_from_input_result(
    ProjectInput::file(filename~, loader?, libraries~, target?),
  )
}

///|
pub fn Project::create_file(
  filename~ : String,
  loader? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
  disassembler? : String,
  driver_source? : ProjectDisassemblySource[ProjectDisassemblyDriver],
  brancher? : ProjectDisassemblySource[ProjectBrancher],
  symbolizer? : ProjectDisassemblySource[ProjectSymbolizer],
  rooter? : ProjectDisassemblySource[ProjectRooter],
  reconstructor? : ProjectDisassemblySource[ProjectReconstructor],
  state? : ProjectState,
) -> Result[Project, String] {
  match ProjectInput::file(filename~, loader?, libraries~, target?) {
    Ok(input) =>
      Project::create_from_input(
        input,
        disassembler?,
        driver_source?,
        brancher?,
        symbolizer?,
        rooter?,
        reconstructor?,
        state?,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn Project::create_file_named(
  filename~ : String,
  loader? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
  disassembler? : String,
  driver_source? : String,
  brancher? : String,
  symbolizer? : String,
  rooter? : String,
  reconstructor? : String,
  state? : ProjectState,
) -> Result[Project, String] {
  match ProjectInput::file(filename~, loader?, libraries~, target?) {
    Ok(input) =>
      Project::create_from_input_named(
        input,
        disassembler?,
        driver_source?,
        brancher?,
        symbolizer?,
        rooter?,
        reconstructor?,
        state?,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectInput::load_file_for_filename(
  path : String,
  filename? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[ProjectInput, String] {
  let selected_filename = match filename {
    Some(value) => value
    None => path
  }
  match @native_io.read_file(path) {
    Ok(data) =>
      match
        ProjectInput::load_for_filename(
          data,
          filename=selected_filename,
          target?,
        ) {
        Ok(input) =>
          match
            project_input_load_libraries(
              path,
              selected_filename,
              libraries,
              None,
              target,
            ) {
            Ok(loaded_libraries) =>
              Ok(
                input
                .with_default_filename(selected_filename)
                .with_extra_libraries(loaded_libraries),
              )
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn Project::load_file_for_filename(
  path : String,
  filename? : String,
  libraries? : Array[String] = [],
  target? : @core_theory.Target,
) -> Result[Project, String] {
  project_from_input_result(
    ProjectInput::load_file_for_filename(path, filename?, libraries~, target?),
  )
}
