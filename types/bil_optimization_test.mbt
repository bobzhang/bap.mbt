///|
fn stmt_text(stmts : Array[@types.Stmt]) -> Array[String] {
  [
    for stmt in stmts => stmt.to_string()
  ]
}

///|
fn last_move_rhs(stmts : Array[@types.Stmt], name : String) -> @types.Exp? {
  let mut found = None
  for stmt in stmts {
    match stmt {
      Move(variable, exp) if variable.name == name => found = Some(exp)
      _ => ()
    }
  }
  found
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
    ["%live:imm8 := 1:8u", "physical:imm8 := (%live:imm8 + 2:8u)"],
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
      "%cond:imm8 := 1:8u", "if (%cond:imm8 == 1:8u) then 0 stmts else 0 stmts",
      "physical:imm8 := %cond:imm8",
    ],
  )
}

///|
test "translated BAP pruning preserves virtuals used by jumps" {
  let typ = @types.ValueType::Imm(8)
  let always_alive = @types.Var::new(name="always_alive", typ~)
  let will_survive = @types.Var::new(name="will_survive", typ~, is_virtual=true)
  let direct = @types.prune_dead_virtual_stmts([
    Move(will_survive, Int(word8(42))),
    Jmp(Var(will_survive)),
  ])
  assert_true(
    stmt_text(direct) ==
    ["%will_survive:imm8 := 0x2A:8u", "jmp %will_survive:imm8"],
  )
  let then_jump = @types.prune_dead_virtual_stmts([
    Move(always_alive, Int(word8(1))),
    Move(will_survive, Int(word8(42))),
    If(
      cond=BinOp(Lt, Int(word8(0)), Var(always_alive)),
      yes=[Jmp(Var(will_survive))],
      no=[],
    ),
  ])
  assert_true(
    stmt_text(then_jump) ==
    [
      "always_alive:imm8 := 1:8u", "%will_survive:imm8 := 0x2A:8u", "if (0:8u < always_alive:imm8) then 1 stmts else 0 stmts",
    ],
  )
  let else_jump = @types.prune_dead_virtual_stmts([
    Move(always_alive, Int(word8(1))),
    Move(will_survive, Int(word8(42))),
    If(cond=BinOp(Lt, Int(word8(0)), Var(always_alive)), yes=[], no=[
      Jmp(Var(will_survive)),
    ]),
  ])
  assert_true(
    stmt_text(else_jump) ==
    [
      "always_alive:imm8 := 1:8u", "%will_survive:imm8 := 0x2A:8u", "if (0:8u < always_alive:imm8) then 0 stmts else 1 stmts",
    ],
  )
}

///|
test "translated BAP pruning preserves effects and conservative loops" {
  let typ = @types.ValueType::Imm(8)
  let could_be_dead = @types.Var::new(
    name="could_be_dead",
    typ~,
    is_virtual=true,
  )
  let will_survive = @types.Var::new(name="will_survive", typ~, is_virtual=true)
  let special = @types.prune_dead_virtual_stmts([
    Move(could_be_dead, Int(word8(1))),
    Special("I will survive!"),
  ])
  assert_true(stmt_text(special) == ["special I will survive!"])
  let cpuexn = @types.prune_dead_virtual_stmts([
    Move(could_be_dead, Int(word8(1))),
    CpuExn(42),
  ])
  assert_true(stmt_text(cpuexn) == ["cpuexn 42"])
  let loop_keeps_condition = @types.prune_dead_virtual_stmts([
    Move(will_survive, Int(word8(1))),
    While(cond=BinOp(Lt, Var(will_survive), Int(word8(4))), body=[
      Move(will_survive, Int(word8(5))),
    ]),
  ])
  assert_true(
    stmt_text(loop_keeps_condition) ==
    [
      "%will_survive:imm8 := 1:8u", "while (%will_survive:imm8 < 4:8u) do 1 stmts",
    ],
  )
  match loop_keeps_condition[1] {
    While(body~, ..) =>
      assert_true(stmt_text(body) == ["%will_survive:imm8 := 5:8u"])
    _ => fail("expected loop")
  }
  let loop_keeps_body = @types.prune_dead_virtual_stmts([
    Move(will_survive, Int(word8(2))),
    While(cond=BinOp(Lt, Var(will_survive), Int(word8(4))), body=[
      Move(could_be_dead, Int(word8(1))),
      Move(will_survive, Int(word8(5))),
    ]),
    Move(could_be_dead, Int(word8(2))),
  ])
  assert_true(
    stmt_text(loop_keeps_body) ==
    [
      "%will_survive:imm8 := 2:8u", "while (%will_survive:imm8 < 4:8u) do 2 stmts",
    ],
  )
  match loop_keeps_body[1] {
    While(body~, ..) =>
      assert_true(
        stmt_text(body) ==
        ["%could_be_dead:imm8 := 1:8u", "%will_survive:imm8 := 5:8u"],
      )
    _ => fail("expected loop")
  }
}

///|
test "translated BAP pruning preserves condition-carried liveness" {
  let typ = @types.ValueType::Imm(8)
  let always_alive = @types.Var::new(name="always_alive", typ~)
  let x = @types.Var::new(name="x", typ~)
  let could_be_dead = @types.Var::new(
    name="could_be_dead",
    typ~,
    is_virtual=true,
  )
  let will_survive = @types.Var::new(name="will_survive", typ~, is_virtual=true)
  let branch_use = [
    @types.Stmt::Move(x, Int(word8(1))),
    Move(will_survive, Int(word8(2))),
    If(cond=BinOp(Lt, Int(word8(0)), Var(x)), yes=[], no=[
      Move(will_survive, Int(word8(1))),
    ]),
    Move(x, Var(will_survive)),
  ]
  assert_true(@types.prune_dead_virtual_stmts(branch_use) == branch_use)
  let includes_conditions = @types.prune_dead_virtual_stmts([
    Move(will_survive, Int(word8(42))),
    If(
      cond=BinOp(Lt, Int(word8(0)), Var(will_survive)),
      yes=[Move(could_be_dead, Int(word8(1)))],
      no=[Move(could_be_dead, Int(word8(2)))],
    ),
    Move(could_be_dead, Int(word8(1))),
    Move(always_alive, Var(could_be_dead)),
    Move(could_be_dead, UnOp(Not, Var(always_alive))),
  ])
  assert_true(
    stmt_text(includes_conditions) ==
    [
      "%will_survive:imm8 := 0x2A:8u", "if (0:8u < %will_survive:imm8) then 0 stmts else 0 stmts",
      "%could_be_dead:imm8 := 1:8u", "always_alive:imm8 := %could_be_dead:imm8",
    ],
  )
}

///|
test "translated BAP pruning preserves deeply nested loop dependencies" {
  let typ = @types.ValueType::Imm(8)
  let always_alive = @types.Var::new(name="always_alive", typ~)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let could_be_dead = @types.Var::new(
    name="could_be_dead",
    typ~,
    is_virtual=true,
  )
  let will_survive = @types.Var::new(name="will_survive", typ~, is_virtual=true)
  let nested = [
    @types.Stmt::Move(x, Int(word8(1))),
    If(
      cond=BinOp(Lt, Var(x), Int(word8(0))),
      yes=[
        If(cond=BinOp(Eq, BinOp(Plus, Var(x), Var(y)), Int(word8(1))), yes=[], no=[
          While(cond=BinOp(Lt, Var(y), Var(z)), body=[
            If(cond=BinOp(Lt, Int(word8(4)), Var(z)), yes=[], no=[
              Move(will_survive, Int(word8(1))),
            ]),
          ]),
        ]),
      ],
      no=[],
    ),
  ]
  assert_true(@types.prune_dead_virtual_stmts(nested) == nested)
  let deep = [
    @types.Stmt::Move(always_alive, Int(word8(1))),
    Move(will_survive, Int(word8(2))),
    Move(always_alive, Int(word8(4))),
    If(
      cond=BinOp(Lt, Int(word8(0)), Var(will_survive)),
      yes=[
        While(cond=BinOp(Eq, Var(will_survive), Int(word8(2))), body=[
          If(
            cond=BinOp(Lt, Int(word8(0)), Var(always_alive)),
            yes=[Move(will_survive, Int(word8(1)))],
            no=[Move(could_be_dead, Int(word8(42)))],
          ),
        ]),
      ],
      no=[],
    ),
  ]
  assert_true(@types.prune_dead_virtual_stmts(deep) == deep)
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
  assert_true(stmt_text(optimized) == ["physical:imm8 := 5:8u"])
  let bounded = @types.optimize_stmts(stmts, max_iterations=2)
  assert_true(bounded == optimized)
}

///|
test "bil optimize folds chained virtual constants into physical uses" {
  let typ = @types.ValueType::Imm(8)
  let v = @types.Var::new(name="v", typ~, is_virtual=true)
  let x = @types.Var::new(name="x", typ~)
  let stmts = [
    @types.Stmt::Move(v, Int(word8(1))),
    Move(v, BinOp(Plus, Var(v), Int(word8(1)))),
    Move(v, BinOp(Plus, Var(v), Int(word8(1)))),
    Move(v, BinOp(Plus, Var(v), Int(word8(1)))),
    Move(x, Var(v)),
  ]
  let optimized = @types.optimize_stmts(stmts)
  assert_true(stmt_text(optimized) == ["x:imm8 := 4:8u"])
}

///|
test "bil optimize removes dead virtual branches with computable conditions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let z = @types.Var::new(name="z", typ~)
  let v = @types.Var::new(name="v", typ~, is_virtual=true)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(1))),
    Move(v, Int(word8(1))),
    If(cond=BinOp(Lt, Int(word8(0)), Var(v)), yes=[Move(v, Int(word8(4)))], no=[
      Move(v, Int(word8(2))),
    ]),
    Move(z, Var(x)),
  ]
  let optimized = @types.optimize_stmts(stmts)
  assert_true(stmt_text(optimized) == ["x:imm8 := 1:8u", "z:imm8 := 1:8u"])
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
  assert_true(stmt_text(propagated) == ["x:imm8 := 2:8u", "y:imm8 := 5:8u"])
}

///|
test "translated BAP constant propagation covers jumps and unknown values" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let undefined = @types.Exp::Unknown("undefined", typ)
  let through_jump = @types.propagate_const_stmts([
    Move(x, Int(word8(42))),
    Jmp(Var(x)),
  ])
  assert_true(stmt_text(through_jump) == ["x:imm8 := 0x2A:8u", "jmp 0x2A:8u"])
  let after_jump = @types.propagate_const_stmts([
    Move(x, Int(word8(42))),
    Jmp(Var(y)),
    Move(z, Var(x)),
  ])
  assert_true(
    stmt_text(after_jump) ==
    ["x:imm8 := 0x2A:8u", "jmp y:imm8", "z:imm8 := 0x2A:8u"],
  )
  let unknown = @types.propagate_const_stmts([
    Move(x, undefined),
    Move(z, Var(x)),
  ])
  assert_true(
    stmt_text(unknown) ==
    ["x:imm8 := unknown(undefined:imm8)", "z:imm8 := unknown(undefined:imm8)"],
  )
  let branch_unknown = @types.propagate_const_stmts([
    Move(x, Int(word8(1))),
    If(cond=BinOp(Lt, Var(x), Int(word8(0))), yes=[Move(y, undefined)], no=[
      Move(y, undefined),
    ]),
    Move(z, Var(y)),
  ])
  assert_true(
    stmt_text(branch_unknown) ==
    [
      "x:imm8 := 1:8u", "if 0:1u then 1 stmts else 1 stmts", "z:imm8 := unknown(undefined:imm8)",
    ],
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
    ["if cond:imm8 then 1 stmts else 1 stmts", "y:imm8 := 5:8u"],
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
    ["if cond:imm8 then 1 stmts else 1 stmts", "y:imm8 := (x:imm8 + 1:8u)"],
  )
}

///|
test "bil constant propagation keeps selected branch facts for static conditions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(1))),
    If(
      cond=BinOp(Lt, Var(x), Int(word8(0))),
      yes=[Move(y, Int(word8(2))), Jmp(Var(y))],
      no=[Move(y, Int(word8(4)))],
    ),
    Move(z, Var(y)),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["x:imm8 := 1:8u", "if 0:1u then 2 stmts else 1 stmts", "z:imm8 := 4:8u"],
  )
  match propagated[1] {
    If(yes~, no~, ..) => {
      assert_true(stmt_text(yes) == ["y:imm8 := 2:8u", "jmp 2:8u"])
      assert_true(stmt_text(no) == ["y:imm8 := 4:8u"])
    }
    _ => fail("expected propagated branch")
  }
}

///|
test "bil constant propagation does not leak selected branch facts past jumps" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(1))),
    Move(y, Int(word8(2))),
    If(
      cond=BinOp(Lt, Int(word8(0)), Var(x)),
      yes=[
        Move(y, Int(word8(1))),
        If(cond=BinOp(Lt, Int(word8(0)), Var(y)), yes=[Jmp(Var(y))], no=[]),
      ],
      no=[],
    ),
    Move(z, Var(y)),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    [
      "x:imm8 := 1:8u", "y:imm8 := 2:8u", "if 1:1u then 2 stmts else 0 stmts", "z:imm8 := y:imm8",
    ],
  )
  match propagated[2] {
    If(yes~, ..) => {
      assert_true(
        stmt_text(yes) ==
        ["y:imm8 := 1:8u", "if 1:1u then 1 stmts else 0 stmts"],
      )
      match yes[1] {
        If(yes=inner_yes, ..) =>
          assert_true(stmt_text(inner_yes) == ["jmp 1:8u"])
        _ => fail("expected nested branch")
      }
    }
    _ => fail("expected propagated branch")
  }
}

///|
test "bil constant propagation preserves facts after definitely skipped loops" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(1))),
    Move(y, Int(word8(2))),
    While(cond=BinOp(Lt, Var(x), Int(word8(0))), body=[
      Move(y, Int(word8(1))),
      Jmp(Var(y)),
    ]),
    Move(z, Var(y)),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    [
      "x:imm8 := 1:8u", "y:imm8 := 2:8u", "while 0:1u do 2 stmts", "z:imm8 := 2:8u",
    ],
  )
  match propagated[2] {
    While(body~, ..) =>
      assert_true(stmt_text(body) == ["y:imm8 := 1:8u", "jmp 1:8u"])
    _ => fail("expected propagated loop")
  }
}

///|
test "bil constant propagation keeps loop-carried definitions conservative" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(4))),
    While(cond=BinOp(Lt, Var(x), Int(word8(5))), body=[
      Move(y, BinOp(Plus, Var(x), Int(word8(1)))),
      Move(x, Int(word8(42))),
    ]),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["x:imm8 := 4:8u", "while (x:imm8 < 5:8u) do 2 stmts"],
  )
  match propagated[1] {
    While(body~, ..) =>
      assert_true(
        stmt_text(body) == ["y:imm8 := (x:imm8 + 1:8u)", "x:imm8 := 0x2A:8u"],
      )
    _ => fail("expected propagated loop")
  }
}

///|
test "bil constant propagation reuses facts within a loop body after redefinition" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(42))),
    While(cond=BinOp(Lt, Int(word8(2)), Var(x)), body=[
      Move(y, BinOp(Plus, Var(x), Int(word8(1)))),
      Move(x, Int(word8(1))),
      Move(z, BinOp(Plus, Var(x), Int(word8(2)))),
    ]),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["x:imm8 := 0x2A:8u", "while (2:8u < x:imm8) do 3 stmts"],
  )
  match propagated[1] {
    While(body~, ..) =>
      assert_true(
        stmt_text(body) ==
        ["y:imm8 := (x:imm8 + 1:8u)", "x:imm8 := 1:8u", "z:imm8 := 3:8u"],
      )
    _ => fail("expected propagated loop")
  }
}

///|
test "bil constant propagation carries invariant facts into loop branches" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let stmts = [
    @types.Stmt::Move(x, Int(word8(42))),
    While(cond=BinOp(Lt, Int(word8(4)), Var(z)), body=[
      If(cond=BinOp(Lt, Int(word8(1)), Var(z)), yes=[Move(y, Int(word8(1)))], no=[
        Move(y, Int(word8(1))),
      ]),
      If(
        cond=BinOp(Lt, Int(word8(1)), BinOp(Plus, Var(x), Var(y))),
        yes=[Move(y, Int(word8(0)))],
        no=[Move(y, Int(word8(2)))],
      ),
      Move(z, Var(y)),
    ]),
  ]
  let propagated = @types.propagate_const_stmts(stmts)
  assert_true(
    stmt_text(propagated) ==
    ["x:imm8 := 0x2A:8u", "while (4:8u < z:imm8) do 3 stmts"],
  )
  match propagated[1] {
    While(body~, ..) => {
      assert_true(
        stmt_text(body) ==
        [
          "if (1:8u < z:imm8) then 1 stmts else 1 stmts", "if 1:1u then 1 stmts else 1 stmts",
          "z:imm8 := 0:8u",
        ],
      )
      match body[1] {
        If(yes~, no~, ..) => {
          assert_true(stmt_text(yes) == ["y:imm8 := 0:8u"])
          assert_true(stmt_text(no) == ["y:imm8 := 2:8u"])
        }
        _ => fail("expected inner branch")
      }
    }
    _ => fail("expected propagated loop")
  }
}

///|
test "bil optimize keeps physical vars and folds propagated rhs" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let optimized = @types.optimize_stmts([
    Move(x, Int(word8(2))),
    Move(y, BinOp(Plus, Var(x), Int(word8(2)))),
  ])
  assert_true(stmt_text(optimized) == ["x:imm8 := 2:8u", "y:imm8 := 4:8u"])
}

///|
test "bil optimize folds computable condition while preserving physical trace" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let v = @types.Var::new(name="v", typ~, is_virtual=true)
  let optimized = @types.optimize_stmts([
    Move(x, Int(word8(1))),
    Move(v, BinOp(Plus, Var(x), Int(word8(1)))),
    Move(y, BinOp(Times, Var(v), Int(word8(2)))),
    If(cond=BinOp(Lt, Var(y), Int(word8(2))), yes=[Move(z, Int(word8(1)))], no=[
      Move(z, Int(word8(2))),
    ]),
    Move(y, Var(z)),
  ])
  assert_true(
    stmt_text(optimized) ==
    ["x:imm8 := 1:8u", "y:imm8 := 4:8u", "z:imm8 := 2:8u", "y:imm8 := 2:8u"],
  )
}

///|
test "bil optimize exposes expected z value for BAP various-input cases" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let v = @types.Var::new(name="v", typ~, is_virtual=true)
  fn make(input : @types.Exp) -> Array[@types.Stmt] raise {
    [
      Move(x, input),
      If(
        cond=BinOp(Lt, Int(word8(2)), Var(x)),
        yes=[
          While(cond=BinOp(Lt, Int(word8(0)), Var(x)), body=[
            Move(y, BinOp(Times, Var(x), Int(word8(2)))),
            Move(x, BinOp(Minus, Var(x), Int(word8(1)))),
          ]),
        ],
        no=[
          If(
            cond=BinOp(Eq, Var(x), Int(word8(0))),
            yes=[Move(y, Int(word8(1)))],
            no=[
              If(
                cond=BinOp(Eq, Var(x), Int(word8(1))),
                yes=[Move(y, Int(word8(2)))],
                no=[Move(y, Int(word8(4)))],
              ),
            ],
          ),
        ],
      ),
      Move(z, Var(y)),
    ]
  }
  let one_case = @types.optimize_stmts(make(Int(word8(1))))
  assert_true(last_move_rhs(one_case, "z") == Some(Int(word8(2))))
  let four_case = @types.optimize_stmts(make(Int(word8(4))))
  assert_true(last_move_rhs(four_case, "z") == Some(Var(y)))
  let unknown_case = @types.optimize_stmts(make(Var(v)))
  assert_true(last_move_rhs(unknown_case, "z") == Some(Var(y)))
}

///|
test "bil optimize handles nested virtual pipeline regression" {
  let typ = @types.ValueType::Imm(8)
  let v = @types.Var::new(name="v", typ~, is_virtual=true)
  let v1 = @types.Var::new(name="v1", typ~, is_virtual=true)
  let v2 = @types.Var::new(name="v2", typ~, is_virtual=true)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let optimized = @types.optimize_stmts([
    Move(v, Int(word8(2))),
    Move(v1, BinOp(Plus, Int(word8(4)), Var(v))),
    If(
      cond=BinOp(Lt, Int(word8(0)), Var(v1)),
      yes=[
        Move(v2, BinOp(Plus, Var(v1), Int(word8(1)))),
        Move(x, BinOp(Plus, Var(v2), Int(word8(1)))),
      ],
      no=[Move(v2, BinOp(Plus, Var(v1), Int(word8(2)))), Move(x, Var(v2))],
    ),
    Move(v2, Int(word8(4))),
    Move(y, BinOp(Minus, Var(x), Var(v2))),
    If(
      cond=BinOp(Lt, Var(y), Int(word8(0))),
      yes=[
        Move(z, Int(word8(4))),
        Jmp(BinOp(Minus, BinOp(Plus, Var(z), Int(word8(2))), Var(y))),
      ],
      no=[Move(z, Int(word8(2)))],
    ),
    Move(x, Var(z)),
  ])
  assert_true(
    stmt_text(optimized) ==
    ["x:imm8 := 8:8u", "y:imm8 := 4:8u", "z:imm8 := 2:8u", "x:imm8 := 2:8u"],
  )
}
