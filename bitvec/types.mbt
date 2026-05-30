///|
pub(all) enum Endian {
  LittleEndian
  BigEndian
} derive(Eq, Debug)

///|
pub(all) suberror BitVecError {
  InvalidWidth(Int)
  IncompatibleWidths(lhs~ : Int, rhs~ : Int)
  InvalidHexDigit(Char)
  InvalidLiteral(String)
} derive(Eq, Debug)

///|
struct BitVec {
  width : Int
  limbs : Array[UInt64]
} derive(Eq, Debug)

///|
pub fn BitVec::width(self : BitVec) -> Int {
  self.width
}

///|
pub fn BitVec::limb_count(self : BitVec) -> Int {
  self.limbs.length()
}
