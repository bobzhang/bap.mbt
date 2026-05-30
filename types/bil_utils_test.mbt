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
test "bil extract and concat expressions mirror BAP word operations" {
  let high = @types.Int(word16(0xDEAD))
  let low = @types.Int(word16(0xBEEF))
  let concat = @types.Exp::concat(high, low)
  assert_true(concat.type_of() == Imm(32))
  assert_true(concat.infer_type() == Ok(Imm(32)))
  assert_true(concat.simplify() == Int(word32(0xDEADBEEF)))
  assert_eval_word(concat, Map([]), word32(0xDEADBEEF))
  let source = @types.Int(@types.Word::of_int(width=16, 0xDAD5))
  let extract = @types.Exp::extract(source, hi=0xB, lo=0x4)
  assert_true(extract.type_of() == Imm(8))
  assert_true(extract.infer_type() == Ok(Imm(8)))
  assert_true(extract.simplify() == Int(word8(0xAD)))
  assert_eval_word(extract, Map([]), word8(0xAD))
  assert_true(
    @types.Extract(hi=8, lo=0, exp=Int(word8(1))).infer_type() ==
    Err(@types.TypeError::bad_cast()),
  )
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
test "bil BAP normalize wrappers recurse with optional expression normalization" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let minus_one = @types.Int(@types.Word::of_int(width=8, -1).signed())
  let exp : @types.Exp = BinOp(Plus, Var(x), minus_one)
  assert_true(exp.normalize() == BinOp(Minus, Var(x), Int(word8(1))))
  let stmts = [@types.Stmt::Move(y, exp)]
  assert_true(@types.normalize(stmts) == stmts)
  let normalized = @types.normalize(stmts, normalize_exp=true)
  inspect(normalized[0].to_string(), content="y:imm8 := (x:imm8 - 1:8u)")
  let branch = @types.normalize(
    [If(cond=exp, yes=[Move(y, exp)], no=[])],
    normalize_exp=true,
  )
  match branch[0] {
    If(cond~, yes~, ..) => {
      inspect(cond.to_string(), content="(x:imm8 - 1:8u)")
      inspect(yes[0].to_string(), content="y:imm8 := (x:imm8 - 1:8u)")
    }
    _ => fail("expected normalized branch")
  }
}

///|
test "bil BAP trie normalization prunes values and canonicalizes variables" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let virtual_x = @types.Var::new(name="x", typ~, is_virtual=true)
  let dead = @types.Var::new(name="dead", typ~, is_virtual=true)
  let y = @types.Var::new(name="y", typ~)
  let stmts = [
    @types.Stmt::Move(dead, Int(word8(7))),
    Move(virtual_x, BinOp(Plus, Var(x), Int(word8(1)))),
    Move(y, Var(virtual_x)),
  ]
  let normalized = @types.normalize_for_trie(stmts)
  assert_true(normalized.length() == 2)
  inspect(
    normalized[0].to_string(),
    content="x:imm8 := (x:imm8 + unknown(<pruned>:imm8))",
  )
  inspect(normalized[1].to_string(), content="y:imm8 := x:imm8")
  match normalized[0] {
    Move(lhs, BinOp(Plus, Var(rhs), Unknown("<pruned>", Imm(8)))) => {
      assert_true(lhs == rhs)
      assert_true(lhs.is_physical())
    }
    _ => fail("expected normalized trie move")
  }
}

///|
test "bil BAP trie normalization applies substitutions before simplifying" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [@types.Stmt::Move(y, Var(x))]
  let replacement : @types.Exp = BinOp(Plus, Var(z), Int(word8(0)))
  let normalized = @types.normalize_for_trie(stmts, subst=[
    (Var(x), replacement),
  ])
  assert_true(normalized.length() == 1)
  inspect(normalized[0].to_string(), content="y:imm8 := z:imm8")
}

///|
test "bil BAP normalize hoists store-chain load memories" {
  let mem_typ = @types.ValueType::Mem(addr_width=32, value_width=8)
  let mem = @types.Var::new(name="mem", typ=mem_typ)
  let x = @types.Var::new(name="x", typ=Imm(32))
  let addr = @types.Int(word32(0))
  let store : @types.Exp = Store(
    mem=Var(mem),
    addr~,
    value=Int(word32(0xdeadbeef)),
    endian=LittleEndian,
  )
  let normalized = @types.normalize([
    Move(x, Load(mem=store, addr~, endian=LittleEndian, typ=Imm(32))),
  ])
  assert_true(normalized.length() == 2)
  match (normalized[0], normalized[1]) {
    (
      Move(
        temp,
        Store(mem=Var(base), addr=Int(store_addr), value=Int(value), ..)
      ),
      Move(lhs, Load(mem=Var(load_mem), addr=Int(load_addr), typ=Imm(32), ..)),
    ) => {
      assert_true(temp.is_virtual())
      assert_true(temp.typ() == mem_typ)
      assert_true(base == mem)
      assert_true(store_addr == word32(0))
      assert_true(value == word32(0xdeadbeef))
      assert_true(lhs == x)
      assert_true(load_mem == temp)
      assert_true(load_addr == word32(0))
    }
    _ => fail("expected memory temp hoist before load")
  }
}

///|
test "bil BAP normalize hoists memory-effect load addresses" {
  let mem_typ = @types.ValueType::Mem(addr_width=32, value_width=8)
  let mem = @types.Var::new(name="mem", typ=mem_typ)
  let x = @types.Var::new(name="x", typ=Imm(8))
  let addr = @types.Int(word32(0))
  let address_load : @types.Exp = Load(
    mem=Var(mem),
    addr~,
    endian=LittleEndian,
    typ=Imm(32),
  )
  let normalized = @types.normalize([
    Move(
      x,
      Load(mem=Var(mem), addr=address_load, endian=LittleEndian, typ=Imm(8)),
    ),
  ])
  assert_true(normalized.length() == 2)
  match (normalized[0], normalized[1]) {
    (
      Move(temp, Load(mem=Var(addr_mem), addr=Int(addr_word), typ=Imm(32), ..)),
      Move(lhs, Load(mem=Var(load_mem), addr=Var(load_addr), typ=Imm(8), ..)),
    ) => {
      assert_true(temp.is_virtual())
      assert_true(temp.typ() == Imm(32))
      assert_true(addr_mem == mem)
      assert_true(addr_word == word32(0))
      assert_true(lhs == x)
      assert_true(load_mem == mem)
      assert_true(load_addr == temp)
    }
    _ => fail("expected address load hoist before outer load")
  }
}

///|
fn assert_ite_setup(stmt : @types.Stmt, flag : @types.Var) -> @types.Var raise {
  match stmt {
    If(cond=Var(seen_flag), yes~, no~) => {
      assert_true(seen_flag == flag)
      assert_true(yes.length() == 1)
      assert_true(no.length() == 1)
      match (yes[0], no[0]) {
        (Move(lhs, Int(yes_word)), Move(rhs, Int(no_word))) => {
          assert_true(lhs == rhs)
          assert_true(lhs.is_virtual())
          assert_true(yes_word == @types.Word::b1())
          assert_true(no_word == @types.Word::b0())
          lhs
        }
        _ => fail("expected hoisted condition assignment")
      }
    }
    _ => fail("expected hoisted condition branch")
  }
}

///|
test "bil BAP normalize hoists ITE branch conditions" {
  let flag = @types.Var::new(name="flag", typ=Imm(1))
  let x = @types.Var::new(name="x", typ=Imm(8))
  let cond : @types.Exp = Ite(
    cond=Var(flag),
    yes=Int(@types.Word::b1()),
    no=Int(@types.Word::b0()),
  )
  let normalized = @types.normalize([
    If(cond~, yes=[Move(x, Int(word8(1)))], no=[Move(x, Int(word8(2)))]),
  ])
  assert_true(normalized.length() == 2)
  let temp = assert_ite_setup(normalized[0], flag)
  match normalized[1] {
    If(cond=Var(branch_temp), yes~, no~) => {
      assert_true(branch_temp == temp)
      assert_true(yes.length() == 1)
      assert_true(no.length() == 1)
      inspect(yes[0].to_string(), content="x:imm8 := 1:8u")
      inspect(no[0].to_string(), content="x:imm8 := 2:8u")
    }
    _ => fail("expected normalized branch")
  }
}

///|
test "bil BAP normalize hoists ITE while conditions with loop updates" {
  let flag = @types.Var::new(name="flag", typ=Imm(1))
  let x = @types.Var::new(name="x", typ=Imm(8))
  let cond : @types.Exp = Ite(
    cond=Var(flag),
    yes=Int(@types.Word::b1()),
    no=Int(@types.Word::b0()),
  )
  let normalized = @types.normalize([
    While(cond~, body=[Move(x, BinOp(Plus, Var(x), Int(word8(1))))]),
  ])
  assert_true(normalized.length() == 2)
  let temp = assert_ite_setup(normalized[0], flag)
  match normalized[1] {
    While(cond=Var(loop_temp), body~) => {
      assert_true(loop_temp == temp)
      assert_true(body.length() == 2)
      inspect(body[0].to_string(), content="x:imm8 := (x:imm8 + 1:8u)")
      assert_true(assert_ite_setup(body[1], flag) == temp)
    }
    _ => fail("expected normalized loop")
  }
}

///|
test "bil normalize splits ITE expressions in moves and jumps" {
  let typ = @types.ValueType::Imm(8)
  let flag = @types.Var::new(name="flag", typ~)
  let x = @types.Var::new(name="x", typ~)
  let choice : @types.Exp = Ite(
    cond=Var(flag),
    yes=Int(word8(1)),
    no=Int(word8(2)),
  )
  let moved = @types.normalize([Move(x, BinOp(Plus, choice, Int(word8(3))))])
  match moved[0] {
    If(cond~, yes~, no~) => {
      assert_true(cond == Var(flag))
      inspect(yes[0].to_string(), content="x:imm8 := (1:8u + 3:8u)")
      inspect(no[0].to_string(), content="x:imm8 := (2:8u + 3:8u)")
    }
    _ => fail("expected split move")
  }
  let jumped = @types.normalize([Jmp(choice)])
  match jumped[0] {
    If(yes~, no~, ..) => {
      inspect(yes[0].to_string(), content="jmp 1:8u")
      inspect(no[0].to_string(), content="jmp 2:8u")
    }
    _ => fail("expected split jump")
  }
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
  assert_true(@types.is_referenced([top, branch], x))
  assert_true(top.is_assigned(x))
  assert_true(top.is_assigned(x, strict=true))
  assert_true(branch.is_assigned(z))
  assert_true(!branch.is_assigned(z, strict=true))
  assert_true(@types.is_assigned_stmts([top, branch], z))
  assert_true(!@types.is_assigned_stmts([top, branch], z, strict=true))
  assert_true(@types.is_assigned([top, branch], z))
  assert_true(!@types.is_assigned([top, branch], z, strict=true))
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
