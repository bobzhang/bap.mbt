///|
test "project instruction converts to mc insn" {
  let mem = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x400UL,
    b"\x01\x02\x03\x04",
  )
  let insn = @project.ProjectDisassemblyInstruction::create(
    mem,
    name="ADDiu",
    assembly="addiu $t0, $t1, 4",
    operands=[
      @project.ProjectInstructionOperand::register(name="T0", code=9),
      @project.ProjectInstructionOperand::register(name="T1", code=10),
      @project.ProjectInstructionOperand::immediate(4),
    ],
  )
  let mc = insn.to_mc_insn()
  assert_eq(mc.name, "ADDiu")
  assert_eq(mc.addr, 0x400UL)
  assert_eq(mc.size, 4)
  assert_eq(mc.ops, [
    @mc.Reg(name="T0", code=9),
    @mc.Reg(name="T1", code=10),
    @mc.Imm(4),
  ])
  @mc.register_lifter("project-mc-test", insn => {
    if insn.name == "ADDiu" {
      []
    } else {
      raise @mc.Unsupported(insn.name)
    }
  })
  assert_eq(insn.lift_registered_bil(target="project-mc-test"), Ok([]))
  assert_true(insn.lift_registered_bil(target="project-mc-missing") is Err(_))
}
