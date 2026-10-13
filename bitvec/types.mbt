///|
pub(all) enum Endian {
  LittleEndian
  BigEndian
} derive(Eq, Debug)

///|
pub extend Endian with Eq::{not_equal, equal}

///|
pub extend Endian with Debug::{to_repr}

///|
pub(all) suberror BitVecError {
  InvalidWidth(Int32)
  IncompatibleWidths(lhs~ : Int32, rhs~ : Int32)
  InvalidHexDigit(Char)
  InvalidLiteral(String)
} derive(Eq, Debug)

///|
pub extend BitVecError with Eq::{not_equal, equal}

///|
pub extend BitVecError with Debug::{to_repr}

///|
struct BitVec {
  width : Int32
  limbs : Array[UInt64]
} derive(Eq, Debug)

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
