// Port of `Arm_mov`: data-processing instructions.

///|
/// Decode an A32 modified immediate constant: an 8-bit value rotated
/// right by twice the 4-bit rotation field (`Arm_mov.MIC.mic`).
pub fn decode_modified_imm(x : UInt) -> UInt {
  let shift = (x >> 8) & 0xF
  let value = x & 0xFF
  if shift == 0 {
    x
  } else {
    let bits = (shift + shift).reinterpret_as_int()
    (value >> bits) | (value << (32 - bits))
  }
}

///|
/// `Arm_mov.MIC.decode`: T32 immediates are already decoded by the
/// disassembler, A32 ones are not.
fn mic_decode(encoding : Encoding, op : Op) -> @types.Exp {
  match (op, encoding) {
    (Imm(x), A32) => int32(decode_modified_imm(x))
    _ => exp_of_op(op)
  }
}

///|
/// `Arm_mov.lift`: data-processing instruction `itype` computing
/// `src1 op src2` (with the second, or for moves the first, operand
/// optionally shifted by `sreg`/`simm`) into `dest`, setting the flags when
/// `wflag` is `CPSR`. `raw` is the instruction word.
fn mov_lift(
  encoding~ : Encoding,
  dest? : Op,
  src1 : Op,
  src2? : Op,
  itype : DataOper,
  sreg? : Op,
  simm? : Op,
  raw : UInt,
  wflag~ : Op,
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let r32 = @types.ValueType::reg32_t()
  let dest = match dest {
    None => tmp(r32)
    Some(Reg(reg)) => reg.to_var()
    Some(Imm(_)) => fail("dest is not a reg")
  }
  let s1 = mic_decode(encoding, src1)
  let s2 = match src2 {
    Some(src) => mic_decode(encoding, src)
    None => zero(r32)
  }
  let unshifted = tmp(r32)
  let is_mov = itype is (MOV | MVN)
  // register or immediate shift of the second (first for moves) operand
  let (s1, s2, stmts, carry) = match (sreg, simm) {
    (Some(sreg), Some(simm)) => {
      let (shifted, carry) = shift_r(v(unshifted), simm, exp_of_op(sreg), r32)
      if is_mov {
        (shifted, s2, [assign(unshifted, s1)], carry)
      } else {
        (s1, shifted, [assign(unshifted, s2)], carry)
      }
    }
    (None, Some(simm)) => {
      let (shifted, carry) = shift_i(v(unshifted), simm, r32)
      if is_mov {
        (shifted, s2, [assign(unshifted, s1)], carry)
      } else {
        (s1, shifted, [assign(unshifted, s2)], carry)
      }
    }
    _ => (s1, s2, [], v(cf))
  }
  let vd = v(dest)
  let (stmts, flags) = match (itype, src1, src2) {
    (MOV | MVN, Imm(imm), _) | (AND | BIC | EOR | ORR, _, Some(Imm(imm))) =>
      (stmts, [set_cf_data(imm~, data=raw), ..set_nzf(vd, r32)])
    (AND | BIC | EOR | MOV | MVN | ORR, _, _) =>
      (stmts, [assign(cf, carry), ..set_nzf(vd, r32)])
    (arith, _, _) => {
      let orig1 = tmp(r32)
      let orig2 = tmp(r32)
      let v1 = v(orig1)
      let v2 = v(orig2)
      let flags = match arith {
        SUB => set_sub(v1, v2, vd, r32)
        RSB => set_sub(v2, v1, vd, r32)
        ADD => set_add(v1, v2, vd, r32)
        ADC => set_adc(v1, v2, vd, r32)
        SBC => set_sbc(v1, v2, vd, r32)
        RSC => set_sbc(v2, v1, vd, r32)
        _ => panic()
      }
      ([..stmts, assign(orig1, s1), assign(orig2, s2)], flags)
    }
  }
  let vcf = cast(Unsigned, 32, v(cf))
  let oper = match itype {
    AND => bin(And, s1, s2)
    BIC => bin(And, s1, lnot(s2))
    EOR => bin(Xor, s1, s2)
    MOV => s1
    MVN => lnot(s1)
    ORR => bin(Or, s1, s2)
    SUB => bin(Minus, s1, s2)
    RSB => bin(Minus, s2, s1)
    ADD => bin(Plus, s1, s2)
    ADC => bin(Plus, bin(Plus, s1, s2), vcf)
    SBC => bin(Plus, bin(Plus, s1, lnot(s2)), vcf)
    RSC => bin(Plus, bin(Plus, lnot(s1), s2), vcf)
  }
  exec([..stmts, assn(dest, oper)], cond, flags~, wflag~)
}
