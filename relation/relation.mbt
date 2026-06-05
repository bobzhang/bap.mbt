///|
pub(all) enum NonInjective[K, S] {
  NonInjectiveFwd(Array[K], S)
  NonInjectiveBwd(Array[S], K)
} derive(Debug)

///|
struct Relation[K, S] {
  left_compare : (K, K) -> Int
  right_compare : (S, S) -> Int
  pairs : Array[(K, S)]
}

///|
pub fn[K, S] Relation::empty(
  compare_left~ : (K, K) -> Int,
  compare_right~ : (S, S) -> Int,
) -> Relation[K, S] {
  { left_compare: compare_left, right_compare: compare_right, pairs: [] }
}

///|
pub fn[K, S] empty(
  compare_left~ : (K, K) -> Int,
  compare_right~ : (S, S) -> Int,
) -> Relation[K, S] {
  Relation::empty(compare_left~, compare_right~)
}

///|
pub fn[K, S] is_empty(relation : Relation[K, S]) -> Bool {
  relation.is_empty()
}

///|
pub fn[K, S] Relation::is_empty(self : Relation[K, S]) -> Bool {
  self.pairs.is_empty()
}

///|
pub fn[K, S] Relation::length(self : Relation[K, S]) -> Int {
  self.pairs.length()
}

///|
fn[K, S] Relation::compare_pair(
  self : Relation[K, S],
  left : (K, S),
  right : (K, S),
) -> Int {
  let left_order = (self.left_compare)(left.0, right.0)
  if left_order != 0 {
    left_order
  } else {
    (self.right_compare)(left.1, right.1)
  }
}

///|
fn[K, S] Relation::sorted_pairs(self : Relation[K, S]) -> Array[(K, S)] {
  let pairs = self.pairs.copy()
  pairs.sort_by(fn(left, right) { self.compare_pair(left, right) })
  pairs
}

///|
pub fn[K, S] Relation::pairs(self : Relation[K, S]) -> Array[(K, S)] {
  self.sorted_pairs()
}

///|
fn[K : Eq, S : Eq] Relation::contains_pair(
  self : Relation[K, S],
  left : K,
  right : S,
) -> Bool {
  self.pairs.any(pair => pair.0 == left && pair.1 == right)
}

///|
pub fn[K : Eq, S : Eq] Relation::mem(
  self : Relation[K, S],
  left : K,
  right : S,
) -> Bool {
  self.pairs.any(pair => pair.0 == left) &&
  self.pairs.any(pair => pair.1 == right)
}

///|
pub fn[K : Eq, S : Eq] mem(
  relation : Relation[K, S],
  left : K,
  right : S,
) -> Bool {
  relation.mem(left, right)
}

///|
pub fn[K : Eq, S : Eq] Relation::add(
  self : Relation[K, S],
  left : K,
  right : S,
) -> Relation[K, S] {
  if self.contains_pair(left, right) {
    self
  } else {
    let pairs = self.pairs.copy()
    pairs.push((left, right))
    { ..self, pairs, }
  }
}

///|
pub fn[K : Eq, S : Eq] add(
  relation : Relation[K, S],
  left : K,
  right : S,
) -> Relation[K, S] {
  relation.add(left, right)
}

///|
pub fn[K : Eq, S] Relation::findl(self : Relation[K, S], left : K) -> Array[S] {
  let values = self.pairs.filter_map(pair => {
    if pair.0 == left {
      Some(pair.1)
    } else {
      None
    }
  })
  values.sort_by(self.right_compare)
  values
}

///|
pub fn[K : Eq, S] findl(relation : Relation[K, S], left : K) -> Array[S] {
  relation.findl(left)
}

///|
pub fn[K, S : Eq] Relation::findr(self : Relation[K, S], right : S) -> Array[K] {
  let values = self.pairs.filter_map(pair => {
    if pair.1 == right {
      Some(pair.0)
    } else {
      None
    }
  })
  values.sort_by(self.left_compare)
  values
}

///|
pub fn[K, S : Eq] findr(relation : Relation[K, S], right : S) -> Array[K] {
  relation.findr(right)
}

///|
pub fn[K, S, A] Relation::fold(
  self : Relation[K, S],
  init~ : A,
  f~ : (K, S, A) -> A,
) -> A {
  let mut result = init
  for pair in self.sorted_pairs() {
    result = f(pair.0, pair.1, result)
  }
  result
}

///|
pub fn[K, S, A] fold(
  relation : Relation[K, S],
  init~ : A,
  f~ : (K, S, A) -> A,
) -> A {
  relation.fold(init~, f~)
}

///|
pub fn[K, S] Relation::iter(self : Relation[K, S], f : (K, S) -> Unit) -> Unit {
  for pair in self.sorted_pairs() {
    f(pair.0, pair.1)
  }
}

///|
pub fn[K, S] iter(relation : Relation[K, S], f : (K, S) -> Unit) -> Unit {
  relation.iter(f)
}

///|
fn[T : Eq] push_unique(values : Array[T], value : T) -> Unit {
  if !values.any(item => item == value) {
    values.push(value)
  }
}

///|
fn[K : Eq, S] Relation::lefts(self : Relation[K, S]) -> Array[K] {
  let values = []
  for pair in self.sorted_pairs() {
    push_unique(values, pair.0)
  }
  values
}

///|
pub fn[K : Eq, S : Eq, A] matching(
  relation : Relation[K, S],
  init~ : A,
  saturated? : (K, S, A) -> A,
  unmatched? : (NonInjective[K, S], A) -> A,
) -> A {
  relation.matching(init~, saturated?, unmatched?)
}

///|
pub fn[K : Eq, S : Eq, A] Relation::matching(
  self : Relation[K, S],
  init~ : A,
  saturated? : (K, S, A) -> A,
  unmatched? : (NonInjective[K, S], A) -> A,
) -> A {
  let mut result = init
  for left in self.lefts() {
    let rights = self.findl(left)
    if rights.length() > 1 {
      match unmatched {
        Some(handle) => result = handle(NonInjectiveBwd(rights, left), result)
        None => ()
      }
    } else if rights.length() == 1 {
      let right = rights[0]
      let lefts = self.findr(right)
      if lefts.length() == 1 {
        match saturated {
          Some(handle) => result = handle(left, right, result)
          None => ()
        }
      } else {
        match unmatched {
          Some(handle) => result = handle(NonInjectiveFwd(lefts, right), result)
          None => ()
        }
      }
    }
  }
  result
}
