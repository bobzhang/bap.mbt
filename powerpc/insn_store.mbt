// Port of BAP `plugins/powerpc/powerpc_store.ml` (pages 54-61 of IBM Power
// ISA 3.0 B).
//
// Operand layouts produced by LLVM:
//   D-form      `stw rs, d(ra)`    -> [rs, d, ra]
//   D-form, u   `stwu rs, d(ra)`   -> [ra(wb), rs, d, ra]
//   X-form      `stwx rs, ra, rb`  -> [rs, ra, rb]
//   X-form, u   `stwux rs, ra, rb` -> [ra(wb), rs, ra, rb]

///|
fn store_d(
  cpu : Cpu,
  ops : Operands,
  width : Int32,
) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  let im = ops.disp(1)
  let ra = cpu.sreg(ops, 2)
  [cpu.store(ra + im, rs, width)]
}

///|
fn store_x(
  cpu : Cpu,
  ops : Operands,
  width : Int32,
) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  [cpu.store(ra + rb, rs, width)]
}

///|
fn store_du(
  cpu : Cpu,
  ops : Operands,
  width : Int32,
) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 1)
  let im = ops.disp(2)
  let ra = cpu.sreg(ops, 3)
  [cpu.store(ra + im, rs, width), ra.set(ra + im)]
}

///|
fn store_xu(
  cpu : Cpu,
  ops : Operands,
  width : Int32,
) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 1)
  let ra = cpu.sreg(ops, 2)
  let rb = cpu.sreg(ops, 3)
  [cpu.store(ra + rb, rs, width), ra.set(ra + rb)]
}

///|
/// `99 3c 01 6c  stb r9,364(r28)`
fn stb(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_d(cpu, ops, byte)
}

///|
/// `b1 3c 01 6c  sth r9,364(r28)`
fn sth(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_d(cpu, ops, halfword)
}

///|
/// `91 28 ff d4  stw r9,-44(r8)`
fn stw(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_d(cpu, ops, word)
}

///|
/// `7d 2e f9 ae  stbx r9,r14,r31`
fn stbx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_x(cpu, ops, byte)
}

///|
/// `7d 3e eb 2e  sthx r9,r30,r29`
fn sthx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_x(cpu, ops, halfword)
}

///|
/// `7f b6 f9 2e  stwx r29,r22,r31`
fn stwx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_x(cpu, ops, word)
}

///|
/// `7c 28 49 2a  stdx r1,r8,r9`
fn stdx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_x(cpu, ops, doubleword)
}

///|
/// `9c 9d ff ff  stbu r4,-1(r29)`
fn stbu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_du(cpu, ops, byte)
}

///|
/// `b5 3d ff ff  sthu r9,-1(r29)`
fn sthu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_du(cpu, ops, halfword)
}

///|
/// `94 21 ff f0  stwu r1,-16(r1)`
fn stwu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_du(cpu, ops, word)
}

///|
/// `7d 3f c9 ee  stbux r9,r31,r25`
fn stbux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_xu(cpu, ops, byte)
}

///|
/// `7d 3f cb 6e  sthux r9,r31,r25`
fn sthux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_xu(cpu, ops, halfword)
}

///|
/// `7d 41 49 6e  stwux r10,r1,r9`
fn stwux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_xu(cpu, ops, word)
}

///|
/// `7c 28 49 6a  stdux r1,r8,r9`
fn stdux(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_xu(cpu, ops, doubleword)
}

///|
/// Store Doubleword (page 57). `f8 29 00 08  std r1,8(r9)`
fn std(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  store_d(cpu, ops, doubleword)
}

///|
/// Store Doubleword with Update (page 57). `f8 29 00 09  stdu r1,8(r9)`
fn stdu(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 1)
  let im = ops.disp(2)
  let ra = cpu.sreg(ops, 3)
  let ea = uvar(doubleword)
  [ea.set(ra + im), cpu.store(ea, rs, doubleword), ra.set(ea)]
}

///|
/// Store Halfword Byte-Reverse Indexed (pages 60-61).
/// `7c 22 1f 2c  sthbrx r1,r2,r3`
fn sthbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let ea = uvar(cpu.word_width)
  let x = uvar(halfword)
  let y = uvar(doubleword)
  [
    ea.set(ra + rb),
    y.set(rs),
    x.set(y.nth(byte, 7).concat(y.nth(byte, 6))),
    cpu.store(ea, x, halfword),
  ]
}

///|
/// Store Word Byte-Reverse Indexed. `7c 22 1d 2c  stwbrx r1,r2,r3`
fn stwbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let ea = uvar(cpu.word_width)
  let x = uvar(word)
  let y = uvar(doubleword)
  [
    ea.set(ra + rb),
    y.set(rs),
    x.set(
      y
      .nth(byte, 7)
      .concat(y.nth(byte, 6).concat(y.nth(byte, 5).concat(y.nth(byte, 4)))),
    ),
    cpu.store(ea, x, word),
  ]
}

///|
/// Store Doubleword Byte-Reverse Indexed. `7c 22 1d 28  stdbrx r1,r2,r3`
fn stdbrx(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(ops, 0)
  let ra = cpu.sreg(ops, 1)
  let rb = cpu.sreg(ops, 2)
  let ea = uvar(doubleword)
  let x = uvar(doubleword)
  [ea.set(ra + rb), x.set(reverse_bytes(rs, 8)), cpu.store(ea, x, doubleword)]
}

///|
fn init_store() -> Unit {
  register_insn("STB", stb)
  register_insn("STH", sth)
  register_insn("STW", stw)
  register_insn("STBX", stbx)
  register_insn("STHX", sthx)
  register_insn("STWX", stwx)
  register_insn("STDX", stdx)
  register_insn("STBU", stbu)
  register_insn("STHU", sthu)
  register_insn("STWU", stwu)
  register_insn("STBUX", stbux)
  register_insn("STHUX", sthux)
  register_insn("STWUX", stwux)
  register_insn("STDUX", stdux)
  register_insn("STD", std)
  register_insn("STDU", stdu)
  register_insn("STHBRX", sthbrx)
  register_insn("STWBRX", stwbrx)
  register_insn("STDBRX", stdbrx)
}
