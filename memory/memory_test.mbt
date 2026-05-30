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
  assert_true(!table.has_memory(memory_at(0x10UL, 0x0f)))
  match table.next_binding(mem_low) {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == mem_high.min_addr())
      assert_true(tag == "hi")
    }
    None => fail("expected next table binding")
  }
  match table.prev_binding(mem_high) {
    Some((memory, tag)) => {
      assert_true(memory.min_addr() == mem_low.min_addr())
      assert_true(tag == "lo")
    }
    None => fail("expected previous table binding")
  }
  match (table.min_binding(), table.max_binding()) {
    (Some((_, "lo")), Some((_, "hi"))) => ()
    _ => fail("expected table min/max bindings")
  }
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
