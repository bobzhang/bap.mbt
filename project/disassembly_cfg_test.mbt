///|
fn cfg_test_block(
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
fn cfg_test_state(
  blocks : Array[@project.ProjectDisassemblyBlock],
) -> @project.ProjectDisassemblyState {
  let mut state = @project.ProjectDisassemblyState::empty()
  for block in blocks {
    state = state.add_block(block.memory())
    for instruction in block.instructions() {
      state = state.add_instruction(instruction)
    }
  }
  state
}

///|
test "project disassembly cfg supports BAP-style graph operations" {
  let entry = cfg_test_block(0x9000UL, b"\x01")
  let body = cfg_test_block(0x9010UL, b"\x02")
  let exit = cfg_test_block(0x9020UL, b"\x03")
  let edge = @project.ProjectDisassemblyCfgEdge::create(
    src=entry,
    dst=body,
    kind=FallEdge,
  )
  assert_true(edge.src().addr() == 0x9000UL)
  assert_true(edge.dst().addr() == 0x9010UL)
  assert_true(edge.kind() == FallEdge)
  let cfg = @project.ProjectDisassemblyCfg::empty()
  assert_true(cfg.is_empty())
  let cfg = cfg.insert_node(body).insert_node(entry).insert_node(entry)
  assert_true(cfg.node_count() == 2)
  assert_true(cfg.nodes()[0].addr() == 0x9000UL)
  assert_true(cfg.nodes()[1].addr() == 0x9010UL)
  let cfg = cfg
    .insert_edge(edge)
    .insert_edge(edge)
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=body,
        dst=exit,
        kind=CondEdge,
      ),
    )
  assert_true(cfg.node_count() == 3)
  assert_true(cfg.edge_count() == 2)
  assert_true(cfg.has_node(exit))
  assert_true(cfg.has_edge(entry, body))
  assert_true(!cfg.has_edge(exit, entry))
  match cfg.edge(body, exit) {
    Some(found) => assert_true(found.kind() == CondEdge)
    None => fail("missing body->exit edge")
  }
  assert_true(cfg.successors(entry).map(block => block.addr()) == [0x9010UL])
  assert_true(cfg.succs(body).map(block => block.addr()) == [0x9020UL])
  assert_true(cfg.predecessors(exit).map(block => block.addr()) == [0x9010UL])
  assert_true(cfg.preds(body).map(block => block.addr()) == [0x9000UL])
  assert_true(cfg.out_edges(body).length() == 1)
  assert_true(cfg.outputs(body).length() == 1)
  assert_true(cfg.in_edges(body).length() == 1)
  assert_true(cfg.inputs(body).length() == 1)
  assert_true(cfg.out_degree(body) == 1)
  assert_true(cfg.in_degree(body) == 1)
  assert_true(cfg.degree(body) == 2)
  let as_state_edges = cfg.to_disassembly_edges()
  assert_true(as_state_edges.length() == 2)
  assert_true(as_state_edges[0].source() == 0x9000UL)
  assert_true(as_state_edges[0].target() == Some(0x9010UL))
  assert_true(as_state_edges[0].kind() == FallEdge)
  let without_edge = cfg.remove_edge(edge)
  assert_true(without_edge.edge_count() == 1)
  assert_true(!without_edge.has_edge(entry, body))
  let without_node = cfg.remove_node(body)
  assert_true(without_node.node_count() == 2)
  assert_true(!without_node.has_node(body))
  assert_true(without_node.edge_count() == 0)
}

///|
test "project disassembly cfg derives block edges from disassembly state" {
  let entry = cfg_test_block(0x9300UL, b"\x01\x02")
  let body = cfg_test_block(0x9310UL, b"\x03\x04")
  let exit = cfg_test_block(0x9320UL, b"\x05")
  let empty_block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x9400UL,
    b"\x06",
  )
  let disassembly = cfg_test_state([exit, body, entry])
    .add_block(empty_block)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x9301UL,
        target=0x9311UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x9310UL,
        target=0x9320UL,
        kind=JumpEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(source=0x9320UL, kind=JumpEdge),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x9320UL,
        target=0x9999UL,
        kind=CondEdge,
      ),
    )
  let cfg = disassembly.cfg()
  assert_true(cfg.node_count() == 3)
  assert_true(
    cfg.nodes().map(block => block.addr()) == [0x9300UL, 0x9310UL, 0x9320UL],
  )
  assert_true(cfg.edge_count() == 2)
  assert_true(cfg.has_edge(entry, body))
  assert_true(cfg.has_edge(body, exit))
  match cfg.edge(entry, body) {
    Some(edge) => assert_true(edge.kind() == FallEdge)
    None => fail("missing entry->body edge")
  }
  match cfg.edge(body, exit) {
    Some(edge) => assert_true(edge.kind() == JumpEdge)
    None => fail("missing body->exit edge")
  }
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    disassembly,
  )
  assert_true(project.disassembly_cfg().edge_count() == 2)
}
