///|
fn[N : Hash + Eq, E] dfs_visit(
  graph : Graph[N, E],
  node : N,
  colors : Map[N, Int],
  entered : Map[N, Int],
  time : Ref[Int],
  events : Array[(EdgeKind, Edge[N, E])],
) -> Unit {
  colors[node] = 1
  entered[node] = time.val
  time.val = time.val + 1
  for edge in graph.out_edges(node) {
    match colors.get(edge.dst) {
      None => {
        events.push((Tree, edge))
        dfs_visit(graph, edge.dst, colors, entered, time, events)
      }
      Some(1) => events.push((Back, edge))
      Some(_) => {
        let src_entered = entered.get_or_default(edge.src, 0)
        let dst_entered = entered.get_or_default(edge.dst, 0)
        if src_entered < dst_entered {
          events.push((Forward, edge))
        } else {
          events.push((Cross, edge))
        }
      }
    }
  }
  colors[node] = 2
}

///|
fn[N : Hash + Eq, E] postorder_visit(
  graph : Graph[N, E],
  node : N,
  seen : Set[N],
  order : Array[N],
  rev : Bool,
) -> Unit {
  if !seen.contains(node) {
    seen.add(node)
    let edges = if rev { graph.in_edges(node) } else { graph.out_edges(node) }
    for edge in edges {
      let adjacent = if rev { edge.src } else { edge.dst }
      postorder_visit(graph, adjacent, seen, order, rev)
    }
    order.push(node)
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::dfs_edges(
  self : Graph[N, E],
  start : N,
) -> Array[(EdgeKind, Edge[N, E])] {
  let colors : Map[N, Int] = {}
  let entered : Map[N, Int] = {}
  let time = Ref::Ref(0)
  let events = []
  if self.has_node(start) {
    dfs_visit(self, start, colors, entered, time, events)
  }
  events
}

///|
fn[N : Hash + Eq, E] dfs_numbering_visit(
  graph : Graph[N, E],
  node : N,
  colors : Map[N, Int],
  time : Ref[Int],
  next_pre : Ref[Int],
  numbering : Map[N, DfsNodeInfo],
  leave_order : Array[N],
) -> Unit {
  colors[node] = 1
  let enter = time.val
  time.val += 1
  let pre = next_pre.val
  next_pre.val += 1
  numbering[node] = { enter, leave: -1, pre, rpost: -1 }
  for edge in graph.out_edges(node) {
    if !colors.contains(edge.dst) {
      dfs_numbering_visit(
        graph,
        edge.dst,
        colors,
        time,
        next_pre,
        numbering,
        leave_order,
      )
    }
  }
  let leave = time.val
  time.val += 1
  match numbering.get(node) {
    Some(info) => numbering[node] = { ..info, leave, }
    None => ()
  }
  leave_order.push(node)
  colors[node] = 2
}

///|
pub fn[N : Hash + Eq, E] Graph::dfs_numbering(
  self : Graph[N, E],
  start : N,
) -> Map[N, DfsNodeInfo] {
  let colors : Map[N, Int] = {}
  let numbering : Map[N, DfsNodeInfo] = {}
  let time = Ref::Ref(0)
  let next_pre = Ref::Ref(0)
  let leave_order : Array[N] = []
  if self.has_node(start) {
    dfs_numbering_visit(
      self, start, colors, time, next_pre, numbering, leave_order,
    )
  }
  let rpo = leave_order.rev()
  for i, node in rpo {
    match numbering.get(node) {
      Some(info) => numbering[node] = { ..info, rpost: i }
      None => ()
    }
  }
  numbering
}

///|
pub fn[N : Hash + Eq, E] Graph::reachable(
  self : Graph[N, E],
  start : N,
  rev? : Bool = false,
) -> Set[N] {
  let seen : Set[N] = Set([])
  let order = []
  if self.has_node(start) {
    postorder_visit(self, start, seen, order, rev)
  }
  seen
}

///|
fn[N : Hash + Eq, E, A] fold_reachable_visit(
  graph : Graph[N, E],
  node : N,
  seen : Set[N],
  acc : A,
  rev : Bool,
  f : (A, N) -> A,
) -> A {
  if seen.contains(node) {
    acc
  } else {
    seen.add(node)
    let mut next = f(acc, node)
    let edges = if rev { graph.in_edges(node) } else { graph.out_edges(node) }
    for edge in edges {
      let adjacent = if rev { edge.src } else { edge.dst }
      next = fold_reachable_visit(graph, adjacent, seen, next, rev, f)
    }
    next
  }
}

///|
pub fn[N : Hash + Eq, E, A] Graph::fold_reachable(
  self : Graph[N, E],
  start : N,
  init : A,
  f : (A, N) -> A,
  rev? : Bool = false,
) -> A {
  if self.has_node(start) {
    fold_reachable_visit(self, start, Set([]), init, rev, f)
  } else {
    init
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::is_reachable(
  self : Graph[N, E],
  start : N,
  finish : N,
  rev? : Bool = false,
) -> Bool {
  self.fold_reachable(
    start,
    false,
    (found, node) => found || node == finish,
    rev~,
  )
}

///|
pub fn[N : Hash + Eq, E] Graph::reverse_postorder(
  self : Graph[N, E],
  start : N,
  rev? : Bool = false,
) -> Array[N] {
  self.postorder(start, rev~).rev()
}

///|
pub fn[N : Hash + Eq, E] Graph::postorder(
  self : Graph[N, E],
  start : N,
  rev? : Bool = false,
) -> Array[N] {
  let seen : Set[N] = Set([])
  let order = []
  if self.has_node(start) {
    postorder_visit(self, start, seen, order, rev)
  }
  order
}

///|
priv struct ShortestPathItem[N, E] {
  total : Int
  node : N
  path : Array[Edge[N, E]]
}

///|
fn[N, E] shortest_path_pop_min(
  queue : Array[ShortestPathItem[N, E]],
) -> ShortestPathItem[N, E]? {
  if queue.is_empty() {
    None
  } else {
    let mut best = 0
    for i in 1..<queue.length() {
      if queue[i].total < queue[best].total {
        best = i
      }
    }
    Some(queue.remove(best))
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::shortest_path(
  self : Graph[N, E],
  start : N,
  finish : N,
  weight? : (Edge[N, E]) -> Int = _ => 1,
  rev? : Bool = false,
) -> GraphPath[Edge[N, E]]? {
  let visited : Set[N] = Set([])
  let distances : Map[N, Int] = {}
  let queue : Array[ShortestPathItem[N, E]] = [
    { total: 0, node: start, path: [] },
  ]
  distances[start] = 0
  let mut result : GraphPath[Edge[N, E]]? = None
  while result is None && !queue.is_empty() {
    match shortest_path_pop_min(queue) {
      Some(item) =>
        if !visited.contains(item.node) {
          if item.node == finish {
            result = Some(GraphPath::new(item.path, weight=item.total))
          } else {
            visited.add(item.node)
            let edges = if rev {
              self.in_edges(item.node)
            } else {
              self.out_edges(item.node)
            }
            for edge in edges {
              let next = if rev { edge.src } else { edge.dst }
              if !visited.contains(next) {
                let total = item.total + weight(edge)
                let keep = match distances.get(next) {
                  Some(old) => old < total
                  None => false
                }
                if !keep {
                  distances[next] = total
                  let path = item.path.copy()
                  path.push(edge)
                  queue.push({ total, node: next, path })
                }
              }
            }
          }
        }
      None => ()
    }
  }
  result
}

///|
fn[N : Hash + Eq, E] strong_connect(
  graph : Graph[N, E],
  node : N,
  index : Ref[Int],
  indexes : Map[N, Int],
  lowlinks : Map[N, Int],
  stack : Array[N],
  on_stack : Set[N],
  components : Array[Set[N]],
) -> Unit {
  indexes[node] = index.val
  lowlinks[node] = index.val
  index.val = index.val + 1
  stack.push(node)
  on_stack.add(node)
  for succ in graph.successors(node) {
    if !indexes.contains(succ) {
      strong_connect(
        graph, succ, index, indexes, lowlinks, stack, on_stack, components,
      )
      lowlinks[node] = Int::min(lowlinks[node], lowlinks[succ])
    } else if on_stack.contains(succ) {
      lowlinks[node] = Int::min(lowlinks[node], indexes[succ])
    }
  }
  if lowlinks[node] == indexes[node] {
    let component : Set[N] = Set([])
    let mut done = false
    while !done {
      match stack.pop() {
        Some(item) => {
          on_stack.remove(item)
          component.add(item)
          if item == node {
            done = true
          }
        }
        None => done = true
      }
    }
    components.push(component)
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::strong_components(
  self : Graph[N, E],
) -> Array[Set[N]] {
  let index = Ref::Ref(0)
  let indexes : Map[N, Int] = {}
  let lowlinks : Map[N, Int] = {}
  let stack : Array[N] = []
  let on_stack : Set[N] = Set([])
  let components : Array[Set[N]] = []
  for node in self.nodes {
    if !indexes.contains(node) {
      strong_connect(
        self, node, index, indexes, lowlinks, stack, on_stack, components,
      )
    }
  }
  components
}

///|
pub fn[N : Hash + Eq, E] Graph::dominators(
  self : Graph[N, E],
  entry : N,
) -> Map[N, Set[N]] {
  let all_nodes : Set[N] = Set::from_array(self.nodes)
  let reachable = self.reachable(entry)
  let doms : Map[N, Set[N]] = {}
  for node in self.nodes {
    if node == entry {
      doms[node] = Set::from_array([node])
    } else if reachable.contains(node) {
      doms[node] = all_nodes.copy()
    } else {
      doms[node] = Set::from_array([node])
    }
  }
  let mut changed = true
  while changed {
    changed = false
    for node in self.nodes {
      if node != entry && reachable.contains(node) {
        let preds = self
          .predecessors(node)
          .filter(pred => reachable.contains(pred))
        let mut next : Set[N]? = None
        for pred in preds {
          match doms.get(pred) {
            Some(pred_dom) =>
              next = match next {
                Some(acc) => Some(acc.intersection(pred_dom))
                None => Some(pred_dom.copy())
              }
            None => ()
          }
        }
        let candidate = match next {
          Some(set) => {
            set.add(node)
            set
          }
          None => Set::from_array([node])
        }
        match doms.get(node) {
          Some(old) if old == candidate => ()
          _ => {
            doms[node] = candidate
            changed = true
          }
        }
      }
    }
  }
  doms
}

///|
fn[N : Hash + Eq] immediate_dominator_of(doms : Map[N, Set[N]], node : N) -> N? {
  match doms.get(node) {
    Some(dominators) => {
      let strict = dominators.copy()
      strict.remove(node)
      for candidate in strict {
        match doms.get(candidate) {
          Some(candidate_doms) => {
            let mut dominated_by_all = true
            for other in strict {
              if other != candidate && !candidate_doms.contains(other) {
                dominated_by_all = false
              }
            }
            if dominated_by_all {
              return Some(candidate)
            }
          }
          None => ()
        }
      }
      None
    }
    None => None
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::immediate_dominators(
  self : Graph[N, E],
  entry : N,
) -> Map[N, N] {
  let doms = self.dominators(entry)
  let reachable = self.reachable(entry)
  let idoms : Map[N, N] = {}
  for node in self.nodes {
    if node != entry && reachable.contains(node) {
      match immediate_dominator_of(doms, node) {
        Some(idom) => idoms[node] = idom
        None => ()
      }
    }
  }
  idoms
}

///|
pub fn[N : Hash + Eq, E] Graph::dominance_frontiers(
  self : Graph[N, E],
  entry : N,
) -> Map[N, Set[N]] {
  let reachable = self.reachable(entry)
  let idoms = self.immediate_dominators(entry)
  let frontiers : Map[N, Set[N]] = {}
  for node in self.nodes {
    frontiers[node] = Set([])
  }
  for node in self.nodes {
    let preds = self.predecessors(node).filter(pred => reachable.contains(pred))
    if reachable.contains(node) && preds.length() >= 2 {
      match idoms.get(node) {
        Some(stop) =>
          for pred in preds {
            let mut runner = pred
            while runner != stop {
              let frontier = match frontiers.get(runner) {
                Some(set) => set
                None => Set([])
              }
              frontier.add(node)
              frontiers[runner] = frontier
              match idoms.get(runner) {
                Some(next) => runner = next
                None => break
              }
            }
          }
        None => ()
      }
    }
  }
  frontiers
}
