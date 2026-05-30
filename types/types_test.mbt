///|
test "word wraps bitvec operations" {
  let high = @types.Word::of_int(width=16, 0xdead)
  let low = @types.Word::of_int(width=16, 0xbeef)
  inspect(high.concat(low).to_hex(), content="0xdeadbeef")
  inspect(
    @types.Word::from_bytes(b"\xef\xbe\xad\xde", endian=LittleEndian).to_hex(),
    content="0xdeadbeef",
  )
  inspect(
    @types.Word::of_int(width=8, 0xff).add(@types.Word::one(width=8)).to_hex(),
    content="0x00",
  )
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
test "bil expressions infer simple result types and render" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let exp = @types.Exp::BinOp(
    Plus,
    Var(x),
    Int(@types.Word::of_int(width=8, 1)),
  )
  inspect(exp.type_of().to_string(), content="imm8")
  inspect(exp.to_string(), content="(x:imm8 + 0x01:8u)")
  let cmp = @types.Exp::BinOp(Eq, exp, Int(@types.Word::of_int(width=8, 2)))
  inspect(cmp.type_of().to_string(), content="imm1")
}

///|
test "bil statements expose definitions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let stmt = @types.Stmt::Move(x, Int(@types.Word::of_int(width=8, 42)))
  assert_true(stmt.defined_var().map(v => v.name) == Some("x"))
  inspect(stmt.to_string(), content="x:imm8 := 0x2a:8u")
}
