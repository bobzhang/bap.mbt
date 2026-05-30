///|
pub(all) enum TypeKind {
  MemKind
  ImmKind
} derive(Eq, Debug)

///|
pub(all) enum TypeError {
  BadKind(TypeKind)
  BadType(expected~ : ValueType, got~ : ValueType)
  BadCast
  UnknownType
} derive(Eq, Debug)

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
