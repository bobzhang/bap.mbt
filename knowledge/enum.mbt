///|
/// `Symbol.keyword`: the package of keywords.
pub const KEYWORD_PACKAGE : String = "keyword"

///|
/// The default package of names and symbols.
pub const USER_PACKAGE : String = "user"

///|
/// An extensible enumerated type (`Knowledge.Enum.Make ()`).
///
/// Elements are names that must be declared before they are read. Every
/// enumeration contains the `:unknown` element, which is the bottom of its
/// flat domain.
struct Enum {
  elements : Map[Name, Unit]
}

///|
/// A fresh enumeration containing only `:unknown` (`Enum.Make ()`).
pub fn Enum::new() -> Enum {
  { elements: Map::from_array([(Name::read(":unknown"), ())]), }
}

///|
/// The `:unknown` element.
pub fn Enum::unknown(self : Enum) -> Name {
  ignore(self)
  Name::read(":unknown")
}

///|
pub fn Enum::is_unknown(self : Enum, name : Name) -> Bool {
  name == self.unknown()
}

///|
/// `declare ?package name`: declares a new element; fails if the element
/// is already declared.
pub fn Enum::declare_element(
  self : Enum,
  name : String,
  pkg? : String,
) -> Name raise Conflict {
  let element = Name::create(name, pkg?)
  if self.elements.contains(element) {
    raise Failure(
      "Enum.declare: the element \{element.show()} is already declared please choose a unique name",
    )
  }
  self.elements[element] = ()
  element
}

///|
/// `read ?package name`: the declared element denoted by `name`; fails if
/// it is not a member of the enumeration.
pub fn Enum::read(
  self : Enum,
  name : String,
  pkg? : String,
) -> Name raise Conflict {
  let element = Name::read(name, pkg?)
  if !self.elements.contains(element) {
    raise Failure(
      "Enum.read: \{element.show()} is not a member of the given enumeration.",
    )
  }
  element
}

///|
/// All declared elements (including `:unknown`), in declaration order.
pub fn Enum::members(self : Enum) -> Array[Name] {
  [
    for name, _ in self.elements => name
  ]
}

///|
/// The flat domain of the enumeration with `:unknown` at the bottom.
pub fn Enum::domain(self : Enum) -> Domain[Name] {
  Domain::flat(Name::create("enum"), name => name.show(), empty=self.unknown())
}

///|
/// Enumeration elements persist as names.
pub fn Enum::persistent(self : Enum) -> Persistent[Name] {
  ignore(self)
  Persistent::name()
}
