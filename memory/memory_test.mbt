///|
fn bytes_0_to_15() -> Bytes {
  Bytes::from_array(Array::makei(16, i => i.to_byte()))
}

///|
fn memory_at(start : UInt64, size : Int) -> @memory.Memory {
  @memory.Memory::from_bytes(
    endian=LittleEndian,
    start~,
    Bytes::from_array(Array::make(size, b'\x00')),
  )
}

///|
test "memory views preserve address ranges" {
  let mem = @memory.Memory::create(
    endian=LittleEndian,
    start=0x1000UL,
    bytes_0_to_15(),
  )
  match mem {
    Ok(memory) => {
      assert_true(memory.min_addr() == 0x1000UL)
      assert_true(memory.max_addr() == 0x100fUL)
      assert_true(memory.contains(0x1008UL))
      assert_true(memory.compare_with(0x0fffUL) == AddrBelow)
      let view = memory.view(from=0x1004UL, words=4)
      match view {
        Ok(chunk) => {
          assert_true(chunk.min_addr() == 0x1004UL)
          assert_true(chunk.max_addr() == 0x1007UL)
          inspect(chunk.hexdump(), content="04 05 06 07")
        }
        Err(reason) => fail(reason)
      }
      let wide_view = memory.view(from=0x1004UL, words=2, word_size=16)
      match wide_view {
        Ok(chunk) => {
          assert_true(chunk.min_addr() == 0x1004UL)
          assert_true(chunk.max_addr() == 0x1007UL)
          inspect(chunk.hexdump(), content="04 05 06 07")
        }
        Err(reason) => fail(reason)
      }
      assert_true(memory.view(from=0x1004UL, words=2, word_size=12) is Err(_))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "memory raising accessors mirror checked view and load errors" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    bytes_0_to_15(),
  )
  let view = memory.view_exn(from=0x1002UL, words=2)
  assert_true(view.min_addr() == 0x1002UL)
  inspect(view.hexdump(), content="02 03")
  assert_eq(memory.load_exn(0x1002UL, width=16).to_hex(), "0x0302")
  try {
    let _ = memory.view_exn(from=0x2000UL)
    fail("unexpected view_exn success")
  } catch {
    @memory.MemoryFailure(reason) =>
      assert_eq(reason, "memory view starts outside the source region")
    _ => fail("expected MemoryFailure from view_exn")
  }
  try {
    let _ = memory.load_exn(0x100fUL, width=16)
    fail("unexpected load_exn success")
  } catch {
    @memory.MemoryFailure(reason) =>
      assert_eq(reason, "memory load is out of bounds")
    _ => fail("expected MemoryFailure from load_exn")
  }
}

///|
test "translated BAP memory create rejects empty regions" {
  assert_true(
    @memory.Memory::create(endian=LittleEndian, start=0UL, b"") is Err(_),
  )
  assert_true(
    @memory.Memory::create(endian=LittleEndian, start=0UL, b"\x01\x02", len=0)
    is Err(_),
  )
  assert_true(
    @memory.Memory::create(endian=LittleEndian, start=0UL, b"\x01\x02", pos=2)
    is Err(_),
  )
  let mem = @memory.Memory::from_bytes(endian=LittleEndian, start=0UL, b"\x01")
  assert_true(mem.view(words=0) is Err(_))
}

///|
test "loads honor endian order and stores update bytes" {
  let le = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0UL,
    bytes_0_to_15(),
  )
  let be = @memory.Memory::from_bytes(
    endian=BigEndian,
    start=0UL,
    bytes_0_to_15(),
  )
  match (le.load(0UL, width=16), be.load(0UL, width=16)) {
    (Ok(l), Ok(b)) => {
      inspect(l.to_hex(), content="0x0100")
      inspect(b.to_hex(), content="0x0001")
    }
    _ => fail("expected endian loads")
  }
  let word = @types.Word::from_hex(width=16, "0xbeef")
  match le.store(2UL, word) {
    Ok(next) =>
      inspect(
        next.hexdump(),
        content="00 01 ef be 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f",
      )
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP memory input readers load words and advance addresses" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x80\x01\x02\x03\x04\x05\x06\x07",
  )
  match @memory.MemoryInputReader::int8().run(memory, 0x1000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1001UL)
      assert_true(word.is_signed())
      assert_true(word.to_int32_exn() == -128)
    }
    Err(reason) => fail(reason)
  }
  match @memory.MemoryInputReader::uint8().run(memory, 0x1000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1001UL)
      assert_true(!word.is_signed())
      assert_true(word.to_int32_exn() == 0x80)
    }
    Err(reason) => fail(reason)
  }
  match @memory.MemoryInputReader::int16().run(memory, 0x1000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1002UL)
      assert_true(word.is_signed())
      assert_true(word.to_hex() == "0x0180")
    }
    Err(reason) => fail(reason)
  }
  match @memory.MemoryInputReader::uint16().run(memory, 0x1000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1002UL)
      assert_true(!word.is_signed())
      assert_true(word.to_hex() == "0x0180")
    }
    Err(reason) => fail(reason)
  }
  match @memory.MemoryInputReader::int32().run(memory, 0x1000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1004UL)
      assert_true(word.is_signed())
      assert_true(word.to_hex() == "0x03020180")
    }
    Err(reason) => fail(reason)
  }
  match @memory.MemoryInputReader::word(word_size=24).run(memory, 0x1001UL) {
    Ok((word, next)) => {
      assert_true(next == 0x1004UL)
      assert_true(!word.is_signed())
      assert_true(word.to_hex() == "0x030201")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @memory.MemoryInputReader::int64().run(memory, 0x1001UL) is Err(_),
  )
}

///|
test "translated BAP memory input readers honor big endian loads" {
  let memory = @memory.Memory::from_bytes(
    endian=BigEndian,
    start=0x2000UL,
    b"\x80\x01\x02\x03\x04\x05\x06\x07",
  )
  match @memory.MemoryInputReader::int64().run(memory, 0x2000UL) {
    Ok((word, next)) => {
      assert_true(next == 0x2008UL)
      assert_true(word.is_signed())
      assert_true(word.to_hex() == "0x8001020304050607")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP memory get uses source-style address scale" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    bytes_0_to_15(),
  )
  match memory.get() {
    Ok(word) => assert_true(word.to_hex() == "0x00")
    Err(reason) => fail(reason)
  }
  match memory.get(scale=32, index=1) {
    Ok(word) => assert_true(word.to_hex() == "0x07060504")
    Err(reason) => fail(reason)
  }
  match memory.get(addr=0x1002UL, disp=1, index=1, scale=16) {
    Ok(word) => assert_true(word.to_hex() == "0x0605")
    Err(reason) => fail(reason)
  }
  match memory.deref(0x1005UL) {
    Ok(word) => assert_true(word.to_hex() == "0x05")
    Err(reason) => fail(reason)
  }
  assert_true(memory.get(scale=0) is Err(_))
  assert_true(memory.get(addr=0x100fUL, scale=16) is Err(_))
  assert_true(memory.deref(0x2000UL) is Err(_))
}

///|
test "translated BAP memory get_exn raises checked load errors" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    bytes_0_to_15(),
  )
  assert_eq(memory.get_exn(scale=16).to_hex(), "0x0100")
  assert_eq(memory.deref_exn(0x1003UL).to_hex(), "0x03")
  try {
    let _ = memory.get_exn(addr=0x100fUL, scale=16)
    fail("unexpected get_exn success")
  } catch {
    @memory.MemoryFailure(reason) =>
      assert_eq(reason, "memory load is out of bounds")
    _ => fail("expected MemoryFailure from get_exn")
  }
  try {
    let _ = memory.deref_exn(0x2000UL)
    fail("unexpected deref_exn success")
  } catch {
    @memory.MemoryFailure(reason) =>
      assert_eq(reason, "memory load is out of bounds")
    _ => fail("expected MemoryFailure from deref_exn")
  }
}

///|
test "translated BAP memory iterators visit complete words by address" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x00\x01\x02\x03\x04\x05\x06\x07",
  )
  let byte_words = []
  memory.iter(word => byte_words.push(word.to_hex()))
  assert_true(
    byte_words ==
    ["0x00", "0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07"],
  )
  let indexed_words = []
  memory.iteri(
    (addr, word) => indexed_words.push((addr, word.to_hex())),
    word_size=16,
  )
  assert_true(
    indexed_words ==
    [
      (0x1000UL, "0x0100"),
      (0x1002UL, "0x0302"),
      (0x1004UL, "0x0504"),
      (0x1006UL, "0x0706"),
    ],
  )
  let folded = memory.fold(
    [],
    (word, acc) => {
      acc.push(word.to_hex())
      acc
    },
    word_size=32,
  )
  assert_true(folded == ["0x03020100", "0x07060504"])
  let with_trailing = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2000UL,
    b"\x0a\x0b\x0c\x0d\x0e",
  )
  let complete_pairs = with_trailing.foldi(
    [],
    (addr, word, acc) => {
      acc.push((addr, word.to_hex()))
      acc
    },
    word_size=16,
  )
  assert_true(complete_pairs == [(0x2000UL, "0x0b0a"), (0x2002UL, "0x0d0c")])
}

///|
test "translated BAP memory predicate iterators stop and search by word" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3000UL,
    b"\x00\x01\x02\x03\x04\x05",
  )
  let exists_seen = []
  assert_true(
    memory.exists((addr, word) => {
      exists_seen.push(addr)
      word.to_hex() == "0x02"
    }),
  )
  assert_true(exists_seen == [0x3000UL, 0x3001UL, 0x3002UL])
  let forall_seen = []
  assert_true(
    !memory.for_all((addr, word) => {
      forall_seen.push(addr)
      word.to_hex() != "0x03"
    }),
  )
  assert_true(forall_seen == [0x3000UL, 0x3001UL, 0x3002UL, 0x3003UL])
  assert_true(memory.count((_, word) => word.width() == 16, word_size=16) == 3)
  match memory.find_if((addr, _) => addr == 0x3004UL, word_size=16) {
    Some(word) => assert_true(word.to_hex() == "0x0504")
    None => fail("expected find_if to return the matching word")
  }
  assert_true(
    memory.find_map(
      (addr, word) => if word.to_hex() == "0x0302" { Some(addr) } else { None },
      word_size=16,
    ) ==
    Some(0x3002UL),
  )
}

///|
test "memory merge accepts contiguous regions" {
  let left = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=10UL,
    b"\x01\x02",
  )
  let right = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=12UL,
    b"\x03\x04",
  )
  match left.merge(right) {
    Ok(mem) => {
      assert_true(mem.min_addr() == 10UL)
      assert_true(mem.max_addr() == 13UL)
      inspect(mem.hexdump(), content="01 02 03 04")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP memmap lookup covers every byte in added ranges" {
  let chunk = memory_at(0x100UL, 10)
  let map = @memory.MemMap::empty().add(chunk, 42)
  for offset in 0..<10 {
    let addr = 0x100UL + offset.to_uint64()
    let got = map.lookup(addr)
    assert_true(got.length() == 1)
    assert_true(got[0].0.min_addr() == chunk.min_addr())
    assert_true(got[0].0.max_addr() == chunk.max_addr())
    assert_true(got[0].1 == 42)
  }
  assert_true(map.lookup(0x0ffUL).is_empty())
  assert_true(map.lookup(0x10aUL).is_empty())
}

///|
test "translated BAP memmap lookup run-through matches interval membership" {
  let first = memory_at(0x100UL, 0x10)
  let second = memory_at(0x108UL, 0x08)
  let third = memory_at(0x10fUL, 0x12)
  let fourth = memory_at(0x120UL, 0x04)
  let fixtures = [(first, 0), (second, 1), (third, 2), (fourth, 3)]
  let map = @memory.MemMap::empty()
    .add(first, 0)
    .add(second, 1)
    .add(third, 2)
    .add(fourth, 3)
  for offset in 0..<0x25 {
    let addr = 0x100UL + offset.to_uint64()
    let expect = fixtures
      .filter(item => item.0.contains(addr))
      .map(item => item.1)
    let got = map.lookup(addr).map(entry => entry.1)
    assert_true(got == expect)
  }
}

///|
test "memmap lookup intersections and dominators follow address intervals" {
  let base = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    bytes_0_to_15(),
  )
  let chunk = match base.view(from=0x1004UL, words=4) {
    Ok(mem) => mem
    Err(reason) => fail(reason)
  }
  let point = match base.view(from=0x1006UL, words=1) {
    Ok(mem) => mem
    Err(reason) => fail(reason)
  }
  let map = @memory.MemMap::empty().add(base, "base").add(chunk, "chunk")
  assert_true(map.lookup(0x1006UL).length() == 2)
  assert_true(map.intersections(point).length() == 2)
  assert_true(map.dominators(point).length() == 2)
  assert_true(map.dominates(chunk))
  assert_true(map.remove_intersections(point).length() == 0)
}

///|
test "memmap min max and removals follow BAP interval behavior" {
  let first = memory_at(0x100UL, 1)
  let middle = memory_at(0x180UL, 10)
  let last = memory_at(0x300UL, 100)
  let map = @memory.MemMap::empty().add(middle, 1).add(last, 2).add(first, 0)
  match (map.min_binding(), map.max_binding()) {
    (Some((min_mem, min_value)), Some((max_mem, max_value))) => {
      assert_true(min_mem.min_addr() == first.min_addr())
      assert_true(min_value == 0)
      assert_true(max_mem.max_addr() == last.max_addr())
      assert_true(max_value == 2)
    }
    _ => fail("expected min and max memmap bindings")
  }
  let point = memory_at(0x184UL, 1)
  assert_true(map.intersects(point))
  assert_true(map.dominates(point))
  let without_intersections = map.remove_intersections(point)
  assert_true(without_intersections.length() == 2)
  assert_true(!without_intersections.intersects(point))
  let without_dominators = map.remove_dominators(point)
  assert_true(without_dominators.length() == 2)
  assert_true(!without_dominators.dominates(point))
  let without_exact = map.remove(middle)
  assert_true(without_exact.length() == 2)
  assert_true(without_exact.lookup(0x100UL).length() == 1)
  assert_true(without_exact.lookup(0x180UL).is_empty())
  assert_true(without_exact.lookup(0x300UL).length() == 1)
}

///|
test "translated BAP memmap transformations preserve ranges and duplicates" {
  let first = memory_at(0x100UL, 2)
  let second = memory_at(0x200UL, 1)
  let map = @memory.MemMap::empty().add(first, 1).add(first, 2).add(second, 3)
  let doubled = map.map(value => value * 2)
  assert_true(doubled.find(first).map(entry => entry.1) == [2, 4])
  assert_true(doubled.find(second).map(entry => entry.1) == [6])
  let with_addr = map.mapi((memory, value) => {
    value + (memory.min_addr() - 0x100UL).to_int()
  })
  assert_true(with_addr.find(first).map(entry => entry.1) == [1, 2])
  assert_true(with_addr.find(second).map(entry => entry.1) == [259])
  let odd = map.filter(value => value % 2 == 1)
  assert_true(odd.find(first).map(entry => entry.1) == [1])
  assert_true(odd.find(second).map(entry => entry.1) == [3])
  let labels = map.filter_map(value => {
    if value > 1 {
      Some("v\{value}")
    } else {
      None
    }
  })
  assert_true(labels.find(first).map(entry => entry.1) == ["v2"])
  assert_true(labels.find(second).map(entry => entry.1) == ["v3"])
  let range_labels = map.filter_mapi((memory, value) => {
    if memory.max_addr() == 0x101UL {
      Some("a\{value}")
    } else {
      None
    }
  })
  assert_true(range_labels.find(first).map(entry => entry.1) == ["a1", "a2"])
  assert_true(range_labels.find(second).is_empty())
}

///|
test "translated BAP memmap duplicate ranges all intersect and remove together" {
  let chunk = memory_at(0x200UL, 10)
  let map = @memory.MemMap::empty()
    .add(chunk, "first")
    .add(chunk, "second")
    .add(chunk, "third")
  assert_true(
    map.intersections(chunk).map(entry => entry.1) ==
    ["first", "second", "third"],
  )
  let removed = map.remove_intersections(chunk)
  assert_true(removed.length() == 0)
  assert_true(!removed.intersects(chunk))
}

///|
test "translated BAP image table checked add rejects intersections" {
  let low = memory_at(0x10UL, 0x10)
  let high = memory_at(0x30UL, 0x10)
  let overlap = memory_at(0x18UL, 0x10)
  let exact = memory_at(0x10UL, 0x10)
  let table = match @memory.MemMap::empty().add_checked(low, "lo") {
    Ok(table) => table
    Err(reason) => fail(reason)
  }
  assert_true(table.entries().map(entry => entry.1) == ["lo"])
  match table.add_checked(overlap, "overlap") {
    Err(reason) => assert_eq(reason, "memory has intersections")
    Ok(_) => fail("expected overlap rejection")
  }
  match table.add_checked(exact, "again") {
    Err(reason) => assert_eq(reason, "memory has intersections")
    Ok(_) => fail("expected exact overlap rejection")
  }
  let table = match table.add_checked(high, "hi") {
    Ok(table) => table
    Err(reason) => fail(reason)
  }
  assert_true(table.entries().map(entry => entry.1) == ["lo", "hi"])
}

///|
test "translated BAP memmap public queries are range ordered" {
  let first = memory_at(0x100UL, 2)
  let first_wide = memory_at(0x100UL, 0x20)
  let middle = memory_at(0x180UL, 2)
  let last = memory_at(0x300UL, 2)
  let map = @memory.MemMap::empty()
    .add(last, "last")
    .add(first, "first")
    .add(middle, "middle")
    .add(first, "first-again")
    .add(first_wide, "first-wide")
  assert_true(
    map.entries().map(entry => entry.1) ==
    ["first", "first-again", "first-wide", "middle", "last"],
  )
  assert_true(
    map.lookup(0x100UL).map(entry => entry.1) ==
    ["first", "first-again", "first-wide"],
  )
  assert_true(
    map.intersections(memory_at(0x100UL, 0x201)).map(entry => entry.1) ==
    ["first", "first-again", "first-wide", "middle", "last"],
  )
  assert_true(
    map.dominators(memory_at(0x100UL, 1)).map(entry => entry.1) ==
    ["first", "first-again", "first-wide"],
  )
}

///|
test "translated BAP memmap max binding follows lower-bound order" {
  let wide_low = memory_at(0x100UL, 0x200)
  let narrow_high = memory_at(0x180UL, 1)
  let same_lower_old = memory_at(0x300UL, 0x40)
  let same_lower_new = memory_at(0x300UL, 1)
  let table = @memory.MemMap::empty()
    .add(wide_low, "wide-low")
    .add(narrow_high, "narrow-high")
    .add(same_lower_old, "same-lower-old")
    .add(same_lower_new, "same-lower-new")
  match table.max_binding() {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == same_lower_new.min_addr())
      assert_true(tag == "same-lower-new")
    }
    None => fail("expected max binding")
  }
  let lower_only = @memory.MemMap::empty()
    .add(wide_low, "wide-low")
    .add(narrow_high, "narrow-high")
  assert_true(
    lower_only.max_binding().map(entry => entry.1) == Some("narrow-high"),
  )
}

///|
test "translated BAP image table ranged traversal helpers follow key order" {
  let first = memory_at(0x100UL, 2)
  let second = memory_at(0x200UL, 2)
  let third = memory_at(0x300UL, 2)
  let fourth = memory_at(0x400UL, 2)
  let table = @memory.MemMap::empty()
    .add(third, 3)
    .add(first, 1)
    .add(fourth, 4)
    .add(second, 2)
  assert_true(table.to_sequence().map(entry => entry.1) == [1, 2, 3, 4])
  assert_true(
    table.regions().map(memory => memory.min_addr()) ==
    [0x100UL, 0x200UL, 0x300UL, 0x400UL],
  )
  assert_true(table.elements() == [1, 2, 3, 4])
  assert_true(
    table
    .to_sequence(start=Some(second), until=Some(third))
    .map(entry => entry.1) ==
    [2, 3],
  )
  assert_true(
    table.to_sequence(until=Some(third)).map(entry => entry.1) == [1, 2, 3],
  )
  assert_true(
    table.to_sequence(start=Some(second)).map(entry => entry.1) == [2, 3, 4],
  )
  assert_true(
    table
    .to_sequence(start=Some(third), until=Some(first))
    .map(entry => entry.1) ==
    [3, 2, 1],
  )
  let folded = table.fold([], (value, acc) => {
    acc.push(value)
    acc
  })
  assert_true(folded == [1, 2, 3, 4])
  let folded_with_addr = table.foldi([], (memory, value, acc) => {
    acc.push((memory.min_addr(), value))
    acc
  })
  assert_true(
    folded_with_addr == [(0x100UL, 1), (0x200UL, 2), (0x300UL, 3), (0x400UL, 4)],
  )
  let reverse_folded = table.fold(
    [],
    (value, acc) => {
      acc.push(value)
      acc
    },
    start=Some(third),
    until=Some(first),
  )
  assert_true(reverse_folded == [3, 2, 1])
  let iter_seen = []
  table.iter(
    value => iter_seen.push(value),
    start=Some(second),
    until=Some(third),
  )
  assert_true(iter_seen == [2, 3])
  let iteri_seen = []
  table.iteri((memory, value) => iteri_seen.push((memory.min_addr(), value)))
  assert_true(
    iteri_seen == [(0x100UL, 1), (0x200UL, 2), (0x300UL, 3), (0x400UL, 4)],
  )
  assert_true(table.exists(value => value == 3))
  assert_true(table.existsi((memory, _) => memory.min_addr() == 0x200UL))
  assert_true(table.for_all(value => value > 0))
  assert_true(!table.for_alli((memory, _) => memory.min_addr() < 0x400UL))
  assert_true(table.count(value => value % 2 == 0) == 2)
  assert_true(table.find_if(value => value == 3) == Some(3))
  assert_true(
    table.find_map(value => if value == 2 { Some(value * 10) } else { None }) ==
    Some(20),
  )
  assert_true(
    table.find_mapi((memory, value) => {
      if memory.min_addr() == 0x300UL {
        Some(value + 10)
      } else {
        None
      }
    }) ==
    Some(13),
  )
  assert_true(
    table
    .map(value => value * 10, start=Some(second), until=Some(third))
    .elements() ==
    [20, 30],
  )
  assert_true(
    table
    .mapi((memory, value) => value + (memory.min_addr() >> 8).to_int())
    .elements() ==
    [2, 4, 6, 8],
  )
  assert_true(
    table
    .filter(value => value != 3, start=Some(second), until=Some(fourth))
    .elements() ==
    [2, 4],
  )
  assert_true(
    table.filteri((memory, _) => memory.min_addr() <= 0x200UL).elements() ==
    [1, 2],
  )
  assert_true(
    table
    .filter_map(value => if value % 2 == 0 { Some(value + 1) } else { None })
    .elements() ==
    [3, 5],
  )
  assert_true(
    table
    .filter_mapi((memory, value) => {
      if memory.min_addr() >= 0x300UL {
        Some(value + 10)
      } else {
        None
      }
    })
    .elements() ==
    [13, 14],
  )
}

///|
test "translated BAP image table change applies commands to intersections" {
  let low = memory_at(0x10UL, 0x10)
  let middle = memory_at(0x20UL, 0x10)
  let high = memory_at(0x40UL, 0x10)
  let target = memory_at(0x18UL, 0x20)
  let table = @memory.MemMap::empty().add(high, 3).add(low, 1).add(middle, 2)
  let ignored_matches : Ref[Array[Int]] = Ref([])
  let ignored = table.change(target, matches => {
    ignored_matches.val = matches.map(entry => entry.1)
    Ignore
  })
  assert_true(ignored_matches.val == [1, 2])
  assert_true(ignored.entries().map(entry => entry.1) == [1, 2, 3])
  let updated_matches : Ref[Array[Int]] = Ref([])
  let updated = table.change(target, matches => {
    updated_matches.val = matches.map(entry => entry.1)
    Update((memory, value) => value + (memory.min_addr() >> 4).to_int())
  })
  assert_true(updated_matches.val == [1, 2])
  assert_true(updated.entries().map(entry => entry.1) == [2, 4, 3])
  let removed = table.change(target, _ => Remove)
  assert_true(removed.entries().map(entry => entry.1) == [3])
  let rebound_memory = memory_at(0x80UL, 0x08)
  let rebound = table.change(target, _ => Rebind(rebound_memory, 9))
  assert_true(rebound.entries().map(entry => entry.1) == [3, 9])
  assert_true(rebound.has_memory(rebound_memory))
  let empty_matches = Ref(false)
  let inserted = table.change(memory_at(0x60UL, 0x10), matches => {
    empty_matches.val = matches.is_empty()
    Rebind(rebound_memory, 7)
  })
  assert_true(empty_matches.val)
  assert_true(inserted.entries().map(entry => entry.1) == [1, 2, 3, 7])
}

///|
fn memmap_tags(entries : Array[(@memory.Memory, String)]) -> Set[String] {
  Set::from_array(entries.map(entry => entry.1))
}

///|
test "translated BAP image table neighbors and intersections use memory ranges" {
  let mem_low = memory_at(0x10UL, 0x10)
  let mem_high = memory_at(0x30UL, 0x10)
  let table = @memory.MemMap::empty().add(mem_low, "lo").add(mem_high, "hi")
  assert_true(table.length() == 2)
  assert_true(table.has_memory(memory_at(0x10UL, 0x10)))
  assert_true(table.mem(memory_at(0x10UL, 0x10)))
  assert_true(!table.has_memory(memory_at(0x10UL, 0x0f)))
  assert_true(!table.mem(memory_at(0x10UL, 0x0f)))
  match table.find_addr(0x12UL) {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == mem_low.min_addr())
      assert_true(tag == "lo")
    }
    None => fail("expected address table binding")
  }
  assert_true(table.find_addr(0x20UL) is None)
  match table.next_binding(mem_low) {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == mem_high.min_addr())
      assert_true(tag == "hi")
    }
    None => fail("expected next table binding")
  }
  assert_true(table.next(mem_low).map(entry => entry.1) == Some("hi"))
  match table.prev_binding(mem_high) {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == mem_low.min_addr())
      assert_true(tag == "lo")
    }
    None => fail("expected previous table binding")
  }
  assert_true(table.prev(mem_high).map(entry => entry.1) == Some("lo"))
  match (table.min_binding(), table.max_binding()) {
    (Some((_, "lo")), Some((_, "hi"))) => ()
    _ => fail("expected table min/max bindings")
  }
  match (table.min(), table.max()) {
    (Some((_, "lo")), Some((_, "hi"))) => ()
    _ => fail("expected table min/max aliases")
  }
  let folded = table.fold_intersections(memory_at(0x10UL, 0x30), init=[], f=fn(
    _memory,
    tag,
    acc,
  ) {
    acc.push(tag)
    acc
  })
  assert_true(folded == ["lo", "hi"])
  assert_true(table.has_intersections(memory_at(0x10UL, 0x30)))
  assert_true(!table.has_intersections(memory_at(0x20UL, 0x10)))
  assert_true(
    memmap_tags(table.intersections(memory_at(0x10UL, 0x30))) ==
    Set::from_array(["lo", "hi"]),
  )
  assert_true(table.intersections(memory_at(0x20UL, 0x10)).is_empty())
  assert_true(
    memmap_tags(table.intersections(memory_at(0x20UL, 0x30))) ==
    Set::from_array(["hi"]),
  )
  assert_true(
    memmap_tags(table.intersections(memory_at(0x00UL, 0x11))) ==
    Set::from_array(["lo"]),
  )
}

///|
test "translated BAP image table intersections cover boundary cases" {
  let mem_low = memory_at(0x10UL, 0x10)
  let mem_high = memory_at(0x30UL, 0x10)
  let table = @memory.MemMap::empty().add(mem_low, "lo").add(mem_high, "hi")
  assert_true(
    table.intersections(memory_at(0x10UL, 0x30)).map(entry => entry.1) ==
    ["lo", "hi"],
  )
  assert_true(
    table.intersections(memory_at(0x1fUL, 0x30)).map(entry => entry.1) ==
    ["lo", "hi"],
  )
  assert_true(table.intersections(memory_at(0x20UL, 0x10)).is_empty())
  assert_true(
    table.intersections(memory_at(0x20UL, 0x30)).map(entry => entry.1) == ["hi"],
  )
  assert_true(
    table.intersections(memory_at(0x31UL, 0x01)).map(entry => entry.1) == ["hi"],
  )
  assert_true(
    table.intersections(memory_at(0x31UL, 0x20)).map(entry => entry.1) == ["hi"],
  )
  assert_true(table.intersections(memory_at(0x00UL, 0x10)).is_empty())
  assert_true(
    table.intersections(memory_at(0x00UL, 0x11)).map(entry => entry.1) == ["lo"],
  )
  assert_true(
    table.intersections(memory_at(0x00UL, 0x21)).map(entry => entry.1) == ["lo"],
  )
}

///|
test "translated BAP image table one-to-one link matches exact regions" {
  let mem_low = memory_at(0x10UL, 0x10)
  let mem_high = memory_at(0x30UL, 0x10)
  let extra = memory_at(0x50UL, 0x30)
  let table = @memory.MemMap::empty().add(mem_low, "lo").add(mem_high, "hi")
  let regs = @memory.MemMap::empty()
    .add(mem_low, "reg1")
    .add(mem_high, "reg2")
    .add(extra, "reg3")
  let links = table.link_one_to_one(regs)
  assert_true(links.get("lo") == Some("reg1"))
  assert_true(links.get("hi") == Some("reg2"))
  assert_true(links.get("missing") is None)
}

///|
test "translated BAP image table link variants handle exact and many intersections" {
  let mem_low = memory_at(0x10UL, 0x10)
  let mem_high = memory_at(0x30UL, 0x10)
  let wide = memory_at(0x10UL, 0x30)
  let missing = memory_at(0x90UL, 0x10)
  let table = @memory.MemMap::empty()
    .add(mem_low, "lo")
    .add(wide, "wide")
    .add(missing, "missing")
  let regs = @memory.MemMap::empty().add(mem_low, "reg1").add(mem_high, "reg2")
  let maybe = table.link_maybe_one(regs)
  assert_true(maybe.get("lo") == Some(Some("reg1")))
  assert_true(maybe.get("wide") == Some(None))
  assert_true(maybe.get("missing") == Some(None))
  let many = table.link_many(regs)
  assert_true(many.get("missing") == Some([]))
  match many.get("wide") {
    Some(values) =>
      assert_true(Set::from_array(values) == Set::from_array(["reg1", "reg2"]))
    None => fail("expected many link entry")
  }
  match table.link_at_least_one(regs).get("wide") {
    Some((head, rest)) => {
      assert_true(head == "reg1")
      assert_true(rest == ["reg2"])
    }
    None => fail("expected at-least-one link entry")
  }
  assert_true(table.link_at_least_one(regs).get("missing") is None)
}

///|
test "translated BAP image table checked links preserve source invariants" {
  let mem_low = memory_at(0x10UL, 0x10)
  let mem_high = memory_at(0x30UL, 0x10)
  let wide = memory_at(0x10UL, 0x30)
  let missing = memory_at(0x90UL, 0x10)
  let exact = @memory.MemMap::empty().add(mem_low, "lo").add(mem_high, "hi")
  let table = exact.add(wide, "wide").add(missing, "missing")
  let regs = @memory.MemMap::empty().add(mem_low, "reg1").add(mem_high, "reg2")
  match exact.link_one_checked(regs) {
    Ok(links) => {
      assert_true(links.get("lo") == Some("reg1"))
      assert_true(links.get("hi") == Some("reg2"))
    }
    Err(reason) => fail(reason)
  }
  match table.link_maybe_one_checked(regs) {
    Ok(links) => {
      assert_true(links.get("lo") == Some(Some("reg1")))
      assert_true(links.get("wide") == Some(None))
      assert_true(links.get("missing") == Some(None))
    }
    Err(reason) => fail(reason)
  }
  match table.link_one_checked(regs) {
    Err(reason) => assert_eq(reason, "link_exn: unbound value")
    Ok(_) => fail("expected missing exact link rejection")
  }
  match table.link_many_checked(regs) {
    Ok(links) => {
      assert_true(links.get("missing") == Some([]))
      assert_true(links.get("wide") == Some(["reg1", "reg2"]))
    }
    Err(reason) => fail(reason)
  }
  match table.link_at_least_one_checked(regs) {
    Err(reason) =>
      assert_eq(reason, "at_least_one invariant failed. element is not mapped")
    Ok(_) => fail("expected at-least-one missing link rejection")
  }
  match table.remove(missing).link_at_least_one_checked(regs) {
    Ok(links) =>
      match links.get("wide") {
        Some((head, tail)) => {
          assert_true(head == "reg1")
          assert_true(tail == ["reg2"])
        }
        None => fail("expected wide at-least-one link")
      }
    Err(reason) => fail(reason)
  }
  let duplicated = @memory.MemMap::empty()
    .add(mem_low, "same")
    .add(mem_high, "same")
  match duplicated.link_maybe_one_checked(regs) {
    Err(reason) => assert_eq(reason, "mapping is non-injective")
    Ok(_) => fail("expected duplicate maybe-one link rejection")
  }
  match duplicated.link_many_checked(regs) {
    Err(reason) => assert_eq(reason, "mapping is non-injective")
    Ok(_) => fail("expected duplicate many link rejection")
  }
}

///|
test "translated BAP image table reverse maps expose value-to-memory lookup" {
  let low = memory_at(0x10UL, 0x10)
  let high = memory_at(0x30UL, 0x10)
  let later_low = memory_at(0x50UL, 0x08)
  let unique = @memory.MemMap::empty().add(low, "text").add(high, "data")
  match unique.rev_map_one() {
    Ok(back) => {
      assert_true(
        back.get("text").map(memory => memory.min_addr()) == Some(0x10UL),
      )
      assert_true(
        back.get("data").map(memory => memory.min_addr()) == Some(0x30UL),
      )
      assert_true(back.get("missing") is None)
    }
    Err(reason) => fail(reason)
  }
  match unique.rev_map_maybe_one() {
    Ok(back) =>
      assert_true(
        back.get("text").map(memory => memory.max_addr()) == Some(0x1fUL),
      )
    Err(reason) => fail(reason)
  }
  let duplicated = unique.add(later_low, "text")
  match duplicated.rev_map_one() {
    Err(reason) => assert_eq(reason, "mapping is non-injective")
    Ok(_) => fail("expected duplicate value rejection")
  }
  match duplicated.rev_map_maybe_one() {
    Err(reason) => assert_eq(reason, "mapping is non-injective")
    Ok(_) => fail("expected maybe-one duplicate value rejection")
  }
  match duplicated.rev_map_many().get("text") {
    Some(memories) =>
      assert_true(memories.map(memory => memory.min_addr()) == [0x10UL, 0x50UL])
    None => fail("expected reverse many text bindings")
  }
  match duplicated.rev_map_at_least_one().get("text") {
    Some((head, tail)) => {
      assert_true(head.min_addr() == 0x10UL)
      assert_true(tail.map(memory => memory.min_addr()) == [0x50UL])
    }
    None => fail("expected reverse at-least-one text binding")
  }
}
