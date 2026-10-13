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
pub fn Digest::compare(self : Digest, other : Digest) -> Int32 {
  self.0.compare(other.0)
}

///|
pub impl Printable for Digest with fn to_string(self) {
  self.0
}

///|
/// The digest of a namespace (upstream `Digest.create ~namespace`): the
/// MD5 of the namespace, in hexadecimal.
pub fn Digest::create(namespace_name~ : StringView) -> Digest {
  digest_string(namespace_name)
}

///|
/// Extends the digest with `text` (upstream `Digest.add d "%s" text`):
/// the MD5 of the digest followed by the text.
pub fn Digest::add(self : Digest, text : StringView) -> Digest {
  digest_string(self.0 + text.to_owned())
}

///|
/// Extends the digest with the digest of `bytes`.
pub fn Digest::add_bytes(self : Digest, bytes : BytesView) -> Digest {
  self.add(digest_bytes(bytes).to_string())
}

///|
/// The MD5 digest of `bytes`, in hexadecimal.
pub fn digest_bytes(bytes : BytesView) -> Digest {
  Digest(@digest.md5_hex(bytes))
}

///|
/// The MD5 digest of the UTF-8 encoding of `text`, in hexadecimal
/// (upstream `Digest.make`).
pub fn digest_string(text : StringView) -> Digest {
  Digest(@digest.md5_string(text))
}

///|
/// `digest(namespace_name~, text)` is
/// `Digest::create(namespace_name~).add(text)` (upstream `digest`).
pub fn digest(namespace_name~ : StringView, text : StringView) -> Digest {
  Digest::create(namespace_name~).add(text)
}
