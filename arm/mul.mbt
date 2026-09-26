// Port of `Arm_mul`: long and signed-halfword multiplies.

///|
/// `Arm_mul.lift_mull`: 32x32->64 multiply (optionally accumulating into
/// the destination pair).
fn lift_mull(
  lodest~ : Op,
  hidest~ : Op,
  src1~ : Op,
  src2~ : Op,
  sign : Sign,
  addend? : Bool = false,
  wflag~ : Op,
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let lodest = assert_reg(lodest)
  let hidest = assert_reg(hidest)
  let s1_64 = cast_of_sign(sign, 64, exp_of_op(src1))
  let s2_64 = cast_of_sign(sign, 64, exp_of_op(src2))
  let result = tmp(@types.ValueType::reg64_t())
  let eres = v(result)
  let flags = set_nzf(eres, @types.ValueType::reg64_t())
  let opn = if addend {
    bin(
      Plus,
      bin(Times, s1_64, s2_64),
      concat(exp_of_reg(hidest), exp_of_reg(lodest)),
    )
  } else {
    bin(Times, s1_64, s2_64)
  }
  let insns = [
    assign(result, opn),
    assign(lodest.to_var(), extract(31, 0, eres)),
    assign(hidest.to_var(), extract(63, 32, eres)),
  ]
  exec(insns, cond, flags~, wflag~)
}

///|
/// `Arm_mul.lift_smul`: signed multiplies of halfwords/words with optional
/// 32/64-bit accumulation and Q flag update.
fn lift_smul(
  dest~ : Op,
  hidest? : Op,
  src1~ : Op,
  src2~ : Op,
  accum? : Op,
  hiaccum? : Op,
  q? : Bool = false,
  size : SmulSize,
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let dest = assert_reg(dest)
  let src1 = exp_of_op(src1)
  let src2 = exp_of_op(src2)
  let excast = (hi : Int, lo : Int, s : @types.Exp) => {
    cast(Signed, 64, extract(hi, lo, s))
  }
  let top = (s : @types.Exp) => excast(31, 16, s)
  let bot = (s : @types.Exp) => excast(15, 0, s)
  let top32 = (s : @types.Exp) => excast(47, 16, s)
  let res = tmp(@types.ValueType::reg64_t())
  let mul = (x : @types.Exp, y : @types.Exp) => bin(Times, x, y)
  let result = match size {
    BB => mul(bot(src1), bot(src2))
    BT => mul(bot(src1), top(src2))
    TB => mul(top(src1), bot(src2))
    D => bin(Plus, mul(top(src1), top(src2)), mul(bot(src1), bot(src2)))
    WB => top32(cast(Signed, 64, mul(src1, bot(src2))))
  }
  let result = match (accum, hiaccum) {
    (None, None) => result
    (Some(a), None) => bin(Plus, result, cast(Signed, 64, exp_of_op(a)))
    (Some(a), Some(hia)) =>
      bin(Plus, result, concat(exp_of_op(hia), exp_of_op(a)))
    _ => fail("Cannot specify only a hi accumulator")
  }
  let qflag = if q {
    [assign(qf, bin(Neq, excast(31, 0, v(res)), v(res)))]
  } else {
    []
  }
  let instr = match hidest {
    Some(Reg(hid)) =>
      [
        assign(res, result),
        assign(hid.to_var(), extract(63, 32, v(res))),
        assign(dest.to_var(), extract(31, 0, v(res))),
      ]
    None => [assign(res, result), assign(dest.to_var(), extract(31, 0, v(res)))]
    _ => fail("unexpected operand type")
  }
  exec([..instr, ..qflag], cond)
}
