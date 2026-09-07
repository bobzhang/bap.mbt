///|
pub(all) struct Digest(String) derive(Eq, Hash, Debug)

///|
pub extend Digest with Eq::{not_equal, equal}

///|
pub extend Digest with Hash::{hash, hash_combine}

///|
pub extend Digest with Debug::{to_repr}

///|
pub fn Digest::to_string(self : Digest) -> String {
  self.0
}

///|
pub fn Digest::compare(self : Digest, other : Digest) -> Int {
  self.0.compare(other.0)
}

///|
pub impl Printable for Digest with fn to_string(self) {
  self.0
}

///|
pub fn Digest::create(namespace_name~ : StringView) -> Digest {
  digest_string(namespace_name)
}

///|
pub fn Digest::add(self : Digest, text : StringView) -> Digest {
  digest_string(self.0 + ":" + text.to_owned())
}

///|
pub fn Digest::add_bytes(self : Digest, bytes : BytesView) -> Digest {
  self.add(digest_bytes(bytes).to_string())
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

///|
pub fn digest(namespace_name~ : StringView, text : StringView) -> Digest {
  Digest::create(namespace_name~).add(text)
}
