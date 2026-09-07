///|
struct Equiv {
  index : Int
} derive(Eq, Debug)

///|
pub extend Equiv with Eq::{not_equal, equal}

///|
pub extend Equiv with Debug::{to_repr}

///|
pub fn Equiv::to_int(self : Equiv) -> Int {
  self.index
}

///|
struct Group[N] {
  top_value : N
  members_value : Set[N]
  equiv_value : Equiv
} derive(Debug)

///|
pub extend Group with Debug::{to_repr}

///|
fn[N] graph_group_new(root : N, members : Set[N], index : Int) -> Group[N] {
  { top_value: root, members_value: members.copy(), equiv_value: { index, }, }
}

///|
pub fn[N] Group::elements(self : Group[N]) -> Array[N] {
  let out : Array[N] = []
  for element in self.members_value {
    out.push(element)
  }
  out
}

///|
pub fn[N] Group::enumerate(self : Group[N]) -> Array[N] {
  self.elements()
}

///|
pub fn[N] Group::members(self : Group[N]) -> Set[N] {
  self.members_value.copy()
}

///|
pub fn[N : Hash + Eq] Group::mem(self : Group[N], element : N) -> Bool {
  self.members_value.contains(element)
}

///|
pub fn[N] Group::top(self : Group[N]) -> N {
  self.top_value
}

///|
pub fn[N] Group::to_equiv(self : Group[N]) -> Equiv {
  self.equiv_value
}

///|
struct Partition[N] {
  roots_value : Array[N]
  groups_value : Array[Set[N]]
} derive(Debug)

///|
pub extend Partition with Debug::{to_repr}

///|
pub fn[N] Partition::group_sets(self : Partition[N]) -> Array[Set[N]] {
  self.groups_value.map(group => group.copy())
}

///|
pub fn[N] Partition::groups(self : Partition[N]) -> Array[Group[N]] {
  let groups = []
  for i in 0..<self.groups_value.length() {
    groups.push(graph_group_new(self.roots_value[i], self.groups_value[i], i))
  }
  groups
}

///|
pub fn[N] Partition::group_count(self : Partition[N]) -> Int {
  self.roots_value.length()
}

///|
pub fn[N] Partition::number_of_groups(self : Partition[N]) -> Int {
  self.group_count()
}

///|
pub fn[N : Hash + Eq] Partition::trivial(
  elements : ArrayView[N],
) -> Partition[N] {
  if elements.is_empty() {
    { roots_value: [], groups_value: [], }
  } else {
    { roots_value: [elements[0]], groups_value: [Set::from_array(elements)], }
  }
}

///|
pub fn[N : Hash + Eq] Partition::discrete(
  elements : ArrayView[N],
) -> Partition[N] {
  {
    roots_value: elements.to_owned(),
    groups_value: [
      for element in elements => Set::from_array([element])
    ],
  }
}

///|
fn[N : Hash + Eq] partition_group_index(
  groups : ArrayView[Set[N]],
  element : N,
) -> Int? {
  groups.search_by(group => group.contains(element))
}

///|
pub fn[N : Hash + Eq] Partition::equiv(
  self : Partition[N],
  lhs : N,
  rhs : N,
) -> Bool {
  match partition_group_index(self.groups_value, lhs) {
    Some(index) => self.groups_value[index].contains(rhs)
    None => false
  }
}

///|
fn[N] Partition::nth_group(self : Partition[N], index : Int) -> Group[N]? {
  if index < 0 || index >= self.group_count() {
    None
  } else {
    Some(
      graph_group_new(self.roots_value[index], self.groups_value[index], index),
    )
  }
}

///|
pub fn[N : Hash + Eq] Partition::group(
  self : Partition[N],
  element : N,
) -> Group[N]? {
  match partition_group_index(self.groups_value, element) {
    Some(index) => self.nth_group(index)
    None => None
  }
}

///|
pub fn[N] Partition::of_equiv(self : Partition[N], equiv : Equiv) -> Group[N]? {
  self.nth_group(equiv.index)
}

///|
pub fn[N : Hash + Eq] Partition::union(
  self : Partition[N],
  lhs : N,
  rhs : N,
) -> Partition[N] {
  let groups = self.groups_value.map(group => group.copy())
  let roots = self.roots_value.copy()
  match
    (partition_group_index(groups, lhs), partition_group_index(groups, rhs)) {
    (Some(left), Some(right)) if left == right => ()
    (Some(left), Some(right)) => {
      let target = left.min(right)
      let source = left.max(right)
      for element in groups[source] {
        groups[target].add(element)
      }
      ignore(groups.remove(source))
      ignore(roots.remove(source))
    }
    (Some(_), None) | (None, Some(_)) | (None, None) => ()
  }
  { roots_value: roots, groups_value: groups, }
}

///|
fn[N : Hash + Eq] add_to_refined_groups(
  groups : Array[Set[N]],
  element : N,
  equiv : (N, N) -> Bool,
) -> Unit {
  for group in groups {
    match group.iter().next() {
      Some(representative) if equiv(representative, element) => {
        group.add(element)
        return
      }
      _ => ()
    }
  }
  groups.push(Set::from_array([element]))
}

///|
pub fn[N : Hash + Eq] Partition::refine(
  self : Partition[N],
  equiv : (N, N) -> Bool,
) -> Partition[N] {
  let roots : Array[N] = []
  let refined : Array[Set[N]] = []
  for group in self.groups_value {
    let subgroups : Array[Set[N]] = []
    for element in group {
      add_to_refined_groups(subgroups, element, equiv)
    }
    for item in subgroups {
      match item.iter().next() {
        Some(root) => {
          roots.push(root)
          refined.push(item)
        }
        None => ()
      }
    }
  }
  { roots_value: roots, groups_value: refined, }
}
