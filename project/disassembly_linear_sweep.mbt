///|
pub(all) suberror ProjectDisassemblyLinearSweepError {
  LinearSweepFailure(String)
} derive(Eq, Debug)

///|
pub extend ProjectDisassemblyLinearSweepError with Eq::{not_equal, equal}

///|
pub extend ProjectDisassemblyLinearSweepError with Debug::{to_repr}

///|
struct ProjectDisassemblyLinearSweep {
  backend_value : String
}

///|
pub fn ProjectDisassemblyLinearSweep::create(
  backend~ : String = "llvm",
) -> ProjectDisassemblyLinearSweep {
  { backend_value: backend, }
}

///|
pub fn ProjectDisassemblyLinearSweep::backend(
  self : ProjectDisassemblyLinearSweep,
) -> String {
  self.backend_value
}

///|
/// `Linear_sweep.sweep ?backend arch mem`: disassembles `mem` from its
/// start to its end with the Basic disassembler of `backend` for `target`
/// (see `ProjectDisassemblyBasic::lookup`), listing every instruction with
/// its memory, `None` for the invalid ones.
pub fn ProjectDisassemblyLinearSweep::sweep(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend~ : String = "llvm",
) -> Result[Array[(@memory.Memory, ProjectDisassemblyInstruction?)], String] {
  match project_disassembly_basic_for_target(target, backend) {
    Err(reason) => Err(reason)
    Ok(dis) => {
      let dis = dis.store_asm().store_kinds()
      Ok(dis.run(memory, init=(), return_=_ => [], stopped=(s, _) => s.insns()))
    }
  }
}

///|
pub fn ProjectDisassemblyLinearSweep::sweep_exn(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend~ : String = "llvm",
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] raise ProjectDisassemblyLinearSweepError {
  match ProjectDisassemblyLinearSweep::sweep(target, memory, backend~) {
    Ok(result) => result
    Err(reason) => raise LinearSweepFailure(reason)
  }
}

///|
pub fn Project::linear_sweep(
  self : Project,
  memory : @memory.Memory,
  backend~ : String = "llvm",
) -> Result[Array[(@memory.Memory, ProjectDisassemblyInstruction?)], String] {
  ProjectDisassemblyLinearSweep::sweep(self.target(), memory, backend~)
}

///|
pub fn Project::linear_sweep_exn(
  self : Project,
  memory : @memory.Memory,
  backend~ : String = "llvm",
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] raise ProjectDisassemblyLinearSweepError {
  ProjectDisassemblyLinearSweep::sweep_exn(self.target(), memory, backend~)
}
