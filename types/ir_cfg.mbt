///|
struct IrCfg {
  sub_value : Term[Sub]
}

///|
pub fn IrCfg::create(tid? : Tid, name? : String) -> IrCfg {
  IrCfg::of_sub(Sub::create(name?, tid?))
}

///|
pub fn IrCfg::of_sub(sub : Term[Sub]) -> IrCfg {
  { sub_value: sub }
}

///|
pub fn Term::to_ir_cfg(self : Term[Sub]) -> IrCfg {
  IrCfg::of_sub(self)
}

///|
pub fn IrCfg::to_sub(self : IrCfg) -> Term[Sub] {
  self.sub_value
}

///|
pub fn IrCfg::is_directed() -> Bool {
  true
}

///|
pub fn IrCfg::is_empty(self : IrCfg) -> Bool {
  self.sub_value.blks().is_empty()
}

///|
pub fn IrCfg::nodes(self : IrCfg) -> Array[Term[Blk]] {
  self.sub_value.blks()
}

///|
pub fn IrCfg::edges(self : IrCfg) -> Array[IrCfgEdge] {
  self.sub_value.sub_edges()
}

///|
pub fn IrCfg::node_count(self : IrCfg) -> Int {
  self.sub_value.blks().length()
}

///|
fn ir_cfg_contains_pair(
  pairs : ArrayView[(Tid, Tid)],
  pair : (Tid, Tid),
) -> Bool {
  pairs.any(item => item.0 == pair.0 && item.1 == pair.1)
}

///|
pub fn IrCfg::edge_count(self : IrCfg) -> Int {
  let pairs : Array[(Tid, Tid)] = []
  for edge in self.edges() {
    let pair = (edge.src().tid(), edge.dst().tid())
    if !ir_cfg_contains_pair(pairs, pair) {
      pairs.push(pair)
    }
  }
  pairs.length()
}

///|
pub fn IrCfg::has_node(self : IrCfg, blk : Term[Blk]) -> Bool {
  self.sub_value.find_blk(blk.tid()) is Some(_)
}

///|
pub fn IrCfg::has_edge(self : IrCfg, src : Term[Blk], dst : Term[Blk]) -> Bool {
  self.edge(src, dst) is Some(_)
}

///|
pub fn IrCfg::edge(
  self : IrCfg,
  src : Term[Blk],
  dst : Term[Blk],
) -> IrCfgEdge? {
  self.sub_value.sub_edge(src, dst)
}

///|
pub fn IrCfg::successors(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.sub_value.sub_successor_blocks(blk)
}

///|
pub fn IrCfg::predecessors(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.sub_value.sub_predecessor_blocks(blk)
}

///|
pub fn IrCfg::out_edges(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.sub_value.sub_out_edges(blk)
}

///|
pub fn IrCfg::in_edges(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.sub_value.sub_in_edges(blk)
}

///|
pub fn IrCfg::out_degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.out_edges(blk).length()
}

///|
pub fn IrCfg::in_degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.in_edges(blk).length()
}

///|
pub fn IrCfg::degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.in_degree(blk) + self.out_degree(blk)
}
