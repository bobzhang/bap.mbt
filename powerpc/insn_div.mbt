// Port of BAP `plugins/powerpc/powerpc_div.ml`.

///|
/// Divide Word (page 74 of IBM Power ISA 3.0 B).
/// `7c 22 1b d6  divw r1,r2,r3`
fn divw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let dividend = svar(word)
  let divisor = svar(word)
  [
    dividend.set(ra.low(word)),
    divisor.set(rb.low(word)),
    rt.set(dividend / divisor),
  ]
}

///|
/// Divide Word Unsigned (page 74).
/// `7c 22 1b 96  divwu r1,r2,r3`
fn divwu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra.low(word) / rb.low(word))]
}

///|
/// Divide Word Extended (page 75).
/// `7c 22 1b 56  divwe r1,r2,r3`
fn divwe(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let x = svar(doubleword)
  [
    x.set(zero),
    x.high(word).set(ra.low(word)),
    rt.set((x / rb.low(word)).low(word)),
  ]
}

///|
/// Divide Word Extended Unsigned (page 75).
/// `7c 22 1b 16  divweu r1,r2,r3`
fn divweu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let x = uvar(doubleword)
  [
    x.set(zero),
    x.high(word).set(ra.low(word)),
    rt.set((x / rb.low(word)).low(word)),
  ]
}

///|
/// Modulo Signed Word (page 77).
/// `7c 22 1e 16  modsw r1,r2,r3`
fn modsw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let dividend = svar(word)
  let divisor = svar(word)
  [
    dividend.set(ra.low(word)),
    divisor.set(rb.low(word)),
    rt.set(dividend % divisor),
  ]
}

///|
/// Modulo Unsigned Word (page 77).
/// `7c 22 1a 16  moduw r1,r2,r3`
fn moduw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra.low(word) % rb.low(word))]
}

///|
/// Divide Doubleword (page 81).
/// `7c 22 1b d2  divd r1,r2,r3`
fn divd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  [rt.set(ra / rb)]
}

///|
/// Divide Doubleword Unsigned (page 81).
/// `7c 22 1b 92  divdu r1,r2,r3`
fn divdu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra / rb)]
}

///|
/// Divide Doubleword Extended (page 82).
/// `7c 22 1b 52  divde r1,r2,r3`
fn divde(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let tm1 = svar(quadword)
  let tm2 = svar(quadword)
  [
    tm1.set(zero),
    tm1.high(doubleword).set(ra),
    tm2.set(tm1 / rb),
    rt.set(tm2.low(doubleword)),
  ]
}

///|
/// Divide Doubleword Extended Unsigned (page 82).
/// `7c 22 1b 12  divdeu r1,r2,r3`
fn divdeu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let tm1 = uvar(quadword)
  let tm2 = uvar(quadword)
  [
    tm1.set(zero),
    tm1.high(doubleword).set(ra),
    tm2.set(tm1 / rb),
    rt.set(tm2.low(doubleword)),
  ]
}

///|
/// Modulo Signed Doubleword (page 83).
/// `7c 22 1e 12  modsd r1,r2,r3`
fn modsd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  [rt.set(ra % rb)]
}

///|
/// Modulo Unsigned Doubleword (page 83).
/// `7c 22 1a 12  modud r1,r2,r3`
fn modud(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra % rb)]
}

///|
fn init_div() -> Unit {
  register_insn("DIVW", divw)
  register_dot_insn("DIVWo", divw)
  register_insn("DIVWU", divwu)
  register_dot_insn("DIVWUo", divwu)
  register_insn("DIVWE", divwe)
  register_dot_insn("DIVWEo", divwe)
  register_insn("DIVWEU", divweu)
  register_dot_insn("DIVWEUo", divweu)
  register_insn("MODSW", modsw)
  register_insn("MODUW", moduw)
  register_insn("DIVD", divd)
  register_dot_insn("DIVDo", divd)
  register_insn("DIVDU", divdu)
  register_dot_insn("DIVDUo", divdu)
  register_insn("DIVDE", divde)
  register_dot_insn("DIVDEo", divde)
  register_insn("DIVDEU", divdeu)
  register_dot_insn("DIVDEUo", divdeu)
  register_insn("MODSD", modsd)
  register_insn("MODUD", modud)
}
