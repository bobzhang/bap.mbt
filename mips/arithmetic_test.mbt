///|
test "arithmetic: mips32 semantics" {
  inspect(
    show("mips", [
      ("ADD", [r("T0"), r("T1"), r("T2")]),
      ("ADDi", [r("T0"), r("T1"), i(-4)]),
      ("ADDiu", [r("SP"), r("SP"), i(-32)]),
      ("ADDiupc", [r("T0"), i(16)]),
      ("ADDu", [r("V0"), r("A0"), r("A1")]),
      ("LSA", [r("V0"), r("A0"), r("A1"), i(1)]),
      ("LUi", [r("GP"), i(0x1234)]),
      ("ALUipc", [r("T0"), i(2)]),
      ("SEB", [r("T0"), r("T1")]),
      ("SEH", [r("T0"), r("T1")]),
      ("SUB", [r("T0"), r("T1"), r("T2")]),
      ("SUBu", [r("T0"), r("T1"), r("T2")]),
    ]),
    content=(
      #|ADD T0, T1, T2
      #|  T0 := (T1 + T2)
      #|ADDi T0, T1, 0x-4
      #|  T0 := (T1 + 0xFFFFFFFC:32u)
      #|ADDiu SP, SP, 0x-20
      #|  SP := (SP + 0xFFFFFFE0:32u)
      #|ADDiupc T0, 0x10
      #|  T0 := (0x1000:32u + 0x10:32u)
      #|ADDu V0, A0, A1
      #|  V0 := (A0 + A1)
      #|LSA V0, A0, A1, 0x1
      #|  V0 := ((A0 << (1:32u + pad:32[1:8u])) + A1)
      #|LUi GP, 0x1234
      #|  GP := (0x1234:32u << pad:32[0x10:8u])
      #|ALUipc T0, 0x2
      #|  tmp2 := 0xFFFF:32u
      #|  tmp1 := (0x1000:32u + (2:32u << pad:32[0x10:8u]))
      #|  T0 := (~tmp2 & tmp1)
      #|SEB T0, T1
      #|  T1 := extend:32[extract:31:24[T0]]
      #|SEH T0, T1
      #|  T1 := extend:32[extract:31:16[T0]]
      #|SUB T0, T1, T2
      #|  T0 := (T1 - T2)
      #|SUBu T0, T1, T2
      #|  T0 := (T1 - T2)
      #|
    ),
  )
}

///|
test "arithmetic: mips64 semantics" {
  inspect(
    show("mips64", [
      ("ADDiu", [r("SP_64"), r("SP_64"), i(-32)]),
      ("DADDiu", [r("SP_64"), r("SP_64"), i(-32)]),
      ("DADDu", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DSUB", [r("T0_64"), r("T1_64"), r("T2_64")]),
      ("DSUBu", [r("T0_64"), r("T1_64"), r("T2_64")]),
      ("DLSA", [r("V0_64"), r("A0_64"), r("A1_64"), i(2)]),
      ("ADDiupc", [r("T0_64"), i(16)]),
    ]),
    content=(
      #|ADDiu SP_64, SP_64, 0x-20
      #|  SP := (SP + extend:64[0xFFFFFFE0:32u])
      #|DADDiu SP_64, SP_64, 0x-20
      #|  SP := (SP + extend:64[0xFFFFFFE0:32u])
      #|DADDu V0_64, A0_64, A1_64
      #|  V0 := (A0 + A1)
      #|DSUB T0_64, T1_64, T2_64
      #|  T0 := (T1 - T2)
      #|DSUBu T0_64, T1_64, T2_64
      #|  T0 := (T1 - T2)
      #|DLSA V0_64, A0_64, A1_64, 0x2
      #|  V0 := ((A0 << pad:64[(2:32u + pad:32[1:8u])]) + A1)
      #|ADDiupc T0_64, 0x10
      #|  T0 := (0x1000:64u + extend:64[0x10:32u])
      #|
    ),
  )
}

///|
test "arithmetic: evaluation" {
  assert_eq(
    eval32("ADDiu", [r("T0"), r("T1"), i(-1)], [("T1", 5)], "T0"),
    "4:32u",
  )
  assert_eq(
    eval32("ADD", [r("T0"), r("T1"), r("T2")], [("T1", 7), ("T2", 8)], "T0"),
    "0xF:32u",
  )
  assert_eq(eval32("LUi", [r("T0"), i(0x1234)], [], "T0"), "0x12340000:32u")
  assert_eq(
    eval32(
      "LSA",
      [r("T0"), r("T1"), r("T2"), i(1)],
      [("T1", 3), ("T2", 1)],
      "T0",
    ),
    "0xD:32u",
  )
  // SEB/SEH mirror upstream: they sign-extend the *most* significant part
  assert_eq(
    eval32("SEB", [r("T0"), r("T1")], [("T0", 0x80_00_00_12)], "T1"),
    "0xFFFFFF80:32u",
  )
  assert_eq(
    eval32("SEH", [r("T0"), r("T1")], [("T0", 0x7F_FF_00_00)], "T1"),
    "0x7FFF:32u",
  )
  assert_eq(
    eval32(
      "DSUBu",
      [r("T0_64"), r("T1_64"), r("T2_64")],
      [("T1", 1), ("T2", 2)],
      "T0",
      wide=true,
    ),
    "0xFFFFFFFFFFFFFFFF:64u",
  )
}

///|
test "arithmetic: count leading ones and zeroes" {
  // Mirrors upstream: operand 0 is the source and operand 1 the
  // destination, and the count starts from the least significant bit.
  let clz = @mips.lift_mips(insn("CLZ", [r("A0"), r("V0")]))
  inspect(
    clz.length(),
    content=(
      #|68
    ),
  )
  inspect(
    render(clz[:6].to_owned()),
    content=(
      #|tmp1 := A0
      #|tmp2 := pad:8[0:1u]
      #|tmp3 := 1:1u
      #|tmp4 := extract:0:0[tmp1]
      #|if (tmp3 & (tmp4 == 0:1u)) {
      #|  tmp2 := (tmp2 + pad:8[1:1u])
      #|} else {
      #|  tmp3 := 0:1u
      #|}
      #|tmp4 := extract:1:1[tmp1]
      #|
    ),
  )
  inspect(
    render([clz[clz.length() - 1]]),
    content=(
      #|V0 := pad:32[tmp2]
      #|
    ),
  )
  let clo = @mips.lift_mips(insn("CLO", [r("A0"), r("V0")]))
  inspect(
    render(clo[:6].to_owned()),
    content=(
      #|tmp1 := A0
      #|tmp2 := pad:8[0:1u]
      #|tmp3 := 1:1u
      #|tmp4 := extract:0:0[tmp1]
      #|if (tmp3 & (tmp4 == 1:1u)) {
      #|  tmp2 := (tmp2 + pad:8[1:1u])
      #|} else {
      #|  tmp3 := 0:1u
      #|}
      #|tmp4 := extract:1:1[tmp1]
      #|
    ),
  )
  assert_eq(eval32("CLZ", [r("A0"), r("V0")], [("A0", 0x10)], "V0"), "4:32u")
  assert_eq(eval32("CLZ", [r("A0"), r("V0")], [("A0", 0)], "V0"), "0x20:32u")
  assert_eq(eval32("CLO", [r("A0"), r("V0")], [("A0", 0x7)], "V0"), "3:32u")
  assert_eq(
    eval32("CLO", [r("A0_64"), r("V0_64")], [("A0", -1)], "V0", wide=true),
    "0x20:64u",
  )
}
