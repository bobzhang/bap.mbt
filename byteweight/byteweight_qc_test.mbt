// Property-based tests for `byteweight`: training counts, lookups, the
// serialized form and the scanners, against naive models on small corpora
// over a tiny byte alphabet (so that signatures repeat).

///|
struct Corpus {
  data : Bytes
  starts : Array[Int] // offsets classified as function starts
  max_length : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Corpus with fn arbitrary(size, rs) {
  let len = 1 +
    rs
    .next_uint(limit=(size.min(40) + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let data = Bytes::makei(len, _ => rs.next_uint(limit=3).to_byte())
  let starts = []
  for i in 0..<len {
    if rs.next_uint(limit=3) == 0 {
      starts.push(i)
    }
  }
  { data, starts, max_length: 1 + rs.next_uint(limit=4).reinterpret_as_int(), }
}

///|
impl @quickcheck.Shrink for Corpus with fn shrink(c) {
  let out : Array[Corpus] = []
  let n = c.data.length()
  if n > 1 {
    let half = n / 2
    out.push({
      ..c,
      data: c.data[:half].to_owned(),
      starts: c.starts.filter(s => s < half),
    })
  }
  if c.max_length > 1 {
    out.push({ ..c, max_length: c.max_length - 1, })
  }
  out.iter()
}

///|
fn Corpus::memory(self : Corpus) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start=0x400UL, self.data)
}

///|
fn Corpus::trained(self : Corpus) -> @byteweight.Byteweight {
  let base = 0x400UL
  @byteweight.Byteweight::create().train(
    max_length=self.max_length,
    chunk => self.starts.contains((chunk.min_addr() - base).to_int()),
    self.memory(),
  )
}

///|
/// Reference counts: (h1, h0) for every key of length 1..max_length that
/// occurs at least once at a start.
fn Corpus::model(self : Corpus) -> Map[Bytes, (Int, Int)] {
  let counts : Map[Bytes, (Int, Int)] = Map([])
  let n = self.data.length()
  for len in 1..<=self.max_length {
    for o in 0..<=(n - len) {
      if self.starts.contains(o) {
        let key = self.data[o:o + len].to_owned()
        let (h1, h0) = counts.get_or_default(key, (0, 0))
        counts[key] = (h1 + 1, h0)
      }
    }
  }
  for len in 1..<=self.max_length {
    for o in 0..<=(n - len) {
      if !self.starts.contains(o) {
        let key = self.data[o:o + len].to_owned()
        if counts.get(key) is Some((h1, h0)) {
          counts[key] = (h1, h0 + 1)
        }
      }
    }
  }
  counts
}

///|
test "qc: training counts positive and negative occurrences of each key" {
  @quickcheck.check(
    (c : Corpus) => {
      let bw = c.trained()
      let model = c.model()
      let entries = bw.entries()
      let mut ok = entries.length() == model.length() &&
        bw.length() == model.length()
      for entry in entries {
        let (key, stats) = entry
        ok = ok &&
          model.get(key) == Some((stats.h1(), stats.h0())) &&
          bw.find(key).map(s => (s.h1(), s.h0())) ==
          Some((stats.h1(), stats.h0()))
      }
      ok
    },
    observe=c => {
      [
        @quickcheck.classify(c.starts.is_empty(), "no starts"),
        @quickcheck.classify(c.trained().length() > 5, "more than 5 signatures"),
      ]
    },
    count=300,
    seed=81,
  )
}

///|
test "qc: probabilities are frequencies of the counts" {
  @quickcheck.check(
    (input : (UInt16, UInt16)) => {
      let (h1, h0) = input
      let stats = @byteweight.ByteweightStats::create(
        h1=h1.to_int(),
        h0=h0.to_int(),
      )
      let trials = h1.to_int() + h0.to_int()
      stats.trials() == trials &&
      (if trials == 0 {
        stats.probability_h1() == 0.0 && stats.probability_h0() == 0.0
      } else {
        (stats.probability_h1() + stats.probability_h0() - 1.0).abs() < 1.0e-9 &&
        stats.probability_h1() >= 0.0 &&
        stats.probability_h1() <= 1.0
      })
    },
    count=300,
    seed=82,
  )
}

///|
test "qc: longest_match returns the longest stored prefix of the key" {
  @quickcheck.check(
    (input : (Corpus, Bytes)) => {
      let (c, raw) = input
      let key = Bytes::makei(raw.length().min(6), i => {
        (raw[i].to_int() % 3).to_byte()
      })
      let bw = c.trained()
      let mut best : Int? = None
      for entry in bw.entries() {
        let k = entry.0
        if k.length() <= key.length() && key[:k.length()] == k[:] {
          best = match best {
            Some(b) if b >= k.length() => Some(b)
            _ => Some(k.length())
          }
        }
      }
      match bw.longest_match(key) {
        Some((len, stats)) =>
          best == Some(len) &&
          bw.find(key[:len]).map(s => (s.h1(), s.h0())) ==
          Some((stats.h1(), stats.h0()))
        None => best is None
      }
    },
    count=300,
    seed=83,
  )
}

///|
test "qc: serialized signatures round trip" {
  @quickcheck.check(
    (c : Corpus) => {
      let bw = c.trained()
      match @byteweight.Byteweight::of_bytes(bw.to_bytes()) {
        Ok(back) => {
          let a = bw.entries().map(e => (e.0, e.1.h1(), e.1.h0()))
          let b = back.entries().map(e => (e.0, e.1.h1(), e.1.h0()))
          a == b && back.to_bytes() == bw.to_bytes()
        }
        Err(_) => false
      }
    },
    count=200,
    seed=84,
  )
}

///|
test "qc: of_bytes rejects or accepts corrupted signature files without aborting" {
  @quickcheck.check(
    (input : (Corpus, Int, Byte)) => {
      let (c, pos, b) = input
      let data = c.trained().to_bytes().to_array()
      if data.length() > 0 {
        let p = (pos % data.length()).abs()
        data[p] = b
        data.truncate(data.length() - (pos % 3).abs())
      }
      match @byteweight.Byteweight::of_bytes(Bytes::from_array(data)) {
        Ok(bw) => bw.entries().iter().all(e => e.1.h1() >= 0 && e.1.h0() >= 0)
        Err(_) => true
      }
    },
    count=300,
    seed=85,
  )
}

///|
test "qc: find_positive reports exactly the offsets whose longest match is likely" {
  @quickcheck.check(
    (input : (Corpus, UInt)) => {
      let (c, t) = input
      let threshold = (t % 11).reinterpret_as_int().to_double() / 10.0
      let bw = c.trained()
      let mem = c.memory()
      let length = c.max_length
      let found = bw.find_positive(length~, threshold~, mem)
      let expected = []
      let n = c.data.length()
      for o in 0..<=(n - length) {
        match bw.longest_match(c.data[o:o + length]) {
          Some((_, stats)) if stats.probability_h1() > threshold =>
            expected.push(0x400UL + o.to_uint64())
          _ => ()
        }
      }
      let next = bw.next(length~, threshold~, mem, 0)
      found == expected &&
      next ==
      (if expected.is_empty() {
        None
      } else {
        Some((expected[0] - 0x400UL).to_int())
      })
    },
    count=300,
    seed=86,
  )
}
