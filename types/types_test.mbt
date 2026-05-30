///|
test "word wraps bitvec operations" {
  let high = @types.Word::of_int(width=16, 0xdead)
  let low = @types.Word::of_int(width=16, 0xbeef)
  inspect(high.concat(low).to_hex(), content="0xdeadbeef")
  assert_true(@types.Word::from_string("true") == @types.Word::b1())
  inspect(@types.Word::from_string("7:2").to_hex(), content="0x3")
  inspect(
    @types.Word::from_bytes(b"\xef\xbe\xad\xde", endian=LittleEndian).to_hex(),
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
