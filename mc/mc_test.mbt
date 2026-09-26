///|
test "op accessors" {
  let r = @mc.Op::reg("R1", code=3)
  assert_eq(r.reg_name(), Some("R1"))
  assert_eq(r.imm_value(), None)
  assert_eq(@mc.Imm(16).imm_value(), Some(16L))
  assert_eq(@mc.Imm(16).to_string(), "0x10")
}

///|
test "insn next address" {
  let insn = @mc.Insn::create("NOP", [], addr=0x1000, size=4)
  assert_eq(insn.next_addr(), 0x1004UL)
  assert_eq(insn.op(0), None)
}

///|
test "lifter registry" {
  @mc.register_lifter("mc-test", insn => {
    if insn.name == "NOP" {
      []
    } else {
      raise @mc.Unsupported(insn.name)
    }
  })
  assert_true(@mc.lifter_targets().contains("mc-test"))
  assert_eq(@mc.lift("mc-test", @mc.Insn::create("NOP", [])).length(), 0)
  try @mc.lift("mc-test", @mc.Insn::create("FOO", [])) catch {
    err => assert_true(err is @mc.Unsupported("FOO"))
  } noraise {
    _ => fail("expected unsupported instruction")
  }
  try @mc.lift("mc-missing", @mc.Insn::create("NOP", [])) catch {
    err => assert_true(err is @mc.Failure(_))
  } noraise {
    _ => fail("expected missing lifter")
  }
}
