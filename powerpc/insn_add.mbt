// Port of BAP `plugins/powerpc/powerpc_add.ml`.
//
// LLVM does not recognize the OE=1 forms (`addo`, `addco`, ...); the record
// forms of the OE=0 instructions are named with an `o` suffix (`ADD4o`,
// `ADDCo`, ...) or, in newer LLVM, a `_rec` suffix.
//
// Extended mnemonics:
//   lis rx, value      = addis  rx, 0,  value
//   li  rx, value      = addi   rx, 0,  value
//   la  rx, disp(ry)   = addi   rx, ry, disp
//   subis rx,ry,value  = addis  rx, ry, -value
//   subic rx,ry,value  = addic  rx, ry, -value
//   subic. rx,ry,value = addic. rx, ry, -value

///|
/// Add Immediate (page 67 of IBM Power ISA 3.0 B).
/// `38 21 00 10  addi r1,r1,16`
fn addi(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let im = ops.simm(2)
  [rt.set(ra + im)]
}

///|
/// Load Immediate (`addi rt, 0, si`, decoded as `LI` by LLVM). Upstream
/// assigns the immediate to an unsigned register, which zero-extends
/// negative values in 64-bit mode; since LLVM decodes every `addi rt, 0, si`
/// as `LI`, the value is sign-extended here, as `addi` does.
fn li(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let im = ops.simm(1)
  [rt.set(im)]
}

///|
/// Add Immediate Shifted (page 67).
/// `3f de 00 02  addis r30,r30,2`
fn addis(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let im = ops.simm(2)
  let sh = uconst(word, 16)
  [rt.set(ra + im.shl(sh))]
}

///|
/// Load Immediate Shifted (`addis rt, 0, si`, decoded as `LIS` by LLVM):
/// sign-extended in 64-bit mode as `addis` (see `li`).
fn lis(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(ops, 0)
  let im = ops.simm(1)
  let sh = uconst(word, 16)
  [rt.set(im.shl(sh))]
}

///|
/// Add (page 69).
/// `7d 62 5a 14  add r11,r2,r11`
fn add(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  [rt.set(ra + rb)]
}

///|
/// `x` as a `width + 1`-bit unsigned value: the low `width` bits of a
/// wider register, or a narrower operand extended by its sign.
fn widen(x : RtlExp, width : Int) -> RtlExp {
  let x = if x.width() > width { x.low(width) } else { x.cast(width, x.sign()) }
  x.unsigned().cast(width + 1, Unsigned)
}

///|
/// The carry out of the `width`-bit sum `a + b + c`.
fn carry_out(width : Int, a : RtlExp, b : RtlExp, c : RtlExp) -> RtlExp {
  (widen(a, width) + widen(b, width) + widen(c, width)).msb()
}

///|
/// `rt := a + b + c`, setting `CA`/`CA32` to the carries out of the
/// doubleword (or word, on 32-bit targets) and of the low word.
///
/// port: upstream compares the result with the first operand, which is
/// wrong when `b + c` wraps (`adde`/`addme`/`subfe`/`subfme` with a carry
/// in), and sets the carry of `subfze`/`subfme` unconditionally.
fn add_carrying(
  cpu : Cpu,
  rt : RtlExp,
  a : RtlExp,
  b : RtlExp,
  c : RtlExp,
) -> Array[Rtl] {
  let ca = uvar(bit)
  let ca32 = uvar(bit)
  [
    ca.set(carry_out(cpu.word_width, a, b, c)),
    ca32.set(carry_out(word, a, b, c)),
    rt.set(a + b + c),
    cpu.ca.set(ca),
    cpu.ca32.set(ca32),
  ]
}

///|
/// Add Immediate Carrying (page 69).
/// `30 21 00 10  addic r1,r1,16`
fn addic(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let im = ops.simm(2)
  add_carrying(cpu, rt, ra, im, zero)
}

///|
/// Add Carrying (page 70).
/// `7d 62 58 14  addc r11,r2,r11`
fn addc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  add_carrying(cpu, rt, ra, rb, zero)
}

///|
/// Add Extended (page 71).
/// `7c 21 81 14  adde r1,r1,r16`
fn adde(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  let rb = cpu.ureg(ops, 2)
  add_carrying(cpu, rt, ra, rb, cpu.ca)
}

///|
/// Add to Minus One Extended (page 71).
/// `7c 22 01 d4  addme r1,r2`
fn addme(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  add_carrying(cpu, rt, ra, ones(cpu.word_width), cpu.ca)
}

///|
/// Add to Zero Extended (page 72).
/// `7c 22 01 94  addze r1,r2`
fn addze(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(ops, 0)
  let ra = cpu.ureg(ops, 1)
  add_carrying(cpu, rt, ra, zero, cpu.ca)
}

///|
fn init_add() -> Unit {
  register_insn("ADD4", add)
  register_dot_insn("ADD4o", add)
  register_insn("ADDI", addi)
  register_insn("ADDIS", addis)
  register_insn("ADDIC", addic)
  register_dot_insn("ADDICo", addic)
  register_insn("ADDC", addc)
  register_dot_insn("ADDCo", addc)
  register_insn("ADDE", adde)
  register_dot_insn("ADDEo", adde)
  register_insn("ADDME", addme)
  register_dot_insn("ADDMEo", addme)
  register_insn("ADDZE", addze)
  register_dot_insn("ADDZEo", addze)
  register_insn("LI", li)
  register_insn("LIS", lis)
  register_insn("LA", addi)
}
