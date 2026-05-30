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
    content="let x:imm8 = 1:8u in (x:imm8 + 1:8u)",
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
fn word32(value : UInt64) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::of_uint64(width=32, value)
}

///|
fn word8(value : UInt64) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::of_uint64(width=8, value)
}

///|
fn word16(value : UInt64) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::of_uint64(width=16, value)
}

///|
fn assert_eval_word(
  exp : @types.Exp,
  env : Map[String, @types.BilValue],
  expected : @types.Word,
) -> Unit raise {
  match exp.eval_value(env) {
    Ok(BilWord(word)) => assert_true(word == expected)
    Ok(BilMem(_)) => fail("expected scalar value")
    Err(reason) => fail(reason)
  }
}

///|
test "bil eval handles byte-addressed load and store expressions" {
  let mem_typ = @types.ValueType::Mem(addr_width=32, value_width=8)
  let mem = @types.Var::new(name="mem", typ=mem_typ)
  let env : Map[String, @types.BilValue] = {
    "mem": BilMem(@types.BilMemory::empty(addr_width=32)),
  }
  let addr0 = @types.Int(word32(0))
  let addr1 = @types.Int(word32(1))
  let data = @types.Int(word32(0xdeadbeef))
  assert_true(
    @types.Exp::Load(mem=Var(mem), addr=addr0, endian=LittleEndian, typ=Imm(32)).eval_value(
      env,
    )
    is Err(_),
  )
  let stored = @types.Exp::Store(
    mem=Var(mem),
    addr=addr0,
    value=data,
    endian=LittleEndian,
  )
  assert_eval_word(
    Load(mem=stored, addr=addr0, endian=LittleEndian, typ=Imm(32)),
    env,
    word32(0xdeadbeef),
  )
  assert_eval_word(
    Load(mem=stored, addr=addr0, endian=BigEndian, typ=Imm(32)),
    env,
    word32(0xefbeadde),
  )
  assert_eval_word(
    Load(mem=stored, addr=addr0, endian=BigEndian, typ=Imm(8)),
    env,
    word8(0xef),
  )
  assert_eval_word(
    Load(mem=stored, addr=addr1, endian=LittleEndian, typ=Imm(8)),
    env,
    word8(0xbe),
  )
  assert_eval_word(
    Load(mem=stored, addr=addr1, endian=BigEndian, typ=Imm(16)),
    env,
    word16(0xbead),
  )
  assert_eval_word(
    Load(mem=stored, addr=addr1, endian=LittleEndian, typ=Imm(16)),
    env,
    word16(0xadbe),
  )
}

///|
test "bil simplifier folds scalar constants and let bindings" {
  let three = @types.Int(word8(3))
  let eight = @types.Int(word8(8))
  let arithmetic = @types.BinOp(
    Div,
    BinOp(Plus, BinOp(Times, three, eight), three),
    three,
  )
  assert_true(arithmetic.simplify() == Int(word8(9)))
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let let_exp = @types.Let(x, Int(word8(2)), BinOp(Plus, Var(x), Int(word8(3))))
  assert_true(let_exp.simplify() == Int(word8(5)))
}

///|
test "bil BAP normalize negatives and fold const aliases" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let minus_one = @types.Int(@types.Word::of_int(width=8, -1).signed())
  let exp : @types.Exp = BinOp(Plus, Var(x), minus_one)
  inspect(exp.normalize_negatives().to_string(), content="(x:imm8 - 1:8u)")
  let nested = @types.Stmt::Move(y, BinOp(Plus, exp, Int(word8(2))))
  let normalized = @types.normalize_negatives([nested])
  inspect(
    normalized[0].to_string(),
    content="y:imm8 := ((x:imm8 - 1:8u) + 2:8u)",
  )
  let sum : @types.Exp = BinOp(Plus, Int(word8(1)), Int(word8(2)))
  assert_true(sum.fold_consts() == Int(word8(3)))
  let folded = @types.fold_consts([Move(y, sum)])
  inspect(folded[0].to_string(), content="y:imm8 := 3:8u")
}

///|
test "bil BAP fixpoint helpers iterate until stable" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let start_exp : @types.Exp = Unknown("start", typ)
  let middle_exp : @types.Exp = Unknown("middle", typ)
  let seven = @types.Int(word8(7))
  fn step_exp(exp : @types.Exp) -> @types.Exp {
    match exp {
      Unknown(name, _) if name == "start" => middle_exp
      Unknown(name, _) if name == "middle" => seven
      _ => exp
    }
  }
  assert_true(start_exp.fixpoint(step_exp) == seven)
  let start_stmt = @types.Stmt::Move(x, start_exp)
  fn step_stmt(stmt : @types.Stmt) -> @types.Stmt {
    match stmt {
      Move(variable, Unknown(name, _)) if name == "start" =>
        Move(variable, middle_exp)
      Move(variable, Unknown(name, _)) if name == "middle" =>
        Move(variable, seven)
      _ => stmt
    }
  }
  inspect(start_stmt.fixpoint(step_stmt).to_string(), content="x:imm8 := 7:8u")
  fn step_stmts(stmts : Array[@types.Stmt]) -> Array[@types.Stmt] {
    if stmts.length() == 1 {
      match stmts[0] {
        Move(variable, Unknown(name, _)) if name == "start" =>
          [Move(variable, middle_exp)]
        Move(variable, Unknown(name, _)) if name == "middle" =>
          [Move(variable, seven)]
        _ => stmts
      }
    } else {
      stmts
    }
  }
  let fixed = @types.fixpoint([start_stmt], step_stmts)
  inspect(fixed[0].to_string(), content="x:imm8 := 7:8u")
}

///|
test "bil simplifier folds loads from recent stores" {
  let mem_typ = @types.ValueType::Mem(addr_width=32, value_width=8)
  let mem = @types.Var::new(name="mem", typ=mem_typ)
  let addr0 = @types.Int(word32(0))
  let addr1 = @types.Int(word32(1))
  let addr4 = @types.Int(word32(4))
  let stored = @types.Store(
    mem=Var(mem),
    addr=addr0,
    value=Int(word32(0xdeadbeef)),
    endian=LittleEndian,
  )
  let load = @types.Load(mem=stored, addr=addr1, endian=BigEndian, typ=Imm(16))
  assert_true(load.simplify() == Int(word16(0xbead)))
  let later = @types.Store(
    mem=stored,
    addr=addr4,
    value=Int(word8(0xaa)),
    endian=LittleEndian,
  )
  let earlier = @types.Load(
    mem=later,
    addr=addr1,
    endian=BigEndian,
    typ=Imm(16),
  )
  assert_true(earlier.simplify() == Int(word16(0xbead)))
}

///|
test "bil simplifier prunes statically selected branches" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let branch = @types.Stmt::If(
    cond=Int(@types.Word::b0()),
    yes=[Move(x, Int(word8(1)))],
    no=[Move(x, Int(word8(2)))],
  )
  let simplified = @types.simplify_stmts([
    branch,
    While(cond=Int(@types.Word::b0()), body=[Move(x, Int(word8(3)))]),
  ])
  assert_true(simplified.length() == 1)
  match @types.exec_stmts(simplified) {
    Ok(state) => assert_true(state.get_word("x") == Some(word8(2)))
    Err(reason) => fail(reason)
  }
}

///|
test "bil statement execution updates scalar variables" {
  let typ = @types.ValueType::Imm(32)
  let a = @types.Var::new(name="a", typ~)
  let b = @types.Var::new(name="b", typ~)
  let result = @types.Var::new(name="result", typ~)
  let stmts = [
    @types.Stmt::Move(a, Int(word32(2))),
    Move(b, Int(word32(3))),
    Move(result, BinOp(Plus, Var(a), Var(b))),
  ]
  match @types.exec_stmts(stmts) {
    Ok(state) => assert_true(state.get_word("result") == Some(word32(5)))
    Err(reason) => fail(reason)
  }
}

///|
test "bil statement execution handles bounded loops" {
  let typ = @types.ValueType::Imm(32)
  let a = @types.Var::new(name="a", typ~)
  let result = @types.Var::new(name="result", typ~)
  let zero = @types.Int(word32(0))
  let one = @types.Int(word32(1))
  let loop_stmt = @types.Stmt::While(cond=BinOp(Lt, zero, Var(a)), body=[
    Move(a, BinOp(Minus, Var(a), one)),
    Move(result, BinOp(Plus, Var(result), one)),
  ])
  match
    @types.exec_stmts([Move(a, Int(word32(3))), Move(result, zero), loop_stmt]) {
    Ok(state) => assert_true(state.get_word("result") == Some(word32(3)))
    Err(reason) => fail(reason)
  }
  let infinite = @types.Stmt::While(cond=Int(@types.Word::b1()), body=[])
  assert_true(@types.exec_stmts([infinite], max_steps=3) is Err(_))
}

///|
test "translated BAP Bili statement tests handle let shadowing and collatz" {
  let typ = @types.ValueType::Imm(32)
  let a = @types.Var::new(name="a", typ~)
  let result = @types.Var::new(name="result", typ~)
  let shadow = @types.exec_stmts([
    Move(a, Int(word32(3))),
    Move(a, BinOp(Plus, Var(a), Let(a, Int(word32(2)), Var(a)))),
    Move(result, Var(a)),
  ])
  match shadow {
    Ok(state) => assert_true(state.get_word("result") == Some(word32(5)))
    Err(reason) => fail(reason)
  }
  let zero = @types.Int(word32(0))
  let one = @types.Int(word32(1))
  let two = @types.Int(word32(2))
  let three = @types.Int(word32(3))
  let collatz = @types.exec_stmts([
    Move(a, Int(word32(17))),
    Move(result, zero),
    While(cond=BinOp(Neq, one, Var(a)), body=[
      If(
        cond=BinOp(Eq, zero, BinOp(Mod, Var(a), two)),
        yes=[Move(a, BinOp(Div, Var(a), two))],
        no=[Move(a, BinOp(Plus, BinOp(Times, Var(a), three), one))],
      ),
      Move(result, BinOp(Plus, Var(result), one)),
    ]),
  ])
  match collatz {
    Ok(state) => assert_true(state.get_word("result") == Some(word32(12)))
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
  assert_true(!vars.any(item => item == x))
  assert_true(vars.any(item => item == y))
  let next = stmt.substitute_var(y, Int(@types.Word::of_int(width=8, 9)))
  inspect(next.to_string(), content="x:imm8 := (9:8u + 1:1u)")
}

///|
test "statement helpers mirror BAP reference and assignment predicates" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let one = @types.Int(word8(1))
  let top = @types.Stmt::Move(x, BinOp(Plus, Var(y), one))
  let branch = @types.Stmt::If(cond=Var(y), yes=[Move(z, Var(x))], no=[])
  let x_exp : @types.Exp = Var(x)
  let sum_exp : @types.Exp = BinOp(Plus, Var(y), one)
  assert_true(x_exp.is_referenced(x))
  assert_true(sum_exp.is_referenced(y))
  assert_true(top.is_referenced(y))
  assert_true(!top.is_referenced(x))
  assert_true(@types.is_referenced_stmts([top, branch], x))
  assert_true(top.is_assigned(x))
  assert_true(top.is_assigned(x, strict=true))
  assert_true(branch.is_assigned(z))
  assert_true(!branch.is_assigned(z, strict=true))
  assert_true(@types.is_assigned_stmts([top, branch], z))
  assert_true(!@types.is_assigned_stmts([top, branch], z, strict=true))
}

///|
test "statement-list helpers preserve BAP substitution and free-var semantics" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Var(y)),
    Move(z, BinOp(Plus, Var(x), Int(word8(1)))),
  ]
  assert_true(@types.free_vars(stmts) == [y])
  let target : @types.Exp = BinOp(Plus, Var(x), Int(word8(1)))
  let replaced = @types.substitute(stmts, target, Int(word8(4)))
  inspect(replaced[1].to_string(), content="z:imm8 := 4:8u")
  let killed = @types.substitute_var(stmts, x, Int(word8(9)))
  inspect(killed[0].to_string(), content="x:imm8 := y:imm8")
  inspect(killed[1].to_string(), content="z:imm8 := (x:imm8 + 1:8u)")
  let branch = [
    @types.Stmt::If(cond=Var(y), yes=[Move(x, Var(y)), Move(z, Var(x))], no=[]),
    Move(z, Var(x)),
  ]
  let branch_sub = @types.substitute_var(branch, x, Int(word8(9)))
  match branch_sub[0] {
    If(yes~, ..) => inspect(yes[1].to_string(), content="z:imm8 := x:imm8")
    _ => fail("expected branch")
  }
  inspect(branch_sub[1].to_string(), content="z:imm8 := 9:8u")
}
