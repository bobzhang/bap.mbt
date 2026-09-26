// Port of BAP `plugins/powerpc/powerpc_rotate.ml` (pages 102-106 of IBM
// Power ISA 3.0 B).
//
// Word rotations rotate the low word of `rs` by replicating it three times
// (`tmp ^ tmp ^ tmp`) and taking the high `word_width` bits of the shifted
// concatenation.

///|
/// Compute the rotate-word mask for `mb`/`me` into `mask`, following the
/// upstream formulation (bit numbers are relative to the low word on 64-bit
/// targets).
fn word_rotate_mask(
  cpu : Cpu,
  ra : RtlExp,
  mb : RtlExp,
  me : RtlExp,
  mask : RtlExp,
  w32 : RtlExp,
) -> Array[Rtl] {
  let start = uvar(cpu.word_width)
  let stop = uvar(cpu.word_width)
  let all_ones = uconst(cpu.word_width, -1)
  let width_ra = ra.width_exp()
  [
    if_(width_ra.neq(w32), [start.set(mb + w32), stop.set(me + w32)], [
      start.set(mb),
      stop.set(me),
    ]),
    mask.set(all_ones),
    if_(
      mb.le(me),
      [mask.set(mask.shr(start) & mask.shl(width_ra - stop - one))],
      [mask.set(mask.shl(width_ra - stop) | mask.shr(start + one))],
    ),
  ]
}

///|
/// Rotate Left Word Immediate then AND with Mask (page 102).
/// `55 2a 18 a0  rlwinm r10,r8,3,2,16`
fn rlwinm(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let mb = ops.uimm(3)
  let me = ops.uimm(4)
  let tmp = uvar(word)
  let mask = uvar(cpu.word_width)
  let w32 = uconst(word, 32)
  [
    ..word_rotate_mask(cpu, ra, mb, me, mask, w32),
    tmp.set(rs.nth(word, 1)),
    ra.set(triple(tmp).shl(sh).nth(cpu.word_width, 0) & mask),
  ]
}

///|
/// Rotate Left Word then AND with Mask (page 103).
/// `5d 2a 19 54  rlwnm r10,r9,r3,5,10`
fn rlwnm(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let mb = ops.uimm(3)
  let me = ops.uimm(4)
  let tmp = uvar(word)
  let mask = uvar(cpu.word_width)
  let w32 = uconst(word, 32)
  [
    ..word_rotate_mask(cpu, ra, mb, me, mask, w32),
    tmp.set(rs.nth(word, 1)),
    ra.set(
      triple(tmp).shl(rb.last(5)).nth(cpu.word_width, 0) & mask,
    ),
  ]
}

///|
/// Rotate Left Word Immediate then Mask Insert (page 103).
/// `51 2a 19 54  rlwimi r10,r9,3,5,10`
fn rlwimi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 1)
  let rs = cpu.ureg(ops, 2)
  let sh = ops.uimm(3)
  let mb = ops.uimm(4)
  let me = ops.uimm(5)
  let tmp1 = uvar(word)
  let tmp2 = uvar(cpu.word_width)
  let mask = uvar(cpu.word_width)
  let w32 = uconst(cpu.word_width, 32)
  [
    ..word_rotate_mask(cpu, ra, mb, me, mask, w32),
    tmp1.set(rs.nth(word, 1)),
    tmp2.set(triple(tmp1).shl(sh).nth(cpu.word_width, 0)),
    ra.set((tmp2 & mask) | (ra & mask.lnot())),
  ]
}

///|
/// `x ^ x ^ x` (right associative, as upstream).
fn triple(x : RtlExp) -> RtlExp {
  x.concat(x.concat(x))
}

///|
/// `rs` rotated left by `sh` (doubleword rotation).
fn rotl64(rs : RtlExp, sh : RtlExp) -> RtlExp {
  triple(rs).shl(sh).nth(doubleword, 0)
}

///|
/// Rotate Left Doubleword Immediate then Clear Left (page 104).
/// `79 2a 7f e2  rldicl r10,r9,47,63`
fn rldicl(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let mb = ops.uimm(3)
  let mask = uvar(doubleword)
  [
    mask.set(zero),
    mask.set(mask.lnot().shr(mb)),
    ra.set(rotl64(rs, sh) & mask),
  ]
}

///|
/// Rotate Left Doubleword Immediate then Clear Right (page 104).
/// `79 2a 26 44  rldicr r10,r9,4,25`
fn rldicr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let me = ops.uimm(3)
  let mask = uvar(doubleword)
  let width = uconst(doubleword, 64)
  [
    mask.set(zero),
    mask.set(mask.lnot().shl(width - me - one)),
    ra.set(rotl64(rs, sh) & mask),
  ]
}

///|
/// Rotate Left Doubleword Immediate then Clear (page 105).
/// `79 2a 26 48  rldic r10,r9,4,25`
fn rldic(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let sh = ops.uimm(2)
  let mb = ops.uimm(3)
  let mask = uvar(doubleword)
  let mask1 = uvar(doubleword)
  let mask2 = uvar(doubleword)
  let all_ones = uconst(doubleword, -1)
  [
    mask.set(all_ones),
    mask1.set(mask.shr(mb)),
    mask2.set(mask.shl(sh)),
    mask.set(mask1 & mask2),
    ra.set(rotl64(rs, sh) & mask),
  ]
}

///|
/// Rotate Left Doubleword then Clear Left (page 105).
/// `79 2a 5e 50  rldcl r10,r9,r11,25`
fn rldcl(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let mb = ops.uimm(3)
  let mask = uvar(doubleword)
  [
    mask.set(zero),
    mask.set(mask.lnot().shr(mb)),
    ra.set(rotl64(rs, rb.last(6)) & mask),
  ]
}

///|
/// Rotate Left Doubleword then Clear Right (page 106).
/// `79 2a 5e 52  rldcr r10,r9,r11,25`
fn rldcr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 0)
  let rs = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  let me = ops.uimm(3)
  let mask = uvar(doubleword)
  let width = uconst(doubleword, 64)
  [
    mask.set(zero),
    mask.set(mask.lnot().shl(width - me - one)),
    ra.set(rotl64(rs, rb.last(6)) & mask),
  ]
}

///|
/// Rotate Left Doubleword Immediate then Mask Insert (page 106).
/// `79 2a 26 4c  rldimi r10,r9,4,25`
fn rldimi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(ops, 1)
  let rs = cpu.ureg(ops, 2)
  let sh = ops.uimm(3)
  let mb = ops.uimm(4)
  let tmp = uvar(doubleword)
  let mask = uvar(doubleword)
  let mask1 = uvar(doubleword)
  let mask2 = uvar(doubleword)
  let all_ones = uconst(doubleword, -1)
  [
    mask.set(all_ones),
    mask1.set(mask.shr(mb)),
    mask2.set(mask.shl(sh)),
    mask.set(mask1 & mask2),
    tmp.set(rotl64(rs, sh)),
    ra.set((tmp & mask) | (ra & mask.lnot())),
  ]
}

///|
fn init_rotate() -> Unit {
  register_insn("RLWINM", rlwinm)
  register_insn("RLWNM", rlwnm)
  register_insn("RLWIMI", rlwimi)
  register_insn("RLDICL", rldicl)
  register_insn("RLDICR", rldicr)
  register_insn("RLDIC", rldic)
  register_insn("RLDCL", rldcl)
  register_insn("RLDCR", rldcr)
  register_insn("RLDIMI", rldimi)
  register_dot_insn("RLWINMo", rlwinm)
  register_dot_insn("RLWNMo", rlwnm)
  register_dot_insn("RLWIMIo", rlwimi)
  register_dot_insn("RLDICLo", rldicl)
  register_dot_insn("RLDICRo", rldicr)
  register_dot_insn("RLDICo", rldic)
  register_dot_insn("RLDCLo", rldcl)
  register_dot_insn("RLDCRo", rldcr)
  register_dot_insn("RLDIMIo", rldimi)
}
