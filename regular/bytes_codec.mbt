///|
fn bytes_hex_digit(value : Int) -> Char {
  if value < 10 {
    (value + '0').unsafe_to_char()
  } else {
    (value - 10 + 'a').unsafe_to_char()
  }
}

///|
fn bytes_hex_value(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0')
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a' + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A' + 10)
  } else {
    None
  }
}

///|
pub fn bytes_to_hex(bytes : BytesView) -> String {
  let out = StringBuilder()
  for byte in bytes {
    let value = byte.to_int()
    out.write_char(bytes_hex_digit(value >> 4))
    out.write_char(bytes_hex_digit(value & 0x0f))
  }
  out.to_string()
}

///|
pub fn bytes_from_hex(text : StringView) -> Result[Bytes, String] {
  let nibbles : Array[Int] = []
  for c in text {
    match bytes_hex_value(c) {
      Some(value) => nibbles.push(value)
      None => return Err("invalid hex byte digit \{c}")
    }
  }
  if nibbles.length() % 2 != 0 {
    Err("hex byte text must contain an even number of digits")
  } else {
    let out : Array[Byte] = []
    let mut i = 0
    while i < nibbles.length() {
      out.push(((nibbles[i] << 4) | nibbles[i + 1]).to_byte())
      i = i + 2
    }
    Ok(Bytes::from_array(out))
  }
}

///|
pub fn bytes_to_sexp_atom(bytes : BytesView) -> String {
  "#bytes:" + bytes_to_hex(bytes)
}

///|
pub fn bytes_from_sexp_atom(text : StringView) -> Result[Bytes, String] {
  if text.has_prefix("#bytes:") {
    bytes_from_hex(text[7:])
  } else {
    Err("expected #bytes:<hex> atom")
  }
}

///|
pub fn bytes_bin_size(bytes : BytesView) -> Int {
  4 + bytes.length()
}

///|
fn bytes_write_u32_le(out : Array[Byte], offset : Int, value : Int) -> Unit {
  out[offset] = (value & 0xff).to_byte()
  out[offset + 1] = ((value >> 8) & 0xff).to_byte()
  out[offset + 2] = ((value >> 16) & 0xff).to_byte()
  out[offset + 3] = ((value >> 24) & 0xff).to_byte()
}

///|
fn bytes_read_u32_le(data : BytesView, offset : Int) -> Result[Int, String] {
  if offset < 0 || offset + 4 > data.length() {
    Err("truncated byte length prefix")
  } else {
    let value = data[offset].to_uint64() |
      (data[offset + 1].to_uint64() << 8) |
      (data[offset + 2].to_uint64() << 16) |
      (data[offset + 3].to_uint64() << 24)
    if value > 0x7fffffff {
      Err("byte payload length is too large")
    } else {
      Ok(value.to_int())
    }
  }
}

///|
pub fn bytes_bin_write(bytes : BytesView) -> Bytes {
  let len = bytes.length()
  let out = Array::make(bytes_bin_size(bytes), b'\x00')
  bytes_write_u32_le(out, 0, len)
  for i in 0..<len {
    out[i + 4] = bytes[i]
  }
  Bytes::from_array(out)
}

///|
pub fn bytes_bin_read(
  data : BytesView,
  pos? : Int = 0,
) -> Result[(Bytes, Int), String] {
  match bytes_read_u32_le(data, pos) {
    Ok(len) => {
      let start = pos + 4
      let stop = start + len
      if stop > data.length() {
        Err("truncated byte payload")
      } else {
        Ok((data[start:stop].to_owned(), stop))
      }
    }
    Err(reason) => Err(reason)
  }
}
