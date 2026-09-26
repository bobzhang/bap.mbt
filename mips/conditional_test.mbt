///|
test "conditional: mips32 semantics" {
  inspect(
    show("mips", [
      ("SLT", [r("V0"), r("V1"), r("A0")]),
      ("SLTi", [r("V0"), r("V1"), i(7)]),
      ("SLTu", [r("V0"), r("V1"), r("A0")]),
      ("SLTiu", [r("V0"), r("V1"), i(-1)]),
      ("SELEQZ", [r("V0"), r("V1"), r("A0")]),
      ("SELNEQ", [r("V0"), r("V1"), r("A0")]),
    ]),
    content=(
      #|SLT V0, V1, A0
      #|  if (V1 s< A0) {
      #|    V0 := pad:32[1:1u]
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|SLTi V0, V1, 0x7
      #|  if (V1 s< 7:32u) {
      #|    V0 := pad:32[1:1u]
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|SLTu V0, V1, A0
      #|  if (V1 < A0) {
      #|    V0 := pad:32[1:1u]
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|SLTiu V0, V1, 0x-1
      #|  if (V1 < 0xFFFFFFFF:32u) {
      #|    V0 := pad:32[1:1u]
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|SELEQZ V0, V1, A0
      #|  if (A0 == pad:32[0:1u]) {
      #|    V0 := V1
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|SELNEQ V0, V1, A0
      #|  if (A0 != pad:32[0:1u]) {
      #|    V0 := V1
      #|  } else {
      #|    V0 := pad:32[0:1u]
      #|  }
      #|
    ),
  )
}

///|
test "conditional: mips64 semantics" {
  inspect(
    show("mips64", [
      ("SLT", [r("V0_64"), r("V1_64"), r("A0_64")]),
      ("SLTiu", [r("V0_64"), r("V1_64"), i(7)]),
    ]),
    content=(
      #|SLT V0_64, V1_64, A0_64
      #|  if (V1 s< A0) {
      #|    V0 := pad:64[1:1u]
      #|  } else {
      #|    V0 := pad:64[0:1u]
      #|  }
      #|SLTiu V0_64, V1_64, 0x7
      #|  if (V1 < extend:64[7:32u]) {
      #|    V0 := pad:64[1:1u]
      #|  } else {
      #|    V0 := pad:64[0:1u]
      #|  }
      #|
    ),
  )
}

///|
test "conditional: evaluation" {
  let slt = [r("V0"), r("V1"), r("A0")]
  assert_eq(eval32("SLT", slt, [("V1", -1), ("A0", 1)], "V0"), "1:32u")
  assert_eq(eval32("SLT", slt, [("V1", 2), ("A0", 1)], "V0"), "0:32u")
  assert_eq(eval32("SLTu", slt, [("V1", -1), ("A0", 1)], "V0"), "0:32u")
  assert_eq(
    eval32("SLTiu", [r("V0"), r("V1"), i(-1)], [("V1", 5)], "V0"),
    "1:32u",
  )
  assert_eq(eval32("SELEQZ", slt, [("V1", 9), ("A0", 0)], "V0"), "9:32u")
  assert_eq(eval32("SELNEQ", slt, [("V1", 9), ("A0", 0)], "V0"), "0:32u")
}
