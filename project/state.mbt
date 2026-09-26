///|
struct ProjectDisassemblyInstruction {
  memory_value : @memory.Memory
  code_value : Int
  name_value : String
  encoding_value : String
  assembly_value : String
  bil_value : String
  kinds_value : Array[ProjectInstructionKind]
  operands_value : Array[ProjectInstructionOperand]
  subinstructions_value : Array[ProjectDisassemblyInstruction]
  /// the relocations of the unit of the instruction, applied to its lifted
  /// semantics (see `ProjectRelocations::fixup`)
  relocations_value : ProjectRelocations?
}

///|
pub(all) enum ProjectInstructionOperand {
  ProjectRegisterOperand(Int, String)
  ProjectImmediateOperand(Int64)
  ProjectFloatingOperand(Double)
} derive(Eq, Debug)

///|
pub extend ProjectInstructionOperand with Eq::{not_equal, equal}

///|
pub extend ProjectInstructionOperand with Debug::{to_repr}

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
pub extend ProjectInstructionKind with Eq::{not_equal, equal}

///|
pub extend ProjectInstructionKind with Debug::{to_repr}

///|
struct ProjectInstructionToken {
  code_value : Int
  operands_value : Array[ProjectInstructionOperand]
}

///|
struct ProjectInstructionKey {
  tokens_value : Array[ProjectInstructionToken]
}

///|
pub(all) enum ProjectDisassemblyEdgeKind {
  JumpEdge
  CondEdge
  FallEdge
} derive(Eq)

///|
pub extend ProjectDisassemblyEdgeKind with Eq::{not_equal, equal}

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
fn project_memory_array_equal(
  lhs : Array[@memory.Memory],
  rhs : Array[@memory.Memory],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !project_memory_equal(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn project_disassembly_instruction_array_equal(
  lhs : Array[ProjectDisassemblyInstruction],
  rhs : Array[ProjectDisassemblyInstruction],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !project_disassembly_instruction_equal(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn project_disassembly_instruction_equal(
  lhs : ProjectDisassemblyInstruction,
  rhs : ProjectDisassemblyInstruction,
) -> Bool {
  project_memory_equal(lhs.memory_value, rhs.memory_value) &&
  lhs.code_value == rhs.code_value &&
  lhs.name_value == rhs.name_value &&
  lhs.encoding_value == rhs.encoding_value &&
  lhs.assembly_value == rhs.assembly_value &&
  lhs.bil_value == rhs.bil_value &&
  lhs.kinds_value == rhs.kinds_value &&
  lhs.operands_value == rhs.operands_value &&
  project_disassembly_instruction_array_equal(
    lhs.subinstructions_value,
    rhs.subinstructions_value,
  )
}

///|
fn project_disassembly_edge_array_equal(
  lhs : Array[ProjectDisassemblyEdge],
  rhs : Array[ProjectDisassemblyEdge],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !project_disassembly_same_edge(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn project_disassembly_state_equal(
  lhs : ProjectDisassemblyState,
  rhs : ProjectDisassemblyState,
) -> Bool {
  project_memory_array_equal(lhs.blocks_value, rhs.blocks_value) &&
  project_disassembly_instruction_array_equal(
    lhs.instructions_value,
    rhs.instructions_value,
  ) &&
  project_disassembly_edge_array_equal(lhs.edges_value, rhs.edges_value)
}

///|
fn project_subroutine_equal(
  lhs : @types.Term[@types.Sub],
  rhs : @types.Term[@types.Sub],
) -> Bool {
  lhs.tid() == rhs.tid() &&
  lhs.attrs() == rhs.attrs() &&
  @types.Sub::to_string(lhs) == @types.Sub::to_string(rhs)
}

///|
fn project_subroutine_array_equal(
  lhs : Array[@types.Term[@types.Sub]],
  rhs : Array[@types.Term[@types.Sub]],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !project_subroutine_equal(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn project_state_equal(lhs : ProjectState, rhs : ProjectState) -> Bool {
  project_disassembly_state_equal(lhs.disassembly_value, rhs.disassembly_value) &&
  project_subroutine_array_equal(lhs.subroutines_value, rhs.subroutines_value)
}

///|
fn project_state_order(
  lhs : ProjectState,
  rhs : ProjectState,
) -> @knowledge.PartialOrder {
  if project_state_equal(lhs, rhs) {
    Equal
  } else if project_state_equal(lhs, ProjectState::empty()) {
    Less
  } else if project_state_equal(rhs, ProjectState::empty()) {
    Greater
  } else {
    Incomparable
  }
}

///|
fn project_state_inspect(state : ProjectState) -> String {
  "(:number-of-basic-blocks \{state.disassembly_value.block_count()}) (:number-of-subroutines \{state.subroutines_value.length()})"
}

///|
/// `project_state_domain`, declared once.
let project_state_domain_value : @knowledge.Domain[ProjectState] = @knowledge.Domain::custom(
  project_name("disassembly"),
  project_state_inspect,
  empty=ProjectState::empty(),
  order=project_state_order,
)

///|
fn project_state_domain() -> @knowledge.Domain[ProjectState] {
  project_state_domain_value
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
pub fn ProjectInstructionToken::create(
  code~ : Int,
  operands? : Array[ProjectInstructionOperand],
) -> ProjectInstructionToken {
  {
    code_value: code,
    operands_value: match operands {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn ProjectInstructionToken::code(self : ProjectInstructionToken) -> Int {
  self.code_value
}

///|
pub fn ProjectInstructionToken::operands(
  self : ProjectInstructionToken,
) -> Array[ProjectInstructionOperand] {
  self.operands_value.copy()
}

///|
pub fn ProjectInstructionToken::operand_count(
  self : ProjectInstructionToken,
) -> Int {
  self.operands_value.length()
}

///|
pub fn ProjectInstructionToken::of_instruction(
  instruction : ProjectDisassemblyInstruction,
) -> ProjectInstructionToken {
  ProjectInstructionToken::create(
    code=instruction.code(),
    operands=instruction.operands(),
  )
}

///|
pub fn ProjectInstructionToken::same_normalized(
  self : ProjectInstructionToken,
  other : ProjectInstructionToken,
) -> Bool {
  self.code_value == other.code_value &&
  project_instruction_operands_same_normalized_prefix(
    self.operands_value,
    other.operands_value,
  )
}

///|
pub fn ProjectInstructionKey::create(
  tokens : Array[ProjectInstructionToken],
) -> ProjectInstructionKey {
  { tokens_value: tokens.copy(), }
}

///|
pub fn ProjectInstructionKey::of_instructions(
  instructions : Array[ProjectDisassemblyInstruction],
  len~ : Int,
) -> ProjectInstructionKey? {
  if len < 0 || instructions.length() < len {
    return None
  }
  let tokens : Array[ProjectInstructionToken] = []
  for i in 0..<len {
    tokens.push(ProjectInstructionToken::of_instruction(instructions[i]))
  }
  Some(ProjectInstructionKey::create(tokens))
}

///|
pub fn ProjectInstructionKey::length(self : ProjectInstructionKey) -> Int {
  self.tokens_value.length()
}

///|
pub fn ProjectInstructionKey::tokens(
  self : ProjectInstructionKey,
) -> Array[ProjectInstructionToken] {
  self.tokens_value.copy()
}

///|
pub fn ProjectInstructionKey::nth(
  self : ProjectInstructionKey,
  index : Int,
) -> ProjectInstructionToken? {
  self.tokens_value.get(index)
}

///|
pub fn ProjectInstructionKey::same_normalized(
  self : ProjectInstructionKey,
  other : ProjectInstructionKey,
) -> Bool {
  if self.tokens_value.length() != other.tokens_value.length() {
    return false
  }
  for i in 0..<self.tokens_value.length() {
    if !self.tokens_value[i].same_normalized(other.tokens_value[i]) {
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
  { source_value: source, target_value: target, kind_value: kind, }
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
  code? : Int = 0,
  name? : String = "",
  encoding? : String = "",
  kinds? : Array[ProjectInstructionKind],
  operands? : Array[ProjectInstructionOperand],
  subinstructions? : Array[ProjectDisassemblyInstruction],
) -> ProjectDisassemblyInstruction {
  {
    memory_value: memory,
    code_value: code,
    name_value: name,
    encoding_value: encoding,
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
    subinstructions_value: match subinstructions {
      Some(items) => items.copy()
      None => []
    },
    relocations_value: None,
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
pub fn ProjectDisassemblyInstruction::code(
  self : ProjectDisassemblyInstruction,
) -> Int {
  self.code_value
}

///|
pub fn ProjectDisassemblyInstruction::name(
  self : ProjectDisassemblyInstruction,
) -> String {
  self.name_value
}

///|
pub fn ProjectDisassemblyInstruction::encoding(
  self : ProjectDisassemblyInstruction,
) -> String {
  self.encoding_value
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
pub fn ProjectDisassemblyInstruction::subinstructions(
  self : ProjectDisassemblyInstruction,
) -> Array[ProjectDisassemblyInstruction] {
  self.subinstructions_value.copy()
}

///|
pub fn ProjectDisassemblyInstruction::subs(
  self : ProjectDisassemblyInstruction,
) -> Array[ProjectDisassemblyInstruction] {
  self.subinstructions()
}

///|
pub fn ProjectDisassemblyInstruction::subinstruction_count(
  self : ProjectDisassemblyInstruction,
) -> Int {
  self.subinstructions_value.length()
}

///|
pub fn ProjectDisassemblyInstruction::with_metadata(
  self : ProjectDisassemblyInstruction,
  code? : Int,
  name? : String,
  encoding? : String,
) -> ProjectDisassemblyInstruction {
  {
    ..self,
    code_value: match code {
      Some(value) => value
      None => self.code_value
    },
    name_value: match name {
      Some(value) => value
      None => self.name_value
    },
    encoding_value: match encoding {
      Some(value) => value
      None => self.encoding_value
    },
  }
}

///|
pub fn ProjectDisassemblyInstruction::with_operands(
  self : ProjectDisassemblyInstruction,
  operands : Array[ProjectInstructionOperand],
) -> ProjectDisassemblyInstruction {
  { ..self, operands_value: operands.copy(), }
}

///|
pub fn ProjectDisassemblyInstruction::with_subinstructions(
  self : ProjectDisassemblyInstruction,
  subinstructions : Array[ProjectDisassemblyInstruction],
) -> ProjectDisassemblyInstruction {
  { ..self, subinstructions_value: subinstructions.copy(), }
}

///|
/// The instruction with the relocations of its unit: the jumps of its
/// lifted semantics are fixed up with them (see `ProjectRelocations::fixup`
/// and `ProjectDisassemblyInstruction::lift`). Empty relocations are the
/// same as no relocations.
pub fn ProjectDisassemblyInstruction::with_relocations(
  self : ProjectDisassemblyInstruction,
  relocations : ProjectRelocations,
) -> ProjectDisassemblyInstruction {
  {
    ..self,
    relocations_value: if relocations.is_empty() {
      None
    } else {
      Some(relocations)
    },
  }
}

///|
/// The relocations of the unit of the instruction, if any.
pub fn ProjectDisassemblyInstruction::relocations(
  self : ProjectDisassemblyInstruction,
) -> ProjectRelocations? {
  self.relocations_value
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
pub fn ProjectDisassemblyInstruction::is_kind(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> Bool {
  self.has_kind(kind)
}

///|
pub fn ProjectDisassemblyInstruction::may(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> Bool {
  self.has_kind(kind)
}

///|
pub fn ProjectDisassemblyInstruction::with_kinds(
  self : ProjectDisassemblyInstruction,
  kinds : Array[ProjectInstructionKind],
) -> ProjectDisassemblyInstruction {
  { ..self, kinds_value: project_instruction_kinds_normalize(kinds), }
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
pub fn ProjectDisassemblyInstruction::must(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.with_kind(kind)
}

///|
pub fn ProjectDisassemblyInstruction::without_kind(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.with_kinds(self.kinds_value.filter(existing => existing != kind))
}

///|
pub fn ProjectDisassemblyInstruction::must_not(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.without_kind(kind)
}

///|
pub fn ProjectDisassemblyInstruction::should(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.with_kind(kind)
}

///|
pub fn ProjectDisassemblyInstruction::should_not(
  self : ProjectDisassemblyInstruction,
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyInstruction {
  self.without_kind(kind)
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
  { blocks_value: [], instructions_value: [], edges_value: [], }
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
pub fn ProjectDisassemblyState::key_of_first_insns(
  self : ProjectDisassemblyState,
  block : @memory.Memory,
  len~ : Int,
) -> ProjectInstructionKey? {
  ProjectInstructionKey::of_instructions(self.instructions_in(block), len~)
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
  { ..self, blocks_value: project_disassembly_dedup_blocks(blocks), }
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
  { ..self, blocks_value: blocks, }
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
  { ..self, edges_value: project_disassembly_dedup_edges(edges), }
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
  { ..self, edges_value: edges, }
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
  {
    disassembly_value: ProjectDisassemblyState::empty(),
    subroutines_value: [],
  }
}

///|
/// `ProjectState::slot`, declared once.
let project_state_slot_value : @knowledge.Slot[Unit, ProjectState] = @core_theory.ProgramUnit::cls().property(
  name=project_name("disassembly"),
  domain=project_state_domain(),
  persistent=ProjectState::persistent(),
)

///|
pub fn ProjectState::slot() -> @knowledge.Slot[Unit, ProjectState] {
  project_state_slot_value
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
  { ..self, disassembly_value: disassembly, }
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
  { ..self, subroutines_value: subroutines.copy(), }
}

///|
pub fn ProjectState::add_subroutine(
  self : ProjectState,
  subroutine : @types.Term[@types.Sub],
) -> ProjectState {
  let subroutines = self.subroutines_value.copy()
  subroutines.push(subroutine)
  { ..self, subroutines_value: subroutines, }
}
