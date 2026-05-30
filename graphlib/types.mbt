///|
pub(all) enum EdgeKind {
  Tree
  Back
  Cross
  Forward
} derive(Eq, Debug)

///|
pub(all) struct Edge[N, E] {
  src : N
  dst : N
  label : E
} derive(Eq, Debug)

///|
pub fn[N, E] Edge::new(src~ : N, dst~ : N, label~ : E) -> Edge[N, E] {
  { src, dst, label }
}

///|
struct Graph[N, E] {
  nodes : Array[N]
  edges : Array[Edge[N, E]]
} derive(Debug)

///|
pub fn[N, E] Graph::new() -> Graph[N, E] {
  { nodes: [], edges: [] }
}

///|
pub fn[N, E] Graph::node_count(self : Graph[N, E]) -> Int {
  self.nodes.length()
}

///|
pub fn[N, E] Graph::edge_count(self : Graph[N, E]) -> Int {
  self.edges.length()
}

///|
pub fn[N, E] Graph::nodes(self : Graph[N, E]) -> Array[N] {
  self.nodes.copy()
}

///|
pub fn[N, E] Graph::edges(self : Graph[N, E]) -> Array[Edge[N, E]] {
  self.edges.copy()
}

///|
pub fn[N, E] Graph::is_empty(self : Graph[N, E]) -> Bool {
  self.nodes.is_empty() && self.edges.is_empty()
}
