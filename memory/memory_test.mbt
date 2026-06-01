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
    }
    Err(reason) => fail(reason)
  }
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
test "translated BAP memmap public queries are range ordered" {
  let first = memory_at(0x100UL, 2)
  let middle = memory_at(0x180UL, 2)
  let last = memory_at(0x300UL, 2)
  let map = @memory.MemMap::empty()
    .add(last, "last")
    .add(first, "first")
    .add(middle, "middle")
    .add(first, "first-again")
  assert_true(
    map.entries().map(entry => entry.1) ==
    ["first", "first-again", "middle", "last"],
  )
  assert_true(
    map.lookup(0x100UL).map(entry => entry.1) == ["first", "first-again"],
  )
  assert_true(
    map.intersections(memory_at(0x100UL, 0x201)).map(entry => entry.1) ==
    ["first", "first-again", "middle", "last"],
  )
  assert_true(
    map.dominators(memory_at(0x100UL, 1)).map(entry => entry.1) ==
    ["first", "first-again"],
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
