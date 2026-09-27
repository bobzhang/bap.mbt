// Port of `Arm_lifter.lift_move`.

///|
fn string_of_ops(ops : ArrayView[Op]) -> String {
  "(" + ops.iter().map(op => op.to_string()).join(" ") + ")"
}

///|
fn lift_move(
  encoding : Encoding,
  ops : ArrayView[Op],
  insn : MoveInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let cpsr_flag = Op::Reg(CPSR)
  // data-processing with a destination register and an `S` flag operand
  let dp = (
    itype : DataOper,
    dest : Op,
    src1 : Op,
    src2 : Op?,
    sreg : Op?,
    simm : Op?,
    cond : Op,
    wflag : Op,
  ) => {
    mov_lift(encoding~, dest~, src1, src2?, itype, sreg?, simm?, wflag~, cond)
  }
  // comparisons and tests: no destination, always set the flags
  let cmp = (
    itype : DataOper,
    src1 : Op,
    src2 : Op,
    sreg : Op?,
    simm : Op?,
    cond : Op,
  ) => {
    mov_lift(encoding~, src1, src2~, itype, sreg?, simm?, wflag=cpsr_flag, cond)
  }
  let is_rsr = insn.name().has_suffix("rsr")
  let is_rsi = insn.name().has_suffix("rsi")
  match (insn, ops) {
    (MOVi | MOVr, [dest, src, cond, _, wflag]) =>
      dp(MOV, dest, src, None, None, None, cond, wflag)
    (MOVsr, [dest, src, sreg, simm, cond, _, wflag]) =>
      dp(MOV, dest, src, None, Some(sreg), Some(simm), cond, wflag)
    (MOVsi, [dest, src, shift_imm, cond, _, wflag]) =>
      dp(MOV, dest, src, None, None, Some(shift_imm), cond, wflag)
    (MOVPCLR, [cond, wflag]) =>
      dp(MOV, Reg(PC), Reg(LR), None, None, None, cond, wflag)
    (MVNi | MVNr, [dest, src, cond, _, wflag]) =>
      dp(MVN, dest, src, None, None, None, cond, wflag)
    (MVNsr, [dest, src, shift_reg, shift_imm, cond, _, wflag]) =>
      dp(MVN, dest, src, None, Some(shift_reg), Some(shift_imm), cond, wflag)
    (MVNsi, [dest, src, shift_imm, cond, _, wflag]) =>
      dp(MVN, dest, src, None, None, Some(shift_imm), cond, wflag)
    // three-operand data processing
    (_, [dest, src1, src2, shift_reg, shift_imm, cond, _, wflag]) if is_rsr &&
      three_operand(insn) is Some(itype) =>
      dp(
        itype,
        dest,
        src1,
        Some(src2),
        Some(shift_reg),
        Some(shift_imm),
        cond,
        wflag,
      )
    (_, [dest, src1, src2, shift_imm, cond, _, wflag]) if is_rsi &&
      three_operand(insn) is Some(itype) =>
      dp(itype, dest, src1, Some(src2), None, Some(shift_imm), cond, wflag)
    (_, [dest, src1, src2, cond, _, wflag]) if !is_rsr &&
      !is_rsi &&
      three_operand(insn) is Some(itype) =>
      dp(itype, dest, src1, Some(src2), None, None, cond, wflag)
    // tests and comparisons
    (TEQri | TEQrr, [src1, src2, cond, _]) =>
      cmp(EOR, src1, src2, None, None, cond)
    (TEQrsr, [src1, src2, shift_reg, shift_imm, cond, _]) =>
      cmp(EOR, src1, src2, Some(shift_reg), Some(shift_imm), cond)
    // LLVM's form (upstream only matches the six-operand one below)
    (TEQrsi, [src1, src2, shift_imm, cond, _]) =>
      cmp(EOR, src1, src2, None, Some(shift_imm), cond)
    (TEQrsi, [_dest, src1, src2, shift_imm, cond, _]) =>
      cmp(EOR, src1, src2, None, Some(shift_imm), cond)
    (TSTri | TSTrr, [src1, src2, cond, _]) =>
      cmp(AND, src1, src2, None, None, cond)
    (TSTrsr, [src1, src2, shift_reg, shift_imm, cond, _]) =>
      cmp(AND, src1, src2, Some(shift_reg), Some(shift_imm), cond)
    (TSTrsi, [src1, src2, shift_imm, cond, _]) =>
      cmp(AND, src1, src2, None, Some(shift_imm), cond)
    (CMPri | CMPrr, [src1, src2, cond, _]) =>
      cmp(SUB, src1, src2, None, None, cond)
    (CMPrsr, [src1, src2, shift_reg, shift_imm, cond, _]) =>
      cmp(SUB, src1, src2, Some(shift_reg), Some(shift_imm), cond)
    (CMPrsi, [src1, src2, shift_imm, cond, _]) =>
      cmp(SUB, src1, src2, None, Some(shift_imm), cond)
    (CMNri | CMNzrr, [src1, src2, cond, _]) =>
      cmp(ADD, src1, src2, None, None, cond)
    (CMNzrsr, [src1, src2, shift_reg, shift_imm, cond, _]) =>
      cmp(ADD, src1, src2, Some(shift_reg), Some(shift_imm), cond)
    (CMNzrsi, [src1, src2, shift_imm, cond, _]) =>
      cmp(ADD, src1, src2, None, Some(shift_imm), cond)
    // special data instructions
    (MOVi16, [Reg(dest), src, cond, _wflag]) =>
      exec([assign(dest.to_var(), exp_of_op(src))], cond)
    (MOVTi16, [Reg(dest), _, src, cond, _wflag]) => {
      let d = dest.to_var()
      let value = bin(
        Or,
        bin(And, v(d), int32(0xFFFF)),
        bin(LShift, exp_of_op(src), int32(16)),
      )
      exec([assign(d, value)], cond)
    }
    _ =>
      fail("ops \{string_of_ops(ops)} doesn't match move insn \{insn.name()}")
  }
}

///|
/// The data operation of a three-operand data-processing instruction.
fn three_operand(insn : MoveInsn) -> DataOper? {
  match insn {
    ANDri | ANDrr | ANDrsr | ANDrsi => Some(AND)
    BICri | BICrr | BICrsr | BICrsi => Some(BIC)
    EORri | EORrr | EORrsr | EORrsi => Some(EOR)
    ORRri | ORRrr | ORRrsr | ORRrsi => Some(ORR)
    ADDri | ADDrr | ADDrsr | ADDrsi => Some(ADD)
    SUBri | SUBrr | SUBrsr | SUBrsi => Some(SUB)
    ADCri | ADCrr | ADCrsr | ADCrsi => Some(ADC)
    SBCri | SBCrr | SBCrsr | SBCrsi => Some(SBC)
    RSBri | RSBrr | RSBrsr | RSBrsi => Some(RSB)
    RSCri | RSCrr | RSCrsr | RSCrsi => Some(RSC)
    _ => None
  }
}
