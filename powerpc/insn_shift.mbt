// Port of BAP `plugins/powerpc/powerpc_shift.ml` (pages 107-110 of IBM
// Power ISA 3.0 B).

///|
/// Shift Left Word. `7d 2a 58 30  slw r10,r9,r11`
fn slw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let sh = uconst(byte, 5)
  [
    if_(rb.shr(sh).lsb().eq(zero), [ra.set(rs.low(word).shl(rb.last(5)))], [
      ra.set(zero),
    ]),
  ]
}

///|
/// Shift Right Word. `7d 2a 5c 30  srw r10,r9,r11`
fn srw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let sh = uconst(byte, 5)
  [
    if_(rb.shr(sh).lsb().eq(zero), [ra.set(rs.low(word).shr(rb.last(5)))], [
      ra.set(zero),
    ]),
  ]
}

///|
/// Shift Right Algebraic Word Immediate. `7d 2a 5e 70  srawi r10,r9,11`
fn srawi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let mask = uvar(cpu.word_width)
  let carry_ones = uvar(bit)
  let all_ones = uconst(cpu.word_width, -1)
  let w32 = uconst(byte, 32)
  let tm = svar(word)
  [
    mask.set(all_ones),
    carry_ones.set((mask.shl(sh).lnot() & rs).neq(zero)),
    tm.set(rs.low(word)),
    cpu.ca.set(carry_ones & tm.lt(zero)),
    cpu.ca32.set(cpu.ca),
    if_(tm.ge(zero), [ra.set(rs.low(word).shr(sh))], [
      if_(ra.width_exp().eq(w32), [mask.set(mask.shr(sh))], [
        mask.set(mask.shr(w32 + sh)),
      ]),
      ra.set(rs.low(word).shr(sh) | mask.lnot()),
    ]),
  ]
}

///|
/// Shift Right Algebraic Word. `7d 2a 5e 30  sraw r10,r9,r11`
fn sraw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let mask = uvar(cpu.word_width)
  let w32 = uconst(cpu.word_width, 32)
  let carry_ones = uvar(bit)
  let s = uvar(bit)
  let shift = uvar(byte)
  let tm = svar(word)
  [
    mask.set(zero),
    shift.set(rb.last(6)),
    when_(rb.last(6).lt(w32), [mask.set(mask.lnot().shl(shift))]),
    tm.set(rs.low(word)),
    s.set(tm.lt(zero)),
    carry_ones.set((mask.lnot() & rs).neq(zero)),
    cpu.ca.set(carry_ones & s),
    cpu.ca32.set(cpu.ca),
    if_(s.eq(zero), [ra.set(rs.low(word).shr(shift))], [
      if_(ra.width_exp().eq(w32), [mask.set(mask.shr(shift))], [
        mask.set(mask.shr(w32 + shift)),
      ]),
      ra.set(rs.low(word).shr(shift) | mask.lnot()),
    ]),
  ]
}

///|
/// Shift Left Doubleword. `7d 2a 58 36  sld r10,r9,r11`
fn sld(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [ra.set(rs.shl(rb.last(6)))]
}

///|
/// Shift Right Doubleword. `7d 2a 5c 36  srd r10,r9,r11`
fn srd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [ra.set(rs.shr(rb.last(6)))]
}

///|
/// Shift Right Algebraic Doubleword Immediate. `7d 2a 26 74  sradi r10,r9,4`
fn sradi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let mask = uvar(doubleword)
  let carry_ones = uvar(bit)
  let tm = svar(cpu.word_width)
  [
    mask.set(zero),
    mask.set(mask.lnot()),
    carry_ones.set((mask.shl(sh).lnot() & rs).neq(zero)),
    tm.set(rs),
    cpu.ca.set(carry_ones & tm.lt(zero)),
    cpu.ca32.set(cpu.ca),
    if_(tm.ge(zero), [ra.set(rs.shr(sh))], [
      mask.set(mask.shr(sh)),
      ra.set(rs.shr(sh) | mask.lnot()),
    ]),
  ]
}

///|
/// Shift Right Algebraic Doubleword. `7d 2a 5e 34  srad r10,r9,r11`
fn srad(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let mask = uvar(doubleword)
  let carry_ones = uvar(bit)
  let s = uvar(bit)
  let shift = uvar(byte)
  let tm = svar(cpu.word_width)
  [
    mask.set(zero),
    shift.set(rb.last(7)),
    when_(rb.nth(bit, 57).eq(zero), [mask.set(mask.lnot().shl(shift))]),
    tm.set(rs),
    s.set(tm.lt(zero)),
    carry_ones.set((mask.lnot() & rs).neq(zero)),
    cpu.ca.set(carry_ones & s),
    cpu.ca32.set(cpu.ca),
    if_(s.eq(zero), [ra.set(rs.shr(shift))], [
      mask.set(mask.shr(shift)),
      ra.set(rs.shr(shift) | mask.lnot()),
    ]),
  ]
}

///|
fn init_shift() -> Unit {
  register_insn("SLW", slw)
  register_insn("SRW", srw)
  register_insn("SRAWI", srawi)
  register_insn("SRAW", sraw)
  register_insn("SLD", sld)
  register_insn("SRD", srd)
  register_insn("SRADI", sradi)
  register_insn("SRAD", srad)
  register_dot_insn("SLWo", slw)
  register_dot_insn("SRWo", srw)
  register_dot_insn("SRAWIo", srawi)
  register_dot_insn("SRAWo", sraw)
  register_dot_insn("SLDo", sld)
  register_dot_insn("SRDo", srd)
  register_dot_insn("SRADIo", sradi)
  register_dot_insn("SRADo", srad)
}
