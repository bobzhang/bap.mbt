///|
test "shift: mips32 semantics" {
  inspect(
    show("mips", [
      ("ROTR", [r("V0"), r("A0"), i(8)]),
      ("ROTRV", [r("V0"), r("A0"), r("A1")]),
      ("SLL", [r("V0"), r("A0"), i(2)]),
      ("SLLV", [r("V0"), r("A0"), r("A1")]),
      ("SRA", [r("V0"), r("A0"), i(2)]),
      ("SRAV", [r("V0"), r("A0"), r("A1")]),
      ("SRL", [r("V0"), r("A0"), i(2)]),
      ("SRLV", [r("V0"), r("A0"), r("A1")]),
    ]),
    content=(
      #|ROTR V0, A0, 0x8
      #|  tmp1 := A0
      #|  tmp2 := (tmp1 >> 8:32u)
      #|  tmp1 := (tmp1 << (pad:32[0x20:8u] - 8:32u))
      #|  V0 := (tmp1 | tmp2)
      #|ROTRV V0, A0, A1
      #|  tmp1 := A0
      #|  tmp2 := (tmp1 >> A1)
      #|  tmp1 := (tmp1 << (pad:32[0x20:8u] - A1))
      #|  V0 := (tmp1 | tmp2)
      #|SLL V0, A0, 0x2
      #|  V0 := (A0 << 2:32u)
      #|SLLV V0, A0, A1
      #|  V0 := (A0 << A1)
      #|SRA V0, A0, 0x2
      #|  V0 := (A0 a>> 2:32u)
      #|SRAV V0, A0, A1
      #|  V0 := (A0 a>> pad:32[extract:31:27[A1]])
      #|SRL V0, A0, 0x2
      #|  V0 := (A0 >> 2:32u)
      #|SRLV V0, A0, A1
      #|  V0 := (A0 >> A1)
      #|
    ),
  )
}

///|
test "shift: mips64 semantics" {
  inspect(
    show("mips64", [
      ("SLL", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSLL", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSLL32", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSLLV", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DSRA", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSRA32", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSRAV", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("DSRL", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSRL32", [r("V0_64"), r("A0_64"), i(2)]),
      ("DSRLV", [r("V0_64"), r("A0_64"), r("A1_64")]),
    ]),
    content=(
      #|SLL V0_64, A0_64, 0x2
      #|  V0 := extend:64[(extract:31:0[A0] << 2:32u)]
      #|DSLL V0_64, A0_64, 0x2
      #|  V0 := (A0 << pad:64[2:32u])
      #|DSLL32 V0_64, A0_64, 0x2
      #|  V0 := (A0 << pad:64[(2:32u + pad:32[0x20:8u])])
      #|DSLLV V0_64, A0_64, A1_64
      #|  V0 := (A0 << A1)
      #|DSRA V0_64, A0_64, 0x2
      #|  V0 := (A0 a>> pad:64[2:32u])
      #|DSRA32 V0_64, A0_64, 0x2
      #|  V0 := (A0 a>> pad:64[(2:32u + pad:32[0x20:8u])])
      #|DSRAV V0_64, A0_64, A1_64
      #|  V0 := (A0 a>> A1)
      #|DSRL V0_64, A0_64, 0x2
      #|  V0 := (A0 >> pad:64[2:32u])
      #|DSRL32 V0_64, A0_64, 0x2
      #|  V0 := (A0 >> pad:64[(2:32u + pad:32[0x20:8u])])
      #|DSRLV V0_64, A0_64, A1_64
      #|  V0 := (A0 >> A1)
      #|
    ),
  )
}

///|
test "shift: evaluation" {
  let a0 = [("A0", 0x8000_00F0L)]
  assert_eq(eval32("SLL", [r("V0"), r("A0"), i(4)], a0, "V0"), "0xF00:32u")
  assert_eq(eval32("SRL", [r("V0"), r("A0"), i(4)], a0, "V0"), "0x800000F:32u")
  assert_eq(eval32("SRA", [r("V0"), r("A0"), i(4)], a0, "V0"), "0xF800000F:32u")
  assert_eq(
    eval32("ROTR", [r("V0"), r("A0"), i(8)], a0, "V0"),
    "0xF0800000:32u",
  )
  assert_eq(
    eval32("SLLV", [r("V0"), r("A0"), r("A1")], [("A0", 1), ("A1", 3)], "V0"),
    "8:32u",
  )
  assert_eq(
    eval32(
      "DSLL32",
      [r("V0_64"), r("A0_64"), i(1)],
      [("A0", 1)],
      "V0",
      wide=true,
    ),
    "0x200000000:64u",
  )
  assert_eq(
    eval32(
      "DSRA",
      [r("V0_64"), r("A0_64"), i(4)],
      [("A0", -256)],
      "V0",
      wide=true,
    ),
    "0xFFFFFFFFFFFFFFF0:64u",
  )
  assert_eq(
    eval32(
      "DSRL32",
      [r("V0_64"), r("A0_64"), i(0)],
      [("A0", -1)],
      "V0",
      wide=true,
    ),
    "0xFFFFFFFF:64u",
  )
}
