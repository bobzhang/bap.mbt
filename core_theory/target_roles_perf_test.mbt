///|
test "target register role queries are fast enough to repeat" {
  let targets = [
    @core_theory.Target::x86_64(),
    @core_theory.Target::arm(),
    @core_theory.Target::mips(),
    @core_theory.Target::riscv(),
  ]
  for _ in 0..<5 {
    for target in targets {
      let regs = target.regs(roles=[@core_theory.General])
      assert_true(regs.length() > 0)
      ignore(target.vars_with_role(@core_theory.StackPointer))
      ignore(target.reg(@core_theory.StackPointer))
    }
  }
  assert_true(
    @core_theory.Target::x86_64().reg(@core_theory.StackPointer) is Some(_),
  )
}
