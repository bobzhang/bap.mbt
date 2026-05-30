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
test "value types and variables keep BAP-visible metadata" {
  let typ = @types.ValueType::Imm(8)
  let physical = @types.Var::new(name="r0", typ~)
  let virtual_var = @types.Var::new(name="tmp", typ~, is_virtual=true)
  inspect(typ.to_string(), content="imm8")
  inspect(physical.to_string(), content="r0:imm8")
  inspect(virtual_var.to_string(), content="%tmp:imm8")
}

///|
test "variables expose BAP-style SSA indices" {
  let typ = @types.ValueType::Imm(32)
  let base = @types.Var::new(name="r0", typ~)
  let indexed = base.with_index(7)
  inspect(indexed.name, content="r0#7")
  assert_true(indexed.index() == 7)
  assert_true(indexed.base() == base)
  assert_true(indexed.with_index(0) == base)
  assert_true(indexed.with_index(-1) == base)
  let virtual_var = @types.Var::new(name="tmp#12", typ~, is_virtual=true)
  assert_true(virtual_var.index() == 12)
  assert_true(virtual_var.base().name == "tmp")
  assert_true(virtual_var.base().is_virtual)
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
