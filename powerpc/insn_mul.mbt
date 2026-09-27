// Port of BAP `plugins/powerpc/powerpc_mul.ml`.

///|
/// Multiply Low Immediate (page 73 of IBM Power ISA 3.0 B).
/// `1c 22 00 2a  mulli r1,r2,42`
fn mulli(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let si = ops.simm(2)
  [rt.set(ra * si)]
}

///|
/// Multiply High Word (page 73).
/// `7c 22 18 96  mulhw r1,r2,r3`
fn mulhw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let tmp1 = svar(doubleword)
  let tmp2 = svar(doubleword)
  [
    tmp1.set(ra.low(word)),
    tmp2.set(rb.low(word)),
    rt.set((tmp1 * tmp2).high(word)),
  ]
}

///|
/// Multiply High Word Unsigned (page 73).
/// `7c 22 18 16  mulhwu r1,r2,r3`
fn mulhwu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let tmp1 = uvar(doubleword)
  let tmp2 = uvar(doubleword)
  [
    tmp1.set(ra.low(word)),
    tmp2.set(rb.low(word)),
    rt.set((tmp1 * tmp2).high(word)),
  ]
}

///|
/// Multiply Low Word (page 73): the doubleword product of the signed low
/// words.
/// `7c 22 19 d6  mullw r1,r2,r3`
///
/// port: upstream multiplies the zero-extended words, which is wrong in the
/// upper half on 64-bit targets.
fn mullw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let tmp1 = svar(doubleword)
  let tmp2 = svar(doubleword)
  [
    tmp1.set(ra.low(word).signed()),
    tmp2.set(rb.low(word).signed()),
    rt.set(tmp1 * tmp2),
  ]
}

///|
/// Multiply Low Doubleword (page 79).
/// `7c 22 19 d2  mulld r1,r2,r3`
fn mulld(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  [rt.set(ra * rb)]
}

///|
/// Multiply High Doubleword (page 79).
/// `7c 22 18 92  mulhd r1,r2,r3`
fn mulhd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let tm = svar(quadword)
  [tm.set(ra), tm.set(tm * rb), rt.set(tm.high(doubleword))]
}

///|
/// Multiply High Doubleword Unsigned (page 79).
/// `7c 22 18 12  mulhdu r1,r2,r3`
fn mulhdu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let tm = uvar(quadword)
  [tm.set(ra), tm.set(tm * rb), rt.set(tm.high(doubleword))]
}

///|
fn init_mul() -> Unit {
  register_insn("MULLI", mulli)
  register_insn("MULHW", mulhw)
  register_dot_insn("MULHWo", mulhw)
  register_insn("MULHWU", mulhwu)
  register_dot_insn("MULHWUo", mulhwu)
  register_insn("MULLW", mullw)
  register_dot_insn("MULLWo", mullw)
  register_insn("MULLD", mulld)
  register_dot_insn("MULLDo", mulld)
  register_insn("MULHD", mulhd)
  register_dot_insn("MULHDo", mulhd)
  register_insn("MULHDU", mulhdu)
  register_dot_insn("MULHDUo", mulhdu)
}
