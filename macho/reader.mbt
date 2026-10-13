///|
/// A malformed Mach-O input; public entry points report it as
/// `Err(message)`.
priv suberror Malformed {
  Malformed(String)
}

///|
fn[T] catch_malformed(f : () -> T raise Malformed) -> Result[T, String] {
  try f() catch {
    Malformed(reason) => Err(reason)
  } noraise {
    x => Ok(x)
  }
}

///|
/// A reader over the bytes of a (thin) Mach-O file; every offset is
/// relative to the start of the file.
priv struct Reader {
  data : Bytes
  endian : @bitvec.Endian
}

///|
fn Reader::check(
  self : Reader,
  offset : Int32,
  bytes : Int32,
  what : String,
) -> Unit raise Malformed {
  if offset < 0 || bytes < 0 || offset > self.data.length() - bytes {
    raise Malformed("\{what} is out of bounds")
  }
}

///|
fn Reader::uint(
  self : Reader,
  offset : Int32,
  bytes : Int32,
) -> UInt64 raise Malformed {
  self.check(offset, bytes, "Mach-O field")
  let mut value = 0UL
  for i in 0..<bytes {
    let shift = match self.endian {
      LittleEndian => i * 8
      BigEndian => (bytes - 1 - i) * 8
    }
    value = value | (self.data[offset + i].to_uint64() << shift)
  }
  value
}

///|
fn Reader::u8(self : Reader, offset : Int32) -> Int32 raise Malformed {
  self.uint(offset, 1).to_int()
}

///|
fn Reader::u16(self : Reader, offset : Int32) -> Int32 raise Malformed {
  self.uint(offset, 2).to_int()
}

///|
fn Reader::u32(self : Reader, offset : Int32) -> UInt32 raise Malformed {
  self.uint(offset, 4).to_uint()
}

///|
fn Reader::u64(self : Reader, offset : Int32) -> UInt64 raise Malformed {
  self.uint(offset, 8)
}

///|
/// A 32-bit field that is used as a size, a count or an offset.
fn Reader::int32(self : Reader, offset : Int32) -> Int32 raise Malformed {
  let value = self.uint(offset, 4)
  if value > 0x7fffffffUL {
    raise Malformed("Mach-O field at \{offset} is too large")
  }
  value.to_int()
}

///|
/// Decodes bytes as UTF-8 when valid, otherwise byte per character.
fn decode_name(bytes : BytesView) -> String {
  @utf8.decode(bytes) catch {
    _ =>
      String::from_array(bytes.to_array().map(b => b.to_int().unsafe_to_char()))
  }
}

///|
/// A fixed-size, possibly not null-terminated, name (`segname`,
/// `sectname`).
fn Reader::fixed_name(
  self : Reader,
  offset : Int32,
  size : Int32,
) -> String raise Malformed {
  self.check(offset, size, "Mach-O name")
  let mut stop = offset
  while stop < offset + size && self.data[stop] != b'\x00' {
    stop = stop + 1
  }
  decode_name(self.data[offset:stop])
}

///|
/// A null-terminated string at `offset` that must start before `limit`;
/// an unterminated string ends at `limit`.
fn Reader::cstring(
  self : Reader,
  offset : Int32,
  limit : Int32,
) -> String raise Malformed {
  let limit = if limit > self.data.length() {
    self.data.length()
  } else {
    limit
  }
  if offset < 0 || offset >= limit {
    raise Malformed("Mach-O string offset is out of bounds")
  }
  let mut stop = offset
  while stop < limit && self.data[stop] != b'\x00' {
    stop = stop + 1
  }
  decode_name(self.data[offset:stop])
}
