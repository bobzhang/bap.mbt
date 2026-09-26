///|
test "multiply: mips32 semantics" {
  inspect(
    show("mips", [
      ("MUL", [r("V0"), r("A0"), r("A1")]),
      ("MUH", [r("V0"), r("A0"), r("A1")]),
      ("MULu", [r("V0"), r("A0"), r("A1")]),
      ("MUHu", [r("V0"), r("A0"), r("A1")]),
      ("MULT", [r("A0"), r("A1")]),
      ("MULTu", [r("A0"), r("A1")]),
    ]),
    content=(
      #|MUL V0, A0, A1
      #|  V0 := (A0 * A1)
      #|MUH V0, A0, A1
      #|  V0 := (A0 * A1)
      #|MULu V0, A0, A1
      #|  V0 := (A0 * A1)
      #|MUHu V0, A0, A1
      #|  V0 := (A0 * A1)
      #|MULT A0, A1
      #|  tmp1 := extend:64[(A0 * A1)]
      #|  HI := extract:63:32[tmp1]
      #|  LO := extract:31:0[tmp1]
      #|MULTu A0, A1
      #|  tmp1 := pad:64[(A0 * A1)]
      #|  HI := extract:63:32[tmp1]
      #|  LO := extract:31:0[tmp1]
      #|
    ),
  )
}

///|
test "multiply: mips64 semantics" {
  inspect(
    show("mips64", [
      ("DMUL", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DMUH", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DMULu", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DMUHu", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("MULT", [r("A0_64"), r("A1_64")]),
    ]),
    content=(
      #|DMUL V0_64, A0_64, A1_64
      #|  tmp1 := extend:128[(A0 * A1)]
      #|  V0 := extract:63:0[tmp1]
      #|DMUH V0_64, A0_64, A1_64
      #|  tmp1 := extend:128[(A0 * A1)]
      #|  V0 := extract:127:64[tmp1]
      #|DMULu V0_64, A0_64, A1_64
      #|  tmp1 := pad:128[(A0 * A1)]
      #|  V0 := extract:63:0[tmp1]
      #|DMUHu V0_64, A0_64, A1_64
      #|  tmp1 := pad:128[(A0 * A1)]
      #|  V0 := extract:127:64[tmp1]
      #|MULT A0_64, A1_64
      #|  tmp1 := (A0 * A1)
      #|  HI := pad:64[extract:63:32[tmp1]]
      #|  LO := pad:64[extract:31:0[tmp1]]
      #|
    ),
  )
}

///|
test "multiply: evaluation" {
  let bil = @mips.lift_mips(insn("MULT", [r("A0"), r("A1")]))
  let state = run(bil, [("A0", word_value(32, -2)), ("A1", word_value(32, 3))])
  assert_eq(reg_hex(state, "LO"), "0xFFFFFFFA:32u")
  assert_eq(reg_hex(state, "HI"), "0xFFFFFFFF:32u")
  // Like upstream, the product is computed at operand width and then
  // extended, so the high word only carries the extension bits.
  let bil = @mips.lift_mips(insn("MULTu", [r("A0"), r("A1")]))
  let state = run(bil, [
    ("A0", word_value(32, 0x8000_0000)),
    ("A1", word_value(32, 4)),
  ])
  assert_eq(reg_hex(state, "LO"), "0:32u")
  assert_eq(reg_hex(state, "HI"), "0:32u")
  assert_eq(
    eval32("MUL", [r("V0"), r("A0"), r("A1")], [("A0", 6), ("A1", 7)], "V0"),
    "0x2A:32u",
  )
  assert_eq(
    eval32(
      "DMUHu",
      [r("V0_64"), r("A0_64"), r("A1_64")],
      [("A0", -1), ("A1", 2)],
      "V0",
      wide=true,
    ),
    "0:64u",
  )
}
