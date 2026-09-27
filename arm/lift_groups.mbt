// Ports of `Arm_lifter.lift_bits`, `lift_mult`, `lift_mem_multi`,
// `lift_mem`, `lift_branch` and `lift_special`.

///|
/// `lsb_width` computes the `(lsb, width)` of a `BFI`/`BFC` bit field from
/// its inverted-mask operand when the raw instruction word is unknown.
fn lift_bits(
  raw : UInt?,
  ops : ArrayView[Op],
  insn : BitsInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let lsb_width = (bmask : Op) => {
    match raw {
      Some(raw) => Some(get_lsb_width(raw))
      None =>
        match bmask {
          Imm(mask) => Some(lsb_width_of_inv_mask(mask))
          Reg(_) => None
        }
    }
  }
  match (insn, ops) {
    // extends
    (UXTB, [dest, src, rot, cond, _]) =>
      bit_extend(dest~, src~, Unsigned, B, rot~, cond)
    (UXTH, [dest, src, rot, cond, _]) =>
      bit_extend(dest~, src~, Unsigned, H, rot~, cond)
    (SXTB, [dest, src, rot, cond, _]) =>
      bit_extend(dest~, src~, Signed, B, rot~, cond)
    (SXTH, [dest, src, rot, cond, _]) =>
      bit_extend(dest~, src~, Signed, H, rot~, cond)
    (UXTAB, [dest, src, shift, rot, cond, _]) =>
      bit_extend(dest~, src=shift, src2=src, Unsigned, B, rot~, cond)
    (UXTAH, [dest, src, shift, rot, cond, _]) =>
      bit_extend(dest~, src=shift, src2=src, Unsigned, H, rot~, cond)
    (SXTAB, [dest, src, shift, rot, cond, _]) =>
      bit_extend(dest~, src=shift, src2=src, Signed, B, rot~, cond)
    (SXTAH, [dest, src, shift, rot, cond, _]) =>
      bit_extend(dest~, src=shift, src2=src, Signed, H, rot~, cond)
    // extracts
    (UBFX, [dest, src, lsb, widthminus1, cond, _]) =>
      bit_extract(dest~, src~, Unsigned, lsb~, widthminus1~, cond)
    (SBFX, [dest, src, lsb, widthminus1, cond, _]) =>
      bit_extract(dest~, src~, Signed, lsb~, widthminus1~, cond)
    // bit field
    (BFI, [dest, _unknown, src, bmask, cond, _]) if lsb_width(bmask) is Some(lw) =>
      bit_field_insert(dest~, src~, lw, cond)
    (BFC, [dest, _unknown, bmask, cond, _]) if lsb_width(bmask) is Some(lw) =>
      bit_field_insert(dest~, src=Imm(0), lw, cond)
    // bit reverse
    (RBIT, [dest, src, cond, _]) => {
      let dest = assert_reg(dest)
      let vv = tmp(@types.ValueType::reg32_t(), name="v")
      let r = tmp(@types.ValueType::reg32_t(), name="r")
      let s = tmp(@types.ValueType::reg32_t(), name="s")
      exec(
        [
          assign(vv, bin(RShift, exp_of_op(src), int32(1))),
          assign(r, exp_of_op(src)),
          assign(s, int32(31)),
          While(cond=bin(Neq, v(vv), int32(0)), body=[
            assign(r, bin(LShift, v(r), int32(1))),
            assign(r, bin(Or, v(r), bin(And, v(vv), int32(1)))),
            assign(vv, bin(RShift, v(vv), int32(1))),
            assign(s, bin(Minus, v(s), int32(1))),
          ]),
          assign(dest.to_var(), bin(LShift, v(r), v(s))),
        ],
        cond,
      )
    }
    // swap bytes
    (SWPB, [Reg(dest), Reg(src1), Reg(src2), cond, _]) => {
      let temp = tmp(@types.ValueType::reg8_t())
      let dest = dest.to_var()
      let src1 = v(src1.to_var())
      let src2 = v(src2.to_var())
      exec(
        [
          assn(temp, load(v(mem), src2, R8)),
          assign(mem, store(v(mem), src2, extract(7, 0, src1), R8)),
          assn(dest, cast(Unsigned, 32, v(temp))),
        ],
        cond,
      )
    }
    // pack half (the shift is always an arithmetic right shift; port: an
    // amount of 0 encodes 32, as for the other immediate shifts)
    (PKHTB, [Reg(dest), src1, src2, Imm(shift), cond, _]) => {
      let (shifted, _) = shift_imm_c(
        exp_of_op(src2),
        ASR,
        decode_imm_shift(ASR, shift),
        @types.ValueType::reg32_t(),
      )
      exec(
        [
          assn(
            dest.to_var(),
            concat(extract(31, 16, exp_of_op(src1)), extract(15, 0, shifted)),
          ),
        ],
        cond,
      )
    }
    // reverses
    (REV, [Reg(dest), src, cond, _]) => {
      let s = exp_of_op(src)
      let rev = concat(
        concat(concat(extract(7, 0, s), extract(15, 8, s)), extract(23, 16, s)),
        extract(31, 24, s),
      )
      exec([assn(dest.to_var(), rev)], cond)
    }
    (REV16, [Reg(dest), src, cond, _]) => {
      let s = exp_of_op(src)
      let rev = concat(
        concat(concat(extract(23, 16, s), extract(31, 24, s)), extract(7, 0, s)),
        extract(15, 8, s),
      )
      exec([assn(dest.to_var(), rev)], cond)
    }
    _ =>
      fail("ops \{string_of_ops(ops)} doesn't match bits insn \{insn.name()}")
  }
}

///|
fn lift_mult(
  ops : ArrayView[Op],
  insn : MultInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let r32 = @types.ValueType::reg32_t()
  match (insn, ops) {
    (
      MUL,
      [Reg(dest), src1, src2, cond, _, wflag]
      | [Reg(dest), src1, src2, cond, wflag],
    ) => {
      let flags = set_nzf(v(dest.to_var()), r32)
      exec(
        [assn(dest.to_var(), bin(Times, exp_of_op(src1), exp_of_op(src2)))],
        cond,
        flags~,
        wflag~,
      )
    }
    (
      MLA,
      [Reg(dest), src1, src2, addend, cond, _, wflag]
      | [Reg(dest), src1, src2, addend, cond, wflag],
    ) => {
      let flags = set_nzf(v(dest.to_var()), r32)
      exec(
        [
          assn(
            dest.to_var(),
            bin(
              Plus,
              exp_of_op(addend),
              bin(Times, exp_of_op(src1), exp_of_op(src2)),
            ),
          ),
        ],
        cond,
        flags~,
        wflag~,
      )
    }
    (MLS, [Reg(dest), src1, src2, addend, cond, _]) =>
      exec(
        [
          assign(
            dest.to_var(),
            bin(
              Minus,
              exp_of_op(addend),
              bin(Times, exp_of_op(src1), exp_of_op(src2)),
            ),
          ),
        ],
        cond,
      )
    (
      UMULL,
      [lodest, hidest, src1, src2, cond, _, wflag]
      | [lodest, hidest, src1, src2, cond, wflag],
    ) => lift_mull(lodest~, hidest~, src1~, src2~, Unsigned, wflag~, cond)
    (
      SMULL,
      [lodest, hidest, src1, src2, cond, _, wflag]
      | [lodest, hidest, src1, src2, cond, wflag],
    ) => lift_mull(lodest~, hidest~, src1~, src2~, Signed, wflag~, cond)
    (
      UMLAL,
      [lodest, hidest, src1, src2, _loadd, _hiadd, cond, _, wflag]
      | [lodest, hidest, src1, src2, _loadd, _hiadd, cond, wflag],
    ) =>
      lift_mull(
        lodest~,
        hidest~,
        src1~,
        src2~,
        Unsigned,
        addend=true,
        wflag~,
        cond,
      )
    (
      SMLAL,
      [lodest, hidest, src1, src2, _loadd, _hiadd, cond, _, wflag]
      | [lodest, hidest, src1, src2, _loadd, _hiadd, cond, wflag],
    ) =>
      lift_mull(
        lodest~,
        hidest~,
        src1~,
        src2~,
        Signed,
        addend=true,
        wflag~,
        cond,
      )
    // signed 16bit mul plus a 32bit bit accum, Q
    (SMLABB, [dest, src1, src2, accum, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, accum~, q=true, BB, cond)
    // signed 16bit mul
    (SMULBB, [dest, src1, src2, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, BB, cond)
    // two signed 16bit muls plus 32bit accum and optional xchg, Q
    (SMLAD, [dest, src1, src2, accum, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, accum~, q=true, D, cond)
    // two signed 16bit muls and optional xchg, Q
    (SMUAD, [dest, src1, src2, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, q=true, D, cond)
    // signed 16bit times signed 32bit added to 32bit accum, Q
    (SMLAWB, [dest, src1, src2, accum, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, accum~, q=true, WB, cond)
    // signed 16bit mul
    (SMULTB, [dest, src1, src2, cond, _wflag]) =>
      lift_smul(dest~, src1~, src2~, TB, cond)
    // signed 16bit mul plus 64bit accum (LLVM also lists the accumulator
    // halves, tied to the destinations, as sources)
    (SMLALBT, [dest, hidest, src1, src2, _, _, cond, _wflag])
    | (SMLALBT, [dest, hidest, src1, src2, cond, _wflag]) =>
      lift_smul(
        dest~,
        hidest~,
        src1~,
        src2~,
        accum=dest,
        hiaccum=hidest,
        BT,
        cond,
      )
    _ =>
      fail("ops \{string_of_ops(ops)} doesn't match mult insn \{insn.name()}")
  }
}

///|
fn reversed(ops : ArrayView[Op]) -> Array[Op] {
  ops.to_owned().rev()
}

///|
fn lift_mem_multi(
  ops : ArrayView[Op],
  insn : MemMultiInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  // operands: base [, written-back base], cond, wr_flag, register list...
  let (base, cond, dest_list) = match (insn, ops) {
    (
      STMDA_UPD
      | LDMIB_UPD
      | STMIB_UPD
      | LDMDB_UPD
      | STMDB_UPD
      | LDMIA_UPD
      | STMIA_UPD
      | LDMDA_UPD,
      [base, _unknown, cond, _wr_flag, .. dest_list],
    ) => (base, cond, dest_list)
    (
      STMDA
      | LDMIB
      | STMIB
      | LDMDB
      | STMDB
      | LDMIA
      | STMIA
      | LDMDA,
      [base, cond, _wr_flag, .. dest_list],
    ) => (base, cond, dest_list)
    _ =>
      fail(
        "ops \{string_of_ops(ops)} doesn't match multi arg insn \{insn.name()}",
      )
  }
  let (mode, update, operation) = match insn {
    STMDA => (DA, NoUpdate, St)
    STMDA_UPD => (DA, Update, St)
    LDMIB => (IB, NoUpdate, Ld)
    LDMIB_UPD => (IB, Update, Ld)
    STMIB => (IB, NoUpdate, St)
    STMIB_UPD => (IB, Update, St)
    LDMDB => (DB, NoUpdate, Ld)
    LDMDB_UPD => (DB, Update, Ld)
    STMDB => (DB, NoUpdate, St)
    STMDB_UPD => (DB, Update, St)
    LDMIA => (IA, NoUpdate, Ld)
    LDMIA_UPD => (IA, Update, Ld)
    STMIA => (IA, NoUpdate, St)
    STMIA_UPD => (IA, Update, St)
    LDMDA => (DA, NoUpdate, Ld)
    LDMDA_UPD => (DA, Update, Ld)
  }
  // decrementing modes access the register list from the highest address
  let dest_list = match mode {
    DA | DB => reversed(dest_list)
    IA | IB => dest_list.to_owned()
  }
  exec(lift_m(dest_list, base, mode, update, operation), cond)
}

///|
fn lift_mem(
  ops : ArrayView[Op],
  insn : MemInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let zero_off = Op::Imm(0)
  // exclusive stores always succeed: the status register is cleared
  let strex = (dest1 : Reg, insns : Array[@types.Stmt], cond : Op) => {
    exec([..insns, assign(dest1.to_var(), int32(0))], cond)
  }
  match (insn, ops) {
    // addressing mode 3: dual, halfword and signed byte accesses
    (STRD, [dest1, dest2, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, Offset, Unsigned, D, St),
        cond,
      )
    }
    (LDRD, [dest1, dest2, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, Offset, Unsigned, D, Ld),
        cond,
      )
    }
    // LLVM's operand order (the written-back base first, as `STRD_PRE`);
    // upstream matches `[dest1; dest2; base; _unknown; ...]`, which reads
    // the base register from the second source register
    (STRD_POST, [_unknown, dest1, dest2, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, PostIndex, Unsigned, D, St),
        cond,
      )
    }
    (LDRD_POST, [dest1, dest2, base, _unknown, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, PostIndex, Unsigned, D, Ld),
        cond,
      )
    }
    (STRD_PRE, [_unknown, dest1, dest2, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, PreIndex, Unsigned, D, St),
        cond,
      )
    }
    (LDRD_PRE, [dest1, dest2, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(
        lift_r_exp(dest1~, dest2~, base~, offset~, PreIndex, Unsigned, D, Ld),
        cond,
      )
    }
    (STRH, [dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, Offset, Unsigned, H, St), cond)
    }
    (LDRH, [dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, Offset, Unsigned, H, Ld), cond)
    }
    (STRH_PRE, [_unknown, dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PreIndex, Unsigned, H, St), cond)
    }
    (LDRH_PRE, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PreIndex, Unsigned, H, Ld), cond)
    }
    (STRH_POST, [_unknown, dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, H, St), cond)
    }
    // Unlike all other loads and stores, the unprivileged (`T`) variants
    // set the sign bit of the immediate when the offset is POSITIVE.
    (STRHTr, [_unknown, dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_pos(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, H, St), cond)
    }
    (LDRH_POST, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, H, Ld), cond)
    }
    (LDRHTr, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_pos(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, H, Ld), cond)
    }
    (LDRSH, [dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, Offset, Signed, H, Ld), cond)
    }
    (LDRSH_PRE, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PreIndex, Signed, H, Ld), cond)
    }
    (LDRSH_POST, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Signed, H, Ld), cond)
    }
    (LDRSHTr, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_pos(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Signed, H, Ld), cond)
    }
    (LDRSHTi, [dest1, _unknown, base, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_pos(Reg(Nil), imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Signed, H, Ld), cond)
    }
    (LDRSB, [dest1, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, Offset, Signed, B, Ld), cond)
    }
    (LDRSB_PRE, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PreIndex, Signed, B, Ld), cond)
    }
    (LDRSB_POST, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_neg(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Signed, B, Ld), cond)
    }
    (LDRSBTr, [dest1, _unknown, base, reg_off, Imm(imm_off), cond, _]) => {
      let offset = mem_offset_reg_or_imm_pos(reg_off, imm_off)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Signed, B, Ld), cond)
    }
    // addressing mode 2: word and unsigned byte accesses
    (STRi12, [dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, Offset, Unsigned, W, St), cond)
    (LDRi12, [dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, Offset, Unsigned, W, Ld), cond)
    (STRBi12, [dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, Offset, Unsigned, B, St), cond)
    (LDRBi12, [dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, Offset, Unsigned, B, Ld), cond)
    (STRrs, [dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, Offset, Unsigned, W, St),
        cond,
      )
    (LDRrs, [dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, Offset, Unsigned, W, Ld),
        cond,
      )
    (STRBrs, [dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, Offset, Unsigned, B, St),
        cond,
      )
    (LDRBrs, [dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, Offset, Unsigned, B, Ld),
        cond,
      )
    (STR_POST_IMM, [_unknown, dest1, base, _invalid, Imm(offset), cond, _]) => {
      let offset = repair_imm(offset, sign_mask=0x1000, imm_mask=0xfff, NEG)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, W, St), cond)
    }
    (LDR_POST_IMM, [dest1, _unknown, base, _invalid, Imm(offset), cond, _]) => {
      let offset = repair_imm(offset, sign_mask=0x1000, imm_mask=0xfff, NEG)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, W, Ld), cond)
    }
    (
      STRB_POST_IMM
      | STRBT_POST_IMM,
      [_unknown, dest1, base, _invalid, Imm(offset), cond, _],
    ) => {
      let offset = repair_imm(offset, sign_mask=0x1000, imm_mask=0xfff, NEG)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, B, St), cond)
    }
    (
      LDRB_POST_IMM
      | LDRBT_POST_IMM,
      [dest1, _unknown, base, _invalid, Imm(offset), cond, _],
    ) => {
      let offset = repair_imm(offset, sign_mask=0x1000, imm_mask=0xfff, NEG)
      exec(lift_r_exp(dest1~, base~, offset~, PostIndex, Unsigned, B, Ld), cond)
    }
    (
      STR_POST_REG
      | STRT_POST_REG,
      [_unknown, dest1, base, offset, shift, cond, _],
    ) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PostIndex, Unsigned, W, St),
        cond,
      )
    (
      LDR_POST_REG
      | LDRT_POST_REG,
      [dest1, _unknown, base, offset, shift, cond, _],
    ) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PostIndex, Unsigned, W, Ld),
        cond,
      )
    (
      STRB_POST_REG
      | STRBT_POST_REG,
      [_unknown, dest1, base, offset, shift, cond, _],
    ) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PostIndex, Unsigned, B, St),
        cond,
      )
    (
      LDRB_POST_REG
      | LDRBT_POST_REG,
      [dest1, _unknown, base, offset, shift, cond, _],
    ) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PostIndex, Unsigned, B, Ld),
        cond,
      )
    (STR_PRE_IMM, [_unknown, dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, PreIndex, Unsigned, W, St), cond)
    (LDR_PRE_IMM, [dest1, _unknown, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, PreIndex, Unsigned, W, Ld), cond)
    (STRB_PRE_IMM, [_unknown, dest1, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, PreIndex, Unsigned, B, St), cond)
    (LDRB_PRE_IMM, [dest1, _unknown, base, offset, cond, _]) =>
      exec(lift_r_op(dest1~, base~, offset~, PreIndex, Unsigned, B, Ld), cond)
    (STR_PRE_REG, [_unknown, dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PreIndex, Unsigned, W, St),
        cond,
      )
    (LDR_PRE_REG, [dest1, _unknown, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PreIndex, Unsigned, W, Ld),
        cond,
      )
    (STRB_PRE_REG, [_unknown, dest1, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PreIndex, Unsigned, B, St),
        cond,
      )
    (LDRB_PRE_REG, [dest1, _unknown, base, offset, shift, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset~, shift~, PreIndex, Unsigned, B, Ld),
        cond,
      )
    // exclusive accesses
    (LDREX, [dest1, base, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset=zero_off, Offset, Unsigned, W, Ld),
        cond,
      )
    (LDREX, [dest1, Reg(_) as dest2, base, cond, _]) =>
      exec(
        lift_r_op(
          dest1~,
          dest2~,
          base~,
          offset=zero_off,
          Offset,
          Unsigned,
          W,
          Ld,
        ),
        cond,
      )
    (LDREXB, [dest1, base, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset=zero_off, Offset, Unsigned, B, Ld),
        cond,
      )
    (LDREXH, [dest1, base, cond, _]) =>
      exec(
        lift_r_op(dest1~, base~, offset=zero_off, Offset, Unsigned, H, Ld),
        cond,
      )
    // port: the register pair (LLVM's `GPRPair` operand) is split into
    // its registers by `ops_of_mc`; upstream fails on it
    (LDREXD, [dest1, dest2, base, cond, _]) =>
      exec(
        lift_r_op(
          dest1~,
          dest2~,
          base~,
          offset=zero_off,
          Offset,
          Unsigned,
          D,
          Ld,
        ),
        cond,
      )
    (STREX, [Reg(dest1), src1, base, cond, _]) =>
      strex(
        dest1,
        lift_r_op(dest1=src1, base~, offset=zero_off, Offset, Unsigned, W, St),
        cond,
      )
    (STREX, [Reg(dest1), src1, Reg(_) as src2, base, cond, _]) =>
      strex(
        dest1,
        lift_r_op(
          dest1=src1,
          dest2=src2,
          base~,
          offset=zero_off,
          Offset,
          Unsigned,
          W,
          St,
        ),
        cond,
      )
    (STREXB, [Reg(dest1), src1, base, cond, _]) =>
      strex(
        dest1,
        lift_r_op(dest1=src1, base~, offset=zero_off, Offset, Unsigned, B, St),
        cond,
      )
    (STREXH, [Reg(dest1), src1, base, cond, _]) =>
      strex(
        dest1,
        lift_r_op(dest1=src1, base~, offset=zero_off, Offset, Unsigned, H, St),
        cond,
      )
    (STREXD, [Reg(dest1), src1, src2, base, cond, _]) =>
      strex(
        dest1,
        lift_r_op(
          dest1=src1,
          dest2=src2,
          base~,
          offset=zero_off,
          Offset,
          Unsigned,
          D,
          St,
        ),
        cond,
      )
    _ =>
      fail(
        "ops \{string_of_ops(ops)} doesn't match mem access insn \{insn.name()}",
      )
  }
}

///|
fn lift_branch(
  addr : UInt,
  ops : ArrayView[Op],
  insn : BranchInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match (insn, ops) {
    (Bcc, [offset, cond, _]) => branch_lift(offset, cond~, addr)
    (BL | BL_pred, [offset, cond, _]) =>
      branch_lift(offset, cond~, link=true, addr)
    (BL, [offset]) => branch_lift(offset, link=true, addr)
    (BX_RET, [cond, _]) => branch_lift(Reg(LR), cond~, addr)
    (BX, [target]) => branch_lift(target, addr)
    (BX_pred, [target, cond, _]) => branch_lift(target, cond~, addr)
    (BLX, [target]) => branch_lift(target, link=true, addr)
    (BLX_pred, [target, cond, _]) => branch_lift(target, cond~, link=true, addr)
    (BLXi, [offset]) => branch_lift(offset, link=true, addr)
    _ =>
      fail("ops \{string_of_ops(ops)} doesn't match branch insn \{insn.name()}")
  }
}

///|
fn lift_special(
  ops : ArrayView[Op],
  insn : SpecialInsn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match (insn, ops) {
    // supervisor call
    (SVC, [Imm(w), cond, _]) => {
      let num = word(24, (w & 0xFFFFFF).to_uint64())
      let dst = "__svc(\{num.format_value()})"
      exec([@types.Stmt::encode(@types.Stmt::call(), dst)], cond)
    }
    (MRS, [Reg(dest), cond, _]) => {
      let get_bits = (flag : @types.Var, src : @types.Exp, lsb : UInt) => {
        bin(Or, src, bin(LShift, cast(Unsigned, 32, v(flag)), int32(lsb)))
      }
      let d = dest.to_var()
      let vd = v(d)
      exec(
        [
          assign(d, int32(0)),
          assign(d, get_bits(nf, vd, 31)),
          assign(d, get_bits(zf, vd, 30)),
          assign(d, get_bits(cf, vd, 29)),
          assign(d, get_bits(vf, vd, 28)),
          assign(d, get_bits(qf, vd, 27)),
          assign(d, get_bits(ge[3], vd, 19)),
          assign(d, get_bits(ge[2], vd, 18)),
          assign(d, get_bits(ge[1], vd, 17)),
          assign(d, get_bits(ge[0], vd, 16)),
        ],
        cond,
      )
    }
    // Move to special from register. An immediate with bit x set means:
    // bit 0 is CPSR_c (is not valid in ARMv7)
    // bit 1 is CPSR_x (is not valid in ARMv7)
    // bit 2 is APSR_g
    // bit 3 is APSR_nzcvq
    (MSR, [Imm(imm), Reg(src), cond, _]) => {
      let src = v(src.to_var())
      let set = (flag : @types.Var, bit : Int) => {
        assign(flag, extract(bit, bit, src))
      }
      let s1 = if (imm & 0x8) == 0x8 {
        [set(nf, 31), set(zf, 30), set(cf, 29), set(vf, 28), set(qf, 27)]
      } else {
        []
      }
      let s2 = if (imm & 0x4) == 0x4 {
        [set(ge[3], 19), set(ge[2], 18), set(ge[1], 17), set(ge[0], 16)]
      } else {
        []
      }
      exec([..s1, ..s2], cond)
    }
    // all of these are nops in user mode
    (CPS2p | DMB | DSB | HINT | PLDi12, _) => []
    _ =>
      fail(
        "ops \{string_of_ops(ops)} doesn't match special insn \{insn.name()}",
      )
  }
}
