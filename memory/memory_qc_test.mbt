// Property-based tests for `memory`: address arithmetic, bounded reads and
// the naive-list `MemMap` checked against simple interval models.

///|
struct MemCase {
  big_endian : Bool
  start : UInt64
  data : Bytes
  // two addresses expressed as offsets from `start` (may lie outside)
  a : Int64
  b : Int64
  words : Int32
  word_size : Int32
} derive(Debug)

///|
fn gen_offset(len : Int32, rs : @splitmix.RandomState) -> Int64 {
  match rs.next_uint(limit=10) {
    // far away: the distance does not fit in 32 bits
    0 => 0x1_0000_0000L + rs.next_uint(limit=16).to_int64() - 8L
    1 => 0x2000_0000L + rs.next_uint(limit=16).to_int64()
    2 => -rs.next_uint(limit=4).to_int64() - 1L
    _ => rs.next_uint(limit=(len + 6).reinterpret_as_uint()).to_int64() - 2L
  }
}

///|
impl @quickcheck.Arbitrary for MemCase with fn arbitrary(_size, rs) {
  let len = 1 + rs.next_uint(limit=40).reinterpret_as_int()
  let data = Bytes::makei(len, _ => rs.next_uint(limit=256).to_byte())
  // keep clear of the top of the address space so max_addr cannot wrap
  let start = match rs.next_uint(limit=4) {
    0 => 0UL
    1 => 0x1000UL
    2 => 0xffff_ffffUL - rs.next_uint64(limit=64)
    _ => rs.next_uint64(limit=0x1_0000_0000_0000UL)
  }
  let words = match rs.next_uint(limit=6) {
    0 => -1
    1 => 0x2000_0001 // words * 8 overflows a 32-bit Int
    _ =>
      rs.next_uint(limit=(len + 3).reinterpret_as_uint()).reinterpret_as_int()
  }
  let word_size = [8, 8, 16, 32, 64, 12][rs
    .next_uint(limit=6)
    .reinterpret_as_int()]
  {
    big_endian: rs.next_uint(limit=2) == 0,
    start,
    data,
    a: gen_offset(len, rs),
    b: gen_offset(len, rs),
    words,
    word_size,
  }
}

///|
/// Shrinks the buffer (keeping at least one byte) and the word count; the
/// addresses are kept so that far-away counterexamples stay far away.
impl @quickcheck.Shrink for MemCase with fn shrink(c) {
  let out : Array[MemCase] = []
  let n = c.data.length()
  if n > 1 {
    out.push({ ..c, data: c.data[:1].to_owned(), })
    out.push({ ..c, data: c.data[:n / 2].to_owned(), })
    out.push({ ..c, data: c.data[:n - 1].to_owned(), })
  }
  if c.data.iter().any(b => b != b'\x00') {
    out.push({ ..c, data: Bytes::make(n, b'\x00'), })
  }
  if c.start != 0x1000UL {
    out.push({ ..c, start: 0x1000UL, })
  }
  out.iter()
}

///|
fn MemCase::endian(self : MemCase) -> @bitvec.Endian {
  if self.big_endian {
    BigEndian
  } else {
    LittleEndian
  }
}

///|
fn MemCase::mem(self : MemCase) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=self.endian(), start=self.start, self.data)
}

///|
fn MemCase::addr(self : MemCase, off : Int64) -> UInt64 {
  self.start + off.reinterpret_as_uint64()
}

///|
fn MemCase::len(self : MemCase) -> Int64 {
  self.data.length().to_int64()
}

///|
fn bytes_value(bytes : BytesView, big_endian : Bool) -> @bigint.BigInt {
  let arr = bytes.to_array()
  let ordered = if big_endian { arr } else { arr.rev() }
  let mut acc = 0N
  for b in ordered {
    acc = (acc << 8) + @bigint.BigInt::from_int(b.to_int())
  }
  acc
}

///|
fn word_value(word : @types.Word) -> @bigint.BigInt {
  @bigint.BigInt::from_string(word.to_bitvec().to_hex(prefix=false), radix=16)
}

///|
test "qc: memory cases cover inside, outside and far addresses" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      m.min_addr() == c.start &&
      m.max_addr() == c.start + (c.len() - 1L).reinterpret_as_uint64() &&
      m.length() == c.data.length() &&
      m.to_bytes() == c.data
    },
    observe=c => {
      [
        @quickcheck.classify(c.a >= 0L && c.a < c.len(), "a inside"),
        @quickcheck.classify(c.a < 0L, "a below"),
        @quickcheck.classify(c.a >= c.len(), "a above"),
        @quickcheck.classify(c.a >= 0x2000_0000L, "a far above"),
        @quickcheck.classify(c.words == 0x2000_0001, "huge word count"),
        @quickcheck.classify(c.big_endian, "big endian"),
      ]
    },
    count=300,
    seed=21,
  )
}

///|
test "qc: create slices the input or rejects bad positions" {
  @quickcheck.check(
    (input : (MemCase, Int32, Int32)) => {
      let (c, pos, len) = input
      let n = c.data.length()
      let pos = pos % (n + 2)
      let len = len % (n + 2)
      let size = if len < 0 { n - pos } else { len }
      let valid = pos >= 0 && pos < n && size > 0 && pos + size <= n
      match
        @memory.Memory::create(
          endian=c.endian(),
          start=c.start,
          c.data,
          pos~,
          len~,
        ) {
        Ok(m) =>
          valid &&
          m.min_addr() == c.start &&
          m.to_bytes() == c.data[pos:pos + size].to_owned()
        Err(_) => !valid
      }
    },
    count=300,
    seed=22,
  )
}

///|
test "qc: contains and compare_with agree with the address interval" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let addr = c.addr(c.a)
      let inside = c.a >= 0L && c.a < c.len()
      let expected : @memory.AddressPosition = if inside {
        AddrInside
      } else if c.a < 0L {
        AddrBelow
      } else {
        AddrAbove
      }
      m.contains(addr) == inside && m.compare_with(addr) == expected
    },
    filter=c => c.start >= 8UL, // offsets below zero must not wrap
    count=300,
    seed=23,
  )
}

///|
test "qc: view returns exactly the requested bytes or fails" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let from = c.addr(c.a)
      let result = m.view(from~, words=c.words, word_size=c.word_size)
      let ws_ok = c.word_size % 8 == 0
      let inside = c.a >= 0L && c.a < c.len()
      let available = c.len() - c.a
      let requested = if c.words < 0 {
        available
      } else {
        c.words.to_int64() * (c.word_size / 8).to_int64()
      }
      let valid = ws_ok && inside && requested > 0L && requested <= available
      match result {
        Ok(v) => {
          let off = c.a.to_int()
          valid &&
          v.min_addr() == from &&
          v.length().to_int64() == requested &&
          v.to_bytes() == c.data[off:off + v.length()].to_owned()
        }
        Err(_) => !valid
      }
    },
    filter=c => c.start >= 8UL,
    count=500,
    seed=24,
  )
}

///|
test "qc: range lo hi returns exactly [lo, hi] or fails" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let lo = c.addr(c.a)
      let hi = c.addr(c.b)
      let valid = c.a >= 0L && c.a <= c.b && c.b < c.len()
      match m.range(lo, hi) {
        Ok(r) =>
          valid &&
          r.min_addr() == lo &&
          r.max_addr() == hi &&
          r.to_bytes() == c.data[c.a.to_int():c.b.to_int() + 1].to_owned()
        Err(_) => !valid
      }
    },
    filter=c => c.start >= 8UL,
    count=500,
    seed=25,
  )
}

///|
test "qc: load reads in-bounds words with the memory byte order" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let addr = c.addr(c.a)
      let width = c.word_size
      let n = (width / 8).to_int64()
      let valid = width % 8 == 0 &&
        c.a >= 0L &&
        c.a < c.len() &&
        c.a + n <= c.len()
      match m.load(addr, width~) {
        Ok(word) => {
          let off = c.a.to_int()
          valid &&
          word.bitwidth() == width &&
          word_value(word) ==
          bytes_value(c.data[off:off + n.to_int()], c.big_endian)
        }
        Err(_) => !valid
      }
    },
    filter=c => c.start >= 8UL,
    count=500,
    seed=26,
  )
}

///|
test "qc: store then load returns the stored word and keeps other bytes" {
  @quickcheck.check(
    (input : (MemCase, UInt64)) => {
      let (c, v) = input
      let m = c.mem()
      let width = if c.word_size % 8 == 0 { c.word_size } else { 8 }
      let n = width / 8
      let off = c.a.to_int()
      let word = try! @types.Word::of_uint64(width~, v)
      match m.store(c.addr(c.a), word) {
        Ok(stored) => {
          let loaded = try! stored.load_exn(c.addr(c.a), width~)
          let after = stored.to_bytes()
          let mut others_ok = true
          for i in 0..<c.data.length() {
            if (i < off || i >= off + n) && after[i] != c.data[i] {
              others_ok = false
            }
          }
          off + n <= c.data.length() &&
          loaded.to_bitvec() == word.to_bitvec() &&
          others_ok &&
          // the original memory is immutable
          m.to_bytes() == c.data
        }
        Err(_) => off + n > c.data.length()
      }
    },
    filter=input => input.0.a >= 0L && input.0.a < input.0.len(),
    count=300,
    seed=27,
  )
}

///|
test "qc: foldi visits every complete word once, in address order" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let n = c.word_size / 8
      let visited = m.foldi(
        [],
        (addr, word, acc) => {
          acc.push((addr, word))
          acc
        },
        word_size=c.word_size,
      )
      if c.word_size % 8 != 0 {
        visited.is_empty()
      } else {
        let mut ok = visited.length() == c.data.length() / n
        for i, item in visited {
          let (addr, word) = item
          let off = i * n
          ok = ok &&
            addr == c.start + off.to_uint64() &&
            word_value(word) == bytes_value(c.data[off:off + n], c.big_endian)
        }
        ok && m.count((_, _) => true, word_size=c.word_size) == visited.length()
      }
    },
    count=300,
    seed=28,
  )
}

///|
test "qc: merging two views of one buffer rebuilds their union" {
  @quickcheck.check(
    (c : MemCase) => {
      let m = c.mem()
      let n = c.data.length()
      let i = c.a.to_int().abs() % n
      let j = c.b.to_int().abs() % n
      // two random sub-ranges [i, i2] and [j, j2]
      let i2 = i + c.words.abs() % (n - i)
      let j2 = j + c.word_size % (n - j)
      let left = try! m.view_exn(from=c.start + i.to_uint64(), words=i2 - i + 1)
      let right = try! m.view_exn(
        from=c.start + j.to_uint64(),
        words=j2 - j + 1,
      )
      let lo = i.min(j)
      let hi = i2.max(j2)
      let touching = i <= j2 + 1 && j <= i2 + 1
      match left.merge(right) {
        Ok(merged) =>
          touching &&
          merged.min_addr() == c.start + lo.to_uint64() &&
          merged.to_bytes() == c.data[lo:hi + 1].to_owned()
        Err(_) => !touching
      }
    },
    count=400,
    seed=29,
  )
}

///|
test "qc: merge rejects regions that are far apart" {
  @quickcheck.check(
    (c : MemCase) => {
      let left = c.mem()
      let right = c.mem().rebase(c.addr(c.len() + 1L + c.b.abs()))
      left.merge(right) is Err(_) && right.merge(left) is Err(_)
    },
    count=300,
    seed=30,
  )
}

///|
test "qc: intersects and dominates agree with interval models" {
  @quickcheck.check(
    (input : (MemCase, MemCase)) => {
      let (c, d) = input
      let m1 = c.mem()
      let m2 = d.mem().rebase(c.addr(d.a))
      let (lo1, hi1) = (m1.min_addr(), m1.max_addr())
      let (lo2, hi2) = (m2.min_addr(), m2.max_addr())
      m1.intersects(m2) == (lo1 <= hi2 && lo2 <= hi1) &&
      m1.intersects(m2) == m2.intersects(m1) &&
      m1.dominates(m2) == (lo1 <= lo2 && hi2 <= hi1) &&
      m1.dominates(m1)
    },
    filter=input => input.0.start >= 8UL,
    count=300,
    seed=31,
  )
}

///|
struct MapCase {
  regions : Array[(Int32, Int32)] // (start, length) with small addresses
  probe : Int32
} derive(Debug)

///|
impl @quickcheck.Arbitrary for MapCase with fn arbitrary(size, rs) {
  let count = rs
    .next_uint(limit=(size.min(12) + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let regions = Array::makei(count, _ => {
    (
      rs.next_uint(limit=48).reinterpret_as_int(),
      1 + rs.next_uint(limit=12).reinterpret_as_int(),
    )
  })
  { regions, probe: rs.next_uint(limit=64).reinterpret_as_int(), }
}

///|
impl @quickcheck.Shrink for MapCase with fn shrink(c) {
  Array::makei(c.regions.length(), i => {
    let regions = c.regions.copy()
    regions.remove(i) |> ignore
    { ..c, regions, }
  }).iter()
}

///|
fn MapCase::map(self : MapCase) -> @memory.MemMap[Int32] {
  let mut map = @memory.MemMap::empty()
  for i, r in self.regions {
    map = map.add(
      @memory.Memory::from_bytes(
        endian=LittleEndian,
        start=r.0.to_uint64(),
        Bytes::make(r.1, b'\x00'),
      ),
      i,
    )
  }
  map
}

///|
fn MapCase::probe_mem(self : MapCase) -> @memory.Memory {
  @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=self.probe.to_uint64(),
    Bytes::make(1 + self.probe % 5, b'\x00'),
  )
}

///|
test "qc: memmap queries agree with a list-of-intervals model" {
  @quickcheck.check(
    (c : MapCase) => {
      let map = c.map()
      let addr = c.probe.to_uint64()
      let p = c.probe_mem()
      let plo = c.probe
      let phi = c.probe + p.length() - 1
      let containing = []
      let intersecting = []
      let dominating = []
      for i, r in c.regions {
        let (lo, hi) = (r.0, r.0 + r.1 - 1)
        if lo <= c.probe && c.probe <= hi {
          containing.push(i)
        }
        if lo <= phi && plo <= hi {
          intersecting.push(i)
        }
        if lo <= plo && phi <= hi {
          dominating.push(i)
        }
      }
      let ids = (xs : Array[(@memory.Memory, Int32)]) => {
        let out = xs.map(x => x.1)
        out.sort()
        out
      }
      ids(map.lookup(addr)) == containing &&
      map.contains(addr) == !containing.is_empty() &&
      ids(map.intersections(p)) == intersecting &&
      map.has_intersections(p) == !intersecting.is_empty() &&
      ids(map.dominators(p)) == dominating &&
      map.remove_intersections(p).length() ==
      c.regions.length() - intersecting.length() &&
      map.length() == c.regions.length()
    },
    observe=c => {
      [
        @quickcheck.classify(c.regions.is_empty(), "empty map"),
        @quickcheck.classify(c.map().contains(c.probe.to_uint64()), "probe hit"),
      ]
    },
    count=300,
    seed=32,
  )
}

///|
test "qc: memmap entries are ordered and min/max bindings are extremal" {
  @quickcheck.check(
    (c : MapCase) => {
      let map = c.map()
      let entries = map.entries()
      let mut sorted = true
      for i in 1..<entries.length() {
        if entries[i - 1].0.min_addr() > entries[i].0.min_addr() {
          sorted = false
        }
      }
      let starts = c.regions.map(r => r.0.to_uint64())
      let lows = c.regions.map(r => r.0.to_uint64())
      let highs = c.regions.map(r => (r.0 + r.1 - 1).to_uint64())
      let min_start = starts
        .iter()
        .fold(init=None, (acc, x) => {
          match acc {
            Some(m) => Some(if x < m { x } else { m })
            None => Some(x)
          }
        })
      let max_start = starts
        .iter()
        .fold(init=None, (acc, x) => {
          match acc {
            Some(m) => Some(if x > m { x } else { m })
            None => Some(x)
          }
        })
      let max_high = highs
        .iter()
        .fold(init=None, (acc, x) => {
          match acc {
            Some(m) => Some(if x > m { x } else { m })
            None => Some(x)
          }
        })
      ignore(lows)
      sorted &&
      entries.length() == c.regions.length() &&
      map.min_binding().map(e => e.0.min_addr()) == min_start &&
      map.max_binding().map(e => e.0.min_addr()) == max_start &&
      map.min_addr() == min_start &&
      map.max_addr() == max_high
    },
    count=300,
    seed=33,
  )
}

///|
/// Regression (found by "qc: view returns exactly the requested bytes or
/// fails"): `words * word_bytes` overflowed a 32-bit Int, so a request for
/// 0x2000_0001 64-bit words was served as a single 8-byte word.
test "regression: view rejects a word count whose byte size overflows" {
  let m = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    Bytes::make(16, b'\x00'),
  )
  assert_true(m.view(words=0x2000_0001, word_size=64) is Err(_))
  assert_true(m.view(words=0x2000_0000, word_size=64) is Err(_))
  assert_true(m.view(words=0x7fff_ffff, word_size=8) is Err(_))
  assert_true(m.view(words=2, word_size=64) is Ok(_))
}

///|
/// Regression (found by "qc: range lo hi returns exactly [lo, hi] or
/// fails"): `hi - lo` was truncated to a 32-bit Int, so a range spanning
/// 2^32 + 1 bytes returned a one-byte memory, and a span of 2^32 - 13 bytes
/// (a negative Int) returned the whole tail of the region.
test "regression: range rejects spans larger than the region" {
  let m = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    Bytes::make(16, b'\x00'),
  )
  assert_true(m.range(0x1000UL, 0x1_0000_1000UL) is Err(_))
  assert_true(m.range(0x1000UL, 0x1000UL + 0xffff_fff2UL) is Err(_))
  assert_true(m.range(0x1000UL, 0x1010UL) is Err(_))
  match m.range(0x1002UL, 0x100fUL) {
    Ok(r) => {
      assert_eq(r.min_addr(), 0x1002UL)
      assert_eq(r.max_addr(), 0x100fUL)
    }
    Err(reason) => fail(reason)
  }
}

///|
/// Regression (found by "qc: merge rejects regions that are far apart"): the
/// merged span was truncated to a 32-bit Int, so regions 2^32 bytes apart
/// were "merged" into a few garbage bytes, or merge aborted with an index
/// out of bounds.
test "regression: merge rejects regions 2^32 bytes apart" {
  let left = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0UL,
    b"\x01\x02",
  )
  let far = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1_0000_0000UL,
    b"\x03\x04",
  )
  assert_true(left.merge(far) is Err(_))
  assert_true(far.merge(left) is Err(_))
  let wide = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0UL,
    b"\x01\x02\x03\x04",
  )
  let wrapping = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xffff_fffeUL,
    b"\x05\x06\x07\x08",
  )
  assert_true(wide.merge(wrapping) is Err(_))
}

///|
/// Operations on a `MemoryTrie` keyed by short byte strings.
struct TrieCase {
  word_size : Int32
  ops : Array[(Bool, Bytes, Int32)] // (add?, key, value)
  probe : Bytes
} derive(Debug)

///|
fn gen_trie_key(word_bytes : Int32, rs : @splitmix.RandomState) -> Bytes {
  let words = rs.next_uint(limit=4).reinterpret_as_int()
  Bytes::makei(words * word_bytes, _ => rs.next_uint(limit=2).to_byte())
}

///|
impl @quickcheck.Arbitrary for TrieCase with fn arbitrary(size, rs) {
  let word_size = [8, 16, 32, 64][rs.next_uint(limit=4).reinterpret_as_int()]
  let wb = word_size / 8
  let count = rs
    .next_uint(limit=(size.min(16) + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let ops : Array[(Bool, Bytes, Int32)] = []
  for i in 0..<count {
    let add = rs.next_uint(limit=3) != 0
    let key = if !add && !ops.is_empty() && rs.next_uint(limit=4) != 0 {
      ops[rs
      .next_uint(limit=ops.length().reinterpret_as_uint())
      .reinterpret_as_int()].1
    } else {
      gen_trie_key(wb, rs)
    }
    ops.push((add, key, i))
  }
  { word_size, ops, probe: gen_trie_key(wb, rs) + gen_trie_key(wb, rs), }
}

///|
impl @quickcheck.Shrink for TrieCase with fn shrink(t) {
  Array::makei(t.ops.length(), i => {
    let ops = t.ops.copy()
    ops.remove(i) |> ignore
    { ..t, ops, }
  }).iter()
}

///|
fn key_memory(key : Bytes) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start=0x10UL, key)
}

///|
test "qc: MemoryTrie agrees with a map model" {
  @quickcheck.check(
    (t : TrieCase) => {
      let trie : @memory.MemoryTrie[Int32] = match
        @memory.MemoryTrie::create(word_size=t.word_size) {
        Ok(trie) => trie
        Err(_) => return false
      }
      let model : Map[Bytes, Int32] = Map([])
      for op in t.ops {
        let (add, key, value) = op
        if add {
          trie.add(key_memory(key), value)
          model[key] = value
        } else {
          trie.remove(key_memory(key))
          model.remove(key)
        }
      }
      let wb = t.word_size / 8
      // longest stored prefix of the probe, in words
      let mut best : (Int32, Int32)? = None
      model.each((key, value) => {
        let n = key.length()
        if n <= t.probe.length() && t.probe[:n] == key[:] {
          best = match best {
            Some((b, _)) if b >= n / wb => best
            _ => Some((n / wb, value))
          }
        }
      })
      trie.length() == model.length() &&
      trie.is_empty() == model.is_empty() &&
      model.iter().all(kv => trie.find(key_memory(kv.0)) == Some(kv.1)) &&
      trie.longest_match(key_memory(t.probe)) == best
    },
    observe=t => {
      [
        @quickcheck.classify(t.ops.iter().any(op => !op.0), "has removals"),
        @quickcheck.collect(t.word_size),
      ]
    },
    count=300,
    seed=34,
  )
}

///|
/// Regression (found by "qc: MemoryTrie agrees with a map model"): `remove`
/// keeps the path to a removed key, so `is_empty` (which only looked at the
/// root) reported a trie with no bindings as non-empty.
test "regression: a memory trie is empty again after removing its only key" {
  let trie : @memory.MemoryTrie[Int32] = @memory.MemoryTrie::r32()
  let key = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x10UL,
    b"\x01\x01\x01\x00\x01\x01\x01\x01",
  )
  trie.add(key, 0)
  trie.remove(key)
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
  trie.add(key, 1)
  assert_true(!trie.is_empty())
}

///|
/// Regression (code review): the merged span is checked against Int::MAX
/// before it is narrowed; spans that fit are still merged.
test "regression: merge checks the span against Int::MAX, not the length sum" {
  let a = @memory.Memory::from_bytes(endian=LittleEndian, start=0UL, b"\x01")
  let far = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7fff_fffeUL,
    b"\x02",
  )
  // 2^31 - 1 bytes apart: not contiguous
  assert_true(a.merge(far) is Err(_))
  let b = @memory.Memory::from_bytes(endian=LittleEndian, start=1UL, b"\x02")
  guard a.merge(b) is Ok(m) else { fail("adjacent regions must merge") }
  inspect(m.hexdump(), content="01 02")
}

///|
/// Regression (code review): `is_empty` and `length` recursed once per key
/// word, so a long (but otherwise supported) key exhausted the stack.
test "regression: memory tries with very long keys" {
  let key = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    Bytes::makei(200000, i => (i % 7).to_byte()),
  )
  let trie : @memory.MemoryTrie[Int32] = @memory.MemoryTrie::r8()
  trie.add(key, 1)
  assert_true(!trie.is_empty())
  assert_eq(trie.length(), 1)
  assert_eq(trie.find(key), Some(1))
  trie.remove(key)
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
}
