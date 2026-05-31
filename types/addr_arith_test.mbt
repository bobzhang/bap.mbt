///|
test "BAP address R32 creation and word conversion preserve bit patterns" {
  let minus_one_word = @types.Word::of_uint64(width=32, 0xffffffffUL)
  let addr = @types.AddrR32::create_exn(minus_one_word)
  assert_true(addr.to_int32() == -1)
  assert_true(addr.to_uint().to_uint64() == 0xffffffffUL)
  assert_true(addr.to_word().to_hex() == "0xffffffff")
  let too_wide = @types.Word::of_uint64(width=33, 0x1ffffffffUL)
  assert_true(@types.AddrR32::create(too_wide) is Err(_))
}

///|
test "BAP address R32 arithmetic wraps and shifts modulo width" {
  let one = @types.AddrR32::one()
  let max = @types.AddrR32::of_int32(0x7fffffff)
  assert_true(max.succ().to_int32() == 0x80000000)
  assert_true(
    @types.AddrR32::zero().pred().to_uint().to_uint64() == 0xffffffffUL,
  )
  assert_true(one.lshift(@types.AddrR32::of_int32(32)).to_int32() == 1)
  assert_true(one.lshift(@types.AddrR32::of_int32(-1)).to_int32() == 0x80000000)
  let minus_eight = @types.AddrR32::of_int32(-8)
  assert_true(minus_eight.rshift(one).to_int32() == 0x7ffffffc)
  assert_true(minus_eight.arshift(one).to_int32() == -4)
  assert_true(
    @types.AddrR32::of_int32(0xf0)
    .logand(@types.AddrR32::of_int32(0x0f))
    .to_int32() ==
    0,
  )
}

///|
test "BAP address R64 creation and word conversion preserve bit patterns" {
  let minus_one_word = @types.Word::of_uint64(width=64, 0xffffffffffffffffUL)
  let addr = @types.AddrR64::create_exn(minus_one_word)
  assert_true(addr.to_int64() == -1L)
  assert_true(addr.to_uint64() == 0xffffffffffffffffUL)
  assert_true(addr.to_word().to_hex() == "0xffffffffffffffff")
  let too_wide = @types.Word::from_bitvec(@bitvec.ones(width=65))
  assert_true(@types.AddrR64::create(too_wide) is Err(_))
}

///|
test "BAP address R64 arithmetic wraps and shifts modulo width" {
  let one = @types.AddrR64::one()
  let max = @types.AddrR64::of_int64(0x7fffffffffffffffL)
  assert_true(max.succ().to_int64() == -9223372036854775808L)
  assert_true(@types.AddrR64::zero().pred().to_uint64() == 0xffffffffffffffffUL)
  assert_true(one.lshift(@types.AddrR64::of_int64(64L)).to_int64() == 1L)
  assert_true(
    one.lshift(@types.AddrR64::of_int64(-1L)).to_int64() ==
    -9223372036854775808L,
  )
  let minus_eight = @types.AddrR64::of_int64(-8L)
  assert_true(minus_eight.rshift(one).to_int64() == 0x7ffffffffffffffcL)
  assert_true(minus_eight.arshift(one).to_int64() == -4L)
  assert_true(
    @types.AddrR64::of_int64(0xf0L)
    .logxor(@types.AddrR64::of_int64(0xffL))
    .to_int64() ==
    0x0fL,
  )
}
