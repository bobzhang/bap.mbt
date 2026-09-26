// Port of BAP `plugins/powerpc/powerpc_move.ml`.

///|
/// SPR number from the 10-bit split field (halves swapped).
fn spr_number(sr : RtlExp) -> (RtlExp, Array[Rtl]) {
  let tmp = uvar(10)
  let num = uvar(word)
  (num, [tmp.set(sr), num.set(tmp.bits(5, 9).concat(tmp.bits(0, 4)))])
}

///|
/// Move To Special Purpose Register (page 116 of IBM Power ISA 3.0 B).
/// `7c 20 4b a6  mtspr 9,r1`
fn mtspr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let sr = ops.uimm(0)
  let rs = cpu.ureg(ops, 1)
  let lr_num = uconst(word, 8)
  let ctr_num = uconst(word, 9)
  let (num, code) = spr_number(sr)
  code +
  [
    switch_(num, [
      case(lr_num, [cpu.lr.set(rs)]),
      case(ctr_num, [cpu.ctr.set(rs)]),
      default([message("Unknown cpu.register number")]),
    ]),
  ]
}

///|
/// Move From Special Purpose Register (page 116).
/// `7c 20 42 a6  mfspr r1,8`
fn mfspr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let sr = ops.uimm(1)
  let lr_num = uconst(word, 8)
  let ctr_num = uconst(word, 9)
  let (num, code) = spr_number(sr)
  code +
  [
    switch_(num, [
      case(lr_num, [rt.set(cpu.lr)]),
      case(ctr_num, [rt.set(cpu.ctr)]),
      default([message("Unknown cpu.register number")]),
    ]),
  ]
}

///|
/// Move To CR Fields (page 121).
/// `7c 20 81 20  mtcrf 8,r1`
fn mtcrf(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let fx = ops.uimm(0)
  let rs = cpu.ureg(ops, 1)
  let mask = uvar(word)
  let bit_i = uvar(bit)
  let halfbyte_i = uvar(4)
  let nibble_ones = uconst(4, 0xF)
  let ind = uvar(byte)
  let fxm = uvar(byte)
  [
    mask.set(zero),
    ind.set(zero),
    fxm.set(fx),
    foreach(halfbyte_i, mask, [
      bit_i.set(fxm.shl(ind).msb()),
      if_(bit_i.eq(one), [halfbyte_i.set(nibble_ones)], [halfbyte_i.set(zero)]),
      ind.set(ind + one),
    ]),
    cpu.cr.set((rs.low(word) & mask) | (cpu.cr & mask.lnot())),
  ]
}

///|
/// Move From CR (page 122).
/// `7c 20 00 26  mfcr r1`
fn mfcr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  [rt.set(cpu.cr)]
}

///|
/// `7c 09 03 a6  mtctr r0`
fn mtctr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  [cpu.ctr.set(rs)]
}

///|
/// `7c 08 03 a6  mtlr r0`
fn mtlr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  [cpu.lr.set(rs)]
}

///|
/// `7c 09 02 a6  mfctr r0`
fn mfctr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  [rt.set(cpu.ctr)]
}

///|
/// `7c 08 02 a6  mflr r0`
fn mflr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  [rt.set(cpu.lr)]
}

///|
fn init_move() -> Unit {
  register_insn("MTSPR", mtspr)
  register_insn("MFSPR", mfspr)
  register_insn("MTCRF", mtcrf)
  register_insn("MFCR", mfcr)
  register_insn("MTCTR", mtctr)
  register_insn("MTLR", mtlr)
  register_insn("MFCTR", mfctr)
  register_insn("MFLR", mflr)
}
