///|
struct ProjectDisassemblyInstruction {
  memory_value : @memory.Memory
  assembly_value : String
  bil_value : String
  kinds_value : Array[ProjectInstructionKind]
  operands_value : Array[ProjectInstructionOperand]
}

///|
pub(all) enum ProjectInstructionOperand {
  ProjectRegisterOperand(Int, String)
  ProjectImmediateOperand(Int64)
  ProjectFloatingOperand(Double)
} derive(Eq, Debug)

///|
pub(all) enum ProjectInstructionKind {
  ProjectConditionalBranch
  ProjectUnconditionalBranch
  ProjectIndirectBranch
  ProjectReturn
  ProjectCall
  ProjectBarrier
  ProjectTerminator
  ProjectMayAffectControlFlow
  ProjectMayLoad
  ProjectMayStore
} derive(Eq, Debug)

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
fn project_disassembly_same_instruction(
  left : ProjectDisassemblyInstruction,
  right : ProjectDisassemblyInstruction,
) -> Bool {
  project_disassembly_same_block(left.memory_value, right.memory_value)
}

///|
fn project_disassembly_replace_instruction(
  instructions : Array[ProjectDisassemblyInstruction],
  instruction : ProjectDisassemblyInstruction,
) -> Array[ProjectDisassemblyInstruction] {
  let result : Array[ProjectDisassemblyInstruction] = []
  let mut replaced = false
  for existing in instructions {
    if project_disassembly_same_instruction(existing, instruction) {
      if !replaced {
        result.push(instruction)
        replaced = true
      }
    } else {
      result.push(existing)
    }
  }
  if !replaced {
    result.push(instruction)
  }
  result
}

///|
fn project_disassembly_dedup_instructions(
  instructions : Array[ProjectDisassemblyInstruction],
) -> Array[ProjectDisassemblyInstruction] {
  let mut result : Array[ProjectDisassemblyInstruction] = []
  for instruction in instructions {
    result = project_disassembly_replace_instruction(result, instruction)
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
fn project_disassembly_edge_touches_block(
  edge : ProjectDisassemblyEdge,
  block : @memory.Memory,
) -> Bool {
  if block.contains(edge.source()) {
    true
  } else {
    match edge.target() {
      Some(target) => block.contains(target)
      None => false
    }
  }
}

///|
pub fn ProjectInstructionOperand::register(
  name~ : String,
  code? : Int = 0,
) -> ProjectInstructionOperand {
  ProjectRegisterOperand(code, name)
}

///|
pub fn ProjectInstructionOperand::immediate(
  value : Int64,
) -> ProjectInstructionOperand {
  ProjectImmediateOperand(value)
}

///|
pub fn ProjectInstructionOperand::floating(
  value : Double,
) -> ProjectInstructionOperand {
  ProjectFloatingOperand(value)
}

///|
pub fn ProjectInstructionOperand::to_string(
  self : ProjectInstructionOperand,
) -> String {
  match self {
    ProjectRegisterOperand(_, name) => name
    ProjectImmediateOperand(value) =>
      if value < 0L {
        "-0x" + (-value).to_string(radix=16)
      } else {
        "0x" + value.to_string(radix=16)
      }
    ProjectFloatingOperand(value) => value.to_string()
  }
}

///|
pub fn ProjectInstructionOperand::register_code(
  self : ProjectInstructionOperand,
) -> Int? {
  match self {
    ProjectRegisterOperand(code, _) => Some(code)
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::register_name(
  self : ProjectInstructionOperand,
) -> String? {
  match self {
    ProjectRegisterOperand(_, name) => Some(name)
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::to_int64(
  self : ProjectInstructionOperand,
) -> Int64? {
  match self {
    ProjectImmediateOperand(value) => Some(value)
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::to_int(
  self : ProjectInstructionOperand,
) -> Int? {
  match self {
    ProjectImmediateOperand(value) =>
      match @types.int_of_int64(value) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::to_word(
  self : ProjectInstructionOperand,
  width~ : Int,
) -> @types.Word? {
  match self {
    ProjectImmediateOperand(value) =>
      try @types.Word::of_int64(value, width~) catch {
        _ => None
      } noraise {
        word => Some(word)
      }
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::to_float(
  self : ProjectInstructionOperand,
) -> Double? {
  match self {
    ProjectFloatingOperand(value) => Some(value)
    _ => None
  }
}

///|
pub fn ProjectInstructionOperand::same_normalized(
  self : ProjectInstructionOperand,
  other : ProjectInstructionOperand,
) -> Bool {
  match (self, other) {
    (ProjectImmediateOperand(_), ProjectImmediateOperand(_)) => true
    (ProjectFloatingOperand(_), ProjectFloatingOperand(_)) => true
    (
      ProjectRegisterOperand(left_code, left_name),
      ProjectRegisterOperand(right_code, right_name),
    ) => left_code == right_code && left_name == right_name
    _ => false
  }
}

///|
pub fn project_instruction_operands_same_normalized_prefix(
  left : Array[ProjectInstructionOperand],
  right : Array[ProjectInstructionOperand],
) -> Bool {
  let len = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for i in 0..<len {
    if !left[i].same_normalized(right[i]) {
      return false
    }
  }
  true
}

///|
pub fn ProjectInstructionKind::members() -> Array[ProjectInstructionKind] {
  [
    ProjectConditionalBranch,
    ProjectUnconditionalBranch,
    ProjectIndirectBranch,
    ProjectReturn,
    ProjectCall,
    ProjectBarrier,
    ProjectTerminator,
    ProjectMayAffectControlFlow,
    ProjectMayLoad,
    ProjectMayStore,
  ]
}

///|
pub fn ProjectInstructionKind::to_string(
  self : ProjectInstructionKind,
) -> String {
  match self {
    ProjectConditionalBranch => "conditional-branch"
    ProjectUnconditionalBranch => "unconditional-branch"
    ProjectIndirectBranch => "indirect-branch"
    ProjectReturn => "return"
    ProjectCall => "call"
    ProjectBarrier => "barrier"
    ProjectTerminator => "terminator"
    ProjectMayAffectControlFlow => "may-affect-control-flow"
    ProjectMayLoad => "may-load"
    ProjectMayStore => "may-store"
  }
}

///|
pub fn ProjectInstructionKind::is_branch(self : ProjectInstructionKind) -> Bool {
  match self {
    ProjectConditionalBranch
    | ProjectUnconditionalBranch
    | ProjectIndirectBranch => true
    _ => false
  }
}

///|
pub fn ProjectInstructionKind::affects_control_flow(
  self : ProjectInstructionKind,
) -> Bool {
  match self {
    ProjectConditionalBranch
    | ProjectUnconditionalBranch
    | ProjectIndirectBranch
    | ProjectReturn
    | ProjectCall
    | ProjectBarrier
    | ProjectTerminator
    | ProjectMayAffectControlFlow => true
    _ => false
  }
}

///|
pub fn ProjectInstructionKind::has_side_effect(
  self : ProjectInstructionKind,
) -> Bool {
  match self {
    ProjectMayLoad | ProjectMayStore => true
    _ => false
  }
}

///|
fn project_instruction_kinds_normalize(
  kinds : Array[ProjectInstructionKind],
) -> Array[ProjectInstructionKind] {
  let out : Array[ProjectInstructionKind] = []
  for known in ProjectInstructionKind::members() {
    if kinds.contains(known) {
      out.push(known)
    }
  }
  out
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
  kinds? : Array[ProjectInstructionKind],
  operands? : Array[ProjectInstructionOperand],
) -> ProjectDisassemblyInstruction {
  {
    memory_value: memory,
    assembly_value: assembly,
    bil_value: bil,
    kinds_value: match kinds {
      Some(items) => project_instruction_kinds_normalize(items)
      None => []
    },
    operands_value: match operands {
      Some(items) => items.copy()
      None => []
    },
  }
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
pub fn ProjectDisassemblyInstruction::kinds(
  self : ProjectDisassemblyInstruction,
) -> Array[ProjectInstructionKind] {
  self.kinds_value.copy()
}

///|
pub fn ProjectDisassemblyInstruction::operands(
  self : ProjectDisassemblyInstruction,
) -> Array[ProjectInstructionOperand] {
  self.operands_value.copy()
}

///|
pub fn ProjectDisassemblyInstruction::operand_count(
  self : ProjectDisassemblyInstruction,
) -> Int {
  self.operands_value.length()
}

///|
pub fn ProjectDisassemblyInstruction::with_operands(
  self : ProjectDisassemblyInstruction,
  operands : Array[ProjectInstructionOperand],
) -> ProjectDisassemblyInstruction {
  { ..self, operands_value: operands.copy() }
}

///|
pub fn ProjectDisassemblyInstruction::same_normalized_operands(
  self : ProjectDisassemblyInstruction,
  other : ProjectDisassemblyInstruction,
) -> Bool {
  project_instruction_operands_same_normalized_prefix(
    self.operands_value,
    other.operands_value,
  )
}

///|
pub fn ProjectDisassemblyInstruction::has_kind(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> Bool {
  self.kinds_value.contains(kind)
}

///|
pub fn ProjectDisassemblyInstruction::with_kinds(
  self : ProjectDisassemblyInstruction,
  kinds : Array[ProjectInstructionKind],
) -> ProjectDisassemblyInstruction {
  { ..self, kinds_value: project_instruction_kinds_normalize(kinds) }
}

///|
pub fn ProjectDisassemblyInstruction::with_kind(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  let kinds = self.kinds_value.copy()
  kinds.push(kind)
  self.with_kinds(kinds)
}

///|
pub fn ProjectDisassemblyInstruction::without_kind(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.with_kinds(self.kinds_value.filter(existing => existing != kind))
}

///|
pub fn ProjectDisassemblyInstruction::is_branch(
  self : ProjectDisassemblyInstruction,
) -> Bool {
  self.kinds_value.any(kind => kind.is_branch())
}

///|
pub fn ProjectDisassemblyInstruction::affects_control_flow(
  self : ProjectDisassemblyInstruction,
) -> Bool {
  self.kinds_value.any(kind => kind.affects_control_flow())
}

///|
pub fn ProjectDisassemblyInstruction::has_side_effect(
  self : ProjectDisassemblyInstruction,
) -> Bool {
  self.kinds_value.any(kind => kind.has_side_effect())
}

///|
pub fn ProjectDisassemblyInstruction::addr(
  self : ProjectDisassemblyInstruction,
) -> UInt64 {
  self.memory_value.min_addr()
}

///|
pub fn ProjectDisassemblyInstruction::contains(
  self : ProjectDisassemblyInstruction,
  addr : UInt64,
) -> Bool {
  self.memory_value.contains(addr)
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
      Some(items) => project_disassembly_dedup_instructions(items)
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
pub fn ProjectDisassemblyState::has_instruction(
  self : ProjectDisassemblyState,
  instruction : ProjectDisassemblyInstruction,
) -> Bool {
  self.instructions_value.any(existing => {
    project_disassembly_same_instruction(existing, instruction)
  })
}

///|
pub fn ProjectDisassemblyState::instruction_at(
  self : ProjectDisassemblyState,
  addr : UInt64,
) -> ProjectDisassemblyInstruction? {
  for instruction in self.instructions_value {
    if instruction.contains(addr) {
      return Some(instruction)
    }
  }
  None
}

///|
pub fn ProjectDisassemblyState::instruction_for(
  self : ProjectDisassemblyState,
  memory : @memory.Memory,
) -> ProjectDisassemblyInstruction? {
  for instruction in self.instructions_value {
    if instruction.memory().dominates(memory) {
      return Some(instruction)
    }
  }
  None
}

///|
pub fn ProjectDisassemblyState::instructions_in(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Array[ProjectDisassemblyInstruction] {
  let result = self.instructions_value.filter(instruction => {
    block.dominates(instruction.memory())
  })
  result.sort_by((left, right) => left.addr().compare(right.addr()))
  result
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
pub fn ProjectDisassemblyState::edges_from_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.filter(edge => block.contains(edge.source()))
}

///|
pub fn ProjectDisassemblyState::edges_to_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.filter(edge => {
    match edge.target() {
      Some(target) => block.contains(target)
      None => false
    }
  })
}

///|
pub fn ProjectDisassemblyState::edges_touching_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.filter(edge => {
    project_disassembly_edge_touches_block(edge, block)
  })
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
pub fn ProjectDisassemblyState::remove_block(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
) -> ProjectDisassemblyState {
  {
    blocks_value: self.blocks_value.filter(existing => {
      !project_disassembly_same_block(existing, block)
    }),
    instructions_value: self.instructions_value.filter(instruction => {
      !block.dominates(instruction.memory())
    }),
    edges_value: self.edges_value.filter(edge => {
      !project_disassembly_edge_touches_block(edge, block)
    }),
  }
}

///|
pub fn ProjectDisassemblyState::with_instructions(
  self : ProjectDisassemblyState,
  instructions : Array[ProjectDisassemblyInstruction],
) -> ProjectDisassemblyState {
  {
    ..self,
    instructions_value: project_disassembly_dedup_instructions(instructions),
  }
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
  {
    ..self,
    instructions_value: project_disassembly_replace_instruction(
      self.instructions_value,
      instruction,
    ),
  }
}

///|
pub fn ProjectDisassemblyState::remove_instruction(
  self : ProjectDisassemblyState,
  instruction : ProjectDisassemblyInstruction,
) -> ProjectDisassemblyState {
  {
    ..self,
    instructions_value: self.instructions_value.filter(existing => {
      !project_disassembly_same_instruction(existing, instruction)
    }),
  }
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
pub fn ProjectDisassemblyState::remove_edge(
  self : ProjectDisassemblyState,
  edge : ProjectDisassemblyEdge,
) -> ProjectDisassemblyState {
  {
    ..self,
    edges_value: self.edges_value.filter(existing => {
      !project_disassembly_same_edge(existing, edge)
    }),
  }
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
