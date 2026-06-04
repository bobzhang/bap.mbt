///|
pub(all) suberror ProjectDisassemblyLinearSweepError {
  LinearSweepFailure(String)
} derive(Eq, Debug)

///|
struct ProjectDisassemblyLinearSweep {
  backend_value : String
}

///|
pub fn ProjectDisassemblyLinearSweep::create(
  backend? : String = "raw",
) -> ProjectDisassemblyLinearSweep {
  { backend_value: backend }
}

///|
pub fn ProjectDisassemblyLinearSweep::backend(
  self : ProjectDisassemblyLinearSweep,
) -> String {
  self.backend_value
}

///|
fn project_disassembly_linear_sweep_instruction(
  memory : @memory.Memory,
) -> ProjectDisassemblyInstruction {
  project_raw_byte_instruction(memory)
}

///|
pub fn ProjectDisassemblyLinearSweep::sweep(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend? : String = "raw",
) -> Result[Array[(@memory.Memory, ProjectDisassemblyInstruction?)], String] {
  let _ = target
  let _ = backend
  let result : Array[(@memory.Memory, ProjectDisassemblyInstruction?)] = []
  for offset in 0..<memory.length() {
    let addr = memory.min_addr() + offset.to_uint64()
    match memory.view(from=addr, words=1) {
      Ok(chunk) =>
        result.push(
          (chunk, Some(project_disassembly_linear_sweep_instruction(chunk))),
        )
      Err(reason) => return Err(reason)
    }
  }
  Ok(result)
}

///|
pub fn ProjectDisassemblyLinearSweep::sweep_exn(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend? : String = "raw",
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
  backend? : String = "raw",
) -> Result[Array[(@memory.Memory, ProjectDisassemblyInstruction?)], String] {
  ProjectDisassemblyLinearSweep::sweep(self.target(), memory, backend~)
}

///|
pub fn Project::linear_sweep_exn(
  self : Project,
  memory : @memory.Memory,
  backend? : String = "raw",
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] raise ProjectDisassemblyLinearSweepError {
  ProjectDisassemblyLinearSweep::sweep_exn(self.target(), memory, backend~)
}
