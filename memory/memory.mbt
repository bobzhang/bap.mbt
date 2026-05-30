///|
pub(all) enum AddressPosition {
  AddrInside
  AddrBelow
  AddrAbove
} derive(Eq, Debug)

///|
struct Memory {
  endian_value : @bitvec.Endian
  base_addr : UInt64
  data_value : Bytes
}

///|
fn u64_from_int(value : Int) -> UInt64 {
  value.to_uint64()
}

///|
fn checked_len(data : Bytes, pos : Int, len : Int) -> Result[Int, String] {
  if pos < 0 {
    Err("memory position is negative")
  } else if pos > data.length() {
    Err("memory position is past the input")
  } else {
    let available = data.length() - pos
    let size = if len < 0 { available } else { len }
    if size < 0 || size > available {
      Err("memory length exceeds the input")
    } else {
      Ok(size)
    }
  }
}

///|
pub fn Memory::create(
  endian~ : @bitvec.Endian,
  start~ : UInt64,
  data : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> Result[Memory, String] {
  match checked_len(data, pos, len) {
    Ok(size) =>
      Ok({
        endian_value: endian,
        base_addr: start,
        data_value: data[pos:pos + size].to_owned(),
      })
    Err(reason) => Err(reason)
  }
}

///|
pub fn Memory::from_bytes(
  endian~ : @bitvec.Endian,
  start~ : UInt64,
  data : Bytes,
) -> Memory {
  { endian_value: endian, base_addr: start, data_value: data }
}

///|
pub fn Memory::rebase(self : Memory, start : UInt64) -> Memory {
  { ..self, base_addr: start }
}

///|
pub fn Memory::endian(self : Memory) -> @bitvec.Endian {
  self.endian_value
}

///|
pub fn Memory::min_addr(self : Memory) -> UInt64 {
  self.base_addr
}

///|
pub fn Memory::max_addr(self : Memory) -> UInt64 {
  if self.data_value.length() == 0 {
    self.base_addr
  } else {
    self.base_addr + u64_from_int(self.data_value.length() - 1)
  }
}

///|
pub fn Memory::length(self : Memory) -> Int {
  self.data_value.length()
}

///|
pub fn Memory::to_bytes(self : Memory) -> Bytes {
  self.data_value
}

///|
pub fn Memory::contains(self : Memory, addr : UInt64) -> Bool {
  self.length() > 0 && addr >= self.min_addr() && addr <= self.max_addr()
}

///|
pub fn Memory::compare_with(self : Memory, addr : UInt64) -> AddressPosition {
  if addr < self.min_addr() {
    AddrBelow
  } else if addr > self.max_addr() || self.length() == 0 {
    AddrAbove
  } else {
    AddrInside
  }
}

///|
fn Memory::offset(self : Memory, addr : UInt64) -> Int? {
  if self.contains(addr) {
    Some((addr - self.base_addr).to_int())
  } else {
    None
  }
}

///|
pub fn Memory::view(
  self : Memory,
  from? : UInt64,
  words? : Int = -1,
  word_size? : Int = 1,
) -> Result[Memory, String] {
  let start = match from {
    Some(addr) => addr
    None => self.min_addr()
  }
  match self.offset(start) {
    Some(pos) => {
      let available = self.length() - pos
      let requested = if words < 0 { available } else { words * word_size }
      if word_size <= 0 {
        Err("word size must be positive")
      } else if requested < 0 || requested > available {
        Err("memory view exceeds the source region")
      } else {
        Memory::create(
          endian=self.endian_value,
          start~,
          self.data_value,
          pos~,
          len=requested,
        )
      }
    }
    None => Err("memory view starts outside the source region")
  }
}

///|
pub fn Memory::range(
  self : Memory,
  lo : UInt64,
  hi : UInt64,
) -> Result[Memory, String] {
  if hi < lo {
    Err("memory range upper bound is below lower bound")
  } else {
    let words = (hi - lo).to_int() + 1
    self.view(from=lo, words~, word_size=1)
  }
}

///|
pub fn Memory::first_byte(self : Memory) -> Memory {
  match self.view(words=1) {
    Ok(mem) => mem
    Err(_) =>
      Memory::from_bytes(endian=self.endian_value, start=self.base_addr, b"")
  }
}

///|
pub fn Memory::last_byte(self : Memory) -> Memory {
  if self.length() == 0 {
    Memory::from_bytes(endian=self.endian_value, start=self.base_addr, b"")
  } else {
    match self.view(from=self.max_addr(), words=1) {
      Ok(mem) => mem
      Err(_) =>
        Memory::from_bytes(endian=self.endian_value, start=self.max_addr(), b"")
    }
  }
}

///|
pub fn Memory::load(
  self : Memory,
  addr : UInt64,
  width? : Int = 8,
  disp? : Int = 0,
  index? : Int = 0,
  scale? : Int = 1,
) -> Result[@types.Word, String] {
  let effective = addr + u64_from_int(disp + index * scale)
  if width <= 0 || width % 8 != 0 {
    Err("memory load width must be a positive multiple of 8")
  } else {
    let bytes = width / 8
    match self.offset(effective) {
      Some(pos) if pos + bytes <= self.length() =>
        try
          @types.Word::from_bytes(
            self.data_value[pos:pos + bytes],
            endian=self.endian_value,
            width~,
          )
        catch {
          _ => Err("failed to build loaded word")
        } noraise {
          word => Ok(word)
        }
      _ => Err("memory load is out of bounds")
    }
  }
}

///|
pub fn Memory::store(
  self : Memory,
  addr : UInt64,
  value : @types.Word,
) -> Result[Memory, String] {
  let bytes = value.to_bytes(endian=self.endian_value)
  match self.offset(addr) {
    Some(pos) if pos + bytes.length() <= self.length() => {
      let data = self.data_value.to_array()
      for i in 0..<bytes.length() {
        data[pos + i] = bytes[i]
      }
      Ok({ ..self, data_value: Bytes::from_array(data) })
    }
    _ => Err("memory store is out of bounds")
  }
}

///|
pub fn Memory::intersects(self : Memory, other : Memory) -> Bool {
  self.length() > 0 &&
  other.length() > 0 &&
  self.min_addr() <= other.max_addr() &&
  other.min_addr() <= self.max_addr()
}

///|
pub fn Memory::dominates(self : Memory, other : Memory) -> Bool {
  other.length() > 0 &&
  self.length() > 0 &&
  self.min_addr() <= other.min_addr() &&
  self.max_addr() >= other.max_addr()
}

///|
pub fn Memory::merge(self : Memory, other : Memory) -> Result[Memory, String] {
  if self.endian_value != other.endian_value {
    Err("can't merge memory with different endian modes")
  } else if self.length() == 0 {
    Ok(other)
  } else if other.length() == 0 {
    Ok(self)
  } else {
    let lo = if self.min_addr() < other.min_addr() {
      self.min_addr()
    } else {
      other.min_addr()
    }
    let hi = if self.max_addr() > other.max_addr() {
      self.max_addr()
    } else {
      other.max_addr()
    }
    let total = (hi - lo).to_int() + 1
    if total > self.length() + other.length() &&
      !self.intersects(other) &&
      self.max_addr() + 1UL != other.min_addr() &&
      other.max_addr() + 1UL != self.min_addr() {
      Err("memory regions are not contiguous")
    } else {
      let data = Array::make(total, b'\x00')
      for i in 0..<self.length() {
        data[(self.min_addr() - lo).to_int() + i] = self.data_value[i]
      }
      for i in 0..<other.length() {
        data[(other.min_addr() - lo).to_int() + i] = other.data_value[i]
      }
      Ok(
        Memory::from_bytes(
          endian=self.endian_value,
          start=lo,
          Bytes::from_array(data),
        ),
      )
    }
  }
}

///|
pub fn Memory::hexdump(self : Memory) -> String {
  let mut out = ""
  for i in 0..<self.length() {
    if i > 0 {
      out = out + " "
    }
    out = out + byte_to_hex(self.data_value[i])
  }
  out
}

///|
fn hex_digit(value : Int) -> String {
  match value {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}

///|
fn byte_to_hex(byte : Byte) -> String {
  let value = byte.to_int()
  hex_digit(value / 16) + hex_digit(value % 16)
}

///|
pub fn Memory::to_string(self : Memory) -> String {
  "[\{self.min_addr().to_string()}, \{self.max_addr().to_string()}] \{self.hexdump()}"
}
