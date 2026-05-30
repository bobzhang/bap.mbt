///|
fn stmt_text(stmts : Array[@types.Stmt]) -> Array[String] {
  [
    for stmt in stmts => stmt.to_string()
  ]
}

///|
test "bil pruning removes dead virtual assignments but preserves physical writes" {
  let typ = @types.ValueType::Imm(8)
  let physical = @types.Var::new(name="physical", typ~)
  let dead = @types.Var::new(name="dead", typ~, is_virtual=true)
  let live = @types.Var::new(name="live", typ~, is_virtual=true)
  let stmts = [
    @types.Stmt::Move(live, Int(word8(1))),
    Move(dead, BinOp(Plus, Var(live), Int(word8(1)))),
    Move(physical, BinOp(Plus, Var(live), Int(word8(2)))),
  ]
  let pruned = @types.prune_dead_virtual_stmts(stmts)
  assert_true(
    stmt_text(pruned) ==
    ["%live:imm8 := 0x01:8u", "physical:imm8 := (%live:imm8 + 0x02:8u)"],
  )
}

///|
test "bil pruning keeps branch condition dependencies" {
  let typ = @types.ValueType::Imm(8)
  let physical = @types.Var::new(name="physical", typ~)
  let cond_var = @types.Var::new(name="cond", typ~, is_virtual=true)
  let branch_tmp = @types.Var::new(name="branch_tmp", typ~, is_virtual=true)
  let stmts = [
    @types.Stmt::Move(cond_var, Int(word8(1))),
    If(
      cond=BinOp(Eq, Var(cond_var), Int(word8(1))),
      yes=[Move(branch_tmp, Int(word8(2)))],
      no=[Move(branch_tmp, Int(word8(3)))],
    ),
    Move(physical, Var(cond_var)),
  ]
  let pruned = @types.prune_dead_virtual_stmts(stmts)
  assert_true(
    stmt_text(pruned) ==
    [
      "%cond:imm8 := 0x01:8u", "if (%cond:imm8 == 0x01:8u) then 0 stmts else 0 stmts",
      "physical:imm8 := %cond:imm8",
    ],
  )
}

///|
test "bil optimize combines simplification and dead virtual pruning" {
  let typ = @types.ValueType::Imm(8)
  let physical = @types.Var::new(name="physical", typ~)
  let dead = @types.Var::new(name="dead", typ~, is_virtual=true)
  let stmts = [
    @types.Stmt::If(
      cond=Int(@types.Word::b0()),
      yes=[Move(dead, Int(word8(1)))],
      no=[Move(physical, BinOp(Plus, Int(word8(2)), Int(word8(3))))],
    ),
  ]
  let optimized = @types.optimize_stmts(stmts)
  assert_true(stmt_text(optimized) == ["physical:imm8 := 0x05:8u"])
  let bounded = @types.optimize_stmts(stmts, max_iterations=2)
  assert_true(bounded == optimized)
}

///|
test "bil constant propagation folds straight-line moves" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(2))),
    Move(y, BinOp(Plus, Var(x), Int(word8(3)))),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) == ["x:imm8 := 0x02:8u", "y:imm8 := 0x05:8u"],
  )
}

///|
test "bil constant propagation joins identical branch facts" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let cond = @types.Var::new(name="cond", typ~)
  let stmts = [
    @types.Stmt::If(cond=Var(cond), yes=[Move(x, Int(word8(4)))], no=[
      Move(x, Int(word8(4))),
    ]),
    Move(y, BinOp(Plus, Var(x), Int(word8(1)))),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["if cond:imm8 then 1 stmts else 1 stmts", "y:imm8 := 0x05:8u"],
  )
}

///|
test "bil constant propagation drops facts that differ across branches" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let cond = @types.Var::new(name="cond", typ~)
  let stmts = [
    @types.Stmt::If(cond=Var(cond), yes=[Move(x, Int(word8(4)))], no=[
      Move(x, Int(word8(5))),
    ]),
    Move(y, BinOp(Plus, Var(x), Int(word8(1)))),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["if cond:imm8 then 1 stmts else 1 stmts", "y:imm8 := (x:imm8 + 0x01:8u)"],
  )
}
