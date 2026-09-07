///|
struct IrCfgEdge {
  src_value : Term[Blk]
  dst_value : Term[Blk]
  pos_value : Int
}

///|
pub fn IrCfgEdge::src(self : IrCfgEdge) -> Term[Blk] {
  self.src_value
}

///|
pub fn IrCfgEdge::dst(self : IrCfgEdge) -> Term[Blk] {
  self.dst_value
}

///|
pub fn IrCfgEdge::position(self : IrCfgEdge) -> Int {
  self.pos_value
}

///|
pub fn IrCfgEdge::label(self : IrCfgEdge) -> Int {
  self.position()
}

///|
pub fn IrCfgEdge::mem(self : IrCfgEdge, cfg : IrCfg) -> Bool {
  cfg.has_edge(self.src(), self.dst())
}

///|
pub fn IrCfgEdge::jmp(self : IrCfgEdge) -> Term[Jmp] {
  self.src_value.payload_value.jmps[self.pos_value]
}

///|
pub fn IrCfgEdge::tid(self : IrCfgEdge) -> Tid {
  self.jmp().tid()
}

///|
fn ir_cfg_edge_current_src(sub : Term[Sub], edge : IrCfgEdge) -> Term[Blk]? {
  sub.find_blk(edge.src_value.tid())
}

///|
fn ir_cfg_edge_jmps_before_index(
  src : Term[Blk],
  index : Int,
) -> Array[Term[Jmp]] {
  let jmps = src.payload_value.jmps
  let stop = Int::max(0, Int::min(index, jmps.length()))
  jmps[0:stop].to_owned()
}

///|
fn ir_cfg_edge_jmps_after_index(
  src : Term[Blk],
  index : Int,
) -> Array[Term[Jmp]] {
  let jmps = src.payload_value.jmps
  let start = Int::max(0, Int::min(index + 1, jmps.length()))
  jmps[start:].to_owned()
}

///|
pub fn IrCfgEdge::jmps_before(
  self : IrCfgEdge,
  sub : Term[Sub],
) -> Array[Term[Jmp]] {
  match ir_cfg_edge_current_src(sub, self) {
    Some(src) => ir_cfg_edge_jmps_before_index(src, self.pos_value)
    None => []
  }
}

///|
pub fn IrCfgEdge::jmps_after(
  self : IrCfgEdge,
  sub : Term[Sub],
) -> Array[Term[Jmp]] {
  match ir_cfg_edge_current_src(sub, self) {
    Some(src) => ir_cfg_edge_jmps_after_index(src, self.pos_value)
    None => []
  }
}

///|
pub fn IrCfgEdge::cond(self : IrCfgEdge, sub : Term[Sub]) -> Exp {
  let mut cond = self.jmp().cond()
  for jmp in self.jmps_before(sub) {
    cond = BinOp(And, cond, UnOp(Not, jmp.cond()))
  }
  cond.simplify()
}

///|
fn ir_cfg_edge_of_jmp(
  sub : Term[Sub],
  src : Term[Blk],
  pos : Int,
  jmp : Term[Jmp],
) -> IrCfgEdge? {
  match jmp.succ_tid_of_jmp() {
    Some(tid) =>
      match sub.find_blk(tid) {
        Some(dst) => Some({ src_value: src, dst_value: dst, pos_value: pos, })
        None => None
      }
    None => None
  }
}

///|
fn ir_cfg_edge_edges_in_range(
  sub : Term[Sub],
  src : Term[Blk],
  start : Int,
  stop : Int,
) -> Array[IrCfgEdge] {
  let jmps = src.payload_value.jmps
  let lo = Int::max(0, Int::min(start, jmps.length()))
  let hi = Int::max(lo, Int::min(stop, jmps.length()))
  let edges = []
  for pos in lo..<hi {
    match ir_cfg_edge_of_jmp(sub, src, pos, jmps[pos]) {
      Some(edge) => edges.push(edge)
      None => ()
    }
  }
  edges
}

///|
pub fn IrCfgEdge::edges_before(
  self : IrCfgEdge,
  sub : Term[Sub],
) -> Array[IrCfgEdge] {
  match ir_cfg_edge_current_src(sub, self) {
    Some(src) => ir_cfg_edge_edges_in_range(sub, src, 0, self.pos_value)
    None => []
  }
}

///|
pub fn IrCfgEdge::edges_after(
  self : IrCfgEdge,
  sub : Term[Sub],
) -> Array[IrCfgEdge] {
  match ir_cfg_edge_current_src(sub, self) {
    Some(src) =>
      ir_cfg_edge_edges_in_range(
        sub,
        src,
        self.pos_value + 1,
        src.payload_value.jmps.length(),
      )
    None => []
  }
}

///|
pub fn Term::sub_out_edges(
  self : Term[Sub],
  blk : Term[Blk],
) -> Array[IrCfgEdge] {
  match self.find_blk(blk.tid()) {
    Some(src) => {
      let edges = []
      for pos, jmp in src.payload_value.jmps {
        match ir_cfg_edge_of_jmp(self, src, pos, jmp) {
          Some(edge) => edges.push(edge)
          None => ()
        }
      }
      edges
    }
    None => []
  }
}

///|
pub fn Term::sub_in_edges(
  self : Term[Sub],
  blk : Term[Blk],
) -> Array[IrCfgEdge] {
  match self.find_blk(blk.tid()) {
    Some(dst) =>
      self.sub_edges().filter(edge => edge.dst_value.tid() == dst.tid())
    None => []
  }
}

///|
pub fn Term::sub_edges(self : Term[Sub]) -> Array[IrCfgEdge] {
  let edges = []
  for blk in self.blks() {
    for edge in self.sub_out_edges(blk) {
      edges.push(edge)
    }
  }
  edges
}

///|
pub fn Term::sub_edge(
  self : Term[Sub],
  src : Term[Blk],
  dst : Term[Blk],
) -> IrCfgEdge? {
  for edge in self.sub_out_edges(src) {
    if edge.dst_value.tid() == dst.tid() {
      return Some(edge)
    }
  }
  None
}
