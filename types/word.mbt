///|
struct Word {
  bits_value : @bitvec.BitVec
  signed_value : Bool
} derive(Eq, Debug)

///|
pub fn Word::from_bitvec(
  value : @bitvec.BitVec,
  signed? : Bool = false,
) -> Word {
  { bits_value: value, signed_value: signed }
}

///|
pub fn Word::to_bitvec(self : Word) -> @bitvec.BitVec {
  self.bits_value
}

///|
pub fn Word::width(self : Word) -> Int {
  self.bits_value.width()
}

///|
pub fn Word::signed(self : Word) -> Word {
  { ..self, signed_value: true }
}

///|
pub fn Word::unsigned(self : Word) -> Word {
  { ..self, signed_value: false }
}

///|
pub fn Word::is_signed(self : Word) -> Bool {
  self.signed_value
}

///|
pub fn Word::of_bool(value : Bool) -> Word {
  Word::from_bitvec(@bitvec.of_bool(value))
}

///|
pub fn Word::of_int(
  width~ : Int,
  value : Int,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.of_int(width~, value))
}

///|
pub fn Word::of_int64(
  width~ : Int,
  value : Int64,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.of_int64(width~, value))
}

///|
pub fn Word::of_uint64(
  width~ : Int,
  value : UInt64,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.of_uint64(width~, value))
}

///|
pub fn Word::from_hex(
  width~ : Int,
  text : StringView,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.from_hex(width~, text))
}

///|
pub fn Word::from_string(text : StringView) -> Word raise @bitvec.BitVecError {
  let source = text.to_owned()
  let signed = match source.split_once(":") {
    Some((_, suffix)) => suffix.has_suffix("s")
    None => false
  }
  Word::from_bitvec(@bitvec.from_string(text), signed~)
}

///|
pub fn Word::from_bytes(
  bytes : BytesView,
  endian~ : @bitvec.Endian,
  width? : Int = -1,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.of_bytes(bytes, endian~, width~))
}

///|
pub fn Word::zero(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.zero(width~))
}

///|
pub fn Word::one(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.one(width~))
}

///|
pub fn Word::ones(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.ones(width~))
}

///|
pub fn Word::b0() -> Word {
  Word::from_bitvec(@bitvec.b0())
}

///|
pub fn Word::b1() -> Word {
  Word::from_bitvec(@bitvec.b1())
}

///|
pub fn Word::is_zero(self : Word) -> Bool {
  self.bits_value.is_zero()
}

///|
pub fn Word::msb(self : Word) -> Bool {
  self.bits_value.msb()
}

///|
pub fn Word::lsb(self : Word) -> Bool {
  self.bits_value.lsb()
}

///|
pub fn Word::is_negative(self : Word) -> Bool {
  self.signed_value && self.msb()
}

///|
pub fn Word::is_positive(self : Word) -> Bool {
  !self.is_zero() && !self.is_negative()
}

///|
pub fn Word::is_non_negative(self : Word) -> Bool {
  !self.is_negative()
}

///|
pub fn Word::is_non_positive(self : Word) -> Bool {
  !self.is_positive()
}

///|
pub fn Word::add(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.add(other.bits_value))
}

///|
pub fn Word::sub(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.sub(other.bits_value))
}

///|
pub fn Word::mul(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.mul(other.bits_value))
}

///|
pub fn Word::div(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.div(other.bits_value))
}

///|
pub fn Word::signed_div(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.sdiv(other.bits_value))
}

///|
pub fn Word::rem(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.rem(other.bits_value))
}

///|
pub fn Word::signed_rem(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.srem(other.bits_value))
}

///|
pub fn Word::gcd(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.gcd(other.bits_value))
}

///|
pub fn Word::gcd_ext(
  self : Word,
  other : Word,
) -> (Word, Word, Word) raise @bitvec.BitVecError {
  let (g, x, y) = self.bits_value.gcd_ext(other.bits_value)
  (Word::from_bitvec(g), Word::from_bitvec(x), Word::from_bitvec(y))
}

///|
pub fn Word::lcm(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.lcm(other.bits_value))
}

///|
pub fn Word::lnot(self : Word) -> Word {
  Word::from_bitvec(self.bits_value.lnot())
}

///|
pub fn Word::neg(self : Word) -> Word {
  Word::from_bitvec(self.bits_value.neg())
}

///|
pub fn Word::bit_and(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_and(other.bits_value))
}

///|
pub fn Word::bit_or(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_or(other.bits_value))
}

///|
pub fn Word::bit_xor(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_xor(other.bits_value))
}

///|
pub fn Word::lshift(self : Word, amount : Int) -> Word {
  Word::from_bitvec(self.bits_value.lshift(amount))
}

///|
pub fn Word::rshift(self : Word, amount : Int) -> Word {
  Word::from_bitvec(self.bits_value.rshift(amount))
}

///|
pub fn Word::arshift(self : Word, amount : Int) -> Word {
  Word::from_bitvec(self.bits_value.arshift(amount))
}

///|
pub fn Word::concat(self : Word, low : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.concat(low.bits_value))
}

///|
pub fn Word::extract(
  self : Word,
  hi? : Int = -1,
  lo? : Int = 0,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.extract(hi~, lo~))
}

///|
pub fn Word::widen(self : Word, width~ : Int) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.widen(width~))
}

///|
pub fn Word::truncate(
  self : Word,
  width~ : Int,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.truncate(width~))
}

///|
pub fn Word::to_uint64(self : Word) -> UInt64 raise @bitvec.BitVecError {
  self.bits_value.to_uint64()
}

///|
pub fn Word::compare_unsigned(
  self : Word,
  other : Word,
) -> Int raise @bitvec.BitVecError {
  self.bits_value.compare_unsigned(other.bits_value)
}

///|
pub fn Word::compare_signed(
  self : Word,
  other : Word,
) -> Int raise @bitvec.BitVecError {
  self.bits_value.compare_signed(other.bits_value)
}

///|
pub fn Word::to_hex(self : Word, prefix? : Bool = true) -> String {
  self.bits_value.to_hex(prefix~)
}

///|
fn char_is_zero(text : String, index : Int) -> Bool {
  match text.get_char(index) {
    Some(c) => c == '0'
    None => false
  }
}

///|
fn upper_hex_char(c : Char) -> Char {
  if c >= 'a' && c <= 'f' {
    (c.to_int() - 'a' + 'A').unsafe_to_char()
  } else {
    c
  }
}

///|
fn canonical_hex_digits(value : @bitvec.BitVec) -> String {
  let raw = value.to_hex(prefix=false)
  let mut start = 0
  while start + 1 < raw.length() && char_is_zero(raw, start) {
    start = start + 1
  }
  let builder = StringBuilder()
  for c in raw[start:] {
    builder.write_char(upper_hex_char(c))
  }
  builder.to_string()
}

///|
fn hex_digit_needs_prefix(c : Char) -> Bool {
  c >= 'A' && c <= 'F'
}

///|
fn should_prefix_hex(digits : String) -> Bool {
  if digits.length() > 1 {
    true
  } else {
    match digits.get_char(0) {
      Some(c) => hex_digit_needs_prefix(c)
      None => false
    }
  }
}

///|
pub fn Word::to_string(self : Word) -> String {
  let negative = self.is_negative()
  let magnitude = if negative { self.bits_value.neg() } else { self.bits_value }
  let digits = canonical_hex_digits(magnitude)
  let prefix = if should_prefix_hex(digits) { "0x" } else { "" }
  let sign = if negative { "-" } else { "" }
  let suffix = if self.signed_value { "s" } else { "u" }
  "\{sign}\{prefix}\{digits}:\{self.width()}\{suffix}"
}

///|
pub fn Word::to_bytes(self : Word, endian~ : @bitvec.Endian) -> Bytes {
  self.bits_value.to_bytes(endian~)
}
