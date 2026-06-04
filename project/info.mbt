///|
enum ProjectInfo {
  ProjectInfoNamespace
}

///|
let project_info_marker : ProjectInfo = ProjectInfoNamespace

///|
fn project_info_namespace() -> Unit {
  ignore(project_info_marker)
}

///|
let project_info_file_pair : (@future.Stream[String], @future.Signal[String]) = @future.Stream::create()

///|
let project_info_arch_pair : (
  @future.Stream[@core_theory.Target],
  @future.Signal[@core_theory.Target],
) = @future.Stream::create()

///|
let project_info_data_pair : (
  @future.Stream[@memory.MemMap[String]],
  @future.Signal[@memory.MemMap[String]],
) = @future.Stream::create()

///|
let project_info_code_pair : (
  @future.Stream[@memory.MemMap[String]],
  @future.Signal[@memory.MemMap[String]],
) = @future.Stream::create()

///|
let project_info_cfg_pair : (
  @future.Stream[ProjectDisassemblyCfg],
  @future.Signal[ProjectDisassemblyCfg],
) = @future.Stream::create()

///|
let project_info_symtab_pair : (
  @future.Stream[ProjectDisassemblySymtab],
  @future.Signal[ProjectDisassemblySymtab],
) = @future.Stream::create()

///|
let project_info_program_pair : (
  @future.Stream[@types.Term[@types.Program]],
  @future.Signal[@types.Term[@types.Program]],
) = @future.Stream::create()

///|
let project_info_spec_pair : (
  @future.Stream[@image.OgreDoc],
  @future.Signal[@image.OgreDoc],
) = @future.Stream::create()

///|
pub fn ProjectInfo::file() -> @future.Stream[String] {
  project_info_namespace()
  project_info_file_pair.0
}

///|
pub fn ProjectInfo::arch() -> @future.Stream[@core_theory.Target] {
  project_info_namespace()
  project_info_arch_pair.0
}

///|
pub fn ProjectInfo::data() -> @future.Stream[@memory.MemMap[String]] {
  project_info_namespace()
  project_info_data_pair.0
}

///|
pub fn ProjectInfo::code() -> @future.Stream[@memory.MemMap[String]] {
  project_info_namespace()
  project_info_code_pair.0
}

///|
pub fn ProjectInfo::cfg() -> @future.Stream[ProjectDisassemblyCfg] {
  project_info_namespace()
  project_info_cfg_pair.0
}

///|
pub fn ProjectInfo::symtab() -> @future.Stream[ProjectDisassemblySymtab] {
  project_info_namespace()
  project_info_symtab_pair.0
}

///|
pub fn ProjectInfo::program() -> @future.Stream[@types.Term[@types.Program]] {
  project_info_namespace()
  project_info_program_pair.0
}

///|
pub fn ProjectInfo::spec() -> @future.Stream[@image.OgreDoc] {
  project_info_namespace()
  project_info_spec_pair.0
}

///|
fn project_info_named_memory(
  memory : @memory.MemMap[String],
  name : String,
) -> @memory.MemMap[String] {
  memory.filter(label => label == name)
}

///|
fn project_info_emit_input(project : Project) -> Unit {
  match project.filename() {
    Some(filename) => project_info_file_pair.1.send(filename)
    None => ()
  }
  let memory = project.memory()
  project_info_arch_pair.1.send(project.arch())
  project_info_data_pair.1.send(project_info_named_memory(memory, "data"))
  project_info_code_pair.1.send(project_info_named_memory(memory, "code"))
  project_info_spec_pair.1.send(project.specification())
}

///|
fn project_info_emit_reconstructed(project : Project) -> Unit {
  project_info_cfg_pair.1.send(project.disassembly_cfg())
  project_info_symtab_pair.1.send(project.disassembly_symtab())
  project_info_program_pair.1.send(project.program())
}
