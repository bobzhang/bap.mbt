// Port of `Arm_shift`: shifted operands and their carry outputs.
//
// port: the shifts follow the ARM ARM (`Shift_C`, `DecodeImmShift`)
// rather than upstream, which shifts by the raw amount: an immediate
// `LSR`/`ASR` amount of 0 encodes 32, register-specified amounts are the
// least significant byte of the register (amounts of 32 and more shift
// every bit out, rotations use the amount modulo 32), and the carry is
// unchanged for zero amounts.

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
/// Bit `n` of `e`.
fn bit_of(n : Int, e : @types.Exp) -> @types.Exp {
  extract(n, n, e)
}

///|
/// Shift `src` by the constant amount `n` (already decoded: `LSR`/`ASR`
/// by 32 are `n = 32`, `n` is ignored by `RRX`) and return the shifted
/// value together with the carry-out bit.
fn shift_imm_c(
  src : @types.Exp,
  shift_type : Shift,
  n : Int,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) {
  let bits = bitlen(t)
  let amount = int_bits(bits, n.to_uint64())
  match shift_type {
    _ if n == 0 && !(shift_type is RRX) => (src, v(cf))
    LSL if n >= bits =>
      (zero(t), if n == bits { bit_of(0, src) } else { bool_exp(false) })
    LSL => (bin(LShift, src, amount), bit_of(bits - n, src))
    LSR if n >= bits =>
      (zero(t), if n == bits { bit_of(bits - 1, src) } else { bool_exp(false) })
    LSR => (bin(RShift, src, amount), bit_of(n - 1, src))
    ASR if n >= bits =>
      (
        bin(ARShift, src, int_bits(bits, (bits - 1).to_uint64())),
        bit_of(bits - 1, src),
      )
    ASR => (bin(ARShift, src, amount), bit_of(n - 1, src))
    ROR => {
      let m = n % bits
      if m == 0 {
        (src, bit_of(bits - 1, src))
      } else {
        let rotated = bin(
          Or,
          bin(RShift, src, int_bits(bits, m.to_uint64())),
          bin(LShift, src, int_bits(bits, (bits - m).to_uint64())),
        )
        (rotated, bit_of(m - 1, src))
      }
    }
    RRX => {
      let e1 = int_bits(bits, 1)
      let carryin = bin(
        LShift,
        cast(Unsigned, bits, v(cf)),
        int_bits(bits, (bits - 1).to_uint64()),
      )
      (bin(Or, bin(RShift, src, e1), carryin), bit_of(0, src))
    }
  }
}

///|
/// Shift `src` by the register-specified `amount` (the least significant
/// byte of the shift register, zero-extended to the width of `src`) and
/// return the shifted value together with the carry-out bit.
fn shift_reg_c(
  src : @types.Exp,
  shift_type : Shift,
  amount : @types.Exp,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) {
  let bits = bitlen(t)
  let k = (n : Int) => int_bits(bits, n.to_uint64())
  let ite = (c, y, n) => @types.Exp::Ite(cond=c, yes=y, no=n)
  let is_zero = bin(Eq, amount, k(0))
  let out = bin(Lt, k(bits), amount) // amount > bits
  let inside = bin(Lt, amount, k(bits)) // amount < bits
  // bit `amount - 1` (resp. `bits - amount`) of `src`
  let low_bit = (n : @types.Exp) => cast(Low, 1, bin(RShift, src, n))
  match shift_type {
    LSL => {
      let value = ite(inside, bin(LShift, src, amount), zero(t))
      let carry = ite(
        is_zero,
        v(cf),
        ite(out, bool_exp(false), low_bit(bin(Minus, k(bits), amount))),
      )
      (value, carry)
    }
    LSR => {
      let value = ite(inside, bin(RShift, src, amount), zero(t))
      let carry = ite(
        is_zero,
        v(cf),
        ite(out, bool_exp(false), low_bit(bin(Minus, amount, k(1)))),
      )
      (value, carry)
    }
    ASR => {
      let value = ite(
        inside,
        bin(ARShift, src, amount),
        bin(ARShift, src, k(bits - 1)),
      )
      let carry = ite(
        is_zero,
        v(cf),
        ite(inside, low_bit(bin(Minus, amount, k(1))), bit_of(bits - 1, src)),
      )
      (value, carry)
    }
    ROR | RRX => {
      let m = bin(And, amount, k(bits - 1))
      let rotated = ite(
        bin(Eq, m, k(0)),
        src,
        bin(Or, bin(RShift, src, m), bin(LShift, src, bin(Minus, k(bits), m))),
      )
      let carry = ite(is_zero, v(cf), bit_of(bits - 1, rotated))
      (rotated, carry)
    }
  }
}

///|
/// `Arm_shift.lift_r`: register-specified shift amount; the immediate
/// operand encodes the shift type. `amount` is the least significant byte
/// of the shift register (see `shift_amount`).
fn shift_r(
  src : @types.Exp,
  shift_type : Op,
  amount : @types.Exp,
  t : @types.ValueType,
) -> (@types.Exp, @types.Exp) raise @mc.LiftError {
  let shift_type = assert_imm(shift_type)
  shift_reg_c(src, shift_of_word(shift_type), amount, t)
}

///|
/// The amount of a register-specified shift: the least significant byte of
/// the register.
fn shift_amount(reg : @types.Exp, t : @types.ValueType) -> @types.Exp {
  cast(Unsigned, bitlen(t), extract(7, 0, reg))
}

///|
/// The amount of an immediate shift: `LSR`/`ASR` amounts of 0 encode 32.
fn decode_imm_shift(shift_type : Shift, amount : UInt) -> Int {
  match shift_type {
    LSR | ASR if amount == 0 => 32
    _ => amount.reinterpret_as_int()
  }
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
  let amount = decode_imm_shift(shift_t, (imm & 7U.lnot()) >> 3)
  shift_imm_c(src, shift_t, amount, t)
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
  let amount = decode_imm_shift(shift_t, shift & 0xFFF)
  let (exp, _) = shift_imm_c(src, shift_t, amount, typ)
  if (shift & 0x1000) == 0x1000 {
    bin(Times, Int(try! @types.Word::ones(width~)), exp)
  } else {
    exp
  }
}
