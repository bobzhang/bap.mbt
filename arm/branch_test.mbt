///|
test "direct branches are PC-relative" {
  inspect(
    lift_str("Bcc", [i(0x100), ..al], addr=0x8000),
    content=(
      #|jmp 0x8108:32u
    ),
  )
  inspect(
    lift_str("Bcc", [i(-8), ..cc(1)], addr=0x8000),
    content=(
      #|if (ZF:imm1 == 0:1u) {
      #|  jmp 0x8000:32u
      #|}
    ),
  )
  inspect(
    lift_str("BL", [i(0x100), ..al], addr=0x8000),
    content=(
      #|LR:imm32 := 0x8004:32u
      #|jmp 0x8108:32u
    ),
  )
  inspect(
    lift_str("BL", [i(0x100)], addr=0x8000),
    content=(
      #|LR:imm32 := 0x8004:32u
      #|jmp 0x8108:32u
    ),
  )
  inspect(
    lift_str("BL_pred", [i(0x10), ..cc(0)], addr=0x8000),
    content=(
      #|if (ZF:imm1 == 1:1u) {
      #|  LR:imm32 := 0x8004:32u
      #|  jmp 0x8018:32u
      #|}
    ),
  )
  inspect(
    lift_str("BLXi", [i(0x20)], addr=0x8000),
    content=(
      #|LR:imm32 := 0x8004:32u
      #|jmp 0x8028:32u
    ),
  )
  // an INT32_MIN offset denotes zero
  inspect(
    lift_str("Bcc", [i(-0x80000000), ..al], addr=0x8000),
    content=(
      #|jmp 0x8008:32u
    ),
  )
}

///|
test "indirect branches" {
  inspect(
    lift_str("BX", [r("R3")]),
    content=(
      #|jmp R3:imm32
    ),
  )
  inspect(
    lift_str("BX_RET", al),
    content=(
      #|jmp LR:imm32
    ),
  )
  inspect(
    lift_str("BX_pred", [r("R3"), ..cc(1)]),
    content=(
      #|if (ZF:imm1 == 0:1u) {
      #|  jmp R3:imm32
      #|}
    ),
  )
  inspect(
    lift_str("BLX", [r("R3")], addr=0x8000),
    content=(
      #|LR:imm32 := 0x8004:32u
      #|jmp R3:imm32
    ),
  )
  inspect(
    lift_str("BLX_pred", [r("R3"), ..cc(10)], addr=0x8000),
    content=(
      #|if (NF:imm1 == VF:imm1) {
      #|  LR:imm32 := 0x8004:32u
      #|  jmp R3:imm32
      #|}
    ),
  )
}

///|
test "branch targets and links" {
  let init = state([("R3", 0x4000), ("LR", 0x1234)], flags=[("ZF", true)])
  let target = (name : String, ops : Array[@mc.Op]) => {
    jump_target(lift_insn(name, ops, addr=0x8000), init)
  }
  assert_eq(target("Bcc", [i(0x100), ..al]), Some(0x8108))
  assert_eq(target("Bcc", [i(-16), ..cc(0)]), Some(0x7FF8))
  assert_eq(target("Bcc", [i(-16), ..cc(1)]), None)
  assert_eq(target("BX_RET", al), Some(0x1234))
  assert_eq(target("BX", [r("R3")]), Some(0x4000))
  assert_eq(target("BX_pred", [r("R3"), ..cc(1)]), None)
  let bl = lift_insn("BL", [i(0x100), ..al], addr=0x8000)
  assert_eq(reg_value(exec(bl, init), "LR"), 0x8004)
  let blx = lift_insn("BLX_pred", [r("R3"), ..cc(0)], addr=0x8000)
  assert_eq(reg_value(exec(blx, init), "LR"), 0x8004)
  assert_eq(jump_target(blx, init), Some(0x4000))
}

///|
test "reads of PC see the address plus 8" {
  inspect(
    lift_str("ADDri", [r("R0"), r("PC"), i(4), ..al, r("Nil")], addr=0x100),
    content=(
      #|%v2:imm32 := 0x108:32u
      #|%v3:imm32 := 4:32u
      #|R0:imm32 := (0x108:32u + 4:32u)
    ),
  )
  inspect(
    lift_str("LDRi12", [r("R0"), r("PC"), i(4), ..al], addr=0x100),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (0x108:32u + 4:32u)):imm32
    ),
  )
  // writes to PC become jumps, also inside conditional code
  inspect(
    lift_str("ADDri", [r("PC"), r("PC"), i(4), ..cc(0), r("Nil")], addr=0x100),
    content=(
      #|if (ZF:imm1 == 1:1u) {
      #|  %v2:imm32 := 0x108:32u
      #|  %v3:imm32 := 4:32u
      #|  jmp (0x108:32u + 4:32u)
      #|}
    ),
  )
  inspect(
    lift_str("MOVi16", [r("PC"), i(0x40), ..al], addr=0x100),
    content=(
      #|jmp 0x40:32u
    ),
  )
  let stmts = @arm.resolve_pc(
    [
      If(cond=Var(@arm.zf), yes=[Move(@arm.pc, Var(@arm.pc))], no=[]),
      While(cond=Var(@arm.zf), body=[Move(@arm.r0, Var(@arm.pc))]),
    ],
    0x108,
  )
  inspect(
    render(stmts),
    content=(
      #|if ZF:imm1 {
      #|  jmp 0x108:32u
      #|}
      #|while ZF:imm1 {
      #|  R0:imm32 := 0x108:32u
      #|}
    ),
  )
}

///|
test "malformed branches" {
  inspect(
    lift_error("BX", [r("R3"), i(1)]),
    content="Failure: BX:ops ((Reg R3) (Imm 1:32u)) doesn't match branch insn BX",
  )
}
