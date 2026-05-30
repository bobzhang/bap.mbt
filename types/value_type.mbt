///|
pub(all) enum ValueType {
  Imm(Int)
  Mem(addr_width~ : Int, value_width~ : Int)
} derive(Eq, Debug)

///|
pub fn ValueType::reg(size : Size) -> ValueType {
  Imm(size.in_bits())
}

///|
pub fn ValueType::bool_t() -> ValueType {
  Imm(1)
}

///|
pub fn ValueType::reg8_t() -> ValueType {
  ValueType::reg(R8)
}

///|
pub fn ValueType::reg16_t() -> ValueType {
  ValueType::reg(R16)
}

///|
pub fn ValueType::reg32_t() -> ValueType {
  ValueType::reg(R32)
}

///|
pub fn ValueType::reg64_t() -> ValueType {
  ValueType::reg(R64)
}

///|
pub fn ValueType::reg128_t() -> ValueType {
  ValueType::reg(R128)
}

///|
pub fn ValueType::reg256_t() -> ValueType {
  ValueType::reg(R256)
}

///|
pub fn ValueType::mem(addr_size : AddrSize, value_size : Size) -> ValueType {
  Mem(addr_width=addr_size.in_bits(), value_width=value_size.in_bits())
}

///|
pub fn ValueType::mem32_t(value_size : Size) -> ValueType {
  ValueType::mem(Addr32, value_size)
}

///|
pub fn ValueType::mem64_t(value_size : Size) -> ValueType {
  ValueType::mem(Addr64, value_size)
}

///|
pub fn ValueType::bitwidth(self : ValueType) -> Int? {
  match self {
    Imm(width) => Some(width)
    Mem(_) => None
  }
}

///|
pub fn ValueType::value_size(self : ValueType) -> Size? {
  match self {
    Imm(width) => Size::of_int_opt(width)
    Mem(value_width~, ..) => Size::of_int_opt(value_width)
  }
}

///|
pub fn ValueType::addr_size(self : ValueType) -> AddrSize? {
  match self {
    Imm(_) => None
    Mem(addr_width~, ..) => Size::addr_of_int_opt(addr_width)
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
fn parse_var_index(name : String) -> (String, Int)? {
  match name.rev_split_once("#") {
    Some((base, suffix)) => {
      let suffix_text = suffix.to_owned()
      try @string.parse_int(suffix_text) catch {
        _ => None
      } noraise {
        index => if index >= 0 { Some((base.to_owned(), index)) } else { None }
      }
    }
    None => None
  }
}

///|
pub fn Var::base(self : Var) -> Var {
  match parse_var_index(self.name) {
    Some((name, _)) => { ..self, name, }
    None => self
  }
}

///|
pub fn Var::index(self : Var) -> Int {
  match parse_var_index(self.name) {
    Some((_, index)) => index
    None => 0
  }
}

///|
pub fn Var::with_index(self : Var, index : Int) -> Var {
  let base = self.base()
  if index <= 0 {
    base
  } else {
    { ..base, name: "\{base.name}#\{index}" }
  }
}

///|
pub fn Var::to_string(self : Var) -> String {
  if self.is_virtual {
    "%\{self.name}:\{self.typ.to_string()}"
  } else {
    "\{self.name}:\{self.typ.to_string()}"
  }
}
