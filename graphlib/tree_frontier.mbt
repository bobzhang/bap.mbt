///|
struct Tree[N] {
  all_value : Array[N]
  parents_value : Map[N, N]
  children_value : Map[N, Set[N]]
} derive(Debug)

///|
fn[N] graph_set_elements(elements : Set[N]) -> Array[N] {
  let out : Array[N] = []
  for element in elements {
    out.push(element)
  }
  out
}

///|
fn[N : Hash + Eq] graph_tree_new(
  nodes : ArrayView[N],
  parents : Map[N, N],
) -> Tree[N] {
  let children : Map[N, Set[N]] = {}
  for node in nodes {
    children[node] = Set([])
  }
  for node in nodes {
    match parents.get(node) {
      Some(parent) => {
        let siblings = match children.get(parent) {
          Some(existing) => existing
          None => Set([])
        }
        siblings.add(node)
        children[parent] = siblings
      }
      None => ()
    }
  }
  {
    all_value: nodes.to_owned(),
    parents_value: parents.copy(),
    children_value: children,
  }
}

///|
pub fn[N] Tree::to_sequence(self : Tree[N]) -> Array[N] {
  self.all_value.copy()
}

///|
pub fn[N : Hash + Eq] Tree::parent(self : Tree[N], node : N) -> N? {
  self.parents_value.get(node)
}

///|
pub fn[N : Hash + Eq] Tree::children(self : Tree[N], node : N) -> Array[N] {
  match self.children_value.get(node) {
    Some(children) => graph_set_elements(children)
    None => []
  }
}

///|
pub fn[N : Hash + Eq] Tree::ancestors(self : Tree[N], node : N) -> Array[N] {
  let out : Array[N] = []
  let seen : Set[N] = Set([])
  let mut current = node
  let mut done = false
  while !done {
    match self.parents_value.get(current) {
      Some(parent) if !seen.contains(parent) => {
        out.push(parent)
        seen.add(parent)
        current = parent
      }
      _ => done = true
    }
  }
  out
}

///|
fn[N : Hash + Eq] graph_tree_collect_descendants(
  tree : Tree[N],
  node : N,
  seen : Set[N],
  out : Array[N],
) -> Unit {
  for child in tree.children(node) {
    if !seen.contains(child) {
      seen.add(child)
      out.push(child)
      graph_tree_collect_descendants(tree, child, seen, out)
    }
  }
}

///|
pub fn[N : Hash + Eq] Tree::descendants(self : Tree[N], node : N) -> Array[N] {
  let out : Array[N] = []
  graph_tree_collect_descendants(self, node, Set([]), out)
  out
}

///|
pub fn[N : Hash + Eq] Tree::is_child_of(
  self : Tree[N],
  child : N,
  parent~ : N,
) -> Bool {
  match self.children_value.get(parent) {
    Some(children) => children.contains(child)
    None => false
  }
}

///|
pub fn[N : Hash + Eq] Tree::is_ancestor_of(
  self : Tree[N],
  ancestor : N,
  child~ : N,
) -> Bool {
  self.ancestors(child).contains(ancestor)
}

///|
pub fn[N : Hash + Eq] Tree::is_descendant_of(
  self : Tree[N],
  descendant : N,
  parent~ : N,
) -> Bool {
  self.descendants(parent).contains(descendant)
}

///|
struct Frontier[N] {
  all_value : Array[N]
  map_value : Map[N, Set[N]]
} derive(Debug)

///|
fn[N : Hash + Eq] graph_frontier_new(
  nodes : ArrayView[N],
  frontiers : Map[N, Set[N]],
) -> Frontier[N] {
  let copied : Map[N, Set[N]] = {}
  for node in nodes {
    match frontiers.get(node) {
      Some(frontier) => copied[node] = frontier.copy()
      None => ()
    }
  }
  { all_value: nodes.to_owned(), map_value: copied }
}

///|
pub fn[N] Frontier::to_sequence(self : Frontier[N]) -> Array[N] {
  self.all_value.copy()
}

///|
pub fn[N : Hash + Eq] Frontier::elements(
  self : Frontier[N],
  node : N,
) -> Array[N] {
  match self.map_value.get(node) {
    Some(frontier) => graph_set_elements(frontier)
    None => []
  }
}

///|
pub fn[N : Hash + Eq] Frontier::enumerate(
  self : Frontier[N],
  node : N,
) -> Array[N] {
  self.elements(node)
}

///|
pub fn[N : Hash + Eq] Frontier::mem(
  self : Frontier[N],
  node : N,
  element : N,
) -> Bool {
  match self.map_value.get(node) {
    Some(frontier) => frontier.contains(element)
    None => false
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::dominator_tree(
  self : Graph[N, E],
  entry : N,
  rev? : Bool = false,
) -> Tree[N] {
  let idoms = self.immediate_dominators(entry, rev~)
  let reachable = self.reachable(entry, rev~)
  let parents : Map[N, N] = {}
  for node in self.nodes {
    if node != entry {
      match idoms.get(node) {
        Some(parent) => parents[node] = parent
        None =>
          if self.has_node(entry) && !reachable.contains(node) {
            parents[node] = entry
          }
      }
    }
  }
  graph_tree_new(self.nodes, parents)
}

///|
pub fn[N : Hash + Eq, E] Graph::dom_frontier(
  self : Graph[N, E],
  entry : N,
  rev? : Bool = false,
) -> Frontier[N] {
  let raw = self.dominance_frontiers(entry, rev~)
  let nodes : Array[N] = []
  let frontiers : Map[N, Set[N]] = {}
  for node in self.nodes {
    match raw.get(node) {
      Some(frontier) if !frontier.is_empty() => {
        nodes.push(node)
        frontiers[node] = frontier.copy()
      }
      _ => ()
    }
  }
  graph_frontier_new(nodes, frontiers)
}

///|
pub fn[N : Hash + Eq, E] Graph::dom_frontier_of_tree(
  self : Graph[N, E],
  tree : Tree[N],
  rev? : Bool = false,
) -> Frontier[N] {
  let frontiers : Map[N, Set[N]] = {}
  for node in self.nodes {
    let adjacent = if rev {
      self.successors(node)
    } else {
      self.predecessors(node)
    }
    let stop = tree.parent(node)
    let visited : Set[N] = Set([])
    for predecessor in adjacent {
      let mut runner = predecessor
      let mut done = false
      while !done {
        match stop {
          Some(limit) if runner == limit => done = true
          _ => {
            visited.add(runner)
            match tree.parent(runner) {
              Some(parent) => runner = parent
              None => done = true
            }
          }
        }
      }
    }
    for runner in visited {
      let frontier = match frontiers.get(runner) {
        Some(set) => set
        None => Set([])
      }
      frontier.add(node)
      frontiers[runner] = frontier
    }
  }
  let nodes : Array[N] = []
  for node in self.nodes {
    match frontiers.get(node) {
      Some(frontier) if !frontier.is_empty() => nodes.push(node)
      _ => ()
    }
  }
  graph_frontier_new(nodes, frontiers)
}
