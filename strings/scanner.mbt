///|
pub(all) struct StringsScanner {}

///|
fn strings_is_whitespace(byte : Byte) -> Bool {
  byte == b'\t' ||
  byte == b'\n' ||
  byte == b'\r' ||
  byte == b'\x0b' ||
  byte == b'\x0c' ||
  byte == b' '
}

///|
fn strings_is_printable(byte : Byte) -> Bool {
  (byte >= b' ' && byte <= b'~') || strings_is_whitespace(byte)
}

///|
fn strings_default_stop(byte : Byte) -> Bool {
  !strings_is_printable(byte)
}

///|
pub fn StringsScanner::next(
  read : (Int) -> Byte?,
  offset : Int,
  is_stop? : (Byte) -> Bool = strings_default_stop,
) -> Bytes {
  let bytes = []
  let mut pos = offset
  let mut running = true
  while running {
    match read(pos) {
      Some(byte) =>
        if is_stop(byte) {
          running = false
        } else {
          bytes.push(byte)
          pos = pos + 1
        }
      None => running = false
    }
  }
  Bytes::from_array(bytes)
}

///|
pub fn StringsScanner::run(
  read : (Int) -> Byte?,
  offset : Int,
  is_stop? : (Byte) -> Bool = strings_default_stop,
) -> Array[(Int, Bytes)] {
  let out = []
  let mut pos = offset
  let mut running = true
  while running {
    let text = StringsScanner::next(read, pos, is_stop~)
    if text.length() != 0 {
      out.push((pos, text))
      pos = pos + text.length()
    } else {
      match read(pos) {
        Some(_) => pos = pos + 1
        None => running = false
      }
    }
  }
  out
}

///|
pub fn StringsScanner::read_bytes(data : BytesView) -> (Int) -> Byte? {
  fn(pos) {
    if pos >= 0 && pos < data.length() {
      Some(data[pos])
    } else {
      None
    }
  }
}

///|
pub fn StringsScanner::scan_bytes(
  data : BytesView,
  offset? : Int = 0,
  is_stop? : (Byte) -> Bool = strings_default_stop,
) -> Array[(Int, Bytes)] {
  StringsScanner::run(StringsScanner::read_bytes(data), offset, is_stop~)
}
