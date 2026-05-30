///|
struct Word {
  bits_value : @bitvec.BitVec
  signed_value : Bool
} derive(Eq, Debug)

///|
pub(all) enum WordValueFormat {
  WordHex
  WordDec
  WordOct
  WordBin
} derive(Eq, Debug)

///|
pub(all) enum WordLetterCase {
  WordUpperCase
  WordLowerCase
} derive(Eq, Debug)

///|
pub(all) enum WordPrefix {
  WordAutoPrefix
  WordBasePrefix
  WordNoPrefix
  WordCustomPrefix(String)
} derive(Eq, Debug)

///|
pub(all) enum WordSuffix {
  WordNoSuffix
  WordFullSuffix
  WordSizeSuffix
} derive(Eq, Debug)

///|
pub fn Word::from_bitvec(
  value : @bitvec.BitVec,
  signed? : Bool = false,
) -> Word {
  { bits_value: value, signed_value: signed }
}

///|
pub fn Word::create(
  value : @bitvec.BitVec,
  width : Int,
) -> Word raise @bitvec.BitVecError {
  let resized = if width >= value.width() {
    value.widen(width~)
  } else {
    value.truncate(width~)
  }
  Word::from_bitvec(resized)
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
pub fn Word::bitwidth(self : Word) -> Int {
  self.width()
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
pub fn Word::of_int32(
  value : Int,
  width? : Int = 32,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(@bitvec.of_int(width~, value))
}

///|
pub fn Word::of_int64(
  value : Int64,
  width? : Int = 64,
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
pub fn Word::of_binary(
  endian : @bitvec.Endian,
  bytes : BytesView,
  width? : Int = -1,
) -> Word raise @bitvec.BitVecError {
  Word::from_bytes(bytes, endian~, width~)
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
pub fn Word::is_one(self : Word) -> Bool {
  self.lsb() && self.bits_value.rshift(1).is_zero()
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
fn validate_word(check : Bool, message : String) -> Result[Unit, String] {
  if check {
    Ok(())
  } else {
    Err(message)
  }
}

///|
pub fn Word::validate_positive(self : Word) -> Result[Unit, String] {
  validate_word(self.is_positive(), "expects a positive number")
}

///|
pub fn Word::validate_non_positive(self : Word) -> Result[Unit, String] {
  validate_word(self.is_non_positive(), "expects a non positive number")
}

///|
pub fn Word::validate_negative(self : Word) -> Result[Unit, String] {
  validate_word(self.is_negative(), "expects a negative number")
}

///|
pub fn Word::validate_non_negative(self : Word) -> Result[Unit, String] {
  validate_word(self.is_non_negative(), "expects a non negative number")
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
  let bits = if self.signed_value || other.signed_value {
    self.bits_value.sdiv(other.bits_value)
  } else {
    self.bits_value.div(other.bits_value)
  }
  Word::from_bitvec(bits)
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
  let bits = if self.signed_value || other.signed_value {
    self.bits_value.srem(other.bits_value)
  } else {
    self.bits_value.rem(other.bits_value)
  }
  Word::from_bitvec(bits)
}

///|
pub fn Word::signed_rem(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.srem(other.bits_value))
}

///|
pub fn Word::modulo(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  self.rem(other)
}

///|
pub fn Word::gcd(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.gcd(other.bits_value))
}

///|
pub fn Word::gcd_exn(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  self.gcd(other)
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
pub fn Word::gcdext(
  self : Word,
  other : Word,
) -> (Word, Word, Word) raise @bitvec.BitVecError {
  self.gcd_ext(other)
}

///|
pub fn Word::gcdext_exn(
  self : Word,
  other : Word,
) -> (Word, Word, Word) raise @bitvec.BitVecError {
  self.gcd_ext(other)
}

///|
pub fn Word::lcm(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.lcm(other.bits_value))
}

///|
pub fn Word::lcm_exn(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  self.lcm(other)
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
pub fn Word::abs(self : Word) -> Word {
  Word::from_bitvec(self.bits_value.abs_signed())
}

///|
pub fn Word::succ(self : Word) -> Word {
  Word::from_bitvec(self.bits_value.succ())
}

///|
pub fn Word::pred(self : Word) -> Word {
  Word::from_bitvec(self.bits_value.pred())
}

///|
pub fn Word::nsucc(self : Word, count : Int) -> Word {
  let delta = try! @bitvec.of_int(width=self.width(), count)
  Word::from_bitvec(try! self.bits_value.add(delta))
}

///|
pub fn Word::npred(self : Word, count : Int) -> Word {
  let delta = try! @bitvec.of_int(width=self.width(), count)
  Word::from_bitvec(try! self.bits_value.sub(delta))
}

///|
pub fn Word::memref(
  self : Word,
  disp? : Int = 0,
  index? : Int = 0,
  scale? : Size = R8,
) -> Word {
  self.nsucc(scale.in_bytes() * index + disp)
}

///|
pub fn Word::bit_and(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_and(other.bits_value))
}

///|
pub fn Word::logand(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  self.bit_and(other)
}

///|
pub fn Word::bit_or(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_or(other.bits_value))
}

///|
pub fn Word::logor(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  self.bit_or(other)
}

///|
pub fn Word::bit_xor(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word::from_bitvec(self.bits_value.bit_xor(other.bits_value))
}

///|
pub fn Word::logxor(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  self.bit_xor(other)
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
pub fn Word::extract_exn(
  self : Word,
  hi? : Int = -1,
  lo? : Int = 0,
) -> Word raise @bitvec.BitVecError {
  self.extract(hi~, lo~)
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
let max_int_as_uint64 : UInt64 = 0x7fffffff

///|
let min_int_value : Int64 = -0x80000000L

///|
let max_int_value : Int64 = 0x7fffffffL

///|
fn word_low_mask(width : Int) -> UInt64 {
  if width <= 0 {
    0
  } else if width >= 64 {
    UInt64::lnot(0)
  } else {
    ((1 : UInt64) << width) - 1
  }
}

///|
fn Word::word_unsigned_bits64(self : Word) -> UInt64 raise @bitvec.BitVecError {
  self.bits_value.to_uint64()
}

///|
fn Word::signed_int64_value(self : Word) -> Int64 raise @bitvec.BitVecError {
  let raw = self.word_unsigned_bits64()
  if self.width() >= 64 || !self.msb() {
    raw.reinterpret_as_int64()
  } else {
    let mask = word_low_mask(self.width())
    (raw | UInt64::lnot(mask)).reinterpret_as_int64()
  }
}

///|
pub fn Word::to_uint64(self : Word) -> UInt64 raise @bitvec.BitVecError {
  self.bits_value.to_uint64()
}

///|
pub fn Word::to_int64(self : Word) -> Int64 raise @bitvec.BitVecError {
  if self.signed_value {
    self.signed_int64_value()
  } else {
    self.word_unsigned_bits64().reinterpret_as_int64()
  }
}

///|
pub fn Word::to_int64_exn(self : Word) -> Int64 raise @bitvec.BitVecError {
  self.to_int64()
}

///|
pub fn Word::to_int32(self : Word) -> Int raise @bitvec.BitVecError {
  if self.signed_value {
    let value = self.signed_int64_value()
    if value < min_int_value || value > max_int_value {
      raise InvalidWidth(self.width())
    }
    value.to_int()
  } else {
    let raw = self.word_unsigned_bits64()
    if raw > 0xffffffff {
      raise InvalidWidth(self.width())
    }
    raw.to_int()
  }
}

///|
pub fn Word::to_int32_exn(self : Word) -> Int raise @bitvec.BitVecError {
  self.to_int32()
}

///|
pub fn Word::to_int(self : Word) -> Int raise @bitvec.BitVecError {
  if self.signed_value {
    let value = self.signed_int64_value()
    if value < min_int_value || value > max_int_value {
      raise InvalidWidth(self.width())
    }
    value.to_int()
  } else {
    let raw = self.word_unsigned_bits64()
    if raw > max_int_as_uint64 {
      raise InvalidWidth(self.width())
    }
    raw.to_int()
  }
}

///|
pub fn Word::to_int_exn(self : Word) -> Int raise @bitvec.BitVecError {
  self.to_int()
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
fn WordValueFormat::base(self : WordValueFormat) -> Int {
  match self {
    WordHex => 16
    WordDec => 10
    WordOct => 8
    WordBin => 2
  }
}

///|
fn WordValueFormat::base_prefix(self : WordValueFormat) -> String {
  match self {
    WordHex => "0x"
    WordOct => "0o"
    WordBin => "0b"
    WordDec => ""
  }
}

///|
fn base_digit_char(digit : Int, letter_case : WordLetterCase) -> Char {
  if digit < 10 {
    (digit + '0').unsafe_to_char()
  } else {
    let base = match letter_case {
      WordUpperCase => 'A'
      WordLowerCase => 'a'
    }
    (digit - 10 + base.to_int()).unsafe_to_char()
  }
}

///|
fn digit_char_value(digit : Char) -> Int {
  if digit >= '0' && digit <= '9' {
    digit.to_int() - '0'
  } else if digit >= 'A' && digit <= 'F' {
    digit.to_int() - 'A' + 10
  } else if digit >= 'a' && digit <= 'f' {
    digit.to_int() - 'a' + 10
  } else {
    0
  }
}

///|
fn bitvec_to_base_string(
  value : @bitvec.BitVec,
  base : Int,
  letter_case : WordLetterCase,
) -> String {
  let digits : Array[Int] = [0]
  for offset in 0..<value.width() {
    let bit = value.width() - offset - 1
    let mut carry = if value.nth(bit) { 1 } else { 0 }
    for i in 0..<digits.length() {
      let next = digits[i] * 2 + carry
      digits[i] = next % base
      carry = next / base
    }
    while carry > 0 {
      digits.push(carry % base)
      carry = carry / base
    }
  }
  let builder = StringBuilder()
  for offset in 0..<digits.length() {
    let i = digits.length() - offset - 1
    builder.write_char(base_digit_char(digits[i], letter_case))
  }
  builder.to_string()
}

///|
fn word_digits_need_auto_prefix(
  format : WordValueFormat,
  digits : String,
) -> Bool {
  match format {
    WordDec => false
    WordBin | WordOct => digits.length() > 1
    WordHex =>
      if digits.length() > 1 {
        true
      } else {
        match digits.get_char(0) {
          Some(digit) => digit_char_value(digit) >= 10
          None => false
        }
      }
  }
}

///|
fn word_prefix_text(
  format : WordValueFormat,
  prefix : WordPrefix,
  digits : String,
) -> String {
  match prefix {
    WordNoPrefix => ""
    WordCustomPrefix(text) => text
    WordBasePrefix => format.base_prefix()
    WordAutoPrefix =>
      if word_digits_need_auto_prefix(format, digits) {
        format.base_prefix()
      } else {
        ""
      }
  }
}

///|
fn Word::unsigned_magnitude(self : Word) -> @bitvec.BitVec {
  if self.is_negative() {
    self.bits_value.neg()
  } else {
    self.bits_value
  }
}

///|
fn Word::format_suffix(self : Word, suffix : WordSuffix) -> String {
  match suffix {
    WordNoSuffix => ""
    WordSizeSuffix => ":\{self.width()}"
    WordFullSuffix => {
      let sign = if self.is_signed() { "s" } else { "u" }
      ":\{self.width()}\{sign}"
    }
  }
}

///|
pub fn Word::format_value(
  self : Word,
  format? : WordValueFormat = WordHex,
  letter_case? : WordLetterCase = WordUpperCase,
  prefix? : WordPrefix = WordAutoPrefix,
  suffix? : WordSuffix = WordNoSuffix,
) -> String {
  let magnitude = self.unsigned_magnitude()
  let digits = bitvec_to_base_string(magnitude, format.base(), letter_case)
  let sign = if self.is_negative() { "-" } else { "" }
  "\{sign}\{word_prefix_text(format, prefix, digits)}\{digits}\{self.format_suffix(suffix)}"
}

///|
pub fn Word::string_of_value(self : Word, hex? : Bool = true) -> String {
  if hex {
    self.format_value(
      format=WordHex,
      letter_case=WordLowerCase,
      prefix=WordNoPrefix,
    )
  } else {
    self.format_value(format=WordDec)
  }
}

///|
pub fn Word::to_hex(self : Word, prefix? : Bool = true) -> String {
  self.bits_value.to_hex(prefix~)
}

///|
pub fn Word::to_string(self : Word) -> String {
  self.format_value(suffix=WordFullSuffix)
}

///|
pub fn Word::to_bytes(self : Word, endian~ : @bitvec.Endian) -> Bytes {
  self.bits_value.to_bytes(endian~)
}

///|
pub fn Word::enum_chars(self : Word, endian~ : @bitvec.Endian) -> Bytes {
  self.to_bytes(endian~)
}

///|
pub fn Word::enum_bytes(self : Word, endian~ : @bitvec.Endian) -> Array[Word] {
  let chars = self.enum_chars(endian~)
  let words = []
  for i in 0..<chars.length() {
    words.push(try! Word::of_int(width=8, chars[i].to_int()))
  }
  words
}

///|
pub fn Word::enum_bits(self : Word, endian~ : @bitvec.Endian) -> Array[Bool] {
  let chars = self.enum_chars(endian~)
  let bits = []
  for i in 0..<chars.length() {
    let byte = chars[i].to_int()
    for j in 0..<8 {
      let shift = 7 - j
      bits.push(((byte >> shift) & 1) == 1)
    }
  }
  bits
}
