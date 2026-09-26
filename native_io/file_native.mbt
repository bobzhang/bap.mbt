///|
fn utf8_bytes_to_string(bytes : Bytes) -> String {
  let res = StringBuilder()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c == 0 {
      break
    } else if c < 0x80 {
      res.write_char(c.unsafe_to_char())
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c -= 0x10000
      res.write_char(((c >> 10) + 0xD800).unsafe_to_char())
      res.write_char(((c & 0x3FF) + 0xDC00).unsafe_to_char())
      i += 4
    }
  }
  res.to_string()
}

///|
fn string_to_utf8_bytes(text : String, append_nul : Bool) -> Bytes {
  let res : Array[Byte] = []
  let len = text.length()
  let mut i = 0
  while i < len {
    let mut c = text.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i += 1
      let low = text.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + low + 0x10000
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xC0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    } else if c < 0x10000 {
      res.push((0xE0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    } else {
      res.push((0xF0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3F)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    }
    i += 1
  }
  if append_nul {
    res.push((0).to_byte())
  }
  Bytes::from_array(res)
}

///|
#borrow(path)
extern "c" fn read_file_ffi(path : Bytes) -> Bytes = "bap_mbt_read_file"

///|
#borrow(path, data)
extern "c" fn write_file_ffi(path : Bytes, data : Bytes) -> Bytes = "bap_mbt_write_file"

///|
pub fn read_file(path : String) -> Result[Bytes, String] {
  let response = read_file_ffi(string_to_utf8_bytes(path, true))
  if response.length() == 0 {
    Err("file IO returned an empty response for \{path}")
  } else if response[0] == (0).to_byte() {
    Ok(response[1:].to_owned())
  } else {
    Err(utf8_bytes_to_string(response[1:].to_owned()))
  }
}

///|
pub fn write_file(path : String, data : BytesView) -> Result[Unit, String] {
  let response = write_file_ffi(
    string_to_utf8_bytes(path, true),
    data.to_owned(),
  )
  if response.length() == 0 {
    Err("file IO returned an empty response for \{path}")
  } else if response[0] == (0).to_byte() {
    Ok(())
  } else {
    Err(utf8_bytes_to_string(response[1:].to_owned()))
  }
}

///|
extern "c" fn host_arch_ffi() -> Int = "bap_mbt_host_arch"

///|
/// The architecture of the host, as LLVM names it (`x86_64`, `i386`,
/// `aarch64`, `arm`, `powerpc64`, `powerpc`, `riscv64`), or `unknown`.
pub fn host_architecture() -> String {
  match host_arch_ffi() {
    1 => "x86_64"
    2 => "i386"
    3 => "aarch64"
    4 => "arm"
    5 => "powerpc64"
    6 => "powerpc"
    7 => "riscv64"
    _ => "unknown"
  }
}
