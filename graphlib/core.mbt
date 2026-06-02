///|
fn[N : Eq] contains_node(nodes : ArrayView[N], node : N) -> Bool {
  nodes.any(n => n == node)
}

///|
fn[N : Eq, E] edge_index(
  edges : ArrayView[Edge[N, E]],
  src : N,
  dst : N,
) -> Int? {
  edges.search_by(edge => edge.src == src && edge.dst == dst)
}

///|
pub fn[N : Eq, E] Graph::has_node(self : Graph[N, E], node : N) -> Bool {
  contains_node(self.nodes, node)
}

///|
pub fn[N : Eq, E] Graph::has_edge(self : Graph[N, E], src : N, dst : N) -> Bool {
  edge_index(self.edges, src, dst) is Some(_)
}

///|
pub fn[N : Eq, E] Graph::edge(
  self : Graph[N, E],
  src : N,
  dst : N,
) -> Edge[N, E]? {
  match edge_index(self.edges, src, dst) {
    Some(i) => Some(self.edges[i])
    None => None
  }
}

///|
pub fn[N : Eq, E] Graph::create(
  nodes? : ArrayView[N] = [],
  edges? : ArrayView[(N, N, E)] = [],
) -> Graph[N, E] {
  let mut graph : Graph[N, E] = Graph::new()
  for edge in edges {
    graph = graph.add_edge(src=edge.0, dst=edge.1, label=edge.2)
  }
  for node in nodes {
    graph = graph.add_node(node)
  }
  graph
}

///|
pub fn[N : Eq, E] Graph::add_node(self : Graph[N, E], node : N) -> Graph[N, E] {
  if self.has_node(node) {
    self
  } else {
    let nodes = self.nodes.copy()
    nodes.push(node)
    { nodes, edges: self.edges.copy() }
  }
}

///|
pub fn[N : Eq, E] Graph::add_edge(
  self : Graph[N, E],
  src~ : N,
  dst~ : N,
  label~ : E,
) -> Graph[N, E] {
  let with_src = self.add_node(src)
  let with_nodes = with_src.add_node(dst)
  let edges = with_nodes.edges.copy()
  match edge_index(edges, src, dst) {
    Some(i) => edges[i] = Edge::new(src~, dst~, label~)
    None => edges.push(Edge::new(src~, dst~, label~))
  }
  { nodes: with_nodes.nodes.copy(), edges }
}

///|
pub fn[N : Eq, E] Graph::remove_edge(
  self : Graph[N, E],
  src : N,
  dst : N,
) -> Graph[N, E] {
  let edges = self.edges.filter(edge => !(edge.src == src && edge.dst == dst))
  { nodes: self.nodes.copy(), edges }
}

///|
pub fn[N : Eq, E] Graph::remove_node(
  self : Graph[N, E],
  node : N,
) -> Graph[N, E] {
  {
    nodes: self.nodes.filter(n => n != node),
    edges: self.edges.filter(edge => edge.src != node && edge.dst != node),
  }
}

///|
pub fn[N : Eq, E] Graph::replace_node(
  self : Graph[N, E],
  old : N,
  replacement : N,
) -> Graph[N, E] {
  if old == replacement || !self.has_node(old) {
    self
  } else {
    let nodes = []
    for node in self.nodes {
      if node == old {
        if !contains_node(nodes, replacement) {
          nodes.push(replacement)
        }
      } else if !contains_node(nodes, node) {
        nodes.push(node)
      }
    }
    let mut out = { nodes, edges: [] }
    for edge in self.edges {
      let src = if edge.src == old { replacement } else { edge.src }
      let dst = if edge.dst == old { replacement } else { edge.dst }
      out = out.add_edge(src~, dst~, label=edge.label)
    }
    out
  }
}

///|
fn[N : Eq, E] contains_edge_pair(
  edges : ArrayView[Edge[N, E]],
  src : N,
  dst : N,
) -> Bool {
  edges.any(item => item.src == src && item.dst == dst)
}

///|
pub fn[N : Eq, E] Graph::union(
  self : Graph[N, E],
  other : Graph[N, E],
) -> Graph[N, E] {
  let mut out = self
  for node in other.nodes {
    out = out.add_node(node)
  }
  for edge in other.edges {
    if !contains_edge_pair(out.edges, edge.src, edge.dst) {
      out = out.add_edge(src=edge.src, dst=edge.dst, label=edge.label)
    }
  }
  out
}

///|
pub fn[N : Eq, E] Graph::intersect(
  self : Graph[N, E],
  other : Graph[N, E],
) -> Graph[N, E] {
  let nodes = self.nodes.filter(node => other.has_node(node))
  let edges = self.edges.filter(edge => other.has_edge(edge.src, edge.dst))
  { nodes, edges }
}

///|
pub fn[N : Eq, E] Graph::successors(self : Graph[N, E], node : N) -> Array[N] {
  self.edges.filter_map(edge => {
    if edge.src == node {
      Some(edge.dst)
    } else {
      None
    }
  })
}

///|
pub fn[N : Eq, E] Graph::predecessors(self : Graph[N, E], node : N) -> Array[N] {
  self.edges.filter_map(edge => {
    if edge.dst == node {
      Some(edge.src)
    } else {
      None
    }
  })
}

///|
pub fn[N : Eq, E] Graph::out_edges(
  self : Graph[N, E],
  node : N,
) -> Array[Edge[N, E]] {
  self.edges.filter(edge => edge.src == node)
}

///|
pub fn[N : Eq, E] Graph::in_edges(
  self : Graph[N, E],
  node : N,
) -> Array[Edge[N, E]] {
  self.edges.filter(edge => edge.dst == node)
}

///|
pub fn[N : Eq, E] Graph::degree(self : Graph[N, E], node : N) -> Int {
  self.in_edges(node).length() + self.out_edges(node).length()
}
