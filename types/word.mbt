///|
struct Word(@bitvec.BitVec) derive(Eq, Debug)

///|
pub fn Word::from_bitvec(value : @bitvec.BitVec) -> Word {
  Word(value)
}

///|
pub fn Word::to_bitvec(self : Word) -> @bitvec.BitVec {
  self.0
}

///|
pub fn Word::width(self : Word) -> Int {
  self.0.width()
}

///|
pub fn Word::of_bool(value : Bool) -> Word {
  Word(@bitvec.of_bool(value))
}

///|
pub fn Word::of_int(
  width~ : Int,
  value : Int,
) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.of_int(width~, value))
}

///|
pub fn Word::of_int64(
  width~ : Int,
  value : Int64,
) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.of_int64(width~, value))
}

///|
pub fn Word::of_uint64(
  width~ : Int,
  value : UInt64,
) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.of_uint64(width~, value))
}

///|
pub fn Word::from_hex(
  width~ : Int,
  text : StringView,
) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.from_hex(width~, text))
}

///|
pub fn Word::from_bytes(
  bytes : BytesView,
  endian~ : @bitvec.Endian,
  width? : Int = -1,
) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.of_bytes(bytes, endian~, width~))
}

///|
pub fn Word::zero(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.zero(width~))
}

///|
pub fn Word::one(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.one(width~))
}

///|
pub fn Word::ones(width~ : Int) -> Word raise @bitvec.BitVecError {
  Word(@bitvec.ones(width~))
}

///|
pub fn Word::b0() -> Word {
  Word(@bitvec.b0())
}

///|
pub fn Word::b1() -> Word {
  Word(@bitvec.b1())
}

///|
pub fn Word::is_zero(self : Word) -> Bool {
  self.0.is_zero()
}

///|
pub fn Word::msb(self : Word) -> Bool {
  self.0.msb()
}

///|
pub fn Word::lsb(self : Word) -> Bool {
  self.0.lsb()
}

///|
pub fn Word::add(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.add(other.0))
}

///|
pub fn Word::sub(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.sub(other.0))
}

///|
pub fn Word::mul(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.mul(other.0))
}

///|
pub fn Word::div(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.div(other.0))
}

///|
pub fn Word::signed_div(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.sdiv(other.0))
}

///|
pub fn Word::rem(self : Word, other : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.rem(other.0))
}

///|
pub fn Word::signed_rem(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.srem(other.0))
}

///|
pub fn Word::lnot(self : Word) -> Word {
  Word(self.0.lnot())
}

///|
pub fn Word::neg(self : Word) -> Word {
  Word(self.0.neg())
}

///|
pub fn Word::bit_and(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.bit_and(other.0))
}

///|
pub fn Word::bit_or(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.bit_or(other.0))
}

///|
pub fn Word::bit_xor(
  self : Word,
  other : Word,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.bit_xor(other.0))
}

///|
pub fn Word::lshift(self : Word, amount : Int) -> Word {
  Word(self.0.lshift(amount))
}

///|
pub fn Word::rshift(self : Word, amount : Int) -> Word {
  Word(self.0.rshift(amount))
}

///|
pub fn Word::arshift(self : Word, amount : Int) -> Word {
  Word(self.0.arshift(amount))
}

///|
pub fn Word::concat(self : Word, low : Word) -> Word raise @bitvec.BitVecError {
  Word(self.0.concat(low.0))
}

///|
pub fn Word::extract(
  self : Word,
  hi? : Int = -1,
  lo? : Int = 0,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.extract(hi~, lo~))
}

///|
pub fn Word::widen(self : Word, width~ : Int) -> Word raise @bitvec.BitVecError {
  Word(self.0.widen(width~))
}

///|
pub fn Word::truncate(
  self : Word,
  width~ : Int,
) -> Word raise @bitvec.BitVecError {
  Word(self.0.truncate(width~))
}

///|
pub fn Word::to_uint64(self : Word) -> UInt64 raise @bitvec.BitVecError {
  self.0.to_uint64()
}

///|
pub fn Word::compare_unsigned(
  self : Word,
  other : Word,
) -> Int raise @bitvec.BitVecError {
  self.0.compare_unsigned(other.0)
}

///|
pub fn Word::compare_signed(
  self : Word,
  other : Word,
) -> Int raise @bitvec.BitVecError {
  self.0.compare_signed(other.0)
}

///|
pub fn Word::to_hex(self : Word, prefix? : Bool = true) -> String {
  self.0.to_hex(prefix~)
}

///|
pub fn Word::to_string(self : Word) -> String {
  self.0.to_string()
}

///|
pub fn Word::to_bytes(self : Word, endian~ : @bitvec.Endian) -> Bytes {
  self.0.to_bytes(endian~)
}
