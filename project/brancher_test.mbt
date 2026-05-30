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

///|
test "project branchers register lookup and named application" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7100UL,
    b"\x01",
  )
  let edge = @project.ProjectDisassemblyEdge::create(
    source=0x7100UL,
    target=0x7110UL,
    kind=CondEdge,
  )
  let brancher = @project.ProjectBrancher::of_edges([edge])
  match @project.register_brancher(name="unit-brancher-direct", brancher) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_brancher("unit-brancher-direct") is Some(_))
  assert_true(@project.brancher_names().contains("unit-brancher-direct"))
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(block),
  )
  match project.apply_brancher_named(brancher="unit-brancher-direct") {
    Ok(branched) => {
      assert_true(branched.disassembly().edge_count() == 1)
      assert_true(branched.disassembly().has_edge(edge))
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.register_brancher(name="unit-brancher-direct", brancher) is Err(_),
  )
  assert_true(
    project.apply_brancher_named(brancher="missing-brancher") is Err(_),
  )
}

///|
test "project registers built-in empty brancher idempotently" {
  match @project.register_builtin_branchers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_branchers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.brancher_names().contains("empty"))
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7200UL,
    b"\x01",
  )
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(block),
  )
  match project.apply_brancher_named(brancher="empty") {
    Ok(branched) => {
      assert_true(branched.disassembly().block_count() == 1)
      assert_true(branched.disassembly().edge_count() == 0)
    }
    Err(reason) => fail(reason)
  }
}
