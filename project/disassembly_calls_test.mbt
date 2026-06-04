///|
test "project disassembly calls summarize entries and memberships" {
  let main = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7000UL,
    b"\x01\x02",
  )
  let body = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7010UL,
    b"\x03\x04",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7020UL,
    b"\x05",
  )
  let helper = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7100UL,
    b"\x06",
  )
  let helper_body = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7110UL,
    b"\x07\x08",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(helper_body)
    .add_block(body)
    .add_block(main)
    .add_block(exit)
    .add_block(helper)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x7001UL,
        target=0x7010UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x7011UL,
        target=0x7020UL,
        kind=CondEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x7020UL,
        target=0x7100UL,
        kind=JumpEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x7100UL,
        target=0x7111UL,
        kind=FallEdge,
      ),
    )
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_symbols([
      @image.Symbol::create(name="main", addr=0x7000UL, is_function=true),
      @image.Symbol::create(name="helper", addr=0x7100UL, is_function=true),
    ])
    .with_disassembly(disassembly)
  let calls = project.disassembly_calls()
  let entries = calls.entries()
  assert_true(entries.length() == 2)
  assert_true(entries[0] == 0x7000UL)
  assert_true(entries[1] == 0x7100UL)
  assert_true(calls.belongs(entry=0x7000UL, 0x7001UL))
  assert_true(calls.belongs(entry=0x7000UL, 0x7011UL))
  assert_true(calls.belongs(entry=0x7000UL, 0x7020UL))
  assert_true(!calls.belongs(entry=0x7000UL, 0x7100UL))
  assert_true(calls.belongs(entry=0x7100UL, 0x7111UL))
  assert_true(calls.entry(0x7011UL) == 0x7000UL)
  assert_true(calls.entry(0x7111UL) == 0x7100UL)
  assert_true(calls.entry(0x9999UL) == 0x9999UL)
  assert_true(calls.siblings(0x7001UL, 0x7011UL))
  assert_true(calls.siblings(0x7010UL, 0x7020UL))
  assert_true(!calls.siblings(0x7010UL, 0x7111UL))
  assert_true(calls.belongs(entry=0x9999UL, 0x9999UL))
}

///|
test "project disassembly calls can be built from explicit roots" {
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7300UL,
    b"\x01",
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7310UL,
    b"\x02",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(first)
    .add_block(second)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x7300UL,
        target=0x7310UL,
        kind=FallEdge,
      ),
    )
  let empty = @project.ProjectDisassemblyCalls::of_disassembly(disassembly, [])
  assert_true(empty.entries().is_empty())
  assert_true(empty.entry(0x7310UL) == 0x7310UL)
  assert_true(!empty.belongs(entry=0x7300UL, 0x7310UL))
  let rooted = @project.ProjectDisassemblyCalls::of_disassembly(disassembly, [
    0x7300UL,
  ])
  assert_true(rooted.entries().length() == 1)
  assert_true(rooted.entries()[0] == 0x7300UL)
  assert_true(rooted.entry(0x7310UL) == 0x7300UL)
  assert_true(rooted.belongs(entry=0x7300UL, 0x7310UL))
  assert_true(rooted.siblings(0x7300UL, 0x7310UL))
}
