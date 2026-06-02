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
  match graph.edge(1, 2) {
    Some(edge) => {
      assert_true(edge.src() == 1)
      assert_true(edge.dst() == 2)
      assert_true(edge.label() == "edge")
    }
    None => fail("expected graph edge")
  }
  let created : @graphlib.Edge[Int, String] = @graphlib.Edge::create(
    3, 4, "created",
  )
  assert_true(created.src() == 3)
  assert_true(created.dst() == 4)
  assert_true(created.label() == "created")
  assert_true(graph.successors(1) == [2])
  assert_true(graph.succs(1) == [2])
  assert_true(graph.predecessors(2) == [1])
  assert_true(graph.preds(2) == [1])
  assert_true(graph.outputs(1).map(edge => edge.label()) == ["edge"])
  assert_true(graph.inputs(2).map(edge => edge.label()) == ["edge"])
}

///|
test "translated BAP graph create folds edges before explicit nodes" {
  let empty : @graphlib.Graph[Int, String] = @graphlib.Graph::create()
  assert_true(empty.is_empty())

  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(1, 2, "first"), (2, 3, "middle"), (1, 2, "updated")],
    nodes=[0, 2, 4],
  )
  assert_true(
    Set::from_array(graph.nodes()) == Set::from_array([0, 1, 2, 3, 4]),
  )
  assert_true(graph.nodes() == [1, 2, 3, 0, 4])
  assert_true(edge_pairs(graph) == Set::from_array([(1, 2), (2, 3)]))
  assert_true(graph.edge(1, 2).map(edge => edge.label) == Some("updated"))
  assert_true(graph.has_node(0))
  assert_true(graph.has_node(4))
}

///|
test "translated BAP graph removal keeps nodes and incident edges coherent" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=0, dst=1, label="entry")
    .add_edge(src=1, dst=2, label="body")
    .add_edge(src=2, dst=0, label="loop")
  let without_edge = graph.remove_edge(1, 2)
  assert_true(without_edge.node_count() == 3)
  assert_true(without_edge.edge_count() == 2)
  assert_true(!without_edge.has_edge(1, 2))
  assert_true(without_edge.predecessors(2).is_empty())
  assert_true(without_edge.has_edge(0, 1))
  assert_true(without_edge.has_edge(2, 0))

  let without_node = graph.remove_node(1)
  assert_true(without_node.node_count() == 2)
  assert_true(without_node.edge_count() == 1)
  assert_true(!without_node.has_node(1))
  assert_true(!without_node.has_edge(0, 1))
  assert_true(!without_node.has_edge(1, 2))
  assert_true(without_node.has_edge(2, 0))

  let reinserted = without_node.add_node(1)
  assert_true(reinserted.node_count() == 3)
  assert_true(reinserted.edge_count() == 1)
  assert_true(reinserted.has_node(1))
  assert_true(!reinserted.has_edge(0, 1))
  assert_true(!reinserted.has_edge(1, 2))

  let restored = reinserted
    .add_edge(src=0, dst=1, label="entry")
    .add_edge(src=1, dst=2, label="body")
  assert_true(restored.node_count() == 3)
  assert_true(restored.edge_count() == 3)
  assert_true(edge_pairs(restored) == Set::from_array([(0, 1), (1, 2), (2, 0)]))
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
  assert_true(left.inter(right).edges() == intersection.edges())
}

///|
test "graph set operations key edges by endpoints and keep left labels" {
  let left : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=1, dst=2, label="left")
    .add_edge(src=2, dst=3, label="only-left")
  let right : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=1, dst=2, label="right")
    .add_edge(src=3, dst=4, label="only-right")
  let union = left.union(right)
  assert_true(edge_pairs(union) == Set::from_array([(1, 2), (2, 3), (3, 4)]))
  assert_true(union.edge(1, 2).map(edge => edge.label) == Some("left"))
  let intersection = left.intersect(right)
  assert_true(edge_pairs(intersection) == Set::from_array([(1, 2)]))
  assert_true(intersection.edge(1, 2).map(edge => edge.label) == Some("left"))
}

///|
test "translated BAP graph compare follows endpoint and node-set ordering" {
  let same_edges : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (1, 2, "left"),
  ])
  let same_edges_extra_node : @graphlib.Graph[Int, Unit] = @graphlib.Graph::create(
    edges=[(1, 2, ())],
    nodes=[0],
  )
  assert_true(same_edges.compare(same_edges_extra_node) == 0)

  let same_nodes_left : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(1, 2, "a")],
    nodes=[3],
  )
  let same_nodes_right : @graphlib.Graph[Int, Unit] = @graphlib.Graph::create(
    edges=[(1, 3, ())],
    nodes=[2],
  )
  assert_true(same_nodes_left.compare(same_nodes_right) == 0)

  let lower_nodes : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(1, 3, "a")],
    nodes=[0],
  )
  let higher_nodes : @graphlib.Graph[Int, Unit] = @graphlib.Graph::create(
    edges=[(1, 2, ())],
    nodes=[9],
  )
  assert_true(lower_nodes.compare(higher_nodes) < 0)
  assert_true(higher_nodes.compare(lower_nodes) > 0)
}

///|
test "translated BAP graph filtered hides nodes and invisible edges" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(0, 1, "keep"), (1, 2, "hidden-by-node"), (3, 4, "hidden-by-edge")],
    nodes=[5],
  )
  let filtered = graph.filtered(skip_node=node => node == 2, skip_edge=edge => {
    edge.label == "hidden-by-edge"
  })
  assert_true(graph.has_node(2))
  assert_true(!filtered.has_node(2))
  assert_true(
    Set::from_array(filtered.nodes()) == Set::from_array([0, 1, 3, 4, 5]),
  )
  assert_true(edge_pairs(filtered) == Set::from_array([(0, 1)]))
  assert_true(!filtered.has_edge(1, 2))
  assert_true(!filtered.has_edge(3, 4))
  assert_true(filtered.has_node(3))
  assert_true(filtered.has_node(4))

  let unfiltered = graph.filtered()
  assert_true(
    Set::from_array(unfiltered.nodes()) == Set::from_array([0, 1, 2, 3, 4, 5]),
  )
  assert_true(
    edge_pairs(unfiltered) == Set::from_array([(0, 1), (1, 2), (3, 4)]),
  )
}

///|
test "translated BAP graph view maps nodes and edge labels" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(1, 2, "a"), (2, 3, "b")],
    nodes=[4],
  )
  let view = graph.view(node=node => "n\{node}", edge=edge => {
    "\{edge.src}->\{edge.dst}:\{edge.label}"
  })
  assert_true(view.nodes() == ["n1", "n2", "n3", "n4"])
  assert_true(
    view.edges() ==
    [
      { src: "n1", dst: "n2", label: "1->2:a" },
      { src: "n2", dst: "n3", label: "2->3:b" },
    ],
  )
  assert_true(view.has_edge("n1", "n2"))
  assert_true(view.successors("n2") == ["n3"])

  let changed = graph.add_edge(src=3, dst=4, label="c")
  assert_true(changed.has_edge(3, 4))
  assert_true(!view.has_edge("n3", "n4"))
}

///|
test "translated BAP graph to_dot uses reverse-postorder node names by default" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (0, 1, "left"),
    (0, 2, "right"),
  ])
  let dot = graph.to_dot()
  assert_true(dot.contains("digraph \"G\""))
  assert_true(dot.contains("\"0\";"))
  assert_true(dot.contains("\"2\";"))
  assert_true(dot.contains("\"1\";"))
  assert_true(dot.contains("\"0\" -> \"2\";"))
  assert_true(dot.contains("\"0\" -> \"1\";"))
  assert_true(!dot.contains("left"))
  assert_true(!dot.contains("right"))
}

///|
test "translated BAP graph to_dot honors custom labels and attributes" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (0, 1, "auto"),
    (1, 2, "manual"),
  ])
  let dot = graph.to_dot(
    name="flow",
    graph_attrs=[("rankdir", "LR")],
    string_of_node=Some(node => "n\{node}"),
    string_of_edge=Some(edge => edge.label),
    node_attrs=node => [("label", "node \{node}")],
    edge_attrs=edge => {
      if edge.label == "manual" {
        [("label", "given"), ("color", "blue")]
      } else {
        [("color", "red")]
      }
    },
  )
  assert_true(dot.contains("digraph \"flow\""))
  assert_true(dot.contains("rankdir=\"LR\";"))
  assert_true(dot.contains("\"n0\" [label=\"node 0\"];"))
  assert_true(dot.contains("\"n0\" -> \"n1\" [label=\"auto\", color=\"red\"];"))
  assert_true(
    dot.contains("\"n1\" -> \"n2\" [label=\"given\", color=\"blue\"];"),
  )
  assert_true(!dot.contains("manual"))
}

///|
test "partitions support BAP trivial discrete union and refinement invariants" {
  let empty : @graphlib.Partition[Int] = @graphlib.Partition::trivial([])
  assert_true(empty.group_count() == 0)
  assert_true(empty.number_of_groups() == 0)
  let empty_discrete : @graphlib.Partition[Int] = @graphlib.Partition::discrete([],
  )
  assert_true(empty_discrete.group_count() == 0)
  let elements = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let trivial = @graphlib.Partition::trivial(elements)
  assert_true(trivial.group_count() == 1)
  assert_true(elements.all(x => elements.all(y => trivial.equiv(x, y))))
  let discrete = @graphlib.Partition::discrete(elements)
  assert_true(discrete.group_count() == elements.length())
  assert_true(
    elements.all(x => elements.all(y => discrete.equiv(x, y) == (x == y))),
  )
  let unchanged = discrete.union(1, 99)
  assert_true(unchanged.group_count() == discrete.group_count())
  assert_true(!unchanged.equiv(1, 99))
  let joined = discrete.union(1, 2)
  assert_true(joined.equiv(1, 2))
  assert_true(!joined.equiv(1, 3))
  match joined.group(1) {
    Some(group) => {
      assert_true(group.top() == 1)
      assert_true(group.mem(2))
      assert_true(group.members().contains(1))
      assert_true(Set::from_array(group.enumerate()) == Set::from_array([1, 2]))
      let group_text = group.to_string(element_to_string=element => {
        element.to_string()
      })
      assert_true(group_text.contains("{1: 1 => ("))
      assert_true(group_text.contains("1"))
      assert_true(group_text.contains("2"))
      match joined.of_equiv(group.to_equiv()) {
        Some(same) => {
          assert_true(same.mem(1))
          assert_true(same.mem(2))
          assert_true(same.to_equiv().to_int() == group.to_equiv().to_int())
        }
        None => fail("expected group by equivalence id")
      }
    }
    None => fail("expected joined group")
  }
  let refined = trivial.refine((x, y) => (x - y) % 2 == 0)
  assert_true(refined.group_count() == 2)
  let partition_text = refined.to_string(element_to_string=element => {
    element.to_string()
  })
  assert_true(partition_text.contains("partition = {"))
  assert_true(partition_text.contains("=> ("))
  let covered : Set[Int] = Set([], capacity=elements.length())
  for group in refined.groups() {
    let representative = group.top()
    for element in group.elements() {
      covered.add(element)
      assert_true((representative - element) % 2 == 0)
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
  assert_true(graph.reachable(4, rev=true) == Set::from_array([0, 1, 2, 3, 4]))
  assert_true(graph.reachable(0, rev=true) == Set::from_array([0]))
  assert_true(graph.is_reachable(0, 4))
  assert_true(!graph.is_reachable(2, 0))
  assert_true(graph.is_reachable(4, 0, rev=true))
  assert_true(!graph.is_reachable(0, 4, rev=true))
  assert_true(
    graph.fold_reachable(0, [], (acc, node) => {
      acc.push(node)
      acc
    }) ==
    [0, 1, 2, 4, 3],
  )
  assert_true(
    graph.fold_reachable(
      4,
      [],
      (acc, node) => {
        acc.push(node)
        acc
      },
      rev=true,
    ) ==
    [4, 2, 1, 0, 3],
  )
  assert_true(
    graph.fold_reachable(99, [7], (acc, node) => {
      acc.push(node)
      acc
    }) ==
    [7],
  )
  assert_true(graph.postorder(0) == [4, 2, 3, 1, 0])
  assert_true(graph.reverse_postorder(0) == [0, 1, 3, 2, 4])
  assert_true(graph.postorder(4, rev=true) == [0, 1, 2, 3, 4])
  assert_true(graph.reverse_postorder(4, rev=true) == [4, 3, 2, 1, 0])
  assert_true(graph.reverse_postorder(0)[0] == 0)
}

///|
fn edge_kind_name(kind : @graphlib.EdgeKind) -> String {
  match kind {
    Tree => "tree"
    Back => "back"
    Forward => "forward"
    Cross => "cross"
  }
}

///|
test "translated BAP depth first search invokes traversal callbacks" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (0, 1, "a"),
    (1, 2, "b"),
    (2, 0, "c"),
    (0, 2, "d"),
    (0, 3, "e"),
    (3, 1, "f"),
  ])
  let initial_events : Array[String] = []
  let events = graph.depth_first_search(
    init=initial_events,
    start=Some(0),
    start_tree=(node, events) => {
      events.push("start:\{node}")
      events
    },
    enter_node=(pre, node, events) => {
      events.push("enter:\{pre}:\{node}")
      events
    },
    leave_node=(rpost, node, events) => {
      events.push("leave:\{rpost}:\{node}")
      events
    },
    enter_edge=(kind, edge, events) => {
      events.push("edge:\{edge_kind_name(kind)}:\{edge.label}")
      events
    },
  )
  assert_true(
    events ==
    [
      "start:0", "enter:0:0", "edge:tree:a", "enter:1:1", "edge:tree:b", "enter:2:2",
      "edge:back:c", "leave:3:2", "leave:2:1", "edge:forward:d", "edge:tree:e", "enter:3:3",
      "edge:cross:f", "leave:1:3", "leave:0:0",
    ],
  )
}

///|
test "translated BAP depth first visit delegates visitor callbacks" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (0, 1, "a"),
    (1, 2, "b"),
    (2, 0, "c"),
    (0, 2, "d"),
    (0, 3, "e"),
    (3, 1, "f"),
  ])
  let visitor : @graphlib.DfsVisitor[Int, String, Array[String]] = @graphlib.DfsVisitor::new(
    start_tree=(node, events) => {
      events.push("start:\{node}")
      events
    },
    enter_node=(pre, node, events) => {
      events.push("enter:\{pre}:\{node}")
      events
    },
    leave_node=(rpost, node, events) => {
      events.push("leave:\{rpost}:\{node}")
      events
    },
    enter_edge=(kind, edge, events) => {
      events.push("edge:\{edge_kind_name(kind)}:\{edge.label}")
      events
    },
  )
  let events = graph.depth_first_visit(
    visitor,
    init=([] : Array[String]),
    start=Some(0),
  )
  assert_true(
    events ==
    [
      "start:0", "enter:0:0", "edge:tree:a", "enter:1:1", "edge:tree:b", "enter:2:2",
      "edge:back:c", "leave:3:2", "leave:2:1", "edge:forward:d", "edge:tree:e", "enter:3:3",
      "edge:cross:f", "leave:1:3", "leave:0:0",
    ],
  )

  let identity : @graphlib.DfsVisitor[Int, String, Array[Int]] = @graphlib.DfsVisitor::identity()
  assert_true(graph.depth_first_visit(identity, init=[7], start=Some(0)) == [7])
}

///|
test "translated BAP depth first search starts requested tree then remaining forest" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(edges=[
    (0, 1, "left"),
    (2, 3, "right"),
  ])
  let starts = graph.depth_first_search(init=([] : Array[Int]), start=Some(2), start_tree=(
    node,
    starts,
  ) => {
    starts.push(node)
    starts
  })
  assert_true(starts == [2, 0])

  let reverse_edges = graph.depth_first_search(
    init=([] : Array[String]),
    rev=true,
    start=Some(3),
    enter_edge=(_kind, edge, labels) => {
      labels.push(edge.label)
      labels
    },
  )
  assert_true(reverse_edges == ["right", "left"])
}

///|
test "translated BAP postorder traverse covers whole forest" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::create(
    edges=[(0, 1, "left"), (2, 3, "right")],
    nodes=[4],
  )
  assert_true(graph.postorder(2) == [3, 2])
  assert_true(graph.postorder_traverse() == [1, 0, 3, 2, 4])
  assert_true(graph.reverse_postorder_traverse() == [4, 2, 3, 0, 1])
  assert_true(graph.postorder_traverse(start=Some(2)) == [3, 2, 1, 0, 4])
  assert_true(graph.postorder_traverse(start=Some(99)) == [1, 0, 3, 2, 4])
  assert_true(
    graph.postorder_traverse(rev=true, start=Some(3)) == [2, 3, 0, 1, 4],
  )
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
fn int_edge_pairs(
  edges : ArrayView[@graphlib.Edge[Int, Int]],
) -> Array[(Int, Int)] {
  edges.map(edge => (edge.src, edge.dst))
}

///|
test "translated BAP shortest path returns weighted edge path" {
  let graph : @graphlib.Graph[Int, Int] = @graphlib.Graph::new()
    .add_edge(src=0, dst=1, label=5)
    .add_edge(src=0, dst=2, label=1)
    .add_edge(src=2, dst=1, label=1)
    .add_edge(src=1, dst=3, label=1)
    .add_edge(src=2, dst=3, label=10)
  match graph.shortest_path(0, 3, weight=edge => edge.label) {
    Some(path) => {
      assert_true(path.weight() == 3)
      assert_true(path.length() == 3)
      assert_true(int_edge_pairs(path.edges()) == [(0, 2), (2, 1), (1, 3)])
      assert_true(int_edge_pairs(path.edges_rev()) == [(1, 3), (2, 1), (0, 2)])
      assert_true((path.start().src, path.start().dst) == (0, 2))
      assert_true((path.finish().src, path.finish().dst) == (1, 3))
      assert_true(
        path.start_opt().map(edge => (edge.src, edge.dst)) == Some((0, 2)),
      )
      assert_true(
        path.finish_opt().map(edge => (edge.src, edge.dst)) == Some((1, 3)),
      )
      assert_true((path.start_exn().src, path.start_exn().dst) == (0, 2))
      assert_true((path.finish_exn().src, path.finish_exn().dst) == (1, 3))
      assert_true(
        path.to_string(edge_to_string=edge => "\{edge.src}->\{edge.dst}") ==
        "{ 0->2, 2->1, 1->3}",
      )
    }
    None => fail("expected a weighted shortest path")
  }
  match graph.shortest_path(3, 0, weight=edge => edge.label, rev=true) {
    Some(path) => {
      assert_true(path.weight() == 3)
      assert_true(int_edge_pairs(path.edges()) == [(1, 3), (2, 1), (0, 2)])
    }
    None => fail("expected a reverse-edge shortest path")
  }
  assert_true(graph.shortest_path(3, 0, weight=edge => edge.label) is None)
  match graph.shortest_path(99, 99) {
    Some(path) => {
      assert_true(path.weight() == 0)
      assert_true(path.length() == 0)
      assert_true(path.start_opt() is None)
      assert_true(path.finish_opt() is None)
      assert_true(
        path.to_string(edge_to_string=edge => "\{edge.src}->\{edge.dst}") ==
        "{}",
      )
    }
    None => fail("expected a zero-length path from a node to itself")
  }
}

///|
fn dfs_tree_parents(
  graph : @graphlib.Graph[Int, String],
  start : Int,
) -> Map[Int, Int] {
  let parents : Map[Int, Int] = {}
  for event in graph.dfs_edges(start) {
    match event.0 {
      Tree => parents[event.1.dst] = event.1.src
      _ => ()
    }
  }
  parents
}

///|
fn dfs_tree_ancestors(parents : Map[Int, Int], node : Int) -> Set[Int] {
  let ancestors : Set[Int] = Set([])
  let mut current = node
  let mut done = false
  while !done {
    match parents.get(current) {
      Some(parent) => {
        ancestors.add(parent)
        current = parent
      }
      None => done = true
    }
  }
  ancestors
}

///|
fn dfs_intervals_are_disjoint_or_nested(
  lhs : @graphlib.DfsNodeInfo,
  rhs : @graphlib.DfsNodeInfo,
) -> Bool {
  (lhs.enter == rhs.enter && lhs.leave == rhs.leave) ||
  lhs.leave < rhs.enter ||
  rhs.leave < lhs.enter ||
  (lhs.enter < rhs.enter && rhs.leave < lhs.leave) ||
  (rhs.enter < lhs.enter && lhs.leave < rhs.leave)
}

///|
test "translated BAP DFS timestamp intervals and ancestor lemma hold" {
  let graph = sample_graph()
  let numbering = graph.dfs_numbering(0)
  let parents = dfs_tree_parents(graph, 0)
  let nodes = graph.reachable(0).to_array()
  for lhs in nodes {
    for rhs in nodes {
      assert_true(
        dfs_intervals_are_disjoint_or_nested(numbering[lhs], numbering[rhs]),
      )
      if lhs != rhs {
        let ordered = numbering[lhs].pre < numbering[rhs].pre &&
          numbering[lhs].rpost < numbering[rhs].rpost
        assert_true(ordered == dfs_tree_ancestors(parents, rhs).contains(lhs))
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
  let post_doms = graph.dominators(4, rev=true)
  assert_true(post_doms[4] == Set::from_array([4]))
  assert_true(post_doms[2] == Set::from_array([2, 4]))
  assert_true(post_doms[3] == Set::from_array([3, 4]))
  assert_true(post_doms[1] == Set::from_array([1, 4]))
  assert_true(post_doms[0] == Set::from_array([0, 1, 4]))
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
  let tree = graph.dominator_tree(0)
  assert_true(tree.parent(0) is None)
  assert_true(tree.parent(1) == Some(0))
  assert_true(tree.parent(2) == Some(1))
  assert_true(tree.parent(3) == Some(1))
  assert_true(tree.parent(4) == Some(1))
  assert_true(Set::from_array(tree.children(1)) == Set::from_array([2, 3, 4]))
  assert_true(Set::from_array(tree.ancestors(4)) == Set::from_array([0, 1]))
  assert_true(
    Set::from_array(tree.descendants(1)) == Set::from_array([2, 3, 4]),
  )
  assert_true(tree.is_child_of(2, parent=1))
  assert_true(tree.is_ancestor_of(0, child=4))
  assert_true(tree.is_descendant_of(4, parent=1))
  assert_true(tree.to_sequence() == graph.nodes())
  let tree_text = tree.to_string(node_to_string=node => node.to_string())
  assert_true(tree_text.contains("digraph {"))
  assert_true(tree_text.contains("\"0\" -> \"1\""))
  assert_true(tree_text.contains("\"1\" -> \"2\""))
  let frontier = graph.dom_frontier(0)
  assert_true(frontier.to_sequence() == [1, 2, 3, 4])
  assert_true(frontier.mem(1, 1))
  assert_true(frontier.elements(2) == [4])
  assert_true(frontier.enumerate(2) == [4])
  assert_true(frontier.elements(0).is_empty())
  let frontier_text = frontier.to_string(node_to_string=node => node.to_string())
  assert_true(frontier_text.contains("[1 => (1)]"))
  assert_true(frontier_text.contains("[2 => (4)]"))
  let post_idoms = graph.immediate_dominators(4, rev=true)
  assert_true(post_idoms[0] == 1)
  assert_true(post_idoms[1] == 4)
  assert_true(post_idoms[2] == 4)
  assert_true(post_idoms[3] == 4)
  let post_frontiers = graph.dominance_frontiers(4, rev=true)
  assert_true(post_frontiers[0].is_empty())
  assert_true(post_frontiers[1].is_empty())
  assert_true(post_frontiers[2] == Set::from_array([1]))
  assert_true(post_frontiers[3] == Set::from_array([1]))
  assert_true(post_frontiers[4].is_empty())
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
  let post_idoms = graph.immediate_dominators(3, rev=true)
  assert_true(post_idoms[0] == 3)
  assert_true(post_idoms[1] == 3)
  assert_true(post_idoms[2] == 3)
  let post_frontiers = graph.dominance_frontiers(3, rev=true)
  assert_true(post_frontiers[0].is_empty())
  assert_true(post_frontiers[1] == Set::from_array([0]))
  assert_true(post_frontiers[2] == Set::from_array([0]))
  assert_true(post_frontiers[3].is_empty())
}

///|
fn int_set_transfer(node : Int, facts : Set[Int]) -> Set[Int] {
  let out = facts.copy()
  out.add(node)
  out
}

///|
fn int_set_union(left : Set[Int], right : Set[Int]) -> Set[Int] {
  left.union(right)
}

///|
fn int_set_equal(left : Set[Int], right : Set[Int]) -> Bool {
  left == right
}

///|
test "graph fixpoint solves forward and reverse dataflow facts" {
  let graph : @graphlib.Graph[Int, String] = @graphlib.Graph::new()
    .add_edge(src=0, dst=1, label="then")
    .add_edge(src=0, dst=2, label="else")
    .add_edge(src=1, dst=3, label="join")
    .add_edge(src=2, dst=3, label="join")
  let init = @graphlib.Fixpoint::create(
    { 0: Set::from_array([0]) },
    Set::from_array([]),
  )
  assert_true(!init.is_fixpoint())
  assert_true(init.iterations() == 0)
  assert_true(init.default().is_empty())
  assert_true(init.get(99).is_empty())
  let solved = graph.fixpoint(
    init~,
    equal=int_set_equal,
    merge=int_set_union,
    f=int_set_transfer,
  )
  assert_true(solved.is_fixpoint())
  assert_true(solved.iterations() > 0)
  assert_true(solved.get(0) == Set::from_array([0]))
  assert_true(solved.get(1) == Set::from_array([0]))
  assert_true(solved.get(2) == Set::from_array([0]))
  assert_true(solved.get(3) == Set::from_array([0, 1, 2]))
  assert_true(solved.entries().length() == 4)
  assert_true(solved.enumerate().length() == solved.entries().length())
  assert_true(solved.equal(solved, equal=int_set_equal))
  let derived = solved.derive_values(
    (_node, facts) => if facts.is_empty() { None } else { Some(facts.length()) },
    0,
  )
  assert_true(!derived.is_fixpoint())
  assert_true(derived.get(3) == 3)

  let partial = graph.fixpoint(
    init~,
    equal=int_set_equal,
    merge=int_set_union,
    f=int_set_transfer,
    steps=Some(1),
  )
  assert_true(!partial.is_fixpoint())
  assert_true(partial.iterations() == 1)
  let resumed = graph.fixpoint(
    init=partial,
    equal=int_set_equal,
    merge=int_set_union,
    f=int_set_transfer,
    steps=Some(20),
  )
  assert_true(resumed.is_fixpoint())
  assert_true(resumed.iterations() > partial.iterations())
  assert_true(resumed.get(3) == solved.get(3))

  let reverse_init = @graphlib.Fixpoint::create(
    { 3: Set::from_array([3]) },
    Set::from_array([]),
  )
  let reverse = graph.fixpoint(
    init=reverse_init,
    equal=int_set_equal,
    merge=int_set_union,
    f=int_set_transfer,
    start=Some(3),
    rev=true,
  )
  assert_true(reverse.is_fixpoint())
  assert_true(reverse.get(3) == Set::from_array([3]))
  assert_true(reverse.get(1) == Set::from_array([3]))
  assert_true(reverse.get(2) == Set::from_array([3]))
  assert_true(reverse.get(0) == Set::from_array([1, 2, 3]))
}
