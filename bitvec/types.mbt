///|
#derive(Eq, Debug)
pub(all) enum Endian {
  LittleEndian
  BigEndian
}

///|
pub extend Endian with Eq::{not_equal, equal}

///|
pub extend Endian with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) suberror BitVecError {
  InvalidWidth(Int32)
  IncompatibleWidths(lhs~ : Int32, rhs~ : Int32)
  InvalidHexDigit(Char)
  InvalidLiteral(String)
}

///|
pub extend BitVecError with Eq::{not_equal, equal}

///|
pub extend BitVecError with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct BitVec {
  width : Int32
  limbs : Array[UInt64]
}

///|
pub extend BitVec with Eq::{not_equal}

///|
pub extend BitVec with Debug::{to_repr}

///|
pub fn BitVec::width(self : BitVec) -> Int32 {
  self.width
}

///|
pub fn BitVec::limb_count(self : BitVec) -> Int32 {
  self.limbs.length()
}
