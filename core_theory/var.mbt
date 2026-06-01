///|
let fresh_var_counter : Ref[Int] = Ref(0)

///|
struct Var {
  sort_value : Sort
  ident_value : String
  version_value : Int
  mutable_flag : Bool
  virtual_flag : Bool
}

///|
fn default_bool(value : Bool?) -> Bool {
  match value {
    Some(flag) => flag
    None => false
  }
}

///|
fn bool_or(value : Bool?, default : Bool) -> Bool {
  match value {
    Some(flag) => flag
    None => default
  }
}

///|
fn next_var_ident() -> String {
  fresh_var_counter.val = fresh_var_counter.val + 1
  "#\{fresh_var_counter.val}"
}

///|
fn var_valid_first_char(ch : Char) -> Bool {
  !(ch >= '0' && ch <= '9') && ch != '#' && ch != '$'
}

///|
fn var_escape_worthy(ch : Char) -> Bool {
  ch == '.' ||
  ch == ' ' ||
  ch == '\n' ||
  ch == '\r' ||
  ch == '\t' ||
  ch.to_int() < 0x20 ||
  ch.to_int() > 0x7e
}

///|
fn var_mangle(name : String) -> String {
  let builder = StringBuilder()
  for ch in name {
    if ch == '\\' {
      builder.write_string("\\\\")
    } else if var_escape_worthy(ch) {
      builder.write_char('\\')
      builder.write_char(ch)
    } else {
      builder.write_char(ch)
    }
  }
  let escaped = builder.to_string()
  if escaped.length() == 0 {
    "_"
  } else {
    match escaped.get_char(0) {
      Some(ch) if !var_valid_first_char(ch) => "_\{escaped}"
      _ => escaped
    }
  }
}

///|
pub fn Var::create(
  sort : Sort,
  name : String,
  is_mutable? : Bool,
  is_virtual? : Bool,
) -> Var {
  {
    sort_value: sort,
    ident_value: var_mangle(name),
    version_value: 0,
    mutable_flag: bool_or(is_mutable, true),
    virtual_flag: default_bool(is_virtual),
  }
}

///|
pub fn Var::fresh(sort : Sort) -> Var {
  {
    sort_value: sort,
    ident_value: next_var_ident(),
    version_value: 0,
    mutable_flag: true,
    virtual_flag: true,
  }
}

///|
pub fn Var::resort(self : Var, sort : Sort) -> Var {
  { ..self, sort_value: sort }
}

///|
pub fn Var::forget(self : Var) -> Var {
  self.resort(self.sort_value.forget())
}

///|
pub fn Var::versioned(self : Var, version : Int) -> Var {
  { ..self, version_value: version }
}

///|
pub fn Var::same(self : Var, other : Var) -> Bool {
  self.ident_value == other.ident_value &&
  self.version_value == other.version_value &&
  self.mutable_flag == other.mutable_flag &&
  self.virtual_flag == other.virtual_flag &&
  self.sort_value.same(other.sort_value)
}

///|
pub fn Var::ident(self : Var) -> String {
  self.ident_value
}

///|
pub fn Var::name(self : Var) -> String {
  if self.version_value == 0 {
    self.ident_value
  } else {
    "\{self.ident_value}.\{self.version_value}"
  }
}

///|
pub fn Var::sort(self : Var) -> Sort {
  self.sort_value
}

///|
pub fn Var::version(self : Var) -> Int {
  self.version_value
}

///|
pub fn Var::is_virtual(self : Var) -> Bool {
  self.virtual_flag
}

///|
pub fn Var::is_mutable(self : Var) -> Bool {
  self.mutable_flag
}

///|
pub fn Var::to_string(self : Var) -> String {
  "\{self.name()}:\{self.sort_value.to_string()}"
}
