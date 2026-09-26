// Port of BAP `plugins/powerpc/powerpc_cpu.ml` and `powerpc_types.ml`: the
// CPU view handed to instruction lifters.

///|
/// CPU model used by lifters: register expressions, memory access helpers
/// and the address of the current instruction.
pub struct Cpu {
  model : Model
  endian : @bitvec.Endian
  /// address of the current instruction (signed, address-size wide)
  pc : RtlExp
  /// natural register width (32 or 64)
  word_width : Int
  ctr : RtlExp
  lr : RtlExp
  tar : RtlExp
  /// condition register (all 32 bits)
  cr : RtlExp
  cr0 : RtlExp
  cr1 : RtlExp
  cr2 : RtlExp
  cr3 : RtlExp
  cr4 : RtlExp
  cr5 : RtlExp
  cr6 : RtlExp
  cr7 : RtlExp
  so : RtlExp
  ca : RtlExp
  ov : RtlExp
  ca32 : RtlExp
  ov32 : RtlExp
}

///|
/// Create the CPU view for an instruction at `addr`.
pub fn Cpu::create(
  addr_size : AddrSize,
  endian : @bitvec.Endian,
  addr : UInt64,
) -> Cpu {
  let model = Model::of_addr_size(addr_size)
  let word_width = addr_size.in_bits()
  let pc = RtlExp::of_word(
    @types.Word::of_uint64(width=word_width, addr) catch {
      _ => abort("PowerPC lifter: invalid address width")
    },
  ).signed()
  {
    model,
    endian,
    pc,
    word_width,
    ctr: RtlExp::of_var(model.ctr),
    lr: RtlExp::of_var(model.lr),
    tar: RtlExp::of_var(model.tar),
    cr: model.cr(),
    cr0: model.cr_field(0),
    cr1: model.cr_field(1),
    cr2: model.cr_field(2),
    cr3: model.cr_field(3),
    cr4: model.cr_field(4),
    cr5: model.cr_field(5),
    cr6: model.cr_field(6),
    cr7: model.cr_field(7),
    so: RtlExp::of_var(model.so),
    ca: RtlExp::of_var(model.ca),
    ov: RtlExp::of_var(model.ov),
    ca32: RtlExp::of_var(model.ca32),
    ov32: RtlExp::of_var(model.ov32),
  }
}

///|
fn size_of_width(width : Int) -> @types.Size raise @mc.LiftError {
  match @types.Size::of_int_opt(width) {
    Some(size) => size
    None => raise Failure("PowerPC lifter fail: invalid size: \{width}")
  }
}

///|
/// `cpu.load(addr, width)` loads `width` bits from memory.
pub fn Cpu::load(
  self : Cpu,
  addr : RtlExp,
  width : Int,
) -> RtlExp raise @mc.LiftError {
  RtlExp::load(self.model.mem, addr, self.endian, size_of_width(width))
}

///|
/// `cpu.store(addr, data, width)` stores the low `width` bits of `data`.
pub fn Cpu::store(
  self : Cpu,
  addr : RtlExp,
  data : RtlExp,
  width : Int,
) -> Rtl raise @mc.LiftError {
  Store(self.model.mem, addr, data, self.endian, size_of_width(width))
}

///|
/// Jump to `addr` (truncated to the address size on 32-bit targets).
pub fn Cpu::jmp(self : Cpu, addr : RtlExp) -> Rtl {
  match self.model.addr_size {
    R32 => Jmp(addr.low(word))
    R64 => Jmp(addr)
  }
}

///|
/// General purpose register `n` (0..31).
pub fn Cpu::gpr(self : Cpu, n : Int) -> RtlExp raise @mc.LiftError {
  match self.model.gpri.get(n) {
    Some(v) => RtlExp::of_var(v)
    None => raise Failure("PowerPC lifter fail: GPR with number \{n} not found")
  }
}

///|
/// Floating-point register `n` (0..31).
pub fn Cpu::fpr(self : Cpu, n : Int) -> RtlExp raise @mc.LiftError {
  match self.model.fpri.get(n) {
    Some(v) => RtlExp::of_var(v)
    None => raise Failure("PowerPC lifter fail: FPR with number \{n} not found")
  }
}

///|
/// Vector register `n` (0..31).
pub fn Cpu::vr(self : Cpu, n : Int) -> RtlExp raise @mc.LiftError {
  match self.model.vri.get(n) {
    Some(v) => RtlExp::of_var(v)
    None => raise Failure("PowerPC lifter fail: VR with number \{n} not found")
  }
}

///|
/// Expression for the register named `name` (LLVM MC name). Unknown
/// registers (e.g. `ZERO`, `ZERO8`) denote a GPR-wide zero, as upstream.
pub fn Cpu::find_reg(self : Cpu, name : String) -> RtlExp {
  let model = self.model
  if model.gpr.get(name) is Some(v) {
    RtlExp::of_var(v)
  } else if model.crn.get(name) is Some(v) {
    RtlExp::of_var(v)
  } else if model.cr_fields.get(name) is Some(vars) {
    RtlExp::of_vars(vars)
  } else if model.fpr.get(name) is Some(v) {
    RtlExp::of_var(v)
  } else if model.vr.get(name) is Some(v) {
    RtlExp::of_var(v)
  } else {
    RtlExp::of_word(make_word(model.gpr_bitwidth, 0))
  }
}

///|
/// Instruction operands together with the opcode name (for diagnostics).
pub struct Operands {
  name : String
  ops : ReadOnlyArray[@mc.Op]
}

///|
pub fn Operands::of_insn(insn : @mc.Insn) -> Operands {
  { name: insn.name, ops: insn.ops, }
}

///|
/// Operand `i`, or `BadOperands` when missing.
pub fn Operands::get(self : Operands, i : Int) -> @mc.Op raise @mc.LiftError {
  match self.ops.get(i) {
    Some(op) => op
    None => raise BadOperands(opcode=self.name, detail="missing operand \{i}")
  }
}

///|
/// Immediate operand `i` as a 32-bit constant with the given sign.
pub fn Operands::imm(
  self : Operands,
  i : Int,
  sign : Sign,
) -> RtlExp raise @mc.LiftError {
  match self.get(i) {
    Imm(value) => RtlExp::of_word(make_word(32, value)).with_sign(sign)
    Reg(..) | Fmm(_) =>
      raise Failure("PowerPC lifter fail: imm operand expected")
  }
}

///|
/// Signed immediate operand `i`.
pub fn Operands::simm(self : Operands, i : Int) -> RtlExp raise @mc.LiftError {
  self.imm(i, Signed)
}

///|
/// Memory displacement operand `i` of a D- or DS-form load or store, as a
/// signed 32-bit constant: LLVM (since version 17) leaves the D-form
/// displacement as the raw 16-bit field, so the low 16 bits are
/// sign-extended (a no-op for the already sign-extended DS-form values).
pub fn Operands::disp(self : Operands, i : Int) -> RtlExp raise @mc.LiftError {
  match self.get(i) {
    Imm(value) => {
      let disp = (value.to_int() & 0xffff) << 16 >> 16
      RtlExp::of_word(make_word(32, disp.to_int64())).with_sign(Signed)
    }
    Reg(..) | Fmm(_) =>
      raise Failure("PowerPC lifter fail: imm operand expected")
  }
}

///|
/// Unsigned immediate operand `i`.
pub fn Operands::uimm(self : Operands, i : Int) -> RtlExp raise @mc.LiftError {
  self.imm(i, Unsigned)
}

///|
/// Register operand `i` with the given sign.
pub fn Cpu::reg(
  self : Cpu,
  ops : Operands,
  i : Int,
  sign : Sign,
) -> RtlExp raise @mc.LiftError {
  match ops.get(i) {
    Reg(name~, ..) => self.find_reg(name).with_sign(sign)
    Imm(_) | Fmm(_) =>
      raise Failure("PowerPC lifter fail: reg operand expected")
  }
}

///|
/// Signed register operand `i`.
pub fn Cpu::sreg(
  self : Cpu,
  ops : Operands,
  i : Int,
) -> RtlExp raise @mc.LiftError {
  self.reg(ops, i, Signed)
}

///|
/// Unsigned register operand `i`.
pub fn Cpu::ureg(
  self : Cpu,
  ops : Operands,
  i : Int,
) -> RtlExp raise @mc.LiftError {
  self.reg(ops, i, Unsigned)
}
