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
