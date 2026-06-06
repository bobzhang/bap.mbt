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
priv struct ProjectDisassemblyBasicX86MemoryOperand {
  base : String
  scale : Int64
  index : String
  displacement : Int64
  segment : String
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
fn project_disassembly_basic_x86_signed_byte(value : Byte) -> Int64 {
  let raw = value.to_int()
  if raw >= 0x80 {
    (raw - 0x100).to_int64()
  } else {
    raw.to_int64()
  }
}

///|
fn project_disassembly_basic_x86_i32_at(bytes : Bytes, offset : Int) -> Int64? {
  if bytes.length() < offset + 4 {
    None
  } else {
    let value = bytes[offset].to_int() |
      (bytes[offset + 1].to_int() << 8) |
      (bytes[offset + 2].to_int() << 16) |
      (bytes[offset + 3].to_int() << 24)
    Some(value.to_int64())
  }
}

///|
fn project_disassembly_basic_x86_call_rel32(memory : @memory.Memory) -> Int64? {
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
fn project_disassembly_basic_x86_jmp_rel32(
  memory : @memory.Memory,
) -> (Int64, UInt64)? {
  let bytes = memory.to_bytes()
  if bytes.length() < 5 || bytes[0].to_int() != 0xe9 {
    None
  } else {
    let displacement = bytes[1].to_int() |
      (bytes[2].to_int() << 8) |
      (bytes[3].to_int() << 16) |
      (bytes[4].to_int() << 24)
    match
      project_disassembly_basic_add_signed_offset(
        memory.min_addr() + 5UL,
        displacement.to_int64(),
      ) {
      Some(target) => Some((displacement.to_int64(), target))
      None => None
    }
  }
}

///|
fn project_disassembly_basic_x86_gpr32_name(code : Int) -> String {
  match code {
    0 => "EAX"
    1 => "ECX"
    2 => "EDX"
    3 => "EBX"
    4 => "ESP"
    5 => "EBP"
    6 => "ESI"
    7 => "EDI"
    8 => "R8D"
    9 => "R9D"
    10 => "R10D"
    11 => "R11D"
    12 => "R12D"
    13 => "R13D"
    14 => "R14D"
    15 => "R15D"
    _ => "R32_\{code}"
  }
}

///|
fn project_disassembly_basic_x86_gpr64_name(code : Int) -> String {
  match code {
    0 => "RAX"
    1 => "RCX"
    2 => "RDX"
    3 => "RBX"
    4 => "RSP"
    5 => "RBP"
    6 => "RSI"
    7 => "RDI"
    8 => "R8"
    9 => "R9"
    10 => "R10"
    11 => "R11"
    12 => "R12"
    13 => "R13"
    14 => "R14"
    15 => "R15"
    _ => "R64_\{code}"
  }
}

///|
fn project_disassembly_basic_x86_gpr_name(code : Int, width : Int) -> String {
  if width == 64 {
    project_disassembly_basic_x86_gpr64_name(code)
  } else {
    project_disassembly_basic_x86_gpr32_name(code)
  }
}

///|
fn project_disassembly_basic_x86_mem_operands(
  memory_operand : ProjectDisassemblyBasicX86MemoryOperand,
) -> Array[ProjectInstructionOperand] {
  [
    ProjectInstructionOperand::register(name=memory_operand.base),
    ProjectInstructionOperand::immediate(memory_operand.scale),
    ProjectInstructionOperand::register(name=memory_operand.index),
    ProjectInstructionOperand::immediate(memory_operand.displacement),
    ProjectInstructionOperand::register(name=memory_operand.segment),
  ]
}

///|
fn project_disassembly_basic_x86_parse_mem_operand(
  bytes : Bytes,
  offset : Int,
  modrm : Int,
  address_width : Int,
  rex : Int,
) -> (Int, ProjectDisassemblyBasicX86MemoryOperand)? {
  let mode = (modrm >> 6) & 0x3
  let rm_low = modrm & 0x7
  if mode == 0x3 {
    return None
  }
  let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
  let rex_x = if address_width == 64 && (rex & 0x2) != 0 { 8 } else { 0 }
  let mut next = offset
  let mut base = ""
  let mut scale = 1L
  let mut index = "Nil"
  if rm_low == 0x4 {
    if bytes.length() <= next {
      return None
    }
    let sib = bytes[next].to_int()
    next = next + 1
    scale = match (sib >> 6) & 0x3 {
      0 => 1L
      1 => 2L
      2 => 4L
      _ => 8L
    }
    let index_low = (sib >> 3) & 0x7
    let base_low = sib & 0x7
    if !(index_low == 0x4 && rex_x == 0) {
      index = project_disassembly_basic_x86_gpr_name(
        index_low + rex_x,
        address_width,
      )
    }
    if mode == 0x0 && base_low == 0x5 {
      return None
    }
    base = project_disassembly_basic_x86_gpr_name(
      base_low + rex_b,
      address_width,
    )
  } else {
    if mode == 0x0 && rm_low == 0x5 {
      return None
    }
    base = project_disassembly_basic_x86_gpr_name(rm_low + rex_b, address_width)
  }
  let displacement = match mode {
    0x0 => 0L
    0x1 =>
      if bytes.length() <= next {
        return None
      } else {
        let value = project_disassembly_basic_x86_signed_byte(bytes[next])
        next = next + 1
        value
      }
    0x2 =>
      match project_disassembly_basic_x86_i32_at(bytes, next) {
        Some(value) => {
          next = next + 4
          value
        }
        None => return None
      }
    _ => return None
  }
  Some((next, { base, scale, index, displacement, segment: "Nil" }))
}

///|
fn project_disassembly_basic_x86_mov32ri(
  memory : @memory.Memory,
) -> (String, Int64)? {
  let bytes = memory.to_bytes()
  if bytes.length() < 5 {
    None
  } else {
    let opcode = bytes[0].to_int()
    if opcode < 0xb8 || opcode > 0xbf {
      None
    } else {
      let imm = bytes[1].to_int() |
        (bytes[2].to_int() << 8) |
        (bytes[3].to_int() << 16) |
        (bytes[4].to_int() << 24)
      Some(
        (
          project_disassembly_basic_x86_gpr32_name(opcode - 0xb8),
          imm.to_int64(),
        ),
      )
    }
  }
}

///|
fn project_disassembly_basic_x86_64_mov64ri(
  memory : @memory.Memory,
) -> (String, Int64)? {
  let bytes = memory.to_bytes()
  if bytes.length() < 10 {
    None
  } else {
    let rex = bytes[0].to_int()
    let opcode = bytes[1].to_int()
    if (rex != 0x48 && rex != 0x49) || opcode < 0xb8 || opcode > 0xbf {
      None
    } else {
      let reg = opcode - 0xb8 + (if (rex & 1) == 1 { 8 } else { 0 })
      let imm = bytes[2].to_uint64() |
        (bytes[3].to_uint64() << 8) |
        (bytes[4].to_uint64() << 16) |
        (bytes[5].to_uint64() << 24) |
        (bytes[6].to_uint64() << 32) |
        (bytes[7].to_uint64() << 40) |
        (bytes[8].to_uint64() << 48) |
        (bytes[9].to_uint64() << 56)
      Some(
        (
          project_disassembly_basic_x86_gpr64_name(reg),
          imm.reinterpret_as_int64(),
        ),
      )
    }
  }
}

///|
fn project_disassembly_basic_x86_mov_mem(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    if opcode != 0x89 && opcode != 0x8b {
      None
    } else {
      let modrm = bytes[opcode_index + 1].to_int()
      let reg_ext = if address_width == 64 && (rex & 0x4) != 0 { 8 } else { 0 }
      let reg = project_disassembly_basic_x86_gpr_name(
        ((modrm >> 3) & 0x7) + reg_ext,
        data_width,
      )
      match
        project_disassembly_basic_x86_parse_mem_operand(
          bytes,
          opcode_index + 2,
          modrm,
          address_width,
          rex,
        ) {
        Some((length, memory_operand)) => {
          let mem_operands = project_disassembly_basic_x86_mem_operands(
            memory_operand,
          )
          if opcode == 0x8b {
            let operands = [ProjectInstructionOperand::register(name=reg)]
            operands.append(mem_operands)
            Some(
              (
                length,
                if data_width == 64 {
                  "MOV64rm"
                } else {
                  "MOV32rm"
                },
                operands,
                [ProjectMayLoad],
              ),
            )
          } else {
            let operands = mem_operands
            operands.push(ProjectInstructionOperand::register(name=reg))
            Some(
              (
                length,
                if data_width == 64 {
                  "MOV64mr"
                } else {
                  "MOV32mr"
                },
                operands,
                [ProjectMayStore],
              ),
            )
          }
        }
        None => None
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_mov_imm_rm(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 6 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    let group = (modrm >> 3) & 0x7
    if opcode != 0xc7 || group != 0 {
      None
    } else {
      let mode = (modrm >> 6) & 0x3
      let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
      if mode == 0x3 {
        match project_disassembly_basic_x86_i32_at(bytes, opcode_index + 2) {
          Some(imm) => {
            let register = project_disassembly_basic_x86_gpr_name(
              (modrm & 0x7) + rex_b,
              data_width,
            )
            Some(
              (
                opcode_index + 6,
                if data_width == 64 {
                  "MOV64ri32"
                } else {
                  "MOV32ri"
                },
                [
                  ProjectInstructionOperand::register(name=register),
                  ProjectInstructionOperand::immediate(imm),
                ],
                [],
              ),
            )
          }
          None => None
        }
      } else {
        match
          project_disassembly_basic_x86_parse_mem_operand(
            bytes,
            opcode_index + 2,
            modrm,
            address_width,
            rex,
          ) {
          Some((imm_offset, memory_operand)) =>
            match project_disassembly_basic_x86_i32_at(bytes, imm_offset) {
              Some(imm) => {
                let operands = project_disassembly_basic_x86_mem_operands(
                  memory_operand,
                )
                operands.push(ProjectInstructionOperand::immediate(imm))
                Some(
                  (
                    imm_offset + 4,
                    "MOV\{data_width}mi",
                    operands,
                    [ProjectMayStore],
                  ),
                )
              }
              None => None
            }
          None => None
        }
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_lea(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    if opcode != 0x8d {
      None
    } else {
      let modrm = bytes[opcode_index + 1].to_int()
      let reg_ext = if address_width == 64 && (rex & 0x4) != 0 { 8 } else { 0 }
      let dst = project_disassembly_basic_x86_gpr_name(
        ((modrm >> 3) & 0x7) + reg_ext,
        data_width,
      )
      match
        project_disassembly_basic_x86_parse_mem_operand(
          bytes,
          opcode_index + 2,
          modrm,
          address_width,
          rex,
        ) {
        Some((length, memory_operand)) => {
          let operands = [ProjectInstructionOperand::register(name=dst)]
          operands.append(
            project_disassembly_basic_x86_mem_operands(memory_operand),
          )
          Some((length, "LEA\{data_width}r", operands, []))
        }
        None => None
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_mov_rr(
  memory : @memory.Memory,
  width : Int,
) -> (Int, String, String, String)? {
  let bytes = memory.to_bytes()
  if width == 64 {
    if bytes.length() < 3 {
      None
    } else {
      let rex = bytes[0].to_int()
      let opcode = bytes[1].to_int()
      let modrm = bytes[2].to_int()
      if rex < 0x48 ||
        rex > 0x4f ||
        (opcode != 0x89 && opcode != 0x8b) ||
        ((modrm >> 6) & 0x3) != 0x3 {
        None
      } else {
        let reg = ((modrm >> 3) & 0x7) + (if (rex & 0x4) != 0 { 8 } else { 0 })
        let rm = (modrm & 0x7) + (if (rex & 0x1) != 0 { 8 } else { 0 })
        let dst = if opcode == 0x89 { rm } else { reg }
        let src = if opcode == 0x89 { reg } else { rm }
        Some(
          (
            3,
            if opcode == 0x89 {
              "MOV64rr"
            } else {
              "MOV64rr_REV"
            },
            project_disassembly_basic_x86_gpr64_name(dst),
            project_disassembly_basic_x86_gpr64_name(src),
          ),
        )
      }
    }
  } else if width == 32 {
    if bytes.length() < 2 {
      None
    } else {
      let opcode = bytes[0].to_int()
      let modrm = bytes[1].to_int()
      if (opcode != 0x89 && opcode != 0x8b) || ((modrm >> 6) & 0x3) != 0x3 {
        None
      } else {
        let reg = (modrm >> 3) & 0x7
        let rm = modrm & 0x7
        let dst = if opcode == 0x89 { rm } else { reg }
        let src = if opcode == 0x89 { reg } else { rm }
        Some(
          (
            2,
            if opcode == 0x89 {
              "MOV32rr"
            } else {
              "MOV32rr_REV"
            },
            project_disassembly_basic_x86_gpr32_name(dst),
            project_disassembly_basic_x86_gpr32_name(src),
          ),
        )
      }
    }
  } else {
    None
  }
}

///|
fn project_disassembly_basic_x86_xchg(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 2 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() <= opcode_index {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
    if opcode >= 0x90 && opcode <= 0x97 {
      let reg_code = (opcode & 0x7) + rex_b
      if reg_code == 0 && rex == 0 {
        None
      } else {
        Some(
          (
            opcode_index + 1,
            "XCHG\{data_width}rr",
            [
              ProjectInstructionOperand::register(
                name=project_disassembly_basic_x86_gpr_name(0, data_width),
              ),
              ProjectInstructionOperand::register(
                name=project_disassembly_basic_x86_gpr_name(
                  reg_code, data_width,
                ),
              ),
            ],
            [],
          ),
        )
      }
    } else if bytes.length() < opcode_index + 2 || opcode != 0x87 {
      None
    } else {
      let modrm = bytes[opcode_index + 1].to_int()
      let reg_ext = if address_width == 64 && (rex & 0x4) != 0 { 8 } else { 0 }
      let reg = project_disassembly_basic_x86_gpr_name(
        ((modrm >> 3) & 0x7) + reg_ext,
        data_width,
      )
      if ((modrm >> 6) & 0x3) == 0x3 {
        let rm = project_disassembly_basic_x86_gpr_name(
          (modrm & 0x7) + rex_b,
          data_width,
        )
        Some(
          (
            opcode_index + 2,
            "XCHG\{data_width}rr",
            [
              ProjectInstructionOperand::register(name=reg),
              ProjectInstructionOperand::register(name=rm),
            ],
            [],
          ),
        )
      } else {
        match
          project_disassembly_basic_x86_parse_mem_operand(
            bytes,
            opcode_index + 2,
            modrm,
            address_width,
            rex,
          ) {
          Some((length, memory_operand)) => {
            let operands = [ProjectInstructionOperand::register(name=reg)]
            operands.append(
              project_disassembly_basic_x86_mem_operands(memory_operand),
            )
            Some(
              (
                length,
                "XCHG\{data_width}rm",
                operands,
                [ProjectMayLoad, ProjectMayStore],
              ),
            )
          }
          None => None
        }
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_arith_rr(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (Int, String, String, String)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    let op = match opcode {
      0x01 | 0x03 => "ADD"
      0x29 | 0x2b => "SUB"
      _ => ""
    }
    if op == "" || ((modrm >> 6) & 0x3) != 0x3 {
      None
    } else {
      let reg_ext = if address_width == 64 && (rex & 0x4) != 0 { 8 } else { 0 }
      let rm_ext = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
      let reg = ((modrm >> 3) & 0x7) + reg_ext
      let rm = (modrm & 0x7) + rm_ext
      let dst_is_reg = (opcode & 0x2) != 0
      let dst = if dst_is_reg { reg } else { rm }
      let src = if dst_is_reg { rm } else { reg }
      let suffix = if dst_is_reg { "_REV" } else { "" }
      Some(
        (
          opcode_index + 2,
          op + "\{data_width}rr" + suffix,
          project_disassembly_basic_x86_gpr_name(dst, data_width),
          project_disassembly_basic_x86_gpr_name(src, data_width),
        ),
      )
    }
  }
}

///|
fn project_disassembly_basic_x86_logic_rr(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (Int, String, String, String)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    let op = match opcode {
      0x09 | 0x0b => "OR"
      0x21 | 0x23 => "AND"
      0x31 | 0x33 => "XOR"
      _ => ""
    }
    if op == "" || ((modrm >> 6) & 0x3) != 0x3 {
      None
    } else {
      let reg_ext = if address_width == 64 && (rex & 0x4) != 0 { 8 } else { 0 }
      let rm_ext = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
      let reg = ((modrm >> 3) & 0x7) + reg_ext
      let rm = (modrm & 0x7) + rm_ext
      let dst_is_reg = (opcode & 0x2) != 0
      let dst = if dst_is_reg { reg } else { rm }
      let src = if dst_is_reg { rm } else { reg }
      let suffix = if dst_is_reg { "_REV" } else { "" }
      Some(
        (
          opcode_index + 2,
          op + "\{data_width}rr" + suffix,
          project_disassembly_basic_x86_gpr_name(dst, data_width),
          project_disassembly_basic_x86_gpr_name(src, data_width),
        ),
      )
    }
  }
}

///|
fn project_disassembly_basic_x86_reg_update(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  match
    project_disassembly_basic_x86_incdec_reg(memory, data_width, address_width) {
    Some((length, name, register)) =>
      return Some(
        (length, name, [ProjectInstructionOperand::register(name=register)], []),
      )
    None => ()
  }
  match
    project_disassembly_basic_x86_unop_reg(memory, data_width, address_width) {
    Some((length, name, register)) =>
      return Some(
        (length, name, [ProjectInstructionOperand::register(name=register)], []),
      )
    None => ()
  }
  if bytes.length() < opcode_index + 3 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    if opcode != 0x83 || ((modrm >> 6) & 0x3) != 0x3 {
      None
    } else {
      let group = (modrm >> 3) & 0x7
      let op = match group {
        0 => "ADD"
        1 => "OR"
        4 => "AND"
        5 => "SUB"
        6 => "XOR"
        _ => ""
      }
      if op == "" {
        None
      } else {
        let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
        let register = project_disassembly_basic_x86_gpr_name(
          (modrm & 0x7) + rex_b,
          data_width,
        )
        Some(
          (
            opcode_index + 3,
            op + "\{data_width}ri8",
            [
              ProjectInstructionOperand::register(name=register),
              ProjectInstructionOperand::register(name=register),
              ProjectInstructionOperand::immediate(
                project_disassembly_basic_x86_signed_byte(
                  bytes[opcode_index + 2],
                ),
              ),
            ],
            [],
          ),
        )
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_incdec_reg(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (Int, String, String)? {
  let bytes = memory.to_bytes()
  if address_width == 32 && data_width == 32 && bytes.length() >= 1 {
    let opcode = bytes[0].to_int()
    if opcode >= 0x40 && opcode <= 0x47 {
      return Some(
        (1, "INC32r", project_disassembly_basic_x86_gpr32_name(opcode & 0x7)),
      )
    }
    if opcode >= 0x48 && opcode <= 0x4f {
      return Some(
        (1, "DEC32r", project_disassembly_basic_x86_gpr32_name(opcode & 0x7)),
      )
    }
  }
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    if opcode != 0xff || ((modrm >> 6) & 0x3) != 0x3 {
      None
    } else {
      let group = (modrm >> 3) & 0x7
      let op = match group {
        0 => "INC"
        1 => "DEC"
        _ => ""
      }
      if op == "" {
        None
      } else {
        let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
        Some(
          (
            opcode_index + 2,
            op + "\{data_width}r",
            project_disassembly_basic_x86_gpr_name(
              (modrm & 0x7) + rex_b,
              data_width,
            ),
          ),
        )
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_unop_reg(
  memory : @memory.Memory,
  data_width : Int,
  address_width : Int,
) -> (Int, String, String)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if data_width == 64 && (rex & 0x8) == 0 {
    return None
  }
  if data_width == 32 && (rex & 0x8) != 0 {
    return None
  }
  if data_width != 32 && data_width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    if opcode != 0xf7 || ((modrm >> 6) & 0x3) != 0x3 {
      None
    } else {
      let group = (modrm >> 3) & 0x7
      let op = match group {
        2 => "NOT"
        3 => "NEG"
        _ => ""
      }
      if op == "" {
        None
      } else {
        let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
        Some(
          (
            opcode_index + 2,
            op + "\{data_width}r",
            project_disassembly_basic_x86_gpr_name(
              (modrm & 0x7) + rex_b,
              data_width,
            ),
          ),
        )
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_push_reg(
  memory : @memory.Memory,
  width : Int,
) -> (Int, String)? {
  project_disassembly_basic_x86_stack_reg(memory, width, 0x50)
}

///|
fn project_disassembly_basic_x86_push_imm(
  memory : @memory.Memory,
  width : Int,
  address_width : Int,
) -> (Int, String, Int64)? {
  let bytes = memory.to_bytes()
  let (opcode_index, _) = if address_width == 64 &&
    bytes.length() >= 2 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if width != 32 && width != 64 {
    return None
  }
  if bytes.length() <= opcode_index {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    match opcode {
      0x6a =>
        if bytes.length() < opcode_index + 2 {
          None
        } else {
          Some(
            (
              opcode_index + 2,
              "PUSH\{width}i8",
              project_disassembly_basic_x86_signed_byte(bytes[opcode_index + 1]),
            ),
          )
        }
      0x68 =>
        match project_disassembly_basic_x86_i32_at(bytes, opcode_index + 1) {
          Some(imm) => Some((opcode_index + 5, "PUSH\{width}i32", imm))
          None => None
        }
      _ => None
    }
  }
}

///|
fn project_disassembly_basic_x86_push_rm(
  memory : @memory.Memory,
  width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if width != 32 && width != 64 {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    if opcode != 0xff || ((modrm >> 3) & 0x7) != 6 {
      None
    } else if ((modrm >> 6) & 0x3) == 0x3 {
      let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
      Some(
        (
          opcode_index + 2,
          "PUSH\{width}r",
          [
            ProjectInstructionOperand::register(
              name=project_disassembly_basic_x86_gpr_name(
                (modrm & 0x7) + rex_b,
                width,
              ),
            ),
          ],
          [ProjectMayStore],
        ),
      )
    } else {
      match
        project_disassembly_basic_x86_parse_mem_operand(
          bytes,
          opcode_index + 2,
          modrm,
          address_width,
          rex,
        ) {
        Some((length, memory_operand)) =>
          Some(
            (
              length,
              "PUSH\{width}m",
              project_disassembly_basic_x86_mem_operands(memory_operand),
              [ProjectMayLoad, ProjectMayStore],
            ),
          )
        None => None
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_group5_control(
  memory : @memory.Memory,
  width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let bytes = memory.to_bytes()
  let (opcode_index, rex) = if address_width == 64 &&
    bytes.length() >= 3 &&
    bytes[0].to_int() >= 0x40 &&
    bytes[0].to_int() <= 0x4f {
    (1, bytes[0].to_int())
  } else {
    (0, 0)
  }
  if width != address_width || (width != 32 && width != 64) {
    return None
  }
  if bytes.length() < opcode_index + 2 {
    None
  } else {
    let opcode = bytes[opcode_index].to_int()
    let modrm = bytes[opcode_index + 1].to_int()
    let group = (modrm >> 3) & 0x7
    let prefix = match group {
      2 => "CALL"
      4 => "JMP"
      _ => ""
    }
    if opcode != 0xff || prefix == "" {
      None
    } else {
      let control_kinds = if group == 2 {
        [ProjectCall, ProjectMayAffectControlFlow]
      } else {
        [ProjectUnconditionalBranch, ProjectMayAffectControlFlow]
      }
      if ((modrm >> 6) & 0x3) == 0x3 {
        let rex_b = if address_width == 64 && (rex & 0x1) != 0 { 8 } else { 0 }
        Some(
          (
            opcode_index + 2,
            "\{prefix}\{width}r",
            [
              ProjectInstructionOperand::register(
                name=project_disassembly_basic_x86_gpr_name(
                  (modrm & 0x7) + rex_b,
                  width,
                ),
              ),
            ],
            control_kinds,
          ),
        )
      } else {
        match
          project_disassembly_basic_x86_parse_mem_operand(
            bytes,
            opcode_index + 2,
            modrm,
            address_width,
            rex,
          ) {
          Some((length, memory_operand)) => {
            let kinds = if group == 2 {
              [ProjectCall, ProjectMayLoad, ProjectMayAffectControlFlow]
            } else {
              [
                ProjectUnconditionalBranch,
                ProjectMayLoad,
                ProjectMayAffectControlFlow,
              ]
            }
            Some(
              (
                length,
                "\{prefix}\{width}m",
                project_disassembly_basic_x86_mem_operands(memory_operand),
                kinds,
              ),
            )
          }
          None => None
        }
      }
    }
  }
}

///|
fn project_disassembly_basic_x86_simple(
  memory : @memory.Memory,
  width : Int,
  address_width : Int,
) -> (
  Int,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  match project_disassembly_basic_x86_reg_update(memory, width, address_width) {
    Some(decoded) => Some(decoded)
    None =>
      project_disassembly_basic_x86_group5_control(memory, width, address_width)
  }
}

///|
fn project_disassembly_basic_x86_pop_reg(
  memory : @memory.Memory,
  width : Int,
) -> (Int, String)? {
  project_disassembly_basic_x86_stack_reg(memory, width, 0x58)
}

///|
fn project_disassembly_basic_x86_stack_reg(
  memory : @memory.Memory,
  width : Int,
  base_opcode : Int,
) -> (Int, String)? {
  let bytes = memory.to_bytes()
  if bytes.length() == 0 {
    None
  } else if width == 64 && bytes.length() >= 2 {
    let rex = bytes[0].to_int()
    let opcode = bytes[1].to_int()
    if rex >= 0x40 &&
      rex <= 0x4f &&
      opcode >= base_opcode &&
      opcode <= base_opcode + 7 {
      Some(
        (
          2,
          project_disassembly_basic_x86_gpr64_name(
            opcode - base_opcode + (if (rex & 1) == 1 { 8 } else { 0 }),
          ),
        ),
      )
    } else if bytes[0].to_int() >= base_opcode &&
      bytes[0].to_int() <= base_opcode + 7 {
      Some(
        (
          1,
          project_disassembly_basic_x86_gpr64_name(
            bytes[0].to_int() - base_opcode,
          ),
        ),
      )
    } else {
      None
    }
  } else {
    let opcode = bytes[0].to_int()
    if opcode >= base_opcode && opcode <= base_opcode + 7 {
      Some(
        (
          1,
          if width == 64 {
            project_disassembly_basic_x86_gpr64_name(opcode - base_opcode)
          } else {
            project_disassembly_basic_x86_gpr32_name(opcode - base_opcode)
          },
        ),
      )
    } else {
      None
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
fn project_disassembly_basic_arm_word(memory : @memory.Memory) -> Int {
  let bytes = memory.to_bytes()
  bytes[0].to_int() |
  (bytes[1].to_int() << 8) |
  (bytes[2].to_int() << 16) |
  (bytes[3].to_int() << 24)
}

///|
fn project_disassembly_basic_arm_reg_name(code : Int) -> String {
  match code {
    0 => "R0"
    1 => "R1"
    2 => "R2"
    3 => "R3"
    4 => "R4"
    5 => "R5"
    6 => "R6"
    7 => "R7"
    8 => "R8"
    9 => "R9"
    10 => "R10"
    11 => "FP"
    12 => "R12"
    13 => "SP"
    14 => "LR"
    15 => "PC"
    _ => "R\{code}"
  }
}

///|
fn project_disassembly_basic_arm_reg(code : Int) -> ProjectInstructionOperand {
  ProjectInstructionOperand::register(
    name=project_disassembly_basic_arm_reg_name(code),
    code~,
  )
}

///|
fn project_disassembly_basic_arm_reg_text(code : Int) -> String {
  project_disassembly_basic_arm_reg_name(code).to_lower()
}

///|
fn project_disassembly_basic_arm_imm_text(value : Int64) -> String {
  if value < 0L {
    "#-" + (-value).to_string()
  } else {
    "#" + value.to_string()
  }
}

///|
fn project_disassembly_basic_arm_decode_data(
  word : Int,
) -> (
  String,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  if ((word >> 28) & 0xf) != 0xe || (word & 0x0c000000) != 0 {
    None
  } else {
    let immediate = ((word >> 25) & 1) == 1
    let opcode = (word >> 21) & 0xf
    let rn = (word >> 16) & 0xf
    let rd = (word >> 12) & 0xf
    let rotate = (word >> 8) & 0xf
    let imm = word & 0xff
    let rm = word & 0xf
    let shift = (word >> 4) & 0xff
    if immediate && rotate == 0 {
      match opcode {
        4 =>
          Some(
            (
              "ADDri",
              "add \{project_disassembly_basic_arm_reg_text(rd)}, \{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(imm.to_int64())}",
              [
                project_disassembly_basic_arm_reg(rd),
                project_disassembly_basic_arm_reg(rn),
                ProjectInstructionOperand::immediate(imm.to_int64()),
              ],
              [],
            ),
          )
        2 =>
          Some(
            (
              "SUBri",
              "sub \{project_disassembly_basic_arm_reg_text(rd)}, \{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(imm.to_int64())}",
              [
                project_disassembly_basic_arm_reg(rd),
                project_disassembly_basic_arm_reg(rn),
                ProjectInstructionOperand::immediate(imm.to_int64()),
              ],
              [],
            ),
          )
        13 =>
          Some(
            (
              "MOVi",
              "mov \{project_disassembly_basic_arm_reg_text(rd)}, \{project_disassembly_basic_arm_imm_text(imm.to_int64())}",
              [
                project_disassembly_basic_arm_reg(rd),
                ProjectInstructionOperand::immediate(imm.to_int64()),
              ],
              [],
            ),
          )
        10 =>
          Some(
            (
              "CMPri",
              "cmp \{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(imm.to_int64())}",
              [
                project_disassembly_basic_arm_reg(rn),
                ProjectInstructionOperand::immediate(imm.to_int64()),
              ],
              [],
            ),
          )
        _ => None
      }
    } else if !immediate && shift == 0 && opcode == 13 {
      Some(
        (
          "MOVr",
          "mov \{project_disassembly_basic_arm_reg_text(rd)}, \{project_disassembly_basic_arm_reg_text(rm)}",
          [
            project_disassembly_basic_arm_reg(rd),
            project_disassembly_basic_arm_reg(rm),
          ],
          [],
        ),
      )
    } else {
      None
    }
  }
}

///|
fn project_disassembly_basic_arm_decode_load_store(
  word : Int,
) -> (
  String,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  if ((word >> 28) & 0xf) != 0xe || (word & 0x0c000000) != 0x04000000 {
    None
  } else {
    let register_offset = ((word >> 25) & 1) == 1
    let pre_index = ((word >> 24) & 1) == 1
    let up = ((word >> 23) & 1) == 1
    let byte_transfer = ((word >> 22) & 1) == 1
    let writeback = ((word >> 21) & 1) == 1
    let load = ((word >> 20) & 1) == 1
    let rn = (word >> 16) & 0xf
    let rd = (word >> 12) & 0xf
    let unsigned_offset = word & 0xfff
    let offset = if up {
      unsigned_offset.to_int64()
    } else {
      -unsigned_offset.to_int64()
    }
    if register_offset || byte_transfer {
      None
    } else {
      let operands = [
        project_disassembly_basic_arm_reg(rd),
        project_disassembly_basic_arm_reg(rn),
        ProjectInstructionOperand::immediate(offset),
      ]
      if load && pre_index && !writeback {
        Some(
          (
            "LDRi12",
            "ldr \{project_disassembly_basic_arm_reg_text(rd)}, [\{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(offset)}]",
            operands,
            [ProjectMayLoad],
          ),
        )
      } else if !load && pre_index && !writeback {
        Some(
          (
            "STRi12",
            "str \{project_disassembly_basic_arm_reg_text(rd)}, [\{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(offset)}]",
            operands,
            [ProjectMayStore],
          ),
        )
      } else if !load && pre_index && writeback {
        Some(
          (
            "STR_PRE_IMM",
            "str \{project_disassembly_basic_arm_reg_text(rd)}, [\{project_disassembly_basic_arm_reg_text(rn)}, \{project_disassembly_basic_arm_imm_text(offset)}]!",
            operands,
            [ProjectMayStore],
          ),
        )
      } else if load && !pre_index && !writeback {
        Some(
          (
            "LDR_POST_IMM",
            "ldr \{project_disassembly_basic_arm_reg_text(rd)}, [\{project_disassembly_basic_arm_reg_text(rn)}], \{project_disassembly_basic_arm_imm_text(offset)}",
            operands,
            [ProjectMayLoad],
          ),
        )
      } else {
        None
      }
    }
  }
}

///|
fn project_disassembly_basic_arm_decode_known(
  memory : @memory.Memory,
) -> (
  String,
  String,
  Array[ProjectInstructionOperand],
  Array[ProjectInstructionKind],
)? {
  let word = project_disassembly_basic_arm_word(memory)
  match project_disassembly_basic_arm_decode_data(word) {
    Some(decoded) => Some(decoded)
    None => project_disassembly_basic_arm_decode_load_store(word)
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
fn project_disassembly_basic_decode_x86_simd_llvm(
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction?, String] {
  let xmm0 = ProjectInstructionOperand::register(name="XMM0")
  let xmm1 = ProjectInstructionOperand::register(name="XMM1")
  let xmm1_xmm0 = [xmm1, xmm0]
  let decoded : (
    Int,
    String,
    Array[ProjectInstructionOperand],
    Array[ProjectInstructionKind],
  )? = if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\x74\xc8") {
    Some((4, "PCMPEQB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\x64\xc8") {
    Some((4, "PCMPGTB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\xda\xc8") {
    Some((4, "PMINUB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x38\xc8",
    ) {
    Some((5, "PMINSB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\xde\xc8") {
    Some((4, "PMAXUB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3c\xc8",
    ) {
    Some((5, "PMAXSB", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3e\xc8",
    ) {
    Some((5, "PMAXUW", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\xee\xc8") {
    Some((4, "PMAXSW", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3a\xc8",
    ) {
    Some((5, "PMINUW", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(memory, b"\x66\x0f\xea\xc8") {
    Some((4, "PMINSW", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3b\xc8",
    ) {
    Some((5, "PMINUD", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x39\xc8",
    ) {
    Some((5, "PMINSD", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3f\xc8",
    ) {
    Some((5, "PMAXUD", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x3d\xc8",
    ) {
    Some((5, "PMAXSD", xmm1_xmm0, []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x00\xc1",
    ) {
    Some((5, "PSHUFB", [xmm0, xmm1], []))
  } else if project_disassembly_basic_has_prefix(
      memory, b"\x66\x0f\x38\x00\x00",
    ) {
    Some(
      (
        5,
        "PSHUFB",
        [xmm0, ProjectInstructionOperand::register(name="EAX")],
        [ProjectMayLoad],
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
        match project_disassembly_basic_arm_decode_known(memory) {
          Some((name, assembly, operands, kinds)) =>
            match memory.view(words=4) {
              Ok(chunk) =>
                Ok(
                  Some(
                    project_disassembly_basic_instruction(
                      chunk,
                      name,
                      assembly~,
                      operands~,
                      kinds~,
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
}

///|
fn project_disassembly_basic_decode_x86_llvm(
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyInstruction?, String] {
  match project_disassembly_basic_decode_x86_simd_llvm(memory) {
    Ok(Some(instruction)) => Ok(Some(instruction))
    Ok(None) => {
      let decoded : (
        Int,
        String,
        String,
        String,
        Array[ProjectInstructionOperand],
        Array[ProjectInstructionKind],
      )? = if project_disassembly_basic_has_prefix(memory, b"\x90") {
        Some((1, "NOOP", "nop", "", [], []))
      } else if project_disassembly_basic_x86_simple(memory, 32, 32) is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_simple(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_push_rm(memory, 32, 32) is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_push_rm(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_push_imm(memory, 32, 32)
        is Some(_) {
        let (length, name, imm) = project_disassembly_basic_x86_push_imm(
          memory, 32, 32,
        ).unwrap()
        Some(
          (
            length,
            name,
            "",
            "",
            [ProjectInstructionOperand::immediate(imm)],
            [ProjectMayStore],
          ),
        )
      } else if project_disassembly_basic_x86_push_reg(memory, 32) is Some(_) {
        let (length, register) = project_disassembly_basic_x86_push_reg(
          memory, 32,
        ).unwrap()
        Some(
          (
            length,
            "PUSH32r",
            "",
            "",
            [ProjectInstructionOperand::register(name=register)],
            [ProjectMayStore],
          ),
        )
      } else if project_disassembly_basic_x86_pop_reg(memory, 32) is Some(_) {
        let (length, register) = project_disassembly_basic_x86_pop_reg(
          memory, 32,
        ).unwrap()
        Some(
          (
            length,
            "POP32r",
            "",
            "",
            [ProjectInstructionOperand::register(name=register)],
            [ProjectMayLoad],
          ),
        )
      } else if project_disassembly_basic_x86_mov_rr(memory, 32) is Some(_) {
        let (length, name, dst, src) = project_disassembly_basic_x86_mov_rr(
          memory, 32,
        ).unwrap()
        Some(
          (
            length,
            name,
            "",
            "",
            [
              ProjectInstructionOperand::register(name=dst),
              ProjectInstructionOperand::register(name=src),
            ],
            [],
          ),
        )
      } else if project_disassembly_basic_x86_xchg(memory, 32, 32) is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_xchg(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_arith_rr(memory, 32, 32)
        is Some(_) {
        let (length, name, dst, src) = project_disassembly_basic_x86_arith_rr(
          memory, 32, 32,
        ).unwrap()
        Some(
          (
            length,
            name,
            "",
            "",
            [
              ProjectInstructionOperand::register(name=dst),
              ProjectInstructionOperand::register(name=src),
            ],
            [],
          ),
        )
      } else if project_disassembly_basic_x86_logic_rr(memory, 32, 32)
        is Some(_) {
        let (length, name, dst, src) = project_disassembly_basic_x86_logic_rr(
          memory, 32, 32,
        ).unwrap()
        Some(
          (
            length,
            name,
            "",
            "",
            [
              ProjectInstructionOperand::register(name=dst),
              ProjectInstructionOperand::register(name=src),
            ],
            [],
          ),
        )
      } else if project_disassembly_basic_x86_lea(memory, 32, 32) is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_lea(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_mov_mem(memory, 32, 32) is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_mem(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_mov_imm_rm(memory, 32, 32)
        is Some(_) {
        let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_imm_rm(
          memory, 32, 32,
        ).unwrap()
        Some((length, name, "", "", operands, kinds))
      } else if project_disassembly_basic_x86_mov32ri(memory) is Some(_) {
        let (dst, imm) = project_disassembly_basic_x86_mov32ri(memory).unwrap()
        Some(
          (
            5,
            "MOV32ri",
            "",
            "",
            [
              ProjectInstructionOperand::register(name=dst),
              ProjectInstructionOperand::immediate(imm),
            ],
            [],
          ),
        )
      } else if project_disassembly_basic_x86_call_rel32(memory) is Some(_) {
        let displacement = project_disassembly_basic_x86_call_rel32(memory).unwrap()
        Some(
          (
            5,
            "CALLpcrel32",
            "",
            "",
            [ProjectInstructionOperand::immediate(displacement)],
            [ProjectCall, ProjectMayAffectControlFlow],
          ),
        )
      } else if project_disassembly_basic_has_prefix(memory, b"\xc9") {
        Some((1, "LEAVE", "", "", [], [ProjectMayLoad]))
      } else if project_disassembly_basic_has_prefix(memory, b"\xc3") {
        Some(
          (
            1,
            "RET",
            "",
            "",
            [],
            [
              ProjectReturn,
              ProjectBarrier,
              ProjectTerminator,
              ProjectMayAffectControlFlow,
            ],
          ),
        )
      } else if project_disassembly_basic_x86_jmp_rel32(memory) is Some(_) {
        let (displacement, target) = project_disassembly_basic_x86_jmp_rel32(
          memory,
        ).unwrap()
        Some(
          (
            5,
            "JMP_4",
            "jmp " +
            ProjectInstructionOperand::immediate(displacement).to_string(),
            "jmp 0x" + target.to_string(radix=16),
            [
              ProjectInstructionOperand::immediate(
                target.reinterpret_as_int64(),
              ),
            ],
            [ProjectUnconditionalBranch, ProjectMayAffectControlFlow],
          ),
        )
      } else if project_disassembly_basic_x86_jmp_rel8(memory) is Some(_) {
        let (displacement, target) = project_disassembly_basic_x86_jmp_rel8(
          memory,
        ).unwrap()
        Some(
          (
            2,
            "JMP_1",
            "jmp " +
            ProjectInstructionOperand::immediate(displacement).to_string(),
            "jmp 0x" + target.to_string(radix=16),
            [
              ProjectInstructionOperand::immediate(
                target.reinterpret_as_int64(),
              ),
            ],
            [ProjectUnconditionalBranch, ProjectMayAffectControlFlow],
          ),
        )
      } else {
        None
      }
      match decoded {
        Some((length, name, assembly, bil, operands, kinds)) =>
          match memory.view(words=length) {
            Ok(chunk) =>
              Ok(
                Some(
                  project_disassembly_basic_instruction(
                    chunk,
                    name,
                    assembly~,
                    bil~,
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
    Err(reason) => Err(reason)
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
  )? = if project_disassembly_basic_x86_simple(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_simple(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_simple(memory, 32, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_simple(
      memory, 32, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_arith_rr(memory, 64, 64) is Some(_) {
    let (length, name, dst, src) = project_disassembly_basic_x86_arith_rr(
      memory, 64, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::register(name=src),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_arith_rr(memory, 32, 64) is Some(_) {
    let (length, name, dst, src) = project_disassembly_basic_x86_arith_rr(
      memory, 32, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::register(name=src),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_push_rm(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_push_rm(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_push_imm(memory, 64, 64) is Some(_) {
    let (length, name, imm) = project_disassembly_basic_x86_push_imm(
      memory, 64, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [ProjectInstructionOperand::immediate(imm)],
        [ProjectMayStore],
      ),
    )
  } else if project_disassembly_basic_x86_push_reg(memory, 64) is Some(_) {
    let (length, register) = project_disassembly_basic_x86_push_reg(memory, 64).unwrap()
    Some(
      (
        length,
        "PUSH64r",
        [ProjectInstructionOperand::register(name=register)],
        [ProjectMayStore],
      ),
    )
  } else if project_disassembly_basic_x86_pop_reg(memory, 64) is Some(_) {
    let (length, register) = project_disassembly_basic_x86_pop_reg(memory, 64).unwrap()
    Some(
      (
        length,
        "POP64r",
        [ProjectInstructionOperand::register(name=register)],
        [ProjectMayLoad],
      ),
    )
  } else if project_disassembly_basic_x86_mov_rr(memory, 64) is Some(_) {
    let (length, name, dst, src) = project_disassembly_basic_x86_mov_rr(
      memory, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::register(name=src),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_xchg(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_xchg(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_xchg(memory, 32, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_xchg(
      memory, 32, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_logic_rr(memory, 64, 64) is Some(_) {
    let (length, name, dst, src) = project_disassembly_basic_x86_logic_rr(
      memory, 64, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::register(name=src),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_logic_rr(memory, 32, 64) is Some(_) {
    let (length, name, dst, src) = project_disassembly_basic_x86_logic_rr(
      memory, 32, 64,
    ).unwrap()
    Some(
      (
        length,
        name,
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::register(name=src),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_x86_lea(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_lea(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_lea(memory, 32, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_lea(
      memory, 32, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_mov_mem(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_mem(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_mov_mem(memory, 32, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_mem(
      memory, 32, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_mov_imm_rm(memory, 64, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_imm_rm(
      memory, 64, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_mov_imm_rm(memory, 32, 64) is Some(_) {
    let (length, name, operands, kinds) = project_disassembly_basic_x86_mov_imm_rm(
      memory, 32, 64,
    ).unwrap()
    Some((length, name, operands, kinds))
  } else if project_disassembly_basic_x86_call_rel32(memory) is Some(_) {
    let displacement = project_disassembly_basic_x86_call_rel32(memory).unwrap()
    Some(
      (
        5,
        "CALL64pcrel32",
        [ProjectInstructionOperand::immediate(displacement)],
        [ProjectCall, ProjectMayAffectControlFlow],
      ),
    )
  } else if project_disassembly_basic_x86_64_mov64ri(memory) is Some(_) {
    let (dst, imm) = project_disassembly_basic_x86_64_mov64ri(memory).unwrap()
    Some(
      (
        10,
        "MOV64ri",
        [
          ProjectInstructionOperand::register(name=dst),
          ProjectInstructionOperand::immediate(imm),
        ],
        [],
      ),
    )
  } else if project_disassembly_basic_has_prefix(memory, b"\xc9") {
    Some((1, "LEAVE64", [], [ProjectMayLoad]))
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
