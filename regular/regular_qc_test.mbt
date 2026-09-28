// Property-based tests for `regular`: the byte codecs round trip, the
// length-prefixed reader is robust on arbitrary input, and the prefix and
// suffix tries agree with a map model.

///|
/// Regression (found by "qc: bytes_bin_read never reads out of bounds"): a
/// length prefix near 2^31 made `pos + 4 + len` overflow to a negative
/// Int, which passed the bounds check and aborted on the slice.
test "regression: bytes_bin_read rejects a length that overflows the end offset" {
  assert_true(@regular.bytes_bin_read(b"\xff\xff\xff\x7f") is Err(_))
  assert_true(@regular.bytes_bin_read(b"\xfd\xff\xff\x7f\x00") is Err(_))
  assert_true(
    @regular.bytes_bin_read(b"\x00\x00\x00\x00", pos=0x7fff_fffe) is Err(_),
  )
  assert_eq(@regular.bytes_bin_read(b"\x01\x00\x00\x00\x2a"), Ok((b"\x2a", 5)))
}
