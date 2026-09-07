///|
struct StringsIndexKey[K] {
  null_value : K
  succ_fn : (K) -> K
  compare_fn : (K, K) -> Int
}

///|
struct StringsIndex[K] {
  key_spec : StringsIndexKey[K]
  strings_value : Array[(K, Bytes)]
  keys_value : Array[(Bytes, K)]
}

///|
pub fn[K] StringsIndexKey::create(
  null~ : K,
  succ~ : (K) -> K,
  compare~ : (K, K) -> Int,
) -> StringsIndexKey[K] {
  { null_value: null, succ_fn: succ, compare_fn: compare, }
}

///|
pub fn StringsIndexKey::int() -> StringsIndexKey[Int] {
  StringsIndexKey::create(null=0, succ=key => key + 1, compare=(lhs, rhs) => {
    lhs.compare(rhs)
  })
}

///|
pub fn[K] StringsIndex::empty(key~ : StringsIndexKey[K]) -> StringsIndex[K] {
  { key_spec: key, strings_value: [], keys_value: [], }
}

///|
pub fn StringsIndex::empty_int() -> StringsIndex[Int] {
  StringsIndex::empty(key=StringsIndexKey::int())
}

///|
fn[K] StringsIndex::last_key(self : StringsIndex[K]) -> K {
  let mut best = self.key_spec.null_value
  let mut seen = false
  for entry in self.strings_value {
    let key = entry.0
    if !seen || (self.key_spec.compare_fn)(key, best) > 0 {
      best = key
      seen = true
    }
  }
  best
}

///|
pub fn[K] StringsIndex::string(self : StringsIndex[K], key : K) -> Bytes {
  for entry in self.strings_value {
    if (self.key_spec.compare_fn)(entry.0, key) == 0 {
      return entry.1
    }
  }
  b""
}

///|
pub fn[K] StringsIndex::key(self : StringsIndex[K], data : BytesView) -> K {
  let owned = data.to_owned()
  for entry in self.keys_value {
    if entry.0 == owned {
      return entry.1
    }
  }
  self.key_spec.null_value
}

///|
pub fn[K] StringsIndex::registered(
  self : StringsIndex[K],
  data : BytesView,
) -> Bool {
  let owned = data.to_owned()
  self.keys_value.any(entry => entry.0 == owned)
}

///|
pub fn[K] StringsIndex::register(
  self : StringsIndex[K],
  data : BytesView,
) -> StringsIndex[K] {
  let owned = data.to_owned()
  if self.registered(owned) {
    self
  } else {
    let key = (self.key_spec.succ_fn)(self.last_key())
    let strings = self.strings_value.copy()
    let keys = self.keys_value.copy()
    strings.push((key, owned))
    keys.push((owned, key))
    { key_spec: self.key_spec, strings_value: strings, keys_value: keys, }
  }
}
