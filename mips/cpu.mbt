// Port of BAP `plugins/mips/mips_cpu.ml` together with the operand
// accessors of `mips_dsl.ml` (`reg`, `imm`, `var`).

///|
/// Lifting context: upstream's `cpu` record plus the operand array of the
/// instruction being lifted.
priv struct Cpu {
  arch : Arch
  endian : @bitvec.Endian
  insn : @mc.Insn
  /// Address of the current instruction, as a signed expression.
  cia : Exp
  tmps : Ref[Int32]
}

///|
fn Cpu::new(
  arch : Arch,
  endian : @bitvec.Endian,
  insn : @mc.Insn,
) -> Cpu raise @mc.LiftError {
  let addr = @types.Word::of_uint64(width=arch.addr_bitwidth(), insn.addr) catch {
    _ => raise mips_fail("invalid instruction address")
  }
  { arch, endian, insn, cia: Exp::of_word(addr).signed(), tmps: Ref(0), }
}

///|
fn Cpu::op(self : Cpu, index : Int32) -> @mc.Op raise @mc.LiftError {
  match self.insn.ops.get(index) {
    Some(op) => op
    None =>
      raise Failure(
        "instruction \{self.insn.name} doesn't have an operand with index \{index}",
      )
  }
}

///|
/// Upstream `Mips_cpu.find`: GPRs are looked up first, then FPRs; unknown
/// register names denote a zero constant of GPR width.
///
/// Deliberate deviation from upstream: the hardwired zero register (`ZERO`,
/// `ZERO_64`, `R0`) reads as the constant zero (upstream reads a `ZERO`
/// variable), and writes to it are discarded (see `translate_move`).
fn Cpu::find_reg(self : Cpu, name : String) -> Exp raise @mc.LiftError {
  if name is ("ZERO" | "ZERO_64" | "R0") {
    return Exp::of_word(make_word(self.arch.gpr_bitwidth(), 0L))
  }
  match (self.arch.find_gpr(name), self.arch.find_fpr(name)) {
    (Some(v), None) | (None, Some(v)) => Exp::of_var(v)
    (None, None) => Exp::of_word(make_word(self.arch.gpr_bitwidth(), 0L))
    (Some(_), Some(_)) =>
      raise mips_fail("Register name \{name} is ambiguous!!!")
  }
}

///|
/// The low word of `e`, as a signed value: the result of a 32-bit
/// operation, which is sign-extended when assigned to a MIPS64 register
/// (and assigned unchanged on MIPS32).
fn sword(e : Exp) -> Exp raise @mc.LiftError {
  low(word, e).signed()
}

///|
/// The low word of the register operand `index`, with the signedness
/// `sign` (the source operand of a 32-bit operation).
fn Cpu::wreg(self : Cpu, index : Int32, sign : Sign) -> Exp raise @mc.LiftError {
  apply_sign(sign, low(word, self.reg(index, sign)))
}

///|
fn Cpu::reg(self : Cpu, index : Int32, sign : Sign) -> Exp raise @mc.LiftError {
  match self.op(index) {
    Reg(name~, ..) => apply_sign(sign, self.find_reg(name))
    Imm(_) | Fmm(_) => raise mips_fail("reg operand expected")
  }
}

///|
/// Upstream `signed cpu.reg ops.(index)`.
fn Cpu::sreg(self : Cpu, index : Int32) -> Exp raise @mc.LiftError {
  self.reg(index, Signed)
}

///|
/// Upstream `unsigned cpu.reg ops.(index)`.
fn Cpu::ureg(self : Cpu, index : Int32) -> Exp raise @mc.LiftError {
  self.reg(index, Unsigned)
}

///|
/// Immediates are always materialized as 32-bit words.
fn Cpu::imm(self : Cpu, index : Int32, sign : Sign) -> Exp raise @mc.LiftError {
  match self.op(index) {
    Imm(x) => apply_sign(sign, Exp::of_word(make_word(32, x)))
    Reg(_) | Fmm(_) => raise mips_fail("imm operand expected")
  }
}

///|
/// Upstream `signed imm ops.(index)`.
fn Cpu::simm(self : Cpu, index : Int32) -> Exp raise @mc.LiftError {
  self.imm(index, Signed)
}

///|
/// Upstream `unsigned imm ops.(index)`.
fn Cpu::uimm(self : Cpu, index : Int32) -> Exp raise @mc.LiftError {
  self.imm(index, Unsigned)
}

///|
/// A fresh virtual temporary of the given width (upstream `var`). Names
/// are numbered per lifted instruction (`tmp1`, `tmp2`, ...), so the output
/// is deterministic.
fn Cpu::tmp(self : Cpu, sign : Sign, width : Int32) -> Exp raise @mc.LiftError {
  self.tmps.val += 1
  let v = @types.Var::new(
    name="tmp\{self.tmps.val}",
    typ=Imm(width),
    is_virtual=true,
  )
  apply_sign(sign, Exp::of_var(v))
}

///|
fn Cpu::svar(self : Cpu, width : Int32) -> Exp raise @mc.LiftError {
  self.tmp(Signed, width)
}

///|
fn Cpu::uvar(self : Cpu, width : Int32) -> Exp raise @mc.LiftError {
  self.tmp(Unsigned, width)
}

///|
fn size_of_width(width : Int32) -> @types.Size raise @mc.LiftError {
  match @types.Size::of_int(width) {
    Ok(size) => size
    Err(_) => raise mips_fail("invalid size: \{width}")
  }
}

///|
fn Cpu::load(self : Cpu, addr : Exp, width : Int32) -> Exp raise @mc.LiftError {
  Exp::load(self.arch.mem(), addr, self.endian, size_of_width(width))
}

///|
fn Cpu::store(
  self : Cpu,
  addr : Exp,
  data : Exp,
  width : Int32,
) -> Rtl raise @mc.LiftError {
  Store(self.arch.mem(), addr, data, self.endian, size_of_width(width))
}

///|
/// Jump; on 32-bit targets the destination is truncated to a word.
fn Cpu::jmp(self : Cpu, dst : Exp) -> Rtl raise @mc.LiftError {
  match self.arch {
    Mips32 => jmp(low(word, dst))
    Mips64 => jmp(dst)
  }
}

///|
fn Cpu::gpr(self : Cpu, index : Int32) -> Exp raise @mc.LiftError {
  match self.arch.gpr(index) {
    Some(v) => Exp::of_var(v)
    None => raise mips_fail("GPR with number \{index} not found")
  }
}

///|
/// `HI`, as a signed register: the 32-bit results assigned to it are
/// sign-extended on MIPS64.
fn Cpu::hi(self : Cpu) -> Exp raise @mc.LiftError {
  Exp::of_var(self.arch.hi()).signed()
}

///|
/// `LO`, as a signed register (see `Cpu::hi`).
fn Cpu::lo(self : Cpu) -> Exp raise @mc.LiftError {
  Exp::of_var(self.arch.lo()).signed()
}
