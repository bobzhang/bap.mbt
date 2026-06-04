///|
let tid_graph_start_node : Tid = Tid::for_name("start-pseudo-node")

///|
let tid_graph_exit_node : Tid = Tid::for_name("exit-pseudo-node")

///|
pub fn tid_graph_start() -> Tid {
  tid_graph_start_node
}

///|
pub fn tid_graph_exit() -> Tid {
  tid_graph_exit_node
}

///|
fn tid_graph_connect_with_start(
  graph : @graphlib.Graph[Tid, Tid],
  node : Tid,
) -> @graphlib.Graph[Tid, Tid] {
  if node == tid_graph_start_node {
    graph
  } else {
    graph.add_edge(
      src=tid_graph_start_node,
      dst=node,
      label=tid_graph_start_node,
    )
  }
}

///|
fn tid_graph_connect_with_exit(
  graph : @graphlib.Graph[Tid, Tid],
  node : Tid,
) -> @graphlib.Graph[Tid, Tid] {
  if node == tid_graph_exit_node {
    graph
  } else {
    graph.add_edge(src=node, dst=tid_graph_exit_node, label=tid_graph_exit_node)
  }
}

///|
pub fn Term::sub_tid_graph(self : Term[Sub]) -> @graphlib.Graph[Tid, Tid] {
  let block_tids = self.blks().map(block => block.tid())
  let mut graph = self
    .sub_cfg()
    .add_node(tid_graph_start_node)
    .add_node(tid_graph_exit_node)
  for tid in block_tids {
    if graph.in_edges(tid).length() == 0 {
      graph = tid_graph_connect_with_start(graph, tid)
    }
    if graph.out_edges(tid).length() == 0 {
      graph = tid_graph_connect_with_exit(graph, tid)
    }
  }
  for tid in block_tids {
    if !graph.reachable(tid_graph_start_node).contains(tid) {
      graph = tid_graph_connect_with_start(graph, tid)
    }
  }
  for tid in block_tids {
    if !graph.reachable(tid).contains(tid_graph_exit_node) {
      graph = tid_graph_connect_with_exit(graph, tid)
    }
  }
  graph
}

///|
pub fn Term::to_graph(self : Term[Sub]) -> @graphlib.Graph[Tid, Tid] {
  self.sub_tid_graph()
}

///|
pub fn Sub::to_graph(sub : Term[Sub]) -> @graphlib.Graph[Tid, Tid] {
  sub.sub_tid_graph()
}
