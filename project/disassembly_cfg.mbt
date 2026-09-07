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
fn project_disassembly_cfg_sort_nodes(
  nodes : Array[ProjectDisassemblyBlock],
) -> Array[ProjectDisassemblyBlock] {
  let result : Array[ProjectDisassemblyBlock] = []
  for node in nodes {
    if !result.any(existing => project_disassembly_cfg_same_node(existing, node)) {
      result.push(node)
    }
  }
  result.sort_by((left, right) => left.compare(right))
  result
}

///|
fn project_disassembly_cfg_sort_edges(
  edges : Array[ProjectDisassemblyCfgEdge],
) -> Array[ProjectDisassemblyCfgEdge] {
  let result : Array[ProjectDisassemblyCfgEdge] = []
  for edge in edges {
    if !result.any(existing => project_disassembly_cfg_same_edge(existing, edge)) {
      result.push(edge)
    }
  }
  result.sort_by((left, right) => {
    let src_order = left.src().compare(right.src())
    if src_order != 0 {
      src_order
    } else {
      let dst_order = left.dst().compare(right.dst())
      if dst_order != 0 {
        dst_order
      } else {
        left.kind().to_string().compare(right.kind().to_string())
      }
    }
  })
  result
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
  let mut cfg = ProjectDisassemblyCfg::create(nodes=blocks)
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
        cfg = cfg.insert_edge(
          ProjectDisassemblyCfgEdge::create(src~, dst~, kind=edge.kind()),
        )
      }
      None => ()
    }
  }
  cfg
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
  if self.has_node(node) {
    self
  } else {
    let nodes = self.nodes_value.copy()
    nodes.push(node)
    { ..self, nodes_value: project_disassembly_cfg_sort_nodes(nodes), }
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
  if with_dst.edges_value.any(existing => existing.same(edge)) {
    with_dst
  } else {
    let edges = with_dst.edges_value.copy()
    edges.push(edge)
    { ..with_dst, edges_value: project_disassembly_cfg_sort_edges(edges), }
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
