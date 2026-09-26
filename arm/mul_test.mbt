///|
test "32-bit multiplies" {
  inspect(
    lift_str("MUL", [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")]),
    content=(
      #|R0:imm32 := (R1:imm32 * R2:imm32)
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("MLA", [r("R0"), r("R1"), r("R2"), r("R3"), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := (R3:imm32 + (R1:imm32 * R2:imm32))
    ),
  )
  inspect(
    lift_str("MLS", [r("R0"), r("R1"), r("R2"), r("R3"), ..al]),
    content=(
      #|R0:imm32 := (R3:imm32 - (R1:imm32 * R2:imm32))
    ),
  )
  let init = state([("R1", 0xFFFFFFFF), ("R2", 3), ("R3", 10)])
  let s = run("MUL", [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")], init)
  assert_eq(reg_value(s, "R0"), 0xFFFFFFFD)
  inspect(nzcv(s), content="N---")
  // the short form without the predicate register
  let s = run("MUL", [r("R0"), r("R2"), r("R3"), i(14), r("Nil")], init)
  assert_eq(reg_value(s, "R0"), 30)
  let s = run("MLA", [r("R0"), r("R2"), r("R3"), r("R2"), ..al, r("Nil")], init)
  assert_eq(reg_value(s, "R0"), 33)
  let s = run(
    "MLA",
    [r("R0"), r("R2"), r("R3"), r("R2"), i(14), r("Nil")],
    init,
  )
  assert_eq(reg_value(s, "R0"), 33)
  let s = run("MLS", [r("R0"), r("R2"), r("R2"), r("R3"), ..al], init)
  assert_eq(reg_value(s, "R0"), 1)
}

///|
test "long multiplies" {
  inspect(
    lift_str("UMULL", [r("R0"), r("R1"), r("R2"), r("R3"), ..al, r("CPSR")]),
    content=(
      #|%v1:imm64 := (pad:64[R2:imm32] * pad:64[R3:imm32])
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|R1:imm32 := extract[63:32](%v1:imm64)
      #|NF:imm1 := high:1[%v1:imm64]
      #|ZF:imm1 := (%v1:imm64 == 0:64u)
    ),
  )
  inspect(
    lift_str(
      "SMLAL",
      [r("R0"), r("R1"), r("R2"), r("R3"), r("R0"), r("R1"), ..al, r("Nil")],
    ),
    content=(
      #|%v1:imm64 := ((extend:64[R2:imm32] * extend:64[R3:imm32]) + concat(R1:imm32, R0:imm32))
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|R1:imm32 := extract[63:32](%v1:imm64)
    ),
  )
  let init = state([("R0", 1), ("R1", 2), ("R2", 0xFFFFFFFF), ("R3", 2)])
  let long = (name : String, ops : Array[@mc.Op]) => {
    let s = run(name, ops, init)
    (reg_value(s, "R0"), reg_value(s, "R1"))
  }
  let ops4 = [r("R0"), r("R1"), r("R2"), r("R3"), ..al, r("Nil")]
  let ops6 = [
    r("R0"),
    r("R1"),
    r("R2"),
    r("R3"),
    r("R0"),
    r("R1"),
    ..al,
    r("Nil"),
  ]
  debug_inspect(long("UMULL", ops4), content="(4294967294, 1)")
  debug_inspect(long("SMULL", ops4), content="(4294967294, 4294967295)")
  debug_inspect(long("UMLAL", ops6), content="(4294967295, 3)")
  debug_inspect(long("SMLAL", ops6), content="(4294967295, 1)")
  // short forms without the predicate register
  debug_inspect(
    long("UMULL", [r("R0"), r("R1"), r("R2"), r("R3"), i(14), r("Nil")]),
    content="(4294967294, 1)",
  )
  debug_inspect(
    long("SMLAL", [
      r("R0"),
      r("R1"),
      r("R2"),
      r("R3"),
      r("R0"),
      r("R1"),
      i(14),
      r("Nil"),
    ]),
    content="(4294967295, 1)",
  )
  let s = run(
    "UMULL",
    [r("R0"), r("R1"), r("R3"), r("R3"), ..al, r("CPSR")],
    init,
  )
  inspect(nzcv(s), content="----")
}

///|
test "signed halfword multiplies" {
  inspect(
    lift_str("SMULBB", [r("R0"), r("R1"), r("R2"), ..al]),
    content=(
      #|%v1:imm64 := (extend:64[extract[15:0](R1:imm32)] * extend:64[extract[15:0](R2:imm32)])
      #|R0:imm32 := extract[31:0](%v1:imm64)
    ),
  )
  inspect(
    lift_str("SMLABB", [r("R0"), r("R1"), r("R2"), r("R3"), ..al]),
    content=(
      #|%v1:imm64 := ((extend:64[extract[15:0](R1:imm32)] * extend:64[extract[15:0](R2:imm32)]) + extend:64[R3:imm32])
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|QF:imm1 := (extend:64[extract[31:0](%v1:imm64)] != %v1:imm64)
    ),
  )
  inspect(
    lift_str("SMUAD", [r("R0"), r("R1"), r("R2"), ..al]),
    content=(
      #|%v1:imm64 := ((extend:64[extract[31:16](R1:imm32)] * extend:64[extract[31:16](R2:imm32)]) + (extend:64[extract[15:0](R1:imm32)] * extend:64[extract[15:0](R2:imm32)]))
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|QF:imm1 := (extend:64[extract[31:0](%v1:imm64)] != %v1:imm64)
    ),
  )
  inspect(
    lift_str("SMLAD", [r("R0"), r("R1"), r("R2"), r("R3"), ..al]),
    content=(
      #|%v1:imm64 := (((extend:64[extract[31:16](R1:imm32)] * extend:64[extract[31:16](R2:imm32)]) + (extend:64[extract[15:0](R1:imm32)] * extend:64[extract[15:0](R2:imm32)])) + extend:64[R3:imm32])
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|QF:imm1 := (extend:64[extract[31:0](%v1:imm64)] != %v1:imm64)
    ),
  )
  inspect(
    lift_str("SMLAWB", [r("R0"), r("R1"), r("R2"), r("R3"), ..al]),
    content=(
      #|%v1:imm64 := (extend:64[extract[47:16]((extend:64[R1:imm32] * extend:64[extract[15:0](R2:imm32)]))] + extend:64[R3:imm32])
      #|R0:imm32 := extract[31:0](%v1:imm64)
      #|QF:imm1 := (extend:64[extract[31:0](%v1:imm64)] != %v1:imm64)
    ),
  )
  inspect(
    lift_str("SMULTB", [r("R0"), r("R1"), r("R2"), ..al]),
    content=(
      #|%v1:imm64 := (extend:64[extract[31:16](R1:imm32)] * extend:64[extract[15:0](R2:imm32)])
      #|R0:imm32 := extract[31:0](%v1:imm64)
    ),
  )
  inspect(
    lift_str("SMLALBT", [r("R0"), r("R1"), r("R2"), r("R3"), ..al]),
    content=(
      #|%v1:imm64 := ((extend:64[extract[15:0](R2:imm32)] * extend:64[extract[31:16](R3:imm32)]) + concat(R1:imm32, R0:imm32))
      #|R1:imm32 := extract[63:32](%v1:imm64)
      #|R0:imm32 := extract[31:0](%v1:imm64)
    ),
  )
  let init = state([
    ("R0", 5),
    ("R1", 1),
    ("R2", 0x0002FFFD),
    ("R3", 0x00040003),
  ])
  let smul = (name : String, ops : Array[@mc.Op]) => {
    reg_value(run(name, ops, init), "R0")
  }
  // bottom(-3) * bottom(3)
  assert_eq(smul("SMULBB", [r("R0"), r("R2"), r("R3"), ..al]), 0xFFFFFFF7)
  // + R1
  assert_eq(
    smul("SMLABB", [r("R0"), r("R2"), r("R3"), r("R1"), ..al]),
    0xFFFFFFF8,
  )
  // top(2) * bottom(3)
  assert_eq(smul("SMULTB", [r("R0"), r("R2"), r("R3"), ..al]), 6)
  // 2*4 + (-3)*3
  assert_eq(smul("SMUAD", [r("R0"), r("R2"), r("R3"), ..al]), 0xFFFFFFFF)
  assert_eq(smul("SMLAD", [r("R0"), r("R2"), r("R3"), r("R1"), ..al]), 0)
  // (0x10000 * bottom(-3)) >> 16 + 0x40003
  let s = run(
    "SMLAWB",
    [r("R0"), r("R1"), r("R2"), r("R3"), ..al],
    state([("R1", 0x10000), ("R2", 0x0002FFFD), ("R3", 0x00040003)]),
  )
  assert_eq(reg_value(s, "R0"), 0x40000)
  // 64-bit accumulate into R1:R0 of bottom(-3) * top(4)
  let s = run("SMLALBT", [r("R0"), r("R1"), r("R2"), r("R3"), ..al], init)
  assert_eq(reg_value(s, "R0"), 0xFFFFFFF9)
  assert_eq(reg_value(s, "R1"), 0)
}
