///|
fn lr(rd : String, rs : String) -> @mc.Insn {
  @mc.Insn::create("LR", [@mc.Op::reg(rd), @mc.Op::reg(rs)], size=2, addr=0)
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
  try @systemz.lift(@mc.Insn::create("AR", [], addr=0, size=4)) catch {
    err => assert_true(err is @mc.Unsupported(opcode="AR", ..))
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
    try @systemz.lift(@mc.Insn::create("LR", ops, addr=0, size=4)) catch {
      err => assert_true(err is @mc.BadOperands(opcode="LR", ..))
    } noraise {
      _ => fail("expected bad operands")
    }
  }
}

///|
test "register installs the systemz provider" {
  let registry = @mc.Registry::new()
  @systemz.register(registry~)
  @systemz.register(registry~)
  assert_eq(registry.names(), [@systemz.provider_name])
  for
    target in [@core_theory.Target::systemz(), @core_theory.Target::systemz9()] {
    let ctx = @mc.Context::create(target)
    assert_true(@systemz.accepts(ctx))
    assert_eq(registry.lift(ctx, lr("R1L", "R2L")).bil.length(), 1)
  }
  assert_false(
    @systemz.accepts(@mc.Context::create(@core_theory.Target::mips())),
  )
  let ctx = @mc.Context::create(@core_theory.Target::systemz())
  try registry.lift(ctx, @mc.Insn::create("AR", [], addr=0, size=2)) catch {
    err => assert_true(err is @mc.Unsupported(opcode="AR", ..))
  } noraise {
    _ => fail("expected unsupported opcode")
  }
}
