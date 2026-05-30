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
  self.entries.copy()
}

///|
pub fn[V] MemMap::length(self : MemMap[V]) -> Int {
  self.entries.length()
}

///|
pub fn[V] MemMap::lookup(self : MemMap[V], addr : UInt64) -> Array[(Memory, V)] {
  self.entries.filter(entry => entry.0.contains(addr))
}

///|
pub fn[V] MemMap::contains(self : MemMap[V], addr : UInt64) -> Bool {
  self.entries.any(entry => entry.0.contains(addr))
}

///|
pub fn[V] MemMap::find(self : MemMap[V], memory : Memory) -> Array[(Memory, V)] {
  self.entries.filter(entry => {
    entry.0.min_addr() == memory.min_addr() &&
    entry.0.max_addr() == memory.max_addr()
  })
}

///|
pub fn[V] MemMap::intersections(
  self : MemMap[V],
  memory : Memory,
) -> Array[(Memory, V)] {
  self.entries.filter(entry => entry.0.intersects(memory))
}

///|
pub fn[V] MemMap::dominators(
  self : MemMap[V],
  memory : Memory,
) -> Array[(Memory, V)] {
  self.entries.filter(entry => entry.0.dominates(memory))
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
