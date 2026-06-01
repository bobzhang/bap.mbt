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
pub fn Var::equal(self : Var, other : Var) -> Bool {
  self.same(other)
}

///|
fn bool_compare(lhs : Bool, rhs : Bool) -> Int {
  if lhs == rhs {
    0
  } else if !lhs && rhs {
    -1
  } else {
    1
  }
}

///|
pub fn Var::compare(self : Var, other : Var) -> Int {
  let ident_order = self.ident_value.compare(other.ident_value)
  if ident_order != 0 {
    return ident_order
  }
  let version_order = self.version_value.compare(other.version_value)
  if version_order != 0 {
    return version_order
  }
  let sort_order = self.sort_value
    .to_string()
    .compare(other.sort_value.to_string())
  if sort_order != 0 {
    return sort_order
  }
  let mutable_order = bool_compare(self.mutable_flag, other.mutable_flag)
  if mutable_order != 0 {
    return mutable_order
  }
  bool_compare(self.virtual_flag, other.virtual_flag)
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

///|
pub fn Var::persistent() -> @knowledge.Persistent[Var] {
  let sort_codec = Sort::persistent()
  let string_codec = @knowledge.Persistent::string()
  let int_codec = @knowledge.Persistent::int()
  let bool_codec = @knowledge.Persistent::bool()
  @knowledge.Persistent::convert(
    to_persistent=variable => {
      [
        sort_codec.encode(variable.sort_value),
        string_codec.encode(variable.ident_value),
        int_codec.encode(variable.version_value),
        bool_codec.encode(variable.mutable_flag),
        bool_codec.encode(variable.virtual_flag),
      ]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 5, "var") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let sort = match sort_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let ident = match string_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let version = match int_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let mutable_flag = match bool_codec.decode(fields[3]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let virtual_flag = match bool_codec.decode(fields[4]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok({
        sort_value: sort,
        ident_value: ident,
        version_value: version,
        mutable_flag,
        virtual_flag,
      })
    },
    persistent_string_fields(),
  )
}
