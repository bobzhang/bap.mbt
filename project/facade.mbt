///|
pub fn empty(target : @core_theory.Target) -> Project {
  Project::empty(target)
}

///|
pub fn create(
  input : ProjectInput,
  pkg? : String,
  state? : ProjectState,
  disassembler? : String,
  driver_source? : ProjectDisassemblySource[ProjectDisassemblyDriver],
  brancher? : ProjectDisassemblySource[ProjectBrancher],
  symbolizer? : ProjectDisassemblySource[ProjectSymbolizer],
  rooter? : ProjectDisassemblySource[ProjectRooter],
  reconstructor? : ProjectDisassemblySource[ProjectReconstructor],
) -> Result[Project, String] {
  Project::create_from_input(
    input,
    disassembler?,
    driver_source?,
    brancher?,
    symbolizer?,
    rooter?,
    reconstructor?,
    state?,
    pkg?,
  )
}

///|
pub fn state(project : Project) -> ProjectState {
  project.state()
}

///|
pub fn arch(project : Project) -> @core_theory.Target {
  project.arch()
}

///|
pub fn target(project : Project) -> @core_theory.Target {
  project.target()
}

///|
pub fn specification(project : Project) -> @image.OgreDoc {
  project.specification()
}

///|
pub fn program(project : Project) -> @types.Term[@types.Program] {
  project.program()
}

///|
pub fn with_program(
  project : Project,
  program : @types.Term[@types.Program],
) -> Project {
  project.with_program(program)
}

///|
pub fn symbols(project : Project) -> Array[@image.Symbol] {
  project.symbols()
}

///|
pub fn with_symbols(
  project : Project,
  symbols : Array[@image.Symbol],
) -> Project {
  project.with_symbols(symbols)
}

///|
pub fn storage(project : Project) -> Map[String, String] {
  project.storage()
}

///|
pub fn with_storage(
  project : Project,
  storage : Map[String, String],
) -> Project {
  project.with_storage(storage)
}

///|
pub fn memory(project : Project) -> @memory.MemMap[String] {
  project.memory()
}

///|
pub fn with_memory(
  project : Project,
  memory : @memory.MemMap[String],
) -> Project {
  project.with_memory(memory)
}

///|
pub fn tag_memory(
  project : Project,
  memory : @memory.Memory,
  tag : String,
) -> Project {
  project.tag_memory(memory, tag)
}

///|
pub fn substitute(
  project : Project,
  memory : @memory.Memory,
  tag : String,
  value : String,
) -> Project {
  project.substitute(memory, tag, value)
}

///|
pub fn set(project : Project, key : String, value : String) -> Project {
  project.set(key, value)
}

///|
pub fn get(project : Project, key : String) -> String? {
  project.get(key)
}

///|
pub fn has(project : Project, key : String) -> Bool {
  project.has(key)
}

///|
pub fn del(project : Project, key : String) -> Project {
  project.del(key)
}

///|
pub fn libraries(project : Project) -> Array[Library] {
  project.libraries()
}

///|
pub fn disasm(project : Project) -> ProjectDisasm {
  project.disasm()
}

///|
pub fn map_program(
  project : Project,
  f : (@types.Term[@types.Program]) -> @types.Term[@types.Program],
) -> Project {
  project.map_program(f)
}

///|
pub fn restore_state(project : Project) -> Result[Unit, String] {
  project.restore_state()
}
