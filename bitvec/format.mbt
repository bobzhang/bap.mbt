///|
fn hex_digit(value : Int) -> Char {
  if value < 10 {
    (value + '0').unsafe_to_char()
  } else {
    (value - 10 + 'a').unsafe_to_char()
  }
}

///|
fn parse_hex_digit(c : Char) -> Int raise BitVecError {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a' + 10
  } else if c >= 'A' && c <= 'F' {
    c.to_int() - 'A' + 10
  } else {
    raise InvalidHexDigit(c)
  }
}

///|
pub fn from_hex(width~ : Int, text : StringView) -> BitVec raise BitVecError {
  let source = if text.has_prefix("0x") || text.has_prefix("0X") {
    text[2:]
  } else {
    text
  }
  let mut acc = zero(width~)
  for c in source {
    let digit = parse_hex_digit(c)
    acc = acc.lshift(4).bit_or(of_int(width~, digit))
  }
  acc
}

///|
fn parse_string_value(
  width : Int,
  text : StringView,
) -> BitVec raise BitVecError {
  if text.has_prefix("0x") || text.has_prefix("0X") {
    from_hex(width~, text)
  } else {
    let source = text.to_owned()
    let value = try @string.parse_int(source) catch {
      _ => raise InvalidLiteral(source)
    } noraise {
      value => value
    }
    of_int(width~, value)
  }
}

///|
pub fn from_string(text : StringView) -> BitVec raise BitVecError {
  let source = text.to_owned()
  match source {
    "false" => b0()
    "true" => b1()
    _ =>
      match source.split_once(":") {
        None => raise InvalidLiteral(source)
        Some((digits, suffix)) => {
          let width_text = if suffix.has_suffix("u") || suffix.has_suffix("s") {
            suffix[:suffix.length() - 1]
          } else {
            suffix
          }
          let width_source = width_text.to_owned()
          let width = try @string.parse_int(width_source) catch {
            _ => raise InvalidLiteral(source)
          } noraise {
            value => value
          }
          parse_string_value(width, digits)
        }
      }
  }
}

///|
pub fn BitVec::to_hex(self : BitVec, prefix? : Bool = true) -> String {
  let digits = Int::max(1, (self.width + 3) / 4)
  let builder = StringBuilder()
  if prefix {
    builder.write_string("0x")
  }
  for k in 0..<digits {
    let nibble_index = digits - 1 - k
    let bit = nibble_index * 4
    let limb = bit / 64
    let shift = bit % 64
    let value = ((self.limbs[limb] >> shift) & 0xf).to_int()
    builder.write_char(hex_digit(value))
  }
  builder.to_string()
}

///|
pub fn BitVec::to_string(self : BitVec) -> String {
  "\{self.to_hex()}:\{self.width}u"
}

///|
pub fn BitVec::to_bytes(self : BitVec, endian~ : Endian) -> Bytes {
  let len = (self.width + 7) / 8
  let bytes = Array::make(len, b'\x00')
  for i in 0..<len {
    let bit = i * 8
    let limb = bit / 64
    let shift = bit % 64
    let byte = ((self.limbs[limb] >> shift) & 0xff).to_byte()
    match endian {
      LittleEndian => bytes[i] = byte
      BigEndian => bytes[len - 1 - i] = byte
    }
  }
  Bytes::from_array(bytes)
}

///|
pub fn of_bytes(
  bytes : BytesView,
  endian~ : Endian,
  width? : Int = -1,
) -> BitVec raise BitVecError {
  let actual_width = if width < 0 { bytes.length() * 8 } else { width }
  let mut acc = zero(width=actual_width)
  for i in 0..<bytes.length() {
    let index = match endian {
      LittleEndian => bytes.length() - 1 - i
      BigEndian => i
    }
    acc = acc
      .lshift(8)
      .bit_or(of_uint64(width=actual_width, bytes[index].to_uint64()))
  }
  acc
}
