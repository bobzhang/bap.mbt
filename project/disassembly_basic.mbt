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
fn ProjectDisassemblyBasic::project_disassembly_basic_is_x86_64_llvm(
  self : ProjectDisassemblyBasic,
) -> Bool {
  self.backend_value == "llvm" &&
  (
    self.triple_value.contains("x86_64") ||
    self.triple_value.contains("x86-64") ||
    self.triple_value.contains("amd64")
  )
}

///|
fn ProjectDisassemblyBasic::project_disassembly_basic_is_arm_llvm(
  self : ProjectDisassemblyBasic,
) -> Bool {
  self.backend_value == "llvm" && self.triple_value.contains("arm")
}

///|
fn ProjectDisassemblyBasic::project_disassembly_basic_is_x86_llvm(
  self : ProjectDisassemblyBasic,
) -> Bool {
  self.backend_value == "llvm" &&
  (
    self.triple_value.contains("x86") ||
    self.triple_value.contains("i386") ||
    self.triple_value.contains("i486") ||
    self.triple_value.contains("i586") ||
    self.triple_value.contains("i686")
  )
}

///|
fn project_disassembly_basic_has_prefix(
  memory : @memory.Memory,
  prefix : Bytes,
) -> Bool {
  let bytes = memory.to_bytes()
  if bytes.length() < prefix.length() {
    false
  } else {
    for i in 0..<prefix.length() {
      if bytes[i] != prefix[i] {
        return false
      }
    }
    true
  }
}

///|
fn project_disassembly_basic_add_signed_offset(
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
fn project_disassembly_basic_x86_64_call_rel32(
  memory : @memory.Memory,
) -> Int64? {
  let bytes = memory.to_bytes()
  if bytes.length() < 5 || bytes[0].to_int() != 0xe8 {
    None
  } else {
    let displacement = bytes[1].to_int() |
      (bytes[2].to_int() << 8) |
      (bytes[3].to_int() << 16) |
      (bytes[4].to_int() << 24)
    Some(displacement.to_int64())
  }
}

///|
fn project_disassembly_basic_x86_jmp_rel8(
  memory : @memory.Memory,
) -> (Int64, UInt64)? {
  let bytes = memory.to_bytes()
  if bytes.length() < 2 || bytes[0].to_int() != 0xeb {
    None
  } else {
    let raw = bytes[1].to_int()
    let displacement = if raw >= 0x80 { raw - 0x100 } else { raw }
    match
      project_disassembly_basic_add_signed_offset(
        memory.min_addr() + 2UL,
        displacement.to_int64(),
      ) {
      Some(target) => Some((displacement.to_int64(), target))
      None => None
    }
  }
}

///|
fn project_disassembly_basic_arm_branch_target(
  memory : @memory.Memory,
) -> (UInt64, Bool)? {
  let bytes = memory.to_bytes()
  if bytes.length() < 4 || (bytes[3].to_int() & 0x0e) != 0x0a {
    None
  } else {
    let cond = bytes[3].to_int() >> 4
    let raw = bytes[0].to_int() |
      (bytes[1].to_int() << 8) |
      (bytes[2].to_int() << 16)
    let signed = if (raw & 0x800000) != 0 { raw - 0x1000000 } else { raw }
    match
      project_disassembly_basic_add_signed_offset(
        memory.min_addr() + 8UL,
        (signed << 2).to_int64(),
      ) {
      Some(target) => Some((target, cond != 0xe))
      None => None
    }
  }
}

///|
fn project_disassembly_basic_assembly(
  name : String,
  operands : Array[ProjectInstructionOperand],
) -> String {
  if operands.is_empty() {
    name
  } else {
    name + " " + operands.map(operand => operand.to_string()).join(", ")
  }
}

///|
fn project_disassembly_basic_instruction(
  memory : @memory.Memory,
  name : String,
  assembly? : String,
  bil? : String,
  operands? : Array[ProjectInstructionOperand] = [],
  kinds? : Array[ProjectInstructionKind] = [],
) -> ProjectDisassemblyInstruction {
  let bytes = memory.to_bytes()
  ProjectDisassemblyInstruction::create(
    memory,
    assembly=match assembly {
      Some(text) => text
      None => project_disassembly_basic_assembly(name, operands)
    },
    bil=match bil {
      Some(text) => text
      None => project_raw_byte_bil(memory)
    },
    code=bytes[0].to_int(),
    name~,
    encoding="llvm",
    kinds~,
    operands~,
  )
}

///|
fn project_disassembly_basic_decode_arm_llvm(
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction?, String] {
  if memory.length() < 4 {
    Ok(None)
  } else if project_disassembly_basic_has_prefix(memory, b"\x1e\xff\x2f\xe1") {
    match memory.view(words=4) {
      Ok(chunk) =>
        Ok(
          Some(
            project_disassembly_basic_instruction(
              chunk,
              "BX",
              assembly="bx lr",
              bil="jmp LR",
              operands=[ProjectInstructionOperand::register(name="LR")],
              kinds=[
                ProjectReturn,
                ProjectBarrier,
                ProjectTerminator,
                ProjectMayAffectControlFlow,
              ],
            ),
          ),
        )
      Err(reason) => Err(reason)
    }
  } else {
    match project_disassembly_basic_arm_branch_target(memory) {
      Some((target, conditional)) =>
        match memory.view(words=4) {
          Ok(chunk) =>
            Ok(
              Some(
                project_disassembly_basic_instruction(
                  chunk,
                  if conditional {
                    "BNE"
                  } else {
                    "B"
                  },
                  operands=[
                    ProjectInstructionOperand::immediate(
                      target.reinterpret_as_int64(),
                    ),
                  ],
                  kinds=if conditional {
                    [ProjectConditionalBranch, ProjectMayAffectControlFlow]
                  } else {
                    [ProjectUnconditionalBranch, ProjectMayAffectControlFlow]
                  },
                ),
              ),
            )
          Err(reason) => Err(reason)
        }
      None =>
        match memory.view(words=4) {
          Ok(chunk) =>
            Ok(Some(project_disassembly_basic_instruction(chunk, "ARM")))
          Err(reason) => Err(reason)
        }
    }
  }
}

///|
fn project_disassembly_basic_decode_x86_llvm(
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction?, String] {
  match project_disassembly_basic_x86_jmp_rel8(memory) {
    Some((displacement, target)) =>
      match memory.view(words=2) {
        Ok(chunk) =>
          Ok(
            Some(
              project_disassembly_basic_instruction(
                chunk,
                "JMP_1",
                assembly="jmp " +
                  ProjectInstructionOperand::immediate(displacement).to_string(),
                bil="jmp 0x" + target.to_string(radix=16),
                operands=[
                  ProjectInstructionOperand::immediate(
                    target.reinterpret_as_int64(),
                  ),
                ],
                kinds=[ProjectUnconditionalBranch, ProjectMayAffectControlFlow],
              ),
            ),
          )
        Err(reason) => Err(reason)
      }
    None => Ok(None)
  }
}

///|
fn project_disassembly_basic_decode_x86_64_llvm(
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction?, String] {
  let decoded : (
    Int,
    String,
    Array[ProjectInstructionOperand],
    Array[ProjectInstructionKind],
  )? = if project_disassembly_basic_has_prefix(memory, b"\x48\x83\xec\x08") {
    Some(
      (
        4,
        "SUB64ri8",
        [
          ProjectInstructionOperand::register(name="RSP"),
          ProjectInstructionOperand::register(name="RSP"),
          ProjectInstructionOperand::immediate(0x8L),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_64_call_rel32(memory) is Some(_) {
    let displacement = project_disassembly_basic_x86_64_call_rel32(memory).unwrap()
    Some(
      (
        5,
        "CALL64pcrel32",
        [ProjectInstructionOperand::immediate(displacement)],
        [ProjectCall, ProjectMayAffectControlFlow],
      ),
    )
  } else if project_disassembly_basic_has_prefix(memory, b"\x8b\x40\x10") {
    Some(
      (
        3,
        "MOV32rm",
        [
          ProjectInstructionOperand::register(name="EAX"),
          ProjectInstructionOperand::register(name="RAX"),
          ProjectInstructionOperand::immediate(0x1L),
          ProjectInstructionOperand::register(name="Nil"),
          ProjectInstructionOperand::immediate(0x10L),
          ProjectInstructionOperand::register(name="Nil"),
        ],
        [ProjectMayLoad],
      ),
    )
  } else if project_disassembly_basic_has_prefix(memory, b"\x48\x83\xc4\x08") {
    Some(
      (
        4,
        "ADD64ri8",
        [
          ProjectInstructionOperand::register(name="RSP"),
          ProjectInstructionOperand::register(name="RSP"),
          ProjectInstructionOperand::immediate(0x8L),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_has_prefix(memory, b"\xc3") {
    Some(
      (
        1,
        "RET",
        [],
        [
          ProjectReturn,
          ProjectBarrier,
          ProjectTerminator,
          ProjectMayAffectControlFlow,
        ],
      ),
    )
  } else {
    None
  }
  match decoded {
    Some((length, name, operands, kinds)) =>
      match memory.view(words=length) {
        Ok(chunk) =>
          Ok(
            Some(
              project_disassembly_basic_instruction(
                chunk,
                name,
                operands~,
                kinds~,
              ),
            ),
          )
        Err(reason) => Err(reason)
      }
    None => Ok(None)
  }
}

///|
fn ProjectDisassemblyBasic::project_disassembly_basic_decode_instruction(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction, String] {
  if self.project_disassembly_basic_is_x86_64_llvm() {
    match project_disassembly_basic_decode_x86_64_llvm(memory) {
      Ok(Some(instruction)) => Ok(instruction)
      Ok(None) =>
        match project_disassembly_basic_decode_x86_llvm(memory) {
          Ok(Some(instruction)) => Ok(instruction)
          Ok(None) =>
            match memory.view(words=1) {
              Ok(chunk) => Ok(project_raw_byte_instruction(chunk))
              Err(reason) => Err(reason)
            }
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  } else if self.project_disassembly_basic_is_x86_llvm() {
    match project_disassembly_basic_decode_x86_llvm(memory) {
      Ok(Some(instruction)) => Ok(instruction)
      Ok(None) =>
        match memory.view(words=1) {
          Ok(chunk) => Ok(project_raw_byte_instruction(chunk))
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  } else if self.project_disassembly_basic_is_arm_llvm() {
    match project_disassembly_basic_decode_arm_llvm(memory) {
      Ok(Some(instruction)) => Ok(instruction)
      Ok(None) =>
        match memory.view(words=1) {
          Ok(chunk) => Ok(project_raw_byte_instruction(chunk))
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  } else {
    match memory.view(words=1) {
      Ok(chunk) => Ok(project_raw_byte_instruction(chunk))
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn ProjectDisassemblyBasic::insn_of_mem(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyBasicInsnResult, String] {
  if memory.length() == 0 {
    Ok(ProjectDisassemblyBasicInsnResult::create(memory, BasicFinished))
  } else {
    match self.project_disassembly_basic_decode_instruction(memory) {
      Ok(instruction) => {
        let chunk = instruction.memory()
        let remainder = if chunk.max_addr() >= memory.max_addr() {
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
  let mut current = memory.min_addr()
  while memory.contains(current) {
    match memory.view(from=current) {
      Ok(rest) =>
        match self.project_disassembly_basic_decode_instruction(rest) {
          Ok(instruction) => {
            let chunk = instruction.memory()
            insns.push((chunk, Some(instruction)))
            addr = chunk.max_addr() + 1UL
            current = addr
            if project_disassembly_basic_matches_stop(instruction, preds) {
              break
            }
          }
          Err(_) => break
        }
      Err(_) => break
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
