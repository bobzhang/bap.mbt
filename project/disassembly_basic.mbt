///|
pub(all) enum ProjectDisassemblyBasicPred {
  BasicValid
  BasicKind(ProjectInstructionKind)
} derive(Eq, Debug)

///|
pub(all) enum ProjectDisassemblyBasicRemainder {
  BasicLeft(@memory.Memory)
  BasicFinished
}

///|
struct ProjectDisassemblyBasic {
  backend_value : String
  triple_value : String
  cpu_value : String
  attrs_value : String
  debug_level_value : Int
  store_asm_value : Bool
  store_kinds_value : Bool
}

///|
struct ProjectDisassemblyBasicState {
  disasm_value : ProjectDisassemblyBasic
  memory_value : @memory.Memory
  addr_value : UInt64
  preds_value : Array[ProjectDisassemblyBasicPred]
  insns_value : Array[(@memory.Memory, ProjectDisassemblyInstruction?)]
}

///|
struct ProjectDisassemblyBasicInsnResult {
  memory_value : @memory.Memory
  instruction_value : ProjectDisassemblyInstruction?
  remainder_value : ProjectDisassemblyBasicRemainder
}

///|
let project_disassembly_basic_backends : Map[String, String] = {
  "llvm": "LLVM-compatible raw-byte disassembler",
  "raw": "raw byte disassembler",
}

///|
fn project_disassembly_basic_known_backend(backend : String) -> Bool {
  project_disassembly_basic_backends.contains(backend)
}

///|
fn project_disassembly_basic_sort_backend_names() -> Array[String] {
  let names : Array[String] = []
  project_disassembly_basic_backends.each((name, _) => names.push(name))
  names.sort_by((left, right) => left.compare(right))
  names
}

///|
fn project_disassembly_basic_instruction_matches(
  instruction : ProjectDisassemblyInstruction,
  pred : ProjectDisassemblyBasicPred,
) -> Bool {
  match pred {
    BasicValid => true
    BasicKind(kind) => instruction.has_kind(kind)
  }
}

///|
fn project_disassembly_basic_matches_stop(
  instruction : ProjectDisassemblyInstruction,
  stop_on : Array[ProjectDisassemblyBasicPred],
) -> Bool {
  stop_on.any(pred => {
    project_disassembly_basic_instruction_matches(instruction, pred)
  })
}

///|
pub fn ProjectDisassemblyBasicPred::valid() -> ProjectDisassemblyBasicPred {
  BasicValid
}

///|
pub fn ProjectDisassemblyBasicPred::kind(
  kind : ProjectInstructionKind,
) -> ProjectDisassemblyBasicPred {
  BasicKind(kind)
}

///|
pub fn ProjectDisassemblyBasicPred::to_string(
  self : ProjectDisassemblyBasicPred,
) -> String {
  match self {
    BasicValid => "valid"
    BasicKind(kind) => kind.to_string()
  }
}

///|
pub fn ProjectDisassemblyBasicRemainder::left(
  memory : @memory.Memory,
) -> ProjectDisassemblyBasicRemainder {
  BasicLeft(memory)
}

///|
pub fn ProjectDisassemblyBasicRemainder::finished() -> ProjectDisassemblyBasicRemainder {
  BasicFinished
}

///|
pub fn ProjectDisassemblyBasicRemainder::is_finished(
  self : ProjectDisassemblyBasicRemainder,
) -> Bool {
  self is BasicFinished
}

///|
pub fn ProjectDisassemblyBasicRemainder::memory(
  self : ProjectDisassemblyBasicRemainder,
) -> @memory.Memory? {
  match self {
    BasicLeft(memory) => Some(memory)
    BasicFinished => None
  }
}

///|
pub fn register_disassembly_basic_backend(
  name~ : String,
  description? : String = "",
) -> Result[Unit, String] {
  if project_disassembly_basic_backends.contains(name) {
    Err("project disassembly basic backend \{name} is already registered")
  } else {
    project_disassembly_basic_backends[name] = description
    Ok(())
  }
}

///|
pub fn register_disassembly_basic_backend_if_absent(
  name~ : String,
  description? : String = "",
) -> Result[Bool, String] {
  if project_disassembly_basic_backends.contains(name) {
    Ok(false)
  } else {
    match register_disassembly_basic_backend(name~, description~) {
      Ok(_) => Ok(true)
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn disassembly_basic_backends() -> Array[String] {
  project_disassembly_basic_sort_backend_names()
}

///|
pub fn ProjectDisassemblyBasic::available_backends() -> Array[String] {
  disassembly_basic_backends()
}

///|
pub fn ProjectDisassemblyBasic::create(
  triple : String,
  backend? : String = "llvm",
  cpu? : String = "",
  attrs? : String = "",
  debug_level? : Int = 0,
) -> Result[ProjectDisassemblyBasic, String] {
  if project_disassembly_basic_known_backend(backend) {
    Ok({
      backend_value: backend,
      triple_value: triple,
      cpu_value: cpu,
      attrs_value: attrs,
      debug_level_value: debug_level,
      store_asm_value: false,
      store_kinds_value: false,
    })
  } else {
    Err("unknown project disassembly basic backend \{backend}")
  }
}

///|
pub fn ProjectDisassemblyBasic::lookup(
  target : @core_theory.Target,
  language : @core_theory.Language,
  backend? : String = "llvm",
) -> Result[ProjectDisassemblyBasic, String] {
  ProjectDisassemblyBasic::create(
    target.to_string() + "-" + language.to_string(),
    backend~,
  )
}

///|
pub fn ProjectDisassemblyBasic::custom(
  target : @core_theory.Target,
  language : @core_theory.Language,
  backend? : String = "raw",
) -> ProjectDisassemblyBasic {
  {
    backend_value: backend,
    triple_value: target.to_string() + "-" + language.to_string(),
    cpu_value: "",
    attrs_value: "",
    debug_level_value: 0,
    store_asm_value: false,
    store_kinds_value: false,
  }
}

///|
pub fn[A] ProjectDisassemblyBasic::with_disasm(
  triple : String,
  backend? : String = "llvm",
  f : (ProjectDisassemblyBasic) -> Result[A, String],
) -> Result[A, String] {
  match ProjectDisassemblyBasic::create(triple, backend~) {
    Ok(disasm) => f(disasm)
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectDisassemblyBasic::close(self : ProjectDisassemblyBasic) -> Unit {
  let _ = self.backend_value
}

///|
pub fn ProjectDisassemblyBasic::backend(
  self : ProjectDisassemblyBasic,
) -> String {
  self.backend_value
}

///|
pub fn ProjectDisassemblyBasic::triple(
  self : ProjectDisassemblyBasic,
) -> String {
  self.triple_value
}

///|
pub fn ProjectDisassemblyBasic::cpu(self : ProjectDisassemblyBasic) -> String {
  self.cpu_value
}

///|
pub fn ProjectDisassemblyBasic::attrs(self : ProjectDisassemblyBasic) -> String {
  self.attrs_value
}

///|
pub fn ProjectDisassemblyBasic::debug_level(
  self : ProjectDisassemblyBasic,
) -> Int {
  self.debug_level_value
}

///|
pub fn ProjectDisassemblyBasic::stores_asm(
  self : ProjectDisassemblyBasic,
) -> Bool {
  self.store_asm_value
}

///|
pub fn ProjectDisassemblyBasic::stores_kinds(
  self : ProjectDisassemblyBasic,
) -> Bool {
  self.store_kinds_value
}

///|
pub fn ProjectDisassemblyBasic::store_asm(
  self : ProjectDisassemblyBasic,
) -> ProjectDisassemblyBasic {
  { ..self, store_asm_value: true }
}

///|
pub fn ProjectDisassemblyBasic::store_kinds(
  self : ProjectDisassemblyBasic,
) -> ProjectDisassemblyBasic {
  { ..self, store_kinds_value: true }
}

///|
pub fn ProjectDisassemblyBasic::insn_of_mem(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyBasicInsnResult, String] {
  let _ = self.backend_value
  if memory.length() == 0 {
    Ok(ProjectDisassemblyBasicInsnResult::create(memory, BasicFinished))
  } else {
    match memory.view(words=1) {
      Ok(chunk) => {
        let instruction = project_raw_byte_instruction(chunk)
        let remainder = if memory.length() == 1 {
          BasicFinished
        } else {
          match memory.view(from=chunk.max_addr() + 1UL) {
            Ok(left) => BasicLeft(left)
            Err(reason) => return Err(reason)
          }
        }
        Ok(
          ProjectDisassemblyBasicInsnResult::create(
            chunk,
            instruction~,
            remainder,
          ),
        )
      }
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn ProjectDisassemblyBasic::run(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
  stop_on? : Array[ProjectDisassemblyBasicPred],
) -> ProjectDisassemblyBasicState {
  let preds = match stop_on {
    Some(items) => items.copy()
    None => []
  }
  let insns : Array[(@memory.Memory, ProjectDisassemblyInstruction?)] = []
  let mut addr = memory.min_addr()
  for offset in 0..<memory.length() {
    let current = memory.min_addr() + offset.to_uint64()
    match memory.view(from=current, words=1) {
      Ok(chunk) => {
        let instruction = project_raw_byte_instruction(chunk)
        insns.push((chunk, Some(instruction)))
        addr = chunk.max_addr() + 1UL
        if project_disassembly_basic_matches_stop(instruction, preds) {
          break
        }
      }
      Err(_) => ()
    }
  }
  ProjectDisassemblyBasicState::create(
    disasm=self,
    memory~,
    addr~,
    preds~,
    insns~,
  )
}

///|
pub fn ProjectDisassemblyBasicInsnResult::create(
  memory : @memory.Memory,
  instruction? : ProjectDisassemblyInstruction,
  remainder : ProjectDisassemblyBasicRemainder,
) -> ProjectDisassemblyBasicInsnResult {
  {
    memory_value: memory,
    instruction_value: instruction,
    remainder_value: remainder,
  }
}

///|
pub fn ProjectDisassemblyBasicInsnResult::memory(
  self : ProjectDisassemblyBasicInsnResult,
) -> @memory.Memory {
  self.memory_value
}

///|
pub fn ProjectDisassemblyBasicInsnResult::instruction(
  self : ProjectDisassemblyBasicInsnResult,
) -> ProjectDisassemblyInstruction? {
  self.instruction_value
}

///|
pub fn ProjectDisassemblyBasicInsnResult::remainder(
  self : ProjectDisassemblyBasicInsnResult,
) -> ProjectDisassemblyBasicRemainder {
  self.remainder_value
}

///|
pub fn ProjectDisassemblyBasicState::create(
  disasm~ : ProjectDisassemblyBasic,
  memory~ : @memory.Memory,
  addr~ : UInt64,
  preds~ : Array[ProjectDisassemblyBasicPred],
  insns~ : Array[(@memory.Memory, ProjectDisassemblyInstruction?)],
) -> ProjectDisassemblyBasicState {
  {
    disasm_value: disasm,
    memory_value: memory,
    addr_value: addr,
    preds_value: preds.copy(),
    insns_value: insns.copy(),
  }
}

///|
pub fn ProjectDisassemblyBasicState::disasm(
  self : ProjectDisassemblyBasicState,
) -> ProjectDisassemblyBasic {
  self.disasm_value
}

///|
pub fn ProjectDisassemblyBasicState::addr(
  self : ProjectDisassemblyBasicState,
) -> UInt64 {
  self.addr_value
}

///|
pub fn ProjectDisassemblyBasicState::preds(
  self : ProjectDisassemblyBasicState,
) -> Array[ProjectDisassemblyBasicPred] {
  self.preds_value.copy()
}

///|
pub fn ProjectDisassemblyBasicState::with_preds(
  self : ProjectDisassemblyBasicState,
  preds : Array[ProjectDisassemblyBasicPred],
) -> ProjectDisassemblyBasicState {
  { ..self, preds_value: preds.copy() }
}

///|
pub fn ProjectDisassemblyBasicState::insns(
  self : ProjectDisassemblyBasicState,
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] {
  self.insns_value.copy()
}

///|
pub fn ProjectDisassemblyBasicState::last(
  self : ProjectDisassemblyBasicState,
  count : Int,
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] {
  if count <= 0 {
    []
  } else if count >= self.insns_value.length() {
    self.insns()
  } else {
    self.insns_value[self.insns_value.length() - count:].to_owned()
  }
}

///|
pub fn ProjectDisassemblyBasicState::memory(
  self : ProjectDisassemblyBasicState,
) -> @memory.Memory {
  self.memory_value
}

///|
pub fn ProjectDisassemblyBasicState::switch(
  self : ProjectDisassemblyBasicState,
  disasm : ProjectDisassemblyBasic,
) -> ProjectDisassemblyBasicState {
  { ..self, disasm_value: disasm }
}
