///|
pub fn Term::succ_tid_of_jmp(self : Term[Jmp]) -> Tid? {
  match self.kind() {
    Goto(Direct(tid)) => Some(tid)
    Interrupt(_, tid) => Some(tid)
    JmpCall(call) =>
      match call.return_label {
        Some(Direct(tid)) => Some(tid)
        _ => None
      }
    _ => None
  }
}

///|
pub fn Term::blk_successor_tids(self : Term[Blk]) -> Array[Tid] {
  self.payload_value.jmps.filter_map(term => term.succ_tid_of_jmp())
}

///|
pub fn Term::entry_blk(self : Term[Sub]) -> Term[Blk]? {
  if self.payload_value.blks.is_empty() {
    None
  } else {
    Some(self.payload_value.blks[0])
  }
}

///|
pub fn Term::sub_cfg(self : Term[Sub]) -> @graphlib.Graph[Tid, Tid] {
  let mut graph : @graphlib.Graph[Tid, Tid] = @graphlib.Graph::new()
  for blk in self.payload_value.blks {
    graph = graph.add_node(blk.tid())
  }
  for blk in self.payload_value.blks {
    for jmp in blk.payload_value.jmps {
      match jmp.succ_tid_of_jmp() {
        Some(dst) if self.find_blk(dst) is Some(_) =>
          graph = graph.add_edge(src=blk.tid(), dst~, label=jmp.tid())
        _ => ()
      }
    }
  }
  graph
}

///|
pub fn Term::sub_successor_blocks(
  self : Term[Sub],
  blk : Term[Blk],
) -> Array[Term[Blk]] {
  let blocks = []
  for tid in blk.blk_successor_tids() {
    match self.find_blk(tid) {
      Some(block) => blocks.push(block)
      None => ()
    }
  }
  blocks
}

///|
pub fn Term::sub_predecessor_blocks(
  self : Term[Sub],
  blk : Term[Blk],
) -> Array[Term[Blk]] {
  let graph = self.sub_cfg()
  graph.predecessors(blk.tid()).filter_map(tid => self.find_blk(tid))
}

///|
pub fn Term::sub_has_edge(
  self : Term[Sub],
  src : Term[Blk],
  dst : Term[Blk],
) -> Bool {
  self.sub_cfg().has_edge(src.tid(), dst.tid())
}

///|
pub fn Term::sub_reverse_postorder(
  self : Term[Sub],
  entry? : Tid,
) -> Array[Term[Blk]] {
  let start = match entry {
    Some(tid) => Some(tid)
    None => self.entry_blk().map(term => term.tid())
  }
  match start {
    Some(tid) =>
      self.sub_cfg().reverse_postorder(tid).filter_map(id => self.find_blk(id))
    None => []
  }
}

///|
pub fn Term::sub_reachable_blocks(
  self : Term[Sub],
  entry? : Tid,
) -> Array[Term[Blk]] {
  self.sub_reverse_postorder(entry?)
}
