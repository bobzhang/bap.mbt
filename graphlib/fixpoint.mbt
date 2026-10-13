///|
struct Fixpoint[N, D] {
  steps_value : Int32?
  iterations_value : Int32
  default_value : D
  approx_value : Map[N, D]
} derive(Debug)

///|
pub extend Fixpoint with Debug::{to_repr}

///|
pub fn[N, D] Fixpoint::create(
  constraints : Map[N, D],
  default : D,
) -> Fixpoint[N, D] {
  {
    steps_value: Some(0),
    iterations_value: 0,
    default_value: default,
    approx_value: constraints.copy(),
  }
}

///|
pub fn[N, D] Fixpoint::iterations(self : Fixpoint[N, D]) -> Int32 {
  self.iterations_value
}

///|
pub fn[N, D] Fixpoint::default(self : Fixpoint[N, D]) -> D {
  self.default_value
}

///|
pub fn[N : Hash + Eq, D] Fixpoint::get(self : Fixpoint[N, D], node : N) -> D {
  match self.approx_value.get(node) {
    Some(value) => value
    None => self.default_value
  }
}

///|
pub fn[N, D] Fixpoint::entries(self : Fixpoint[N, D]) -> Array[(N, D)] {
  let out : Array[(N, D)] = []
  for entry in self.approx_value {
    out.push(entry)
  }
  out
}

///|
pub fn[N, D] Fixpoint::enumerate(self : Fixpoint[N, D]) -> Array[(N, D)] {
  self.entries()
}

///|
fn[N : Hash + Eq, D] Fixpoint::fixpoint_is_subset(
  self : Fixpoint[N, D],
  other : Fixpoint[N, D],
  equal : (D, D) -> Bool,
) -> Bool {
  for entry in self.approx_value {
    if !equal(other.get(entry.0), entry.1) {
      return false
    }
  }
  true
}

///|
pub fn[N : Hash + Eq, D] Fixpoint::equal(
  self : Fixpoint[N, D],
  other : Fixpoint[N, D],
  equal~ : (D, D) -> Bool,
) -> Bool {
  equal(self.default_value, other.default_value) &&
  self.approx_value.length() == other.approx_value.length() &&
  self.fixpoint_is_subset(other, equal) &&
  other.fixpoint_is_subset(self, equal)
}

///|
pub fn[N, D] Fixpoint::is_fixpoint(self : Fixpoint[N, D]) -> Bool {
  match self.steps_value {
    Some(steps) => self.iterations_value < steps
    None => self.iterations_value > 0
  }
}

///|
pub fn[N : Hash + Eq, D, A] Fixpoint::derive_values(
  self : Fixpoint[N, D],
  f : (N, D) -> A?,
  default : A,
) -> Fixpoint[N, A] {
  let out : Map[N, A] = Map([])
  for entry in self.approx_value {
    match f(entry.0, entry.1) {
      Some(value) => out[entry.0] = value
      None => ()
    }
  }
  Fixpoint::create(out, default)
}

///|
fn[D] fixpoint_get_approx(
  approx : Map[Int32, D],
  node : Int32,
  default : D,
) -> D {
  match approx.get(node) {
    Some(value) => value
    None => default
  }
}

///|
/// The set of nodes (reverse postorder ranks) left to visit, visited in the
/// increasing order of their ranks: a binary min-heap with a membership
/// table, so that adding a node twice keeps it once.
priv struct FixpointWorklist {
  heap : Array[Int32]
  queued : FixedArray[Bool]
}

///|
fn FixpointWorklist::new(size : Int32) -> FixpointWorklist {
  { heap: [], queued: FixedArray::make(size, false), }
}

///|
fn FixpointWorklist::is_empty(self : FixpointWorklist) -> Bool {
  self.heap.is_empty()
}

///|
fn FixpointWorklist::add(self : FixpointWorklist, index : Int32) -> Unit {
  if self.queued[index] {
    return
  }
  self.queued[index] = true
  let heap = self.heap
  heap.push(index)
  let mut i = heap.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if heap[parent] <= heap[i] {
      break
    }
    let tmp = heap[parent]
    heap[parent] = heap[i]
    heap[i] = tmp
    i = parent
  }
}

///|
fn FixpointWorklist::pop_min(self : FixpointWorklist) -> Int32? {
  let heap = self.heap
  guard heap.pop() is Some(last) else { return None }
  let result = if heap.is_empty() {
    last
  } else {
    let top = heap[0]
    heap[0] = last
    let n = heap.length()
    let mut i = 0
    while true {
      let l = 2 * i + 1
      let r = l + 1
      let mut smallest = i
      if l < n && heap[l] < heap[smallest] {
        smallest = l
      }
      if r < n && heap[r] < heap[smallest] {
        smallest = r
      }
      if smallest == i {
        break
      }
      let tmp = heap[i]
      heap[i] = heap[smallest]
      heap[smallest] = tmp
      i = smallest
    }
    top
  }
  self.queued[result] = false
  Some(result)
}

///|
fn fixpoint_can_iter(steps : Int32?, iterations : Int32) -> Bool {
  match steps {
    Some(limit) => iterations < limit
    None => true
  }
}

///|
fn[N : Hash + Eq, D] fixpoint_make_solution(
  init : Fixpoint[N, D],
  steps : Int32?,
  iterations : Int32,
  nodes : ArrayView[N],
  approx : Map[Int32, D],
) -> Fixpoint[N, D] {
  let out = init.approx_value.copy()
  for entry in approx {
    out[nodes[entry.0]] = entry.1
  }
  {
    steps_value: steps,
    iterations_value: iterations,
    default_value: init.default_value,
    approx_value: out,
  }
}

///|
pub fn[N : Hash + Eq, E, D] Graph::fixpoint(
  self : Graph[N, E],
  init~ : Fixpoint[N, D],
  equal~ : (D, D) -> Bool,
  merge~ : (D, D) -> D,
  f~ : (N, D) -> D,
  steps~ : Int32? = None,
  start~ : N? = None,
  rev~ : Bool = false,
  step~ : ((Int32, N, D, D) -> D)? = None,
) -> Fixpoint[N, D] {
  let nodes = self.reverse_postorder_traverse(rev~, start~)
  let rnodes : Map[N, Int32] = Map([])
  for i in 0..<nodes.length() {
    rnodes[nodes[i]] = i
  }
  let successors : Array[Set[Int32]] = []
  let adj = self.adjacency(rev)
  for node in nodes {
    let adjacent = adjacent_nodes(adj, node, rev)
    let ranked : Set[Int32] = Set([])
    for next in adjacent {
      match rnodes.get(next) {
        Some(index) => ranked.add(index)
        None => ()
      }
    }
    successors.push(ranked)
  }
  let approx : Map[Int32, D] = Map([])
  for entry in init.approx_value {
    match rnodes.get(entry.0) {
      Some(index) => approx[index] = entry.1
      None => ()
    }
  }
  let visits : Map[Int32, Int32] = Map([])
  let worklist = FixpointWorklist::new(nodes.length())
  for i in 0..<nodes.length() {
    worklist.add(i)
  }
  let mut iterations = init.iterations_value
  while fixpoint_can_iter(steps, iterations) && !worklist.is_empty() {
    match worklist.pop_min() {
      Some(index) => {
        let out = f(
          nodes[index],
          fixpoint_get_approx(approx, index, init.default_value),
        )
        for successor in successors[index] {
          let old = fixpoint_get_approx(approx, successor, init.default_value)
          let mut candidate = merge(out, old)
          match step {
            Some(user_step) => {
              let count = visits.get_or_default(successor, 0) + 1
              visits[successor] = count
              candidate = user_step(count, nodes[successor], old, candidate)
            }
            None => ()
          }
          if !equal(old, candidate) {
            approx[successor] = candidate
            worklist.add(successor)
          }
        }
        iterations += 1
      }
      None => ()
    }
  }
  fixpoint_make_solution(init, steps, iterations, nodes, approx)
}
