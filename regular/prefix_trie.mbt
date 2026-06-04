///|
struct PrefixTrie[V] {
  mut value : V?
  children : Map[Byte, PrefixTrie[V]]
}

///|
struct SuffixTrie[V] {
  trie : PrefixTrie[V]
}

///|
fn trie_key_bytes(key : StringView) -> Bytes {
  @utf8.encode(key.to_owned())
}

///|
fn reverse_trie_bytes(key : BytesView) -> Bytes {
  Bytes::from_array(Array::makei(key.length(), i => key[key.length() - i - 1]))
}

///|
fn decode_trie_bytes(key : BytesView) -> String {
  try @utf8.decode(key) catch {
    _ => abort("invalid UTF-8 trie key")
  } noraise {
    text => text
  }
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
  self.change_bytes(trie_key_bytes(key), f)
}

///|
fn[V] PrefixTrie::change_bytes(
  self : PrefixTrie[V],
  key : BytesView,
  f : (V?) -> V?,
) -> Unit {
  let mut node = self
  for i in 0..<key.length() {
    match node.children.get(key[i]) {
      Some(next) => node = next
      None =>
        match f(None) {
          Some(value) => {
            for j in i..<key.length() {
              node = node.children.get_or_init(key[j], () => PrefixTrie::new())
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
  self.find_bytes(trie_key_bytes(key))
}

///|
fn[V] PrefixTrie::find_bytes(self : PrefixTrie[V], key : BytesView) -> V? {
  let mut node = self
  for byte in key {
    match node.children.get(byte) {
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
  prefix : Array[Byte],
  acc : Ref[A],
  f : (A, ArrayView[Byte], V) -> A,
) -> Unit {
  match self.value {
    Some(value) => acc.val = f(acc.val, prefix, value)
    None => ()
  }
  self.children.each((ch, child) => {
    let next_prefix = prefix.copy()
    next_prefix.push(ch)
    child.fold_with_prefix(next_prefix, acc, f)
  })
}

///|
fn[V, A] PrefixTrie::fold_bytes(
  self : PrefixTrie[V],
  init~ : A,
  f~ : (A, ArrayView[Byte], V) -> A,
) -> A {
  let acc = Ref(init)
  self.fold_with_prefix([], acc, f)
  acc.val
}

///|
pub fn[V, A] PrefixTrie::fold(
  self : PrefixTrie[V],
  init~ : A,
  f~ : (A, String, V) -> A,
) -> A {
  self.fold_bytes(init~, f=fn(acc, key, value) {
    f(acc, decode_trie_bytes(Bytes::from_array(key)), value)
  })
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
  self.longest_match_bytes(trie_key_bytes(key))
}

///|
fn[V] PrefixTrie::longest_match_bytes(
  self : PrefixTrie[V],
  key : BytesView,
) -> (Int, V)? {
  let mut node = self
  let mut best : (Int, V)? = match node.value {
    Some(value) => Some((0, value))
    None => None
  }
  for i in 0..<key.length() {
    match node.children.get(key[i]) {
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
  self.trie.change_bytes(reverse_trie_bytes(trie_key_bytes(key)), f)
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
  self.trie.find_bytes(reverse_trie_bytes(trie_key_bytes(key)))
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
  self.trie.fold_bytes(init~, f=fn(acc, key, value) {
    f(acc, decode_trie_bytes(reverse_trie_bytes(Bytes::from_array(key))), value)
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
  self.trie.longest_match_bytes(reverse_trie_bytes(trie_key_bytes(key)))
}
