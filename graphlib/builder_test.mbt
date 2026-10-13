///|
test "graph builder agrees with the persistent graph operations" {
  let ops : Array[(Int32, Int32?, String)] = [
    (5, None, ""),
    (0, Some(1), "entry"),
    (1, Some(2), "then"),
    (7, None, ""),
    (1, Some(3), "else"),
    (2, Some(4), "join"),
    (1, Some(2), "relabeled"),
    (3, Some(4), "join"),
    (4, Some(1), "loop"),
    (2, None, ""),
    (0, Some(1), "entry again"),
  ]
  let builder : @graphlib.GraphBuilder[Int32, String] = @graphlib.GraphBuilder::new()
  let mut graph : @graphlib.Graph[Int32, String] = @graphlib.Graph::new()
  for op in ops {
    match op {
      (node, None, _) => {
        builder.add_node(node)
        graph = graph.add_node(node)
      }
      (src, Some(dst), label) => {
        builder.add_edge(src~, dst~, label~)
        graph = graph.add_edge(src~, dst~, label~)
      }
    }
  }
  let built = builder.to_graph()
  assert_eq(built.nodes(), graph.nodes())
  assert_eq(
    built.edges().map(e => (e.src(), e.dst(), e.label())),
    graph.edges().map(e => (e.src(), e.dst(), e.label())),
  )
  // the built graph is a snapshot
  builder.add_node(9)
  assert_false(built.has_node(9))
  assert_eq(built.nodes(), [5, 0, 1, 2, 7, 3, 4])
}
