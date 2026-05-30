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
  { ..self, memory_value: memory }
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
