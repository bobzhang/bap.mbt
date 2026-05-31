///|
pub fn Call::target(self : Call) -> Label {
  self.target
}

///|
pub fn Call::return_label(self : Call) -> Label? {
  self.return_label
}

///|
pub fn Call::return_(self : Call) -> Label? {
  self.return_label()
}

///|
pub fn Term::direct_call_target(self : Term[Jmp]) -> Tid? {
  match self.kind() {
    JmpCall(call) =>
      match call.target {
        Direct(tid) => Some(tid)
        Indirect(_) => None
      }
    _ => None
  }
}

///|
pub fn Term::resolved_call_targets(
  self : Term[Jmp],
  resolve_indirect~ : (Exp) -> Array[Tid],
) -> Array[Tid] {
  match self.kind() {
    JmpCall(call) =>
      match call.target {
        Direct(tid) => [tid]
        Indirect(exp) => resolve_indirect(exp)
      }
    _ => []
  }
}

///|
pub fn Term::sub_direct_call_tids(self : Term[Sub]) -> Array[Tid] {
  let tids = []
  for blk in self.payload_value.blks {
    for jmp in blk.payload_value.jmps {
      match jmp.direct_call_target() {
        Some(tid) => tids.push(tid)
        None => ()
      }
    }
  }
  tids
}

///|
pub fn Term::sub_resolved_call_tids(
  self : Term[Sub],
  resolve_indirect~ : (Exp) -> Array[Tid],
) -> Array[Tid] {
  let tids = []
  for blk in self.payload_value.blks {
    for jmp in blk.payload_value.jmps {
      for tid in jmp.resolved_call_targets(resolve_indirect~) {
        tids.push(tid)
      }
    }
  }
  tids
}

///|
fn append_call_edge(
  graph : @graphlib.Graph[Tid, Array[Term[Jmp]]],
  src : Tid,
  dst : Tid,
  jmp : Term[Jmp],
) -> @graphlib.Graph[Tid, Array[Term[Jmp]]] {
  let label = match graph.edge(src, dst) {
    Some(edge) => {
      let calls = edge.label.copy()
      calls.push(jmp)
      calls
    }
    None => [jmp]
  }
  graph.add_edge(src~, dst~, label~)
}

///|
pub fn Term::program_callgraph(
  self : Term[Program],
) -> @graphlib.Graph[Tid, Array[Term[Jmp]]] {
  let mut graph : @graphlib.Graph[Tid, Array[Term[Jmp]]] = @graphlib.Graph::new()
  for sub in self.payload_value.subs {
    graph = graph.add_node(sub.tid())
  }
  for sub in self.payload_value.subs {
    let src = sub.tid()
    for blk in sub.payload_value.blks {
      for jmp in blk.payload_value.jmps {
        match jmp.direct_call_target() {
          Some(dst) => graph = append_call_edge(graph, src, dst, jmp)
          None => ()
        }
      }
    }
  }
  graph
}

///|
pub fn Term::program_resolved_callgraph(
  self : Term[Program],
  resolve_indirect~ : (Exp) -> Array[Tid],
) -> @graphlib.Graph[Tid, Array[Term[Jmp]]] {
  let mut graph : @graphlib.Graph[Tid, Array[Term[Jmp]]] = @graphlib.Graph::new()
  for sub in self.payload_value.subs {
    graph = graph.add_node(sub.tid())
  }
  for sub in self.payload_value.subs {
    let src = sub.tid()
    for blk in sub.payload_value.blks {
      for jmp in blk.payload_value.jmps {
        for dst in jmp.resolved_call_targets(resolve_indirect~) {
          graph = append_call_edge(graph, src, dst, jmp)
        }
      }
    }
  }
  graph
}

///|
pub fn Term::program_callees(
  self : Term[Program],
  sub : Term[Sub],
) -> Array[Tid] {
  self.program_callgraph().successors(sub.tid())
}

///|
pub fn Term::program_callers(
  self : Term[Program],
  sub : Term[Sub],
) -> Array[Tid] {
  self.program_callgraph().predecessors(sub.tid())
}

///|
pub fn Term::program_resolved_callees(
  self : Term[Program],
  sub : Term[Sub],
  resolve_indirect~ : (Exp) -> Array[Tid],
) -> Array[Tid] {
  self.program_resolved_callgraph(resolve_indirect~).successors(sub.tid())
}

///|
pub fn Term::program_resolved_callers(
  self : Term[Program],
  sub : Term[Sub],
  resolve_indirect~ : (Exp) -> Array[Tid],
) -> Array[Tid] {
  self.program_resolved_callgraph(resolve_indirect~).predecessors(sub.tid())
}
