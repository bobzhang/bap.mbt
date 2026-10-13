// Property-based robustness tests for the Itanium demangler: it is
// documented to return `None` (and `cxxfilt` the name unchanged) for any
// string that is not a valid mangling, so no input may abort it.

///|
let mangling_alphabet : Array[String] = [
  "_Z", "_", "N", "E", "I", "S", "T", "Z", "L", "P", "R", "O", "K", "V", "C", "F",
  "Y", "D", "d", "p", "v", "i", "c", "l", "m", "b", "f", "a", "St", "Sa", "S_", "S0_",
  "T_", "T0_", "fp_", "Dp", "Dv", "Dt", "Do", "DO", "Dw", "Ut", "Ul", "Tt", "Ty",
  "Tn", "X", "J", "pl", "cv", "sr", "srN", "dn", "on", "3foo", "1a", "0", "9", ".",
  "B", "M", "A", "G", "Gs", "gs", "nw", "na", "il", "tl", "di", "dx", "fL", "C1",
  "D0", "Q", "u", "\u{1F600}", "\u{0}",
]

///|
/// A string made of mangling tokens, biased to start like a mangled name.
struct Token(String) derive(Debug)

///|
impl @quickcheck.Arbitrary for Token with fn arbitrary(size, rs) {
  let n = rs
    .next_uint(limit=(size.min(60) + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let sb = StringBuilder()
  match rs.next_uint(limit=4) {
    0 => ()
    1 => sb.write_string("__Z")
    _ => sb.write_string("_Z")
  }
  for _ in 0..<n {
    sb.write_string(
      mangling_alphabet[rs
      .next_uint(limit=mangling_alphabet.length().reinterpret_as_uint())
      .reinterpret_as_int()],
    )
  }
  Token(sb.to_string())
}

///|
impl @quickcheck.Shrink for Token with fn shrink(t) {
  let Token(s) = t
  let out : Array[Token] = []
  if s.length() > 0 {
    out.push(Token(s.view(end_offset=s.length() / 2).to_owned()))
    out.push(Token(s.view(start_offset=1).to_owned()))
    out.push(Token(s.view(end_offset=s.length() - 1).to_owned()))
  }
  out.iter()
}

///|
/// A real mangled name from the verified corpora, mutated a few times.
struct Mutant {
  original : String
  mutated : String
} derive(Debug)

///|
fn corpus_names() -> Array[String] {
  let out = symbols.map(e => e.0)
  for e in llvm_cases {
    out.push(e.0)
  }
  out
}

///|
let corpus : Array[String] = corpus_names()

///|
impl @quickcheck.Arbitrary for Mutant with fn arbitrary(_size, rs) {
  let original = corpus[rs
    .next_uint(limit=corpus.length().reinterpret_as_uint())
    .reinterpret_as_int()]
  let chars = original.to_array()
  let edits = 1 + rs.next_uint(limit=4).reinterpret_as_int()
  for _ in 0..<edits {
    let len = chars.length()
    let pos = if len == 0 {
      0
    } else {
      rs.next_uint(limit=len.reinterpret_as_uint()).reinterpret_as_int()
    }
    match rs.next_uint(limit=5) {
      0 => if len > 0 { chars.remove(pos) |> ignore }
      1 => {
        let tok = mangling_alphabet[rs
          .next_uint(limit=mangling_alphabet.length().reinterpret_as_uint())
          .reinterpret_as_int()]
        for c in tok.rev() {
          chars.insert(pos, c)
        }
      }
      2 => chars.truncate(pos)
      3 =>
        // duplicate a slice: repeats nested structure
        if len > 0 {
          let end = pos +
            rs
            .next_uint(limit=(len - pos).reinterpret_as_uint())
            .reinterpret_as_int()
          let slice = chars[pos:end].to_owned()
          for c in slice.rev() {
            chars.insert(pos, c)
          }
        }
      _ =>
        if len > 0 {
          chars[pos] = (chars[pos].to_int() ^ 1).unsafe_to_char()
        }
    }
  }
  { original, mutated: String::from_array(chars), }
}

///|
impl @quickcheck.Shrink for Mutant

///|
/// The Itanium <seq-id> of substitution `index`: `S_` is the first, then
/// `S0_`...`S9_`, `SA_`...`SZ_`, `S10_`... (uppercase base 36).
fn substitution(index : Int32) -> String {
  if index == 0 {
    return "S_"
  }
  let digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let mut n = index - 1
  let out : Array[Char] = []
  while true {
    out.push(digits.get_char(n % 36).unwrap())
    n = n / 36
    if n == 0 {
      break
    }
  }
  "S" + String::from_array(out.rev()) + "_"
}

///|
/// `f(int*, int**, ..., int*...*)` with `len` parameters, each a pointer to
/// the previous one through a substitution: the parser stays shallow while
/// the last parameter prints `len` levels deep.
fn substitution_chain(len : Int32) -> String {
  let sb = StringBuilder()
  sb.write_string("_Z1fPi")
  for i in 1..<len {
    sb.write_string("P" + substitution(i - 1))
  }
  sb.to_string()
}

///|
/// Deeply nested instances of the recursive productions.
struct Nest {
  kind : Int32
  depth : Int32
} derive(Debug)

///|
let nest_kinds : Int32 = 12

///|
fn Nest::render(self : Nest) -> String {
  let d = self.depth
  match self.kind {
    0 => "_Z1f" + "P".repeat(d) + "i" // pointer chain
    1 => "_Z1fI" + "1aI".repeat(d) + "i" + "E".repeat(d) + "Evv" // template args
    2 => "_Z1fP" + "A1_".repeat(d) + "i" // array types
    3 => "_Z1f" + "PF".repeat(d) + "v" + "E".repeat(d) // function types
    4 => "_Z1fIX" + "plLi1E".repeat(d) + "Li1EEEvv" // binary expressions
    5 => "_Z" + "Z1f".repeat(d) + "v" + "E1g".repeat(d) + "v" // local names
    6 => substitution_chain(d) // substitutions
    7 => "_Z1f" + "PVK".repeat(d) + "i" // qualified pointers
    8 => "_Z1f" + "U1a".repeat(d) + "i" // vendor qualifiers
    9 => "_Z1fI" + "J".repeat(d) + "i" + "E".repeat(d) + "Evv" // argument packs
    10 => "_Z1f" + "R".repeat(d) + "i" // references (collapse when printed)
    _ => "_Z1fIX" + "ng".repeat(d) + "Li1EEEvv" // prefix expressions
  }
}

///|
impl @quickcheck.Arbitrary for Nest with fn arbitrary(_size, rs) {
  let depth = match rs.next_uint(limit=5) {
    0 => 1 + rs.next_uint(limit=8).reinterpret_as_int()
    // around the printer limit (96) and the parser limit (256)
    1 => 85 + rs.next_uint(limit=20).reinterpret_as_int()
    2 => 245 + rs.next_uint(limit=20).reinterpret_as_int()
    _ => 200 + rs.next_uint(limit=20000).reinterpret_as_int()
  }
  {
    kind: rs
    .next_uint(limit=nest_kinds.reinterpret_as_uint())
    .reinterpret_as_int(),
    depth,
  }
}

///|
impl @quickcheck.Shrink for Nest with fn shrink(n) {
  (if n.depth > 1 { [{ ..n, depth: n.depth / 2, }] } else { [] }).iter()
}

///|
/// `cxxfilt` without options returns the name unchanged exactly when
/// `demangle` rejects it (for names without a leading `.` or `__imp_`).
fn agrees_with_cxxfilt(name : String) -> Bool {
  let plain = !name.has_prefix(".") && !name.has_prefix("__imp_")
  match @itanium.demangle(name) {
    None =>
      !plain ||
      !@itanium.is_itanium_encoding(name) ||
      @itanium.cxxfilt(name) == name
    Some(out) =>
      !@itanium.is_itanium_encoding(name) || @itanium.cxxfilt(name) == out
  }
}

///|
test "qc: token soup never aborts the demangler" {
  @quickcheck.check(
    (t : Token) => {
      let Token(s) = t
      ignore(@itanium.demangle(s, params=false))
      ignore(@itanium.cxxfilt(s, types=true, strip_underscore=true))
      agrees_with_cxxfilt(s)
    },
    observe=t => {
      let Token(s) = t
      [@quickcheck.classify(@itanium.demangle(s) is Some(_), "valid mangling")]
    },
    count=1000,
    seed=61,
  )
}

///|
test "qc: mutated real manglings never abort the demangler" {
  @quickcheck.check(
    (m : Mutant) => {
      ignore(@itanium.demangle(m.mutated, params=false))
      ignore(@itanium.cxxfilt(m.mutated, types=true))
      agrees_with_cxxfilt(m.mutated)
    },
    observe=m => {
      [
        @quickcheck.classify(
          @itanium.demangle(m.mutated) is Some(_),
          "still valid",
        ),
      ]
    },
    count=1000,
    seed=62,
  )
}

///|
test "qc: every prefix of a real mangling is handled" {
  @quickcheck.check(
    (m : Mutant) => {
      let name = m.original
      let mut ok = true
      for i in 0..<=name.length() {
        let prefix = name.view(end_offset=i).to_owned()
        ok = ok && agrees_with_cxxfilt(prefix)
      }
      ok
    },
    filter=m => m.original.has_prefix("_Z"),
    count=100,
    seed=63,
  )
}

///|
test "qc: deeply nested manglings are rejected, not a stack overflow" {
  @quickcheck.check(
    (n : Nest) => {
      let s = n.render()
      let result = @itanium.demangle(s)
      ignore(@itanium.cxxfilt(s, params=false))
      // shallow nestings of every construct are still demangled
      n.depth > 8 || result is Some(_)
    },
    observe=n => {
      [@quickcheck.collect(n.kind), @quickcheck.classify(n.depth > 8, "deep")]
    },
    count=300,
    seed=64,
  )
}

///|
/// Regression (found by "qc: deeply nested manglings are rejected, not a
/// stack overflow"): the recursive parser and printer had no depth bound,
/// so a crafted symbol such as `_Z1f` + 200 `P` + `i` exhausted the stack
/// (a trap on wasm-gc, SIGSEGV on native) instead of being rejected.
test "regression: deep nesting does not overflow the stack" {
  assert_eq(@itanium.demangle("_Z1f" + "P".repeat(200) + "i"), None)
  assert_eq(@itanium.demangle("_Z1f" + "P".repeat(5000) + "!"), None)
  assert_eq(@itanium.demangle(substitution_chain(400)), None)
  assert_eq(
    @itanium.cxxfilt("_Z1f" + "P".repeat(200) + "i"),
    "_Z1f" + "P".repeat(200) + "i",
  )
  // moderate nesting is unaffected
  assert_eq(
    @itanium.demangle("_Z1f" + "P".repeat(20) + "i"),
    Some("f(int" + "*".repeat(20) + ")"),
  )
}

///|
/// Regression (code review): vendor qualifiers (`U <source-name>`) and
/// template argument packs (`J ... E`) recursed through productions that
/// did not count towards the parser limit.
test "regression: vendor qualifiers and argument packs are depth-limited" {
  assert_eq(@itanium.demangle("_Z1f" + "U1a".repeat(100000) + "i"), None)
  assert_eq(
    @itanium.demangle(
      "_Z1fI" + "J".repeat(100000) + "i" + "E".repeat(100000) + "Evv",
    ),
    None,
  )
  assert_eq(
    @itanium.demangle("_Z1fIX" + "ng".repeat(100000) + "Li1EEEvv"),
    None,
  )
  assert_eq(@itanium.demangle("_Z1f" + "R".repeat(100000) + "i"), None)
  assert_eq(@itanium.demangle("_Z1fU1aU1bi"), Some("f(int b a)"))
  assert_eq(@itanium.demangle("_Z1fIJJiEEEvv"), Some("void f<int>()"))
}

///|
test "substitution ids are uppercase base 36" {
  assert_eq(substitution(0), "S_")
  assert_eq(substitution(1), "S0_")
  assert_eq(substitution(10), "S9_")
  assert_eq(substitution(11), "SA_")
  assert_eq(substitution(36), "SZ_")
  assert_eq(substitution(37), "S10_")
  assert_eq(
    @itanium.demangle(substitution_chain(40)),
    Some(
      "f(" + Array::makei(40, i => "int" + "*".repeat(i + 1)).join(", ") + ")",
    ),
  )
}

///|
/// The limits are a compatibility restriction (see `MAX_PARSE_DEPTH` and
/// `MAX_PRINT_DEPTH`): names right at a limit are demangled, one level
/// deeper they are rejected.
test "limits: names at the parser limit (256 levels) are accepted" {
  // `R`-chains nest the parser (n + 2 levels) but collapse when printed
  assert_eq(@itanium.demangle("_Z1f" + "R".repeat(254) + "i"), Some("f(int&)"))
  assert_eq(@itanium.demangle("_Z1f" + "R".repeat(255) + "i"), None)
}

///|
test "limits: names at the printer limit (96 levels) are accepted" {
  // pointer chains print n + 2 levels deep
  assert_eq(
    @itanium.demangle("_Z1f" + "P".repeat(94) + "i"),
    Some("f(int" + "*".repeat(94) + ")"),
  )
  assert_eq(@itanium.demangle("_Z1f" + "P".repeat(95) + "i"), None)
  // substitution chains stay 3 levels deep in the parser and print the
  // last parameter len + 2 levels deep
  assert_true(@itanium.demangle(substitution_chain(94)) is Some(_))
  assert_eq(@itanium.demangle(substitution_chain(95)), None)
  // argument packs print n + 4 levels deep
  assert_eq(
    @itanium.demangle("_Z1fI" + "J".repeat(92) + "i" + "E".repeat(92) + "Evv"),
    Some("void f<int>()"),
  )
  assert_eq(
    @itanium.demangle("_Z1fI" + "J".repeat(93) + "i" + "E".repeat(93) + "Evv"),
    None,
  )
  // vendor qualifiers print n + 2 levels deep
  assert_true(@itanium.demangle("_Z1f" + "U1a".repeat(94) + "i") is Some(_))
  assert_eq(@itanium.demangle("_Z1f" + "U1a".repeat(95) + "i"), None)
}
