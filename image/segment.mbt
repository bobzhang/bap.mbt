///|
struct Segment {
  name_value : String
  memory_value : @memory.Memory
  offset_value : Int
  readable_flag : Bool
  writable_flag : Bool
  executable_flag : Bool
}

///|
fn default_flag(value : Bool?, fallback : Bool) -> Bool {
  match value {
    Some(flag) => flag
    None => fallback
  }
}

///|
pub fn Segment::create(
  name~ : String,
  endian~ : @bitvec.Endian,
  addr~ : UInt64,
  data : Bytes,
  offset? : Int = 0,
  readable? : Bool,
  writable? : Bool,
  executable? : Bool,
) -> Segment {
  {
    name_value: name,
    memory_value: @memory.Memory::from_bytes(endian~, start=addr, data),
    offset_value: offset,
    readable_flag: default_flag(readable, true),
    writable_flag: default_flag(writable, false),
    executable_flag: default_flag(executable, false),
  }
}

///|
pub fn Segment::from_memory(
  name~ : String,
  memory~ : @memory.Memory,
  offset? : Int = 0,
  readable? : Bool,
  writable? : Bool,
  executable? : Bool,
) -> Segment {
  {
    name_value: name,
    memory_value: memory,
    offset_value: offset,
    readable_flag: default_flag(readable, true),
    writable_flag: default_flag(writable, false),
    executable_flag: default_flag(executable, false),
  }
}

///|
pub fn Segment::name(self : Segment) -> String {
  self.name_value
}

///|
pub fn Segment::memory(self : Segment) -> @memory.Memory {
  self.memory_value
}

///|
pub fn Segment::with_memory(self : Segment, memory : @memory.Memory) -> Segment {
  { ..self, memory_value: memory, }
}

///|
pub fn Segment::addr(self : Segment) -> UInt64 {
  self.memory_value.min_addr()
}

///|
pub fn Segment::max_addr(self : Segment) -> UInt64 {
  self.memory_value.max_addr()
}

///|
pub fn Segment::size(self : Segment) -> Int {
  self.memory_value.length()
}

///|
pub fn Segment::offset(self : Segment) -> Int {
  self.offset_value
}

///|
pub fn Segment::is_readable(self : Segment) -> Bool {
  self.readable_flag
}

///|
pub fn Segment::is_writable(self : Segment) -> Bool {
  self.writable_flag
}

///|
pub fn Segment::is_executable(self : Segment) -> Bool {
  self.executable_flag
}

///|
pub fn Segment::contains(self : Segment, addr : UInt64) -> Bool {
  self.memory_value.contains(addr)
}

///|
fn image_bool_compare(lhs : Bool, rhs : Bool) -> Int {
  if lhs == rhs {
    0
  } else if !lhs && rhs {
    -1
  } else {
    1
  }
}

///|
fn image_endian_compare(lhs : @bitvec.Endian, rhs : @bitvec.Endian) -> Int {
  fn rank(value : @bitvec.Endian) -> Int {
    match value {
      LittleEndian => 0
      BigEndian => 1
    }
  }
  rank(lhs).compare(rank(rhs))
}

///|
pub fn Segment::to_string(self : Segment) -> String {
  "\{self.name()} \{self.addr()} \{self.size()}"
}

///|
pub fn Segment::hash(self : Segment) -> Int {
  self.addr().to_string().hash()
}

///|
pub fn Segment::equal(self : Segment, other : Segment) -> Bool {
  self.compare(other) == 0
}

///|
pub fn Segment::compare(self : Segment, other : Segment) -> Int {
  let name_order = self.name_value.compare(other.name_value)
  if name_order != 0 {
    return name_order
  }
  let addr_order = self.addr().compare(other.addr())
  if addr_order != 0 {
    return addr_order
  }
  let size_order = self.size().compare(other.size())
  if size_order != 0 {
    return size_order
  }
  let offset_order = self.offset_value.compare(other.offset_value)
  if offset_order != 0 {
    return offset_order
  }
  let endian_order = image_endian_compare(
    self.memory_value.endian(),
    other.memory_value.endian(),
  )
  if endian_order != 0 {
    return endian_order
  }
  let readable_order = image_bool_compare(
    self.readable_flag,
    other.readable_flag,
  )
  if readable_order != 0 {
    return readable_order
  }
  let writable_order = image_bool_compare(
    self.writable_flag,
    other.writable_flag,
  )
  if writable_order != 0 {
    return writable_order
  }
  image_bool_compare(self.executable_flag, other.executable_flag)
}

///|
pub fn Segment::module_name() -> String? {
  Some("Bap.Std.Image.Segment")
}

///|
pub fn Segment::version() -> String {
  "2.0.0"
}
