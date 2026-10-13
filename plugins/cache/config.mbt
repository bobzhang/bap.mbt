// Port of `Bap_cache_types.config` and `Bap_cache.Cfg`: the cache
// configuration and its on-disk representation.

///|
/// The configuration of the cache (upstream `Bap_cache_types.config`).
pub(all) struct Config {
  /// the capacity of the cache, in megabytes
  capacity : Int32
  /// the allowed excess over the capacity, in percents of the capacity
  overhead : Int32
  /// whether the garbage collector runs on startup
  gc_enabled : Bool
} derive(Eq, Debug)

///|
pub extend Config with Eq::{equal, not_equal}

///|
pub extend Config with Debug::{to_repr}

///|
/// A configuration; the defaults are 4 Gb, 25% overhead, GC enabled.
pub fn Config::new(
  capacity~ : Int32 = 4 * 1024,
  overhead~ : Int32 = 25,
  gc_enabled~ : Bool = true,
) -> Config {
  { capacity, overhead, gc_enabled, }
}

///|
/// The default configuration (upstream `Cfg.default`).
pub fn Config::default() -> Config {
  Config::new()
}

///|
/// The version of the configuration file format.
pub let config_version : Int32 = 3

///|
/// The name of the configuration file in the cache root (`config.3`).
pub let config_file_name : String = "config.\{config_version}"

///|
/// The size (in megabytes) above which the garbage collector shrinks the
/// cache on startup: `capacity + capacity * overhead / 100`.
pub fn Config::gc_threshold(self : Config) -> Int32 {
  self.capacity + self.capacity * self.overhead / 100
}

///|
/// The size (in kilobytes) to which the garbage collector shrinks the
/// cache: `capacity - capacity * overhead / 100`, but not negative.
pub fn Config::lower_bound(self : Config) -> Int32 {
  let mb = self.capacity - self.capacity * self.overhead / 100
  (if mb < 0 { 0 } else { mb }) * 1024
}

// The configuration file is the `bin_prot` serialization of the record,
// as written by upstream BAP: three variable-length integers and a
// boolean byte.

///|
fn bin_write_int(buf : Array[Byte], n : Int32) -> Unit {
  let put = (value : Int32, bytes : Int32) => {
    for i in 0..<bytes {
      buf.push((value >> (8 * i)).to_byte())
    }
  }
  if n >= 0 && n < 0x80 {
    buf.push(n.to_byte())
  } else if n < 0 && n >= -0x80 {
    buf.push(0xff)
    buf.push(n.to_byte())
  } else if n >= -0x8000 && n < 0x8000 {
    buf.push(0xfe)
    put(n, 2)
  } else {
    buf.push(0xfd)
    put(n, 4)
  }
}

///|
fn bin_read_int(data : BytesView, pos : Ref[Int32]) -> Int32? {
  let get = (bytes : Int32) => {
    guard pos.val + bytes <= data.length() else { None }
    let mut v : Int64 = 0
    for i in 0..<bytes {
      v = v | (data[pos.val + i].to_int64() << (8 * i))
    }
    pos.val += bytes
    // sign-extend
    let shift = 64 - 8 * bytes
    Some(v << shift >> shift)
  }
  guard pos.val < data.length() else { None }
  let code = data[pos.val].to_int()
  pos.val += 1
  let value = match code {
    0xff => get(1)
    0xfe => get(2)
    0xfd => get(4)
    0xfc => get(8)
    _ if code < 0x80 => Some(code.to_int64())
    _ => None
  }
  match value {
    Some(v) if v >= -0x80000000L && v <= 0x7fffffffL => Some(v.to_int())
    _ => None
  }
}

///|
/// The `bin_prot` serialization of the configuration (the contents of
/// `config.3`).
pub fn Config::to_bytes(self : Config) -> Bytes {
  let buf : Array[Byte] = []
  bin_write_int(buf, self.capacity)
  bin_write_int(buf, self.overhead)
  buf.push(if self.gc_enabled { 1 } else { 0 })
  Bytes::from_array(buf)
}

///|
/// Reads a configuration serialized with `Config::to_bytes`.
pub fn Config::of_bytes(data : BytesView) -> Config? {
  let pos = Ref(0)
  guard bin_read_int(data, pos) is Some(capacity) &&
    bin_read_int(data, pos) is Some(overhead) &&
    data.get(pos.val) is Some(flag) &&
    flag.to_int() <= 1 else {
    None
  }
  Some({ capacity, overhead, gc_enabled: flag == 1, })
}
