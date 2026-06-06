///|
fn rec_test_block(
  start : UInt64,
  bytes : Bytes,
  assembly? : String = "nop",
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
