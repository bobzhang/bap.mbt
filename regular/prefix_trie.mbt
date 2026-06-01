///|
struct PrefixTrie[V] {
  mut value : V?
  children : Map[Char, PrefixTrie[V]]
}

///|
struct SuffixTrie[V] {
  trie : PrefixTrie[V]
}

///|
fn reverse_trie_key(key : StringView) -> String {
  let chars = []
  for ch in key {
    chars.push(ch)
  }
  let mut out = ""
  let mut i = chars.length()
  while i > 0 {
    i = i - 1
    out = out + "\{chars[i]}"
  }
  out
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
fn[V, A] PrefixTrie::fold_with_prefix(
  self : PrefixTrie[V],
  prefix : String,
  acc : Ref[A],
  f : (A, String, V) -> A,
) -> Unit {
  match self.value {
    Some(value) => acc.val = f(acc.val, prefix, value)
    None => ()
  }
  self.children.each((ch, child) => {
    child.fold_with_prefix(prefix + "\{ch}", acc, f)
  })
}

///|
pub fn[V, A] PrefixTrie::fold(
  self : PrefixTrie[V],
  init~ : A,
  f~ : (A, String, V) -> A,
) -> A {
  let acc = Ref(init)
  self.fold_with_prefix("", acc, f)
  acc.val
}

///|
pub fn[V] PrefixTrie::iter(
  self : PrefixTrie[V],
  f~ : (String, V) -> Unit,
) -> Unit {
  self.fold(init=(), f=fn(_, key, value) { f(key, value) })
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

///|
pub fn[V] SuffixTrie::new() -> SuffixTrie[V] {
  { trie: PrefixTrie::new() }
}

///|
pub fn[V] SuffixTrie::is_empty(self : SuffixTrie[V]) -> Bool {
  self.trie.is_empty()
}

///|
pub fn[V] SuffixTrie::length(self : SuffixTrie[V]) -> Int {
  self.trie.length()
}

///|
pub fn[V] SuffixTrie::change(
  self : SuffixTrie[V],
  key : StringView,
  f : (V?) -> V?,
) -> Unit {
  self.trie.change(reverse_trie_key(key), f)
}

///|
pub fn[V] SuffixTrie::add(
  self : SuffixTrie[V],
  key : StringView,
  value : V,
) -> Unit {
  self.change(key, _ => Some(value))
}

///|
pub fn[V] SuffixTrie::find(self : SuffixTrie[V], key : StringView) -> V? {
  self.trie.find(reverse_trie_key(key))
}

///|
pub fn[V] SuffixTrie::remove(self : SuffixTrie[V], key : StringView) -> Unit {
  self.change(key, _ => None)
}

///|
pub fn[V, A] SuffixTrie::fold(
  self : SuffixTrie[V],
  init~ : A,
  f~ : (A, String, V) -> A,
) -> A {
  self.trie.fold(init~, f=fn(acc, key, value) {
    f(acc, reverse_trie_key(key), value)
  })
}

///|
pub fn[V] SuffixTrie::iter(
  self : SuffixTrie[V],
  f~ : (String, V) -> Unit,
) -> Unit {
  self.fold(init=(), f=fn(_, key, value) { f(key, value) })
}

///|
pub fn[V] SuffixTrie::longest_match(
  self : SuffixTrie[V],
  key : StringView,
) -> (Int, V)? {
  self.trie.longest_match(reverse_trie_key(key))
}
