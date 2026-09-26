// Port of `Arm_bit`: sign/zero extension, bit-field extraction and
// insertion.

///|
/// `Arm_bit.extend`: rotate `src` by `rot * 8`, take the low byte or
/// halfword, extend it to 32 bits and optionally add `src2`.
fn bit_extend(
  dest~ : Op,
  src~ : Op,
  src2? : Op,
  sign : Sign,
  size : MemSize,
  rot~ : Op,
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let rot = assert_imm(rot)
  let dest = assert_reg(dest)
  let bits = match size {
    H => 16
    B => 8
    _ => fail("unexpected extension size")
  }
  let amount = rot * 8
  let rotated = if amount == 0 {
    exp_of_op(src)
  } else {
    shift_imm_c(
      exp_of_op(src),
      ROR,
      amount.reinterpret_as_int(),
      @types.ValueType::reg32_t(),
    ).0
  }
  let extracted = cast(Low, bits, rotated)
  let extent = cast_of_sign(sign, 32, extracted)
  let final_ = match src2 {
    Some(s2) => bin(Plus, exp_of_op(s2), extent)
    None => extent
  }
  exec([assn(dest.to_var(), final_)], cond)
}

///|
/// `Arm_bit.bit_extract` (`UBFX`/`SBFX`).
fn bit_extract(
  dest~ : Op,
  src~ : Op,
  sign : Sign,
  lsb~ : Op,
  widthminus1~ : Op,
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let dest = assert_reg(dest)
  let low = assert_imm(lsb).reinterpret_as_int()
  let high = low + assert_imm(widthminus1).reinterpret_as_int()
  let extracted = extract(high, low, exp_of_op(src))
  let final_ = cast_of_sign(sign, 32, extracted)
  exec([assn(dest.to_var(), final_)], cond)
}

///|
/// `Arm_bit.get_lsb_width`: the `lsb` and `width` fields of a `BFI`/`BFC`
/// instruction word.
fn get_lsb_width(instr : UInt) -> (Int, Int) {
  let lsb = ((instr >> 7) & 0x1f).reinterpret_as_int()
  let msb = ((instr >> 16) & 0x1f).reinterpret_as_int()
  (lsb, (msb - lsb + 1).abs())
}

///|
/// The `lsb` and `width` of a bit field, recovered from the LLVM
/// `bf_inv_mask_imm` operand (the inverted field mask). Used when the raw
/// instruction word is not available.
fn lsb_width_of_inv_mask(mask : UInt) -> (Int, Int) {
  let field = mask.lnot()
  if field == 0 {
    (0, 0)
  } else {
    (field.ctz(), field.popcnt())
  }
}

///|
/// `Arm_bit.bit_field_insert` (`BFI`/`BFC`).
fn bit_field_insert(
  dest~ : Op,
  src~ : Op,
  lsb_width : (Int, Int),
  cond : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let dest = assert_reg(dest)
  let d = dest.to_var()
  let d_e = v(d)
  let (lsb, width) = lsb_width
  let extracted = extract(width - 1, 0, exp_of_op(src))
  let ext_h = (b : Int, s : @types.Exp) => extract(31, b, s)
  let ext_l = (b : Int, s : @types.Exp) => extract(b, 0, s)
  let inst = match (lsb + width - 1, lsb) {
    (31, 0) => extracted
    (31, l) => concat(extracted, ext_l(l - 1, d_e))
    (m, 0) => concat(ext_h(m + 1, d_e), extracted)
    (m, l) => concat(concat(ext_h(m + 1, d_e), extracted), ext_l(l - 1, d_e))
  }
  exec([assign(d, inst)], cond)
}
