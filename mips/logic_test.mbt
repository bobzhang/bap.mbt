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
      #|  V0 := ~(A0 | 0:32u)
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
      #|  V0 := extend:64[(extract:23:16[extract:31:0[A0]] . (extract:31:24[extract:31:0[A0]] . (extract:7:0[extract:31:0[A0]] . extract:15:8[extract:31:0[A0]])))]
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
      #|1
    ),
  )
  inspect(
    render(bil[:7].to_owned()),
    content=(
      #|V0 := (((((((((((((((((((((((((((((((extract:24:24[A0] . extract:25:25[A0]) . extract:26:26[A0]) . extract:27:27[A0]) . extract:28:28[A0]) . extract:29:29[A0]) . extract:30:30[A0]) . extract:31:31[A0]) . extract:16:16[A0]) . extract:17:17[A0]) . extract:18:18[A0]) . extract:19:19[A0]) . extract:20:20[A0]) . extract:21:21[A0]) . extract:22:22[A0]) . extract:23:23[A0]) . extract:8:8[A0]) . extract:9:9[A0]) . extract:10:10[A0]) . extract:11:11[A0]) . extract:12:12[A0]) . extract:13:13[A0]) . extract:14:14[A0]) . extract:15:15[A0]) . extract:0:0[A0]) . extract:1:1[A0]) . extract:2:2[A0]) . extract:3:3[A0]) . extract:4:4[A0]) . extract:5:5[A0]) . extract:6:6[A0]) . extract:7:7[A0])
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
