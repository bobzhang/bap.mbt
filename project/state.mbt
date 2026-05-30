///|
struct ProjectDisassemblyState {
  blocks_value : Array[@memory.Memory]
}

///|
struct ProjectState {
  disassembly_value : ProjectDisassemblyState
  subroutines_value : Array[@types.Term[@types.Sub]]
}

///|
pub fn ProjectDisassemblyState::empty() -> ProjectDisassemblyState {
  { blocks_value: [] }
}

///|
pub fn ProjectDisassemblyState::create(
  blocks? : Array[@memory.Memory],
) -> ProjectDisassemblyState {
  {
    blocks_value: match blocks {
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
pub fn ProjectDisassemblyState::with_blocks(
  _self : ProjectDisassemblyState,
  blocks : Array[@memory.Memory],
) -> ProjectDisassemblyState {
  { blocks_value: blocks.copy() }
}

///|
pub fn ProjectDisassemblyState::add_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> ProjectDisassemblyState {
  let blocks = self.blocks_value.copy()
  blocks.push(block)
  { blocks_value: blocks }
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
