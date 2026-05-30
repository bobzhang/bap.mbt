///|
fn tid_names(tids : Array[@types.Tid]) -> Array[String] {
  [
    for tid in tids => tid.to_string()
  ]
}

///|
fn block_names(blocks : Array[@types.Term[@types.Blk]]) -> Array[String] {
  [
    for block in blocks => block.name()
  ]
}

///|
test "ir graph helpers resolve local successors from jumps" {
  let typ = @types.ValueType::Imm(32)
  let ptr = @types.Var::new(name="ptr", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let dead = @types.Blk::create(tid=@types.Tid::for_name("dead"))
  let entry_jmp = @types.Jmp::create_goto(@types.Label::direct(body.tid()))
  let call = @types.Call::create(
    target=@types.Label::indirect(Var(ptr)),
    return_label=@types.Label::direct(exit.tid()),
  )
  let body_jmp = @types.Jmp::create_call(call)
  let ret_jmp = @types.Jmp::create_ret(@types.Label::direct(entry.tid()))
  let entry = entry.append_jmp(entry_jmp)
  let body = body.append_jmp(body_jmp)
  let exit = exit.append_jmp(ret_jmp)
  assert_true(entry_jmp.succ_tid_of_jmp() == Some(body.tid()))
  assert_true(body_jmp.succ_tid_of_jmp() == Some(exit.tid()))
  assert_true(ret_jmp.succ_tid_of_jmp() is None)
  assert_true(tid_names(entry.blk_successor_tids()) == [body.tid().to_string()])
  let sub = @types.Sub::create(name="main", blks=[entry, body, exit, dead])
  let cfg = sub.sub_cfg()
  assert_true(cfg.node_count() == 4)
  assert_true(cfg.edge_count() == 2)
  assert_true(cfg.has_edge(entry.tid(), body.tid()))
  assert_true(cfg.has_edge(body.tid(), exit.tid()))
  assert_true(!cfg.has_edge(exit.tid(), entry.tid()))
  match cfg.edge(entry.tid(), body.tid()) {
    Some(edge) => assert_true(edge.label == entry_jmp.tid())
    None => fail("expected entry edge")
  }
  assert_true(block_names(sub.sub_successor_blocks(entry)) == ["@body"])
  assert_true(block_names(sub.sub_predecessor_blocks(exit)) == ["@body"])
  assert_true(
    block_names(sub.sub_reverse_postorder()) == ["@entry", "@body", "@exit"],
  )
  assert_true(
    block_names(sub.sub_reachable_blocks()) == ["@entry", "@body", "@exit"],
  )
}

///|
test "ir graph helpers ignore unresolved and external successors" {
  let typ = @types.ValueType::Imm(32)
  let ptr = @types.Var::new(name="ptr", typ~)
  let start = @types.Blk::create(tid=@types.Tid::for_name("start"))
  let handler = @types.Blk::create(tid=@types.Tid::for_name("handler"))
  let interrupt = @types.Jmp::create_int(3, handler.tid())
  let external = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("external")),
  )
  let indirect = @types.Jmp::create_goto(@types.Label::indirect(Var(ptr)))
  let start = start
    .append_jmp(interrupt)
    .append_jmp(external)
    .append_jmp(indirect)
  assert_true(interrupt.succ_tid_of_jmp() == Some(handler.tid()))
  assert_true(external.succ_tid_of_jmp() is Some(_))
  assert_true(indirect.succ_tid_of_jmp() is None)
  let sub = @types.Sub::create(name="trap", blks=[start, handler])
  let cfg = sub.sub_cfg()
  assert_true(cfg.node_count() == 2)
  assert_true(cfg.edge_count() == 1)
  assert_true(cfg.has_edge(start.tid(), handler.tid()))
  assert_true(block_names(sub.sub_successor_blocks(start)) == ["@handler"])
  assert_true(block_names(sub.sub_predecessor_blocks(handler)) == ["@start"])
}

///|
test "ir dominance helpers describe subroutine diamond cfgs" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let join = @types.Blk::create(tid=@types.Tid::for_name("join"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let dead = @types.Blk::create(tid=@types.Tid::for_name("dead"))
  let entry = entry
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(left.tid())))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(right.tid())))
  let left = left.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(join.tid())),
  )
  let right = right.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(join.tid())),
  )
  let join = join.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(exit.tid())),
  )
  let sub = @types.Sub::create(name="diamond", blks=[
    entry, left, right, join, exit, dead,
  ])

  let doms = sub.sub_dominator_tids()
  assert_true(doms[entry.tid()] == Set::from_array([entry.tid()]))
  assert_true(doms[left.tid()] == Set::from_array([entry.tid(), left.tid()]))
  assert_true(doms[right.tid()] == Set::from_array([entry.tid(), right.tid()]))
  assert_true(doms[join.tid()] == Set::from_array([entry.tid(), join.tid()]))
  assert_true(
    doms[exit.tid()] == Set::from_array([entry.tid(), join.tid(), exit.tid()]),
  )
  assert_true(sub.sub_dominates(entry, join))
  assert_true(sub.sub_strictly_dominates(entry, join))
  assert_true(!sub.sub_strictly_dominates(join, join))
  assert_true(!sub.sub_dominates(left, right))

  let idoms = sub.sub_immediate_dominator_tids()
  assert_true(!idoms.contains(entry.tid()))
  assert_true(idoms[left.tid()] == entry.tid())
  assert_true(idoms[right.tid()] == entry.tid())
  assert_true(idoms[join.tid()] == entry.tid())
  assert_true(idoms[exit.tid()] == join.tid())
  match sub.sub_immediate_dominator(join) {
    Some(block) => assert_true(block.name() == "@entry")
    None => fail("expected join immediate dominator")
  }
  match sub.sub_immediate_dominator(exit) {
    Some(block) => assert_true(block.name() == "@join")
    None => fail("expected exit immediate dominator")
  }

  let frontiers = sub.sub_dominance_frontier_tids()
  assert_true(frontiers[entry.tid()].is_empty())
  assert_true(frontiers[left.tid()] == Set::from_array([join.tid()]))
  assert_true(frontiers[right.tid()] == Set::from_array([join.tid()]))
  assert_true(frontiers[join.tid()].is_empty())
  assert_true(block_names(sub.sub_dominance_frontier_blocks(left)) == ["@join"])
  assert_true(
    block_names(sub.sub_dominance_frontier_blocks(right)) == ["@join"],
  )

  let missing = @types.Tid::for_name("missing")
  assert_true(sub.sub_dominator_tids(entry=missing).is_empty())
  assert_true(sub.sub_immediate_dominator_tids(entry=missing).is_empty())
  assert_true(sub.sub_dominance_frontier_tids(entry=missing).is_empty())
  assert_true(!sub.sub_dominates(entry, join, entry=missing))
  assert_true(sub.sub_immediate_dominator(join, entry=missing) is None)
  assert_true(sub.sub_dominance_frontier_blocks(left, entry=missing).is_empty())
}
