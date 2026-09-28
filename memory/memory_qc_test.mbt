// Property-based tests for `memory`: address arithmetic, bounded reads and
// the naive-list `MemMap` checked against simple interval models.

///|
/// Regression (found by "qc: view returns exactly the requested bytes or
/// fails"): `words * word_bytes` overflowed a 32-bit Int, so a request for
/// 0x2000_0001 64-bit words was served as a single 8-byte word.
test "regression: view rejects a word count whose byte size overflows" {
  let m = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    Bytes::make(16, b'\x00'),
  )
  assert_true(m.view(words=0x2000_0001, word_size=64) is Err(_))
  assert_true(m.view(words=0x2000_0000, word_size=64) is Err(_))
  assert_true(m.view(words=0x7fff_ffff, word_size=8) is Err(_))
  assert_true(m.view(words=2, word_size=64) is Ok(_))
}

///|
/// Regression (found by "qc: range lo hi returns exactly [lo, hi] or
/// fails"): `hi - lo` was truncated to a 32-bit Int, so a range spanning
/// 2^32 + 1 bytes returned a one-byte memory, and a span of 2^32 - 13 bytes
/// (a negative Int) returned the whole tail of the region.
test "regression: range rejects spans larger than the region" {
  let m = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    Bytes::make(16, b'\x00'),
  )
  assert_true(m.range(0x1000UL, 0x1_0000_1000UL) is Err(_))
  assert_true(m.range(0x1000UL, 0x1000UL + 0xffff_fff2UL) is Err(_))
  assert_true(m.range(0x1000UL, 0x1010UL) is Err(_))
  match m.range(0x1002UL, 0x100fUL) {
    Ok(r) => {
      assert_eq(r.min_addr(), 0x1002UL)
      assert_eq(r.max_addr(), 0x100fUL)
    }
    Err(reason) => fail(reason)
  }
}

///|
/// Regression (found by "qc: merge rejects regions that are far apart"): the
/// merged span was truncated to a 32-bit Int, so regions 2^32 bytes apart
/// were "merged" into a few garbage bytes, or merge aborted with an index
/// out of bounds.
test "regression: merge rejects regions 2^32 bytes apart" {
  let left = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0UL,
    b"\x01\x02",
  )
  let far = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1_0000_0000UL,
    b"\x03\x04",
  )
  assert_true(left.merge(far) is Err(_))
  assert_true(far.merge(left) is Err(_))
  let wide = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0UL,
    b"\x01\x02\x03\x04",
  )
  let wrapping = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xffff_fffeUL,
    b"\x05\x06\x07\x08",
  )
  assert_true(wide.merge(wrapping) is Err(_))
}

///|
/// Regression (found by "qc: MemoryTrie agrees with a map model"): `remove`
/// keeps the path to a removed key, so `is_empty` (which only looked at the
/// root) reported a trie with no bindings as non-empty.
test "regression: a memory trie is empty again after removing its only key" {
  let trie : @memory.MemoryTrie[Int] = @memory.MemoryTrie::r32()
  let key = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x10UL,
    b"\x01\x01\x01\x00\x01\x01\x01\x01",
  )
  trie.add(key, 0)
  trie.remove(key)
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
  trie.add(key, 1)
  assert_true(!trie.is_empty())
}
