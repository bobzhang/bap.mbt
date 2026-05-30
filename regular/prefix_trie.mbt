///|
struct PrefixTrie[V] {
  mut value : V?
  children : Map[Char, PrefixTrie[V]]
}

///|
pub fn[V] PrefixTrie::new() -> PrefixTrie[V] {
  { value: None, children: {} }
}

///|
pub fn[V] PrefixTrie::is_empty(self : PrefixTrie[V]) -> Bool {
  self.value is None && self.children.is_empty()
}

///|
pub fn[V] PrefixTrie::add(
  self : PrefixTrie[V],
  key : StringView,
  value : V,
) -> Unit {
  let mut node = self
  for ch in key {
    node = node.children.get_or_init(ch, () => PrefixTrie::new())
  }
  node.value = Some(value)
}

///|
pub fn[V] PrefixTrie::find(self : PrefixTrie[V], key : StringView) -> V? {
  let mut node = self
  for ch in key {
    match node.children.get(ch) {
      Some(next) => node = next
      None => return None
    }
  }
  node.value
}

///|
pub fn[V] PrefixTrie::remove(self : PrefixTrie[V], key : StringView) -> Unit {
  let mut node = self
  for ch in key {
    match node.children.get(ch) {
      Some(next) => node = next
      None => return
    }
  }
  node.value = None
}

///|
pub fn[V] PrefixTrie::longest_match(
  self : PrefixTrie[V],
  key : StringView,
) -> (Int, V)? {
  let mut node = self
  let mut best : (Int, V)? = match node.value {
    Some(value) => Some((0, value))
    None => None
  }
  for i, ch in key {
    match node.children.get(ch) {
      Some(next) => {
        node = next
        match node.value {
          Some(value) => best = Some((i + 1, value))
          None => ()
        }
      }
      None => return best
    }
  }
  best
}
