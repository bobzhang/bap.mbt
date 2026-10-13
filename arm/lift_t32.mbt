// Thumb-2 operand layouts of the opcodes the ARM lifter shares with A32.
//
// port: upstream lifts `t2*` opcodes with the A32 operand patterns (after
// dropping the `t2` prefix), which do not match LLVM's Thumb-2 layouts
// for the pre/post-indexed halfword, signed and dual accesses and the
// exclusive word accesses (lifting fails), and read the predicate
// register of the Thumb-2 multiplies (`CPSR` in IT blocks) as their
// flag-setting operand.

///|
/// A Thumb-2 8-bit immediate offset: LLVM encodes `#-0` as `INT32_MIN`.
fn t2_offset(x : UInt32) -> @types.Exp {
  int32(if x == 0x80000000 { 0 } else { x })
}

///|
/// The operands of a Thumb-2 multiply in the A32 layout: Thumb-2
/// multiplies never set the flags, so a `Nil` flag operand is appended to
/// the forms that lack one.
fn t32_mult_ops(ops : ArrayView[Op], insn : MultInsn) -> ArrayView[Op] {
  let short = match insn {
    MUL => 5
    MLA | SMULL | UMULL => 6
    SMLAL | UMLAL => 8
    _ => -1
  }
  if ops.length() == short {
    [..ops, Reg(Nil)][:]
  } else {
    ops
  }
}

///|
/// Thumb-2 loads and stores whose layouts differ from A32 ones; the others
/// use the A32 patterns.
fn lift_mem_t32(
  ops : ArrayView[Op],
  insn : MemInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let single = (
    dest1 : Op,
    base : Op,
    off : UInt32,
    cond : Op,
    mode : ModeR,
    sign : Sign,
    size : MemSize,
    operation : Operation,
  ) => {
    exec(
      lift_r_exp(
        dest1~,
        base~,
        offset=t2_offset(off),
        mode,
        sign,
        size,
        operation,
      ),
      cond,
    )
  }
  let dual = (
    dest1 : Op,
    dest2 : Op,
    base : Op,
    off : UInt32,
    cond : Op,
    mode : ModeR,
    operation : Operation,
  ) => {
    exec(
      lift_r_exp(
        dest1~,
        dest2~,
        base~,
        offset=t2_offset(off),
        mode,
        Unsigned,
        D,
        operation,
      ),
      cond,
    )
  }
  match (insn, ops) {
    (LDRH_PRE, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PreIndex, Unsigned, H, Ld)
    (LDRH_POST, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PostIndex, Unsigned, H, Ld)
    (LDRSH_PRE, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PreIndex, Signed, H, Ld)
    (LDRSH_POST, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PostIndex, Signed, H, Ld)
    (LDRSB_PRE, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PreIndex, Signed, B, Ld)
    (LDRSB_POST, [d, _, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PostIndex, Signed, B, Ld)
    (STRH_PRE, [_, d, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PreIndex, Unsigned, H, St)
    (STRH_POST, [_, d, base, Imm(off), cond, _]) =>
      single(d, base, off, cond, PostIndex, Unsigned, H, St)
    (LDRD_PRE, [d1, d2, _, base, Imm(off), cond, _]) =>
      dual(d1, d2, base, off, cond, PreIndex, Ld)
    (LDRD_POST, [d1, d2, _, base, Imm(off), cond, _]) =>
      dual(d1, d2, base, off, cond, PostIndex, Ld)
    (STRD_PRE, [_, d1, d2, base, Imm(off), cond, _]) =>
      dual(d1, d2, base, off, cond, PreIndex, St)
    (STRD_POST, [_, d1, d2, base, Imm(off), cond, _]) =>
      dual(d1, d2, base, off, cond, PostIndex, St)
    // the word exclusives have an (unscaled) immediate offset
    (LDREX, [d, base, Imm(off), cond, _]) =>
      single(d, base, off * 4, cond, Offset, Unsigned, W, Ld)
    (STREX, [Reg(status), d, base, Imm(off), cond, _]) =>
      exec(
        [
          ..lift_r_exp(
            dest1=d,
            base~,
            offset=t2_offset(off * 4),
            Offset,
            Unsigned,
            W,
            St,
          ),
          assign(status.to_var(), int32(0)),
        ],
        cond,
      )
    // `t2LDRBs`/`t2STRBs`: the offset register is shifted left by a plain
    // amount rather than by an addressing mode 2 shift operand
    (LDRBrs | STRBrs, [d, base, off, Imm(amount), cond, preg]) =>
      lift_mem([d, base, off, Imm((2U << 13) | amount), cond, preg], insn)
    _ => lift_mem(ops, insn)
  }
}
