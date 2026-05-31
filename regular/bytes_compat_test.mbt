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

///|
test "translated BAP bytes text and binary serialization round trip" {
  let bytes : Bytes = [
    0x54, 0x68, 0x69, 0x73, 0x00, 0xff, 0x20, 0x42, 0x41, 0x50,
  ]
  let atom = @regular.bytes_to_sexp_atom(bytes)
  inspect(atom, content="#bytes:5468697300ff20424150")
  match @regular.bytes_from_sexp_atom(atom) {
    Ok(decoded) => assert_true(decoded == bytes)
    Err(reason) => fail(reason)
  }
  let encoded = @regular.bytes_bin_write(bytes)
  assert_true(@regular.bytes_bin_size(bytes) == encoded.length())
  assert_true(byte_values(encoded[0:4].to_owned()) == [10, 0, 0, 0])
  match @regular.bytes_bin_read(encoded) {
    Ok((decoded, pos)) => {
      assert_true(decoded == bytes)
      assert_true(pos == encoded.length())
    }
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_from_hex("0ff") is Err(_))
  assert_true(@regular.bytes_bin_read(encoded[:6]) is Err(_))
}
