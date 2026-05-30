///|
struct Library {
  name_value : String
  target_value : @core_theory.Target
  memory_value : @memory.MemMap[String]
  program_value : @types.Term[@types.Program]
}

///|
struct Project {
  target_value : @core_theory.Target
  image_value : @image.Image?
  filename_value : String?
  program_value : @types.Term[@types.Program]
  memory_value : @memory.MemMap[String]
  storage_value : Map[String, String]
  libraries_value : Array[Library]
}

///|
pub fn Library::create(
  name~ : String,
  target~ : @core_theory.Target,
  memory? : @memory.MemMap[String],
  program? : @types.Term[@types.Program],
) -> Library {
  {
    name_value: name,
    target_value: target,
    memory_value: match memory {
      Some(map) => map
      None => @memory.MemMap::empty()
    },
    program_value: match program {
      Some(term) => term
      None => @types.Program::create()
    },
  }
}

///|
pub fn Library::name(self : Library) -> String {
  self.name_value
}

///|
pub fn Library::target(self : Library) -> @core_theory.Target {
  self.target_value
}

///|
pub fn Library::memory(self : Library) -> @memory.MemMap[String] {
  self.memory_value
}

///|
pub fn Library::program(self : Library) -> @types.Term[@types.Program] {
  self.program_value
}

///|
pub fn Project::empty(target : @core_theory.Target) -> Project {
  {
    target_value: target,
    image_value: None,
    filename_value: None,
    program_value: @types.Program::create(),
    memory_value: @memory.MemMap::empty(),
    storage_value: {},
    libraries_value: [],
  }
}

///|
pub fn Project::create(
  target~ : @core_theory.Target,
  image? : @image.Image,
  filename? : String,
  program? : @types.Term[@types.Program],
  memory? : @memory.MemMap[String],
  storage? : Map[String, String],
  libraries? : Array[Library],
) -> Project {
  {
    target_value: target,
    image_value: image,
    filename_value: filename,
    program_value: match program {
      Some(term) => term
      None => @types.Program::create()
    },
    memory_value: match memory {
      Some(map) => map
      None => @memory.MemMap::empty()
    },
    storage_value: match storage {
      Some(map) => map.copy()
      None => {}
    },
    libraries_value: match libraries {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn Project::from_image(
  image : @image.Image,
  target? : @core_theory.Target,
  program? : @types.Term[@types.Program],
) -> Project {
  let selected_target = match target {
    Some(value) => value
    None =>
      match image.target() {
        Some(value) => value
        None => @core_theory.Target::unknown()
      }
  }
  Project::create(
    target=selected_target,
    image~,
    filename?=image.filename(),
    program?,
    memory=image.memory(),
  )
}

///|
pub fn Project::target(self : Project) -> @core_theory.Target {
  self.target_value
}

///|
pub fn Project::image(self : Project) -> @image.Image? {
  self.image_value
}

///|
pub fn Project::filename(self : Project) -> String? {
  self.filename_value
}

///|
pub fn Project::program(self : Project) -> @types.Term[@types.Program] {
  self.program_value
}

///|
pub fn Project::with_program(
  self : Project,
  program : @types.Term[@types.Program],
) -> Project {
  { ..self, program_value: program }
}

///|
pub fn Project::map_program(
  self : Project,
  f : (@types.Term[@types.Program]) -> @types.Term[@types.Program],
) -> Project {
  self.with_program(f(self.program_value))
}

///|
pub fn Project::memory(self : Project) -> @memory.MemMap[String] {
  self.memory_value
}

///|
pub fn Project::with_memory(
  self : Project,
  memory : @memory.MemMap[String],
) -> Project {
  { ..self, memory_value: memory }
}

///|
pub fn Project::tag_memory(
  self : Project,
  memory : @memory.Memory,
  tag : String,
) -> Project {
  self.with_memory(self.memory_value.add(memory, tag))
}

///|
pub fn Project::storage(self : Project) -> Map[String, String] {
  self.storage_value.copy()
}

///|
pub fn Project::set(self : Project, key : String, value : String) -> Project {
  let storage = self.storage_value.copy()
  storage[key] = value
  { ..self, storage_value: storage }
}

///|
pub fn Project::get(self : Project, key : String) -> String? {
  self.storage_value.get(key)
}

///|
pub fn Project::has(self : Project, key : String) -> Bool {
  self.storage_value.contains(key)
}

///|
pub fn Project::del(self : Project, key : String) -> Project {
  let storage = self.storage_value.copy()
  storage.remove(key)
  { ..self, storage_value: storage }
}

///|
pub fn Project::libraries(self : Project) -> Array[Library] {
  self.libraries_value.copy()
}

///|
pub fn Project::add_library(self : Project, library : Library) -> Project {
  let libraries = self.libraries_value.copy()
  libraries.push(library)
  { ..self, libraries_value: libraries }
}
