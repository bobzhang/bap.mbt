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
/// Carry flag of logical instructions with a modified immediate `imm`
/// (`ARMExpandImm_C`/`ThumbExpandImm_C`): unchanged when the constant is
/// not rotated, its most significant bit otherwise. A32 immediates are the
/// undecoded 12-bit fields, T32 ones are decoded, and their rotated forms
/// are the constants that are not below 256 nor replicated bytes.
///
/// port: upstream sets the carry to an unknown value or to zero for
/// unrotated constants and ignores T32 encodings.
fn set_cf_data(encoding : Encoding, imm : UInt32) -> @types.Stmt {
  let rotated = match encoding {
    A32 => imm >> 8 != 0
    T32 => {
      let b = imm & 0xFF
      let b1 = (imm >> 8) & 0xFF
      !(imm < 256 ||
      imm == b * 0x00010001 ||
      imm == b1 * 0x01000100 ||
      imm == b * 0x01010101)
    }
  }
  let value = if rotated {
    let decoded = match encoding {
      A32 => decode_modified_imm(imm)
      T32 => imm
    }
    bool_exp(decoded >> 31 != 0)
  } else {
    v(cf)
  }
  assign(cf, value)
}
