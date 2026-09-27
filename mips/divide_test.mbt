///|
test "divide: mips32 semantics" {
  inspect(
    show("mips", [
      ("SDIV", [r("A0"), r("A1")]),
      ("UDIV", [r("A0"), r("A1")]),
      ("MOD", [r("V0"), r("A0"), r("A1")]),
      ("MODu", [r("V0"), r("A0"), r("A1")]),
    ]),
    content=(
      #|SDIV A0, A1
      #|  LO := (A0 s/ A1)
      #|  HI := (A0 s% A1)
      #|UDIV A0, A1
      #|  LO := (A0 / A1)
      #|  HI := (A0 % A1)
      #|MOD V0, A0, A1
      #|  V0 := (A0 s% A1)
      #|MODu V0, A0, A1
      #|  V0 := (A0 % A1)
      #|
    ),
  )
}

///|
test "divide: mips64 semantics" {
  inspect(
    show("mips64", [
      ("SDIV", [r("A0_64"), r("A1_64")]),
      ("DDIV", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DMOD", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DDIVu", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DMODu", [r("V0_64"), r("A0_64"), r("A1_64")]),
    ]),
    content=(
      #|SDIV A0_64, A1_64
      #|  LO := extend:64[(extract:31:0[A0] s/ extract:31:0[A1])]
      #|  HI := extend:64[(extract:31:0[A0] s% extract:31:0[A1])]
      #|DDIV V0_64, A0_64, A1_64
      #|  V0 := (A0 s/ A1)
      #|DMOD V0_64, A0_64, A1_64
      #|  V0 := (A0 s% A1)
      #|DDIVu V0_64, A0_64, A1_64
      #|  V0 := (A0 / A1)
      #|DMODu V0_64, A0_64, A1_64
      #|  V0 := (A0 % A1)
      #|
    ),
  )
}

///|
test "divide: evaluation" {
  let bil = @mips.lift_mips(insn("SDIV", [r("A0"), r("A1")]))
  let state = run(bil, [("A0", word_value(32, -7)), ("A1", word_value(32, 2))])
  assert_eq(reg_hex(state, "LO"), "0xFFFFFFFD:32u")
  assert_eq(reg_hex(state, "HI"), "0xFFFFFFFF:32u")
  let bil = @mips.lift_mips(insn("UDIV", [r("A0"), r("A1")]))
  let state = run(bil, [("A0", word_value(32, 7)), ("A1", word_value(32, 2))])
  assert_eq(reg_hex(state, "LO"), "3:32u")
  assert_eq(reg_hex(state, "HI"), "1:32u")
  assert_eq(
    eval32(
      "DDIVu",
      [r("V0_64"), r("A0_64"), r("A1_64")],
      [("A0", 100), ("A1", 7)],
      "V0",
      wide=true,
    ),
    "0xE:64u",
  )
}
