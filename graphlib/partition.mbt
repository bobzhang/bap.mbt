///|
struct Partition[N] {
  groups_value : Array[Set[N]]
} derive(Debug)

///|
pub fn[N] Partition::groups(self : Partition[N]) -> Array[Set[N]] {
  self.groups_value.map(group => group.copy())
}

///|
pub fn[N] Partition::group_count(self : Partition[N]) -> Int {
  self.groups_value.length()
}

///|
pub fn[N : Hash + Eq] Partition::trivial(
  elements : ArrayView[N],
) -> Partition[N] {
  { groups_value: [Set::from_array(elements)] }
}

///|
pub fn[N : Hash + Eq] Partition::discrete(
  elements : ArrayView[N],
) -> Partition[N] {
  { groups_value: [ for element in elements => Set::from_array([element]) ] }
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
pub fn[N : Hash + Eq] Partition::union(
  self : Partition[N],
  lhs : N,
  rhs : N,
) -> Partition[N] {
  let groups = self.groups_value.map(group => group.copy())
  match
    (partition_group_index(groups, lhs), partition_group_index(groups, rhs)) {
    (Some(left), Some(right)) if left == right => ()
    (Some(left), Some(right)) => {
      for element in groups[right] {
        groups[left].add(element)
      }
      ignore(groups.remove(right))
    }
    (Some(left), None) => groups[left].add(rhs)
    (None, Some(right)) => groups[right].add(lhs)
    (None, None) => groups.push(Set::from_array([lhs, rhs]))
  }
  { groups_value: groups }
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
  let refined : Array[Set[N]] = []
  for group in self.groups_value {
    let subgroups : Array[Set[N]] = []
    for element in group {
      add_to_refined_groups(subgroups, element, equiv)
    }
    for item in subgroups {
      refined.push(item)
    }
  }
  { groups_value: refined }
}
