// The partition of basic blocks into subroutines (upstream
// `lib/bap_disasm/bap_disasm_calls.ml`, `Disasm.Calls`).
//
// The blocks and the jumps between them (including the calls) form a
// graph with an artificial entry node linked to the known subroutine
// starts. A block `n` is a parent of a block `m` if it strictly dominates
// `m` and is not the entry; the parents are computed with a descending
// fixed point over the lattice of sets of blocks (`Top` is the set of all
// blocks; blocks unreachable from the entry keep `Top`, so unconnected
// components do not change the parents of the other blocks). A block
// without parents is a subroutine entry, and a block belongs to the
// subroutines of its parents.

///|
/// A node of the call graph: the artificial entry or a block start.
priv enum CallNode {
  CallEntry
  CallBlock(UInt64)
} derive(Eq, Hash)

///|
/// The parents of a block (upstream `Parent.t`).
priv enum CallParent {
  /// all blocks (unknown)
  CallTop
  /// the known parents
  CallParents(@sorted_set.SortedSet[UInt64])
} derive(Eq)

///|
/// The subroutine partition of the disassembled blocks (upstream
/// `Calls.t`): the parents of the blocks and the subroutine entries.
struct ProjectDisassemblyCalls {
  parents : @graphlib.Fixpoint[CallNode, CallParent]
  entries_value : @sorted_set.SortedSet[UInt64]
  /// the extents of the blocks, for the queries with instruction addresses
  /// of the partitions built from a disassembly state
  spans : Array[(UInt64, UInt64)]
}

///|
fn call_parent_merge(x : CallParent, y : CallParent) -> CallParent {
  match (x, y) {
    (CallTop, x) | (x, CallTop) => x
    (CallParents(x), CallParents(y)) => CallParents(x.intersection(y))
  }
}

///|
fn call_parent_transfer(node : CallNode, parents : CallParent) -> CallParent {
  match (node, parents) {
    (CallEntry, parents) => parents
    (_, CallTop) => CallTop
    (CallBlock(addr), CallParents(parents)) => CallParents(parents.add(addr))
  }
}

///|
/// The initial solution: the entry has no parents, the other nodes are
/// unknown.
fn call_parents_init() -> @graphlib.Fixpoint[CallNode, CallParent] {
  @graphlib.Fixpoint::create(
    Map::from_array([(CallEntry, CallParents(@sorted_set.new()))]),
    CallTop,
  )
}

///|
/// `Calls.empty`.
pub fn ProjectDisassemblyCalls::empty() -> ProjectDisassemblyCalls {
  { parents: call_parents_init(), entries_value: @sorted_set.new(), spans: [], }
}

///|
/// The partition of the blocks of `graph` refining `init`.
fn project_calls_of_graph(
  graph : @graphlib.Graph[CallNode, Unit],
  init : @graphlib.Fixpoint[CallNode, CallParent],
  spans : Array[(UInt64, UInt64)],
) -> ProjectDisassemblyCalls {
  let parents = graph.fixpoint(
    init~,
    start=Some(CallEntry),
    equal=(x, y) => x == y,
    merge=call_parent_merge,
    f=call_parent_transfer,
  )
  let mut entries = @sorted_set.new()
  for node in graph.nodes() {
    match node {
      CallBlock(addr) =>
        if parents.get(node) is CallParents(p) && p.is_empty() {
          entries = entries.add(addr)
        }
      CallEntry => ()
    }
  }
  { parents, entries_value: entries, spans, }
}

///|
/// `Calls.update calls disasm`: the partition of the blocks of the
/// disassembled program, starting from the partition `self`. The call graph
/// is explored from the subroutine starts of `driver`; the blocks that the
/// knowledge base knows to be subroutine starts (`Theory.Label.is_subroutine`)
/// are linked to the entry.
pub fn ProjectDisassemblyCalls::update(
  self : ProjectDisassemblyCalls,
  driver : ProjectDisassemblyDriverState,
  kb : @knowledge.State,
) -> ProjectDisassemblyCalls raise {
  let builder : @graphlib.GraphBuilder[CallNode, Unit] = @graphlib.GraphBuilder::new()
  builder.add_node(CallEntry)
  let graph = driver.explore(
    kb,
    entries=driver.subroutines(),
    init=builder,
    block=(mem, _) => mem.min_addr(),
    node=(n, g) => {
      g.add_node(CallBlock(n))
      let code = project_label_for_addr(kb, n)
      if kb.collect(project_label_is_subroutine, code) is Some(true) {
        g.add_edge(src=CallEntry, dst=CallBlock(n), label=())
      }
      g
    },
    edge=(src, dst, g) => {
      g.add_edge(src=CallBlock(src), dst=CallBlock(dst), label=())
      g
    },
  )
  project_calls_of_graph(graph.to_graph(), self.parents, [])
}

///|
/// The partition of the blocks of a disassembly state: the blocks are
/// linked by the edges of the state, and `roots` are the subroutine starts.
/// The queries accept any address of a block.
pub fn ProjectDisassemblyCalls::of_disassembly(
  disassembly : ProjectDisassemblyState,
  roots : Array[UInt64],
) -> ProjectDisassemblyCalls {
  let blocks = disassembly.blocks()
  blocks.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  let spans = blocks.map(block => (block.min_addr(), block.max_addr()))
  let start_of = (addr : UInt64) => {
    for span in spans {
      if addr >= span.0 && addr <= span.1 {
        return Some(span.0)
      }
    }
    None
  }
  let graph : @graphlib.GraphBuilder[CallNode, Unit] = @graphlib.GraphBuilder::new()
  graph.add_node(CallEntry)
  for span in spans {
    graph.add_node(CallBlock(span.0))
    if roots.contains(span.0) {
      graph.add_edge(src=CallEntry, dst=CallBlock(span.0), label=())
    }
  }
  for edge in disassembly.edges() {
    match (start_of(edge.source()), edge.target().bind(start_of)) {
      (Some(src), Some(dst)) =>
        graph.add_edge(src=CallBlock(src), dst=CallBlock(dst), label=())
      _ => ()
    }
  }
  project_calls_of_graph(graph.to_graph(), call_parents_init(), spans)
}

///|
/// The block start of `addr` (itself for the partitions made by `update`).
fn ProjectDisassemblyCalls::block_of(
  self : ProjectDisassemblyCalls,
  addr : UInt64,
) -> UInt64 {
  for span in self.spans {
    if addr >= span.0 && addr <= span.1 {
      return span.0
    }
  }
  addr
}

///|
fn ProjectDisassemblyCalls::parents_of(
  self : ProjectDisassemblyCalls,
  addr : UInt64,
) -> CallParent {
  self.parents.get(CallBlock(self.block_of(addr)))
}

///|
/// `Calls.entries`: the subroutine entries, in increasing order.
pub fn ProjectDisassemblyCalls::entries(
  self : ProjectDisassemblyCalls,
) -> Array[UInt64] {
  self.entries_value.to_array()
}

///|
/// `Calls.belongs calls ~entry addr`: the block at `addr` belongs to the
/// subroutine starting at `entry`.
pub fn ProjectDisassemblyCalls::belongs(
  self : ProjectDisassemblyCalls,
  entry~ : UInt64,
  addr : UInt64,
) -> Bool {
  entry == addr ||
  self.block_of(entry) == self.block_of(addr) ||
  (match self.parents_of(addr) {
    CallTop => false
    CallParents(parents) => parents.contains(self.block_of(entry))
  })
}

///|
/// `Calls.entry calls addr`: the entry of the subroutine of the block at
/// `addr`, or `addr` itself when it is unknown.
pub fn ProjectDisassemblyCalls::entry(
  self : ProjectDisassemblyCalls,
  addr : UInt64,
) -> UInt64 {
  match self.parents_of(addr) {
    CallTop => addr
    CallParents(parents) =>
      match parents.intersection(self.entries_value).to_array() {
        [parent] => parent
        _ =>
          if self.entries_value.contains(self.block_of(addr)) {
            self.block_of(addr)
          } else {
            addr
          }
      }
  }
}

///|
/// `Calls.siblings calls x y`: the blocks at `x` and `y` belong to the same
/// subroutine.
pub fn ProjectDisassemblyCalls::siblings(
  self : ProjectDisassemblyCalls,
  x : UInt64,
  y : UInt64,
) -> Bool {
  let x = self.block_of(x)
  let y = self.block_of(y)
  x == y ||
  (match (self.parents_of(x), self.parents_of(y)) {
    (CallTop, _) | (_, CallTop) => false
    (CallParents(p1), CallParents(p2)) =>
      if p1.is_empty() {
        p2.contains(x)
      } else if p2.is_empty() {
        p1.contains(x)
      } else {
        !p1.is_disjoint(p2)
      }
  })
}

///|
/// `Calls.equal`.
pub fn ProjectDisassemblyCalls::equal(
  self : ProjectDisassemblyCalls,
  other : ProjectDisassemblyCalls,
) -> Bool {
  self.entries_value == other.entries_value &&
  self.parents.equal(other.parents, equal=(x, y) => x == y)
}

///|
/// The subroutine partition of the project: computed from the state of the
/// incremental disassembler when the project was disassembled by it (see
/// `ProjectDisassemblyDriver::recursive`), otherwise from the disassembly
/// state with the rooter roots as the subroutine starts.
pub fn Project::disassembly_calls(self : Project) -> ProjectDisassemblyCalls {
  match self.disassembly_driver_state() {
    Some(driver) =>
      self.with_disasm_providers(() => {
        ProjectDisassemblyCalls::empty().update(driver, self.knowledge())
      }) catch {
        _ =>
          ProjectDisassemblyCalls::of_disassembly(
            self.disassembly(),
            self.rooter().roots(),
          )
      }
    None =>
      ProjectDisassemblyCalls::of_disassembly(
        self.disassembly(),
        self.rooter().roots(),
      )
  }
}
