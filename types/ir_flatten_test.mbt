///|
fn flat_int8(value : Int32) -> @types.Exp raise @bitvec.BitVecError {
  Int(@types.Word::of_int(width=8, value))
}

///|
test "flatten block materializes nested definition expressions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let rhs : @types.Exp = BinOp(
    Xor,
    BinOp(Plus, Var(x), flat_int8(1)),
    flat_int8(2),
  )
  let def = @types.Def::create(y, rhs)
  let blk = @types.Blk::create(defs=[def]).flatten_blk()
  let defs = blk.defs()
  assert_true(defs.length() == 3)
  let first_tmp = defs[0].lhs()
  let second_tmp = defs[1].lhs()
  assert_true(first_tmp.is_virtual)
  assert_true(second_tmp.is_virtual)
  assert_true(defs[0].rhs() == BinOp(Plus, Var(x), flat_int8(1)))
  assert_true(defs[1].rhs() == BinOp(Xor, Var(first_tmp), flat_int8(2)))
  assert_true(defs[2].tid() == def.tid())
  assert_true(defs[2].lhs() == y)
  assert_true(defs[2].rhs() == Var(second_tmp))
}

///|
test "flatten block materializes jump condition and indirect target expressions" {
  let typ = @types.ValueType::Imm(8)
  let flag = @types.Var::new(name="flag", typ~)
  let target = @types.Var::new(name="target", typ~)
  let cond : @types.Exp = BinOp(Eq, Var(flag), flat_int8(0))
  let label = @types.Label::indirect(BinOp(Plus, Var(target), flat_int8(4)))
  let jmp = @types.Jmp::create_goto(label, cond~)
  let blk = @types.Blk::create(jmps=[jmp]).flatten_blk()
  let defs = blk.defs()
  let jmps = blk.jmps()
  assert_true(defs.length() == 2)
  assert_true(jmps.length() == 1)
  assert_true(defs[0].rhs() == cond)
  assert_true(defs[1].rhs() == BinOp(Plus, Var(target), flat_int8(4)))
  assert_true(jmps[0].cond() == Var(defs[0].lhs()))
  match jmps[0].kind() {
    Goto(Indirect(Var(target_tmp))) => assert_true(target_tmp == defs[1].lhs())
    _ => fail("expected indirect goto through flattened target")
  }
}

///|
test "flatten sub maps all blocks" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let left = @types.Blk::create(tid=@types.Tid::for_name("left")).append_def(
    @types.Def::create(y, BinOp(Plus, Var(x), flat_int8(1))),
  )
  let right = @types.Blk::create(tid=@types.Tid::for_name("right")).append_jmp(
    @types.Jmp::create_goto(
      @types.Label::indirect(BinOp(Xor, Var(x), flat_int8(2))),
    ),
  )
  let sub = @types.Sub::create(name="flat", blks=[left, right]).flatten_sub()
  let left = sub.find_blk(left.tid()).unwrap()
  let right = sub.find_blk(right.tid()).unwrap()
  assert_true(left.defs().length() == 2)
  assert_true(right.defs().length() == 1)
}
