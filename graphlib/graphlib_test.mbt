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
struct LabeledNode {
  id : Int
  name : String
} derive(Eq, Debug)

///|
test "translated BAP graph node update preserves incident edges" {
  let n1 = { id: 1, name: "1" }
  let n2 = { id: 2, name: "2" }
  let s1 = { id: 1, name: "one" }
  let s2 = { id: 2, name: "two" }
  let graph : @graphlib.Graph[LabeledNode, Unit] = @graphlib.Graph::new()
    .add_edge(src=n1, dst=n2, label=())
    .replace_node(n1, s1)
    .replace_node(n2, s2)
  assert_true(!graph.has_node(n1))
  assert_true(!graph.has_node(n2))
  assert_true(graph.has_edge(s1, s2))
  assert_true(graph.predecessors(s2) == [s1])
  assert_true(graph.successors(s1) == [s2])
  inspect(graph.edge_count(), content="1")
}

///|
fn edge_pairs(graph : @graphlib.Graph[Int, String]) -> Set[(Int, Int)] {
  Set::from_array(graph.edges().map(edge => (edge.src, edge.dst)))
}

///|
test "graph union and intersection follow set semantics" {
  let left : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_node(0)
    .add_edge(src=1, dst=2, label="a")
    .add_edge(src=2, dst=3, label="b")
  let right : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=2, dst=3, label="b")
    .add_edge(src=3, dst=4, label="c")
  let union = left.union(right)
  assert_true(
    Set::from_array(union.nodes()) == Set::from_array([0, 1, 2, 3, 4]),
  )
  assert_true(edge_pairs(union) == Set::from_array([(1, 2), (2, 3), (3, 4)]))
  let intersection = left.intersect(right)
  assert_true(Set::from_array(intersection.nodes()) == Set::from_array([2, 3]))
  assert_true(edge_pairs(intersection) == Set::from_array([(2, 3)]))
}

///|
test "partitions support BAP trivial discrete union and refinement invariants" {
  let elements = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let trivial = @graphlib.Partition::trivial(elements)
  assert_true(trivial.group_count() == 1)
  assert_true(elements.all(x => elements.all(y => trivial.equiv(x, y))))
  let discrete = @graphlib.Partition::discrete(elements)
  assert_true(discrete.group_count() == elements.length())
  assert_true(
    elements.all(x => elements.all(y => discrete.equiv(x, y) == (x == y))),
  )
  let joined = discrete.union(1, 2)
  assert_true(joined.equiv(1, 2))
  assert_true(!joined.equiv(1, 3))
  let refined = trivial.refine((x, y) => (x - y) % 2 == 0)
  assert_true(refined.group_count() == 2)
  let covered : Set[Int] = Set([], capacity=elements.length())
  for group in refined.groups() {
    match group.iter().next() {
      Some(representative) =>
        for element in group {
          covered.add(element)
          assert_true((representative - element) % 2 == 0)
        }
      None => fail("empty partition group")
    }
  }
  assert_true(covered == Set::from_array(elements))
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
test "dfs numbering exposes BAP timestamp and rpost invariants" {
  let graph = sample_graph()
  let numbering = graph.dfs_numbering(0)
  let rpo = graph.reverse_postorder(0)
  for i, node in rpo {
    assert_true(numbering.contains(node))
    let info = numbering[node]
    assert_true(info.enter < info.leave)
    assert_true(info.pre >= 0)
    assert_true(info.rpost == i)
  }
  for event in graph.dfs_edges(0) {
    let src = numbering[event.1.src]
    let dst = numbering[event.1.dst]
    match event.0 {
      Back => {
        assert_true(src.pre >= dst.pre)
        assert_true(src.rpost >= dst.rpost)
      }
      Tree | Forward => {
        assert_true(src.pre < dst.pre)
        assert_true(src.rpost < dst.rpost)
      }
      Cross => {
        assert_true(src.pre > dst.pre)
        assert_true(src.rpost < dst.rpost)
      }
    }
  }
}

///|
fn component_containing(components : Array[Set[Int]], node : Int) -> Set[Int]? {
  components
  .search_by(component => component.contains(node))
  .map(index => components[index])
}

///|
fn same_component(components : Array[Set[Int]], lhs : Int, rhs : Int) -> Bool {
  match component_containing(components, lhs) {
    Some(component) => component.contains(rhs)
    None => false
  }
}

///|
test "strong components group mutually reachable nodes" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=0, dst=1, label="entry")
    .add_edge(src=1, dst=2, label="cycle")
    .add_edge(src=2, dst=1, label="cycle")
    .add_edge(src=2, dst=3, label="exit")
    .add_edge(src=3, dst=4, label="cycle")
    .add_edge(src=4, dst=3, label="cycle")
    .add_edge(src=5, dst=5, label="self")
  let components = graph.strong_components()
  assert_true(components.length() == 4)
  assert_true(component_containing(components, 0) == Some(Set::from_array([0])))
  assert_true(
    component_containing(components, 1) == Some(Set::from_array([1, 2])),
  )
  assert_true(
    component_containing(components, 3) == Some(Set::from_array([3, 4])),
  )
  assert_true(component_containing(components, 5) == Some(Set::from_array([5])))
  assert_true(same_component(components, 1, 2))
  assert_true(same_component(components, 3, 4))
  assert_true(!same_component(components, 0, 1))
  assert_true(!same_component(components, 2, 3))
  assert_true(!same_component(components, 4, 5))
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

///|
test "immediate dominators and frontiers describe branches and loop headers" {
  let graph = sample_graph()
  let idoms = graph.immediate_dominators(0)
  assert_true(!idoms.contains(0))
  assert_true(idoms[1] == 0)
  assert_true(idoms[2] == 1)
  assert_true(idoms[3] == 1)
  assert_true(idoms[4] == 1)
  let frontiers = graph.dominance_frontiers(0)
  assert_true(frontiers[0].is_empty())
  assert_true(frontiers[1] == Set::from_array([1]))
  assert_true(frontiers[2] == Set::from_array([4]))
  assert_true(frontiers[3] == Set::from_array([4]))
  assert_true(frontiers[4] == Set::from_array([1]))
}

///|
test "dominance frontiers report diamond joins" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=0, dst=1, label="then")
    .add_edge(src=0, dst=2, label="else")
    .add_edge(src=1, dst=3, label="join")
    .add_edge(src=2, dst=3, label="join")
  let idoms = graph.immediate_dominators(0)
  assert_true(idoms[1] == 0)
  assert_true(idoms[2] == 0)
  assert_true(idoms[3] == 0)
  let frontiers = graph.dominance_frontiers(0)
  assert_true(frontiers[0].is_empty())
  assert_true(frontiers[1] == Set::from_array([3]))
  assert_true(frontiers[2] == Set::from_array([3]))
  assert_true(frontiers[3].is_empty())
}
