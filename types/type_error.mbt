///|
pub(all) enum TypeKind {
  MemKind
  ImmKind
} derive(Eq, Debug)

///|
pub extend TypeKind with Eq::{not_equal, equal}

///|
pub extend TypeKind with Debug::{to_repr}

///|
fn TypeKind::rank(self : TypeKind) -> Int32 {
  match self {
    MemKind => 0
    ImmKind => 1
  }
}

///|
fn TypeKind::compare(self : TypeKind, other : TypeKind) -> Int32 {
  self.rank().compare(other.rank())
}

///|
pub(all) enum TypeError {
  BadKind(TypeKind)
  BadType(expected~ : ValueType, got~ : ValueType)
  BadCast
  UnknownType
} derive(Eq, Debug)

///|
pub extend TypeError with Eq::{not_equal}

///|
pub extend TypeError with Debug::{to_repr}

///|
pub(all) suberror TypeInferenceError {
  InvalidExpType(TypeError)
} derive(Eq, Debug)

///|
pub extend TypeInferenceError with Eq::{not_equal, equal}

///|
pub extend TypeInferenceError with Debug::{to_repr}

///|
fn TypeError::rank(self : TypeError) -> Int32 {
  match self {
    BadKind(_) => 0
    BadType(_) => 1
    BadCast => 2
    UnknownType => 3
  }
}

///|
pub fn TypeError::equal(self : TypeError, other : TypeError) -> Bool {
  self == other
}

///|
pub fn TypeError::compare(self : TypeError, other : TypeError) -> Int32 {
  let rank_order = self.rank().compare(other.rank())
  if rank_order != 0 {
    return rank_order
  }
  match (self, other) {
    (BadKind(left), BadKind(right)) => left.compare(right)
    (
      BadType(expected=left_expected, got=left_got),
      BadType(expected=right_expected, got=right_got),
    ) => {
      let expected_order = left_expected.compare(right_expected)
      if expected_order != 0 {
        return expected_order
      }
      left_got.compare(right_got)
    }
    _ => 0
  }
}

///|
pub fn TypeError::bad_mem() -> TypeError {
  BadKind(MemKind)
}

///|
pub fn TypeError::bad_imm() -> TypeError {
  BadKind(ImmKind)
}

///|
pub fn TypeError::bad_type(
  expected~ : ValueType,
  got~ : ValueType,
) -> TypeError {
  BadType(expected~, got~)
}

///|
pub fn TypeError::bad_cast() -> TypeError {
  BadCast
}

///|
pub fn TypeError::unknown() -> TypeError {
  UnknownType
}

///|
pub fn TypeError::to_string(self : TypeError) -> String {
  match self {
    UnknownType => "a non-representable in BIL type"
    BadKind(MemKind) => "expected storage, got immediate value"
    BadKind(ImmKind) => "expected immediate value, got storage"
    BadCast => "malformed cast arguments"
    BadType(expected~, got~) =>
      "expected value of type \{expected.to_string()}, but got \{got.to_string()}"
  }
}
