// Ports of `Arm_reg`, `Arm_op`, `Arm_cond` and `Arm_insn`: decoding of
// backend register names, operands, condition codes and opcode names into
// the typed ARM representation.

///|
/// Register name as printed by upstream (`Arm_reg.to_string`).
pub fn Reg::name(self : Reg) -> String {
  match self {
    Nil => "Nil"
    R0 => "R0"
    R1 => "R1"
    R2 => "R2"
    R3 => "R3"
    R4 => "R4"
    R5 => "R5"
    R6 => "R6"
    R7 => "R7"
    R8 => "R8"
    R9 => "R9"
    R10 => "R10"
    R11 => "R11"
    R12 => "R12"
    LR => "LR"
    PC => "PC"
    SP => "SP"
    CPSR => "CPSR"
    SPSR => "SPSR"
    ITSTATE => "ITSTATE"
  }
}

///|
/// All registers, in upstream declaration order.
pub fn Reg::all() -> Array[Reg] {
  [
    Nil,
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    R8,
    R9,
    R10,
    R11,
    R12,
    LR,
    PC,
    SP,
    CPSR,
    SPSR,
    ITSTATE,
  ]
}

///|
/// `Arm_reg.create`: decode a backend register name (exact match on the
/// upstream constructor spelling, e.g. `R0`, `SP`, `CPSR`, `Nil`).
pub fn Reg::of_name(name : StringView) -> Reg? {
  for reg in Reg::all() {
    if name == reg.name() {
      return Some(reg)
    }
  }
  None
}

///|
/// Whether the register is a general purpose register (`gpr_reg`).
pub fn Reg::is_gpr(self : Reg) -> Bool {
  !(self is (Nil | CPSR | SPSR | ITSTATE))
}

///|
pub fn Op::to_string(self : Op) -> String {
  match self {
    Reg(reg) => "(Reg \{reg.name()})"
    Imm(imm) => "(Imm \{imm_word(imm).to_string()})"
  }
}

///|
/// `Arm_op.create`: convert a backend operand. Floating-point immediates
/// and unknown registers are rejected; integer immediates are truncated to
/// 32 bits.
pub fn Op::of_mc(op : @mc.Op) -> Op? {
  match op {
    Fmm(_) => None
    Reg(name~, ..) => Reg::of_name(name).map(r => Reg(r))
    Imm(value) => Some(Imm(value.to_int().reinterpret_as_uint()))
  }
}

///|
/// `Arm_cond.of_int_exn` without the exception.
pub fn Cond::of_int(n : Int) -> Cond? {
  match n {
    0 => Some(EQ)
    1 => Some(NE)
    2 => Some(CS)
    3 => Some(CC)
    4 => Some(MI)
    5 => Some(PL)
    6 => Some(VS)
    7 => Some(VC)
    8 => Some(HI)
    9 => Some(LS)
    10 => Some(GE)
    11 => Some(LT)
    12 => Some(GT)
    13 => Some(LE)
    14 => Some(AL)
    _ => None
  }
}

///|
pub fn Insn::name(self : Insn) -> String {
  match self {
    Move(i) => i.name()
    Bits(i) => i.name()
    Mult(i) => i.name()
    Mem(i) => i.name()
    MemMulti(i) => i.name()
    Branch(i) => i.name()
    Special(i) => i.name()
  }
}

///|
/// Every instruction supported by the lifter.
pub fn Insn::all() -> Array[Insn] {
  let all : Array[Insn] = []
  for i in MoveInsn::all() {
    all.push(Move(i))
  }
  for i in BitsInsn::all() {
    all.push(Bits(i))
  }
  for i in MultInsn::all() {
    all.push(Mult(i))
  }
  for i in MemMultiInsn::all() {
    all.push(MemMulti(i))
  }
  for i in MemInsn::all() {
    all.push(Mem(i))
  }
  for i in BranchInsn::all() {
    all.push(Branch(i))
  }
  for i in SpecialInsn::all() {
    all.push(Special(i))
  }
  all
}

///|
let insn_table : Map[String, Insn] = {
  let table = Map([])
  for insn in Insn::all() {
    table[insn.name()] = insn
  }
  table
}

///|
/// `Arm_insn.is_thumb2`.
pub fn is_thumb2(name : StringView) -> Bool {
  name.has_prefix("t2")
}

///|
/// `Arm_insn.of_name`: decode an LLVM MC opcode name. Thumb-2 opcodes
/// (`t2` prefix) are recoded as their ARM counterparts, except branches.
pub fn Insn::of_name(name : StringView) -> Insn? {
  let is_t2 = is_thumb2(name)
  let name = if is_t2 { name[2:] } else { name }
  match insn_table.get(name.to_owned()) {
    Some(Branch(_)) if is_t2 => None
    None if is_t2 => insn_table.get(t2_alias(name))
    other => other
  }
}

///|
/// port: the A32 counterpart of a Thumb-2 opcode whose name differs
/// (upstream has no semantics for them): the shifted-register forms
/// (`t2ANDrs` is `ANDrsi`, except `t2ADDrs`, `t2EORrs` and `t2RSBrs`, which
/// the Thumb Lisp semantics define), the negative 8-bit offsets of word and
/// byte accesses (`t2LDRi8` is `LDRi12`) and the byte accesses with a
/// shifted register offset (`t2LDRBs` is `LDRBrs`, see `lift_mem_t32`).
fn t2_alias(name : StringView) -> String {
  match name {
    "ADDrs" | "EORrs" | "RSBrs" => ""
    "LDRi8" | "STRi8" | "LDRBi8" | "STRBi8" =>
      name[:name.length() - 2].to_owned() + "i12"
    "LDRBs" | "STRBs" => name[:name.length() - 1].to_owned() + "rs"
    _ if name.has_suffix("rs") => name.to_owned() + "i"
    "MVNs" => "MVNsi"
    _ => ""
  }
}
