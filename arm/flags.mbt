// Port of `Arm_flags`: status flag computations.

///|
fn set_nzf(r : @types.Exp, t : @types.ValueType) -> Array[@types.Stmt] {
  [assign(nf, msb(r)), assign(zf, bin(Eq, r, zero(t)))]
}

///|
fn set_vnzf_add(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  [
    assign(vf, msb(bin(And, lnot(bin(Xor, s1, s2)), bin(Xor, s1, r)))),
    ..set_nzf(r, t),
  ]
}

///|
fn set_add(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  [assign(cf, bin(Lt, r, s1)), ..set_vnzf_add(s1, s2, r, t)]
}

///|
fn set_vnzf_sub(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  [
    assign(vf, msb(bin(And, bin(Xor, s1, s2), bin(Xor, s1, r)))),
    ..set_nzf(r, t),
  ]
}

///|
fn set_sub(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  [assign(cf, bin(Le, s2, s1)), ..set_vnzf_sub(s1, s2, r, t)]
}

///|
fn set_adc(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  let width = bitlen(t) + 1
  let widen = (x : @types.Exp) => cast(Unsigned, width, x)
  let sum_with_carry = bin(Plus, bin(Plus, widen(s1), widen(s2)), widen(v(cf)))
  [assign(cf, msb(sum_with_carry)), ..set_vnzf_add(s1, s2, r, t)]
}

///|
fn set_sbc(
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
  t : @types.ValueType,
) -> Array[@types.Stmt] {
  set_adc(s1, lnot(s2), r, t)
}

///|
/// Carry flag of data-processing instructions with a modified immediate.
/// `imm` is the (undecoded) immediate operand, `data` the raw instruction.
fn set_cf_data(imm~ : UInt, data~ : UInt) -> @types.Stmt {
  let value = if imm <= 255 {
    if (data & 0xf00) == 0 {
      @types.Exp::unknown("undefined", @types.ValueType::bool_t())
    } else {
      bool_exp(false)
    }
  } else {
    msb(int32(imm))
  }
  assign(cf, value)
}
