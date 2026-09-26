///|
test "logic: mips32 semantics" {
  inspect(
    show("mips", [
      ("AND", [r("V0"), r("A0"), r("A1")]),
      ("ANDi", [r("V0"), r("A0"), i(0xFF)]),
      ("NOP", []),
      ("NOR", [r("V0"), r("A0"), r("ZERO")]),
      ("NOT", [r("V0"), r("A0")]),
      ("OR", [r("V0"), r("A0"), r("A1")]),
      ("ORi", [r("V0"), r("A0"), i(0x8000)]),
      ("XOR", [r("V0"), r("A0"), r("A1")]),
      ("XORi", [r("V0"), r("A0"), i(1)]),
      ("WSBH", [r("V0"), r("A0")]),
    ]),
    content=(
      #|AND V0, A0, A1
      #|  V0 := (A0 & A1)
      #|ANDi V0, A0, 0xff
      #|  V0 := (A0 & 0xFF:32u)
      #|NOP 
      #|NOR V0, A0, ZERO
      #|  V0 := ~(A0 | ZERO)
      #|NOT V0, A0
      #|  V0 := ~A0
      #|OR V0, A0, A1
      #|  V0 := (A0 | A1)
      #|ORi V0, A0, 0x8000
      #|  V0 := (A0 | 0x8000:32u)
      #|XOR V0, A0, A1
      #|  V0 := (A0 ^ A1)
      #|XORi V0, A0, 0x1
      #|  V0 := (A0 ^ 1:32u)
      #|WSBH V0, A0
      #|  V0 := (extract:23:16[A0] . (extract:31:24[A0] . (extract:7:0[A0] . extract:15:8[A0])))
      #|
    ),
  )
}

///|
test "logic: mips64 semantics" {
  inspect(
    show("mips64", [
      ("AND", [r("V0_64"), r("A0_64"), r("A1_64")]),
      ("ORi", [r("V0_64"), r("A0_64"), i(0x8000)]),
      ("WSBH", [r("V0_64"), r("A0_64")]),
      ("DSBH", [r("V0_64"), r("A0_64")]),
    ]),
    content=(
      #|AND V0_64, A0_64, A1_64
      #|  V0 := (A0 & A1)
      #|ORi V0_64, A0_64, 0x8000
      #|  V0 := (A0 | pad:64[0x8000:32u])
      #|WSBH V0_64, A0_64
      #|  V0 := pad:64[(extract:23:16[A0] . (extract:31:24[A0] . (extract:7:0[A0] . extract:15:8[A0])))]
      #|DSBH V0_64, A0_64
      #|  V0 := (extract:55:48[A0] . (extract:63:56[A0] . (extract:39:32[A0] . (extract:47:40[A0] . (extract:23:16[A0] . (extract:31:24[A0] . (extract:7:0[A0] . extract:15:8[A0])))))))
      #|
    ),
  )
}

///|
test "logic: bitswap" {
  let bil = @mips.lift_mips(insn("BITSWAP", [r("V0"), r("A0")]))
  inspect(
    bil.length(),
    content=(
      #|193
    ),
  )
  inspect(
    render(bil[:7].to_owned()),
    content=(
      #|tmp1 := pad:8[0:1u]
      #|tmp2 := extract:0:0[V0]
      #|tmp4 := (tmp1 / 8:8u)
      #|tmp3 := ((tmp4 * 8:8u) + (7:8u - (tmp1 % 8:8u)))
      #|tmp2 := extract:0:0[(A0 >> pad:32[tmp3])]
      #|tmp1 := (tmp1 + pad:8[1:1u])
      #|V0 := (extract:31:1[V0] . tmp2)
      #|
    ),
  )
  assert_eq(
    eval32(
      "BITSWAP",
      [r("V0"), r("A0")],
      [("A0", 0x01_80_0F_03), ("V0", 0)],
      "V0",
    ),
    "0x8001F0C0:32u",
  )
  assert_eq(
    eval32(
      "DBITSWAP",
      [r("V0_64"), r("A0_64")],
      [("A0", 0x01_02_04_08_10_20_40_80), ("V0", 0)],
      "V0",
      wide=true,
    ),
    "0x8040201008040201:64u",
  )
}

///|
test "logic: evaluation" {
  let rrr = [r("V0"), r("A0"), r("A1")]
  let regs = [("A0", 0x0FF0L), ("A1", 0x00FFL)]
  assert_eq(eval32("AND", rrr, regs, "V0"), "0xF0:32u")
  assert_eq(eval32("OR", rrr, regs, "V0"), "0xFFF:32u")
  assert_eq(eval32("XOR", rrr, regs, "V0"), "0xF0F:32u")
  assert_eq(eval32("NOR", rrr, regs, "V0"), "0xFFFFF000:32u")
  assert_eq(eval32("NOT", [r("V0"), r("A0")], regs, "V0"), "0xFFFFF00F:32u")
  assert_eq(
    eval32("ANDi", [r("V0"), r("A0"), i(0xFFFF)], [("A0", -1)], "V0"),
    "0xFFFF:32u",
  )
  assert_eq(
    eval32("WSBH", [r("V0"), r("A0")], [("A0", 0x11223344)], "V0"),
    "0x22114433:32u",
  )
  assert_eq(
    eval32(
      "DSBH",
      [r("V0_64"), r("A0_64")],
      [("A0", 0x1122334455667788)],
      "V0",
      wide=true,
    ),
    "0x2211443366558877:64u",
  )
}
