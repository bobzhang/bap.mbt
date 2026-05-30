///|
pub fn BitVec::add(self : BitVec, other : BitVec) -> BitVec raise BitVecError {
  require_same_width(self, other)
  let out = Array::make(self.limbs.length(), (0 : UInt64))
  let mut carry : UInt64 = 0
  for i in 0..<self.limbs.length() {
    let sum = self.limbs[i] + other.limbs[i]
    let carry0 : UInt64 = if sum < self.limbs[i] { 1 } else { 0 }
    let sum_with_carry = sum + carry
    let carry1 : UInt64 = if sum_with_carry < sum { 1 } else { 0 }
    out[i] = sum_with_carry
    carry = if carry0 == 1 || carry1 == 1 { 1 } else { 0 }
  }
  make_unchecked(self.width, out)
}

///|
pub fn BitVec::sub(self : BitVec, other : BitVec) -> BitVec raise BitVecError {
  require_same_width(self, other)
  let out = Array::make(self.limbs.length(), (0 : UInt64))
  let mut borrow : UInt64 = 0
  for i in 0..<self.limbs.length() {
    let diff = self.limbs[i] - other.limbs[i]
    let borrow0 : UInt64 = if self.limbs[i] < other.limbs[i] { 1 } else { 0 }
    let diff_with_borrow = diff - borrow
    let borrow1 : UInt64 = if diff < borrow { 1 } else { 0 }
    out[i] = diff_with_borrow
    borrow = if borrow0 == 1 || borrow1 == 1 { 1 } else { 0 }
  }
  make_unchecked(self.width, out)
}

///|
pub fn BitVec::lnot(self : BitVec) -> BitVec {
  make_unchecked(self.width, self.limbs.map(limb => UInt64::lnot(limb)))
}

///|
pub fn BitVec::neg(self : BitVec) -> BitVec {
  try! self.lnot().add(try! one(width=self.width))
}

///|
pub fn BitVec::succ(self : BitVec) -> BitVec {
  try! self.add(try! one(width=self.width))
}

///|
pub fn BitVec::pred(self : BitVec) -> BitVec {
  try! self.sub(try! one(width=self.width))
}

///|
pub fn BitVec::mul(self : BitVec, other : BitVec) -> BitVec raise BitVecError {
  require_same_width(self, other)
  let mut acc = zero(width=self.width)
  let mut addend = self
  for i in 0..<self.width {
    if other.nth(i) {
      acc = acc.add(addend)
    }
    addend = addend.lshift(1)
  }
  acc
}

///|
pub fn BitVec::abs_signed(self : BitVec) -> BitVec {
  if self.msb() {
    self.neg()
  } else {
    self
  }
}

///|
pub fn BitVec::div_rem(
  self : BitVec,
  divisor : BitVec,
) -> (BitVec, BitVec) raise BitVecError {
  require_same_width(self, divisor)
  if divisor.is_zero() {
    (ones(width=self.width), self)
  } else {
    let mut quotient = zero(width=self.width)
    let mut remainder = zero(width=self.width)
    for k in 0..<self.width {
      let i = self.width - 1 - k
      remainder = remainder.lshift(1)
      if self.nth(i) {
        remainder = remainder.bit_or(one(width=self.width))
      }
      if remainder.compare_unsigned(divisor) >= 0 {
        remainder = remainder.sub(divisor)
        quotient = quotient.set_bit(i)
      }
    }
    (quotient, remainder)
  }
}

///|
pub fn BitVec::div(self : BitVec, divisor : BitVec) -> BitVec raise BitVecError {
  let (quotient, _) = self.div_rem(divisor)
  quotient
}

///|
pub fn BitVec::rem(self : BitVec, divisor : BitVec) -> BitVec raise BitVecError {
  let (_, remainder) = self.div_rem(divisor)
  remainder
}

///|
pub fn BitVec::sdiv(
  self : BitVec,
  divisor : BitVec,
) -> BitVec raise BitVecError {
  require_same_width(self, divisor)
  if divisor.is_zero() {
    ones(width=self.width)
  } else {
    let negative = self.msb() != divisor.msb()
    let quotient = self.abs_signed().div(divisor.abs_signed())
    if negative {
      quotient.neg()
    } else {
      quotient
    }
  }
}

///|
pub fn BitVec::srem(
  self : BitVec,
  divisor : BitVec,
) -> BitVec raise BitVecError {
  require_same_width(self, divisor)
  if divisor.is_zero() {
    self
  } else {
    let remainder = self.abs_signed().rem(divisor.abs_signed())
    if self.msb() {
      remainder.neg()
    } else {
      remainder
    }
  }
}

///|
pub fn BitVec::gcd(self : BitVec, other : BitVec) -> BitVec raise BitVecError {
  require_same_width(self, other)
  let mut a = self
  let mut b = other
  while !b.is_zero() {
    let r = a.rem(b)
    a = b
    b = r
  }
  a
}

///|
pub fn BitVec::lcm(self : BitVec, other : BitVec) -> BitVec raise BitVecError {
  require_same_width(self, other)
  if self.is_zero() || other.is_zero() {
    zero(width=self.width)
  } else {
    let g = self.gcd(other)
    let reduced = self.div(g)
    reduced.mul(other)
  }
}
