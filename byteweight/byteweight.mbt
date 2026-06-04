///|
struct ByteweightStats {
  h1_value : Int
  h0_value : Int
}

///|
struct Byteweight {
  entries_value : Array[(Bytes, ByteweightStats)]
}

///|
pub fn ByteweightStats::create(h1? : Int = 0, h0? : Int = 0) -> ByteweightStats {
  { h1_value: h1, h0_value: h0 }
}

///|
pub fn ByteweightStats::h1(self : ByteweightStats) -> Int {
  self.h1_value
}

///|
pub fn ByteweightStats::h0(self : ByteweightStats) -> Int {
  self.h0_value
}

///|
pub fn ByteweightStats::trials(self : ByteweightStats) -> Int {
  self.h1_value + self.h0_value
}

///|
pub fn ByteweightStats::probability_h1(self : ByteweightStats) -> Double {
  let trials = self.trials()
  if trials == 0 {
    0.0
  } else {
    self.h1_value.to_double() / trials.to_double()
  }
}

///|
pub fn ByteweightStats::probability_h0(self : ByteweightStats) -> Double {
  let trials = self.trials()
  if trials == 0 {
    0.0
  } else {
    self.h0_value.to_double() / trials.to_double()
  }
}

///|
pub fn Byteweight::create() -> Byteweight {
  { entries_value: [] }
}

///|
pub fn Byteweight::length(self : Byteweight) -> Int {
  self.entries_value.length()
}

///|
pub fn Byteweight::entries(
  self : Byteweight,
) -> Array[(Bytes, ByteweightStats)] {
  self.entries_value.copy()
}

///|
pub fn Byteweight::find(self : Byteweight, key : BytesView) -> ByteweightStats? {
  let owned = key.to_owned()
  for entry in self.entries_value {
    if entry.0 == owned {
      return Some(entry.1)
    }
  }
  None
}

///|
fn byteweight_look(
  corpus : @memory.Memory,
  length : Int,
  offset : Int,
) -> @memory.Memory? {
  if length <= 0 || offset < 0 {
    None
  } else {
    let start = corpus.min_addr() + offset.to_uint64()
    match corpus.view(from=start, words=length) {
      Ok(memory) => Some(memory)
      Err(_) => None
    }
  }
}

///|
fn bytes_starts_with(data : BytesView, prefix : BytesView) -> Bool {
  if prefix.length() > data.length() {
    false
  } else {
    for i in 0..<prefix.length() {
      if data[i] != prefix[i] {
        return false
      }
    }
    true
  }
}

///|
fn Byteweight::change(
  self : Byteweight,
  key : BytesView,
  f : (ByteweightStats?) -> ByteweightStats?,
) -> Byteweight {
  let owned = key.to_owned()
  let entries = self.entries_value.copy()
  for i in 0..<entries.length() {
    if entries[i].0 == owned {
      match f(Some(entries[i].1)) {
        Some(stats) => entries[i] = (entries[i].0, stats)
        None => ignore(entries.remove(i))
      }
      return { entries_value: entries }
    }
  }
  match f(None) {
    Some(stats) => {
      entries.push((owned, stats))
      { entries_value: entries }
    }
    None => self
  }
}

///|
fn Byteweight::observe_positive(
  self : Byteweight,
  key : BytesView,
) -> Byteweight {
  self.change(key, stats => {
    match stats {
      Some(stats) =>
        Some(ByteweightStats::create(h1=stats.h1() + 1, h0=stats.h0()))
      None => Some(ByteweightStats::create(h1=1, h0=0))
    }
  })
}

///|
fn Byteweight::observe_negative(
  self : Byteweight,
  key : BytesView,
) -> Byteweight {
  self.change(key, stats => {
    match stats {
      Some(stats) =>
        Some(ByteweightStats::create(h1=stats.h1(), h0=stats.h0() + 1))
      None => None
    }
  })
}

///|
fn Byteweight::train_pass(
  self : Byteweight,
  max_length : Int,
  classify : (@memory.Memory) -> Bool,
  corpus : @memory.Memory,
  positive : Bool,
) -> Byteweight {
  let mut decider = self
  let mut length = max_length
  while length > 0 {
    let mut offset = 0
    let mut running = true
    while running {
      match byteweight_look(corpus, length, offset) {
        Some(chunk) => {
          if classify(chunk) {
            if positive {
              decider = decider.observe_positive(chunk.to_bytes())
            }
          } else if !positive {
            decider = decider.observe_negative(chunk.to_bytes())
          }
          offset = offset + 1
        }
        None => running = false
      }
    }
    length = length - 1
  }
  decider
}

///|
pub fn Byteweight::train(
  self : Byteweight,
  max_length~ : Int,
  classify : (@memory.Memory) -> Bool,
  corpus : @memory.Memory,
) -> Byteweight {
  self
  .train_pass(max_length, classify, corpus, true)
  .train_pass(max_length, classify, corpus, false)
}

///|
pub fn Byteweight::longest_match(
  self : Byteweight,
  key : BytesView,
) -> (Int, ByteweightStats)? {
  let mut best : (Int, ByteweightStats)? = None
  for entry in self.entries_value {
    let length = entry.0.length()
    if bytes_starts_with(key, entry.0) {
      best = match best {
        Some((best_length, _)) if best_length >= length => best
        _ => Some((length, entry.1))
      }
    }
  }
  best
}

///|
pub fn[A] Byteweight::fold(
  self : Byteweight,
  init~ : A,
  f~ : (A, Bytes, ByteweightStats) -> A,
) -> A {
  let mut result = init
  for entry in self.entries_value {
    result = f(result, entry.0, entry.1)
  }
  result
}

///|
pub fn Byteweight::next_if(
  self : Byteweight,
  length~ : Int,
  f~ : (@memory.Memory, Int, ByteweightStats) -> Bool,
  corpus : @memory.Memory,
  offset : Int,
) -> Int? {
  let mut current = if offset < 0 { 0 } else { offset }
  let mut running = true
  while running {
    match byteweight_look(corpus, length, current) {
      Some(chunk) =>
        match self.longest_match(chunk.to_bytes()) {
          Some((matched_length, stats)) if f(chunk, matched_length, stats) =>
            return Some(current)
          _ => current = current + 1
        }
      None => running = false
    }
  }
  None
}

///|
pub fn Byteweight::next(
  self : Byteweight,
  length~ : Int,
  threshold~ : Double,
  corpus : @memory.Memory,
  offset : Int,
) -> Int? {
  self.next_if(
    length~,
    f=(_, _, stats) => stats.probability_h1() > threshold,
    corpus,
    offset,
  )
}

///|
pub fn Byteweight::find_if(
  self : Byteweight,
  length~ : Int,
  f~ : (@memory.Memory, Int, ByteweightStats) -> Bool,
  corpus : @memory.Memory,
) -> Array[UInt64] {
  let addresses = []
  let mut offset = 0
  let mut running = true
  while running {
    match self.next_if(length~, f~, corpus, offset) {
      Some(next) => {
        addresses.push(corpus.min_addr() + next.to_uint64())
        offset = next + 1
      }
      None => running = false
    }
  }
  addresses
}

///|
pub fn Byteweight::find_positive(
  self : Byteweight,
  length~ : Int,
  threshold~ : Double,
  corpus : @memory.Memory,
) -> Array[UInt64] {
  self.find_if(
    length~,
    f=(_, _, stats) => stats.probability_h1() > threshold,
    corpus,
  )
}

///|
fn byteweight_ratio(numerator : Double, denominator : Double) -> Double {
  numerator / denominator
}

///|
pub fn Byteweight::find_using_bayes_factor(
  self : Byteweight,
  min_length~ : Int,
  max_length~ : Int,
  threshold : Double,
  corpus : @memory.Memory,
) -> Array[UInt64] {
  let totals = self.fold(init=(0, 0), f=fn(acc, key, stats) {
    if key.length() >= min_length && key.length() <= max_length {
      (acc.0 + stats.h1(), acc.1 + stats.h0())
    } else {
      acc
    }
  })
  if totals.0 + totals.1 == 0 {
    []
  } else {
    let ph1 = totals.0.to_double() / (totals.0 + totals.1).to_double()
    let ph0 = 1.0 - ph1
    self.find_if(
      length=max_length,
      f=(_, length, stats) => {
        if length < min_length || length > max_length {
          false
        } else {
          let p1 = stats.probability_h1()
          let p0 = stats.probability_h0()
          byteweight_ratio(p1, p0) * byteweight_ratio(ph1, ph0) > threshold
        }
      },
      corpus,
    )
  }
}

///|
pub fn Byteweight::find_using_threshold(
  self : Byteweight,
  min_length~ : Int,
  max_length~ : Int,
  threshold : Double,
  corpus : @memory.Memory,
) -> Array[UInt64] {
  self.find_if(
    length=max_length,
    f=(_, length, stats) => {
      length >= min_length && stats.probability_h1() > threshold
    },
    corpus,
  )
}
