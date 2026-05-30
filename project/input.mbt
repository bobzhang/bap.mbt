///|
struct ProjectInput {
  target_value : @core_theory.Target
  filename_value : String?
  image_value : @image.Image?
  program_value : @types.Term[@types.Program]?
  memory_value : @memory.MemMap[String]
  symbols_value : Array[@image.Symbol]
  libraries_value : Array[Library]
  finish_fn : (Project) -> Project
}

///|
struct ProjectInputLoader {
  name_value : String
  description_value : String
  extensions_value : Array[String]
  priority_value : Int
  load_fn : (Bytes) -> Result[ProjectInput, String]
}

///|
let input_loader_registry : Map[String, ProjectInputLoader] = {}

///|
fn identity_project(project : Project) -> Project {
  project
}

///|
fn project_input_add_memory_entries(
  target : @memory.MemMap[String],
  source : @memory.MemMap[String],
) -> @memory.MemMap[String] {
  let mut result = target
  for entry in source.entries() {
    result = result.add(entry.0, entry.1)
  }
  result
}

///|
fn project_input_union_memory(
  code : @memory.MemMap[String]?,
  data : @memory.MemMap[String]?,
) -> @memory.MemMap[String] {
  let mut result = @memory.MemMap::empty()
  match code {
    Some(map) => result = project_input_add_memory_entries(result, map)
    None => ()
  }
  match data {
    Some(map) => result = project_input_add_memory_entries(result, map)
    None => ()
  }
  result
}

///|
pub fn ProjectInput::custom(
  target~ : @core_theory.Target,
  filename? : String,
  image? : @image.Image,
  program? : @types.Term[@types.Program],
  memory? : @memory.MemMap[String],
  symbols? : Array[@image.Symbol],
  libraries? : Array[Library],
  finish? : (Project) -> Project,
) -> ProjectInput {
  {
    target_value: target,
    filename_value: filename,
    image_value: image,
    program_value: program,
    memory_value: match memory {
      Some(map) => map
      None => @memory.MemMap::empty()
    },
    symbols_value: match symbols {
      Some(items) => items.copy()
      None =>
        match image {
          Some(value) => value.symbols()
          None => []
        }
    },
    libraries_value: match libraries {
      Some(items) => items.copy()
      None => []
    },
    finish_fn: match finish {
      Some(f) => f
      None => identity_project
    },
  }
}

///|
pub fn ProjectInput::create(
  target~ : @core_theory.Target,
  filename~ : String,
  code? : @memory.MemMap[String],
  data? : @memory.MemMap[String],
  finish? : (Project) -> Project,
) -> ProjectInput {
  ProjectInput::custom(
    target~,
    filename~,
    memory=project_input_union_memory(code, data),
    finish?,
  )
}

///|
pub fn ProjectInput::from_image(
  image : @image.Image,
  target? : @core_theory.Target,
  program? : @types.Term[@types.Program],
  finish? : (Project) -> Project,
) -> ProjectInput {
  let selected_target = match target {
    Some(value) => value
    None =>
      match image.target() {
        Some(value) => value
        None => @core_theory.Target::unknown()
      }
  }
  ProjectInput::custom(
    target=selected_target,
    filename?=image.filename(),
    image~,
    program?,
    memory=image.memory(),
    symbols=image.symbols(),
    finish?,
  )
}

///|
pub fn ProjectInput::from_bytes(
  target~ : @core_theory.Target,
  data : Bytes,
  endian~ : @bitvec.Endian,
  base? : UInt64 = 0UL,
  filename? : String,
  finish? : (Project) -> Project,
) -> ProjectInput {
  ProjectInput::from_raw_bytes(
    target~,
    data,
    endian~,
    base~,
    filename?,
    finish?,
    segment_name=".raw",
  )
}

///|
fn ProjectInput::from_raw_bytes(
  target~ : @core_theory.Target,
  data : Bytes,
  endian~ : @bitvec.Endian,
  base? : UInt64 = 0UL,
  filename? : String,
  finish? : (Project) -> Project,
  segment_name~ : String,
) -> ProjectInput {
  let segment = @image.Segment::create(
    name=segment_name,
    endian~,
    addr=base,
    data,
    readable=true,
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=base,
    endian~,
    [segment],
    filename?,
    target~,
  )
  ProjectInput::from_image(image, target~, finish?)
}

///|
pub fn ProjectInput::raw_bytes(
  target~ : @core_theory.Target,
  data : Bytes,
  base? : UInt64 = 0UL,
  filename? : String,
  finish? : (Project) -> Project,
) -> Result[ProjectInput, String] {
  if data.length() == 0 {
    Err("raw project input is empty")
  } else {
    Ok(
      ProjectInput::from_raw_bytes(
        target~,
        data,
        endian=project_raw_endian(target),
        base~,
        filename?,
        finish?,
        segment_name="bap.user",
      ),
    )
  }
}

///|
pub fn ProjectInput::from_bigstring(
  target~ : @core_theory.Target,
  data : Bytes,
  base? : UInt64 = 0UL,
  filename? : String,
  finish? : (Project) -> Project,
) -> Result[ProjectInput, String] {
  ProjectInput::raw_bytes(target~, data, base~, filename?, finish?)
}

///|
pub fn ProjectInput::from_string(
  target~ : @core_theory.Target,
  text : String,
  base? : UInt64 = 0UL,
  filename? : String,
  finish? : (Project) -> Project,
) -> Result[ProjectInput, String] {
  ProjectInput::raw_bytes(
    target~,
    @utf8.encode(text),
    base~,
    filename?,
    finish?,
  )
}

///|
pub fn ProjectInput::target(self : ProjectInput) -> @core_theory.Target {
  self.target_value
}

///|
pub fn ProjectInput::filename(self : ProjectInput) -> String? {
  self.filename_value
}

///|
pub fn ProjectInput::image(self : ProjectInput) -> @image.Image? {
  self.image_value
}

///|
pub fn ProjectInput::memory(self : ProjectInput) -> @memory.MemMap[String] {
  self.memory_value
}

///|
pub fn ProjectInput::symbols(self : ProjectInput) -> Array[@image.Symbol] {
  self.symbols_value.copy()
}

///|
pub fn ProjectInput::libraries(self : ProjectInput) -> Array[Library] {
  self.libraries_value.copy()
}

///|
pub fn ProjectInputLoader::create(
  name~ : String,
  description? : String,
  extensions? : Array[String],
  priority? : Int,
  load~ : (Bytes) -> Result[ProjectInput, String],
) -> ProjectInputLoader {
  {
    name_value: name,
    description_value: match description {
      Some(text) => text
      None => ""
    },
    extensions_value: match extensions {
      Some(items) => items.copy()
      None => []
    },
    priority_value: match priority {
      Some(value) => value
      None => 0
    },
    load_fn: load,
  }
}

///|
pub fn ProjectInputLoader::name(self : ProjectInputLoader) -> String {
  self.name_value
}

///|
pub fn ProjectInputLoader::description(self : ProjectInputLoader) -> String {
  self.description_value
}

///|
pub fn ProjectInputLoader::extensions(
  self : ProjectInputLoader,
) -> Array[String] {
  self.extensions_value.copy()
}

///|
pub fn ProjectInputLoader::priority(self : ProjectInputLoader) -> Int {
  self.priority_value
}

///|
pub fn ProjectInputLoader::supports_extension(
  self : ProjectInputLoader,
  extension : String,
) -> Bool {
  self.extensions_value.any(item => item == extension)
}

///|
pub fn ProjectInputLoader::load(
  self : ProjectInputLoader,
  data : Bytes,
) -> Result[ProjectInput, String] {
  (self.load_fn)(data)
}

///|
pub fn register_input_loader(
  loader : ProjectInputLoader,
) -> Result[Unit, String] {
  let name = loader.name()
  if input_loader_registry.contains(name) {
    Err("project input loader \{name} is already registered")
  } else {
    input_loader_registry[name] = loader
    Ok(())
  }
}

///|
pub fn register_builtin_input_loaders() -> Result[Unit, String] {
  @image.register_builtin_backends()
}

///|
pub fn find_input_loader(name : String) -> ProjectInputLoader? {
  input_loader_registry.get(name)
}

///|
fn push_unique_string(items : Array[String], item : String) -> Unit {
  if !items.contains(item) {
    items.push(item)
  }
}

///|
pub fn available_input_loaders() -> Array[String] {
  let names = []
  input_loader_registry.each((name, _) => names.push(name))
  for name in @image.available_backends() {
    push_unique_string(names, name)
  }
  names
}

///|
pub fn input_loaders_for_extension(
  extension : String,
) -> Array[ProjectInputLoader] {
  let result = []
  input_loader_registry.each((_, loader) => {
    if loader.supports_extension(extension) {
      result.push(loader)
    }
  })
  result.sort_by((left, right) => right.priority().compare(left.priority()))
  result
}

///|
pub fn input_loader_names_for_extension(extension : String) -> Array[String] {
  let names = [
    for loader in input_loaders_for_extension(extension) => loader.name()
  ]
  for name in @image.backend_names_for_extension(extension) {
    push_unique_string(names, name)
  }
  names
}

///|
pub fn ProjectInput::load(
  data : Bytes,
  loader~ : String,
) -> Result[ProjectInput, String] {
  match find_input_loader(loader) {
    Some(input_loader) => input_loader.load(data)
    None =>
      match @image.Image::of_bytes(data, backend=loader) {
        Ok((image, _warnings)) => Ok(ProjectInput::from_image(image))
        Err(reason) =>
          Err(
            "unknown project input loader or image backend \{loader}: \{reason}",
          )
      }
  }
}

///|
fn filename_extension(filename : String) -> String? {
  let parts = filename.split(".").to_array()
  if parts.length() > 1 {
    Some(parts[parts.length() - 1].to_owned().to_lower())
  } else {
    None
  }
}

///|
pub fn ProjectInput::load_for_filename(
  data : Bytes,
  filename~ : String,
) -> Result[ProjectInput, String] {
  match filename_extension(filename) {
    Some(extension) => {
      let loaders = input_loaders_for_extension(extension)
      if !loaders.is_empty() {
        let mut last_error = ""
        for loader in loaders {
          match loader.load(data) {
            Ok(input) => return Ok(input)
            Err(reason) => last_error = reason
          }
        }
        match @image.Image::of_bytes_for_filename(data, filename~) {
          Ok((image, _warnings)) =>
            return Ok(
              ProjectInput::from_image(image).with_default_filename(filename),
            )
          Err(reason) =>
            return Err(
              "all project input loaders failed for extension \{extension}: \{last_error}; image backend fallback failed: \{reason}",
            )
        }
      }
      match @image.Image::of_bytes_for_filename(data, filename~) {
        Ok((image, _warnings)) =>
          Ok(ProjectInput::from_image(image).with_default_filename(filename))
        Err(reason) =>
          Err(
            "no project input loader or image backend for extension \{extension}: \{reason}",
          )
      }
    }
    None => Err("can't infer project input loader from filename \{filename}")
  }
}

///|
pub fn Project::from_input(input : ProjectInput) -> Project {
  let project = Project::create(
    target=input.target_value,
    image?=input.image_value,
    filename?=input.filename_value,
    program?=input.program_value,
    memory=input.memory_value,
    symbols=input.symbols_value,
    libraries=input.libraries_value,
  )
  (input.finish_fn)(project)
}
