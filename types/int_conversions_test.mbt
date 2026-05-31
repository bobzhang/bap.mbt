///|
test "BAP-style int conversions accept values representable as MoonBit Int" {
  assert_true(@types.int_of_int32(-7) == Ok(-7))
  assert_true(@types.int_of_int64(0x7fffffffL) == Ok(0x7fffffff))
  assert_true(@types.int_of_int64(-0x80000000L) == Ok(0x80000000))
  assert_true(@types.int_of_uint64(0x7fffffffUL) == Ok(0x7fffffff))
}

///|
test "BAP-style int conversions reject values outside MoonBit Int range" {
  assert_true(@types.int_of_int64(0x80000000L) is Err(_))
  assert_true(@types.int_of_int64(-0x80000001L) is Err(_))
  assert_true(@types.int_of_uint64(0x80000000UL) is Err(_))
}

///|
test "BAP-style word to int conversion delegates to checked word conversion" {
  let small = try! @types.Word::of_int(width=8, 42)
  let wide = try! @types.Word::of_uint64(width=64, 0x80000000UL)
  let signed_min = try! @types.Word::of_uint64(width=32, 0x80000000UL)
  assert_true(@types.int_of_word(small) == Ok(42))
  assert_true(@types.int_of_word(signed_min.signed()) == Ok(0x80000000))
  assert_true(@types.int_of_word(wide) is Err(_))
}
