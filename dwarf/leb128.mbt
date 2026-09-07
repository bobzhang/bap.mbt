///|
struct Leb128 {
  negative : Bool
  data : Array[Byte]
} derive(Eq, Debug)

///|
pub extend Leb128 with Eq::{not_equal, equal}

///|
pub extend Leb128 with Debug::{to_repr}

///|
fn leb128_from_data(data : Array[Byte], negative : Bool) -> Leb128 {
  { negative, data: data.copy(), }
}

///|
fn leb128_of_uint64(value : UInt64) -> Leb128 {
  let data = []
  let mut current = value
  let mut more = true
  while more {
    let mut byte = (current & 0x7fUL).to_int()
    current = current >> 7
    if current == 0UL {
      more = false
    } else {
      byte = byte | 0x80
    }
    data.push(byte.to_byte())
  }
  leb128_from_data(data, false)
}

///|
fn leb128_of_int64_signed(value : Int64) -> Leb128 {
  let data = []
  let mut current = value
  let mut more = true
  while more {
    let mut byte = (current & 0x7fL).to_int()
    let sign_bit_set = (byte & 0x40) != 0
    current = current >> 7
    if (current == 0L && !sign_bit_set) || (current == -1L && sign_bit_set) {
      more = false
    } else {
      byte = byte | 0x80
    }
    data.push(byte.to_byte())
  }
  leb128_from_data(data, value < 0L)
}

///|
pub fn Leb128::of_int(value : Int, signed? : Bool = false) -> Leb128 {
  if signed {
    leb128_of_int64_signed(value.to_int64())
  } else {
    leb128_of_uint64(value.reinterpret_as_uint().to_uint64())
  }
}

///|
pub fn Leb128::of_int32(value : Int, signed? : Bool = false) -> Leb128 {
  Leb128::of_int(value, signed~)
}

///|
pub fn Leb128::of_int64(value : Int64, signed? : Bool = false) -> Leb128 {
  if signed {
    leb128_of_int64_signed(value)
  } else {
    leb128_of_uint64(value.reinterpret_as_uint64())
  }
}

///|
pub fn Leb128::read(
  data : BytesView,
  signed? : Bool = false,
  pos? : Int = 0,
) -> Result[(Leb128, Int), String] {
  if pos < 0 || pos > data.length() {
    return Err("LEB128 read position is out of bounds")
  }
  let bytes = []
  let mut index = pos
  let mut done = false
  while !done {
    if index >= data.length() {
      return Err("truncated LEB128 value")
    }
    let byte = data[index]
    bytes.push(byte)
    index = index + 1
    done = (byte.to_int() & 0x80) == 0
    if bytes.length() > 10 {
      return Err("LEB128 value is too large")
    }
  }
  let last = bytes[bytes.length() - 1].to_int()
  Ok((leb128_from_data(bytes, signed && (last & 0x40) != 0), index))
}

///|
pub fn Leb128::size(self : Leb128) -> Int {
  self.data.length().max(1)
}

///|
pub fn Leb128::is_negative(self : Leb128) -> Bool {
  self.negative
}

///|
pub fn Leb128::bytes(self : Leb128) -> Bytes {
  Bytes::from_array(self.data.copy())
}

///|
pub fn Leb128::write(self : Leb128) -> Bytes {
  self.bytes()
}

///|
fn Leb128::to_uint64_bits(self : Leb128) -> Result[UInt64, String] {
  let mut result = 0UL
  let mut shift = 0
  for byte in self.data {
    let low = (byte.to_int() & 0x7f).to_uint64()
    if shift >= 64 {
      if low != 0UL {
        return Err("LEB128 value does not fit in 64 bits")
      }
    } else {
      result = result | (low << shift)
    }
    shift = shift + 7
  }
  if self.negative && shift < 64 {
    result = result | (UInt64::lnot(0UL) << shift)
  }
  Ok(result)
}

///|
pub fn Leb128::to_int64(self : Leb128) -> Result[Int64, String] {
  match self.to_uint64_bits() {
    Ok(bits) => Ok(bits.reinterpret_as_int64())
    Err(reason) => Err(reason)
  }
}

///|
pub fn Leb128::to_int(self : Leb128) -> Result[Int, String] {
  match self.to_int64() {
    Ok(value) =>
      if value < -2147483648L || value > 2147483647L {
        Err("LEB128 value does not fit in Int")
      } else {
        Ok(value.to_int())
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn Leb128::to_int32(self : Leb128) -> Result[Int, String] {
  self.to_int()
}
