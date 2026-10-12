///|
fn expect_int(value : Result[Int32, String]) -> Int32 raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_int64(value : Result[Int64, String]) -> Int64 raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_read(
  value : Result[(@dwarf.Leb128, Int32), String],
) -> (@dwarf.Leb128, Int32) raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP LEB128 examples read and write integers" {
  let (uint, uint_pos) = expect_read(@dwarf.Leb128::read(b"\xe5\x8e\x26"))
  assert_true(uint_pos == 3)
  assert_true(expect_int(uint.to_int()) == 624485)
  assert_true(uint.write() == b"\xe5\x8e\x26")
  let (sint, sint_pos) = expect_read(
    @dwarf.Leb128::read(b"\x9b\xf1\x59", signed=true),
  )
  assert_true(sint_pos == 3)
  assert_true(expect_int(sint.to_int()) == -624485)
  assert_true(sint.write() == b"\x9b\xf1\x59")
  let encoded = @dwarf.Leb128::of_int(624485, signed=true)
  assert_true(encoded.write() == b"\xe5\x8e\x26")
}

///|
test "translated BAP LEB128 Int32 aliases mirror Int conversion" {
  let unsigned = @dwarf.Leb128::of_int32(624485)
  assert_true(unsigned.write() == b"\xe5\x8e\x26")
  assert_true(expect_int(unsigned.to_int32()) == 624485)
  let signed = @dwarf.Leb128::of_int32(-624485, signed=true)
  assert_true(signed.write() == b"\x9b\xf1\x59")
  assert_true(expect_int(signed.to_int32()) == -624485)
  let wide = @dwarf.Leb128::of_int64(0x1_0000_0000L)
  assert_true(wide.to_int32() is Err(_))
}

///|
test "translated BAP LEB128 roundtrips Int values" {
  let unsigned_values = [
    0, 1, 2, 63, 64, 127, 128, 255, 256, 16384, 624485, 2147483647,
  ]
  for value in unsigned_values {
    let encoded = @dwarf.Leb128::of_int(value)
    let (read_back, next) = expect_read(@dwarf.Leb128::read(encoded.write()))
    assert_true(next == encoded.size())
    assert_true(expect_int(read_back.to_int()) == value)
  }
  let signed_values = [
    -2147483647 - 1,
    -624485,
    -8192,
    -129,
    -128,
    -65,
    -64,
    -2,
    -1,
    0,
    1,
    63,
    64,
    127,
    128,
    624485,
    2147483647,
  ]
  for value in signed_values {
    let encoded = @dwarf.Leb128::of_int(value, signed=true)
    let (read_back, next) = expect_read(
      @dwarf.Leb128::read(encoded.write(), signed=true),
    )
    assert_true(next == encoded.size())
    assert_true(expect_int(read_back.to_int()) == value)
  }
}

///|
test "translated BAP LEB128 roundtrips Int64 values" {
  let unsigned_values : Array[Int64] = [
    0L, 1L, 63L, 64L, 127L, 128L, 624485L, 2147483647L, 4294967295L, 9223372036854775807L,
  ]
  for value in unsigned_values {
    let encoded = @dwarf.Leb128::of_int64(value)
    let (read_back, next) = expect_read(@dwarf.Leb128::read(encoded.write()))
    assert_true(next == encoded.size())
    assert_true(expect_int64(read_back.to_int64()) == value)
  }
  let signed_values : Array[Int64] = [
    -9223372036854775807L - 1L,
    -4294967296L,
    -624485L,
    -129L,
    -128L,
    -65L,
    -64L,
    -1L,
    0L,
    1L,
    63L,
    64L,
    127L,
    128L,
    624485L,
    4294967295L,
    9223372036854775807L,
  ]
  for value in signed_values {
    let encoded = @dwarf.Leb128::of_int64(value, signed=true)
    let (read_back, next) = expect_read(
      @dwarf.Leb128::read(encoded.write(), signed=true),
    )
    assert_true(next == encoded.size())
    assert_true(expect_int64(read_back.to_int64()) == value)
  }
}

///|
test "translated BAP LEB128 sizes and read errors" {
  assert_true(@dwarf.Leb128::of_int(0).size() == 1)
  assert_true(@dwarf.Leb128::of_int(0, signed=true).size() == 1)
  assert_true(@dwarf.Leb128::of_int(1).size() == 1)
  assert_true(@dwarf.Leb128::of_int(1, signed=true).size() == 1)
  assert_true(@dwarf.Leb128::read(b"\x80") is Err(_))
  assert_true(@dwarf.Leb128::read(b"\x00", pos=2) is Err(_))
  match @dwarf.Leb128::read(b"\x00more", pos=0) {
    Ok((leb, next)) => {
      assert_true(next == 1)
      assert_true(expect_int(leb.to_int()) == 0)
    }
    Err(reason) => fail(reason)
  }
}
