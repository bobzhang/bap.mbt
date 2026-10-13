// MD5 digests (OCaml `Stdlib.Digest`, `Core.Md5`).
//
// BAP uses MD5 for command-line parameter digests, the context digest
// (`bap_main`) and the cache keys (`Regular.Data.Cache.Digest`). `md5`
// returns the raw 16-byte digest, `md5_hex` and `md5_string` its
// lowercase hexadecimal rendering (`Digest.to_hex`).

///|
let md5_shifts : FixedArray[Int32] = [
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5, 9,
  14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
]

///|
/// `K[i] = floor(|sin(i + 1)| * 2^32)`, the standard MD5 round constants.
let md5_constants : FixedArray[UInt32] = FixedArray::makei(64, i => {
  let v = @math.sin((i + 1).to_double()).abs() * 4294967296.0
  v.floor().to_uint64().to_uint()
})

///|
fn md5_rotl(x : UInt32, c : Int32) -> UInt32 {
  (x << c) | (x >> (32 - c))
}

///|
/// The raw 16-byte MD5 digest of `data` (`Digest.bytes`).
///
/// ```mbt check
/// test {
///   inspect(@digest.md5(b"").length(), content="16")
/// }
/// ```
pub fn md5(data : BytesView) -> Bytes {
  let len = data.length()
  let padded_len = (len + 8) / 64 * 64 + 64
  let msg = FixedArray::make(padded_len, (0 : Byte))
  for i in 0..<len {
    msg[i] = data[i]
  }
  msg[len] = 0x80
  let bit_len = len.to_uint64() * 8
  for i in 0..<8 {
    msg[padded_len - 8 + i] = (bit_len >> (8 * i)).to_byte()
  }
  let mut a0 : UInt32 = 0x67452301
  let mut b0 : UInt32 = 0xefcdab89
  let mut c0 : UInt32 = 0x98badcfe
  let mut d0 : UInt32 = 0x10325476
  let m = FixedArray::make(16, (0 : UInt32))
  for chunk = 0; chunk < padded_len; chunk = chunk + 64 {
    for j in 0..<16 {
      let o = chunk + j * 4
      m[j] = msg[o].to_uint() |
        (msg[o + 1].to_uint() << 8) |
        (msg[o + 2].to_uint() << 16) |
        (msg[o + 3].to_uint() << 24)
    }
    let mut a = a0
    let mut b = b0
    let mut c = c0
    let mut d = d0
    for i in 0..<64 {
      let (f, g) = if i < 16 {
        ((b & c) | (b.lnot() & d), i)
      } else if i < 32 {
        ((d & b) | (d.lnot() & c), (5 * i + 1) % 16)
      } else if i < 48 {
        (b ^ c ^ d, (3 * i + 5) % 16)
      } else {
        (c ^ (b | d.lnot()), 7 * i % 16)
      }
      let f2 = f + a + md5_constants[i] + m[g]
      a = d
      d = c
      c = b
      b = b + md5_rotl(f2, md5_shifts[i])
    }
    a0 = a0 + a
    b0 = b0 + b
    c0 = c0 + c
    d0 = d0 + d
  }
  let out = FixedArray::make(16, (0 : Byte))
  for i, w in [a0, b0, c0, d0] {
    for k in 0..<4 {
      out[i * 4 + k] = (w >> (8 * k)).to_byte()
    }
  }
  Bytes::from_array(out[:])
}

///|
/// The lowercase hexadecimal rendering of `bytes` (`Digest.to_hex`).
pub fn to_hex(bytes : BytesView) -> String {
  let digits = "0123456789abcdef"
  let sb = StringBuilder()
  for b in bytes {
    let v = b.to_int()
    sb.write_char(digits.get_char(v >> 4).unwrap())
    sb.write_char(digits.get_char(v & 15).unwrap())
  }
  sb.to_string()
}

///|
/// The MD5 digest of raw bytes, as lowercase hexadecimal.
pub fn md5_hex(data : BytesView) -> String {
  to_hex(md5(data))
}

///|
/// The MD5 digest of the UTF-8 encoding of `text`, as lowercase
/// hexadecimal (`Digest.(to_hex (string text))`).
///
/// ```mbt check
/// test {
///   inspect(@digest.md5_string("abc"), content="900150983cd24fb0d6963f7d28e17f72")
/// }
/// ```
pub fn md5_string(text : StringView) -> String {
  md5_hex(@utf8.encode(text))
}
