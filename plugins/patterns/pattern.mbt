///|
/// A ditted byte pattern (upstream `Pattern`).
///
/// A pattern is described as a sequence of bits or nibbles: `0`, `1` and
/// `.` match a zero, a one or any bit; after the `0x` prefix, each
/// hexadecimal digit matches its four-bit representation and `.` matches
/// any four bits, until the next white space. Sequences may be separated
/// with arbitrary white space; `_` is ignored inside nibble sequences.
///
/// The pattern is split into bytes starting from its end: when the number
/// of bits is not a multiple of eight, the leading extra bits are ignored
/// by the matcher (but are still counted by `weight`), as upstream does.
pub struct Pattern {
  priv repr : String
  priv bits : Array[Int32]
  priv mask : Array[Int32]
  priv pops : Int32
  priv size : Int32
}

///|
priv enum Mode {
  Start
  Wait
  Bin
  Hex
}

///|
/// An ill-formed pattern.
pub(all) suberror PatternError {
  PatternError(String)
} derive(Eq, Debug)

///|
pub extend PatternError with Eq::{not_equal, equal}

///|
pub extend PatternError with Debug::{to_repr}

///|
fn hex_digit(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    'a'..<='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..<='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// Parses a ditted pattern. Fails on a character that is not a
/// hexadecimal digit inside a nibble sequence (upstream raises an
/// exception).
pub fn Pattern::create(repr : String) -> Pattern raise PatternError {
  // the bits and the mask, most significant first
  let bits : Array[Bool] = []
  let mask : Array[Bool] = []
  let push = (b : Bool, m : Bool) => {
    bits.push(b)
    mask.push(m)
  }
  let mut mode = Start
  for c in repr {
    match (mode, c) {
      (Start, '1') => {
        push(true, true)
        mode = Bin
      }
      (Start, '0') => mode = Wait
      (Start, '.') => {
        push(false, false)
        mode = Bin
      }
      (Start, _) => ()
      (Wait, '0') => {
        push(false, true)
        push(false, true)
        mode = Bin
      }
      (Wait, '1') => {
        push(false, true)
        push(true, true)
        mode = Bin
      }
      (Wait, 'x') => mode = Hex
      (Wait, _) => mode = Start
      (Bin, '0') => push(false, true)
      (Bin, '1') => push(true, true)
      (Bin, '.') => push(false, false)
      (Bin, _) => mode = Start
      (Hex, ' ') => mode = Start
      (Hex, '.') =>
        for _ in 0..<4 {
          push(false, false)
        }
      (Hex, '_') => ()
      (Hex, x) =>
        match hex_digit(x) {
          Some(d) =>
            for i in 0..<4 {
              push(((d >> (3 - i)) & 1) == 1, true)
            }
          None => raise PatternError("invalid digit `\{x}' in pattern \{repr}")
        }
    }
  }
  let size = bits.length()
  let nbytes = size / 8
  let skip = size - nbytes * 8
  let byte_of = (xs : Array[Bool], n : Int32) => {
    let mut v = 0
    for i in 0..<8 {
      v = (v << 1) | (if xs[skip + n * 8 + i] { 1 } else { 0 })
    }
    v
  }
  {
    repr,
    bits: Array::makei(nbytes, n => byte_of(bits, n)),
    mask: Array::makei(nbytes, n => byte_of(mask, n)),
    pops: mask.fold(init=0, (n, m) => if m { n + 1 } else { n }),
    size,
  }
}

///|
/// The empty pattern.
pub fn Pattern::empty() -> Pattern {
  { repr: "", bits: [], mask: [], pops: 0, size: 0, }
}

///|
/// The concatenation of two patterns.
pub fn Pattern::concat(self : Pattern, other : Pattern) -> Pattern {
  {
    repr: self.repr + other.repr,
    bits: self.bits + other.bits,
    mask: self.mask + other.mask,
    pops: self.pops + other.pops,
    size: self.size + other.size,
  }
}

///|
/// The number of bytes matched by the pattern.
pub fn Pattern::length(self : Pattern) -> Int32 {
  self.size / 8
}

///|
/// The number of non-masked bits.
pub fn Pattern::weight(self : Pattern) -> Int32 {
  self.pops
}

///|
/// `true` if the byte `data` matches the `pos`-th byte of the pattern.
pub fn Pattern::matches(self : Pattern, pos~ : Int32, data : Int32) -> Bool {
  match (self.mask.get(pos), self.bits.get(pos)) {
    (Some(m), Some(b)) => (data & m) == b
    _ => false
  }
}

///|
/// The textual representation (as written in the patterns file).
pub fn Pattern::to_string(self : Pattern) -> String {
  self.repr
}

///|
pub impl Show for Pattern with fn output(self, logger) {
  logger.write_string(self.repr)
}

///|
pub extend Pattern with Show::{output}
