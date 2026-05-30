///|
struct ProjectDisassemblyInstruction {
  memory_value : @memory.Memory
  assembly_value : String
  bil_value : String
}

///|
struct ProjectDisassemblyState {
  blocks_value : Array[@memory.Memory]
  instructions_value : Array[ProjectDisassemblyInstruction]
}

///|
struct ProjectState {
  disassembly_value : ProjectDisassemblyState
  subroutines_value : Array[@types.Term[@types.Sub]]
}

///|
fn project_disassembly_same_block(
  left : @memory.Memory,
  right : @memory.Memory,
) -> Bool {
  left.min_addr() == right.min_addr() && left.max_addr() == right.max_addr()
}

///|
fn project_disassembly_dedup_blocks(
  blocks : Array[@memory.Memory],
) -> Array[@memory.Memory] {
  let result : Array[@memory.Memory] = []
  for block in blocks {
    if !result.any(existing => project_disassembly_same_block(existing, block)) {
      result.push(block)
    }
  }
  result
}

///|
pub fn ProjectDisassemblyInstruction::create(
  memory : @memory.Memory,
  assembly? : String = "",
  bil? : String = "",
) -> ProjectDisassemblyInstruction {
  { memory_value: memory, assembly_value: assembly, bil_value: bil }
}

///|
pub fn ProjectDisassemblyInstruction::memory(
  self : ProjectDisassemblyInstruction,
) -> @memory.Memory {
  self.memory_value
}

///|
pub fn ProjectDisassemblyInstruction::assembly(
  self : ProjectDisassemblyInstruction,
) -> String {
  self.assembly_value
}

///|
pub fn ProjectDisassemblyInstruction::bil(
  self : ProjectDisassemblyInstruction,
) -> String {
  self.bil_value
}

///|
pub fn ProjectDisassemblyState::empty() -> ProjectDisassemblyState {
  { blocks_value: [], instructions_value: [] }
}

///|
pub fn ProjectDisassemblyState::create(
  blocks? : Array[@memory.Memory],
  instructions? : Array[ProjectDisassemblyInstruction],
) -> ProjectDisassemblyState {
  {
    blocks_value: match blocks {
      Some(items) => project_disassembly_dedup_blocks(items)
      None => []
    },
    instructions_value: match instructions {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn ProjectDisassemblyState::blocks(
  self : ProjectDisassemblyState,
) -> Array[@memory.Memory] {
  self.blocks_value.copy()
}

///|
pub fn ProjectDisassemblyState::block_count(
  self : ProjectDisassemblyState,
) -> Int {
  self.blocks_value.length()
}

///|
pub fn ProjectDisassemblyState::has_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Bool {
  self.blocks_value.any(existing => {
    project_disassembly_same_block(existing, block)
  })
}

///|
pub fn ProjectDisassemblyState::instructions(
  self : ProjectDisassemblyState,
) -> Array[ProjectDisassemblyInstruction] {
  self.instructions_value.copy()
}

///|
pub fn ProjectDisassemblyState::instruction_count(
  self : ProjectDisassemblyState,
) -> Int {
  self.instructions_value.length()
}

///|
pub fn ProjectDisassemblyState::with_blocks(
  self : ProjectDisassemblyState,
  blocks : Array[@memory.Memory],
) -> ProjectDisassemblyState {
  { ..self, blocks_value: project_disassembly_dedup_blocks(blocks) }
}

///|
pub fn ProjectDisassemblyState::add_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> ProjectDisassemblyState {
  if self.has_block(block) {
    return self
  }
  let blocks = self.blocks_value.copy()
  blocks.push(block)
  { ..self, blocks_value: blocks }
}

///|
pub fn ProjectDisassemblyState::with_instructions(
  self : ProjectDisassemblyState,
  instructions : Array[ProjectDisassemblyInstruction],
) -> ProjectDisassemblyState {
  { ..self, instructions_value: instructions.copy() }
}

///|
pub fn ProjectDisassemblyState::add_instruction(
  self : ProjectDisassemblyState,
  instruction : ProjectDisassemblyInstruction,
) -> ProjectDisassemblyState {
  let instructions = self.instructions_value.copy()
  instructions.push(instruction)
  { ..self, instructions_value: instructions }
}

///|
pub fn ProjectState::empty() -> ProjectState {
  { disassembly_value: ProjectDisassemblyState::empty(), subroutines_value: [] }
}

///|
pub fn ProjectState::create(
  disassembly? : ProjectDisassemblyState,
  subroutines? : Array[@types.Term[@types.Sub]],
) -> ProjectState {
  {
    disassembly_value: match disassembly {
      Some(state) => state
      None => ProjectDisassemblyState::empty()
    },
    subroutines_value: match subroutines {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn ProjectState::disassembly(
  self : ProjectState,
) -> ProjectDisassemblyState {
  self.disassembly_value
}

///|
pub fn ProjectState::with_disassembly(
  self : ProjectState,
  disassembly : ProjectDisassemblyState,
) -> ProjectState {
  { ..self, disassembly_value: disassembly }
}

///|
pub fn ProjectState::subroutines(
  self : ProjectState,
) -> Array[@types.Term[@types.Sub]] {
  self.subroutines_value.copy()
}

///|
pub fn ProjectState::with_subroutines(
  self : ProjectState,
  subroutines : Array[@types.Term[@types.Sub]],
) -> ProjectState {
  { ..self, subroutines_value: subroutines.copy() }
}

///|
pub fn ProjectState::add_subroutine(
  self : ProjectState,
  subroutine : @types.Term[@types.Sub],
) -> ProjectState {
  let subroutines = self.subroutines_value.copy()
  subroutines.push(subroutine)
  { ..self, subroutines_value: subroutines }
}
