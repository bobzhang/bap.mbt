// Port of BAP `plugins/powerpc/powerpc_compare.ml`.

///|
/// Write the LT/GT/EQ/SO bits of the CR field `bf` for `lhs <=> rhs`.
fn compare_into(
  cpu : Cpu,
  bf : RtlExp,
  lhs : RtlExp,
  rhs : RtlExp,
) -> Array[Rtl] {
  [
    bf.nth(bit, 0).set(lhs.lt(rhs)),
    bf.nth(bit, 1).set(lhs.gt(rhs)),
    bf.nth(bit, 2).set(lhs.eq(rhs)),
    bf.nth(bit, 3).set(cpu.so),
  ]
}

///|
/// Compare Immediate, word (page 85 of IBM Power ISA 3.0 B).
/// `2f 89 ff ff  cmpwi cr7,r9,-1`
fn cmpwi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let si = ops.simm(2)
  compare_into(cpu, bf, ra.low(word).signed(), si)
}

///|
/// Compare Immediate, doubleword.
/// `2f a9 ff ff  cmpdi cr7,r9,-1`
fn cmpdi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let si = ops.simm(2)
  compare_into(cpu, bf, ra, si)
}

///|
/// Compare, word (page 85).
/// `7f 86 38 00  cmpw cr7,r6,r7`
///
/// port: compares the low words of both operands (upstream compares the
/// low word of `ra` with the whole `rb`, and unsigned on 32-bit targets
/// when `ra` is a register).
fn cmpw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  compare_into(cpu, bf, ra.low(word).signed(), rb.low(word).signed())
}

///|
/// Compare, doubleword.
/// `7f a6 38 00  cmpd cr7,r6,r7`
fn cmpd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  compare_into(cpu, bf, ra, rb)
}

///|
/// Compare Logical Immediate, word (page 86).
/// `2b 89 00 01  cmplwi cr7,r9,1`
fn cmplwi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let ui = ops.uimm(2)
  compare_into(cpu, bf, ra.low(word), ui)
}

///|
/// Compare Logical Immediate, doubleword.
/// `2b a9 00 01  cmpldi cr7,r9,1`
fn cmpldi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let ui = ops.uimm(2)
  compare_into(cpu, bf, ra, ui)
}

///|
/// Compare Logical, word (page 86).
/// `7f 86 38 40  cmplw cr7,r6,r7`
///
/// port: compares the low words of both operands (upstream compares the
/// low word of `ra` with the whole `rb`).
fn cmplw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  compare_into(cpu, bf, ra.low(word), rb.low(word))
}

///|
/// Compare Logical, doubleword.
/// `7f a6 38 40  cmpld cr7,r6,r7`
fn cmpld(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bf = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  compare_into(cpu, bf, ra, rb)
}

///|
fn init_compare() -> Unit {
  register_insn("CMPWI", cmpwi)
  register_insn("CMPDI", cmpdi)
  register_insn("CMPW", cmpw)
  register_insn("CMPD", cmpd)
  register_insn("CMPLWI", cmplwi)
  register_insn("CMPLDI", cmpldi)
  register_insn("CMPLW", cmplw)
  register_insn("CMPLD", cmpld)
}
