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

///|
test "translated BAP strings alphabets expose source-compatible indexes" {
  let alpha = @strings.StringsAlphabet::alpha()
  assert_eq(alpha.length(), 52)
  assert_eq(alpha.index(b'A'), 0)
  assert_eq(alpha.index(b'Z'), 25)
  assert_eq(alpha.index(b'a'), 26)
  assert_eq(alpha.index(b'z'), 51)
  assert_true(!alpha.contains(b'0'))

  let caseless = @strings.StringsAlphabet::alpha_caseless()
  assert_eq(caseless.index(b'a'), 0)
  assert_eq(caseless.index(b'A'), 0)
  assert_true(caseless.contains(b'z'))

  let alphanum = @strings.StringsAlphabet::alphanum()
  assert_eq(alphanum.index(b'0'), 52)
  assert_eq(alphanum.index(b'9'), 61)
  assert_eq(@strings.StringsAlphabet::printable().index(b' '), 0)
}

///|
test "translated BAP strings unscrambler builds dictionary words from bytes" {
  let dict = @strings.StringsUnscrambler::empty(
      alphabet=@strings.StringsAlphabet::alpha_caseless(),
    )
    .add_word(b"hell")
    .add_word(b"hello")
    .add_word(b"ell")
    .add_word(b"hoe")
    .add_word(b"hold")
  let built = dict.build(b"heLLo-")
  assert_true(built.contains(b"hell"))
  assert_true(built.contains(b"hello"))
  assert_true(built.contains(b"ell"))
  assert_true(built.contains(b"hoe"))
  assert_true(!built.contains(b"hold"))
  assert_true(dict.is_buildable(b"oleh"))
  assert_true(!dict.is_buildable(b"xyz"))
}

///|
test "translated BAP strings unscrambler loads newline dictionaries" {
  let dict = @strings.StringsUnscrambler::of_bytes(
    alphabet=@strings.StringsAlphabet::alpha_caseless(),
    b"one\ntwo\r\nthree",
  )
  assert_eq(dict.words().length(), 3)
  assert_true(dict.build(b"neo").contains(b"one"))
  assert_true(dict.build(b"owt").contains(b"two"))
  assert_true(dict.build(b"ether").contains(b"three"))
}

///|
test "translated BAP strings detector emits finished decisions" {
  let detector : @strings.StringsDetector[Int] = @strings.StringsDetector::create(
    @strings.StringsAlphabet::alpha_caseless(),
    beta=0.4,
  )
  let trace = [
    (0, b'a'),
    (1, b'b'),
    (2, b'c'),
    (3, b'!'),
    (4, b'!'),
    (5, b'!'),
    (6, b'!'),
    (7, b'!'),
  ]
  let decisions = detector.run(trace)
  assert_eq(decisions.length(), 1)
  assert_true(byte_values(decisions[0].chars()) == byte_values(b"abc"))
  assert_true(decisions[0].data() == [0, 1, 2])
  assert_true(decisions[0].result().map(item => item.0) == [0, 1, 2])
  assert_true(
    decisions[0].result().map(item => item.1.to_int()) == [97, 98, 99],
  )
}

///|
test "translated BAP strings detector supports aborting accepted hypotheses" {
  let mut detector : @strings.StringsDetector[Int] = @strings.StringsDetector::create(
    @strings.StringsAlphabet::alpha_caseless(),
    beta=0.4,
  )
  detector = detector.step(10, b'h')
  assert_true(detector.abort() is None)
  detector = detector.step(11, b'i')
  match detector.abort() {
    Some(decision) => {
      assert_true(byte_values(decision.chars()) == byte_values(b"hi"))
      assert_true(decision.data() == [10, 11])
      assert_true(decision.data(rev=true) == [11, 10])
    }
    None => fail("expected accepted detector hypothesis")
  }
}
