///|
/// A mutable graph under construction: `add_node` and `add_edge` have the
/// effect of `Graph::add_node` and `Graph::add_edge` on the graph built so
/// far, in constant (amortized) time instead of the time linear in the size
/// of the graph of the persistent operations.
struct GraphBuilder[N, E] {
  nodes : Array[N]
  node_set : Map[N, Unit]
  edges : Array[Edge[N, E]]
  edge_index : Map[(N, N), Int32]
}

///|
/// A builder of an empty graph.
pub fn[N : Hash + Eq, E] GraphBuilder::new() -> GraphBuilder[N, E] {
  { nodes: [], node_set: Map([]), edges: [], edge_index: Map([]), }
}

///|
/// Adds `node` to the graph, unless it is already a node of it.
pub fn[N : Hash + Eq, E] GraphBuilder::add_node(
  self : GraphBuilder[N, E],
  node : N,
) -> Unit {
  if !self.node_set.contains(node) {
    self.node_set[node] = ()
    self.nodes.push(node)
  }
}

///|
/// Adds the edge from `src` to `dst` (and its nodes) to the graph, replacing
/// the label of an existing edge between them.
pub fn[N : Hash + Eq, E] GraphBuilder::add_edge(
  self : GraphBuilder[N, E],
  src~ : N,
  dst~ : N,
  label~ : E,
) -> Unit {
  self.add_node(src)
  self.add_node(dst)
  let edge = Edge::new(src~, dst~, label~)
  match self.edge_index.get((src, dst)) {
    Some(i) => self.edges[i] = edge
    None => {
      self.edge_index[(src, dst)] = self.edges.length()
      self.edges.push(edge)
    }
  }
}

///|
/// The graph built so far.
pub fn[N, E] GraphBuilder::to_graph(self : GraphBuilder[N, E]) -> Graph[N, E] {
  { nodes: self.nodes.copy(), edges: self.edges.copy(), }
}
