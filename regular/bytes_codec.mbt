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
pub(all) enum BytesFoldStep[A, R] {
  BytesContinue(A)
  BytesStop(R)
} derive(Eq, Debug)

///|
pub fn bytes_empty() -> Bytes {
  Bytes::new(0)
}

///|
pub fn bytes_create(length : Int) -> Result[Bytes, String] {
  if length < 0 {
    Err("byte length is negative")
  } else {
    Ok(Bytes::new(length))
  }
}

///|
pub fn bytes_make(length : Int, byte : Byte) -> Result[Bytes, String] {
  if length < 0 {
    Err("byte length is negative")
  } else {
    Ok(Bytes::from_array(Array::make(length, byte)))
  }
}

///|
pub fn bytes_init(length : Int, f : (Int) -> Byte) -> Result[Bytes, String] {
  if length < 0 {
    Err("byte length is negative")
  } else {
    Ok(Bytes::from_array(Array::makei(length, f)))
  }
}

///|
pub fn bytes_copy(bytes : BytesView) -> Bytes {
  Bytes::makei(bytes.length(), i => bytes[i])
}

///|
pub fn bytes_length(bytes : BytesView) -> Int {
  bytes.length()
}

///|
pub fn bytes_get(bytes : BytesView, pos : Int) -> Byte? {
  bytes.get(pos)
}

///|
pub fn bytes_equal(left : BytesView, right : BytesView) -> Bool {
  left == right
}

///|
pub fn bytes_compare(left : BytesView, right : BytesView) -> Int {
  left.compare(right)
}

///|
pub fn bytes_hash(bytes : BytesView) -> Int {
  bytes.hash()
}

///|
pub fn bytes_sub(
  bytes : BytesView,
  pos : Int,
  len : Int,
) -> Result[Bytes, String] {
  if pos < 0 || len < 0 || pos > bytes.length() || len > bytes.length() - pos {
    Err("byte slice is out of bounds")
  } else {
    Ok(bytes[pos:pos + len].to_owned())
  }
}

///|
pub fn bytes_subo(
  bytes : BytesView,
  pos? : Int = 0,
  len? : Int,
) -> Result[Bytes, String] {
  let slice_len = match len {
    Some(len) => len
    None => bytes.length() - pos
  }
  bytes_sub(bytes, pos, slice_len)
}

///|
pub fn bytes_extend(
  bytes : BytesView,
  left : Int,
  right : Int,
) -> Result[Bytes, String] {
  let new_len = bytes.length() + left + right
  if new_len < 0 {
    Err("extended byte length is negative")
  } else {
    let out = Array::make(new_len, b'\x00')
    let dst_start = if left > 0 { left } else { 0 }
    let src_start = if left < 0 { -left } else { 0 }
    let src_available = bytes.length() - src_start
    let dst_available = new_len - dst_start
    let copy_len = if src_available < dst_available {
      src_available
    } else {
      dst_available
    }
    if copy_len > 0 {
      for i in 0..<copy_len {
        out[dst_start + i] = bytes[src_start + i]
      }
    }
    Ok(Bytes::from_array(out))
  }
}

///|
pub fn bytes_is_empty(bytes : BytesView) -> Bool {
  bytes.length() == 0
}

///|
pub fn bytes_to_array(bytes : BytesView) -> Array[Byte] {
  let out = []
  for byte in bytes {
    out.push(byte)
  }
  out
}

///|
pub fn bytes_to_list(bytes : BytesView) -> @list.List[Byte] {
  @list.from_array(bytes_to_array(bytes))
}

///|
fn ascii_space_byte(byte : Byte) -> Bool {
  byte == b' ' ||
  byte == b'\t' ||
  byte == b'\n' ||
  byte == b'\r' ||
  byte == b'\x0b' ||
  byte == b'\x0c'
}

///|
pub fn bytes_trim(bytes : BytesView) -> Bytes {
  let mut start = 0
  while start < bytes.length() && ascii_space_byte(bytes[start]) {
    start = start + 1
  }
  let mut stop = bytes.length()
  while stop > start && ascii_space_byte(bytes[stop - 1]) {
    stop = stop - 1
  }
  bytes[start:stop].to_owned()
}

///|
pub fn bytes_iteri(bytes : BytesView, f : (Int, Byte) -> Unit) -> Unit {
  for i in 0..<bytes.length() {
    f(i, bytes[i])
  }
}

///|
pub fn bytes_iter(bytes : BytesView, f : (Byte) -> Unit) -> Unit {
  bytes_iteri(bytes, (_, byte) => f(byte))
}

///|
pub fn[A] bytes_fold(bytes : BytesView, init : A, f : (A, Byte) -> A) -> A {
  let mut acc = init
  for byte in bytes {
    acc = f(acc, byte)
  }
  acc
}

///|
pub fn[A, E] bytes_fold_result(
  bytes : BytesView,
  init : A,
  f : (A, Byte) -> Result[A, E],
) -> Result[A, E] {
  let mut acc = init
  for byte in bytes {
    match f(acc, byte) {
      Ok(next) => acc = next
      Err(reason) => return Err(reason)
    }
  }
  Ok(acc)
}

///|
pub fn[A, R] bytes_fold_until(
  bytes : BytesView,
  init~ : A,
  f~ : (A, Byte) -> BytesFoldStep[A, R],
  finish~ : (A) -> R,
) -> R {
  let mut acc = init
  for byte in bytes {
    match f(acc, byte) {
      BytesContinue(next) => acc = next
      BytesStop(result) => return result
    }
  }
  finish(acc)
}

///|
pub fn[A] bytes_find_map(bytes : BytesView, f : (Byte) -> A?) -> A? {
  for byte in bytes {
    match f(byte) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
pub fn bytes_find(bytes : BytesView, f : (Byte) -> Bool) -> Byte? {
  bytes_find_map(bytes, byte => if f(byte) { Some(byte) } else { None })
}

///|
pub fn bytes_exists(bytes : BytesView, f : (Byte) -> Bool) -> Bool {
  bytes_find(bytes, f) is Some(_)
}

///|
pub fn bytes_for_all(bytes : BytesView, f : (Byte) -> Bool) -> Bool {
  for byte in bytes {
    if !f(byte) {
      return false
    }
  }
  true
}

///|
pub fn bytes_count(bytes : BytesView, f : (Byte) -> Bool) -> Int {
  let mut total = 0
  for byte in bytes {
    if f(byte) {
      total = total + 1
    }
  }
  total
}

///|
pub fn bytes_min_elt(bytes : BytesView) -> Byte? {
  if bytes.length() == 0 {
    return None
  }
  let mut best = bytes[0]
  for i in 1..<bytes.length() {
    if bytes[i] < best {
      best = bytes[i]
    }
  }
  Some(best)
}

///|
pub fn bytes_max_elt(bytes : BytesView) -> Byte? {
  if bytes.length() == 0 {
    return None
  }
  let mut best = bytes[0]
  for i in 1..<bytes.length() {
    if bytes[i] > best {
      best = bytes[i]
    }
  }
  Some(best)
}

///|
pub fn bytes_map(bytes : BytesView, f : (Byte) -> Byte) -> Bytes {
  Bytes::from_array(bytes_to_array(bytes).map(f))
}

///|
pub fn bytes_mapi(bytes : BytesView, f : (Int, Byte) -> Byte) -> Bytes {
  Bytes::from_array(Array::makei(bytes.length(), i => f(i, bytes[i])))
}

///|
pub fn bytes_cat(left : BytesView, right : BytesView) -> Bytes {
  let out = []
  for byte in left {
    out.push(byte)
  }
  for byte in right {
    out.push(byte)
  }
  Bytes::from_array(out)
}

///|
pub fn bytes_concat(sep : BytesView, chunks : ArrayView[Bytes]) -> Bytes {
  let out = []
  for i, chunk in chunks {
    if i > 0 {
      for byte in sep {
        out.push(byte)
      }
    }
    for byte in chunk {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
}

///|
pub fn bytes_index_from(bytes : BytesView, start : Int, needle : Byte) -> Int? {
  if start < 0 || start >= bytes.length() {
    None
  } else {
    for i in start..<bytes.length() {
      if bytes[i] == needle {
        return Some(i)
      }
    }
    None
  }
}

///|
pub fn bytes_index(bytes : BytesView, needle : Byte) -> Int? {
  bytes_index_from(bytes, 0, needle)
}

///|
pub fn bytes_rindex_from(bytes : BytesView, start : Int, needle : Byte) -> Int? {
  if bytes.length() == 0 || start < 0 {
    None
  } else {
    let mut i = if start >= bytes.length() { bytes.length() - 1 } else { start }
    while i >= 0 {
      if bytes[i] == needle {
        return Some(i)
      }
      if i == 0 {
        return None
      }
      i = i - 1
    }
    None
  }
}

///|
pub fn bytes_rindex(bytes : BytesView, needle : Byte) -> Int? {
  bytes_rindex_from(bytes, bytes.length() - 1, needle)
}

///|
pub fn bytes_contains_from(
  bytes : BytesView,
  start : Int,
  needle : Byte,
) -> Bool {
  bytes_index_from(bytes, start, needle) is Some(_)
}

///|
pub fn bytes_rcontains_from(
  bytes : BytesView,
  start : Int,
  needle : Byte,
) -> Bool {
  bytes_rindex_from(bytes, start, needle) is Some(_)
}

///|
pub fn bytes_contains(bytes : BytesView, needle : Byte) -> Bool {
  bytes_contains_from(bytes, 0, needle)
}

///|
pub fn bytes_mem(bytes : BytesView, needle : Byte) -> Bool {
  bytes_contains(bytes, needle)
}

///|
fn ascii_upper_byte(byte : Byte) -> Byte {
  if byte >= b'a' && byte <= b'z' {
    (byte.to_int() - 32).to_byte()
  } else {
    byte
  }
}

///|
fn ascii_lower_byte(byte : Byte) -> Byte {
  if byte >= b'A' && byte <= b'Z' {
    (byte.to_int() + 32).to_byte()
  } else {
    byte
  }
}

///|
pub fn bytes_uppercase(bytes : BytesView) -> Bytes {
  bytes_map(bytes, ascii_upper_byte)
}

///|
pub fn bytes_lowercase(bytes : BytesView) -> Bytes {
  bytes_map(bytes, ascii_lower_byte)
}

///|
pub fn bytes_capitalize(bytes : BytesView) -> Bytes {
  bytes_mapi(bytes, (i, byte) => {
    if i == 0 {
      ascii_upper_byte(byte)
    } else {
      byte
    }
  })
}

///|
pub fn bytes_uncapitalize(bytes : BytesView) -> Bytes {
  bytes_mapi(bytes, (i, byte) => {
    if i == 0 {
      ascii_lower_byte(byte)
    } else {
      byte
    }
  })
}

///|
fn bytes_push_decimal_escape(out : Array[Byte], value : Int) -> Unit {
  out.push(b'\\')
  out.push((value / 100 + 48).to_byte())
  out.push((value / 10 % 10 + 48).to_byte())
  out.push((value % 10 + 48).to_byte())
}

///|
pub fn bytes_escaped(bytes : BytesView) -> Bytes {
  let out = []
  for byte in bytes {
    if byte == b'"' {
      out.push(b'\\')
      out.push(b'"')
    } else if byte == b'\\' {
      out.push(b'\\')
      out.push(b'\\')
    } else if byte == b'\n' {
      out.push(b'\\')
      out.push(b'n')
    } else if byte == b'\t' {
      out.push(b'\\')
      out.push(b't')
    } else if byte == b'\r' {
      out.push(b'\\')
      out.push(b'r')
    } else if byte == b'\x08' {
      out.push(b'\\')
      out.push(b'b')
    } else if byte < b' ' || byte > b'~' {
      bytes_push_decimal_escape(out, byte.to_int())
    } else {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
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
