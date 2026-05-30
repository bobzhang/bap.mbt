///|
let all_ones64 : UInt64 = UInt64::lnot(0)

///|
fn check_width(width : Int) -> Unit raise BitVecError {
  if width <= 0 {
    raise InvalidWidth(width)
  }
}

///|
fn limb_count_for_width(width : Int) -> Int {
  (width + 63) / 64
}

///|
fn low_mask(bits : Int) -> UInt64 {
  if bits <= 0 {
    0
  } else if bits >= 64 {
    all_ones64
  } else {
    ((1 : UInt64) << bits) - 1
  }
}

///|
fn high_limb_mask(width : Int) -> UInt64 {
  let bits = width % 64
  if bits == 0 {
    all_ones64
  } else {
    low_mask(bits)
  }
}

///|
fn normalize_limbs(width : Int, limbs : ArrayView[UInt64]) -> Array[UInt64] {
  let count = limb_count_for_width(width)
  let out = Array::make(count, (0 : UInt64))
  let take = Int::min(count, limbs.length())
  for i in 0..<take {
    out[i] = limbs[i]
  }
  if count > 0 {
    let last = count - 1
    out[last] = out[last] & high_limb_mask(width)
  }
  out
}

///|
fn make(width : Int, limbs : ArrayView[UInt64]) -> BitVec raise BitVecError {
  check_width(width)
  { width, limbs: normalize_limbs(width, limbs) }
}

///|
fn make_unchecked(width : Int, limbs : ArrayView[UInt64]) -> BitVec {
  { width, limbs: normalize_limbs(width, limbs) }
}

///|
fn require_same_width(lhs : BitVec, rhs : BitVec) -> Unit raise BitVecError {
  if lhs.width != rhs.width {
    raise IncompatibleWidths(lhs=lhs.width, rhs=rhs.width)
  }
}

///|
pub fn zero(width~ : Int) -> BitVec raise BitVecError {
  check_width(width)
  make_unchecked(width, [])
}

///|
pub fn one(width~ : Int) -> BitVec raise BitVecError {
  of_uint64(width~, 1)
}

///|
pub fn ones(width~ : Int) -> BitVec raise BitVecError {
  check_width(width)
  let count = limb_count_for_width(width)
  let limbs = Array::make(count, all_ones64)
  make_unchecked(width, limbs)
}

///|
pub fn of_bool(value : Bool) -> BitVec {
  if value {
    make_unchecked(1, [1])
  } else {
    make_unchecked(1, [0])
  }
}

///|
pub fn of_uint64(width~ : Int, value : UInt64) -> BitVec raise BitVecError {
  make(width, [value])
}

///|
pub fn of_int(width~ : Int, value : Int) -> BitVec raise BitVecError {
  of_uint64(width~, value.to_uint64())
}

///|
pub fn of_int64(width~ : Int, value : Int64) -> BitVec raise BitVecError {
  of_uint64(width~, value.reinterpret_as_uint64())
}

///|
pub fn b0() -> BitVec {
  of_bool(false)
}

///|
pub fn b1() -> BitVec {
  of_bool(true)
}

///|
pub fn BitVec::is_zero(self : BitVec) -> Bool {
  self.limbs.all(limb => limb == 0)
}

///|
pub fn BitVec::lsb(self : BitVec) -> Bool {
  (self.limbs[0] & 1) == 1
}

///|
pub fn BitVec::msb(self : BitVec) -> Bool {
  let bit = (self.width - 1) % 64
  let limb = (self.width - 1) / 64
  ((self.limbs[limb] >> bit) & 1) == 1
}

///|
pub fn BitVec::nth(self : BitVec, index : Int) -> Bool {
  if index < 0 {
    self.lsb()
  } else if index >= self.width {
    self.msb()
  } else {
    let limb = index / 64
    let bit = index % 64
    ((self.limbs[limb] >> bit) & 1) == 1
  }
}

///|
fn BitVec::set_bit(self : BitVec, index : Int) -> BitVec {
  let limbs = self.limbs.copy()
  let limb = index / 64
  let bit = index % 64
  limbs[limb] = limbs[limb] | ((1 : UInt64) << bit)
  make_unchecked(self.width, limbs)
}

///|
pub fn BitVec::to_uint64(self : BitVec) -> UInt64 raise BitVecError {
  if self.width > 64 {
    for i in 1..<self.limbs.length() {
      if self.limbs[i] != 0 {
        raise InvalidWidth(self.width)
      }
    }
  }
  self.limbs[0]
}

///|
pub fn BitVec::compare_unsigned(
  self : BitVec,
  other : BitVec,
) -> Int raise BitVecError {
  require_same_width(self, other)
  let mut result = 0
  for k in 0..<self.limbs.length() {
    if result == 0 {
      let i = self.limbs.length() - 1 - k
      if self.limbs[i] < other.limbs[i] {
        result = -1
      } else if self.limbs[i] > other.limbs[i] {
        result = 1
      }
    }
  }
  result
}

///|
pub fn BitVec::compare_signed(
  self : BitVec,
  other : BitVec,
) -> Int raise BitVecError {
  require_same_width(self, other)
  let self_negative = self.msb()
  let other_negative = other.msb()
  if self_negative && !other_negative {
    -1
  } else if !self_negative && other_negative {
    1
  } else {
    self.compare_unsigned(other)
  }
}
