///|
struct ProjectDisassemblyBlock {
  memory_value : @memory.Memory
  instructions_value : Array[ProjectDisassemblyInstruction]
}

///|
pub fn ProjectDisassemblyBlock::create(
  memory : @memory.Memory,
  instructions : Array[ProjectDisassemblyInstruction],
) -> Result[ProjectDisassemblyBlock, String] {
  if instructions.is_empty() {
    Err("project disassembly block requires at least one instruction")
  } else {
    Ok({ memory_value: memory, instructions_value: instructions.copy(), })
  }
}

///|
pub fn ProjectDisassemblyBlock::addr(self : ProjectDisassemblyBlock) -> UInt64 {
  self.memory_value.min_addr()
}

///|
pub fn ProjectDisassemblyBlock::memory(
  self : ProjectDisassemblyBlock,
) -> @memory.Memory {
  self.memory_value
}

///|
pub fn ProjectDisassemblyBlock::leader(
  self : ProjectDisassemblyBlock,
) -> ProjectDisassemblyInstruction {
  self.instructions_value[0]
}

///|
pub fn ProjectDisassemblyBlock::terminator(
  self : ProjectDisassemblyBlock,
) -> ProjectDisassemblyInstruction {
  self.instructions_value[self.instructions_value.length() - 1]
}

///|
pub fn ProjectDisassemblyBlock::instructions(
  self : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyInstruction] {
  self.instructions_value.copy()
}

///|
pub fn ProjectDisassemblyBlock::insns(
  self : ProjectDisassemblyBlock,
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction)] {
  self.instructions_value.map(instruction => (instruction.memory(), instruction))
}

///|
pub fn ProjectDisassemblyBlock::instruction_count(
  self : ProjectDisassemblyBlock,
) -> Int {
  self.instructions_value.length()
}

///|
pub fn ProjectDisassemblyBlock::compare(
  self : ProjectDisassemblyBlock,
  other : ProjectDisassemblyBlock,
) -> Int {
  let addr_order = self.addr().compare(other.addr())
  if addr_order != 0 {
    addr_order
  } else {
    self.memory_value.length().compare(other.memory_value.length())
  }
}

///|
pub fn ProjectDisassemblyBlock::same(
  self : ProjectDisassemblyBlock,
  other : ProjectDisassemblyBlock,
) -> Bool {
  self.compare(other) == 0
}

///|
pub fn ProjectDisassemblyBlock::to_string(
  self : ProjectDisassemblyBlock,
) -> String {
  "[0x" +
  self.memory_value.min_addr().to_string(radix=16) +
  ",0x" +
  self.memory_value.max_addr().to_string(radix=16) +
  "]"
}

///|
pub fn ProjectDisassemblyState::block_view(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Result[ProjectDisassemblyBlock, String] {
  ProjectDisassemblyBlock::create(block, self.instructions_in(block))
}

///|
pub fn ProjectDisassemblyState::blocks_with_instructions(
  self : ProjectDisassemblyState,
) -> Array[ProjectDisassemblyBlock] {
  let result : Array[ProjectDisassemblyBlock] = []
  for block in self.blocks() {
    match self.block_view(block) {
      Ok(view) => result.push(view)
      Err(_) => ()
    }
  }
  result
}
