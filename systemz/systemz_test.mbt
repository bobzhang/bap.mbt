///|
fn lr(rd : String, rs : String) -> @mc.Insn {
  @mc.Insn::create("LR", [@mc.Op::reg(rd), @mc.Op::reg(rs)], size=2)
}

///|
test "LR lifts to a low-half register move" {
  let stmts = @systemz.lift(lr("R1L", "R2L"))
  inspect(
    stmts.map(s => s.to_string()).join("\n"),
    content=(
      #|R1:imm64 := concat(high:32[R1:imm64], low:32[R2:imm64])
    ),
  )
  assert_true(@types.check_stmt_types(stmts) is Ok(_))
  // upstream `regnum` parses `R%d`, so plain and suffixed names both work
  let plain = @systemz.lift(lr("R15", "R0D"))
  inspect(
    plain.map(s => s.to_string()).join("\n"),
    content=(
      #|R15:imm64 := concat(high:32[R15:imm64], low:32[R0:imm64])
    ),
  )
}

///|
test "LR evaluates to high(rd) ++ low(rs)" {
  let state = @types.BilState::new()
    .set("R1", BilWord(@types.Word::of_uint64(width=64, 0x1111111122222222)))
    .set("R2", BilWord(@types.Word::of_uint64(width=64, 0x33333333AAAABBBB)))
  guard @types.exec_stmts(@systemz.lift(lr("R1L", "R2L")), state~) is Ok(next) else {
    fail("evaluation failed")
  }
  guard next.get_word("R1") is Some(w) else { fail("missing R1") }
  assert_eq(w.to_uint64(), 0x11111111AAAABBBB)
}

///|
test "register helpers" {
  assert_eq(@systemz.regnum("R7L"), Some(7))
  assert_eq(@systemz.regnum("R12D"), Some(12))
  assert_eq(@systemz.regnum("F0D"), None)
  assert_eq(@systemz.regnum("R"), None)
  assert_eq(@systemz.gpr(15).map(v => v.name), Some("R15"))
  assert_eq(@systemz.gpr(16), None)
  assert_eq(@systemz.gpr(-1), None)
}

///|
test "lift errors" {
  try @systemz.lift(@mc.Insn::create("AR", [])) catch {
    err => assert_true(err is @mc.Unsupported("AR"))
  } noraise {
    _ => fail("expected unsupported opcode")
  }
  let bad = [
    [@mc.Op::reg("R1L")],
    [@mc.Op::reg("R1L"), @mc.Imm(3)],
    [@mc.Op::reg("F1D"), @mc.Op::reg("R2L")],
    [@mc.Op::reg("R16L"), @mc.Op::reg("R2L")],
  ]
  for ops in bad {
    try @systemz.lift(@mc.Insn::create("LR", ops)) catch {
      err => assert_true(err is @mc.BadOperands("LR"))
    } noraise {
      _ => fail("expected bad operands")
    }
  }
}

///|
test "register installs the lifter for systemz targets" {
  @systemz.register()
  @systemz.register()
  let targets = @mc.lifter_targets()
  for name in @systemz.target_names() {
    assert_true(targets.contains(name))
  }
  assert_eq(@mc.lift("systemz", lr("R1L", "R2L")).length(), 1)
}
