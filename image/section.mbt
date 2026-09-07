///|
struct Section {
  name_value : String
  addr_value : UInt64
  size_value : Int
}

///|
pub fn Section::create(name~ : String, addr~ : UInt64, size~ : Int) -> Section {
  { name_value: name, addr_value: addr, size_value: size, }
}

///|
pub fn Section::name(self : Section) -> String {
  self.name_value
}

///|
pub fn Section::addr(self : Section) -> UInt64 {
  self.addr_value
}

///|
pub fn Section::size(self : Section) -> Int {
  self.size_value
}

///|
pub fn Section::max_addr(self : Section) -> UInt64 {
  if self.size_value <= 0 {
    self.addr_value
  } else {
    self.addr_value + (self.size_value - 1).to_uint64()
  }
}

///|
pub fn Section::contains(self : Section, addr : UInt64) -> Bool {
  self.size_value > 0 && addr >= self.addr_value && addr <= self.max_addr()
}
