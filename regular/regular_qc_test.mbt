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

///|
/// Regression (found by "qc: PrefixTrie is_empty agrees with length"):
/// `remove` keeps the path to a removed key, so `is_empty` (which only
/// looked at the root) reported a trie with no bindings as non-empty.
test "regression: a trie is empty again after removing its only key" {
  let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
  trie.add("\u{e9}aba", 1)
  trie.remove("\u{e9}aba")
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
  trie.add("ab", 2)
  assert_true(!trie.is_empty())
  let suffix : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
  suffix.add("abc", 3)
  suffix.remove("abc")
  assert_true(suffix.is_empty())
}
