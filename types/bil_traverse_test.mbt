///|
fn traverse_word8(value : UInt64) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::of_uint64(width=8, value)
}

///|
fn traverse_exp_tag(exp : @types.Exp) -> String {
  match exp {
    Int(_) => "int"
    Var(_) => "var"
    Unknown(_) => "unknown"
    Load(_) => "load"
    Store(_) => "store"
    Let(_) => "let"
    Cast(_) => "cast"
    Extract(_) => "extract"
    Concat(_) => "concat"
    UnOp(_) => "unop"
    BinOp(_) => "binop"
    Ite(_) => "ite"
  }
}

///|
fn traverse_stmt_tag(stmt : @types.Stmt) -> String {
  match stmt {
    Move(_) => "move"
    Jmp(_) => "jmp"
    Special(_) => "special"
    CpuExn(_) => "cpuexn"
    If(_) => "if"
    While(_) => "while"
  }
}

///|
test "expression traversal folds finds and maps in source order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let unknown : @types.Exp = Unknown("u", typ)
  let exp : @types.Exp = Let(
    x,
    Int(traverse_word8(1)),
    BinOp(
      Plus,
      Var(x),
      Ite(cond=Var(y), yes=Int(traverse_word8(2)), no=unknown),
    ),
  )
  let tags : Array[String] = exp.fold([], (acc, item) => {
    acc.push(traverse_exp_tag(item))
    acc
  })
  assert_true(
    tags == ["let", "int", "binop", "var", "ite", "var", "int", "unknown"],
  )
  assert_true(exp.find(item => item == unknown) == Some(unknown))
  assert_true(exp.exists(item => item == Var(y)))
  let missing : @types.Exp = Int(traverse_word8(0xff))
  assert_true(!exp.exists(item => item == missing))

  let replacement : @types.Exp = Int(traverse_word8(7))
  let mapped = exp.map(item => {
    match item {
      Var(variable) if variable == y => replacement
      _ => item
    }
  })
  assert_true(!mapped.exists(item => item == Var(y)))
  assert_true(mapped.exists(item => item == replacement))
}

///|
test "statement traversal folds statements and contained expressions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let flag = @types.Var::new(name="flag", typ~)
  let stmts : Array[@types.Stmt] = [
    Move(x, BinOp(Plus, Var(y), Int(traverse_word8(1)))),
    If(cond=Var(flag), yes=[Jmp(Var(x))], no=[
      While(cond=Var(y), body=[Special("side")]),
    ]),
    CpuExn(7),
  ]
  let stmt_tags : Array[String] = @types.fold(stmts, [], (acc, stmt) => {
    acc.push(traverse_stmt_tag(stmt))
    acc
  })
  assert_true(stmt_tags == ["move", "if", "jmp", "while", "special", "cpuexn"])

  let exp_tags : Array[String] = @types.fold_exps(stmts, [], (acc, exp) => {
    acc.push(traverse_exp_tag(exp))
    acc
  })
  assert_true(exp_tags == ["binop", "var", "int", "var", "var", "var"])

  assert_true(
    @types.find_stmt(stmts, stmt => stmt is Special(_)) == Some(Special("side")),
  )
  assert_true(@types.exists_stmt(stmts, stmt => stmt is CpuExn(7)))
  assert_true(
    @types.find_exp(stmts, exp => exp == Var(flag)) == Some(Var(flag)),
  )
  assert_true(@types.exists_exp(stmts, exp => exp == Var(x)))

  let replacement : @types.Exp = Int(traverse_word8(9))
  let mapped = @types.map_exps(stmts, exp => {
    match exp {
      Var(variable) if variable == y => replacement
      _ => exp
    }
  })
  assert_true(!@types.exists_exp(mapped, exp => exp == Var(y)))
  assert_true(@types.exists_exp(mapped, exp => exp == replacement))
  assert_true(mapped[0].defined_var() == Some(x))
}
