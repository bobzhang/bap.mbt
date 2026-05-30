///|
pub fn BitVec::bit_and(
  self : BitVec,
  other : BitVec,
) -> BitVec raise BitVecError {
  require_same_width(self, other)
  make_unchecked(
    self.width,
    Array::makei(self.limbs.length(), i => self.limbs[i] & other.limbs[i]),
  )
}

///|
pub fn BitVec::bit_or(
  self : BitVec,
  other : BitVec,
) -> BitVec raise BitVecError {
  require_same_width(self, other)
  make_unchecked(
    self.width,
    Array::makei(self.limbs.length(), i => self.limbs[i] | other.limbs[i]),
  )
}

///|
pub fn BitVec::bit_xor(
  self : BitVec,
  other : BitVec,
) -> BitVec raise BitVecError {
  require_same_width(self, other)
  make_unchecked(
    self.width,
    Array::makei(self.limbs.length(), i => self.limbs[i] ^ other.limbs[i]),
  )
}

///|
pub fn BitVec::lshift(self : BitVec, amount : Int) -> BitVec {
  if amount <= 0 {
    self
  } else if amount >= self.width {
    make_unchecked(self.width, [])
  } else {
    let word_shift = amount / 64
    let bit_shift = amount % 64
    let count = self.limbs.length()
    let out = Array::make(count, (0 : UInt64))
    for i in 0..<count {
      let dest = i + word_shift
      if dest < count {
        out[dest] = out[dest] | (self.limbs[i] << bit_shift)
      }
      if bit_shift != 0 && dest + 1 < count {
        out[dest + 1] = out[dest + 1] | (self.limbs[i] >> (64 - bit_shift))
      }
    }
    make_unchecked(self.width, out)
  }
}

///|
pub fn BitVec::rshift(self : BitVec, amount : Int) -> BitVec {
  if amount <= 0 {
    self
  } else if amount >= self.width {
    make_unchecked(self.width, [])
  } else {
    let word_shift = amount / 64
    let bit_shift = amount % 64
    let count = self.limbs.length()
    let out = Array::make(count, (0 : UInt64))
    for dest in 0..<count {
      let src = dest + word_shift
      if src < count {
        let mut value = self.limbs[src] >> bit_shift
        if bit_shift != 0 && src + 1 < count {
          value = value | (self.limbs[src + 1] << (64 - bit_shift))
        }
        out[dest] = value
      }
    }
    make_unchecked(self.width, out)
  }
}

///|
pub fn BitVec::arshift(self : BitVec, amount : Int) -> BitVec {
  if amount <= 0 {
    self
  } else if amount >= self.width {
    if self.msb() {
      try! ones(width=self.width)
    } else {
      make_unchecked(self.width, [])
    }
  } else {
    let shifted = self.rshift(amount)
    if self.msb() {
      let fill = try! ones(width=self.width)
      try! shifted.bit_or(fill.lshift(self.width - amount))
    } else {
      shifted
    }
  }
}

///|
pub fn BitVec::concat(self : BitVec, low : BitVec) -> BitVec raise BitVecError {
  let high = self
  let width = high.width + low.width
  let shifted = high.widen(width~).lshift(low.width)
  shifted.bit_or(low.widen(width~))
}

///|
pub fn BitVec::widen(self : BitVec, width~ : Int) -> BitVec raise BitVecError {
  if width < self.width {
    raise InvalidWidth(width)
  }
  make(width, self.limbs)
}

///|
pub fn BitVec::extract(
  self : BitVec,
  hi? : Int = -1,
  lo? : Int = 0,
) -> BitVec raise BitVecError {
  let actual_hi = if hi < 0 { self.width - 1 } else { hi }
  if lo < 0 || actual_hi < lo || actual_hi >= self.width {
    raise InvalidWidth(actual_hi - lo + 1)
  }
  let width = actual_hi - lo + 1
  self.rshift(lo).truncate(width~)
}

///|
pub fn BitVec::truncate(
  self : BitVec,
  width~ : Int,
) -> BitVec raise BitVecError {
  if width > self.width {
    raise InvalidWidth(width)
  }
  make(width, self.limbs)
}
