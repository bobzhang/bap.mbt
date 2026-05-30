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
