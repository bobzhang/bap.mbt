///|
test "bil free variables respect let binding" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let exp = @types.Let(x, Var(y), BinOp(Plus, Var(x), Var(y)))
  let vars = exp.free_vars()
  assert_true(vars.length() == 1)
  assert_true(vars[0] == y)
}

///|
test "bil substitution avoids replacing let-bound variables" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let one = @types.Int(@types.Word::of_int(width=8, 1))
  let exp = @types.Let(x, Var(y), BinOp(Plus, Var(x), Var(y)))
  let substituted = exp.substitute_var(x, one)
  inspect(
    substituted.to_string(),
    content="let x:imm8 = y:imm8 in (x:imm8 + y:imm8)",
  )
  let replaced_y = exp.substitute_var(y, one)
  inspect(
    replaced_y.to_string(),
    content="let x:imm8 = 0x01:8u in (x:imm8 + 0x01:8u)",
  )
}

///|
test "bil eval folds scalar arithmetic comparisons and conditionals" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let env : Map[String, @types.Word] = { "x": @types.Word::of_int(width=8, 7) }
  let exp = @types.BinOp(
    Times,
    BinOp(Plus, Var(x), Int(@types.Word::of_int(width=8, 1))),
    Int(@types.Word::of_int(width=8, 3)),
  )
  match exp.eval(env) {
    Ok(word) => inspect(word.to_hex(), content="0x18")
    Err(reason) => fail(reason)
  }
  let cmp = @types.BinOp(
    SignedLt,
    Int(@types.Word::of_int(width=8, -1)),
    Var(x),
  )
  match cmp.eval(env) {
    Ok(word) => assert_true(word == @types.Word::b1())
    Err(reason) => fail(reason)
  }
  let branch = @types.Ite(
    cond=cmp,
    yes=Int(@types.Word::of_int(width=8, 0xaa)),
    no=Int(@types.Word::of_int(width=8, 0xbb)),
  )
  match branch.eval(env) {
    Ok(word) => inspect(word.to_hex(), content="0xaa")
    Err(reason) => fail(reason)
  }
}

///|
test "statement helpers expose used variables and substitute expressions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let stmt = @types.Stmt::Move(x, BinOp(Plus, Var(y), Int(@types.Word::b1())))
  let vars = stmt.free_vars()
  assert_true(vars.any(item => item == x))
  assert_true(vars.any(item => item == y))
  let next = stmt.substitute_var(y, Int(@types.Word::of_int(width=8, 9)))
  inspect(next.to_string(), content="x:imm8 := (0x09:8u + 0x1:1u)")
}
