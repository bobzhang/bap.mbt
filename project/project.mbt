///|
struct Library {
  name_value : String
  unit_value : @core_theory.ProgramUnit
  target_value : @core_theory.Target
  memory_value : @memory.MemMap[String]
  symbols_value : Array[@image.Symbol]
  program_value : @types.Term[@types.Program]
  state_value : ProjectState
}

///|
struct Project {
  target_value : @core_theory.Target
  image_value : @image.Image?
  filename_value : String?
  program_value : @types.Term[@types.Program]
  memory_value : @memory.MemMap[String]
  symbols_value : Array[@image.Symbol]
  storage_value : Map[String, String]
  libraries_value : Array[Library]
  state_value : ProjectState
}

///|
pub fn Library::create(
  name~ : String,
  target~ : @core_theory.Target,
  unit? : @core_theory.ProgramUnit,
  memory? : @memory.MemMap[String],
  symbols? : Array[@image.Symbol],
  program? : @types.Term[@types.Program],
  state? : ProjectState,
) -> Library {
  {
    name_value: name,
    unit_value: match unit {
      Some(value) => value
      None => @core_theory.ProgramUnit::for_file(name, target~)
    },
    target_value: target,
    memory_value: match memory {
      Some(map) => map
      None => @memory.MemMap::empty()
    },
    symbols_value: match symbols {
      Some(items) => items.copy()
      None => []
    },
    program_value: match program {
      Some(term) => term
      None => @types.Program::create()
    },
    state_value: match state {
      Some(value) => value
      None => ProjectState::empty()
    },
  }
}

///|
pub fn Library::name(self : Library) -> String {
  self.name_value
}

///|
pub fn Library::unit(self : Library) -> @core_theory.ProgramUnit {
  self.unit_value
}

///|
pub fn Library::target(self : Library) -> @core_theory.Target {
  self.target_value
}

///|
pub fn Library::arch(self : Library) -> @core_theory.Target {
  self.target_value
}

///|
pub fn Library::specification(self : Library) -> @image.OgreDoc {
  @image.OgreDoc::from_target(self.target_value)
}

///|
pub fn Library::memory(self : Library) -> @memory.MemMap[String] {
  self.memory_value
}

///|
pub fn Library::symbols(self : Library) -> Array[@image.Symbol] {
  self.symbols_value.copy()
}

///|
pub fn Library::program(self : Library) -> @types.Term[@types.Program] {
  self.program_value
}

///|
pub fn Library::state(self : Library) -> ProjectState {
  self.state_value
}

///|
pub fn Library::disassembly(self : Library) -> ProjectDisassemblyState {
  self.state_value.disassembly()
}

///|
pub fn Project::empty(target : @core_theory.Target) -> Project {
  {
    target_value: target,
    image_value: None,
    filename_value: None,
    program_value: @types.Program::create(),
    memory_value: @memory.MemMap::empty(),
    symbols_value: [],
    storage_value: {},
    libraries_value: [],
    state_value: ProjectState::empty(),
  }
}

///|
pub fn Project::create(
  target~ : @core_theory.Target,
  image? : @image.Image,
  filename? : String,
  program? : @types.Term[@types.Program],
  memory? : @memory.MemMap[String],
  symbols? : Array[@image.Symbol],
  storage? : Map[String, String],
  libraries? : Array[Library],
  state? : ProjectState,
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
    symbols_value: match symbols {
      Some(items) => items.copy()
      None =>
        match image {
          Some(value) => value.symbols()
          None => []
        }
    },
    storage_value: match storage {
      Some(map) => map.copy()
      None => {}
    },
    libraries_value: match libraries {
      Some(items) => items.copy()
      None => []
    },
    state_value: match state {
      Some(value) => value
      None => ProjectState::empty()
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
pub fn Project::arch(self : Project) -> @core_theory.Target {
  self.target_value
}

///|
pub fn Project::specification(self : Project) -> @image.OgreDoc {
  match self.image_value {
    Some(image) => image.spec()
    None => @image.OgreDoc::from_target(self.target_value)
  }
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
pub fn Project::state(self : Project) -> ProjectState {
  self.state_value
}

///|
pub fn Project::with_state(self : Project, state : ProjectState) -> Project {
  { ..self, state_value: state }
}

///|
pub fn Project::disassembly(self : Project) -> ProjectDisassemblyState {
  self.state_value.disassembly()
}

///|
pub fn Project::with_disassembly(
  self : Project,
  disassembly : ProjectDisassemblyState,
) -> Project {
  self.with_state(self.state_value.with_disassembly(disassembly))
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
pub fn Project::symbols(self : Project) -> Array[@image.Symbol] {
  self.symbols_value.copy()
}

///|
pub fn Project::with_symbols(
  self : Project,
  symbols : Array[@image.Symbol],
) -> Project {
  { ..self, symbols_value: symbols.copy() }
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
pub fn Project::with_storage(
  self : Project,
  storage : Map[String, String],
) -> Project {
  { ..self, storage_value: storage.copy() }
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
