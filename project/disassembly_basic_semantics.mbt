///|
struct ProjectX86SimdState {
  registers_value : Map[String, @types.Word]
  vector_memory_value : Map[UInt64, @types.Word]
}

///|
fn project_x86_simd_register_key(name : String) -> String {
  name.to_upper()
}

///|
fn project_x86_simd_is_vector_register(name : String) -> Bool {
  let key = project_x86_simd_register_key(name)
  key.has_prefix("XMM") || key.has_prefix("YMM")
}

///|
fn project_x86_simd_copy_registers(
  registers : Map[String, @types.Word],
) -> Map[String, @types.Word] {
  let copy : Map[String, @types.Word] = {}
  registers.each((name, value) => copy[name] = value)
  copy
}

///|
fn project_x86_simd_copy_vector_memory(
  memory : Map[UInt64, @types.Word],
) -> Map[UInt64, @types.Word] {
  let copy : Map[UInt64, @types.Word] = {}
  memory.each((addr, value) => copy[addr] = value)
  copy
}

///|
fn project_x86_simd_addr(word : @types.Word) -> Result[UInt64, String] {
  try word.to_uint64() catch {
    _ => Err("x86 SIMD memory address is not representable")
  } noraise {
    value => Ok(value)
  }
}

///|
fn ProjectDisassemblyInstruction::project_x86_simd_register_operand(
  self : ProjectDisassemblyInstruction,
  index : Int,
) -> Result[String, String] {
  match self.operands_value.get(index) {
    Some(ProjectRegisterOperand(_, name)) =>
      Ok(project_x86_simd_register_key(name))
    Some(_) => Err("x86 SIMD instruction operand \{index} is not a register")
    None => Err("x86 SIMD instruction is missing operand \{index}")
  }
}

///|
fn ProjectX86SimdState::project_x86_simd_require_register(
  self : ProjectX86SimdState,
  name : String,
) -> Result[@types.Word, String] {
  let key = project_x86_simd_register_key(name)
  match self.registers_value.get(key) {
    Some(word) => Ok(word)
    None => Err("missing x86 SIMD register \{key}")
  }
}

///|
fn ProjectX86SimdState::project_x86_simd_require_vector_memory(
  self : ProjectX86SimdState,
  addr : UInt64,
) -> Result[@types.Word, String] {
  match self.vector_memory_value.get(addr) {
    Some(word) => Ok(word)
    None =>
      Err("missing x86 SIMD vector memory at 0x\{addr.to_string(radix=16)}")
  }
}

///|
fn ProjectX86SimdState::project_x86_simd_source_word(
  self : ProjectX86SimdState,
  source : String,
  memory_width : Int,
) -> Result[@types.Word, String] {
  if project_x86_simd_is_vector_register(source) {
    self.project_x86_simd_require_register(source)
  } else {
    match self.project_x86_simd_require_register(source) {
      Ok(addr_word) =>
        match project_x86_simd_addr(addr_word) {
          Ok(addr) =>
            if memory_width == 128 && (addr & 0xfUL) != 0UL {
              Err(
                "x86 SIMD memory operand at 0x\{addr.to_string(radix=16)} is not 16-byte aligned",
              )
            } else {
              self.project_x86_simd_require_vector_memory(addr)
            }
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  }
}

///|
fn ProjectDisassemblyInstruction::project_x86_simd_eval(
  self : ProjectDisassemblyInstruction,
  dest : @types.Word,
  source : @types.Word,
) -> Result[@types.Word, String] {
  match self.name_value.to_upper() {
    "PCMPEQB" => dest.packed_eq(source, element_width=8)
    "PCMPGTB" => dest.packed_gt(source, element_width=8, signed=true)
    "PMINUB" => dest.packed_min(source, element_width=8)
    "PMINSB" => dest.packed_min(source, element_width=8, signed=true)
    "PMAXUB" => dest.packed_max(source, element_width=8)
    "PMAXSB" => dest.packed_max(source, element_width=8, signed=true)
    "PMAXUW" => dest.packed_max(source, element_width=16)
    "PMAXSW" => dest.packed_max(source, element_width=16, signed=true)
    "PMINUW" => dest.packed_min(source, element_width=16)
    "PMINSW" => dest.packed_min(source, element_width=16, signed=true)
    "PMINUD" => dest.packed_min(source, element_width=32)
    "PMINSD" => dest.packed_min(source, element_width=32, signed=true)
    "PMAXUD" => dest.packed_max(source, element_width=32)
    "PMAXSD" => dest.packed_max(source, element_width=32, signed=true)
    "PSHUFB" => dest.x86_pshufb(source)
    name => Err("unsupported x86 SIMD instruction \{name}")
  }
}

///|
pub fn ProjectX86SimdState::empty() -> ProjectX86SimdState {
  { registers_value: {}, vector_memory_value: {} }
}

///|
pub fn ProjectX86SimdState::create(
  registers? : Array[(String, @types.Word)] = [],
  vector_memory? : Array[(UInt64, @types.Word)] = [],
) -> ProjectX86SimdState {
  let registers_map : Map[String, @types.Word] = {}
  for item in registers {
    registers_map[project_x86_simd_register_key(item.0)] = item.1
  }
  let memory_map : Map[UInt64, @types.Word] = {}
  for item in vector_memory {
    memory_map[item.0] = item.1
  }
  { registers_value: registers_map, vector_memory_value: memory_map }
}

///|
pub fn ProjectX86SimdState::registers(
  self : ProjectX86SimdState,
) -> Map[String, @types.Word] {
  project_x86_simd_copy_registers(self.registers_value)
}

///|
pub fn ProjectX86SimdState::vector_memory(
  self : ProjectX86SimdState,
) -> Map[UInt64, @types.Word] {
  project_x86_simd_copy_vector_memory(self.vector_memory_value)
}

///|
pub fn ProjectX86SimdState::get_register(
  self : ProjectX86SimdState,
  name : String,
) -> @types.Word? {
  self.registers_value.get(project_x86_simd_register_key(name))
}

///|
pub fn ProjectX86SimdState::with_register(
  self : ProjectX86SimdState,
  name~ : String,
  value : @types.Word,
) -> ProjectX86SimdState {
  let registers = project_x86_simd_copy_registers(self.registers_value)
  registers[project_x86_simd_register_key(name)] = value
  { ..self, registers_value: registers }
}

///|
pub fn ProjectX86SimdState::get_vector_memory(
  self : ProjectX86SimdState,
  addr : UInt64,
) -> @types.Word? {
  self.vector_memory_value.get(addr)
}

///|
pub fn ProjectX86SimdState::with_vector_memory(
  self : ProjectX86SimdState,
  addr~ : UInt64,
  value : @types.Word,
) -> ProjectX86SimdState {
  let memory = project_x86_simd_copy_vector_memory(self.vector_memory_value)
  memory[addr] = value
  { ..self, vector_memory_value: memory }
}

///|
pub fn ProjectDisassemblyInstruction::apply_x86_simd(
  self : ProjectDisassemblyInstruction,
  state : ProjectX86SimdState,
) -> Result[ProjectX86SimdState, String] {
  match self.project_x86_simd_register_operand(0) {
    Ok(dest_name) =>
      match self.project_x86_simd_register_operand(1) {
        Ok(source_name) =>
          match state.project_x86_simd_require_register(dest_name) {
            Ok(dest_word) =>
              match
                state.project_x86_simd_source_word(
                  source_name,
                  dest_word.width(),
                ) {
                Ok(source_word) =>
                  match self.project_x86_simd_eval(dest_word, source_word) {
                    Ok(result) =>
                      Ok(state.with_register(name=dest_name, result))
                    Err(reason) => Err(reason)
                  }
                Err(reason) => Err(reason)
              }
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectX86SimdState::apply_instruction(
  self : ProjectX86SimdState,
  instruction : ProjectDisassemblyInstruction,
) -> Result[ProjectX86SimdState, String] {
  instruction.apply_x86_simd(self)
}

///|
pub fn ProjectX86SimdState::apply_instructions(
  self : ProjectX86SimdState,
  instructions : Array[ProjectDisassemblyInstruction],
) -> Result[ProjectX86SimdState, String] {
  let mut state = self
  for instruction in instructions {
    match instruction.apply_x86_simd(state) {
      Ok(next) => state = next
      Err(reason) =>
        return Err(
          "failed to apply x86 SIMD instruction \{instruction.name()} at 0x\{instruction.addr().to_string(radix=16)}: \{reason}",
        )
    }
  }
  Ok(state)
}

///|
pub fn ProjectDisassemblyBasicState::apply_x86_simd(
  self : ProjectDisassemblyBasicState,
  state : ProjectX86SimdState,
) -> Result[ProjectX86SimdState, String] {
  let instructions : Array[ProjectDisassemblyInstruction] = []
  for item in self.insns_value {
    match item.1 {
      Some(instruction) => instructions.push(instruction)
      None => ()
    }
  }
  state.apply_instructions(instructions)
}

///|
pub fn ProjectDisassemblyState::apply_x86_simd(
  self : ProjectDisassemblyState,
  state : ProjectX86SimdState,
) -> Result[ProjectX86SimdState, String] {
  state.apply_instructions(self.instructions())
}

///|
pub fn Project::apply_x86_simd(
  self : Project,
  state : ProjectX86SimdState,
) -> Result[ProjectX86SimdState, String] {
  self.disassembly().apply_x86_simd(state)
}
