///|
struct Relocation {
  fixup_value : UInt64
  target_value : UInt64?
  addend_value : Int64?
  relative_flag : Bool
}

///|
pub fn Relocation::create(
  fixup~ : UInt64,
  target? : UInt64,
  addend? : Int64,
  relative? : Bool,
) -> Relocation {
  {
    fixup_value: fixup,
    target_value: target,
    addend_value: addend,
    relative_flag: default_flag(relative, false),
  }
}

///|
pub fn Relocation::fixup(self : Relocation) -> UInt64 {
  self.fixup_value
}

///|
pub fn Relocation::target(self : Relocation) -> UInt64? {
  self.target_value
}

///|
pub fn Relocation::addend(self : Relocation) -> Int64? {
  self.addend_value
}

///|
pub fn Relocation::is_relative(self : Relocation) -> Bool {
  self.relative_flag
}

///|
struct ExternalReference {
  addr_value : UInt64
  name_value : String
}

///|
pub fn ExternalReference::create(
  addr~ : UInt64,
  name~ : String,
) -> ExternalReference {
  { addr_value: addr, name_value: name }
}

///|
pub fn ExternalReference::addr(self : ExternalReference) -> UInt64 {
  self.addr_value
}

///|
pub fn ExternalReference::name(self : ExternalReference) -> String {
  self.name_value
}

///|
struct SymbolValue {
  addr_value : UInt64
  value_value : UInt64
}

///|
pub fn SymbolValue::create(addr~ : UInt64, value~ : UInt64) -> SymbolValue {
  { addr_value: addr, value_value: value }
}

///|
pub fn SymbolValue::addr(self : SymbolValue) -> UInt64 {
  self.addr_value
}

///|
pub fn SymbolValue::value(self : SymbolValue) -> UInt64 {
  self.value_value
}
