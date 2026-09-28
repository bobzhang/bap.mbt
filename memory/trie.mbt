///|
struct MemoryTrie[V] {
  word_size_value : Int
  mut value : V?
  children : Array[(@types.Word, MemoryTrie[V])]
}

///|
fn memory_trie_valid_word_size(word_size : Int) -> Bool {
  word_size == 8 || word_size == 16 || word_size == 32 || word_size == 64
}

///|
fn[V] memory_trie_make(word_size : Int) -> MemoryTrie[V] {
  { word_size_value: word_size, value: None, children: [], }
}

///|
pub fn[V] MemoryTrie::create(
  word_size? : Int = 8,
) -> Result[MemoryTrie[V], String] {
  if memory_trie_valid_word_size(word_size) {
    Ok(memory_trie_make(word_size))
  } else {
    Err("memory trie word size must be one of 8, 16, 32, or 64")
  }
}

///|
pub fn[V] MemoryTrie::new() -> MemoryTrie[V] {
  memory_trie_make(8)
}

///|
pub fn[V] MemoryTrie::r8() -> MemoryTrie[V] {
  memory_trie_make(8)
}

///|
pub fn[V] MemoryTrie::r16() -> MemoryTrie[V] {
  memory_trie_make(16)
}

///|
pub fn[V] MemoryTrie::r32() -> MemoryTrie[V] {
  memory_trie_make(32)
}

///|
pub fn[V] MemoryTrie::r64() -> MemoryTrie[V] {
  memory_trie_make(64)
}

///|
pub fn[V] MemoryTrie::word_size(self : MemoryTrie[V]) -> Int {
  self.word_size_value
}

///|
fn Memory::trie_token_count(self : Memory, word_size : Int) -> Int {
  self.length() / (word_size / 8)
}

///|
fn Memory::trie_token_at(
  self : Memory,
  word_size : Int,
  index : Int,
) -> @types.Word {
  match self.get(index~, scale=word_size) {
    Ok(word) => word
    Err(reason) => abort("memory trie token invariant failed: \{reason}")
  }
}

///|
fn[V] MemoryTrie::child_index(
  self : MemoryTrie[V],
  token : @types.Word,
) -> Int? {
  for i in 0..<self.children.length() {
    if self.children[i].0 == token {
      return Some(i)
    }
  }
  None
}

///|
fn[V] MemoryTrie::child(
  self : MemoryTrie[V],
  token : @types.Word,
) -> MemoryTrie[V]? {
  match self.child_index(token) {
    Some(index) => Some(self.children[index].1)
    None => None
  }
}

///|
pub fn[V] MemoryTrie::is_empty(self : MemoryTrie[V]) -> Bool {
  // `remove` clears a value but keeps the path to it, so a node without a
  // value may still have (empty) children. Iterative: keys can be long.
  let stack = [self]
  while stack.pop() is Some(node) {
    if node.value is Some(_) {
      return false
    }
    for child in node.children {
      stack.push(child.1)
    }
  }
  true
}

///|
pub fn[V] MemoryTrie::length(self : MemoryTrie[V]) -> Int {
  // iterative: keys can be long
  let mut total = 0
  let stack = [self]
  while stack.pop() is Some(node) {
    if node.value is Some(_) {
      total = total + 1
    }
    for child in node.children {
      stack.push(child.1)
    }
  }
  total
}

///|
pub fn[V] MemoryTrie::change(
  self : MemoryTrie[V],
  key : Memory,
  f : (V?) -> V?,
) -> Unit {
  let len = key.trie_token_count(self.word_size_value)
  if len == 0 {
    self.value = f(self.value)
  } else {
    let mut node = self
    for i in 0..<len {
      let token = key.trie_token_at(self.word_size_value, i)
      match node.child_index(token) {
        Some(index) => node = node.children[index].1
        None =>
          match f(None) {
            Some(value) => {
              for j in i..<len {
                let next = memory_trie_make(self.word_size_value)
                let next_token = key.trie_token_at(self.word_size_value, j)
                node.children.push((next_token, next))
                node = next
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
}

///|
pub fn[V] MemoryTrie::add(
  self : MemoryTrie[V],
  key : Memory,
  value : V,
) -> Unit {
  self.change(key, _ => Some(value))
}

///|
pub fn[V, A] MemoryTrie::walk(
  self : MemoryTrie[V],
  key : Memory,
  init~ : A,
  f~ : (A, V?) -> A,
) -> A {
  let len = key.trie_token_count(self.word_size_value)
  let mut acc = f(init, self.value)
  let mut node = self
  for i in 0..<len {
    let token = key.trie_token_at(self.word_size_value, i)
    match node.child(token) {
      Some(next) => {
        node = next
        acc = f(acc, node.value)
      }
      None => return acc
    }
  }
  acc
}

///|
pub fn[V] MemoryTrie::longest_match(
  self : MemoryTrie[V],
  key : Memory,
) -> (Int, V)? {
  let len = key.trie_token_count(self.word_size_value)
  let mut best : (Int, V)? = match self.value {
    Some(value) => Some((0, value))
    None => None
  }
  let mut node = self
  for i in 0..<len {
    let token = key.trie_token_at(self.word_size_value, i)
    match node.child(token) {
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
pub fn[V] MemoryTrie::find(self : MemoryTrie[V], key : Memory) -> V? {
  let len = key.trie_token_count(self.word_size_value)
  match self.longest_match(key) {
    Some((matched, value)) if matched == len => Some(value)
    _ => None
  }
}

///|
pub fn[V] MemoryTrie::remove(self : MemoryTrie[V], key : Memory) -> Unit {
  self.change(key, _ => None)
}

///|
fn[V, A] MemoryTrie::fold_with_prefix(
  self : MemoryTrie[V],
  prefix : Array[@types.Word],
  acc : Ref[A],
  f : (A, ArrayView[@types.Word], V) -> A,
) -> Unit {
  match self.value {
    Some(value) => acc.val = f(acc.val, prefix, value)
    None => ()
  }
  for child in self.children {
    let next_prefix = prefix.copy()
    next_prefix.push(child.0)
    child.1.fold_with_prefix(next_prefix, acc, f)
  }
}

///|
pub fn[V, A] MemoryTrie::fold(
  self : MemoryTrie[V],
  init~ : A,
  f~ : (A, ArrayView[@types.Word], V) -> A,
) -> A {
  let acc = Ref(init)
  self.fold_with_prefix([], acc, f)
  acc.val
}

///|
pub fn[V] MemoryTrie::iter(
  self : MemoryTrie[V],
  f~ : (ArrayView[@types.Word], V) -> Unit,
) -> Unit {
  self.fold(init=(), f=fn(_, tokens, value) { f(tokens, value) })
}
