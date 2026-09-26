// Port of BAP `plugins/powerpc/powerpc_sub.ml`.

///|
/// Subtract From (page 69 of IBM Power ISA 3.0 B).
/// `7c 22 18 50  subf r1,r2,r3`
fn subf(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra.lnot() + rb + one)]
}

///|
/// Subtract From Immediate Carrying (page 70).
/// `20 22 10 92  subfic r1,r2,4242`
fn subfic(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let si = ops.simm(2)
  [
    rt.set(ra.lnot() + si + one),
    cpu.ca.set(si.low(cpu.word_width).lt(ra)),
    cpu.ca32.set(si.low(word).lt(ra.low(word))),
  ]
}

///|
/// Subtract From Carrying (page 70).
/// `7c 22 18 10  subfc r1,r2,r3`
fn subfc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [
    rt.set(ra.lnot() + rb + one),
    cpu.ca.set(rb.low(cpu.word_width).lt(ra.low(cpu.word_width))),
    cpu.ca32.set(rb.low(word).lt(ra.low(word))),
  ]
}

///|
/// Subtract From Extended (page 71).
/// `7c 22 19 10  subfe r1,r2,r3`
fn subfe(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [
    rt.set(ra.lnot() + rb + cpu.ca),
    cpu.ca32.set(rb.low(word).lt((ra + one - cpu.ca).low(word))),
    cpu.ca.set(rb.lt(ra + one - cpu.ca)),
  ]
}

///|
/// Subtract From Minus One Extended (page 71).
/// `7c 22 01 d0  subfme r1,r2`
fn subfme(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  [rt.set(ra.lnot() + cpu.ca - one), cpu.ca32.set(one), cpu.ca.set(one)]
}

///|
/// Subtract From Zero Extended (page 71).
/// `7c 22 01 90  subfze r1,r2`
fn subfze(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  [rt.set(ra.lnot() + cpu.ca), cpu.ca32.set(one), cpu.ca.set(one)]
}

///|
fn init_sub() -> Unit {
  register_insn("SUBF", subf)
  register_dot_insn("SUBFo", subf)
  register_insn("SUBFIC", subfic)
  register_insn("SUBFC", subfc)
  register_dot_insn("SUBFCo", subfc)
  register_insn("SUBFE", subfe)
  register_dot_insn("SUBFEo", subfe)
  register_insn("SUBFME", subfme)
  register_dot_insn("SUBFMEo", subfme)
  register_insn("SUBFZE", subfze)
  register_dot_insn("SUBFZEo", subfze)
}
