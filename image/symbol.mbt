///|
struct Symbol {
  name_value : String
  addr_value : UInt64
  size_value : Int
  extra_locations_value : Array[(UInt64, Int)]
  function_flag : Bool
  debug_flag : Bool
}

///|
pub fn Symbol::create(
  name~ : String,
  addr~ : UInt64,
  size? : Int = 0,
  extra_locations? : Array[(UInt64, Int)] = [],
  is_function? : Bool,
  is_debug? : Bool,
) -> Symbol {
  {
    name_value: name,
    addr_value: addr,
    size_value: size,
    extra_locations_value: extra_locations.copy(),
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
pub fn Symbol::extra_locations(self : Symbol) -> Array[(UInt64, Int)] {
  self.extra_locations_value.copy()
}

///|
pub fn Symbol::locations(self : Symbol) -> Array[(UInt64, Int)] {
  let locations = [(self.addr_value, self.size_value)]
  for location in self.extra_locations_value {
    locations.push(location)
  }
  locations
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
fn image_symbol_location_contains(
  location : (UInt64, Int),
  addr : UInt64,
) -> Bool {
  let (base, size) = location
  if size <= 0 {
    base == addr
  } else {
    addr >= base && addr < base + size.to_uint64()
  }
}

///|
pub fn Symbol::contains(self : Symbol, addr : UInt64) -> Bool {
  self
  .locations()
  .any(location => image_symbol_location_contains(location, addr))
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
fn symbol_location_compare(left : (UInt64, Int), right : (UInt64, Int)) -> Int {
  let addr_order = left.0.compare(right.0)
  if addr_order != 0 {
    return addr_order
  }
  left.1.compare(right.1)
}

///|
fn symbol_locations_compare(
  left : Array[(UInt64, Int)],
  right : Array[(UInt64, Int)],
) -> Int {
  let length_order = left.length().compare(right.length())
  if length_order != 0 {
    return length_order
  }
  for i in 0..<left.length() {
    let order = symbol_location_compare(left[i], right[i])
    if order != 0 {
      return order
    }
  }
  0
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
  let debug_order = image_bool_compare(self.debug_flag, other.debug_flag)
  if debug_order != 0 {
    return debug_order
  }
  symbol_locations_compare(
    self.extra_locations_value,
    other.extra_locations_value,
  )
}

///|
pub fn Symbol::module_name() -> String? {
  Some("Bap.Std.Image.Symbol")
}

///|
pub fn Symbol::version() -> String {
  "2.0.0"
}
