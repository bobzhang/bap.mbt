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
fn project_disassembly_rec_has_instruction_at(
  instructions : Array[ProjectDisassemblyInstruction],
  addr : UInt64,
) -> Bool {
  instructions.any(instruction => instruction.addr() == addr)
}

///|
fn project_disassembly_rec_add_start(
  starts : Array[UInt64],
  block : @memory.Memory,
  instructions : Array[ProjectDisassemblyInstruction],
  addr : UInt64,
) -> Unit {
  if block.contains(addr) &&
    project_disassembly_rec_has_instruction_at(instructions, addr) &&
    !starts.contains(addr) {
    starts.push(addr)
  }
}

///|
fn project_disassembly_rec_next_addr(
  instruction : ProjectDisassemblyInstruction,
) -> UInt64 {
  instruction.memory().max_addr() + 1UL
}

///|
fn project_disassembly_rec_add_signed_offset(
  base : UInt64,
  offset : Int64,
) -> UInt64? {
  if offset >= 0L {
    Some(base + offset.reinterpret_as_uint64())
  } else {
    let delta = (0L - offset).reinterpret_as_uint64()
    if base >= delta {
      Some(base - delta)
    } else {
      None
    }
  }
}

///|
fn project_disassembly_rec_call_target(
  instruction : ProjectDisassemblyInstruction,
) -> UInt64? {
  if !instruction.has_kind(ProjectCall) || instruction.operands().is_empty() {
    None
  } else {
    match instruction.operands()[0].to_int64() {
      Some(offset) =>
        project_disassembly_rec_add_signed_offset(
          project_disassembly_rec_next_addr(instruction),
          offset,
        )
      None => None
    }
  }
}

///|
fn project_disassembly_rec_direct_branch_target(
  instruction : ProjectDisassemblyInstruction,
) -> UInt64? {
  if !instruction.is_branch() || instruction.operands().is_empty() {
    None
  } else if instruction.encoding() is ("llvm-x86" | "llvm-x86_64") {
    // x86 instructions in LLVM's MCInst form: the immediate of a direct
    // branch is relative to the next instruction; the far branches, whose
    // immediates are a segment and an offset, are indirect
    if instruction.has_kind(ProjectIndirectBranch) {
      None
    } else {
      match instruction.operands()[0].to_int64() {
        Some(offset) =>
          project_disassembly_rec_add_signed_offset(
            project_disassembly_rec_next_addr(instruction),
            offset,
          )
        None => None
      }
    }
  } else {
    match instruction.operands()[0].to_int64() {
      Some(addr) if addr >= 0L => Some(addr.reinterpret_as_uint64())
      _ => None
    }
  }
}

///|
fn project_disassembly_rec_splits_after(
  instruction : ProjectDisassemblyInstruction,
) -> Bool {
  instruction.has_kind(ProjectCall) ||
  instruction.has_kind(ProjectTerminator) ||
  instruction.is_branch()
}

///|
fn project_disassembly_rec_split_starts(
  block : @memory.Memory,
  instructions : Array[ProjectDisassemblyInstruction],
) -> Array[UInt64] {
  let starts = [block.min_addr()]
  for instruction in instructions {
    if project_disassembly_rec_splits_after(instruction) {
      project_disassembly_rec_add_start(
        starts,
        block,
        instructions,
        project_disassembly_rec_next_addr(instruction),
      )
    }
    match project_disassembly_rec_call_target(instruction) {
      Some(target) =>
        project_disassembly_rec_add_start(starts, block, instructions, target)
      None => ()
    }
    match project_disassembly_rec_direct_branch_target(instruction) {
      Some(target) =>
        project_disassembly_rec_add_start(starts, block, instructions, target)
      None => ()
    }
  }
  starts.sort_by((left, right) => left.compare(right))
  starts
}

///|
fn project_disassembly_rec_split_block(
  block : @memory.Memory,
  instructions : Array[ProjectDisassemblyInstruction],
) -> Result[Array[@memory.Memory], String] {
  if instructions.is_empty() {
    Ok([block])
  } else {
    let starts = project_disassembly_rec_split_starts(block, instructions)
    let result : Array[@memory.Memory] = []
    for i in 0..<starts.length() {
      let start = starts[i]
      let end = if i + 1 < starts.length() {
        starts[i + 1] - 1UL
      } else {
        block.max_addr()
      }
      match block.view(from=start, words=(end - start + 1UL).to_int()) {
        Ok(slice) => result.push(slice)
        Err(reason) => return Err(reason)
      }
    }
    Ok(result)
  }
}

///|
fn project_disassembly_rec_control_edges(
  block : @memory.Memory,
  instructions : Array[ProjectDisassemblyInstruction],
) -> Array[ProjectDisassemblyEdge] {
  let edges : Array[ProjectDisassemblyEdge] = []
  for instruction in instructions {
    if instruction.has_kind(ProjectCall) {
      let fall = project_disassembly_rec_next_addr(instruction)
      if block.contains(fall) &&
        project_disassembly_rec_has_instruction_at(instructions, fall) {
        edges.push(
          ProjectDisassemblyEdge::create(
            source=instruction.addr(),
            target=fall,
            kind=FallEdge,
          ),
        )
      }
      match project_disassembly_rec_call_target(instruction) {
        Some(target) if block.contains(target) &&
          project_disassembly_rec_has_instruction_at(instructions, target) =>
          edges.push(
            ProjectDisassemblyEdge::create(
              source=instruction.addr(),
              target~,
              kind=JumpEdge,
            ),
          )
        _ => ()
      }
    } else if instruction.has_kind(ProjectConditionalBranch) {
      match project_disassembly_rec_direct_branch_target(instruction) {
        Some(target) if block.contains(target) &&
          project_disassembly_rec_has_instruction_at(instructions, target) =>
          edges.push(
            ProjectDisassemblyEdge::create(
              source=instruction.addr(),
              target~,
              kind=CondEdge,
            ),
          )
        _ => ()
      }
    } else if instruction.has_kind(ProjectUnconditionalBranch) {
      match project_disassembly_rec_direct_branch_target(instruction) {
        Some(target) if block.contains(target) &&
          project_disassembly_rec_has_instruction_at(instructions, target) =>
          edges.push(
            ProjectDisassemblyEdge::create(
              source=instruction.addr(),
              target~,
              kind=JumpEdge,
            ),
          )
        _ => ()
      }
    }
  }
  edges
}

///|
fn project_disassembly_rec_can_fall_through(
  instruction : ProjectDisassemblyInstruction,
) -> Bool {
  // LLVM marks conditional branches as terminators too: only barriers
  // (and returns, unconditional and indirect branches) do not fall through
  !instruction.has_kind(ProjectReturn) &&
  !instruction.has_kind(ProjectBarrier) &&
  !instruction.has_kind(ProjectUnconditionalBranch) &&
  !instruction.has_kind(ProjectIndirectBranch)
}

///|
fn project_disassembly_rec_add_fall_edges(
  state : ProjectDisassemblyState,
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
) -> Unit {
  if blocks.length() <= 1 {
    return
  }
  for i in 0..<(blocks.length() - 1) {
    let instructions = state.instructions_in(blocks[i])
    if !instructions.is_empty() {
      let terminator = instructions[instructions.length() - 1]
      if project_disassembly_rec_can_fall_through(terminator) {
        edges.push(
          ProjectDisassemblyEdge::create(
            source=terminator.addr(),
            target=blocks[i + 1].min_addr(),
            kind=FallEdge,
          ),
        )
      }
    }
  }
}

///|
fn project_disassembly_rec_refine_state(
  state : ProjectDisassemblyState,
) -> Result[ProjectDisassemblyState, String] {
  let blocks : Array[@memory.Memory] = []
  let edges = state.edges()
  for block in state.blocks() {
    let instructions = state.instructions_in(block)
    match project_disassembly_rec_split_block(block, instructions) {
      Ok(split) => {
        for item in split {
          blocks.push(item)
        }
        project_disassembly_rec_add_fall_edges(state, split, edges)
      }
      Err(reason) => return Err(reason)
    }
    for edge in project_disassembly_rec_control_edges(block, instructions) {
      edges.push(edge)
    }
  }
  Ok(
    ProjectDisassemblyState::create(
      blocks~,
      instructions=state.instructions(),
      edges~,
    ),
  )
}

///|
fn project_disassembly_rec_refine_project(
  project : Project,
) -> Result[Project, String] {
  match project_disassembly_rec_refine_state(project.disassembly()) {
    Ok(state) => Ok(project.with_disassembly(state))
    Err(reason) => Err(reason)
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
        Ok(branched) =>
          match project_disassembly_rec_refine_project(branched) {
            Ok(refined) => Ok(ProjectDisassemblyRec::create(refined))
            Err(reason) => Err(reason)
          }
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
