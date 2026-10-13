///|
struct MemMap[V] {
  entries : Array[(Memory, V)]
}

///|
pub(all) enum MemMapChange[V] {
  Rebind(Memory, V)
  Update((Memory, V) -> V)
  Remove
  Ignore
}

///|
pub fn[V] MemMap::empty() -> MemMap[V] {
  { entries: [], }
}

///|
pub fn[V] MemMap::singleton(memory : Memory, value : V) -> MemMap[V] {
  { entries: [(memory, value)], }
}

///|
pub fn[V] MemMap::add(
  self : MemMap[V],
  memory : Memory,
  value : V,
) -> MemMap[V] {
  let entries = self.entries.copy()
  entries.push((memory, value))
  { entries, }
}

///|
pub fn[V] MemMap::add_checked(
  self : MemMap[V],
  memory : Memory,
  value : V,
) -> Result[MemMap[V], String] {
  if self.has_intersections(memory) {
    Err("memory has intersections")
  } else {
    Ok(self.add(memory, value))
  }
}

///|
pub fn[V] MemMap::entries(self : MemMap[V]) -> Array[(Memory, V)] {
  self.ordered_entries()
}

///|
fn[V] MemMap::ranged_entries(
  self : MemMap[V],
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Array[(Memory, V)] {
  let entries = self.ordered_entries()
  if entries.is_empty() {
    return []
  }
  let from = match start {
    Some(memory) => memory
    None => entries[0].0
  }
  let last = match until {
    Some(memory) => memory
    None => entries[entries.length() - 1].0
  }
  if memory_range_compare(from, last) <= 0 {
    entries.filter(entry => {
      memory_range_compare(entry.0, from) >= 0 &&
      memory_range_compare(entry.0, last) <= 0
    })
  } else {
    entries
    .rev()
    .filter(entry => {
      memory_range_compare(entry.0, from) <= 0 &&
      memory_range_compare(entry.0, last) >= 0
    })
  }
}

///|
pub fn[V] MemMap::length(self : MemMap[V]) -> Int32 {
  self.entries.length()
}

///|
pub fn[V] MemMap::lookup(self : MemMap[V], addr : UInt64) -> Array[(Memory, V)] {
  self.ordered_entries().filter(entry => entry.0.contains(addr))
}

///|
pub fn[V] MemMap::find_addr(self : MemMap[V], addr : UInt64) -> (Memory, V)? {
  match self.lookup(addr) {
    [entry, ..] => Some(entry)
    [] => None
  }
}

///|
pub fn[V] MemMap::contains(self : MemMap[V], addr : UInt64) -> Bool {
  self.entries.any(entry => entry.0.contains(addr))
}

///|
pub fn[V, U] MemMap::map(
  self : MemMap[V],
  f : (V) -> U,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[U] {
  {
    entries: self
    .ranged_entries(start~, until~)
    .map(entry => (entry.0, f(entry.1))),
  }
}

///|
pub fn[V, U] MemMap::mapi(
  self : MemMap[V],
  f : (Memory, V) -> U,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[U] {
  {
    entries: self
    .ranged_entries(start~, until~)
    .map(entry => (entry.0, f(entry.0, entry.1))),
  }
}

///|
pub fn[V] MemMap::filter(
  self : MemMap[V],
  f : (V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[V] {
  self.filteri((_, value) => f(value), start~, until~)
}

///|
pub fn[V] MemMap::filteri(
  self : MemMap[V],
  f : (Memory, V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[V] {
  self.filter_mapi(
    (memory, value) => if f(memory, value) { Some(value) } else { None },
    start~,
    until~,
  )
}

///|
pub fn[V, U] MemMap::filter_map(
  self : MemMap[V],
  f : (V) -> U?,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[U] {
  self.filter_mapi((_, value) => f(value), start~, until~)
}

///|
pub fn[V, U] MemMap::filter_mapi(
  self : MemMap[V],
  f : (Memory, V) -> U?,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> MemMap[U] {
  let entries = []
  for entry in self.ranged_entries(start~, until~) {
    match f(entry.0, entry.1) {
      Some(value) => entries.push((entry.0, value))
      None => ()
    }
  }
  { entries, }
}

///|
pub fn[V] MemMap::find(self : MemMap[V], memory : Memory) -> Array[(Memory, V)] {
  self
  .ordered_entries()
  .filter(entry => {
    entry.0.min_addr() == memory.min_addr() &&
    entry.0.max_addr() == memory.max_addr()
  })
}

///|
pub fn[V] MemMap::has_memory(self : MemMap[V], memory : Memory) -> Bool {
  self.entries.any(entry => {
    entry.0.min_addr() == memory.min_addr() &&
    entry.0.max_addr() == memory.max_addr()
  })
}

///|
pub fn[V] MemMap::mem(self : MemMap[V], memory : Memory) -> Bool {
  self.has_memory(memory)
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_one_to_one(
  self : MemMap[V],
  other : MemMap[U],
) -> Map[V, U] {
  let links : Map[V, U] = Map([])
  for entry in self.entries {
    let matches = other.find(entry.0)
    if matches.length() == 1 {
      links[entry.1] = matches[0].1
    }
  }
  links
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_maybe_one(
  self : MemMap[V],
  other : MemMap[U],
) -> Map[V, U?] {
  let links : Map[V, U?] = Map([])
  for entry in self.entries {
    let matches = other.find(entry.0)
    links[entry.1] = match matches {
      [matched] => Some(matched.1)
      _ => None
    }
  }
  links
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_many(
  self : MemMap[V],
  other : MemMap[U],
) -> Map[V, Array[U]] {
  let links : Map[V, Array[U]] = Map([])
  for entry in self.entries {
    links[entry.1] = other.intersections(entry.0).map(item => item.1)
  }
  links
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_at_least_one(
  self : MemMap[V],
  other : MemMap[U],
) -> Map[V, (U, Array[U])] {
  let links : Map[V, (U, Array[U])] = Map([])
  for entry in self.entries {
    let matches = other.intersections(entry.0).map(item => item.1)
    if !matches.is_empty() {
      links[entry.1] = (matches[0], matches[1:].to_owned())
    }
  }
  links
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_maybe_one_checked(
  self : MemMap[V],
  other : MemMap[U],
) -> Result[Map[V, U?], String] {
  let links : Map[V, U?] = Map([])
  for entry in self.ordered_entries() {
    if links.get(entry.1) is Some(_) {
      return Err("mapping is non-injective")
    }
    let matches = other.find(entry.0)
    links[entry.1] = match matches {
      [matched] => Some(matched.1)
      _ => None
    }
  }
  Ok(links)
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_one_checked(
  self : MemMap[V],
  other : MemMap[U],
) -> Result[Map[V, U], String] {
  let links : Map[V, U] = Map([])
  for entry in self.ordered_entries() {
    if links.get(entry.1) is Some(_) {
      return Err("mapping is non-injective")
    }
    match other.find(entry.0) {
      [matched] => links[entry.1] = matched.1
      _ => return Err("link_exn: unbound value")
    }
  }
  Ok(links)
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_many_checked(
  self : MemMap[V],
  other : MemMap[U],
) -> Result[Map[V, Array[U]], String] {
  let links : Map[V, Array[U]] = Map([])
  for entry in self.ordered_entries() {
    if links.get(entry.1) is Some(_) {
      return Err("mapping is non-injective")
    }
    links[entry.1] = other.intersections(entry.0).map(item => item.1)
  }
  Ok(links)
}

///|
pub fn[V : Hash + Eq, U] MemMap::link_at_least_one_checked(
  self : MemMap[V],
  other : MemMap[U],
) -> Result[Map[V, (U, Array[U])], String] {
  let links : Map[V, (U, Array[U])] = Map([])
  for entry in self.ordered_entries() {
    if links.get(entry.1) is Some(_) {
      return Err("mapping is non-injective")
    }
    let matches = other.intersections(entry.0).map(item => item.1)
    if matches.is_empty() {
      return Err("at_least_one invariant failed. element is not mapped")
    }
    links[entry.1] = (matches[0], matches[1:].to_owned())
  }
  Ok(links)
}

///|
fn[V : Hash + Eq] MemMap::rev_map_injective(
  self : MemMap[V],
) -> Result[Map[V, Memory], String] {
  let result : Map[V, Memory] = Map([])
  for entry in self.ordered_entries() {
    if result.get(entry.1) is Some(_) {
      return Err("mapping is non-injective")
    }
    result[entry.1] = entry.0
  }
  Ok(result)
}

///|
pub fn[V : Hash + Eq] MemMap::rev_map_one(
  self : MemMap[V],
) -> Result[Map[V, Memory], String] {
  self.rev_map_injective()
}

///|
pub fn[V : Hash + Eq] MemMap::rev_map_maybe_one(
  self : MemMap[V],
) -> Result[Map[V, Memory], String] {
  self.rev_map_injective()
}

///|
pub fn[V : Hash + Eq] MemMap::rev_map_many(
  self : MemMap[V],
) -> Map[V, Array[Memory]] {
  let result : Map[V, Array[Memory]] = Map([])
  for entry in self.ordered_entries() {
    match result.get(entry.1) {
      Some(memories) => {
        let next = memories.copy()
        next.push(entry.0)
        result[entry.1] = next
      }
      None => result[entry.1] = [entry.0]
    }
  }
  result
}

///|
pub fn[V : Hash + Eq] MemMap::rev_map_at_least_one(
  self : MemMap[V],
) -> Map[V, (Memory, Array[Memory])] {
  let result : Map[V, (Memory, Array[Memory])] = Map([])
  self
  .rev_map_many()
  .each((value, memories) => {
    if !memories.is_empty() {
      result[value] = (memories[0], memories[1:].to_owned())
    }
  })
  result
}

///|
pub fn[V] MemMap::intersections(
  self : MemMap[V],
  memory : Memory,
) -> Array[(Memory, V)] {
  self.ordered_entries().filter(entry => entry.0.intersects(memory))
}

///|
pub fn[V, A] MemMap::fold_intersections(
  self : MemMap[V],
  memory : Memory,
  init~ : A,
  f~ : (Memory, V, A) -> A,
) -> A {
  let mut result = init
  for entry in self.intersections(memory) {
    result = f(entry.0, entry.1, result)
  }
  result
}

///|
pub fn[V, A] MemMap::foldi(
  self : MemMap[V],
  init : A,
  f : (Memory, V, A) -> A,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> A {
  let mut result = init
  for entry in self.ranged_entries(start~, until~) {
    result = f(entry.0, entry.1, result)
  }
  result
}

///|
pub fn[V, A] MemMap::fold(
  self : MemMap[V],
  init : A,
  f : (V, A) -> A,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> A {
  self.foldi(init, (_, value, acc) => f(value, acc), start~, until~)
}

///|
pub fn[V] MemMap::iteri(
  self : MemMap[V],
  f : (Memory, V) -> Unit,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Unit {
  for entry in self.ranged_entries(start~, until~) {
    f(entry.0, entry.1)
  }
}

///|
pub fn[V] MemMap::iter(
  self : MemMap[V],
  f : (V) -> Unit,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Unit {
  self.iteri((_, value) => f(value), start~, until~)
}

///|
pub fn[V] MemMap::existsi(
  self : MemMap[V],
  f : (Memory, V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Bool {
  for entry in self.ranged_entries(start~, until~) {
    if f(entry.0, entry.1) {
      return true
    }
  }
  false
}

///|
pub fn[V] MemMap::exists(
  self : MemMap[V],
  f : (V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Bool {
  self.existsi((_, value) => f(value), start~, until~)
}

///|
pub fn[V] MemMap::for_alli(
  self : MemMap[V],
  f : (Memory, V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Bool {
  for entry in self.ranged_entries(start~, until~) {
    if !f(entry.0, entry.1) {
      return false
    }
  }
  true
}

///|
pub fn[V] MemMap::for_all(
  self : MemMap[V],
  f : (V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Bool {
  self.for_alli((_, value) => f(value), start~, until~)
}

///|
pub fn[V] MemMap::count(
  self : MemMap[V],
  f : (V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Int32 {
  let mut total = 0
  for entry in self.ranged_entries(start~, until~) {
    if f(entry.1) {
      total = total + 1
    }
  }
  total
}

///|
pub fn[V, U] MemMap::find_mapi(
  self : MemMap[V],
  f : (Memory, V) -> U?,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> U? {
  for entry in self.ranged_entries(start~, until~) {
    match f(entry.0, entry.1) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
pub fn[V, U] MemMap::find_map(
  self : MemMap[V],
  f : (V) -> U?,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> U? {
  self.find_mapi((_, value) => f(value), start~, until~)
}

///|
pub fn[V] MemMap::find_if(
  self : MemMap[V],
  f : (V) -> Bool,
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> V? {
  self.find_map(
    value => if f(value) { Some(value) } else { None },
    start~,
    until~,
  )
}

///|
pub fn[V] MemMap::to_sequence(
  self : MemMap[V],
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Array[(Memory, V)] {
  self.ranged_entries(start~, until~)
}

///|
pub fn[V] MemMap::regions(
  self : MemMap[V],
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Array[Memory] {
  self.ranged_entries(start~, until~).map(entry => entry.0)
}

///|
pub fn[V] MemMap::elements(
  self : MemMap[V],
  start~ : Memory? = None,
  until~ : Memory? = None,
) -> Array[V] {
  self.ranged_entries(start~, until~).map(entry => entry.1)
}

///|
pub fn[V] MemMap::intersects(self : MemMap[V], memory : Memory) -> Bool {
  self.entries.any(entry => entry.0.intersects(memory))
}

///|
pub fn[V] MemMap::has_intersections(self : MemMap[V], memory : Memory) -> Bool {
  self.intersects(memory)
}

///|
pub fn[V] MemMap::remove(self : MemMap[V], memory : Memory) -> MemMap[V] {
  {
    entries: self.entries.filter(entry => {
      entry.0.min_addr() != memory.min_addr() ||
      entry.0.max_addr() != memory.max_addr()
    }),
  }
}

///|
pub fn[V] MemMap::change(
  self : MemMap[V],
  memory : Memory,
  f : (Array[(Memory, V)]) -> MemMapChange[V],
) -> MemMap[V] {
  match f(self.intersections(memory)) {
    Ignore => self
    Remove => self.remove_intersections(memory)
    Update(update) =>
      {
        entries: self.entries.map(entry => {
          if entry.0.intersects(memory) {
            (entry.0, update(entry.0, entry.1))
          } else {
            entry
          }
        }),
      }
    Rebind(next_memory, next_value) => {
      let entries = self.entries.filter(entry => !entry.0.intersects(memory))
      entries.push((next_memory, next_value))
      { entries, }
    }
  }
}

///|
pub fn[V] MemMap::dominators(
  self : MemMap[V],
  memory : Memory,
) -> Array[(Memory, V)] {
  self.ordered_entries().filter(entry => entry.0.dominates(memory))
}

///|
pub fn[V] MemMap::dominates(self : MemMap[V], memory : Memory) -> Bool {
  self.entries.any(entry => entry.0.dominates(memory))
}

///|
pub fn[V] MemMap::remove_intersections(
  self : MemMap[V],
  memory : Memory,
) -> MemMap[V] {
  { entries: self.entries.filter(entry => !entry.0.intersects(memory)), }
}

///|
pub fn[V] MemMap::remove_dominators(
  self : MemMap[V],
  memory : Memory,
) -> MemMap[V] {
  { entries: self.entries.filter(entry => !entry.0.dominates(memory)), }
}

///|
pub fn[V] MemMap::min_binding(self : MemMap[V]) -> (Memory, V)? {
  let mut best : Int32? = None
  for i in 0..<self.entries.length() {
    best = match best {
      Some(j) if self.entries[j].0.min_addr() <= self.entries[i].0.min_addr() =>
        Some(j)
      _ => Some(i)
    }
  }
  match best {
    Some(i) => Some(self.entries[i])
    None => None
  }
}

///|
pub fn[V] MemMap::max_binding(self : MemMap[V]) -> (Memory, V)? {
  let mut best : Int32? = None
  for i in 0..<self.entries.length() {
    let candidate = self.entries[i].0
    best = match best {
      Some(j) => {
        let current = self.entries[j].0
        if candidate.min_addr() >= current.min_addr() {
          Some(i)
        } else {
          Some(j)
        }
      }
      None => Some(i)
    }
  }
  match best {
    Some(i) => Some(self.entries[i])
    None => None
  }
}

///|
pub fn[V] MemMap::min(self : MemMap[V]) -> (Memory, V)? {
  self.min_binding()
}

///|
pub fn[V] MemMap::max(self : MemMap[V]) -> (Memory, V)? {
  self.max_binding()
}

///|
fn memory_range_less(left : Memory, right : Memory) -> Bool {
  left.min_addr() < right.min_addr()
}

///|
fn memory_range_compare(left : Memory, right : Memory) -> Int32 {
  if memory_range_less(left, right) {
    -1
  } else if memory_range_less(right, left) {
    1
  } else {
    0
  }
}

///|
fn[V] MemMap::ordered_entries(self : MemMap[V]) -> Array[(Memory, V)] {
  let indexed = [ for i in 0..<self.entries.length() => (self.entries[i], i) ]
  indexed.sort_by(fn(left, right) {
    let order = memory_range_compare(left.0.0, right.0.0)
    if order != 0 {
      order
    } else {
      left.1.compare(right.1)
    }
  })
  indexed.map(item => item.0)
}

///|
pub fn[V] MemMap::next_binding(
  self : MemMap[V],
  memory : Memory,
) -> (Memory, V)? {
  let mut best : Int32? = None
  for i in 0..<self.entries.length() {
    let candidate = self.entries[i].0
    if memory_range_less(memory, candidate) {
      best = match best {
        Some(j) if memory_range_less(self.entries[j].0, candidate) => Some(j)
        _ => Some(i)
      }
    }
  }
  match best {
    Some(i) => Some(self.entries[i])
    None => None
  }
}

///|
pub fn[V] MemMap::next(self : MemMap[V], memory : Memory) -> (Memory, V)? {
  self.next_binding(memory)
}

///|
pub fn[V] MemMap::prev_binding(
  self : MemMap[V],
  memory : Memory,
) -> (Memory, V)? {
  let mut best : Int32? = None
  for i in 0..<self.entries.length() {
    let candidate = self.entries[i].0
    if memory_range_less(candidate, memory) {
      best = match best {
        Some(j) if memory_range_less(candidate, self.entries[j].0) => Some(j)
        _ => Some(i)
      }
    }
  }
  match best {
    Some(i) => Some(self.entries[i])
    None => None
  }
}

///|
pub fn[V] MemMap::prev(self : MemMap[V], memory : Memory) -> (Memory, V)? {
  self.prev_binding(memory)
}

///|
pub fn[V] MemMap::min_addr(self : MemMap[V]) -> UInt64? {
  let mut best : UInt64? = None
  for entry in self.entries {
    best = match best {
      Some(addr) if addr <= entry.0.min_addr() => Some(addr)
      _ => Some(entry.0.min_addr())
    }
  }
  best
}

///|
pub fn[V] MemMap::max_addr(self : MemMap[V]) -> UInt64? {
  let mut best : UInt64? = None
  for entry in self.entries {
    best = match best {
      Some(addr) if addr >= entry.0.max_addr() => Some(addr)
      _ => Some(entry.0.max_addr())
    }
  }
  best
}
