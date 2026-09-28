// Property-based tests for `regular`: the byte codecs round trip, the
// length-prefixed reader is robust on arbitrary input, and the prefix and
// suffix tries agree with a map model.

///|
test "qc: hex and sexp atom encodings round trip" {
  @quickcheck.check(
    (b : Bytes) => {
      let hex = @regular.bytes_to_hex(b)
      hex.length() == 2 * b.length() &&
      @regular.bytes_from_hex(hex) == Ok(b) &&
      @regular.bytes_from_hex(hex.to_upper()) == Ok(b) &&
      @regular.bytes_from_sexp_atom(@regular.bytes_to_sexp_atom(b)) == Ok(b)
    },
    count=300,
    seed=91,
  )
}

///|
test "qc: bytes_from_hex rejects odd lengths and non-hex digits" {
  @quickcheck.check(
    (s : String) => {
      let all_hex = s.iter().all(c => c is ('0'..='9' | 'a'..='f' | 'A'..='F'))
      match @regular.bytes_from_hex(s) {
        Ok(b) => all_hex && s.length() % 2 == 0 && b.length() * 2 == s.length()
        Err(_) => !all_hex || s.length() % 2 != 0
      }
    },
    count=300,
    seed=92,
  )
}

///|
test "qc: length-prefixed binary form round trips, also when concatenated" {
  @quickcheck.check(
    (input : (Bytes, Bytes)) => {
      let (a, b) = input
      let data = @regular.bytes_bin_write(a) + @regular.bytes_bin_write(b)
      match @regular.bytes_bin_read(data) {
        Ok((first, next)) =>
          first == a &&
          next == @regular.bytes_bin_size(a) &&
          @regular.bytes_bin_read(data, pos=next) == Ok((b, data.length()))
        Err(_) => false
      }
    },
    count=300,
    seed=93,
  )
}

///|
test "qc: bytes_bin_read never reads out of bounds" {
  @quickcheck.check(
    (input : (Bytes, Int, UInt)) => {
      let (payload, pos, len) = input
      // a length prefix that may claim far more bytes than there are,
      // often just below 2^31 where the end offset overflows
      let len = if len % 3 == 0 { 0x7fff_ffffU - len / 3 % 8 } else { len }
      let prefix = Bytes::makei(4, i => ((len >> (8 * i)) & 0xff).to_byte())
      let data = prefix + payload
      let pos = if pos % 2 == 0 { 0 } else { pos }
      match @regular.bytes_bin_read(data, pos~) {
        Ok((got, next)) =>
          pos >= 0 &&
          next <= data.length() &&
          got.length() == next - pos - 4 &&
          got == data[pos + 4:next].to_owned()
        Err(_) => true
      }
    },
    observe=input => {
      [
        @quickcheck.classify(input.2 % 3 == 0, "length near Int max"),
        @quickcheck.classify(
          input.2 % 3 != 0 && input.2 >= 0x8000_0000U,
          "length >= 2^31",
        ),
      ]
    },
    count=500,
    seed=94,
  )
}

///|
/// Regression (found by "qc: bytes_bin_read never reads out of bounds"): a
/// length prefix near 2^31 made `pos + 4 + len` overflow to a negative
/// Int, which passed the bounds check and aborted on the slice.
test "regression: bytes_bin_read rejects a length that overflows the end offset" {
  assert_true(@regular.bytes_bin_read(b"\xff\xff\xff\x7f") is Err(_))
  assert_true(@regular.bytes_bin_read(b"\xfd\xff\xff\x7f\x00") is Err(_))
  assert_true(
    @regular.bytes_bin_read(b"\x00\x00\x00\x00", pos=0x7fff_fffe) is Err(_),
  )
  assert_eq(@regular.bytes_bin_read(b"\x01\x00\x00\x00\x2a"), Ok((b"\x2a", 5)))
}

///|
test "qc: bytes_sub agrees with slicing" {
  @quickcheck.check(
    (input : (Bytes, Int, Int)) => {
      let (b, pos, len) = input
      let n = b.length()
      let pos = pos % (n + 3)
      let len = len % (n + 3)
      let valid = pos >= 0 && len >= 0 && pos + len <= n
      match @regular.bytes_sub(b, pos, len) {
        Ok(sub) => valid && sub == b[pos:pos + len].to_owned()
        Err(_) => !valid
      }
    },
    count=300,
    seed=95,
  )
}

///|
/// A sequence of trie operations over short keys from a small alphabet
/// (including non-ASCII characters) so that keys share prefixes.
struct TrieOps {
  ops : Array[(Bool, String, Int)] // (add?, key, value)
  probe : String
} derive(Debug)

///|
let trie_alphabet : Array[String] = ["a", "b", "ab", "\u{e9}", "\u{1F600}", "x"]

///|
fn gen_key(rs : @splitmix.RandomState) -> String {
  let n = rs.next_uint(limit=4).reinterpret_as_int()
  let sb = StringBuilder()
  for _ in 0..<n {
    sb.write_string(trie_alphabet[rs.next_uint(limit=6).reinterpret_as_int()])
  }
  sb.to_string()
}

///|
impl @quickcheck.Arbitrary for TrieOps with fn arbitrary(size, rs) {
  let count = rs
    .next_uint(limit=(size.min(20) + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let ops : Array[(Bool, String, Int)] = []
  for i in 0..<count {
    let add = rs.next_uint(limit=3) != 0
    // removals mostly target a key added earlier
    let key = if !add && !ops.is_empty() && rs.next_uint(limit=4) != 0 {
      ops[rs
      .next_uint(limit=ops.length().reinterpret_as_uint())
      .reinterpret_as_int()].1
    } else {
      gen_key(rs)
    }
    ops.push((add, key, i))
  }
  { ops, probe: gen_key(rs) + gen_key(rs), }
}

///|
impl @quickcheck.Shrink for TrieOps with fn shrink(t) {
  Array::makei(t.ops.length(), i => {
    let ops = t.ops.copy()
    ops.remove(i) |> ignore
    { ..t, ops, }
  }).iter()
}

///|
fn TrieOps::model(self : TrieOps) -> Map[String, Int] {
  let m : Map[String, Int] = Map([])
  for op in self.ops {
    let (add, key, value) = op
    if add {
      m[key] = value
    } else {
      m.remove(key)
    }
  }
  m
}

///|
fn utf8_length(s : String) -> Int {
  @utf8.encode(s).length()
}

///|
test "qc: PrefixTrie agrees with a map model" {
  @quickcheck.check(
    (t : TrieOps) => {
      let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
      for op in t.ops {
        let (add, key, value) = op
        if add {
          trie.add(key, value)
        } else {
          trie.remove(key)
        }
      }
      let model = t.model()
      // longest stored prefix of the probe, measured in UTF-8 bytes
      let mut best : (Int, Int)? = None
      model.each((key, value) => {
        if t.probe.has_prefix(key) {
          let len = utf8_length(key)
          best = match best {
            Some((b, _)) if b >= len => best
            _ => Some((len, value))
          }
        }
      })
      let folded = trie.fold(init=Map([]), f=(acc : Map[String, Int], k, v) => {
        acc[k] = v
        acc
      })
      trie.length() == model.length() &&
      model.iter().all(kv => trie.find(kv.0) == Some(kv.1)) &&
      trie.find(t.probe) == model.get(t.probe) &&
      trie.longest_match(t.probe) == best &&
      folded == model
    },
    count=300,
    seed=96,
  )
}

///|
test "qc: PrefixTrie is_empty agrees with length" {
  @quickcheck.check(
    (t : TrieOps) => {
      let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
      let suffix : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
      for op in t.ops {
        let (add, key, value) = op
        if add {
          trie.add(key, value)
          suffix.add(key, value)
        } else {
          trie.remove(key)
          suffix.remove(key)
        }
      }
      trie.is_empty() == (trie.length() == 0) &&
      suffix.is_empty() == (suffix.length() == 0)
    },
    observe=t => {
      [
        @quickcheck.classify(t.model().is_empty(), "empty model"),
        @quickcheck.classify(t.ops.iter().any(op => !op.0), "has removals"),
      ]
    },
    count=300,
    seed=97,
  )
}

///|
test "qc: SuffixTrie agrees with a map model" {
  @quickcheck.check(
    (t : TrieOps) => {
      let trie : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
      for op in t.ops {
        let (add, key, value) = op
        if add {
          trie.add(key, value)
        } else {
          trie.remove(key)
        }
      }
      let model = t.model()
      let mut best : (Int, Int)? = None
      model.each((key, value) => {
        if t.probe.has_suffix(key) {
          let len = utf8_length(key)
          best = match best {
            Some((b, _)) if b >= len => best
            _ => Some((len, value))
          }
        }
      })
      let folded = trie.fold(init=Map([]), f=(acc : Map[String, Int], k, v) => {
        acc[k] = v
        acc
      })
      trie.length() == model.length() &&
      model.iter().all(kv => trie.find(kv.0) == Some(kv.1)) &&
      trie.longest_match(t.probe) == best &&
      folded == model
    },
    count=300,
    seed=98,
  )
}

///|
/// Regression (found by "qc: PrefixTrie is_empty agrees with length"):
/// `remove` keeps the path to a removed key, so `is_empty` (which only
/// looked at the root) reported a trie with no bindings as non-empty.
test "regression: a trie is empty again after removing its only key" {
  let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
  trie.add("\u{e9}aba", 1)
  trie.remove("\u{e9}aba")
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
  trie.add("ab", 2)
  assert_true(!trie.is_empty())
  let suffix : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
  suffix.add("abc", 3)
  suffix.remove("abc")
  assert_true(suffix.is_empty())
}

///|
/// Regression (code review): `is_empty` and `length` recursed once per key
/// byte, so a long (but otherwise supported) key exhausted the stack.
test "regression: tries with very long keys" {
  let key = "ab".repeat(100000)
  let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
  trie.add(key, 1)
  trie.add("a", 2)
  assert_true(!trie.is_empty())
  assert_eq(trie.length(), 2)
  assert_eq(trie.find(key), Some(1))
  assert_eq(trie.longest_match(key + "c"), Some((key.length(), 1)))
  trie.remove(key)
  trie.remove("a")
  assert_eq(trie.length(), 0)
  assert_true(trie.is_empty())
  let suffix : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
  suffix.add(key, 3)
  assert_true(!suffix.is_empty())
  assert_eq(suffix.length(), 1)
  suffix.remove(key)
  assert_true(suffix.is_empty())
}
