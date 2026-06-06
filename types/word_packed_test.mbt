///|
fn word128(hex : String) -> @types.Word raise {
  @types.Word::from_string("0x" + hex + ":128u")
}

///|
fn assert_word_result(
  label : String,
  result : Result[@types.Word, String],
  expected : @types.Word,
) -> Unit raise {
  match result {
    Ok(word) => assert_true(word == expected)
    Err(reason) => fail(label + ": " + reason)
  }
}

///|
test "translated BAP x86 packed compare byte semantics" {
  let ascending = word128("0f0e0d0c0b0a09080706050403020100")
  let endpoints = word128("0f000000000000000000000000000000")
  assert_word_result(
    "pcmpeqb",
    endpoints.packed_eq(ascending, element_width=8),
    word128("ff0000000000000000000000000000ff"),
  )
  assert_word_result(
    "pcmpgtb",
    ascending.packed_gt(endpoints, element_width=8, signed=true),
    word128("00ffffffffffffffffffffffffffff00"),
  )
}

///|
test "translated BAP x86 packed byte min max semantics" {
  let source = word128("0f0e0d0c0b0a09080706050403020100")
  let dest = word128("ff0000000000000000000000000000ff")
  assert_word_result(
    "pminub",
    dest.packed_min(source, element_width=8),
    word128("0f000000000000000000000000000000"),
  )
  assert_word_result(
    "pminsb",
    dest.packed_min(source, element_width=8, signed=true),
    word128("ff0000000000000000000000000000ff"),
  )
  assert_word_result(
    "pmaxub",
    dest.packed_max(source, element_width=8),
    word128("ff0e0d0c0b0a090807060504030201ff"),
  )
  assert_word_result(
    "pmaxsb",
    dest.packed_max(source, element_width=8, signed=true),
    word128("0f0e0d0c0b0a09080706050403020100"),
  )
}

///|
test "translated BAP x86 packed word and dword min max semantics" {
  let source = word128("8f0e00000b0a09080506050403040100")
  let dest = word128("0f000d0c000000000706050503020000")
  assert_word_result(
    "pmaxuw",
    dest.packed_max(source, element_width=16),
    word128("8f0e0d0c0b0a09080706050503040100"),
  )
  assert_word_result(
    "pmaxsw",
    dest.packed_max(source, element_width=16, signed=true),
    word128("0f000d0c0b0a09080706050503040100"),
  )
  assert_word_result(
    "pminuw",
    dest.packed_min(source, element_width=16),
    word128("0f000000000000000506050403020000"),
  )
  assert_word_result(
    "pminsw",
    dest.packed_min(source, element_width=16, signed=true),
    word128("8f0e0000000000000506050403020000"),
  )
  assert_word_result(
    "pminud",
    dest.packed_min(source, element_width=32),
    word128("0f000d0c000000000506050403020000"),
  )
  assert_word_result(
    "pminsd",
    dest.packed_min(source, element_width=32, signed=true),
    word128("8f0e0000000000000506050403020000"),
  )
  assert_word_result(
    "pmaxud",
    dest.packed_max(source, element_width=32),
    word128("8f0e00000b0a09080706050503040100"),
  )
  assert_word_result(
    "pmaxsd",
    dest.packed_max(source, element_width=32, signed=true),
    word128("0f000d0c0b0a09080706050503040100"),
  )
}

///|
test "translated BAP x86 pshufb byte shuffle semantics" {
  let origin = word128("504f4e4d4c4b4a494847464544434241")
  assert_word_result(
    "pshufb identity",
    origin.x86_pshufb(word128("0f0e0d0c0b0a09080706050403020100")),
    origin,
  )
  assert_word_result(
    "pshufb last three byte one",
    origin.x86_pshufb(word128("0f0e0d0c0b0a09080706050403010101")),
    word128("504f4e4d4c4b4a494847464544424242"),
  )
  assert_word_result(
    "pshufb first three byte one",
    origin.x86_pshufb(word128("0101010c0b0a09080706050403020100")),
    word128("4242424d4c4b4a494847464544434241"),
  )
  assert_word_result(
    "pshufb last three zero",
    origin.x86_pshufb(word128("0f0e0d0c0b0a09080706050403808080")),
    word128("504f4e4d4c4b4a494847464544000000"),
  )
}

///|
test "packed word helpers reject invalid layouts" {
  let value = word128("00000000000000000000000000000000")
  let narrow = @types.Word::zero(width=64)
  assert_true(
    value.packed_min(narrow, element_width=8) ==
    Err("packed word operation requires matching widths"),
  )
  assert_true(
    value.packed_eq(value, element_width=7) ==
    Err(
      "packed word operation requires an element width that divides the word width",
    ),
  )
  assert_true(
    value.x86_pshufb(narrow) == Err("pshufb requires matching operand widths"),
  )
}
