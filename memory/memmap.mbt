///|
struct MemMap[V] {
  entries : Array[(Memory, V)]
}

///|
pub fn[V] MemMap::empty() -> MemMap[V] {
  { entries: [] }
}

///|
pub fn[V] MemMap::singleton(memory : Memory, value : V) -> MemMap[V] {
  { entries: [(memory, value)] }
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
pub fn[V] MemMap::entries(self : MemMap[V]) -> Array[(Memory, V)] {
  self.ordered_entries()
}

///|
pub fn[V] MemMap::length(self : MemMap[V]) -> Int {
  self.entries.length()
}

///|
pub fn[V] MemMap::lookup(self : MemMap[V], addr : UInt64) -> Array[(Memory, V)] {
  self.ordered_entries().filter(entry => entry.0.contains(addr))
}

///|
pub fn[V] MemMap::contains(self : MemMap[V], addr : UInt64) -> Bool {
  self.entries.any(entry => entry.0.contains(addr))
}

///|
pub fn[V, U] MemMap::map(self : MemMap[V], f : (V) -> U) -> MemMap[U] {
  { entries: self.entries.map(entry => (entry.0, f(entry.1))) }
}

///|
pub fn[V, U] MemMap::mapi(self : MemMap[V], f : (Memory, V) -> U) -> MemMap[U] {
  { entries: self.entries.map(entry => (entry.0, f(entry.0, entry.1))) }
}

///|
pub fn[V] MemMap::filter(self : MemMap[V], f : (V) -> Bool) -> MemMap[V] {
  { entries: self.entries.filter(entry => f(entry.1)) }
}

///|
pub fn[V, U] MemMap::filter_map(self : MemMap[V], f : (V) -> U?) -> MemMap[U] {
  let entries = []
  for entry in self.entries {
    match f(entry.1) {
      Some(value) => entries.push((entry.0, value))
      None => ()
    }
  }
  { entries, }
}

///|
pub fn[V, U] MemMap::filter_mapi(
  self : MemMap[V],
  f : (Memory, V) -> U?,
) -> MemMap[U] {
  let entries = []
  for entry in self.entries {
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
pub fn[V : Hash + Eq, U] MemMap::link_one_to_one(
  self : MemMap[V],
  other : MemMap[U],
) -> Map[V, U] {
  let links : Map[V, U] = {}
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
  let links : Map[V, U?] = {}
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
  let links : Map[V, Array[U]] = {}
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
  let links : Map[V, (U, Array[U])] = {}
  for entry in self.entries {
    let matches = other.intersections(entry.0).map(item => item.1)
    if !matches.is_empty() {
      links[entry.1] = (matches[0], matches[1:].to_owned())
    }
  }
  links
}

///|
pub fn[V] MemMap::intersections(
  self : MemMap[V],
  memory : Memory,
) -> Array[(Memory, V)] {
  self.ordered_entries().filter(entry => entry.0.intersects(memory))
}

///|
pub fn[V] MemMap::intersects(self : MemMap[V], memory : Memory) -> Bool {
  self.entries.any(entry => entry.0.intersects(memory))
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
  { entries: self.entries.filter(entry => !entry.0.intersects(memory)) }
}

///|
pub fn[V] MemMap::remove_dominators(
  self : MemMap[V],
  memory : Memory,
) -> MemMap[V] {
  { entries: self.entries.filter(entry => !entry.0.dominates(memory)) }
}

///|
pub fn[V] MemMap::min_binding(self : MemMap[V]) -> (Memory, V)? {
  let mut best : Int? = None
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
  let mut best : Int? = None
  for i in 0..<self.entries.length() {
    best = match best {
      Some(j) if self.entries[j].0.max_addr() >= self.entries[i].0.max_addr() =>
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
fn memory_range_less(left : Memory, right : Memory) -> Bool {
  left.min_addr() < right.min_addr() ||
  (left.min_addr() == right.min_addr() && left.max_addr() < right.max_addr())
}

///|
fn memory_range_compare(left : Memory, right : Memory) -> Int {
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
  let mut best : Int? = None
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
pub fn[V] MemMap::prev_binding(
  self : MemMap[V],
  memory : Memory,
) -> (Memory, V)? {
  let mut best : Int? = None
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
