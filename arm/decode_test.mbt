///|
test "instruction names round-trip" {
  let all = @arm.Insn::all()
  assert_eq(all.length(), 192)
  for insn in all {
    assert_true(@arm.Insn::of_name(insn.name()) is Some(i) && i == insn)
  }
  debug_inspect(@arm.Insn::of_name("ADDrsi"), content="Some(Move(ADDrsi))")
  debug_inspect(
    @arm.Insn::of_name("LDMIA_UPD"),
    content="Some(MemMulti(LDMIA_UPD))",
  )
  debug_inspect(@arm.Insn::of_name("addrsi"), content="None")
  debug_inspect(@arm.Insn::of_name("tMOVi8"), content="None")
}

///|
test "thumb2 opcodes are recoded as ARM, except branches" {
  debug_inspect(@arm.Insn::of_name("t2ADDri"), content="Some(Move(ADDri))")
  debug_inspect(@arm.Insn::of_name("t2LDRi12"), content="Some(Mem(LDRi12))")
  debug_inspect(@arm.Insn::of_name("t2Bcc"), content="None")
  debug_inspect(@arm.Insn::of_name("t2BX"), content="None")
  debug_inspect(@arm.encoding_of_name("t2ADDri"), content="T32")
  debug_inspect(@arm.encoding_of_name("ADDri"), content="A32")
}

///|
test "registers, operands and conditions" {
  for reg in @arm.Reg::all() {
    assert_true(@arm.Reg::of_name(reg.name()) is Some(r) && r == reg)
  }
  debug_inspect(@arm.Reg::of_name("R13"), content="None")
  debug_inspect(@arm.Reg::R0.is_gpr(), content="true")
  debug_inspect(@arm.Reg::CPSR.is_gpr(), content="false")
  debug_inspect(@arm.Reg::Nil.is_gpr(), content="false")
  debug_inspect(@arm.Op::of_mc(r("SP")), content="Some(Reg(SP))")
  debug_inspect(@arm.Op::of_mc(i(-1)), content="Some(Imm(4294967295))")
  debug_inspect(@arm.Op::of_mc(Fmm(1.0)), content="None")
  debug_inspect(@arm.Op::of_mc(r("D0")), content="None")
  debug_inspect(@arm.Cond::of_int(0), content="Some(EQ)")
  debug_inspect(@arm.Cond::of_int(14), content="Some(AL)")
  debug_inspect(@arm.Cond::of_int(15), content="None")
  inspect(@arm.Op::Imm(0x10).to_string(), content="(Imm 0x10:32u)")
  inspect(
    @arm.Reg::LR.to_var().to_string(),
    content=(
      #|LR:imm32
    ),
  )
}

///|
test "unknown opcodes lift to an empty program" {
  inspect(lift_str("tMOVi8", [r("R0"), i(1)]), content="")
  inspect(lift_str("VADDD", [r("D0"), r("D1"), r("D2")]), content="")
}

///|
test "malformed instructions are reported" {
  inspect(
    lift_error("MOVi", [r("R0"), Fmm(1.5), ..al, r("Nil")]),
    content="BadOperands: unsupported operand: 1.5",
  )
  inspect(
    lift_error("MOVi", [r("R0"), i(1)]),
    content=(
      #|Failure: MOVi:ops ((Reg R0) (Imm 1:32u)) doesn't match move insn MOVi
    ),
  )
  inspect(
    lift_error("MOVi", [r("R0"), i(1), i(15), r("Nil"), r("Nil")]),
    content="Failure: MOVi:bad argument (cond): not a condition: 15",
  )
  inspect(
    lift_error("MOVsi", [r("R0"), r("R1"), i(0x0f), ..al, r("Nil")]),
    content=(
      #|Failure: MOVsi:Imm 7:32u, doesn't stand for shift
    ),
  )
  inspect(
    lift_error("LDRi12", [r("CPSR"), r("R1"), i(0), ..al]),
    content="Failure: LDRi12:Unexpected arguments: (Reg CPSR), unspecified",
  )
}

///|
test "register installs the lifter for all ARM targets" {
  @arm.register()
  @arm.register()
  for name in @arm.target_names {
    assert_true(@mc.find_lifter(name) is Some(_))
  }
  let insn = @mc.Insn::create("MOVr", [r("R0"), r("R1"), ..al, r("Nil")])
  inspect(render(@mc.lift("armv7", insn)), content="R0:imm32 := R1:imm32")
  inspect(render(@mc.lift("thumbeb", insn)), content="R0:imm32 := R1:imm32")
}

///|
test "machine state variables" {
  inspect(
    @arm.cpu_regs().map(v => v.to_string()).join(" "),
    content=(
      #|R0:imm32 R1:imm32 R2:imm32 R3:imm32 R4:imm32 R5:imm32 R6:imm32 R7:imm32 R8:imm32 R9:imm32 R10:imm32 R11:imm32 R12:imm32 PC:imm32 SP:imm32 LR:imm32 SPSR:imm32 CPSR:imm32 ITSTATE:imm8
    ),
  )
  inspect(
    @arm.cpu_gpr().map(v => v.to_string()).join(" "),
    content=(
      #|R0:imm32 R1:imm32 R2:imm32 R3:imm32 R4:imm32 R5:imm32 R6:imm32 R7:imm32 R8:imm32 R9:imm32 R10:imm32 R11:imm32 R12:imm32 SP:imm32 LR:imm32
    ),
  )
  inspect(
    @arm.cpu_flags().map(v => v.to_string()).join(" "),
    content=(
      #|NF:imm1 ZF:imm1 CF:imm1 QF:imm1 VF:imm1 GE0:imm1 GE1:imm1 GE2:imm1 GE3:imm1
    ),
  )
  inspect(
    @arm.mem.typ.to_string(),
    content=(
      #|mem32x8
    ),
  )
  assert_true(@arm.is_sp(@arm.sp))
  assert_true(@arm.is_bp(@arm.r11))
  assert_true(@arm.is_pc(@arm.pc))
  assert_true(@arm.is_flag(@arm.ge[2]))
  assert_true(@arm.is_reg(@arm.itstate))
  assert_true(!@arm.is_reg(@arm.nf))
  assert_true(@arm.is_mem(@arm.mem))
  assert_true(@arm.is_zf(@arm.zf) && @arm.is_cf(@arm.cf))
  assert_true(@arm.is_vf(@arm.vf) && @arm.is_nf(@arm.nf))
  assert_eq(@arm.addr_of_pc(0x100), 0x108)
}
