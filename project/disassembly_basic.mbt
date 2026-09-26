///|
pub(all) enum ProjectDisassemblyBasicPred {
  BasicValid
  BasicKind(ProjectInstructionKind)
} derive(Eq, Debug)

///|
pub extend ProjectDisassemblyBasicPred with Eq::{not_equal, equal}

///|
pub extend ProjectDisassemblyBasicPred with Debug::{to_repr}

///|
pub(all) enum ProjectDisassemblyBasicRemainder {
  BasicLeft(@memory.Memory)
  BasicFinished
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
  { ..self, store_asm_value: true, }
}

///|
pub fn ProjectDisassemblyBasic::store_kinds(
  self : ProjectDisassemblyBasic,
) -> ProjectDisassemblyBasic {
  { ..self, store_kinds_value: true, }
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
                    [
                      ProjectUnconditionalBranch,
                      ProjectBarrier,
                      ProjectTerminator,
                      ProjectMayAffectControlFlow,
                    ]
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
