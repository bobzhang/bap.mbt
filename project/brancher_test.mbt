///|
test "project brancher resolves edge tables and applies them to blocks" {
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5000UL,
    b"\x01",
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5010UL,
    b"\x02",
  )
  let known = @project.ProjectDisassemblyEdge::create(
    source=0x5000UL,
    target=0x5010UL,
    kind=FallEdge,
  )
  let unknown = @project.ProjectDisassemblyEdge::create(
    source=0x5000UL,
    kind=JumpEdge,
  )
  let ignored = @project.ProjectDisassemblyEdge::create(
    source=0x6000UL,
    target=0x6010UL,
    kind=CondEdge,
  )
  let brancher = @project.ProjectBrancher::of_edges([known, unknown, ignored])
    .set_path("unit.bin")
    .with_biased(true)
  assert_true(brancher.path() == Some("unit.bin"))
  assert_true(brancher.is_biased())
  assert_true(brancher.resolve(first).length() == 2)
  assert_true(brancher.resolve(second).is_empty())
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(first).add_block(second),
  )
  match project.apply_brancher(brancher~) {
    Ok(branched) => {
      assert_true(branched.disassembly().edge_count() == 2)
      assert_true(branched.disassembly().has_edge(known))
      assert_true(branched.disassembly().has_edge(unknown))
      assert_true(!branched.disassembly().has_edge(ignored))
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown()).apply_brancher()
    is Err(_),
  )
}

///|
test "project empty brancher preserves existing disassembly blocks" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7000UL,
    b"\x01",
  )
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(block),
  )
  match project.apply_brancher() {
    Ok(branched) => {
      assert_true(branched.disassembly().block_count() == 1)
      assert_true(branched.disassembly().edge_count() == 0)
    }
    Err(reason) => fail(reason)
  }
}
