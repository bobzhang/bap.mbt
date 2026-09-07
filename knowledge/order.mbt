///|
pub(all) enum PartialOrder {
  Less
  Equal
  Greater
  Incomparable
} derive(Eq, Debug)

///|
pub extend PartialOrder with Eq::{not_equal, equal}

///|
pub extend PartialOrder with Debug::{to_repr}

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
