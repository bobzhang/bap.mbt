///|
pub(all) enum ProjectDisassemblyRecError {
  FailedToDisasm(@memory.Memory)
  FailedToLift(@memory.Memory, ProjectDisassemblyInstruction, String)
}

///|
struct ProjectDisassemblyRec {
  project_value : Project
  errors_value : Array[ProjectDisassemblyRecError]
}

///|
fn project_disassembly_rec_driver(
  project : Project,
  driver : String?,
) -> Result[Project, String] {
  match driver {
    Some(name) => project.disassemble(driver=name)
    None => project.disassemble_with_available()
  }
}

///|
fn project_disassembly_rec_apply_brancher(
  project : Project,
  brancher : ProjectBrancher?,
) -> Result[Project, String] {
  match brancher {
    Some(value) => project.apply_brancher(brancher=value)
    None => Ok(project)
  }
}

///|
pub fn ProjectDisassemblyRecError::failed_to_disasm(
  memory : @memory.Memory,
) -> ProjectDisassemblyRecError {
  FailedToDisasm(memory)
}

///|
pub fn ProjectDisassemblyRecError::failed_to_lift(
  memory : @memory.Memory,
  instruction : ProjectDisassemblyInstruction,
  reason : String,
) -> ProjectDisassemblyRecError {
  FailedToLift(memory, instruction, reason)
}

///|
pub fn ProjectDisassemblyRecError::memory(
  self : ProjectDisassemblyRecError,
) -> @memory.Memory {
  match self {
    FailedToDisasm(memory) => memory
    FailedToLift(memory, _, _) => memory
  }
}

///|
pub fn ProjectDisassemblyRecError::instruction(
  self : ProjectDisassemblyRecError,
) -> ProjectDisassemblyInstruction? {
  match self {
    FailedToDisasm(_) => None
    FailedToLift(_, instruction, _) => Some(instruction)
  }
}

///|
pub fn ProjectDisassemblyRecError::reason(
  self : ProjectDisassemblyRecError,
) -> String? {
  match self {
    FailedToDisasm(_) => None
    FailedToLift(_, _, reason) => Some(reason)
  }
}

///|
pub fn ProjectDisassemblyRecError::to_string(
  self : ProjectDisassemblyRecError,
) -> String {
  let memory = self.memory()
  let span = "0x\{memory.min_addr().to_string(radix=16)}-0x\{memory.max_addr().to_string(radix=16)}"
  match self {
    FailedToDisasm(_) => "failed to disassemble \{span}"
    FailedToLift(_, instruction, reason) =>
      "failed to lift \{instruction.assembly()} at \{span}: \{reason}"
  }
}

///|
pub fn ProjectDisassemblyRec::create(
  project : Project,
  errors? : Array[ProjectDisassemblyRecError],
) -> ProjectDisassemblyRec {
  {
    project_value: project,
    errors_value: match errors {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn ProjectDisassemblyRec::project(self : ProjectDisassemblyRec) -> Project {
  self.project_value
}

///|
pub fn ProjectDisassemblyRec::disassembly(
  self : ProjectDisassemblyRec,
) -> ProjectDisassemblyState {
  self.project_value.disassembly()
}

///|
pub fn ProjectDisassemblyRec::cfg(
  self : ProjectDisassemblyRec,
) -> ProjectDisassemblyCfg {
  self.disassembly().cfg()
}

///|
pub fn ProjectDisassemblyRec::errors(
  self : ProjectDisassemblyRec,
) -> Array[ProjectDisassemblyRecError] {
  self.errors_value.copy()
}

///|
pub fn ProjectDisassemblyRec::has_errors(self : ProjectDisassemblyRec) -> Bool {
  !self.errors_value.is_empty()
}

///|
pub fn ProjectDisassemblyRec::run(
  project : Project,
  driver? : String,
  brancher? : ProjectBrancher,
) -> Result[ProjectDisassemblyRec, String] {
  match project_disassembly_rec_driver(project, driver) {
    Ok(disassembled) =>
      match project_disassembly_rec_apply_brancher(disassembled, brancher) {
        Ok(branched) => Ok(ProjectDisassemblyRec::create(branched))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectDisassemblyRec::scan(
  project : Project,
  driver? : String,
  brancher? : ProjectBrancher,
) -> Result[ProjectDisassemblyState, String] {
  match ProjectDisassemblyRec::run(project, driver?, brancher?) {
    Ok(result) => Ok(result.disassembly())
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectDisassemblyRec::global_cfg(
  disassembly : ProjectDisassemblyState,
) -> ProjectDisassemblyCfg {
  disassembly.cfg()
}

///|
pub fn Project::disassembly_rec(self : Project) -> ProjectDisassemblyRec {
  ProjectDisassemblyRec::create(self)
}

///|
pub fn Project::disassemble_rec(
  self : Project,
  driver? : String,
  brancher? : ProjectBrancher,
) -> Result[ProjectDisassemblyRec, String] {
  ProjectDisassemblyRec::run(self, driver?, brancher?)
}
