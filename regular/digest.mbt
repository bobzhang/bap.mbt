///|
pub(all) struct Digest(String) derive(Eq, Debug)

///|
pub fn Digest::to_string(self : Digest) -> String {
  self.0
}

///|
pub impl Printable for Digest with fn to_string(self) {
  self.0
}

///|
pub fn digest_bytes(bytes : BytesView) -> Digest {
  let mut hash : UInt64 = 0xcbf29ce484222325
  for b in bytes {
    hash = hash ^ b.to_uint64()
    hash = hash * 0x100000001b3
  }
  Digest(hash.to_string(radix=16).pad_start(16, '0'))
}

///|
pub fn digest_string(text : StringView) -> Digest {
  let mut hash : UInt64 = 0xcbf29ce484222325
  for ch in text {
    hash = hash ^ ch.to_uint().to_uint64()
    hash = hash * 0x100000001b3
  }
  Digest(hash.to_string(radix=16).pad_start(16, '0'))
}
