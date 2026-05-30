///|
pub(all) enum PartialOrder {
  Less
  Equal
  Greater
  Incomparable
} derive(Eq, Debug)

///|
pub fn PartialOrder::invert(self : PartialOrder) -> PartialOrder {
  match self {
    Less => Greater
    Equal => Equal
    Greater => Less
    Incomparable => Incomparable
  }
}

///|
pub fn PartialOrder::leq(self : PartialOrder) -> Bool {
  self == Less || self == Equal
}

///|
pub fn PartialOrder::geq(self : PartialOrder) -> Bool {
  self == Greater || self == Equal
}
