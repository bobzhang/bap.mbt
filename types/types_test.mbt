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
test "bil statements expose definitions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let stmt = @types.Stmt::Move(x, Int(@types.Word::of_int(width=8, 42)))
  assert_true(stmt.defined_var().map(v => v.name) == Some("x"))
  inspect(stmt.to_string(), content="x:imm8 := 0x2A:8u")
}
