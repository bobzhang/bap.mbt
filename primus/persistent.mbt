///|
/// A persistent (immutable) ordered map, convenient for plugin states:
/// updates return a new map and never affect other forks that share the
/// old one (see the clone policy of `State`).
pub struct PersistentMap[K, V] {
  priv map : @sorted_map.SortedMap[K, V]
}

///|
pub fn[K, V] PersistentMap::empty() -> PersistentMap[K, V] {
  { map: @sorted_map.SortedMap::new(), }
}

///|
pub fn[K : Compare, V] PersistentMap::get(
  self : PersistentMap[K, V],
  key : K,
) -> V? {
  self.map.get(key)
}

///|
pub fn[K : Compare, V] PersistentMap::contains(
  self : PersistentMap[K, V],
  key : K,
) -> Bool {
  self.map.contains(key)
}

///|
pub fn[K : Compare, V] PersistentMap::add(
  self : PersistentMap[K, V],
  key : K,
  value : V,
) -> PersistentMap[K, V] {
  { map: self.map.add(key, value), }
}

///|
pub fn[K : Compare, V] PersistentMap::remove(
  self : PersistentMap[K, V],
  key : K,
) -> PersistentMap[K, V] {
  { map: self.map.remove(key), }
}

///|
pub fn[K, V] PersistentMap::length(self : PersistentMap[K, V]) -> Int {
  self.map.length()
}

///|
/// The bindings in increasing key order.
pub fn[K, V] PersistentMap::to_array(
  self : PersistentMap[K, V],
) -> Array[(K, V)] {
  self.map.to_array()
}
