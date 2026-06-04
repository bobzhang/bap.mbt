///|
pub(all) enum ValueType {
  Imm(Int)
  Mem(addr_width~ : Int, value_width~ : Int)
} derive(Eq, Debug)

///|
fn ValueType::rank(self : ValueType) -> Int {
  match self {
    Imm(_) => 0
    Mem(_) => 1
  }
}

///|
pub fn ValueType::equal(self : ValueType, other : ValueType) -> Bool {
  self == other
}

///|
pub fn ValueType::compare(self : ValueType, other : ValueType) -> Int {
  let rank_order = self.rank().compare(other.rank())
  if rank_order != 0 {
    return rank_order
  }
  match (self, other) {
    (Imm(left), Imm(right)) => left.compare(right)
    (
      Mem(addr_width=left_addr, value_width=left_value),
      Mem(addr_width=right_addr, value_width=right_value),
    ) => {
      let addr_order = left_addr.compare(right_addr)
      if addr_order != 0 {
        return addr_order
      }
      left_value.compare(right_value)
    }
    _ => 0
  }
}

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
let var_create_fresh_counter : Ref[Int] = Ref(0xC00000)

///|
fn next_create_fresh_var_name() -> String {
  var_create_fresh_counter.val -= 1
  "#\{var_create_fresh_counter.val}"
}

///|
pub fn Var::new(
  name~ : String,
  typ~ : ValueType,
  is_virtual? : Bool = false,
) -> Var {
  { name, typ, is_virtual }
}

///|
pub fn Var::create(
  name : String,
  typ : ValueType,
  is_virtual? : Bool = false,
  fresh? : Bool = false,
) -> Var {
  if is_virtual || fresh {
    Var::new(name=next_create_fresh_var_name(), typ~, is_virtual=true)
  } else {
    Var::new(name~, typ~)
  }
}

///|
pub fn Var::name(self : Var) -> String {
  self.name
}

///|
pub fn Var::typ(self : Var) -> ValueType {
  self.typ
}

///|
pub fn Var::is_virtual(self : Var) -> Bool {
  self.is_virtual
}

///|
pub fn Var::is_physical(self : Var) -> Bool {
  !self.is_virtual
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
pub fn Var::same(self : Var, other : Var) -> Bool {
  self.base().name == other.base().name
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
