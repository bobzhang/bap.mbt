// Port of BAP `plugins/powerpc/powerpc_branch.ml`.

///|
fn update_link_register(
  cpu : Cpu,
  _ops : Operands,
) -> Array[Rtl] {
  [cpu.lr.set(cpu.pc + uconst(byte, 4))]
}

///|
/// Branch (page 37 of IBM Power ISA 3.0 B).
/// `4b ff fe f0  b .+67108592`
fn b(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let im = ops.simm(0)
  let tm = svar(cpu.word_width)
  let sh = uconst(byte, 2)
  [tm.set(im.shl(sh).last(26)), cpu.jmp(cpu.pc + tm)]
}

///|
/// Branch Absolute.
/// `4b ff fe f2  ba 67108592`
fn ba(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let im = ops.simm(0)
  let tm = svar(cpu.word_width)
  let sh = uconst(byte, 2)
  [tm.set(im.shl(sh).last(26)), cpu.jmp(tm)]
}

///|
/// Decode the BO field: decrement CTR when BO_2 is clear and compute the
/// CTR and condition predicates.
fn branch_conditions(
  cpu : Cpu,
  bo : RtlExp,
  bi : RtlExp,
  ctr_ok : RtlExp,
  cond_ok : RtlExp,
) -> Array[Rtl] {
  let x = uvar(5)
  [
    x.set(bo.last(5)),
    when_(x.nth(bit, 2).eq(zero), [cpu.ctr.set(cpu.ctr - one)]),
    ctr_ok.set(x.nth(bit, 2) | (cpu.ctr.neq(zero) ^ x.nth(bit, 3))),
    cond_ok.set(x.nth(bit, 0) | (bi ^ x.nth(bit, 1).lnot())),
  ]
}

///|
/// Branch Conditional (page 37).
/// `42 9f 00 04  bc 20,31,.+4`
fn bc(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let bd = ops.simm(2)
  let sh = uconst(byte, 2)
  let ctr_ok = uvar(bit)
  let cond_ok = uvar(bit)
  let tm = svar(cpu.word_width)
  [
    ..branch_conditions(cpu, bo, bi, ctr_ok, cond_ok),
    when_(ctr_ok & cond_ok, [
      tm.set(bd.shl(sh).last(16)),
      cpu.jmp(cpu.pc + tm),
    ]),
  ]
}

///|
/// Branch Conditional Absolute.
/// `42 9f 00 06  bca 20,31,4`
fn bca(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let bd = ops.simm(2)
  let sh = uconst(byte, 2)
  let ctr_ok = uvar(bit)
  let cond_ok = uvar(bit)
  let tm = svar(cpu.word_width)
  [
    ..branch_conditions(cpu, bo, bi, ctr_ok, cond_ok),
    when_(ctr_ok & cond_ok, [tm.set(bd.shl(sh).last(16)), cpu.jmp(tm)]),
  ]
}

///|
/// `bdz target` = `bc 18,0,target`
fn bdz(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bd = ops.uimm(0)
  let sh = uconst(byte, 2)
  let tm = svar(cpu.word_width)
  [
    cpu.ctr.set(cpu.ctr - one),
    when_(cpu.ctr.low(cpu.word_width).eq(zero), [
      tm.set(bd.shl(sh)),
      cpu.jmp(cpu.pc + tm),
    ]),
  ]
}

///|
/// `bdnz target` = `bc 16,0,target`
fn bdnz(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bd = ops.uimm(0)
  let sh = uconst(byte, 2)
  let tm = svar(cpu.word_width)
  [
    cpu.ctr.set(cpu.ctr - one),
    when_(cpu.ctr.low(cpu.word_width).neq(zero), [
      tm.set(bd.shl(sh)),
      cpu.jmp(cpu.pc + tm),
    ]),
  ]
}

///|
/// `reg` with the two low-order bits cleared.
fn word_aligned(cpu : Cpu, reg : RtlExp) -> RtlExp {
  reg & ones(cpu.word_width).shl(uconst(byte, 2))
}

///|
/// Branch Conditional to Link Register (page 38).
/// `4e 9f 00 20  bclr 20,31`
fn bclr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let ctr_ok = uvar(bit)
  let cond_ok = uvar(bit)
  [
    ..branch_conditions(cpu, bo, bi, ctr_ok, cond_ok),
    when_(ctr_ok & cond_ok, [cpu.jmp(word_aligned(cpu, cpu.lr))]),
  ]
}

///|
/// Branch Conditional to Link Register and Link.
/// `4e 9f 00 21  bclrl 20,31`
fn bclrl(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let ctr_ok = uvar(bit)
  let cond_ok = uvar(bit)
  let tm = uvar(cpu.word_width)
  let step = uconst(byte, 4)
  [
    ..branch_conditions(cpu, bo, bi, ctr_ok, cond_ok),
    tm.set(word_aligned(cpu, cpu.lr)),
    cpu.lr.set(cpu.pc + step),
    when_(ctr_ok & cond_ok, [cpu.jmp(tm)]),
  ]
}

///|
/// Branch to LR unconditionally (page 792).
/// `4e 80 00 20  blr`
fn blr(cpu : Cpu, _ops : Operands) -> Array[Rtl] {
  [cpu.jmp(word_aligned(cpu, cpu.lr))]
}

///|
/// `4e 80 00 21  blrl`
fn blrl(cpu : Cpu, _ops : Operands) -> Array[Rtl] {
  let tm = uvar(cpu.word_width)
  let step = uconst(byte, 4)
  [
    tm.set(word_aligned(cpu, cpu.lr)),
    cpu.lr.set(cpu.pc + step),
    cpu.jmp(tm),
  ]
}

///|
/// `bdnzlr` = `bclr 16,0,0`
fn bdnzlr(cpu : Cpu, _ops : Operands) -> Array[Rtl] {
  [
    cpu.ctr.set(cpu.ctr - one),
    when_(cpu.ctr.neq(zero), [cpu.jmp(word_aligned(cpu, cpu.lr))]),
  ]
}

///|
/// Branch Conditional to Count Register (page 38).
/// `4d 5f 04 20  bcctr 10,31`
fn bcctr(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let cond_ok = uvar(bit)
  let x = uvar(5)
  [
    x.set(bo.last(5)),
    cond_ok.set(x.nth(bit, 0).eq(one) | (bi ^ x.nth(bit, 1).lnot())),
    when_(cond_ok, [cpu.jmp(word_aligned(cpu, cpu.ctr))]),
  ]
}

///|
/// Branch to CTR unconditionally (page 792).
/// `4e 80 04 20  bctr`
fn bctr(cpu : Cpu, _ops : Operands) -> Array[Rtl] {
  [cpu.jmp(word_aligned(cpu, cpu.ctr))]
}

///|
/// Branch Conditional to Target Register (page 39).
/// `4e 9f 04 60  bctar`
fn bctar(cpu : Cpu, ops : Operands) -> Array[Rtl] raise @mc.LiftError {
  let bo = ops.uimm(0)
  let bi = cpu.ureg(ops, 1)
  let cond_ok = uvar(bit)
  let ctr_ok = uvar(bit)
  [
    ..branch_conditions(cpu, bo, bi, ctr_ok, cond_ok),
    when_(ctr_ok & cond_ok, [cpu.jmp(word_aligned(cpu, cpu.tar))]),
  ]
}

///|
fn init_branch() -> Unit {
  let bl = concat(infallible(update_link_register), b)
  let bla = concat(infallible(update_link_register), ba)
  let bcl = concat(infallible(update_link_register), bc)
  let bcla = concat(infallible(update_link_register), bca)
  let bcctrl = concat(infallible(update_link_register), bcctr)
  let bctrl = concat(infallible(update_link_register), infallible(bctr))
  let bctarl = concat(infallible(update_link_register), bctar)
  register_insn("B", b)
  register_insn("BA", ba)
  register_insn("BL", bl)
  register_insn("BLA", bla)
  register_insn("gBC", bc)
  register_insn("gBCA", bca)
  register_insn("gBCL", bcl)
  register_insn("gBCLA", bcla)
  register_insn("BDZ", bdz)
  register_insn("BDNZ", bdnz)
  register_insn("BCC", bc)
  register_insn("BCCL", bcl)
  register_insn("BCCLA", bcla)
  register_insn("gBCLR", bclr)
  register_insn("gBCLRL", bclrl)
  register_insn("gBCCTR", bcctr)
  register_insn("gBCCTRL", bcctrl)
  register_insn("BDNZLR", infallible(bdnzlr))
  register_insn("gBCTAR", bctar)
  register_insn("gBCTARL", bctarl)
  register_insn("BLR", infallible(blr))
  register_insn("BLRL", infallible(blrl))
  register_insn("BCTR", infallible(bctr))
  register_insn("BCTRL", bctrl)
  register_insn("BCCLR", bclr)
  register_insn("BCCLRL", bclrl)
  register_insn("BCCCTR", bcctr)
  register_insn("BCCCTRL", bcctrl)
}
