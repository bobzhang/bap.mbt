///|
fn sample_graph() -> @graphlib.Graph[Int, String] {
  @graphlib.Graph::new()
  .add_edge(src=0, dst=1, label="entry")
  .add_edge(src=1, dst=2, label="then")
  .add_edge(src=1, dst=3, label="else")
  .add_edge(src=2, dst=4, label="join")
  .add_edge(src=3, dst=4, label="join")
  .add_edge(src=4, dst=1, label="loop")
}

///|
test "graph construction is persistent and deterministic" {
  let empty : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
  let graph = empty.add_edge(src=1, dst=2, label="edge")
  assert_true(empty.is_empty())
  inspect(graph.node_count(), content="2")
  inspect(graph.edge_count(), content="1")
  assert_true(graph.has_node(1))
  assert_true(graph.has_edge(1, 2))
  assert_true(graph.edge(1, 2).map(e => e.label) == Some("edge"))
  assert_true(graph.successors(1) == [2])
  assert_true(graph.predecessors(2) == [1])
}

///|
test "dfs classifies tree and back edges" {
  let graph = sample_graph()
  let kinds = graph.dfs_edges(0).map(pair => pair.0)
  assert_true(kinds.contains(Tree))
  assert_true(kinds.contains(Back))
  assert_true(graph.reachable(0).length() == 5)
  assert_true(graph.reverse_postorder(0)[0] == 0)
}

///|
test "dominators converge for a small flow graph" {
  let graph = sample_graph()
  let doms = graph.dominators(0)
  assert_true(doms[0] == Set::from_array([0]))
  assert_true(doms[1] == Set::from_array([0, 1]))
  assert_true(doms[2] == Set::from_array([0, 1, 2]))
  assert_true(doms[3] == Set::from_array([0, 1, 3]))
  assert_true(doms[4] == Set::from_array([0, 1, 4]))
}
