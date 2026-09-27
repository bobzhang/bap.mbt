// Port of BAP `plugins/powerpc/powerpc_load.ml` (pages 48-61 of IBM Power
// ISA 3.0 B).
//
// Operand layouts produced by LLVM:
//   D-form      `lwz rt, d(ra)`    -> [rt, d, ra]
//   D-form, u   `lwzu rt, d(ra)`   -> [rt, ra(wb), d, ra]
//   X-form      `lwzx rt, ra, rb`  -> [rt, ra, rb]
//   X-form, u   `lwzux rt, ra, rb` -> [rt, ra(wb), ra, rb]

///|
/// `rt := load(ra + d)` for a D-form load with operands `[rt, d, ra]`.
fn load_d(
  cpu : Cpu,
  ops : Operands,
  width : Int,
  sign : Sign,
) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.reg(ops, 0, sign)
  let im = ops.disp(1)
  let ra = cpu.sreg(ops, 2)
  [rt.set(cpu.load(ra + im, width))]
}

///|
/// `rt := load(ra + rb)` for an X-form load with operands `[rt, ra, rb]`.
fn load_x(
  cpu : Cpu,
  ops : Operands,
  width : Int,
  sign : Sign,
) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.reg(ops, 0, sign)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  [rt.set(cpu.load(ra + rb, width))]
}

///|
/// D-form load with update, operands `[rt, ra(wb), d, ra]`.
fn load_du(
  cpu : Cpu,
  ops : Operands,
  width : Int,
  sign : Sign,
) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.reg(ops, 0, sign)
  let im = ops.disp(2)
  let ra = cpu.sreg(ops, 3)
  [rt.set(cpu.load(ra + im, width)), ra.set(ra + im)]
}

///|
/// X-form load with update, operands `[rt, ra(wb), ra, rb]`.
fn load_xu(
  cpu : Cpu,
  ops : Operands,
  width : Int,
  sign : Sign,
) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.reg(ops, 0, sign)
  let ra = cpu.sreg(ops, 2)
  let rb = cpu.sreg(ops, 3)
  [rt.set(cpu.load(ra + rb, width)), ra.set(ra + rb)]
}

///|
/// Load Byte and Zero. `89 3c 00 14  lbz r9,20(r28)`
fn lbz(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, byte, Unsigned)
}

///|
/// Load Halfword and Zero. `a1 3c 00 14  lhz r9,20(r28)`
fn lhz(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, halfword, Unsigned)
}

///|
/// Load Word and Zero. `83 eb ff fc  lwz r31,-4(r11)`
fn lwz(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, word, Unsigned)
}

///|
/// `7d 3d 50 ae  lbzx r9,r29,r10`
fn lbzx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, byte, Unsigned)
}

///|
/// `7d 3d 52 2e  lhzx r9,r29,r10`
fn lhzx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, halfword, Unsigned)
}

///|
/// `7d 3d 50 2e  lwzx r9,r29,r10`
fn lwzx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, word, Unsigned)
}

///|
/// `8d 3c 00 14  lbzu r9,20(r28)`
fn lbzu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_du(cpu, ops, byte, Unsigned)
}

///|
/// `a5 3c 00 14  lhzu r9,20(r28)`
fn lhzu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_du(cpu, ops, halfword, Unsigned)
}

///|
/// `85 3f ff fc  lwzu r9,-4(r31)`
fn lwzu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_du(cpu, ops, word, Unsigned)
}

///|
/// `7d 3d 50 ee  lbzux r9,r29,r10`
fn lbzux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, byte, Unsigned)
}

///|
/// `7d 3d 52 6e  lhzux r9,r29,r10`
fn lhzux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, halfword, Unsigned)
}

///|
/// `7d 3d 50 6e  lwzux r9,r29,r10`
fn lwzux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, word, Unsigned)
}

///|
/// Load Halfword Algebraic. `a8 29 00 05  lha r1,5(r9)`
fn lha(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, halfword, Signed)
}

///|
/// Load Word Algebraic. `eb eb 01 16  lwa r31,276(r11)`
fn lwa(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, word, Signed)
}

///|
/// `7c 25 4a ae  lhax r1,r5,r9`
fn lhax(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, halfword, Signed)
}

///|
/// `7c 25 4a aa  lwax r1,r5,r9`
fn lwax(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, word, Signed)
}

///|
/// Load Halfword Algebraic with Update. `ac 29 00 05  lhau r1,5(r9)`
///
/// As upstream, the base register is read from operand 1 (the written-back
/// copy of `ra`) and the displacement from operand 2.
fn lhau(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let im = ops.disp(2)
  [rt.set(cpu.load(ra + im, halfword)), ra.set(ra + im)]
}

///|
/// `7c 25 4a ee  lhaux r1,r5,r9`
fn lhaux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, halfword, Signed)
}

///|
/// `7c 25 4a ea  lwaux r1,r5,r9`
fn lwaux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, word, Signed)
}

///|
/// Load Doubleword. `e8 29 00 08  ld r1,8(r9)`
fn ld(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_d(cpu, ops, doubleword, Unsigned)
}

///|
/// `7c 28 48 2a  ldx r1,r8,r9`
fn ldx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_x(cpu, ops, doubleword, Unsigned)
}

///|
/// Load Doubleword with Update. `e8 29 00 09  ldu r1,8(r9)`
///
/// As upstream, the base is read from operand 1. Upstream reads the DS
/// displacement as unsigned, which turns negative displacements into large
/// offsets in 64-bit mode; it is sign-extended here (as in `ld`).
fn ldu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let im = ops.disp(2)
  [rt.set(cpu.load(ra + im, doubleword)), ra.set(ra + im)]
}

///|
/// `7c 28 48 6a  ldux r1,r8,r9`
fn ldux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  load_xu(cpu, ops, doubleword, Unsigned)
}

///|
/// Load Halfword Byte-Reverse Indexed (pages 60-61).
/// `7c 22 1e 2c  lhbrx r1,r2,r3`
fn lhbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let x = uvar(halfword)
  [
    x.set(cpu.load(ra + rb, halfword)),
    rt.set(x.nth(byte, 1).concat(x.nth(byte, 0))),
  ]
}

///|
/// `nth byte x (count-1) ^ ... ^ nth byte x 0`: the first `count` bytes of
/// `x` in reverse order (concatenation associates to the right, as in
/// upstream).
fn reverse_bytes(x : RtlExp, count : Int) -> RtlExp {
  let mut acc = x.nth(byte, 0)
  for i in 1..<count {
    acc = x.nth(byte, i).concat(acc)
  }
  acc
}

///|
/// Load Word Byte-Reverse Indexed. `7c 22 1c 2c  lwbrx r1,r2,r3`
fn lwbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let x = uvar(word)
  [x.set(cpu.load(ra + rb, word)), rt.set(reverse_bytes(x, 4))]
}

///|
/// Load Doubleword Byte-Reverse Indexed. `7c 22 1c 28  ldbrx r1,r2,r3`
fn ldbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let x = uvar(doubleword)
  [x.set(cpu.load(ra + rb, doubleword)), rt.set(reverse_bytes(x, 8))]
}

///|
fn init_load() -> Unit {
  register_insn("LBZ", lbz)
  register_insn("LHZ", lhz)
  register_insn("LWZ", lwz)
  register_insn("LBZX", lbzx)
  register_insn("LHZX", lhzx)
  register_insn("LWZX", lwzx)
  register_insn("LBZU", lbzu)
  register_insn("LHZU", lhzu)
  register_insn("LWZU", lwzu)
  register_insn("LBZUX", lbzux)
  register_insn("LHZUX", lhzux)
  register_insn("LWZUX", lwzux)
  register_insn("LHA", lha)
  register_insn("LWA", lwa)
  register_insn("LHAX", lhax)
  register_insn("LWAX", lwax)
  register_insn("LHAU", lhau)
  register_insn("LHAUX", lhaux)
  register_insn("LWAUX", lwaux)
  register_insn("LD", ld)
  register_insn("LDX", ldx)
  register_insn("LDU", ldu)
  register_insn("LDUX", ldux)
  register_insn("LHBRX", lhbrx)
  register_insn("LWBRX", lwbrx)
  register_insn("LDBRX", ldbrx)
}
