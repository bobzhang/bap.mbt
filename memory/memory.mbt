///|
pub(all) enum AddressPosition {
  AddrInside
  AddrBelow
  AddrAbove
} derive(Eq, Debug)

///|
pub extend AddressPosition with Eq::{not_equal, equal}

///|
pub extend AddressPosition with Debug::{to_repr}

///|
pub(all) suberror MemoryError {
  MemoryFailure(String)
} derive(Eq, Debug)

///|
pub extend MemoryError with Eq::{not_equal, equal}

///|
pub extend MemoryError with Debug::{to_repr}

///|
struct Memory {
  endian_value : @bitvec.Endian
  base_addr : UInt64
  data_value : Bytes
}

///|
struct MemoryInputReader {
  width_value : Int
  signed_value : Bool
}

///|
fn u64_from_int(value : Int) -> UInt64 {
  value.to_uint64()
}

///|
fn checked_len(data : Bytes, pos : Int, len : Int) -> Result[Int, String] {
  if data.length() == 0 {
    Err("memory input is empty")
  } else if pos < 0 {
    Err("memory position is negative")
  } else if pos >= data.length() {
    Err("memory position is past the input")
  } else {
    let available = data.length() - pos
    let size = if len < 0 { available } else { len }
    if size <= 0 {
      Err("memory length must be positive")
    } else if size > available {
      Err("memory length exceeds the input")
    } else {
      Ok(size)
    }
  }
}

///|
fn memory_word_bytes(word_size : Int) -> Int? {
  if word_size <= 0 || word_size % 8 != 0 {
    None
  } else {
    Some(word_size / 8)
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
  { endian_value: endian, base_addr: start, data_value: data, }
}

///|
pub fn Memory::rebase(self : Memory, start : UInt64) -> Memory {
  { ..self, base_addr: start, }
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
pub fn Memory::to_buffer(self : Memory) -> BytesView {
  self.data_value[:]
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
  word_size? : Int = 8,
) -> Result[Memory, String] {
  let start = match from {
    Some(addr) => addr
    None => self.min_addr()
  }
  match memory_word_bytes(word_size) {
    None => Err("word size must be a positive multiple of 8")
    Some(word_bytes) =>
      match self.offset(start) {
        Some(pos) => {
          let available = self.length() - pos
          let requested = if words < 0 { available } else { words * word_bytes }
          if requested < 0 || requested > available {
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
}

///|
pub fn Memory::view_exn(
  self : Memory,
  from? : UInt64,
  words? : Int = -1,
  word_size? : Int = 8,
) -> Memory raise MemoryError {
  match self.view(from?, words~, word_size~) {
    Ok(memory) => memory
    Err(reason) => raise MemoryFailure(reason)
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
    self.view(from=lo, words~, word_size=8)
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
pub fn Memory::load_exn(
  self : Memory,
  addr : UInt64,
  width? : Int = 8,
  disp? : Int = 0,
  index? : Int = 0,
  scale? : Int = 1,
) -> @types.Word raise MemoryError {
  match self.load(addr, width~, disp~, index~, scale~) {
    Ok(word) => word
    Err(reason) => raise MemoryFailure(reason)
  }
}

///|
pub fn Memory::get(
  self : Memory,
  addr? : UInt64,
  disp? : Int = 0,
  index? : Int = 0,
  scale? : Int = 8,
) -> Result[@types.Word, String] {
  if scale <= 0 || scale % 8 != 0 {
    Err("memory get scale must be a positive multiple of 8")
  } else {
    let base = match addr {
      Some(value) => value
      None => self.min_addr()
    }
    self.load(base, width=scale, disp~, index~, scale=scale / 8)
  }
}

///|
pub fn Memory::get_exn(
  self : Memory,
  addr? : UInt64,
  disp? : Int = 0,
  index? : Int = 0,
  scale? : Int = 8,
) -> @types.Word raise MemoryError {
  match self.get(addr?, disp~, index~, scale~) {
    Ok(word) => word
    Err(reason) => raise MemoryFailure(reason)
  }
}

///|
pub fn Memory::deref(
  self : Memory,
  addr : UInt64,
) -> Result[@types.Word, String] {
  self.get(addr~)
}

///|
pub fn Memory::deref_exn(
  self : Memory,
  addr : UInt64,
) -> @types.Word raise MemoryError {
  self.get_exn(addr~)
}

///|
pub fn[A] Memory::foldi(
  self : Memory,
  init : A,
  f : (UInt64, @types.Word, A) -> A,
  word_size? : Int = 8,
) -> A {
  match memory_word_bytes(word_size) {
    None => init
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      let mut acc = init
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) => acc = f(addr, word, acc)
          Err(_) => return acc
        }
        offset = offset + word_bytes
      }
      acc
    }
  }
}

///|
pub fn[A] Memory::fold(
  self : Memory,
  init : A,
  f : (@types.Word, A) -> A,
  word_size? : Int = 8,
) -> A {
  self.foldi(init, (_, word, acc) => f(word, acc), word_size~)
}

///|
pub fn Memory::iteri(
  self : Memory,
  f : (UInt64, @types.Word) -> Unit,
  word_size? : Int = 8,
) -> Unit {
  self.foldi(
    (),
    (addr, word, _) => {
      f(addr, word)
      ()
    },
    word_size~,
  )
}

///|
pub fn Memory::iter(
  self : Memory,
  f : (@types.Word) -> Unit,
  word_size? : Int = 8,
) -> Unit {
  self.iteri((_, word) => f(word), word_size~)
}

///|
pub fn Memory::exists(
  self : Memory,
  f : (UInt64, @types.Word) -> Bool,
  word_size? : Int = 8,
) -> Bool {
  match
    self.find_map(
      (addr, word) => if f(addr, word) { Some(true) } else { None },
      word_size~,
    ) {
    Some(_) => true
    None => false
  }
}

///|
pub fn Memory::for_all(
  self : Memory,
  f : (UInt64, @types.Word) -> Bool,
  word_size? : Int = 8,
) -> Bool {
  match memory_word_bytes(word_size) {
    None => true
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) => if !f(addr, word) { return false }
          Err(_) => return true
        }
        offset = offset + word_bytes
      }
      true
    }
  }
}

///|
pub fn Memory::count(
  self : Memory,
  f : (UInt64, @types.Word) -> Bool,
  word_size? : Int = 8,
) -> Int {
  self.foldi(
    0,
    (addr, word, total) => if f(addr, word) { total + 1 } else { total },
    word_size~,
  )
}

///|
pub fn[A] Memory::find_map(
  self : Memory,
  f : (UInt64, @types.Word) -> A?,
  word_size? : Int = 8,
) -> A? {
  match memory_word_bytes(word_size) {
    None => None
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) =>
            match f(addr, word) {
              Some(value) => return Some(value)
              None => ()
            }
          Err(_) => return None
        }
        offset = offset + word_bytes
      }
      None
    }
  }
}

///|
pub fn Memory::find_if(
  self : Memory,
  f : (UInt64, @types.Word) -> Bool,
  word_size? : Int = 8,
) -> @types.Word? {
  self.find_map(
    (addr, word) => if f(addr, word) { Some(word) } else { None },
    word_size~,
  )
}

///|
pub fn[A, E] Memory::foldi_result(
  self : Memory,
  init : A,
  f : (UInt64, @types.Word, A) -> Result[A, E],
  word_size? : Int = 8,
) -> Result[A, E] {
  match memory_word_bytes(word_size) {
    None => Ok(init)
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      let mut acc = init
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) =>
            match f(addr, word, acc) {
              Ok(next) => acc = next
              Err(reason) => return Err(reason)
            }
          Err(_) => return Ok(acc)
        }
        offset = offset + word_bytes
      }
      Ok(acc)
    }
  }
}

///|
pub fn[A, E] Memory::fold_result(
  self : Memory,
  init : A,
  f : (@types.Word, A) -> Result[A, E],
  word_size? : Int = 8,
) -> Result[A, E] {
  self.foldi_result(init, (_, word, acc) => f(word, acc), word_size~)
}

///|
pub fn[E] Memory::iteri_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[Unit, E],
  word_size? : Int = 8,
) -> Result[Unit, E] {
  self.foldi_result((), (addr, word, _) => f(addr, word), word_size~)
}

///|
pub fn[E] Memory::iter_result(
  self : Memory,
  f : (@types.Word) -> Result[Unit, E],
  word_size? : Int = 8,
) -> Result[Unit, E] {
  self.iteri_result((_, word) => f(word), word_size~)
}

///|
pub fn[E] Memory::exists_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[Bool, E],
  word_size? : Int = 8,
) -> Result[Bool, E] {
  match memory_word_bytes(word_size) {
    None => Ok(false)
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) =>
            match f(addr, word) {
              Ok(true) => return Ok(true)
              Ok(false) => ()
              Err(reason) => return Err(reason)
            }
          Err(_) => return Ok(false)
        }
        offset = offset + word_bytes
      }
      Ok(false)
    }
  }
}

///|
pub fn[E] Memory::for_all_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[Bool, E],
  word_size? : Int = 8,
) -> Result[Bool, E] {
  match memory_word_bytes(word_size) {
    None => Ok(true)
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) =>
            match f(addr, word) {
              Ok(false) => return Ok(false)
              Ok(true) => ()
              Err(reason) => return Err(reason)
            }
          Err(_) => return Ok(true)
        }
        offset = offset + word_bytes
      }
      Ok(true)
    }
  }
}

///|
pub fn[E] Memory::count_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[Bool, E],
  word_size? : Int = 8,
) -> Result[Int, E] {
  self.foldi_result(
    0,
    (addr, word, total) => {
      match f(addr, word) {
        Ok(true) => Ok(total + 1)
        Ok(false) => Ok(total)
        Err(reason) => Err(reason)
      }
    },
    word_size~,
  )
}

///|
pub fn[A, E] Memory::find_map_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[A?, E],
  word_size? : Int = 8,
) -> Result[A?, E] {
  match memory_word_bytes(word_size) {
    None => Ok(None)
    Some(word_bytes) => {
      let finish = self.length() - word_bytes
      let mut offset = 0
      while offset <= finish {
        let addr = self.min_addr() + offset.to_uint64()
        match self.load(addr, width=word_size) {
          Ok(word) =>
            match f(addr, word) {
              Ok(Some(value)) => return Ok(Some(value))
              Ok(None) => ()
              Err(reason) => return Err(reason)
            }
          Err(_) => return Ok(None)
        }
        offset = offset + word_bytes
      }
      Ok(None)
    }
  }
}

///|
pub fn[E] Memory::find_if_result(
  self : Memory,
  f : (UInt64, @types.Word) -> Result[Bool, E],
  word_size? : Int = 8,
) -> Result[@types.Word?, E] {
  self.find_map_result(
    (addr, word) => {
      match f(addr, word) {
        Ok(true) => Ok(Some(word))
        Ok(false) => Ok(None)
        Err(reason) => Err(reason)
      }
    },
    word_size~,
  )
}

///|
pub fn MemoryInputReader::word(word_size~ : Int) -> MemoryInputReader {
  { width_value: word_size, signed_value: false, }
}

///|
pub fn MemoryInputReader::int8() -> MemoryInputReader {
  { width_value: 8, signed_value: true, }
}

///|
pub fn MemoryInputReader::uint8() -> MemoryInputReader {
  { width_value: 8, signed_value: false, }
}

///|
pub fn MemoryInputReader::int16() -> MemoryInputReader {
  { width_value: 16, signed_value: true, }
}

///|
pub fn MemoryInputReader::uint16() -> MemoryInputReader {
  { width_value: 16, signed_value: false, }
}

///|
pub fn MemoryInputReader::int32() -> MemoryInputReader {
  { width_value: 32, signed_value: true, }
}

///|
pub fn MemoryInputReader::int64() -> MemoryInputReader {
  { width_value: 64, signed_value: true, }
}

///|
pub fn MemoryInputReader::int128() -> MemoryInputReader {
  { width_value: 128, signed_value: true, }
}

///|
pub fn MemoryInputReader::int256() -> MemoryInputReader {
  { width_value: 256, signed_value: true, }
}

///|
pub fn MemoryInputReader::run(
  self : MemoryInputReader,
  memory : Memory,
  addr : UInt64,
) -> Result[(@types.Word, UInt64), String] {
  if self.width_value <= 0 || self.width_value % 8 != 0 {
    Err("memory input reader width must be a positive multiple of 8")
  } else {
    match memory.load(addr, width=self.width_value) {
      Ok(word) => {
        let value = if self.signed_value {
          word.signed()
        } else {
          word.unsigned()
        }
        Ok((value, addr + (self.width_value / 8).to_uint64()))
      }
      Err(reason) => Err(reason)
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
      Ok({ ..self, data_value: Bytes::from_array(data), })
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
