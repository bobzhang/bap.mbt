///|
fn rec_test_block(
  start : UInt64,
  bytes : Bytes,
  assembly~ : String = "nop",
) -> @project.ProjectDisassemblyBlock raise {
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  match
    @project.ProjectDisassemblyBlock::create(memory, [
      @project.ProjectDisassemblyInstruction::create(memory, assembly~),
    ]) {
    Ok(block) => block
    Err(reason) => fail(reason)
  }
}

///|
fn rec_test_state(
  blocks : Array[@project.ProjectDisassemblyBlock],
  edges? : Array[@project.ProjectDisassemblyEdge],
) -> @project.ProjectDisassemblyState {
  let mut state = @project.ProjectDisassemblyState::empty()
  for block in blocks {
    state = state.add_block(block.memory())
    for instruction in block.instructions() {
      state = state.add_instruction(instruction)
    }
  }
  match edges {
    Some(items) =>
      for edge in items {
        state = state.add_edge(edge)
      }
    None => ()
  }
  state
}

///|
fn rec_arm_strlen_bytes() -> Bytes {
  b"\x04\xb0\x2d\xe5" +
  b"\x00\xb0\x8d\xe2" +
  b"\x14\xd0\x4d\xe2" +
  b"\x10\x00\x0b\xe5" +
  b"\x00\x30\xa0\xe3" +
  b"\x08\x30\x0b\xe5" +
  b"\x05\x00\x00\xea" +
  b"\x10\x30\x1b\xe5" +
  b"\x01\x30\x83\xe2" +
  b"\x10\x30\x0b\xe5" +
  b"\x08\x30\x1b\xe5" +
  b"\x01\x30\x83\xe2" +
  b"\x08\x30\x0b\xe5" +
  b"\x10\x30\x1b\xe5" +
  b"\x00\x00\x53\xe3" +
  b"\xf6\xff\xff\x1a" +
  b"\x08\x30\x1b\xe5" +
  b"\x03\x00\xa0\xe1" +
  b"\x00\xd0\x4b\xe2" +
  b"\x04\xb0\x9d\xe4" +
  b"\x1e\xff\x2f\xe1"
}

///|
test "project recursive disassembly wraps cfg and errors" {
  let entry = rec_test_block(0xa100UL, b"\x01")
  let exit = rec_test_block(0xa110UL, b"\x02")
  let edge = @project.ProjectDisassemblyEdge::create(
    source=0xa100UL,
    target=0xa110UL,
    kind=JumpEdge,
  )
  let state = rec_test_state([exit, entry], edges=[edge])
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    state,
  )
  let result = project.disassembly_rec()
  assert_true(result.project().disassembly().edge_count() == 1)
  assert_true(!result.has_errors())
  assert_true(result.errors().is_empty())
  assert_true(result.cfg().node_count() == 2)
  assert_true(result.cfg().edge_count() == 1)
  assert_true(
    @project.ProjectDisassemblyRec::global_cfg(state).edge_count() == 1,
  )
}

///|
test "project recursive disassembly carries BAP-style errors" {
  let block = rec_test_block(0xa200UL, b"\x01", assembly="bad")
  let failed_disasm = @project.ProjectDisassemblyRecError::failed_to_disasm(
    block.memory(),
  )
  let failed_lift = @project.ProjectDisassemblyRecError::failed_to_lift(
    block.memory(),
    block.leader(),
    "unsupported semantics",
  )
  let result = @project.ProjectDisassemblyRec::create(
    @project.Project::empty(@core_theory.Target::unknown()),
    errors=[failed_disasm, failed_lift],
  )
  assert_true(result.has_errors())
  assert_true(result.errors().length() == 2)
  assert_true(result.errors()[0].memory().min_addr() == 0xa200UL)
  match result.errors()[0].instruction() {
    None => ()
    Some(_) => fail("unexpected failed disassembly instruction")
  }
  assert_true(result.errors()[0].reason() == None)
  assert_true(
    result.errors()[0].to_string() == "failed to disassemble 0xa200-0xa200",
  )
  match result.errors()[1].instruction() {
    Some(instruction) => assert_true(instruction.assembly() == "bad")
    None => fail("missing failed lift instruction")
  }
  assert_true(result.errors()[1].reason() == Some("unsupported semantics"))
  assert_true(
    result.errors()[1].to_string() ==
    "failed to lift bad at 0xa200-0xa200: unsupported semantics",
  )
}

///|
test "project recursive disassembly runs driver and brancher" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xa300UL,
    b"\x01\x02",
  )
  let edge = @project.ProjectDisassemblyEdge::create(
    source=0xa300UL,
    target=0xa301UL,
    kind=FallEdge,
  )
  let brancher = @project.ProjectBrancher::of_edges([edge])
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    @memory.MemMap::empty().add(memory, "text"),
  )
  match project.disassemble_rec(driver="raw-bytes", brancher~) {
    Ok(result) => {
      assert_true(result.project().get("disassembler") == Some("raw-bytes"))
      assert_true(result.disassembly().block_count() == 1)
      assert_true(result.disassembly().instruction_count() == 2)
      assert_true(result.disassembly().edge_count() == 1)
      assert_true(result.disassembly().has_edge(edge))
      assert_true(result.cfg().node_count() == 1)
      assert_true(result.cfg().edge_count() == 1)
      assert_true(!result.has_errors())
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectDisassemblyRec::scan(project, driver="raw-bytes", brancher~) {
    Ok(state) => {
      assert_true(state.instruction_count() == 2)
      assert_true(state.has_edge(edge))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project recursive disassembly keeps BAP one-instruction micro CFGs" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let samples = [b"\xc3", b"\xe8\x47\xee\xff\xff"]
  for bytes in samples {
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0UL,
      bytes,
    )
    let project = @project.Project::empty(@core_theory.Target::x86_64()).with_memory(
      @memory.MemMap::empty().add(memory, "text"),
    )
    match project.disassemble_rec(driver="basic") {
      Ok(result) => {
        assert_true(!result.has_errors())
        assert_true(result.disassembly().instruction_count() == 1)
        assert_true(result.disassembly().block_count() == 1)
        let cfg = result.cfg()
        assert_true(cfg.node_count() == 1)
        assert_true(cfg.edge_count() == 0)
        let block = cfg.nodes()[0].memory()
        assert_true(block.min_addr() == 0UL)
        assert_true(block.max_addr() == bytes.length().to_uint64() - 1UL)
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "project recursive disassembly splits ARM strlen CFG fixture" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x840cUL,
    rec_arm_strlen_bytes(),
  )
  let project = @project.Project::empty(@core_theory.Target::arm()).with_memory(
    @memory.MemMap::empty().add(memory, "text"),
  )
  match project.disassemble_rec(driver="basic") {
    Ok(result) => {
      assert_true(!result.has_errors())
      assert_true(result.disassembly().instruction_count() == 21)
      assert_true(result.disassembly().block_count() == 4)
      let cfg = result.cfg()
      assert_true(cfg.node_count() == 4)
      assert_true(cfg.edge_count() == 4)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0x840cUL, 0x8428UL, 0x8440UL, 0x844cUL],
      )
      assert_true(
        blocks.map(block => block.memory().length()) == [28, 24, 12, 20],
      )
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing ARM entry jump edge")
      }
      match cfg.edge(blocks[1], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing ARM loop fall edge")
      }
      match cfg.edge(blocks[2], blocks[1]) {
        Some(edge) => assert_true(edge.kind() == CondEdge)
        None => fail("missing ARM conditional loop edge")
      }
      match cfg.edge(blocks[2], blocks[3]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing ARM exit fall edge")
      }
      assert_true(cfg.predecessors(blocks[0]).is_empty())
      assert_true(
        cfg.predecessors(blocks[1]).map(block => block.addr()) == [0x8440UL],
      )
      assert_true(
        cfg.predecessors(blocks[2]).map(block => block.addr()) ==
        [0x840cUL, 0x8428UL],
      )
      assert_true(
        cfg.predecessors(blocks[3]).map(block => block.addr()) == [0x8440UL],
      )
      assert_true(cfg.successors(blocks[3]).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project recursive disassembly splits BAP call1 micro CFG" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xa400UL,
    b"\xe8\x01\x00\x00\x00" + b"\xc3" + b"\xc3" + b"\xc3",
  )
  let project = @project.Project::empty(@core_theory.Target::x86_64()).with_memory(
    @memory.MemMap::empty().add(memory, "text"),
  )
  match project.disassemble_rec(driver="basic") {
    Ok(result) => {
      assert_true(!result.has_errors())
      assert_true(result.disassembly().instruction_count() == 4)
      assert_true(result.disassembly().block_count() == 4)
      let cfg = result.cfg()
      assert_true(cfg.node_count() == 4)
      assert_true(cfg.edge_count() == 2)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0xa400UL, 0xa405UL, 0xa406UL, 0xa407UL],
      )
      assert_true(blocks.map(block => block.memory().length()) == [5, 1, 1, 1])
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing call target edge")
      }
      match cfg.edge(blocks[0], blocks[1]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing call fall-through edge")
      }
      assert_true(cfg.successors(blocks[1]).is_empty())
      assert_true(cfg.successors(blocks[2]).is_empty())
      assert_true(cfg.successors(blocks[3]).is_empty())
    }
    Err(reason) => fail(reason)
  }
}
