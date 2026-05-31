///|
fn tid_graph_names(tids : Array[@types.Tid]) -> Array[String] {
  tids.map(tid => tid.to_string())
}

///|
test "BAP-style tid graph adds pseudo start and exit around local cfg" {
  let entry = @types.Blk::create(tid=@types.Tid::for_name("tg-entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("tg-body"))
  let dead = @types.Blk::create(tid=@types.Tid::for_name("tg-dead"))
  let entry = entry.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(body.tid())),
  )
  let sub = @types.Sub::create(name="tid-graph", blks=[entry, body, dead])
  let graph = sub.sub_tid_graph()
  let graph_alias = sub.to_graph()
  let start = @types.tid_graph_start()
  let exit = @types.tid_graph_exit()
  assert_true(graph.has_node(start))
  assert_true(graph.has_node(exit))
  assert_true(graph_alias.node_count() == graph.node_count())
  assert_true(graph_alias.edge_count() == graph.edge_count())
  assert_true(graph_alias.has_edge(start, entry.tid()))
  assert_true(graph_alias.has_edge(dead.tid(), exit))
  assert_true(graph.has_edge(start, entry.tid()))
  assert_true(graph.has_edge(entry.tid(), body.tid()))
  assert_true(graph.has_edge(body.tid(), exit))
  assert_true(graph.has_edge(start, dead.tid()))
  assert_true(graph.has_edge(dead.tid(), exit))
  assert_true(
    tid_graph_names(graph.successors(start)) ==
    [entry.tid().to_string(), dead.tid().to_string()],
  )
}

///|
test "BAP-style tid graph anchors unrooted cycles with one start and exit edge" {
  let left = @types.Blk::create(tid=@types.Tid::for_name("tg-left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("tg-right"))
  let left = left.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(right.tid())),
  )
  let right = right.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(left.tid())),
  )
  let sub = @types.Sub::create(name="tid-cycle", blks=[left, right])
  let graph = sub.sub_tid_graph()
  let start = @types.tid_graph_start()
  let exit = @types.tid_graph_exit()
  assert_true(graph.has_edge(left.tid(), right.tid()))
  assert_true(graph.has_edge(right.tid(), left.tid()))
  assert_true(
    tid_graph_names(graph.successors(start)) == [left.tid().to_string()],
  )
  assert_true(
    tid_graph_names(graph.predecessors(exit)) == [left.tid().to_string()],
  )
  assert_true(graph.reachable(start).contains(right.tid()))
  assert_true(graph.reachable(right.tid()).contains(exit))
}

///|
test "BAP-style tid graph still exposes pseudo nodes for empty subroutines" {
  let sub = @types.Sub::create(name="empty")
  let graph = sub.sub_tid_graph()
  assert_true(graph.node_count() == 2)
  assert_true(graph.edge_count() == 0)
  assert_true(graph.has_node(@types.tid_graph_start()))
  assert_true(graph.has_node(@types.tid_graph_exit()))
}
