///|
struct ProjectDisassemblyCfgEdge {
  src_value : ProjectDisassemblyBlock
  dst_value : ProjectDisassemblyBlock
  kind_value : ProjectDisassemblyEdgeKind
}

///|
struct ProjectDisassemblyCfg {
  nodes_value : Array[ProjectDisassemblyBlock]
  edges_value : Array[ProjectDisassemblyCfgEdge]
}

///|
fn project_disassembly_cfg_same_node(
  left : ProjectDisassemblyBlock,
  right : ProjectDisassemblyBlock,
) -> Bool {
  left.same(right)
}

///|
fn project_disassembly_cfg_same_edge(
  left : ProjectDisassemblyCfgEdge,
  right : ProjectDisassemblyCfgEdge,
) -> Bool {
  left.src().same(right.src()) &&
  left.dst().same(right.dst()) &&
  left.kind() == right.kind()
}

///|
/// Blocks are identified by their address and size (`ProjectDisassemblyBlock::same`).
fn project_disassembly_cfg_node_key(
  node : ProjectDisassemblyBlock,
) -> (UInt64, Int) {
  (node.addr(), node.memory_value.length())
}

///|
/// The rank of an edge kind in the order of its textual name.
fn project_disassembly_cfg_kind_rank(kind : ProjectDisassemblyEdgeKind) -> Int {
  match kind {
    CondEdge => 0
    FallEdge => 1
    JumpEdge => 2
  }
}

///|
/// Removes duplicate nodes (keeping the first occurrence) and sorts them.
fn project_disassembly_cfg_sort_nodes(
  nodes : Array[ProjectDisassemblyBlock],
) -> Array[ProjectDisassemblyBlock] {
  let seen : Map[(UInt64, Int), Unit] = Map([])
  let result : Array[ProjectDisassemblyBlock] = []
  for node in nodes {
    let key = project_disassembly_cfg_node_key(node)
    if !seen.contains(key) {
      seen[key] = ()
      result.push(node)
    }
  }
  result.sort_by((left, right) => left.compare(right))
  result
}

///|
fn project_disassembly_cfg_compare_edges(
  left : ProjectDisassemblyCfgEdge,
  right : ProjectDisassemblyCfgEdge,
) -> Int {
  let src_order = left.src().compare(right.src())
  if src_order != 0 {
    src_order
  } else {
    let dst_order = left.dst().compare(right.dst())
    if dst_order != 0 {
      dst_order
    } else {
      project_disassembly_cfg_kind_rank(left.kind()).compare(
        project_disassembly_cfg_kind_rank(right.kind()),
      )
    }
  }
}

///|
/// Removes duplicate edges (keeping the first occurrence) and sorts them.
fn project_disassembly_cfg_sort_edges(
  edges : Array[ProjectDisassemblyCfgEdge],
) -> Array[ProjectDisassemblyCfgEdge] {
  let seen : Map[(UInt64, Int, UInt64, Int, Int), Unit] = Map([])
  let result : Array[ProjectDisassemblyCfgEdge] = []
  for edge in edges {
    let (src_addr, src_size) = project_disassembly_cfg_node_key(edge.src())
    let (dst_addr, dst_size) = project_disassembly_cfg_node_key(edge.dst())
    let key = (
      src_addr,
      src_size,
      dst_addr,
      dst_size,
      project_disassembly_cfg_kind_rank(edge.kind()),
    )
    if !seen.contains(key) {
      seen[key] = ()
      result.push(edge)
    }
  }
  result.sort_by(project_disassembly_cfg_compare_edges)
  result
}

///|
/// Inserts `item` into the sorted, duplicate-free array `items` unless an
/// element comparing equal is already present.
fn[T] project_disassembly_cfg_sorted_insert(
  items : Array[T],
  item : T,
  compare : (T, T) -> Int,
) -> Array[T]? {
  let mut lo = 0
  let mut hi = items.length()
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    let order = compare(items[mid], item)
    if order == 0 {
      return None
    } else if order < 0 {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  let result = Array(capacity=items.length() + 1)
  for i in 0..<lo {
    result.push(items[i])
  }
  result.push(item)
  for i in lo..<items.length() {
    result.push(items[i])
  }
  Some(result)
}

///|
fn project_disassembly_cfg_find_block_containing(
  blocks : Array[ProjectDisassemblyBlock],
  addr : UInt64,
) -> ProjectDisassemblyBlock? {
  for block in blocks {
    if block.memory().contains(addr) {
      return Some(block)
    }
  }
  None
}

///|
fn project_disassembly_cfg_edge_to_state_edge(
  edge : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyEdge {
  ProjectDisassemblyEdge::create(
    source=edge.src().addr(),
    target=edge.dst().addr(),
    kind=edge.kind(),
  )
}

///|
pub fn ProjectDisassemblyCfgEdge::create(
  src~ : ProjectDisassemblyBlock,
  dst~ : ProjectDisassemblyBlock,
  kind? : ProjectDisassemblyEdgeKind = JumpEdge,
) -> ProjectDisassemblyCfgEdge {
  { src_value: src, dst_value: dst, kind_value: kind, }
}

///|
pub fn ProjectDisassemblyCfgEdge::src(
  self : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyBlock {
  self.src_value
}

///|
pub fn ProjectDisassemblyCfgEdge::dst(
  self : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyBlock {
  self.dst_value
}

///|
pub fn ProjectDisassemblyCfgEdge::kind(
  self : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyEdgeKind {
  self.kind_value
}

///|
pub fn ProjectDisassemblyCfgEdge::same(
  self : ProjectDisassemblyCfgEdge,
  other : ProjectDisassemblyCfgEdge,
) -> Bool {
  project_disassembly_cfg_same_edge(self, other)
}

///|
pub fn ProjectDisassemblyCfg::empty() -> ProjectDisassemblyCfg {
  { nodes_value: [], edges_value: [], }
}

///|
pub fn ProjectDisassemblyCfg::create(
  nodes? : Array[ProjectDisassemblyBlock],
  edges? : Array[ProjectDisassemblyCfgEdge],
) -> ProjectDisassemblyCfg {
  let clean_nodes = match nodes {
    Some(items) => project_disassembly_cfg_sort_nodes(items)
    None => []
  }
  let clean_edges = match edges {
    Some(items) => project_disassembly_cfg_sort_edges(items)
    None => []
  }
  let mut cfg = { nodes_value: clean_nodes, edges_value: [], }
  for edge in clean_edges {
    cfg = cfg.insert_edge(edge)
  }
  cfg
}

///|
pub fn ProjectDisassemblyCfg::of_disassembly(
  disassembly : ProjectDisassemblyState,
) -> ProjectDisassemblyCfg {
  let blocks = disassembly.blocks_with_instructions()
  let nodes = project_disassembly_cfg_sort_nodes(blocks)
  let edges = []
  for edge in disassembly.edges() {
    match edge.target() {
      Some(target) => {
        let src = match
          project_disassembly_cfg_find_block_containing(blocks, edge.source()) {
          Some(block) => block
          None => continue
        }
        let dst = match
          project_disassembly_cfg_find_block_containing(blocks, target) {
          Some(block) => block
          None => continue
        }
        edges.push(
          ProjectDisassemblyCfgEdge::create(src~, dst~, kind=edge.kind()),
        )
      }
      None => ()
    }
  }
  // The endpoints are blocks of `blocks`, hence already nodes.
  {
    nodes_value: nodes,
    edges_value: project_disassembly_cfg_sort_edges(edges),
  }
}

///|
pub fn ProjectDisassemblyCfg::nodes(
  self : ProjectDisassemblyCfg,
) -> Array[ProjectDisassemblyBlock] {
  self.nodes_value.copy()
}

///|
pub fn ProjectDisassemblyCfg::edges(
  self : ProjectDisassemblyCfg,
) -> Array[ProjectDisassemblyCfgEdge] {
  self.edges_value.copy()
}

///|
pub fn ProjectDisassemblyCfg::node_count(self : ProjectDisassemblyCfg) -> Int {
  self.nodes_value.length()
}

///|
pub fn ProjectDisassemblyCfg::edge_count(self : ProjectDisassemblyCfg) -> Int {
  self.edges_value.length()
}

///|
pub fn ProjectDisassemblyCfg::is_empty(self : ProjectDisassemblyCfg) -> Bool {
  self.nodes_value.is_empty()
}

///|
pub fn ProjectDisassemblyCfg::has_node(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Bool {
  self.nodes_value.any(existing => {
    project_disassembly_cfg_same_node(existing, node)
  })
}

///|
pub fn ProjectDisassemblyCfg::insert_node(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> ProjectDisassemblyCfg {
  match
    project_disassembly_cfg_sorted_insert(self.nodes_value, node, (l, r) => {
      l.compare(r)
    }) {
    None => self
    Some(nodes) => { ..self, nodes_value: nodes, }
  }
}

///|
pub fn ProjectDisassemblyCfg::has_edge(
  self : ProjectDisassemblyCfg,
  src : ProjectDisassemblyBlock,
  dst : ProjectDisassemblyBlock,
) -> Bool {
  self.edges_value.any(edge => edge.src().same(src) && edge.dst().same(dst))
}

///|
pub fn ProjectDisassemblyCfg::edge(
  self : ProjectDisassemblyCfg,
  src : ProjectDisassemblyBlock,
  dst : ProjectDisassemblyBlock,
) -> ProjectDisassemblyCfgEdge? {
  for edge in self.edges_value {
    if edge.src().same(src) && edge.dst().same(dst) {
      return Some(edge)
    }
  }
  None
}

///|
pub fn ProjectDisassemblyCfg::insert_edge(
  self : ProjectDisassemblyCfg,
  edge : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyCfg {
  let with_src = self.insert_node(edge.src())
  let with_dst = with_src.insert_node(edge.dst())
  match
    project_disassembly_cfg_sorted_insert(
      with_dst.edges_value,
      edge,
      project_disassembly_cfg_compare_edges,
    ) {
    None => with_dst
    Some(edges) => { ..with_dst, edges_value: edges, }
  }
}

///|
pub fn ProjectDisassemblyCfg::remove_edge(
  self : ProjectDisassemblyCfg,
  edge : ProjectDisassemblyCfgEdge,
) -> ProjectDisassemblyCfg {
  {
    ..self,
    edges_value: self.edges_value.filter(existing => !existing.same(edge)),
  }
}

///|
pub fn ProjectDisassemblyCfg::remove_node(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> ProjectDisassemblyCfg {
  {
    nodes_value: self.nodes_value.filter(existing => !existing.same(node)),
    edges_value: self.edges_value.filter(edge => {
      !edge.src().same(node) && !edge.dst().same(node)
    }),
  }
}

///|
pub fn ProjectDisassemblyCfg::successors(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  self.edges_value.filter_map(edge => {
    if edge.src().same(node) {
      Some(edge.dst())
    } else {
      None
    }
  })
}

///|
pub fn ProjectDisassemblyCfg::succs(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  self.successors(node)
}

///|
pub fn ProjectDisassemblyCfg::predecessors(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  self.edges_value.filter_map(edge => {
    if edge.dst().same(node) {
      Some(edge.src())
    } else {
      None
    }
  })
}

///|
pub fn ProjectDisassemblyCfg::preds(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  self.predecessors(node)
}

///|
pub fn ProjectDisassemblyCfg::out_edges(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyCfgEdge] {
  self.edges_value.filter(edge => edge.src().same(node))
}

///|
pub fn ProjectDisassemblyCfg::outputs(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyCfgEdge] {
  self.out_edges(node)
}

///|
pub fn ProjectDisassemblyCfg::in_edges(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyCfgEdge] {
  self.edges_value.filter(edge => edge.dst().same(node))
}

///|
pub fn ProjectDisassemblyCfg::inputs(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyCfgEdge] {
  self.in_edges(node)
}

///|
pub fn ProjectDisassemblyCfg::out_degree(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Int {
  self.out_edges(node).length()
}

///|
pub fn ProjectDisassemblyCfg::in_degree(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Int {
  self.in_edges(node).length()
}

///|
pub fn ProjectDisassemblyCfg::degree(
  self : ProjectDisassemblyCfg,
  node : ProjectDisassemblyBlock,
) -> Int {
  self.in_degree(node) + self.out_degree(node)
}

///|
pub fn ProjectDisassemblyCfg::to_disassembly_edges(
  self : ProjectDisassemblyCfg,
) -> Array[ProjectDisassemblyEdge] {
  self.edges_value.map(project_disassembly_cfg_edge_to_state_edge)
}

///|
pub fn ProjectDisassemblyState::cfg(
  self : ProjectDisassemblyState,
) -> ProjectDisassemblyCfg {
  ProjectDisassemblyCfg::of_disassembly(self)
}

///|
pub fn Project::disassembly_cfg(self : Project) -> ProjectDisassemblyCfg {
  self.disassembly().cfg()
}
