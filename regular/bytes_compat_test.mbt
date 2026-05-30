///|
fn byte_values(bytes : Bytes) -> Array[Int] {
  bytes.to_array().map(byte => byte.to_int())
}

///|
test "translated BAP bytes create allocates zero-filled byte storage" {
  let bytes = Bytes::new(8)
  assert_true(bytes.length() == 8)
  assert_true(byte_values(bytes) == [0, 0, 0, 0, 0, 0, 0, 0])
}

///|
test "translated BAP bytes copy preserves value while owning storage" {
  let source : Array[Byte] = [84, 101, 115, 116]
  let bytes = Bytes::from_array(source)
  source[0] = 0
  assert_true(byte_values(bytes) == [84, 101, 115, 116])
  let copied = Bytes::makei(bytes.length(), i => bytes[i])
  assert_true(copied == bytes)
  assert_true(byte_values(copied) == [84, 101, 115, 116])
}
