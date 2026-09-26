// Port of BAP `plugins/powerpc/powerpc_cr.ml`: condition register logical
// instructions (pages 40-41 of IBM Power ISA 3.0 B).

///|
/// Operands `bt, ba, bb` of a CR logical instruction.
fn cr_operands(
  cpu : Cpu,
  ops : Operands,
) -> (RtlExp, RtlExp, RtlExp) raise @mc.LiftError {
  (cpu.ureg(ops, 0), cpu.ureg(ops, 1), cpu.ureg(ops, 2))
}

///|
/// `4c 22 1a 02  crand 1,2,3`
fn crand(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba & bb)]
}

///|
/// `4c 22 19 c2  crnand 1,2,3`
fn crnand(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set((ba & bb).lnot())]
}

///|
/// `4c 22 1b 82  cror 1,2,3`
fn cror(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba | bb)]
}

///|
/// `4c 22 19 82  crxor 1,2,3`
fn crxor(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba ^ bb)]
}

///|
/// `4c 22 18 42  crnor 1,2,3`
fn crnor(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set((ba | bb).lnot())]
}

///|
/// `4c 22 1a 42  creqv 1,2,3`
fn creqv(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba ^ bb.lnot())]
}

///|
/// `4c 22 19 02  crandc 1,2,3`
fn crandc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba & bb.lnot())]
}

///|
/// `4c 22 1b 42  crorc 1,2,3`
fn crorc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (bt, ba, bb) = cr_operands(cpu, ops)
  [bt.set(ba | bb.lnot())]
}

///|
/// Move Condition Register Field.
/// `4c 88 00 00  mcrf 1,2`
fn mcrf(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bt = cpu.ureg(ops, 0)
  let bs = cpu.ureg(ops, 1)
  [bt.set(bs)]
}

///|
fn init_cr() -> Unit {
  register_insn("CRAND", crand)
  register_insn("CRNAND", crnand)
  register_insn("CROR", cror)
  register_insn("CRXOR", crxor)
  register_insn("CRNOR", crnor)
  register_insn("CREQV", creqv)
  register_insn("CRANDC", crandc)
  register_insn("CRORC", crorc)
  register_insn("MCRF", mcrf)
}
