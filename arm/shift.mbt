// Port of `Arm_shift`: shifted operands and their carry outputs.

///|
fn shift_of_word(op : UInt) -> Shift raise @mc.LiftError {
  match op {
    1 => ASR
    2 => LSL
    3 => LSR
    4 => ROR
    5 => RRX
    _ => fail("Imm \{imm_word(op).to_string()}, doesn't stand for shift")
  }
}

///|
/// `Arm_shift.lift_c`: shift `src` by `shift` and return the shifted value
/// together with the carry-out bit.
fn shift_c(
  src : @types.Exp,
  shift_type : Shift,
  shift : @types.Exp,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) {
  let bits = bitlen(t)
  let bits_e = int_bits(bits, bits.to_uint64())
  let nth_bit = (n : @types.Exp, e : @types.Exp) => {
    cast(Low, 1, bin(RShift, e, n))
  }
  let e1 = int_bits(bits, 1)
  match shift_type {
    ASR => (bin(ARShift, src, shift), nth_bit(bin(Minus, shift, e1), src))
    LSL => {
      let carry = @types.Exp::Ite(
        cond=bin(Neq, shift, int_bits(bits, 0)),
        yes=nth_bit(bin(Minus, bits_e, shift), src),
        no=v(cf),
      )
      (bin(LShift, src, shift), carry)
    }
    LSR => (bin(RShift, src, shift), nth_bit(bin(Minus, shift, e1), src))
    ROR => {
      let ret1 = bin(RShift, src, shift)
      let ret2 = bin(LShift, src, bin(Minus, bits_e, shift))
      (bin(Or, ret1, ret2), nth_bit(bin(Minus, shift, e1), src))
    }
    RRX => {
      let ret1 = bin(RShift, src, e1)
      let carryin = bin(
        LShift,
        cast(Unsigned, bits, v(cf)),
        bin(Minus, bits_e, e1),
      )
      (bin(Or, ret1, carryin), nth_bit(int_bits(1, 0), src))
    }
  }
}

///|
/// `Arm_shift.lift_r`: register-specified shift amount; the immediate
/// operand encodes the shift type.
fn shift_r(
  src : @types.Exp,
  shift_type : Op,
  shift : @types.Exp,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) raise @mc.LiftError {
  let shift_type = assert_imm(shift_type)
  shift_c(src, shift_of_word(shift_type), shift, t)
}

///|
/// `Arm_shift.lift_i`: immediate shift; the low three bits of the operand
/// are the shift type, the remaining bits the amount.
fn shift_i(
  src : @types.Exp,
  shift_type : Op,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) raise @mc.LiftError {
  let imm = assert_imm(shift_type)
  let shift_t = shift_of_word(imm & 7)
  let amount = (imm & 7U.lnot()) >> 3
  shift_c(src, shift_t, int_bits(bitlen(t), amount.to_uint64()), t)
}

///|
/// `Arm_shift.lift_mem`: decode the shifted offset of a memory operand.
/// Bits 11..0 are the amount, bit 12 negates the result, bits 15..13 are
/// the shift type.
fn shift_mem(
  src : @types.Exp,
  shift : Op,
  typ : @types.ValueType,
) -> @types.Exp raise @mc.LiftError {
  let shift = assert_imm(shift)
  let width = bitlen(typ)
  let shift_t = shift_of_word((shift & 0xE000) >> 13)
  let amount = int_bits(width, (shift & 0xFFF).to_uint64())
  let (exp, _) = shift_c(src, shift_t, amount, typ)
  if (shift & 0x1000) == 0x1000 {
    bin(Times, Int(try! @types.Word::ones(width~)), exp)
  } else {
    exp
  }
}
