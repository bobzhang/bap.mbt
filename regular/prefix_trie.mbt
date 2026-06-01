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
pub fn[V] PrefixTrie::length(self : PrefixTrie[V]) -> Int {
  let total = Ref(if self.value is Some(_) { 1 } else { 0 })
  self.children.each((_, child) => total.val = total.val + child.length())
  total.val
}

///|
pub fn[V] PrefixTrie::change(
  self : PrefixTrie[V],
  key : StringView,
  f : (V?) -> V?,
) -> Unit {
  let chars = []
  for ch in key {
    chars.push(ch)
  }
  let mut node = self
  for i in 0..<chars.length() {
    match node.children.get(chars[i]) {
      Some(next) => node = next
      None =>
        match f(None) {
          Some(value) => {
            for j in i..<chars.length() {
              node = node.children.get_or_init(chars[j], () => PrefixTrie::new())
            }
            node.value = Some(value)
            return
          }
          None => return
        }
    }
  }
  node.value = f(node.value)
}

///|
pub fn[V] PrefixTrie::add(
  self : PrefixTrie[V],
  key : StringView,
  value : V,
) -> Unit {
  self.change(key, _ => Some(value))
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
  self.change(key, _ => None)
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
