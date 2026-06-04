///|
fn bw_memory(start : UInt64, data : Bytes) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start~, data)
}

///|
test "translated BAP byteweight training records positive and negative stats" {
  let corpus = bw_memory(0x100UL, b"\xaa\xbb\xaa\xbb")
  let starts = Set::from_array([0x100UL])
  let decider = @byteweight.Byteweight::create().train(
    max_length=2,
    mem => starts.contains(mem.min_addr()),
    corpus,
  )
  assert_true(decider.length() == 2)
  match decider.find(b"\xaa\xbb") {
    Some(stats) => {
      assert_true(stats.h1() == 1)
      assert_true(stats.h0() == 1)
      assert_true(stats.trials() == 2)
      assert_true(stats.probability_h1() == 0.5)
    }
    None => fail("expected trained two-byte signature")
  }
  match decider.find(b"\xaa") {
    Some(stats) => {
      assert_true(stats.h1() == 1)
      assert_true(stats.h0() == 1)
    }
    None => fail("expected trained one-byte signature")
  }
  assert_true(decider.find(b"\xbb") is None)
}

///|
test "translated BAP byteweight printer renders stats and hex signatures" {
  let corpus = bw_memory(0x100UL, b"\xaa\xbb\xaa\xbb")
  let starts = Set::from_array([0x100UL])
  let decider = @byteweight.Byteweight::create().train(
    max_length=2,
    mem => starts.contains(mem.min_addr()),
    corpus,
  )
  let expected =
    #|2        1        1        0.5000 aabb
    #|2        1        1        0.5000 aa
    #|
  inspect(decider.to_string(), content=expected)
}

///|
test "translated BAP byteweight scanning uses longest known signatures" {
  let corpus = bw_memory(0x100UL, b"abcxabcy")
  let decider = @byteweight.Byteweight::create().train(
    max_length=3,
    mem => mem.min_addr() == 0x100UL,
    corpus,
  )
  let seen = Ref((0UL, 0, @byteweight.ByteweightStats::create()))
  let next = decider.next_if(
    length=4,
    f=(mem, length, stats) => {
      seen.val = (mem.min_addr(), length, stats)
      length == 3 && stats.h1() == 1 && stats.h0() == 1
    },
    corpus,
    0,
  )
  assert_true(next == Some(0))
  assert_true(seen.val.0 == 0x100UL)
  assert_true(seen.val.1 == 3)
  match decider.next(length=4, threshold=0.4, corpus, 1) {
    Some(offset) => assert_true(offset == 4)
    None => fail("expected second matching byteweight offset")
  }
  assert_true(decider.next(length=4, threshold=0.6, corpus, 0) is None)
}

///|
test "translated BAP byteweight find helpers classify memory addresses" {
  let corpus = bw_memory(0x200UL, b"\xaa\xbb\xaa\xbb")
  let decider = @byteweight.Byteweight::create().train(
    max_length=2,
    mem => mem.min_addr() == 0x200UL,
    corpus,
  )
  assert_true(
    decider.find_positive(length=2, threshold=0.4, corpus) == [0x200UL, 0x202UL],
  )
  assert_true(decider.find_positive(length=2, threshold=0.6, corpus).is_empty())
  assert_true(
    decider.find_using_threshold(min_length=2, max_length=2, 0.4, corpus) ==
    [0x200UL, 0x202UL],
  )
  assert_true(
    decider.find_using_bayes_factor(min_length=2, max_length=2, 0.9, corpus) ==
    [0x200UL, 0x202UL],
  )
  assert_true(
    decider
    .find_using_bayes_factor(min_length=2, max_length=2, 1.0, corpus)
    .is_empty(),
  )
}
