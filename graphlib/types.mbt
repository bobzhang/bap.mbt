///|
pub(all) enum EdgeKind {
  Tree
  Back
  Cross
  Forward
} derive(Eq, Debug)

///|
pub extend EdgeKind with Eq::{not_equal, equal}

///|
pub extend EdgeKind with Debug::{to_repr}

///|
pub(all) struct DfsNodeInfo {
  enter : Int
  leave : Int
  pre : Int
  rpost : Int
} derive(Eq, Debug)

///|
pub extend DfsNodeInfo with Eq::{not_equal, equal}

///|
pub extend DfsNodeInfo with Debug::{to_repr}

///|
pub(all) struct Edge[N, E] {
  src : N
  dst : N
  label : E
} derive(Eq, Debug)

///|
pub extend Edge with Eq::{not_equal, equal}

///|
pub extend Edge with Debug::{to_repr}

///|
pub fn[N, E] Edge::new(src~ : N, dst~ : N, label~ : E) -> Edge[N, E] {
  { src, dst, label, }
}

///|
pub fn[N, E] Edge::create(src : N, dst : N, label : E) -> Edge[N, E] {
  Edge::new(src~, dst~, label~)
}

///|
pub fn[N, E] Edge::src(self : Edge[N, E]) -> N {
  self.src
}

///|
pub fn[N, E] Edge::dst(self : Edge[N, E]) -> N {
  self.dst
}

///|
pub fn[N, E] Edge::label(self : Edge[N, E]) -> E {
  self.label
}

///|
struct GraphPath[E] {
  edges_value : Array[E]
  weight_value : Int
} derive(Eq, Debug)

///|
pub extend GraphPath with Eq::{not_equal, equal}

///|
pub extend GraphPath with Debug::{to_repr}

///|
pub fn[E] GraphPath::new(edges : ArrayView[E], weight~ : Int) -> GraphPath[E] {
  { edges_value: edges.to_owned(), weight_value: weight, }
}

///|
pub fn[E] GraphPath::length(self : GraphPath[E]) -> Int {
  self.edges_value.length()
}

///|
pub fn[E] GraphPath::weight(self : GraphPath[E]) -> Int {
  self.weight_value
}

///|
pub fn[E] GraphPath::edges(self : GraphPath[E]) -> Array[E] {
  self.edges_value.copy()
}

///|
pub fn[E] GraphPath::edges_rev(self : GraphPath[E]) -> Array[E] {
  self.edges_value.rev()
}

///|
pub fn[E] GraphPath::start_opt(self : GraphPath[E]) -> E? {
  if self.edges_value.is_empty() {
    None
  } else {
    Some(self.edges_value[0])
  }
}

///|
pub fn[E] GraphPath::finish_opt(self : GraphPath[E]) -> E? {
  let length = self.edges_value.length()
  if length == 0 {
    None
  } else {
    Some(self.edges_value[length - 1])
  }
}

///|
pub fn[E] GraphPath::start(self : GraphPath[E]) -> E {
  match self.start_opt() {
    Some(edge) => edge
    None => abort("empty graph path")
  }
}

///|
pub fn[E] GraphPath::finish(self : GraphPath[E]) -> E {
  match self.finish_opt() {
    Some(edge) => edge
    None => abort("empty graph path")
  }
}

///|
pub fn[E] GraphPath::start_exn(self : GraphPath[E]) -> E {
  self.start()
}

///|
pub fn[E] GraphPath::finish_exn(self : GraphPath[E]) -> E {
  self.finish()
}

///|
struct Graph[N, E] {
  nodes : Array[N]
  edges : Array[Edge[N, E]]
} derive(Debug)

///|
pub extend Graph with Debug::{to_repr}

///|
pub fn[N, E] Graph::new() -> Graph[N, E] {
  { nodes: [], edges: [], }
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
