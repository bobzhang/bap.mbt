// Test fixtures: small Mach-O and PE/COFF files built byte by byte, for the
// readers (`@macho`, `@coff`), the image loaders and the `bap` frontend.

///|
/// A growable file image with fixed-width integer writers.
priv struct Buf {
  bytes : Array[Byte]
  big : Bool
}

///|
fn Buf::new(size : Int32, big~ : Bool = false) -> Buf {
  { bytes: Array::make(size, b'\x00'), big, }
}

///|
fn Buf::ensure(self : Buf, size : Int32) -> Unit {
  while self.bytes.length() < size {
    self.bytes.push(b'\x00')
  }
}

///|
fn Buf::put(self : Buf, off : Int32, n : Int32, value : UInt64) -> Unit {
  self.ensure(off + n)
  for i in 0..<n {
    let shift = if self.big { (n - 1 - i) * 8 } else { i * 8 }
    self.bytes[off + i] = ((value >> shift) & 0xffUL).to_byte()
  }
}

///|
fn Buf::u16(self : Buf, off : Int32, value : Int32) -> Unit {
  self.put(off, 2, value.to_uint64())
}

///|
fn Buf::u32(self : Buf, off : Int32, value : UInt64) -> Unit {
  self.put(off, 4, value)
}

///|
fn Buf::u64(self : Buf, off : Int32, value : UInt64) -> Unit {
  self.put(off, 8, value)
}

///|
fn Buf::blob(self : Buf, off : Int32, data : BytesView) -> Unit {
  self.ensure(off + data.length())
  for i, b in data {
    self.bytes[off + i] = b
  }
}

///|
/// An ASCII string (not terminated: the buffer is zero-filled).
fn Buf::str(self : Buf, off : Int32, text : String) -> Unit {
  self.blob(off, @utf8.encode(text))
}

///|
fn Buf::to_bytes(self : Buf) -> Bytes {
  Bytes::from_array(self.bytes)
}
