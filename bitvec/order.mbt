///|
pub(all) enum BitVecOrder {
  BitVecAscending
  BitVecDescending
} derive(Eq, Debug)

///|
pub extend BitVecOrder with Eq::{not_equal, equal}

///|
pub extend BitVecOrder with Debug::{to_repr}

///|
pub fn BitVec::compare(self : BitVec, other : BitVec) -> Int {
  let count = Int::max(self.limbs.length(), other.limbs.length())
  let mut result = 0
  for offset in 0..<count {
    if result == 0 {
      let index = count - 1 - offset
      let lhs = if index < self.limbs.length() { self.limbs[index] } else { 0 }
      let rhs = if index < other.limbs.length() {
        other.limbs[index]
      } else {
        0
      }
      if lhs < rhs {
        result = -1
      } else if lhs > rhs {
        result = 1
      }
    }
  }
  result
}

///|
pub fn compare(lhs : BitVec, rhs : BitVec) -> Int {
  lhs.compare(rhs)
}

///|
pub fn BitVec::equal(self : BitVec, other : BitVec) -> Bool {
  self.compare(other) == 0
}

///|
pub fn equal(lhs : BitVec, rhs : BitVec) -> Bool {
  lhs.equal(rhs)
}

///|
pub fn BitVecOrder::ascending() -> BitVecOrder {
  BitVecAscending
}

///|
pub fn BitVecOrder::descending() -> BitVecOrder {
  BitVecDescending
}

///|
pub fn BitVecOrder::natural() -> BitVecOrder {
  BitVecAscending
}

///|
pub fn BitVecOrder::compare(
  self : BitVecOrder,
  lhs : BitVec,
  rhs : BitVec,
) -> Int {
  match self {
    BitVecAscending => lhs.compare(rhs)
    BitVecDescending => rhs.compare(lhs)
  }
}
