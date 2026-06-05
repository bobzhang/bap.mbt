///|
struct Symbol {
  name_value : String
  addr_value : UInt64
  size_value : Int
  function_flag : Bool
  debug_flag : Bool
}

///|
pub fn Symbol::create(
  name~ : String,
  addr~ : UInt64,
  size? : Int = 0,
  is_function? : Bool,
  is_debug? : Bool,
) -> Symbol {
  {
    name_value: name,
    addr_value: addr,
    size_value: size,
    function_flag: default_flag(is_function, false),
    debug_flag: default_flag(is_debug, false),
  }
}

///|
pub fn Symbol::name(self : Symbol) -> String {
  self.name_value
}

///|
pub fn Symbol::addr(self : Symbol) -> UInt64 {
  self.addr_value
}

///|
pub fn Symbol::size(self : Symbol) -> Int {
  self.size_value
}

///|
pub fn Symbol::is_function(self : Symbol) -> Bool {
  self.function_flag
}

///|
pub fn Symbol::is_debug(self : Symbol) -> Bool {
  self.debug_flag
}

///|
pub fn Symbol::contains(self : Symbol, addr : UInt64) -> Bool {
  if self.size_value <= 0 {
    self.addr_value == addr
  } else {
    addr >= self.addr_value &&
    addr < self.addr_value + self.size_value.to_uint64()
  }
}

///|
pub fn Symbol::to_string(self : Symbol) -> String {
  "\{self.name()} \{self.addr()} \{self.size()}"
}

///|
pub fn Symbol::hash(self : Symbol) -> Int {
  self.addr().to_string().hash()
}

///|
pub fn Symbol::equal(self : Symbol, other : Symbol) -> Bool {
  self.compare(other) == 0
}

///|
pub fn Symbol::compare(self : Symbol, other : Symbol) -> Int {
  let name_order = self.name_value.compare(other.name_value)
  if name_order != 0 {
    return name_order
  }
  let addr_order = self.addr_value.compare(other.addr_value)
  if addr_order != 0 {
    return addr_order
  }
  let size_order = self.size_value.compare(other.size_value)
  if size_order != 0 {
    return size_order
  }
  let function_order = image_bool_compare(
    self.function_flag,
    other.function_flag,
  )
  if function_order != 0 {
    return function_order
  }
  image_bool_compare(self.debug_flag, other.debug_flag)
}

///|
pub fn Symbol::module_name() -> String? {
  Some("Bap.Std.Image.Symbol")
}

///|
pub fn Symbol::version() -> String {
  "2.0.0"
}
