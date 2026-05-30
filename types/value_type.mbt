///|
pub(all) enum ValueType {
  Imm(Int)
  Mem(addr_width~ : Int, value_width~ : Int)
} derive(Eq, Debug)

///|
pub fn ValueType::bitwidth(self : ValueType) -> Int? {
  match self {
    Imm(width) => Some(width)
    Mem(_) => None
  }
}

///|
pub fn ValueType::to_string(self : ValueType) -> String {
  match self {
    Imm(width) => "imm\{width}"
    Mem(addr_width~, value_width~) => "mem\{addr_width}x\{value_width}"
  }
}

///|
pub(all) struct Var {
  name : String
  typ : ValueType
  is_virtual : Bool
} derive(Eq, Debug)

///|
pub fn Var::new(
  name~ : String,
  typ~ : ValueType,
  is_virtual? : Bool = false,
) -> Var {
  { name, typ, is_virtual }
}

///|
pub fn Var::to_string(self : Var) -> String {
  if self.is_virtual {
    "%\{self.name}:\{self.typ.to_string()}"
  } else {
    "\{self.name}:\{self.typ.to_string()}"
  }
}
