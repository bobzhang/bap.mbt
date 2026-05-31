///|
struct AddrR32 {
  value : Int
} derive(Eq, Debug)

///|
struct AddrR64 {
  value : Int64
} derive(Eq, Debug)

///|
fn addr_r32_shift_amount(amount : Int) -> Int {
  amount & 31
}

///|
fn addr_r64_shift_amount(amount : Int64) -> Int {
  (amount.reinterpret_as_uint64() & 63UL).to_int()
}

///|
pub fn AddrR32::of_int32(value : Int) -> AddrR32 {
  { value, }
}

///|
pub fn AddrR32::create(word : Word) -> Result[AddrR32, String] {
  try word.to_int32() catch {
    _ => Err("address does not fit into 32 bits")
  } noraise {
    value => Ok(AddrR32::of_int32(value))
  }
}

///|
pub fn AddrR32::create_exn(word : Word) -> AddrR32 raise @bitvec.BitVecError {
  AddrR32::of_int32(word.to_int32())
}

///|
pub fn AddrR32::to_int32(self : AddrR32) -> Int {
  self.value
}

///|
pub fn AddrR32::to_uint(self : AddrR32) -> UInt {
  self.value.reinterpret_as_uint()
}

///|
pub fn AddrR32::to_word(self : AddrR32) -> Word raise @bitvec.BitVecError {
  Word::of_int32(self.value)
}

///|
pub fn AddrR32::zero() -> AddrR32 {
  { value: 0 }
}

///|
pub fn AddrR32::one() -> AddrR32 {
  { value: 1 }
}

///|
pub fn AddrR32::succ(self : AddrR32) -> AddrR32 {
  { value: self.value + 1 }
}

///|
pub fn AddrR32::pred(self : AddrR32) -> AddrR32 {
  { value: self.value - 1 }
}

///|
pub fn AddrR32::abs(self : AddrR32) -> AddrR32 {
  { value: self.value.abs() }
}

///|
pub fn AddrR32::neg(self : AddrR32) -> AddrR32 {
  { value: -self.value }
}

///|
pub fn AddrR32::add(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value + other.value }
}

///|
pub fn AddrR32::sub(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value - other.value }
}

///|
pub fn AddrR32::mul(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value * other.value }
}

///|
pub fn AddrR32::div(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value / other.value }
}

///|
pub fn AddrR32::modulo(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value % other.value }
}

///|
pub fn AddrR32::lnot(self : AddrR32) -> AddrR32 {
  { value: self.value.lnot() }
}

///|
pub fn AddrR32::logand(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value & other.value }
}

///|
pub fn AddrR32::logor(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value | other.value }
}

///|
pub fn AddrR32::logxor(self : AddrR32, other : AddrR32) -> AddrR32 {
  { value: self.value ^ other.value }
}

///|
pub fn AddrR32::lshift(self : AddrR32, amount : AddrR32) -> AddrR32 {
  { value: self.value << addr_r32_shift_amount(amount.value) }
}

///|
pub fn AddrR32::rshift(self : AddrR32, amount : AddrR32) -> AddrR32 {
  let shifted = self.value.reinterpret_as_uint() >>
    addr_r32_shift_amount(amount.value)
  { value: shifted.reinterpret_as_int() }
}

///|
pub fn AddrR32::arshift(self : AddrR32, amount : AddrR32) -> AddrR32 {
  { value: self.value >> addr_r32_shift_amount(amount.value) }
}

///|
pub fn AddrR64::of_int64(value : Int64) -> AddrR64 {
  { value, }
}

///|
pub fn AddrR64::create(word : Word) -> Result[AddrR64, String] {
  try word.to_int64() catch {
    _ => Err("address does not fit into 64 bits")
  } noraise {
    value => Ok(AddrR64::of_int64(value))
  }
}

///|
pub fn AddrR64::create_exn(word : Word) -> AddrR64 raise @bitvec.BitVecError {
  AddrR64::of_int64(word.to_int64())
}

///|
pub fn AddrR64::to_int64(self : AddrR64) -> Int64 {
  self.value
}

///|
pub fn AddrR64::to_uint64(self : AddrR64) -> UInt64 {
  self.value.reinterpret_as_uint64()
}

///|
pub fn AddrR64::to_word(self : AddrR64) -> Word raise @bitvec.BitVecError {
  Word::of_int64(self.value)
}

///|
pub fn AddrR64::zero() -> AddrR64 {
  { value: 0L }
}

///|
pub fn AddrR64::one() -> AddrR64 {
  { value: 1L }
}

///|
pub fn AddrR64::succ(self : AddrR64) -> AddrR64 {
  { value: self.value + 1L }
}

///|
pub fn AddrR64::pred(self : AddrR64) -> AddrR64 {
  { value: self.value - 1L }
}

///|
pub fn AddrR64::abs(self : AddrR64) -> AddrR64 {
  { value: self.value.abs() }
}

///|
pub fn AddrR64::neg(self : AddrR64) -> AddrR64 {
  { value: -self.value }
}

///|
pub fn AddrR64::add(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value + other.value }
}

///|
pub fn AddrR64::sub(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value - other.value }
}

///|
pub fn AddrR64::mul(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value * other.value }
}

///|
pub fn AddrR64::div(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value / other.value }
}

///|
pub fn AddrR64::modulo(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value % other.value }
}

///|
pub fn AddrR64::lnot(self : AddrR64) -> AddrR64 {
  { value: Int64::lnot(self.value) }
}

///|
pub fn AddrR64::logand(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value & other.value }
}

///|
pub fn AddrR64::logor(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value | other.value }
}

///|
pub fn AddrR64::logxor(self : AddrR64, other : AddrR64) -> AddrR64 {
  { value: self.value ^ other.value }
}

///|
pub fn AddrR64::lshift(self : AddrR64, amount : AddrR64) -> AddrR64 {
  { value: self.value << addr_r64_shift_amount(amount.value) }
}

///|
pub fn AddrR64::rshift(self : AddrR64, amount : AddrR64) -> AddrR64 {
  let shifted = self.value.reinterpret_as_uint64() >>
    addr_r64_shift_amount(amount.value)
  { value: shifted.reinterpret_as_int64() }
}

///|
pub fn AddrR64::arshift(self : AddrR64, amount : AddrR64) -> AddrR64 {
  { value: self.value >> addr_r64_shift_amount(amount.value) }
}
