///|
test "supervisor call" {
  inspect(
    lift_str("SVC", [i(0), ..al]),
    content=(
      #|special @attribute:(bap:call "__svc(0)")
    ),
  )
  inspect(
    lift_str("SVC", [i(0x900001), ..cc(0)]),
    content=(
      #|if (ZF:imm1 == 1:1u) {
      #|  special @attribute:(bap:call "__svc(0x900001)")
      #|}
    ),
  )
  let stmts = lift_insn("SVC", [i(0xFF000042), ..al])
  inspect(
    @types.Stmt::decode(@types.Stmt::call(), stmts[0]).unwrap(),
    content=(
      #|__svc(0x42)
    ),
  )
}

///|
test "status register moves" {
  inspect(
    lift_str("MRS", [r("R0"), ..al]),
    content=(
      #|R0:imm32 := 0:32u
      #|R0:imm32 := (R0:imm32 | (pad:32[NF:imm1] << 0x1F:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[ZF:imm1] << 0x1E:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[CF:imm1] << 0x1D:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[VF:imm1] << 0x1C:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[QF:imm1] << 0x1B:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[GE3:imm1] << 0x13:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[GE2:imm1] << 0x12:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[GE1:imm1] << 0x11:32u))
      #|R0:imm32 := (R0:imm32 | (pad:32[GE0:imm1] << 0x10:32u))
    ),
  )
  inspect(
    lift_str("MSR", [i(0x8), r("R0"), ..al]),
    content=(
      #|NF:imm1 := extract[31:31](R0:imm32)
      #|ZF:imm1 := extract[30:30](R0:imm32)
      #|CF:imm1 := extract[29:29](R0:imm32)
      #|VF:imm1 := extract[28:28](R0:imm32)
      #|QF:imm1 := extract[27:27](R0:imm32)
    ),
  )
  inspect(
    lift_str("MSR", [i(0x4), r("R0"), ..al]),
    content=(
      #|GE3:imm1 := extract[19:19](R0:imm32)
      #|GE2:imm1 := extract[18:18](R0:imm32)
      #|GE1:imm1 := extract[17:17](R0:imm32)
      #|GE0:imm1 := extract[16:16](R0:imm32)
    ),
  )
  inspect(lift_str("MSR", [i(0x3), r("R0"), ..al]), content="")
  let init = state([("R0", 0)], flags=[
    ("NF", true),
    ("CF", true),
    ("QF", true),
    ("GE1", true),
  ])
  let s = run("MRS", [r("R0"), ..al], init)
  assert_eq(reg_value(s, "R0"), 0xA8020000)
  let s = run(
    "MSR",
    [i(0xC), r("R0"), ..al],
    state([("R0", 0x68080000)], flags=[("NF", true)]),
  )
  inspect(nzcv(s), content="-ZC-")
  assert_true(flag_value(s, "QF"))
  assert_true(flag_value(s, "GE3"))
  assert_true(!flag_value(s, "GE0"))
}

///|
test "hints and barriers are no-ops" {
  inspect(lift_str("DMB", [i(15)]), content="")
  inspect(lift_str("DSB", [i(15)]), content="")
  inspect(lift_str("HINT", [i(0), ..al]), content="")
  inspect(lift_str("CPS2p", [i(2), i(0)]), content="")
  inspect(lift_str("PLDi12", [r("R0"), i(0)]), content="")
  inspect(
    lift_error("MRS", [i(0), ..al]),
    content="Failure: MRS:ops ((Imm 0:32u) (Imm 0xE:32u) (Reg Nil)) doesn't match special insn MRS",
  )
}

///|
test "thumb-2 data processing and memory access" {
  inspect(
    lift_str("t2ADDri", [r("R0"), r("R1"), i(0x104), ..al, r("Nil")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := 0x104:32u
      #|R0:imm32 := (R1:imm32 + 0x104:32u)
    ),
  )
  inspect(
    lift_str("t2LDRi12", [r("R0"), r("SP"), i(8), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (SP:imm32 + 8:32u)):imm32
    ),
  )
  inspect(lift_str("t2Bcc", [i(8), ..al]), content="")
}
