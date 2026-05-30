///|
test "word wraps bitvec operations" {
  let high = @types.Word::of_int(width=16, 0xdead)
  let low = @types.Word::of_int(width=16, 0xbeef)
  inspect(high.concat(low).to_hex(), content="0xdeadbeef")
  inspect(
    @types.Word::of_int32(0xDEADBEEF).to_string(),
    content="0xDEADBEEF:32u",
  )
  inspect(
    @types.Word::of_int32(0xDEADBEEF, width=16).to_hex(),
    content="0xbeef",
  )
  inspect(
    @types.Word::of_int64(0xDEADBEEFL).to_string(),
    content="0xDEADBEEF:64u",
  )
  inspect(
    @types.Word::of_int64(0xDEADBEEFL, width=16).to_hex(),
    content="0xbeef",
  )
  assert_true(@types.Word::from_string("true") == @types.Word::b1())
  inspect(@types.Word::from_string("7:2").to_hex(), content="0x3")
  inspect(
    @types.Word::from_bytes(b"\xef\xbe\xad\xde", endian=LittleEndian).to_hex(),
    content="0xdeadbeef",
  )
  inspect(
    @types.Word::of_binary(BigEndian, b"\xde\xad\xbe\xef").to_hex(),
    content="0xdeadbeef",
  )
  inspect(
    @types.Word::of_binary(LittleEndian, b"\xef\xbe\xad\xde").to_hex(),
    content="0xdeadbeef",
  )
  inspect(
    @types.Word::of_int(width=8, 0xff).add(@types.Word::one(width=8)).to_hex(),
    content="0x00",
  )
  let x = @types.Word::of_int(width=8, 0x10)
  let y = @types.Word::of_int(width=8, 0x0c)
  inspect(x.gcd(y).to_hex(), content="0x04")
  inspect(x.lcm(y).to_hex(), content="0x30")
  let (g, a, b) = x.gcd_ext(y)
  assert_true((g.to_hex(), a.to_hex(), b.to_hex()) == ("0x04", "0x01", "0xff"))
}

///|
test "word exposes BAP numeric compatibility aliases" {
  let x = @types.Word::of_int(width=8, 0x10)
  let y = @types.Word::of_int(width=8, 0x33)
  let source = @bitvec.of_uint64(width=16, 0xdead)
  assert_true(@types.Word::create(source, 8).to_hex() == "0xad")
  assert_true(
    @types.Word::create(@bitvec.of_uint64(width=8, 0xef), 16).to_hex() ==
    "0x00ef",
  )
  assert_true(x.bitwidth() == 8)
  assert_true(@types.Word::of_int(width=8, 0xff).succ().is_zero())
  assert_true(@types.Word::zero(width=8).pred().to_hex() == "0xff")
  assert_true(x.nsucc(0x20).to_hex() == "0x30")
  assert_true(x.npred(0x11).to_hex() == "0xff")
  assert_true(x.nsucc(-1) == x.pred())
  assert_true(@types.Word::of_int(width=8, 0xff).abs().to_hex() == "0x01")
  assert_true(x.logand(y) == x.bit_and(y))
  assert_true(x.logor(y) == x.bit_or(y))
  assert_true(x.logxor(y) == x.bit_xor(y))
  assert_true(
    @types.Word::of_int(width=8, 0xf0)
    .modulo(@types.Word::of_int(width=8, 7))
    .to_int() ==
    2,
  )
  assert_true(x.gcd_exn(y) == x.gcd(y))
  assert_true(x.lcm_exn(y) == x.lcm(y))
  assert_true(x.gcdext(y) == x.gcd_ext(y))
  assert_true(x.gcdext_exn(y) == x.gcd_ext(y))
  assert_true(
    @types.Word::of_int(width=16, 0xdad5)
    .extract_exn(hi=0xB, lo=0x4)
    .to_int_exn() ==
    0xad,
  )
  assert_true(@types.Word::of_int(width=8, -6).signed().to_int32_exn() == -6)
  assert_true(
    @types.Word::of_int64(-6L, width=8).signed().to_int64_exn() == -6L,
  )
}

///|
test "word BAP value formatting covers radix prefix suffix and case" {
  let value = @types.Word::of_int(width=8, 42)
  assert_true(value.string_of_value() == "2a")
  assert_true(value.string_of_value(hex=false) == "42")
  assert_true(value.format_value() == "0x2A")
  assert_true(
    value.format_value(format=WordDec, suffix=WordFullSuffix) == "42:8u",
  )
  assert_true(value.format_value(format=WordOct) == "0o52")
  assert_true(
    @types.Word::of_int(width=8, 2).format_value(format=WordBin) == "0b10",
  )
  assert_true(
    value.format_value(
      letter_case=WordLowerCase,
      prefix=WordCustomPrefix("#"),
      suffix=WordSizeSuffix,
    ) ==
    "#2a:8",
  )
  let minus_one = @types.Word::of_int(width=8, -1).signed()
  assert_true(minus_one.string_of_value() == "-1")
  assert_true(
    minus_one.format_value(format=WordDec, suffix=WordFullSuffix) == "-1:8s",
  )
  let min_i8 = @types.Word::of_int(width=8, -128).signed()
  assert_true(
    min_i8.format_value(format=WordDec, suffix=WordFullSuffix) == "-128:8s",
  )
}

///|
test "word address memref mirrors BAP scaling and wrapping" {
  let base = @types.Word::of_int(width=32, 0x1000)
  assert_true(base.memref(disp=4, index=3, scale=R16).to_int() == 0x100a)
  assert_true(base.memref(disp=-0x10).to_int() == 0x0ff0)
  assert_true(
    @types.Word::of_int(width=8, 0xfe).memref(disp=4).to_hex() == "0x02",
  )
}

///|
test "word generic division follows BAP signedness flag" {
  let minus_two = @types.Word::of_int(width=8, -2).signed()
  let minus_three = @types.Word::of_int(width=8, -3).signed()
  let two = @types.Word::of_int(width=8, 2)
  assert_true(minus_two.div(two).to_hex() == "0xff")
  assert_true(minus_two.unsigned().div(two).to_hex() == "0x7f")
  assert_true(minus_three.rem(two).to_hex() == "0xff")
  assert_true(minus_three.unsigned().rem(two).to_hex() == "0x01")
  assert_true(minus_three.modulo(two).to_hex() == "0xff")
}

///|
fn assert_word_concat(
  high : @types.Word,
  low : @types.Word,
  expected : @types.Word,
) -> Unit raise {
  assert_true(high.concat(low) == expected)
}

///|
test "translated BAP word concatenation preserves operand widths" {
  assert_word_concat(
    @types.Word::of_int(width=16, 0xDEAD),
    @types.Word::of_int(width=16, 0xBEEF),
    @types.Word::of_uint64(width=32, 0xDEADBEEF),
  )
  assert_word_concat(
    @types.Word::of_int(width=8, 0xDE),
    @types.Word::of_int(width=24, 0xADBEEF),
    @types.Word::of_uint64(width=32, 0xDEADBEEF),
  )
  assert_word_concat(
    @types.Word::of_int(width=4, 0x0D),
    @types.Word::of_int(width=28, 0x0EADBEEF),
    @types.Word::of_uint64(width=32, 0xDEADBEEF),
  )
  assert_word_concat(
    @types.Word::of_int(width=3, 0x6),
    @types.Word::of_int(width=5, 0x17),
    @types.Word::of_int(width=8, 0xD7),
  )
}

///|
fn assert_word_extract(
  source : @types.Word,
  hi? : Int = -1,
  lo? : Int = 0,
  expected~ : @types.Word,
) -> Unit raise {
  assert_true(source.extract(hi~, lo~) == expected)
}

///|
test "translated BAP word extraction follows bit numbering cases" {
  let word = @types.Word::of_int(width=16, 0xDAD5)
  assert_word_extract(word, lo=0xC, expected=@types.Word::of_int(width=4, 0xD))
  assert_word_extract(word, lo=0x8, expected=@types.Word::of_int(width=8, 0xDA))
  assert_word_extract(word, hi=0x7, expected=@types.Word::of_int(width=8, 0xD5))
  assert_word_extract(word, hi=0x3, expected=@types.Word::of_int(width=4, 0x5))
  assert_word_extract(
    word,
    hi=0xB,
    lo=0x4,
    expected=@types.Word::of_int(width=8, 0xAD),
  )
  assert_word_extract(
    @types.Word::of_int(width=8, 1),
    hi=8,
    expected=@types.Word::of_uint64(width=9, 1),
  )
  assert_word_extract(
    @types.Word::of_int(width=8, 1),
    hi=15,
    lo=8,
    expected=@types.Word::zero(width=8),
  )
  assert_word_extract(
    @types.Word::of_int(width=8, -1).signed(),
    hi=15,
    expected=@types.Word::of_uint64(width=16, 0xffff),
  )
  assert_word_extract(
    @types.Word::of_int(width=8, -1).signed(),
    hi=15,
    lo=8,
    expected=@types.Word::of_uint64(width=8, 0xff),
  )
}

///|
fn byte_values(bytes : Bytes) -> Array[Int] {
  bytes.to_array().map(byte => byte.to_int())
}

///|
fn word_values(words : Array[@types.Word]) -> Array[Int] raise {
  let values = []
  for word in words {
    values.push(word.to_int())
  }
  values
}

///|
test "translated BAP word byte enumeration preserves endian order for odd widths" {
  assert_true(
    byte_values(@types.Word::of_int(width=128, 1).to_bytes(endian=LittleEndian)) ==
    [
      for i in 0..<16 => if i == 0 { 1 } else { 0 }
    ],
  )
  assert_true(
    byte_values(@types.Word::of_int(width=128, 1).to_bytes(endian=BigEndian)) ==
    [
      for i in 0..<16 => if i == 15 { 1 } else { 0 }
    ],
  )
  assert_true(
    byte_values(@types.Word::of_int(width=13, 1).to_bytes(endian=LittleEndian)) ==
    [1, 0],
  )
  assert_true(
    byte_values(@types.Word::of_int(width=13, 1).to_bytes(endian=BigEndian)) ==
    [0, 1],
  )
  assert_true(
    byte_values(@types.Word::of_int(width=71, 1).to_bytes(endian=LittleEndian)) ==
    [
      for i in 0..<9 => if i == 0 { 1 } else { 0 }
    ],
  )
  assert_true(
    byte_values(@types.Word::of_int(width=71, 1).to_bytes(endian=BigEndian)) ==
    [
      for i in 0..<9 => if i == 8 { 1 } else { 0 }
    ],
  )
  let deadbeef = @types.Word::of_uint64(width=32, 0xDEADBEEF)
  assert_true(
    byte_values(deadbeef.to_bytes(endian=LittleEndian)) ==
    [0xEF, 0xBE, 0xAD, 0xDE],
  )
  assert_true(
    byte_values(deadbeef.to_bytes(endian=BigEndian)) == [0xDE, 0xAD, 0xBE, 0xEF],
  )
}

///|
test "word enum aliases expose BAP byte and bit order" {
  let value = @types.Word::of_uint64(width=16, 0x0102)
  assert_true(byte_values(value.enum_chars(endian=BigEndian)) == [0x01, 0x02])
  assert_true(
    byte_values(value.enum_chars(endian=LittleEndian)) == [0x02, 0x01],
  )
  assert_true(word_values(value.enum_bytes(endian=BigEndian)) == [0x01, 0x02])
  assert_true(
    word_values(value.enum_bytes(endian=LittleEndian)) == [0x02, 0x01],
  )
  assert_true(
    value.enum_bits(endian=BigEndian) ==
    [
      false, false, false, false, false, false, false, true, false, false, false,
      false, false, false, true, false,
    ],
  )
  assert_true(
    value.enum_bits(endian=LittleEndian) ==
    [
      false, false, false, false, false, false, true, false, false, false, false,
      false, false, false, false, true,
    ],
  )
}

///|
test "word literals preserve BAP signedness and display" {
  inspect(@types.Word::b0().to_string(), content="0:1u")
  inspect(@types.Word::b1().to_string(), content="1:1u")
  inspect(@types.Word::of_int(width=4, 7).to_string(), content="7:4u")
  inspect(@types.Word::of_int(width=2, 7).to_string(), content="3:2u")
  inspect(@types.Word::of_int(width=3, -1).to_string(), content="7:3u")
  let signed_minus_one = @types.Word::of_int(width=3, -1).signed()
  inspect(signed_minus_one.to_string(), content="-1:3s")
  assert_true(signed_minus_one.is_signed())
  assert_true(signed_minus_one.is_negative())
  assert_true(signed_minus_one.is_non_positive())
  assert_true(!signed_minus_one.is_positive())
  let parsed_signed = @types.Word::from_string("7:3s")
  assert_true(parsed_signed.is_signed())
  inspect(parsed_signed.to_string(), content="-1:3s")
  assert_true(@types.Word::from_string("-1:3").to_string() == "7:3u")
  inspect(@types.Word::of_int(width=8, 42).to_string(), content="0x2A:8u")
}

///|
test "word signedness predicates match BAP validation cases" {
  let zero32 = @types.Word::zero(width=32)
  let zero64 = @types.Word::zero(width=64)
  let deadbeef32 = @types.Word::of_uint64(width=32, 0xDEADBEEF)
  let deadbeef64 = @types.Word::of_uint64(width=64, 0xDEADBEEF)
  assert_true(@types.Word::b0().is_zero())
  assert_true(!@types.Word::b0().is_one())
  assert_true(@types.Word::b1().is_one())
  assert_true(@types.Word::b1().is_positive())
  assert_true(@types.Word::b1().is_non_negative())
  assert_true(@types.Word::b0().is_non_negative())
  assert_true(@types.Word::b0().is_non_positive())
  assert_true(@types.Word::b1().neg().is_positive())
  assert_true(@types.Word::b1().neg().signed().is_negative())
  assert_true(@types.Word::b1().signed().is_negative())
  assert_true(deadbeef32.compare_unsigned(zero32) > 0)
  assert_true(deadbeef32.is_positive())
  assert_true(deadbeef32.neg().is_positive())
  assert_true(deadbeef32.neg().signed().is_positive())
  assert_true(deadbeef64.compare_unsigned(zero64) > 0)
  assert_true(deadbeef64.neg().is_positive())
  assert_true(deadbeef64.neg().signed().is_negative())
  assert_true(@types.Word::b1().validate_positive() == Ok(()))
  assert_true(@types.Word::b1().validate_non_negative() == Ok(()))
  assert_true(@types.Word::b0().validate_non_negative() == Ok(()))
  assert_true(@types.Word::b0().validate_non_positive() == Ok(()))
  assert_true(
    @types.Word::b0().validate_positive() == Err("expects a positive number"),
  )
  assert_true(
    @types.Word::b1().validate_negative() == Err("expects a negative number"),
  )
  assert_true(@types.Word::b1().neg().validate_positive() == Ok(()))
  assert_true(@types.Word::b1().neg().signed().validate_negative() == Ok(()))
  assert_true(deadbeef32.validate_positive() == Ok(()))
  assert_true(deadbeef32.neg().validate_positive() == Ok(()))
  assert_true(deadbeef32.neg().signed().validate_positive() == Ok(()))
  assert_true(deadbeef64.neg().signed().validate_negative() == Ok(()))
}

///|
test "word integer conversions follow BAP signedness" {
  let x = @types.Word::of_int(width=8, -6)
  assert_true(x.to_int() == 250)
  assert_true(x.signed().to_int() == -6)
  assert_true(x.to_int32() == 250)
  assert_true(x.signed().to_int32() == -6)
  assert_true(x.to_int64() == 250L)
  assert_true(x.signed().to_int64() == -6L)
  let all32 = @types.Word::of_uint64(width=32, 0xffffffff)
  assert_true(all32.to_int32() == -1)
  try all32.to_int() catch {
    InvalidWidth(_) => ()
    _ => fail("expected InvalidWidth")
  } noraise {
    _ => fail("expected InvalidWidth")
  }
  let signed_min32 = @types.Word::of_uint64(width=32, 0x80000000).signed()
  assert_true(signed_min32.to_int() == 0x80000000)
  assert_true(signed_min32.to_int32() == 0x80000000)
  assert_true(signed_min32.to_int64() == -2147483648L)
  let all64 = @types.Word::of_uint64(width=64, 0xffffffffffffffff)
  assert_true(all64.to_int64() == -1L)
  try all64.to_int32() catch {
    InvalidWidth(_) => ()
    _ => fail("expected InvalidWidth")
  } noraise {
    _ => fail("expected InvalidWidth")
  }
  assert_true(all64.signed().to_int32() == -1)
  let signed_min64 = @types.Word::of_uint64(width=64, 0x8000000000000000).signed()
  try signed_min64.to_int32() catch {
    InvalidWidth(_) => ()
    _ => fail("expected InvalidWidth")
  } noraise {
    _ => fail("expected InvalidWidth")
  }
}

///|
test "size helpers mirror BAP fixed word and address sizes" {
  assert_true(@types.Size::of_int_opt(8) == Some(R8))
  assert_true(@types.Size::of_int_opt(256) == Some(R256))
  assert_true(@types.Size::of_int_opt(24) == None)
  assert_true(@types.Size::of_int_exn(32) == R32)
  assert_true(@types.Size::R64.in_bits() == 64)
  assert_true(@types.Size::R64.in_bytes() == 8)
  assert_true(@types.Size::R128.to_string() == "u128")
  assert_true(@types.Size::addr_of_int_opt(32) == Some(Addr32))
  assert_true(@types.Size::addr_of_int_opt(16) == None)
  assert_true(@types.Size::addr_of_int_exn(64) == Addr64)
  assert_true(@types.Size::R64.to_addr_size_exn() == Addr64)
  assert_true(@types.Size::R8.to_addr_size_opt() == None)
  assert_true(@types.AddrSize::Addr32.to_size() == R32)
  assert_true(@types.WordSize::W64.to_size() == R64)
  assert_true(@types.Size::addr_of_word_size(W32) == Addr32)
  assert_true(@types.Size::word_of_addr_size(Addr64) == W64)
  try @types.Size::of_int_exn(24) catch {
    UnsupportedWordSize(24) => ()
    _ => fail("expected UnsupportedWordSize")
  } noraise {
    _ => fail("expected UnsupportedWordSize")
  }
  try @types.Size::R8.to_addr_size_exn() catch {
    UnsupportedAddressSizeValue(R8) => ()
    _ => fail("expected UnsupportedAddressSizeValue")
  } noraise {
    _ => fail("expected UnsupportedAddressSizeValue")
  }
}

///|
test "arch helpers mirror BAP normalization size and endian cases" {
  assert_true(@types.Arch::of_string(" i686 ") == Some(X86))
  assert_true(@types.Arch::of_string("amd64") == Some(X86_64))
  assert_true(@types.Arch::of_string("arm") == Some(Armv7))
  assert_true(@types.Arch::of_string("thumbeb") == Some(Thumbv7eb))
  assert_true(@types.Arch::of_string("powerpc64le") == Some(Ppc64le))
  assert_true(@types.Arch::of_string("sparc64") == Some(Sparcv9))
  assert_true(@types.Arch::of_string("s390x") == Some(Systemz))
  assert_true(@types.Arch::of_string("arm64_be") == Some(Aarch64_be))
  assert_true(@types.Arch::of_string("not-an-arch") == None)
  assert_true(@types.Arch::X86.to_string() == "i386")
  assert_true(@types.Arch::Ppc64.to_string() == "powerpc64")
  assert_true(@types.Arch::Systemz.to_string() == "s390x")
  assert_true(@types.Arch::X86.addr_size() == Addr32)
  assert_true(@types.Arch::Aarch64.addr_size() == Addr64)
  assert_true(@types.Arch::Mips64.endian() == BigEndian)
  assert_true(@types.Arch::Mips64el.endian() == LittleEndian)
  assert_true(@types.Arch::Thumbv7eb.endian() == BigEndian)
  assert_true(@types.Arch::UnknownArch.addr_size() == Addr32)
}

///|
test "value types expose BAP size-based constructors" {
  assert_true(@types.ValueType::bool_t() == Imm(1))
  assert_true(@types.ValueType::reg8_t() == Imm(8))
  assert_true(@types.ValueType::reg32_t() == Imm(32))
  assert_true(@types.ValueType::reg256_t() == Imm(256))
  assert_true(@types.ValueType::reg(R128) == Imm(128))
  let mem32 = @types.ValueType::mem32_t(R8)
  let mem64 = @types.ValueType::mem64_t(R256)
  assert_true(mem32 == Mem(addr_width=32, value_width=8))
  assert_true(mem64 == Mem(addr_width=64, value_width=256))
  assert_true(mem32.addr_size() == Some(Addr32))
  assert_true(mem32.value_size() == Some(R8))
  assert_true(@types.ValueType::reg64_t().addr_size() == None)
  assert_true(@types.ValueType::reg64_t().value_size() == Some(R64))
}

///|
test "value types and variables keep BAP-visible metadata" {
  let typ = @types.ValueType::Imm(8)
  let physical = @types.Var::new(name="r0", typ~)
  let virtual_var = @types.Var::new(name="tmp", typ~, is_virtual=true)
  assert_true(physical.name() == "r0")
  assert_true(physical.typ() == typ)
  assert_true(physical.is_physical())
  assert_true(!physical.is_virtual())
  assert_true(virtual_var.is_virtual())
  assert_true(!virtual_var.is_physical())
  inspect(typ.to_string(), content="imm8")
  inspect(physical.to_string(), content="r0:imm8")
  inspect(virtual_var.to_string(), content="%tmp:imm8")
}

///|
test "variables expose BAP-style SSA indices" {
  let typ = @types.ValueType::Imm(32)
  let base = @types.Var::new(name="r0", typ~)
  let indexed = base.with_index(7)
  inspect(indexed.name(), content="r0#7")
  assert_true(indexed.index() == 7)
  assert_true(indexed.base() == base)
  assert_true(indexed.same(base.with_index(9)))
  assert_true(!indexed.same(@types.Var::new(name="r1", typ~)))
  assert_true(indexed.with_index(0) == base)
  assert_true(indexed.with_index(-1) == base)
  let virtual_var = @types.Var::new(name="tmp#12", typ~, is_virtual=true)
  assert_true(virtual_var.index() == 12)
  assert_true(virtual_var.base().name() == "tmp")
  assert_true(virtual_var.base().is_virtual())
  let literal_hash = @types.Var::new(name="flag#hi", typ~)
  assert_true(literal_hash.index() == 0)
  assert_true(literal_hash.base() == literal_hash)
}

///|
test "bil expressions infer simple result types and render" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let exp = @types.Exp::BinOp(
    Plus,
    Var(x),
    Int(@types.Word::of_int(width=8, 1)),
  )
  inspect(exp.type_of().to_string(), content="imm8")
  inspect(exp.to_string(), content="(x:imm8 + 1:8u)")
  let cmp = @types.Exp::BinOp(Eq, exp, Int(@types.Word::of_int(width=8, 2)))
  inspect(cmp.type_of().to_string(), content="imm1")
}

///|
test "bil operators expose BAP compatibility metadata" {
  assert_true(@types.BinOp::Plus.is_commutative())
  assert_true(@types.BinOp::Eq.is_commutative())
  assert_true(!@types.BinOp::Minus.is_commutative())
  assert_true(@types.BinOp::Xor.is_associative())
  assert_true(!@types.BinOp::Eq.is_associative())
  assert_true(@types.BinOp::SignedDiv.string_of_binop() == "/$")
  assert_true(@types.BinOp::SignedMod.string_of_binop() == "%$")
  assert_true(@types.BinOp::ARShift.string_of_binop() == "~>>")
  assert_true(@types.BinOp::Eq.string_of_binop() == "=")
  assert_true(@types.BinOp::Neq.string_of_binop() == "<>")
  assert_true(@types.BinOp::SignedLt.string_of_binop() == "<$")
  assert_true(@types.BinOp::SignedLe.string_of_binop() == "<=$")
  assert_true(@types.UnOp::Not.string_of_unop() == "~")
  assert_true(@types.UnOp::Neg.string_of_unop() == "-")
}

///|
test "bil apply helpers expose BAP word operator behavior" {
  let narrow = @types.Word::of_int(width=8, 0xff)
  let wide_one = @types.Word::of_int(width=16, 1)
  match @types.BinOp::Plus.apply(narrow, wide_one) {
    Ok(word) => inspect(word.to_hex(), content="0x0100")
    Err(reason) => fail(reason)
  }
  match @types.BinOp::Eq.apply(@types.Word::of_int(width=8, 1), wide_one) {
    Ok(word) => assert_true(word == @types.Word::b1())
    Err(reason) => fail(reason)
  }
  match
    @types.BinOp::SignedDiv.apply(
      @types.Word::of_int(width=8, -2),
      @types.Word::of_int(width=8, 2),
    ) {
    Ok(word) => inspect(word.to_hex(), content="0xff")
    Err(reason) => fail(reason)
  }
  match
    @types.BinOp::LShift.apply(
      @types.Word::of_int(width=8, 1),
      @types.Word::of_int(width=8, 2),
    ) {
    Ok(word) => inspect(word.to_hex(), content="0x04")
    Err(reason) => fail(reason)
  }
  match @types.UnOp::Not.apply(@types.Word::of_int(width=8, 0x55)) {
    Ok(word) => inspect(word.to_hex(), content="0xaa")
    Err(reason) => fail(reason)
  }
}

///|
test "bil expressions and statements expose BAP-style constructors" {
  let word = @types.Word::of_int(width=8, 1)
  let imm8 = @types.ValueType::Imm(8)
  let mem_typ = @types.ValueType::mem32_t(R8)
  let x = @types.Var::new(name="x", typ=imm8)
  let mem = @types.Var::new(name="mem", typ=mem_typ)
  let value = @types.Exp::int(word)
  let mem_exp = @types.Exp::var_exp(mem)
  let addr = @types.Exp::var_exp(x)
  assert_true(@types.Exp::var_exp(x) == Var(x))
  assert_true(@types.Exp::binop(Plus, value, addr) == BinOp(Plus, value, addr))
  assert_true(@types.Exp::unop(Not, addr) == UnOp(Not, addr))
  assert_true(@types.Exp::let_(x, value, addr) == Let(x, value, addr))
  assert_true(@types.Exp::unknown("u", imm8) == Unknown("u", imm8))
  assert_true(
    @types.Exp::cast(Unsigned, 16, value) ==
    Cast(kind=Unsigned, width=16, exp=value),
  )
  inspect(@types.Unsigned.to_string(), content="pad")
  inspect(@types.Signed.to_string(), content="extend")
  inspect(@types.High.to_string(), content="high")
  inspect(@types.Low.to_string(), content="low")
  assert_true(
    @types.Exp::extract(value, hi=3, lo=0) == Extract(hi=3, lo=0, exp=value),
  )
  assert_true(@types.Exp::concat(value, addr) == Concat(high=value, low=addr))
  assert_true(
    @types.Exp::ite(if_=value, then_=addr, else_=mem_exp) ==
    Ite(cond=value, yes=addr, no=mem_exp),
  )
  assert_true(
    @types.Exp::load(mem=mem_exp, addr~, LittleEndian, R16) ==
    Load(mem=mem_exp, addr~, endian=LittleEndian, typ=Imm(16)),
  )
  assert_true(
    @types.Exp::load_byte(mem=mem_exp, addr~) ==
    Load(mem=mem_exp, addr~, endian=BigEndian, typ=Imm(8)),
  )
  assert_true(
    @types.Exp::store(mem=mem_exp, addr~, value, BigEndian, R8) ==
    Store(mem=mem_exp, addr~, value~, endian=BigEndian),
  )
  assert_true(
    @types.Exp::store_byte(mem=mem_exp, addr~, value) ==
    Store(mem=mem_exp, addr~, value~, endian=BigEndian),
  )
  assert_true(@types.Stmt::move_stmt(x, value) == Move(x, value))
  assert_true(@types.Stmt::jmp(addr) == Jmp(addr))
  assert_true(@types.Stmt::special("halt") == Special("halt"))
  assert_true(@types.Stmt::cpuexn(13) == CpuExn(13))
  assert_true(
    @types.Stmt::while_(value, [@types.Stmt::jmp(addr)]) ==
    While(cond=value, body=[@types.Stmt::jmp(addr)]),
  )
  assert_true(
    @types.Stmt::if_(value, [@types.Stmt::jmp(addr)], []) ==
    If(cond=value, yes=[@types.Stmt::jmp(addr)], no=[]),
  )
}

///|
test "bil checked type inference mirrors BAP error cases" {
  let imm1 = @types.ValueType::Imm(1)
  let imm4 = @types.ValueType::Imm(4)
  let imm8 = @types.ValueType::Imm(8)
  let imm16 = @types.ValueType::Imm(16)
  let imm32 = @types.ValueType::Imm(32)
  let mem32 = @types.ValueType::mem32_t(R8)
  let flag = @types.Var::new(name="flag", typ=imm1)
  let x = @types.Var::new(name="x", typ=imm8)
  let y = @types.Var::new(name="y", typ=imm16)
  let addr = @types.Var::new(name="addr", typ=imm32)
  let mem = @types.Var::new(name="mem", typ=mem32)
  let mem_exp = @types.Exp::var_exp(mem)
  let addr_exp = @types.Exp::var_exp(addr)
  let x_exp = @types.Exp::var_exp(x)
  assert_true(
    @types.Exp::load(mem=mem_exp, addr=addr_exp, LittleEndian, R16).infer_type() ==
    Ok(imm16),
  )
  assert_true(
    @types.Exp::store(mem=mem_exp, addr=addr_exp, x_exp, BigEndian, R8).infer_type() ==
    Ok(mem32),
  )
  assert_true(@types.Exp::binop(Eq, x_exp, x_exp).infer_type() == Ok(imm1))
  assert_true(
    @types.Exp::binop(LShift, x_exp, addr_exp).infer_type() == Ok(imm8),
  )
  assert_true(@types.Exp::cast(Unsigned, 16, x_exp).infer_type() == Ok(imm16))
  assert_true(@types.Exp::cast(Signed, 16, x_exp).infer_type() == Ok(imm16))
  assert_true(@types.Exp::cast(Low, 4, x_exp).infer_type() == Ok(imm4))
  assert_true(@types.Exp::cast(High, 16, x_exp).infer_type() == Err(BadCast))
  assert_true(@types.Exp::cast(Unsigned, 0, x_exp).infer_type() == Err(BadCast))
  assert_true(
    @types.Exp::cast(Unsigned, 8, mem_exp).infer_type() == Err(BadKind(ImmKind)),
  )
  assert_true(
    @types.Exp::binop(Plus, x_exp, @types.Exp::var_exp(y)).infer_type() ==
    Err(BadType(expected=imm8, got=imm16)),
  )
  assert_true(
    @types.Exp::load(mem=x_exp, addr=addr_exp, LittleEndian, R8).infer_type() ==
    Err(BadKind(MemKind)),
  )
  assert_true(
    @types.Exp::load(mem=mem_exp, addr=x_exp, LittleEndian, R8).infer_type() ==
    Err(BadType(expected=imm32, got=imm8)),
  )
  assert_true(
    @types.Exp::ite(if_=x_exp, then_=x_exp, else_=x_exp).infer_type() ==
    Err(BadType(expected=imm1, got=imm8)),
  )
  let bad_value = @types.Var::new(name="wide", typ=Imm(24))
  assert_true(
    @types.Exp::store(
      mem=mem_exp,
      addr=addr_exp,
      @types.Exp::var_exp(bad_value),
      BigEndian,
      R8,
    ).infer_type() ==
    Err(BadCast),
  )
  assert_true(@types.Stmt::move_stmt(x, x_exp).check_type() == Ok(()))
  assert_true(
    @types.Stmt::move_stmt(x, @types.Exp::var_exp(y)).check_type() ==
    Err(BadType(expected=imm8, got=imm16)),
  )
  assert_true(@types.Stmt::jmp(addr_exp).check_type() == Ok(()))
  assert_true(@types.Stmt::jmp(mem_exp).check_type() == Err(BadKind(ImmKind)))
  assert_true(
    @types.check_stmt_types([
      @types.Stmt::if_(
        @types.Exp::var_exp(flag),
        [@types.Stmt::jmp(addr_exp)],
        [],
      ),
    ]) ==
    Ok(()),
  )
  inspect(
    @types.TypeError::bad_type(expected=imm8, got=imm16).to_string(),
    content="expected value of type imm8, but got imm16",
  )
}

///|
test "bil expression effects mirror BAP read load store and raise approximations" {
  let imm8 = @types.ValueType::Imm(8)
  let mem32 = @types.ValueType::mem32_t(R8)
  let x = @types.Var::new(name="x", typ=imm8)
  let addr = @types.Var::new(name="addr", typ=Imm(32))
  let mem = @types.Var::new(name="mem", typ=mem32)
  let x_exp = @types.Exp::var_exp(x)
  let addr_exp = @types.Exp::var_exp(addr)
  let mem_exp = @types.Exp::var_exp(mem)
  let none = @types.ExpEffect::none()
  assert_true(none.idempotent())
  assert_true(!none.has_effects())
  assert_true(!none.has_coeffects())
  let read = x_exp.effect()
  assert_true(read.reads())
  assert_true(read.has_coeffects())
  assert_true(!read.has_effects())
  let load_exp = @types.Exp::load(mem=mem_exp, addr=addr_exp, LittleEndian, R8)
  let load_effect = load_exp.effect()
  assert_true(load_effect.reads())
  assert_true(load_effect.loads())
  assert_true(load_effect.raises())
  assert_true(load_effect.has_effects())
  assert_true(load_effect.has_coeffects())
  let store = @types.Exp::store(
    mem=mem_exp,
    addr=addr_exp,
    x_exp,
    BigEndian,
    R8,
  ).effect()
  assert_true(store.reads())
  assert_true(store.stores())
  assert_true(store.raises())
  assert_true(store.has_effects())
  let zero = @types.Exp::int(@types.Word::zero(width=8))
  let one = @types.Exp::int(@types.Word::one(width=8))
  assert_true(@types.Exp::binop(Div, x_exp, zero).effect().raises())
  assert_true(!@types.Exp::binop(Div, x_exp, one).effect().raises())
  assert_true(@types.Exp::binop(Div, x_exp, addr_exp).effect().raises())
  let nonzero_or = @types.Exp::binop(Or, zero, one)
  assert_true(!@types.Exp::binop(Mod, x_exp, nonzero_or).effect().raises())
  assert_true(@types.Exp::unknown("opaque", imm8).effect().idempotent())
  assert_true(
    @types.ExpEffect::compute(@types.Exp::let_(x, load_exp, x_exp)) ==
    load_effect.join(read),
  )
}

///|
test "bil statements expose definitions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let stmt = @types.Stmt::Move(x, Int(@types.Word::of_int(width=8, 42)))
  assert_true(stmt.defined_var().map(v => v.name) == Some("x"))
  inspect(stmt.to_string(), content="x:imm8 := 0x2A:8u")
}
