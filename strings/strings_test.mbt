///|
fn byte_values(data : Bytes) -> Array[Int] {
  data.to_array().map(byte => byte.to_int())
}

///|
test "translated BAP strings scanner returns contiguous printable byte runs" {
  let data = b"\x00hello\tworld\x00A B\nC\xff"
  let runs = @strings.StringsScanner::scan_bytes(data)
  assert_eq(runs.length(), 2)
  assert_eq(runs[0].0, 1)
  assert_true(byte_values(runs[0].1) == byte_values(b"hello\tworld"))
  assert_eq(runs[1].0, 13)
  assert_true(byte_values(runs[1].1) == byte_values(b"A B\nC"))
}

///|
test "translated BAP strings scanner supports custom stop predicates and offsets" {
  let data = b"aa,bbb;cc"
  let read = @strings.StringsScanner::read_bytes(data)
  let first = @strings.StringsScanner::next(read, 0, is_stop=byte => {
    byte == b','
  })
  assert_true(byte_values(first) == byte_values(b"aa"))
  let runs = @strings.StringsScanner::scan_bytes(data, offset=3, is_stop=byte => {
    byte == b';'
  })
  assert_eq(runs.length(), 2)
  assert_eq(runs[0].0, 3)
  assert_true(byte_values(runs[0].1) == byte_values(b"bbb"))
  assert_eq(runs[1].0, 7)
  assert_true(byte_values(runs[1].1) == byte_values(b"cc"))
}

///|
test "translated BAP persistent strings index assigns stable keys" {
  let index = @strings.StringsIndex::empty_int()
  assert_eq(index.string(0).length(), 0)
  assert_eq(index.key(b"alpha"), 0)
  let index = index.register(b"alpha")
  let index = index.register(b"beta")
  let again = index.register(b"alpha")
  assert_true(index.registered(b"alpha"))
  assert_true(!index.registered(b"missing"))
  assert_eq(index.key(b"alpha"), 1)
  assert_eq(index.key(b"beta"), 2)
  assert_eq(again.key(b"alpha"), 1)
  assert_true(byte_values(index.string(1)) == byte_values(b"alpha"))
  assert_true(byte_values(index.string(2)) == byte_values(b"beta"))
}
