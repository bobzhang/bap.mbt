// Port of BAP `plugins/powerpc/powerpc_logical.ml` (pages 92-100 of IBM
// Power ISA 3.0 B).
//
// Extended mnemonics:
//   nop           = ori 0, 0, 0
//   xnop          = xri 0, 0, 0
//   mr  rx, ry    = or rx, ry, ry
//   not rx, ry    = nor rx, ry, ry

///|
/// Operands `ra, rs, x` of a two-source logical instruction, where `x` is
/// either a register or an unsigned immediate.
fn logical_reg_operands(
  cpu : Cpu,
  ops : Operands,
) -> (RtlExp, RtlExp, RtlExp) raise @mc.LiftError {
  (cpu.ureg(ops, 0), cpu.ureg(ops, 1), cpu.ureg(ops, 2))
}

///|
fn logical_imm_operands(
  cpu : Cpu,
  ops : Operands,
) -> (RtlExp, RtlExp, RtlExp) raise @mc.LiftError {
  (cpu.ureg(ops, 0), cpu.ureg(ops, 1), ops.uimm(2))
}

///|
/// AND Immediate. `71 2a 00 20  andi. r10,r9,32`
fn andi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs & im)]
}

///|
/// AND Immediate Shifted. `75 2a 08 00  andis. r10,r9,2048`
fn andis(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs & im.shl(uconst(byte, 16)))]
}

///|
/// AND. `7f 39 e8 38  and r25,r25,r29`
fn and_(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set(rs & rb)]
}

///|
/// AND with Complement. `7c ea 50 78  andc r10,r7,r10`
fn andc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set(rs & rb.lnot())]
}

///|
/// OR Immediate. `60 c6 51 c1  ori r6,r6,20929`
fn ori(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs | im)]
}

///|
/// `60 00 00 00  nop` (equivalent to `ori 0,0,0`)
fn nop(_cpu : Cpu, _ops : Operands) -> Array[Rtl] {
  []
}

///|
/// OR Immediate Shifted. `65 4a 00 10  oris r10,r10,16`
fn oris(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs | im.shl(uconst(byte, 16)))]
}

///|
/// OR. `7f 38 c3 78  or r24,r25,r24`
fn or_(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set(rs | rb)]
}

///|
/// OR with Complement. `7c 8a 53 38  orc r10,r4,r10`
fn orc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set(rs | rb.lnot())]
}

///|
/// XOR Immediate. `68 63 00 01  xori r3,r3,1`
fn xori(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs ^ im)]
}

///|
/// XOR Immediate Shifted. `6d 2a 04 00  xoris r10,r9,1024`
fn xoris(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, im) = logical_imm_operands(cpu, ops)
  [ra.set(rs ^ im.shl(uconst(byte, 16)))]
}

///|
/// XOR. `7c 6a 52 78  xor r10,r3,r10`
fn xor(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set(rs ^ rb)]
}

///|
/// NAND. `7c 63 1b b8  nand r3,r3,r3`
fn nand(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set((rs & rb).lnot())]
}

///|
/// NOR. `7d 09 48 f8  nor r9,r8,r9`
fn nor(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set((rs | rb).lnot())]
}

///|
/// Equivalent. `7d 09 4a 38  eqv r9,r8,r9`
fn eqv(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  [ra.set((rs ^ rb).lnot())]
}

///|
/// Extend Sign Byte. `7d 4a 07 74  extsb r10,r10`
fn extsb(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.sreg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  [ra.set(rs.low(byte))]
}

///|
/// Extend Sign Halfword. `7d 25 07 34  extsh r5,r9`
fn extsh(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.sreg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  [ra.set(rs.low(halfword))]
}

///|
/// Extend Sign Word. `7d 25 07 b4  extsw r5,r9`
fn extsw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.sreg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  [ra.set(rs.low(word))]
}

///|
/// Count leading zeros of `xv` (iterating from the most significant bit).
fn count_leading_zeros(ra : RtlExp, xv : RtlExp, init : Rtl) -> Array[Rtl] {
  let cnt = uvar(byte)
  let has_no_ones = uvar(bit)
  let biti = uvar(bit)
  [
    init,
    cnt.set(zero),
    has_no_ones.set(one),
    foreach(biti, xv, [
      if_(has_no_ones & biti.eq(zero), [cnt.set(cnt + one)], [
        has_no_ones.set(zero),
      ]),
    ]),
    ra.set(cnt),
  ]
}

///|
/// Count Leading Zeros Word. `7c 63 00 34  cntlzw r3,r3`
fn cntlzw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let xv = uvar(word)
  count_leading_zeros(ra, xv, xv.set(rs.low(word)))
}

///|
/// Count Leading Zeros Doubleword. `7c 63 00 74  cntlzd r3,r3`
fn cntlzd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let xv = uvar(doubleword)
  count_leading_zeros(ra, xv, xv.set(rs))
}

///|
/// Count trailing zeros of `xv`: the counter restarts at every one bit.
fn count_trailing_zeros(ra : RtlExp, xv : RtlExp, init : Rtl) -> Array[Rtl] {
  let cnt = uvar(word)
  let biti = uvar(bit)
  [
    init,
    cnt.set(zero),
    foreach(biti, xv, [
      if_(biti.eq(zero), [cnt.set(cnt + one)], [cnt.set(zero)]),
    ]),
    ra.set(cnt),
  ]
}

///|
/// Count Trailing Zeros Word. `7c 63 04 34  cnttzw r3,r3`
fn cnttzw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let xv = uvar(word)
  count_trailing_zeros(ra, xv, xv.set(rs.low(word)))
}

///|
/// Count Trailing Zeros Doubleword. `7c 63 04 74  cnttzd r3,r3`
fn cnttzd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let xv = uvar(doubleword)
  count_trailing_zeros(ra, xv, xv.set(rs))
}

///|
/// Compare Bytes. `7c 8a 53 f8  cmpb r10,r4,r10`
fn cmpb(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  let xb = uconst(byte, 0xFF)
  let ind = uvar(byte)
  let byte_i = uvar(byte)
  let byte_j = uvar(byte)
  let byte_k = uvar(byte)
  let sh = uconst(byte, 8)
  let tmp = uvar(cpu.word_width)
  [
    ind.set(zero),
    tmp.set(zero),
    foreach(byte_k, tmp, [
      byte_i.set(rs.shl(ind * sh).nth(byte, 0)),
      byte_j.set(rb.shl(ind * sh).nth(byte, 0)),
      when_(byte_i.eq(byte_j), [byte_k.set(xb)]),
      ind.set(ind + one),
    ]),
    ra.set(tmp),
  ]
}

///|
/// Population Count Words. `7c 84 02 f4  popcntw r4,r4`
fn popcntw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let cnt = uvar(word)
  let res = uvar(cpu.word_width)
  let word_i = uvar(word)
  let word_j = uvar(word)
  let bit_i = uvar(bit)
  let ind = uvar(word)
  let x = uconst(byte, 32)
  [
    res.set(zero),
    ind.set(zero),
    foreach(word_j, res, [
      cnt.set(zero),
      word_i.set(rs.shl(ind * x).nth(word, 0)),
      foreach(bit_i, word_i, [when_(bit_i.eq(one), [cnt.set(cnt + one)])]),
      word_j.set(cnt),
      ind.set(ind + one),
    ]),
    ra.set(res),
  ]
}

///|
/// Population Count Doubleword. `7c 84 03 f4  popcntd r4,r4`
fn popcntd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let cnt = uvar(doubleword)
  let bit_i = uvar(bit)
  [
    cnt.set(zero),
    foreach(bit_i, rs, [when_(bit_i.eq(one), [cnt.set(cnt + one)])]),
    ra.set(cnt),
  ]
}

///|
/// Bit Permute Doubleword (page 100). `7c a1 49 f8  bpermd r1,r5,r9`
fn bpermd(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let (ra, rs, rb) = logical_reg_operands(cpu, ops)
  let max_ind = uconst(byte, 64)
  let tmp = uvar(byte)
  let bit_index = uvar(byte)
  let ind = uvar(byte)
  let x = uvar(doubleword)
  let max = uconst(byte, 7)
  [
    tmp.set(zero),
    ind.set(max),
    foreach(bit_index, rs, [
      if_(bit_index.lt(max_ind), [x.set(rb.shl(bit_index).msb())], [
        x.set(zero),
      ]),
      tmp.set(tmp | x.shl(ind)),
      ind.set(ind - one),
    ]),
    ra.set(tmp),
  ]
}

///|
/// Negate (page 72). `7c 22 00 d0  neg r1,r2`
fn neg(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  [rt.set(ra.lnot() + one)]
}

///|
fn init_logical() -> Unit {
  register_dot_insn("ANDIo", andi)
  register_dot_insn("ANDISo", andis)
  register_insn("AND", and_)
  register_dot_insn("ANDo", and_)
  register_insn("ANDC", andc)
  register_dot_insn("ANDCo", andc)
  register_insn("ORI", ori)
  register_insn("NOP", infallible(nop))
  register_insn("ORIS", oris)
  register_insn("OR", or_)
  register_dot_insn("ORo", or_)
  register_insn("ORC", orc)
  register_dot_insn("ORCo", orc)
  register_insn("XORI", xori)
  register_insn("XORIS", xoris)
  register_insn("XOR", xor)
  register_dot_insn("XORo", xor)
  register_insn("NAND", nand)
  register_dot_insn("NANDo", nand)
  register_insn("NOR", nor)
  register_dot_insn("NORo", nor)
  register_insn("EQV", eqv)
  register_dot_insn("EQVo", eqv)
  register_insn("EXTSB", extsb)
  register_dot_insn("EXTSBo", extsb)
  register_insn("EXTSH", extsh)
  register_dot_insn("EXTSHo", extsh)
  register_insn("EXTSW", extsw)
  register_dot_insn("EXTSWo", extsw)
  register_insn("CNTLZW", cntlzw)
  register_dot_insn("CNTLZWo", cntlzw)
  register_insn("CNTLZD", cntlzd)
  register_dot_insn("CNTLZDo", cntlzd)
  register_insn("CNTTZW", cnttzw)
  register_dot_insn("CNTTZWo", cnttzw)
  register_insn("CNTTZD", cnttzd)
  register_dot_insn("CNTTZDo", cnttzd)
  register_insn("CMPB", cmpb)
  register_insn("POPCNTW", popcntw)
  register_insn("POPCNTD", popcntd)
  register_insn("BPERMD", bpermd)
  register_insn("NEG", neg)
  register_dot_insn("NEGo", neg)
}
