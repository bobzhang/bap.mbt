///|
fn cfg_blk_tids(blks : Array[@types.Term[@types.Blk]]) -> Array[@types.Tid] {
  blks.map(blk => blk.tid())
}

///|
fn cfg_edge_tids(edges : Array[@types.IrCfgEdge]) -> Array[@types.Tid] {
  edges.map(edge => edge.tid())
}

///|
fn cfg_edge_positions(edges : Array[@types.IrCfgEdge]) -> Array[Int] {
  edges.map(edge => edge.position())
}

///|
fn cfg_block_jmp_count(
  cfg : @types.IrCfg,
  blk : @types.Term[@types.Blk],
) -> Int {
  cfg.to_sub().find_blk(blk.tid()).unwrap().jmps().length()
}

///|
test "BAP IR CFG create and sub round trip preserve sub identity" {
  let tid = @types.Tid::for_name("cfg")
  let cfg = @types.IrCfg::create(name="main", tid~)
  assert_true(@types.IrCfg::is_directed())
  assert_true(cfg.is_empty())
  assert_true(cfg.node_count() == 0)
  assert_true(cfg.edge_count() == 0)
  let sub = cfg.to_sub()
  assert_true(sub.tid() == tid)
  assert_true(sub.sub_name() == "main")
  let round_trip = sub.to_ir_cfg().to_sub()
  assert_true(round_trip.tid() == sub.tid())
  assert_true(round_trip.sub_name() == sub.sub_name())
}

///|
test "BAP IR CFG exposes block nodes and positional edges" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let first = @types.Jmp::create_goto(@types.Label::direct(body.tid()))
  let second = @types.Jmp::create_goto(@types.Label::direct(body.tid()))
  let third = @types.Jmp::create_goto(@types.Label::direct(exit.tid()))
  let entry = entry.append_jmp(first).append_jmp(second).append_jmp(third)
  let sub = @types.Sub::create(name="with-parallel", blks=[entry, body, exit])
  let cfg = @types.IrCfg::of_sub(sub)
  assert_true(!cfg.is_empty())
  assert_true(cfg.node_count() == 3)
  assert_true(
    cfg_blk_tids(cfg.nodes()) == [entry.tid(), body.tid(), exit.tid()],
  )
  assert_true(cfg.has_node(entry))
  assert_true(
    !cfg.has_node(@types.Blk::create(tid=@types.Tid::for_name("missing"))),
  )
  assert_true(cfg.edges().length() == 3)
  assert_true(cfg.edge_count() == 2)
  assert_true(
    cfg_edge_tids(cfg.edges()) == [first.tid(), second.tid(), third.tid()],
  )
  assert_true(cfg.has_edge(entry, body))
  assert_true(cfg.has_edge(entry, exit))
  assert_true(!cfg.has_edge(body, entry))
  match cfg.edge(entry, body) {
    Some(edge) => {
      assert_true(edge.position() == 0)
      assert_true(edge.tid() == first.tid())
    }
    None => fail("expected entry-to-body edge")
  }
}

///|
test "BAP IR CFG successor predecessor and degree queries use graph endpoints" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let join = @types.Blk::create(tid=@types.Tid::for_name("join"))
  let entry = entry
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(left.tid())))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(right.tid())))
  let left_jmp = @types.Jmp::create_goto(@types.Label::direct(join.tid()))
  let right_jmp = @types.Jmp::create_goto(@types.Label::direct(join.tid()))
  let left = left.append_jmp(left_jmp)
  let right = right.append_jmp(right_jmp)
  let cfg = @types.IrCfg::of_sub(
    @types.Sub::create(name="diamond", blks=[entry, left, right, join]),
  )
  assert_true(cfg_blk_tids(cfg.successors(entry)) == [left.tid(), right.tid()])
  assert_true(cfg_blk_tids(cfg.predecessors(join)) == [left.tid(), right.tid()])
  assert_true(
    cfg_edge_tids(cfg.in_edges(join)) == [left_jmp.tid(), right_jmp.tid()],
  )
  assert_true(cfg.out_degree(entry) == 2)
  assert_true(cfg.in_degree(join) == 2)
  assert_true(cfg.degree(left) == 2)
}

///|
test "BAP IR CFG node insertion and removal update graph membership" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let entry = entry.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(body.tid())),
  )
  let body = body.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(exit.tid())),
  )
  let cfg = @types.IrCfg::create(name="editable")
  let cfg = cfg.insert_node(entry).insert_node(body).insert_node(body)
  assert_true(cfg.node_count() == 2)
  assert_true(cfg.edge_count() == 1)
  let cfg = cfg.insert_node(exit)
  assert_true(cfg.node_count() == 3)
  assert_true(cfg.edge_count() == 2)
  let removed = cfg.remove_node(body)
  assert_true(!removed.has_node(body))
  assert_true(removed.node_count() == 2)
  assert_true(!removed.has_edge(entry, body))
  assert_true(removed.edge_count() == 0)
  match removed.to_sub().find_blk(entry.tid()) {
    Some(block) => assert_true(block.jmps().length() == 1)
    None => fail("expected entry to remain")
  }
}

///|
test "BAP IR CFG node update only accepts same-TID replacement blocks" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let entry = entry.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(body.tid())),
  )
  let cfg = @types.IrCfg::of_sub(
    @types.Sub::create(name="update", blks=[entry, body, exit]),
  )
  let wrong_tid = @types.Blk::create(jmps=[
    @types.Jmp::create_goto(@types.Label::direct(exit.tid())),
  ])
  let unchanged = cfg.update_node(entry, wrong_tid)
  assert_true(cfg_blk_tids(unchanged.successors(entry)) == [body.tid()])
  let replacement = @types.Blk::create(tid=entry.tid(), jmps=[
    @types.Jmp::create_goto(@types.Label::direct(exit.tid())),
  ])
  let updated = cfg.update_node(entry, replacement)
  assert_true(updated.has_node(entry))
  assert_true(cfg_blk_tids(updated.successors(entry)) == [exit.tid()])
  assert_true(!updated.has_edge(entry, body))
  assert_true(updated.has_edge(entry, exit))
}

///|
test "BAP IR CFG edge insertion appends retargets and pads positions" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let cfg = @types.IrCfg::create(name="edges").insert_edge(entry, body)
  assert_true(cfg.node_count() == 2)
  assert_true(cfg.has_edge(entry, body))
  assert_true(cfg.out_edges(entry)[0].position() == 0)
  let cfg = cfg.insert_edge(entry, exit, position=0)
  assert_true(cfg.has_node(exit))
  assert_true(!cfg.has_edge(entry, body))
  assert_true(cfg.has_edge(entry, exit))
  assert_true(cfg_block_jmp_count(cfg, entry) == 1)
  let cfg = cfg.insert_edge(entry, body, position=2)
  assert_true(cfg.has_edge(entry, body))
  assert_true(cfg_edge_positions(cfg.out_edges(entry)) == [0, 2])
  assert_true(cfg_block_jmp_count(cfg, entry) == 3)
}

///|
test "BAP IR CFG edge removal leaves middle dummies and trims dummy tail" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let first = @types.Blk::create(tid=@types.Tid::for_name("first"))
  let middle = @types.Blk::create(tid=@types.Tid::for_name("middle"))
  let last = @types.Blk::create(tid=@types.Tid::for_name("last"))
  let cfg = @types.IrCfg::create(name="remove-edge")
    .insert_edge(entry, first)
    .insert_edge(entry, middle)
    .insert_edge(entry, last)
  assert_true(cfg_edge_positions(cfg.out_edges(entry)) == [0, 1, 2])
  let middle_edge = cfg.edge(entry, middle).unwrap()
  let cfg = cfg.remove_edge(middle_edge)
  assert_true(!cfg.has_edge(entry, middle))
  assert_true(cfg_edge_positions(cfg.out_edges(entry)) == [0, 2])
  assert_true(cfg_block_jmp_count(cfg, entry) == 3)
  let last_edge = cfg.edge(entry, last).unwrap()
  let cfg = cfg.remove_edge(last_edge)
  assert_true(!cfg.has_edge(entry, last))
  assert_true(cfg_edge_positions(cfg.out_edges(entry)) == [0])
  assert_true(cfg_block_jmp_count(cfg, entry) == 1)
  let first_edge = cfg.edge(entry, first).unwrap()
  let cfg = cfg.remove_edge(first_edge)
  assert_true(cfg.out_edges(entry).is_empty())
  assert_true(cfg_block_jmp_count(cfg, entry) == 0)
}
