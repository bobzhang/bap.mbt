///|
fn bil_pass_var(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(8))
}

///|
fn bil_pass_stmt(name : String, value : Int) -> @types.Stmt {
  Move(bil_pass_var(name), Int(try! @types.Word::of_int(width=8, value)))
}

///|
fn bil_pass_text(stmts : Array[@types.Stmt]) -> Array[String] {
  stmts.map(stmt => stmt.to_string())
}

///|
test "BAP-style BIL pass registry records metadata and overwrites by name" {
  let first = @types.register_pass(
    "unit-bil-alpha",
    stmts => stmts,
    desc="alpha pass",
  )
  assert_eq(first.name(), "unit-bil-alpha")
  assert_eq(first.desc(), "alpha pass")
  assert_eq(first.to_string(), "unit-bil-alpha           alpha pass")

  let replaced = @types.register_pass(
    "unit-bil-alpha",
    stmts => {
      let next = stmts.copy()
      next.push(bil_pass_stmt("alpha", 1))
      next
    },
    desc="replacement pass",
  )
  assert_eq(replaced.desc(), "replacement pass")
  let matching = @types.passes().filter(pass => pass.name() == "unit-bil-alpha")
  assert_true(matching.length() == 1)
  assert_eq(matching[0].desc(), "replacement pass")
  assert_true(bil_pass_text(replaced.run([])) == ["alpha:imm8 := 1:8u"])
}

///|
test "BAP-style selected BIL passes preserve requested order" {
  let append_left = @types.register_pass("unit-bil-left", stmts => {
    let next = stmts.copy()
    next.push(bil_pass_stmt("left", 1))
    next
  })
  let append_right = @types.register_pass("unit-bil-right", stmts => {
    let next = stmts.copy()
    next.push(bil_pass_stmt("right", 2))
    next
  })
  @types.select_passes([append_right, append_left])
  let selected = @types.selected_passes()
  assert_true(selected.length() == 2)
  let stmts = @types.run_selected_passes([])
  assert_true(
    bil_pass_text(stmts) == ["right:imm8 := 2:8u", "left:imm8 := 1:8u"],
  )
}

///|
test "BIL pass enumeration is deterministic by pass name" {
  ignore(@types.register_pass("unit-bil-order-z", stmts => stmts))
  ignore(@types.register_pass("unit-bil-order-a", stmts => stmts))
  ignore(@types.register_pass("unit-bil-order-b", stmts => stmts))
  let names = @types.passes()
    .filter(pass => pass.name().has_prefix("unit-bil-order-"))
    .map(pass => pass.name())
  assert_true(
    names == ["unit-bil-order-a", "unit-bil-order-b", "unit-bil-order-z"],
  )
}
