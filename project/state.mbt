///|
struct ProjectDisassemblyInstruction {
  memory_value : @memory.Memory
  assembly_value : String
  bil_value : String
}

///|
pub(all) enum ProjectDisassemblyEdgeKind {
  JumpEdge
  CondEdge
  FallEdge
} derive(Eq)

///|
struct ProjectDisassemblyEdge {
  source_value : UInt64
  target_value : UInt64?
  kind_value : ProjectDisassemblyEdgeKind
}

///|
struct ProjectDisassemblyState {
  blocks_value : Array[@memory.Memory]
  instructions_value : Array[ProjectDisassemblyInstruction]
  edges_value : Array[ProjectDisassemblyEdge]
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
fn project_disassembly_same_edge(
  left : ProjectDisassemblyEdge,
  right : ProjectDisassemblyEdge,
) -> Bool {
  left.source_value == right.source_value &&
  left.target_value == right.target_value &&
  left.kind_value == right.kind_value
}

///|
fn project_disassembly_dedup_edges(
  edges : Array[ProjectDisassemblyEdge],
) -> Array[ProjectDisassemblyEdge] {
  let result : Array[ProjectDisassemblyEdge] = []
  for edge in edges {
    if !result.any(existing => project_disassembly_same_edge(existing, edge)) {
      result.push(edge)
    }
  }
  result
}

///|
pub fn ProjectDisassemblyEdgeKind::to_string(
  self : ProjectDisassemblyEdgeKind,
) -> String {
  match self {
    JumpEdge => "jump"
    CondEdge => "cond"
    FallEdge => "fall"
  }
}

///|
pub fn ProjectDisassemblyEdge::create(
  source~ : UInt64,
  target? : UInt64,
  kind? : ProjectDisassemblyEdgeKind = JumpEdge,
) -> ProjectDisassemblyEdge {
  { source_value: source, target_value: target, kind_value: kind }
}

///|
pub fn ProjectDisassemblyEdge::source(self : ProjectDisassemblyEdge) -> UInt64 {
  self.source_value
}

///|
pub fn ProjectDisassemblyEdge::target(self : ProjectDisassemblyEdge) -> UInt64? {
  self.target_value
}

///|
pub fn ProjectDisassemblyEdge::kind(
  self : ProjectDisassemblyEdge,
) -> ProjectDisassemblyEdgeKind {
  self.kind_value
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
  { blocks_value: [], instructions_value: [], edges_value: [] }
}

///|
pub fn ProjectDisassemblyState::create(
  blocks? : Array[@memory.Memory],
  instructions? : Array[ProjectDisassemblyInstruction],
  edges? : Array[ProjectDisassemblyEdge],
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
    edges_value: match edges {
      Some(items) => project_disassembly_dedup_edges(items)
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
pub fn ProjectDisassemblyState::edges(
  self : ProjectDisassemblyState,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.copy()
}

///|
pub fn ProjectDisassemblyState::edge_count(
  self : ProjectDisassemblyState,
) -> Int {
  self.edges_value.length()
}

///|
pub fn ProjectDisassemblyState::has_edge(
  self : ProjectDisassemblyState,
  edge : ProjectDisassemblyEdge,
) -> Bool {
  self.edges_value.any(existing => project_disassembly_same_edge(existing, edge))
}

///|
pub fn ProjectDisassemblyState::edges_from(
  self : ProjectDisassemblyState,
  source : UInt64,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.filter(edge => edge.source() == source)
}

///|
pub fn ProjectDisassemblyState::edges_to(
  self : ProjectDisassemblyState,
  target : UInt64,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.filter(edge => edge.target() == Some(target))
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
pub fn ProjectDisassemblyState::with_edges(
  self : ProjectDisassemblyState,
  edges : Array[ProjectDisassemblyEdge],
) -> ProjectDisassemblyState {
  { ..self, edges_value: project_disassembly_dedup_edges(edges) }
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
pub fn ProjectDisassemblyState::add_edge(
  self : ProjectDisassemblyState,
  edge : ProjectDisassemblyEdge,
) -> ProjectDisassemblyState {
  if self.has_edge(edge) {
    return self
  }
  let edges = self.edges_value.copy()
  edges.push(edge)
  { ..self, edges_value: edges }
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
