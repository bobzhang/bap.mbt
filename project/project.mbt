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
fn project_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="bap")
}

///|
fn project_memory_equal(lhs : @memory.Memory, rhs : @memory.Memory) -> Bool {
  lhs.endian() == rhs.endian() &&
  lhs.min_addr() == rhs.min_addr() &&
  lhs.max_addr() == rhs.max_addr() &&
  lhs.to_bytes() == rhs.to_bytes()
}

///|
fn project_memory_maps_equal(
  lhs : @memory.MemMap[String],
  rhs : @memory.MemMap[String],
) -> Bool {
  let lhs_entries = lhs.entries()
  let rhs_entries = rhs.entries()
  if lhs_entries.length() != rhs_entries.length() {
    return false
  }
  for i in 0..<lhs_entries.length() {
    if !project_memory_equal(lhs_entries[i].0, rhs_entries[i].0) ||
      lhs_entries[i].1 != rhs_entries[i].1 {
      return false
    }
  }
  true
}

///|
fn project_memory_order(
  lhs : @memory.MemMap[String],
  rhs : @memory.MemMap[String],
) -> @knowledge.PartialOrder {
  if project_memory_maps_equal(lhs, rhs) {
    Equal
  } else if lhs.length() == 0 {
    Less
  } else if rhs.length() == 0 {
    Greater
  } else {
    Incomparable
  }
}

///|
fn project_memory_inspect(memory : @memory.MemMap[String]) -> String {
  let entries = memory.entries()
  if entries.is_empty() {
    "{}"
  } else {
    entries.map(entry => "\{entry.0.to_string()} => \{entry.1}").join("; ")
  }
}

///|
fn project_memory_domain() -> @knowledge.Domain[@memory.MemMap[String]] {
  let empty : @memory.MemMap[String] = @memory.MemMap::empty()
  @knowledge.Domain::custom(
    project_name("unit-memory"),
    project_memory_inspect,
    empty~,
    order=project_memory_order,
  )
}

///|
pub fn memory_slot() -> @knowledge.Slot[Unit, @memory.MemMap[String]] {
  @core_theory.ProgramUnit::cls().property(
    name=project_name("unit-memory"),
    domain=project_memory_domain(),
    desc="annotated memory regions of the unit",
    public=true,
  )
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
pub fn Project::restore_state(self : Project) -> Result[Unit, String] {
  let _ = self
  Err(
    "Project.restore_state: this function should no be used. Please use the Toplevel module to save/restore the state.",
  )
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
pub fn Project::relocations(self : Project) -> Array[@image.Relocation] {
  match self.image_value {
    Some(image) => image.relocations()
    None => []
  }
}

///|
pub fn Project::external_references(
  self : Project,
) -> Array[@image.ExternalReference] {
  match self.image_value {
    Some(image) => image.external_references()
    None => []
  }
}

///|
pub fn Project::required_libraries(self : Project) -> Array[String] {
  match self.image_value {
    Some(image) => image.required_libraries()
    None => []
  }
}

///|
pub fn Project::rpaths(self : Project) -> Array[String] {
  match self.image_value {
    Some(image) => image.rpaths()
    None => []
  }
}

///|
pub fn Project::runpaths(self : Project) -> Array[String] {
  match self.image_value {
    Some(image) => image.runpaths()
    None => []
  }
}

///|
pub fn Project::symbol_values(self : Project) -> Array[@image.SymbolValue] {
  match self.image_value {
    Some(image) => image.symbol_values()
    None => []
  }
}

///|
pub fn Project::interpreter(self : Project) -> String? {
  match self.image_value {
    Some(image) => image.interpreter()
    None => None
  }
}

///|
pub fn Project::soname(self : Project) -> String? {
  match self.image_value {
    Some(image) => image.soname()
    None => None
  }
}

///|
pub fn Project::load_bias(self : Project) -> Int64? {
  match self.image_value {
    Some(image) => image.load_bias()
    None => None
  }
}

///|
pub fn Project::is_executable(self : Project) -> Bool? {
  match self.image_value {
    Some(image) => image.is_executable()
    None => None
  }
}

///|
pub fn Project::base_address(self : Project) -> UInt64? {
  match self.image_value {
    Some(image) => image.base_address()
    None => None
  }
}

///|
pub fn Project::with_applied_relocations(
  self : Project,
) -> Result[Project, String] {
  match self.image_value {
    Some(image) =>
      match image.with_applied_relocations() {
        Ok(updated) =>
          Ok({
            ..self,
            image_value: Some(updated),
            memory_value: updated.memory(),
          })
        Err(reason) => Err(reason)
      }
    None => Ok(self)
  }
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
fn project_persistent_endian(endian : @bitvec.Endian) -> String {
  match endian {
    LittleEndian => "little"
    BigEndian => "big"
  }
}

///|
fn project_read_persistent_endian(
  input : String,
) -> Result[@bitvec.Endian, String] {
  match input {
    "little" => Ok(LittleEndian)
    "big" => Ok(BigEndian)
    _ => Err("invalid persistent project memory endian")
  }
}

///|
fn project_read_persistent_uint64(input : String) -> Result[UInt64, String] {
  try @string.parse_uint64(input) catch {
    _ => Err("invalid persistent project memory address")
  } noraise {
    value => Ok(value)
  }
}

///|
fn project_memory_entry_persistent() -> @knowledge.Persistent[
  (@memory.Memory, String),
] {
  let bytes_codec = @knowledge.Persistent::bytes()
  @knowledge.Persistent::convert(
    to_persistent=entry => {
      [
        project_persistent_endian(entry.0.endian()),
        entry.0.min_addr().to_string(),
        bytes_codec.encode(entry.0.to_bytes()),
        entry.1,
      ]
    },
    of_persistent=fields => {
      if fields.length() != 4 {
        return Err("invalid persistent project memory entry")
      }
      let endian = match project_read_persistent_endian(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let start = match project_read_persistent_uint64(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let data = match bytes_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok((@memory.Memory::from_bytes(endian~, start~, data), fields[3]))
    },
    @knowledge.Persistent::array(@knowledge.Persistent::string()),
  )
}

///|
fn project_memory_persistent() -> @knowledge.Persistent[@memory.MemMap[String]] {
  let entries_codec = @knowledge.Persistent::array(
    project_memory_entry_persistent(),
  )
  @knowledge.Persistent::convert(
    to_persistent=memory => memory.entries(),
    of_persistent=entries => {
      let mut memory = @memory.MemMap::empty()
      for entry in entries {
        memory = memory.add(entry.0, entry.1)
      }
      Ok(memory)
    },
    entries_codec,
  )
}

///|
pub fn Project::persistent() -> @knowledge.Persistent[Project] {
  let target_codec = @core_theory.Target::persistent()
  let filename_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::string(),
  )
  let storage_codec = @knowledge.Persistent::map(
    @knowledge.Persistent::string(),
    @knowledge.Persistent::string(),
  )
  let memory_codec = project_memory_persistent()
  @knowledge.Persistent::convert(
    to_persistent=project => {
      [
        target_codec.encode(project.target_value),
        filename_codec.encode(project.filename_value),
        storage_codec.encode(project.storage_value),
        memory_codec.encode(project.memory_value),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 && fields.length() != 4 {
        return Err("invalid persistent project encoding")
      }
      let target = match target_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let filename = match filename_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let storage = match storage_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let memory = if fields.length() == 4 {
        match memory_codec.decode(fields[3]) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
      } else {
        @memory.MemMap::empty()
      }
      Ok(Project::create(target~, filename?, storage~, memory~))
    },
    @knowledge.Persistent::array(@knowledge.Persistent::string()),
  )
}

///|
pub fn Project::set(self : Project, key : String, value : String) -> Project {
  let storage = self.storage_value.copy()
  storage[key] = value
  { ..self, storage_value: storage }
}

///|
pub fn Project::get(self : Project, key : String) -> String? {
  match self.storage_value.get(key) {
    Some(value) => Some(value)
    None => if key == "filename" { self.filename_value } else { None }
  }
}

///|
pub fn Project::has(self : Project, key : String) -> Bool {
  self.storage_value.contains(key) ||
  (key == "filename" && self.filename_value is Some(_))
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
