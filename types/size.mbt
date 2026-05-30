///|
pub(all) enum Size {
  R8
  R16
  R32
  R64
  R128
  R256
} derive(Eq, Debug)

///|
pub(all) enum AddrSize {
  Addr32
  Addr64
} derive(Eq, Debug)

///|
pub(all) enum WordSize {
  W32
  W64
} derive(Eq, Debug)

///|
pub(all) suberror SizeError {
  UnsupportedWordSize(Int)
  UnsupportedAddressSize(Int)
  UnsupportedAddressSizeValue(Size)
} derive(Eq, Debug)

///|
pub fn Size::in_bits(self : Size) -> Int {
  match self {
    R8 => 8
    R16 => 16
    R32 => 32
    R64 => 64
    R128 => 128
    R256 => 256
  }
}

///|
pub fn Size::in_bytes(self : Size) -> Int {
  self.in_bits() / 8
}

///|
pub fn Size::to_string(self : Size) -> String {
  "u\{self.in_bits()}"
}

///|
pub fn Size::of_int(bits : Int) -> Result[Size, String] {
  match bits {
    8 => Ok(R8)
    16 => Ok(R16)
    32 => Ok(R32)
    64 => Ok(R64)
    128 => Ok(R128)
    256 => Ok(R256)
    _ => Err("unsupported word size: \{bits}")
  }
}

///|
pub fn Size::of_int_opt(bits : Int) -> Size? {
  match Size::of_int(bits) {
    Ok(size) => Some(size)
    Err(_) => None
  }
}

///|
pub fn Size::of_int_exn(bits : Int) -> Size raise SizeError {
  match Size::of_int(bits) {
    Ok(size) => size
    Err(_) => raise UnsupportedWordSize(bits)
  }
}

///|
pub fn AddrSize::in_bits(self : AddrSize) -> Int {
  match self {
    Addr32 => 32
    Addr64 => 64
  }
}

///|
pub fn AddrSize::in_bytes(self : AddrSize) -> Int {
  self.in_bits() / 8
}

///|
pub fn AddrSize::to_string(self : AddrSize) -> String {
  "u\{self.in_bits()}"
}

///|
pub fn AddrSize::to_size(self : AddrSize) -> Size {
  match self {
    Addr32 => R32
    Addr64 => R64
  }
}

///|
pub fn Size::addr_of_int(bits : Int) -> Result[AddrSize, String] {
  match bits {
    32 => Ok(Addr32)
    64 => Ok(Addr64)
    _ => Err("unsupported address size: \{bits}")
  }
}

///|
pub fn Size::addr_of_int_opt(bits : Int) -> AddrSize? {
  match Size::addr_of_int(bits) {
    Ok(size) => Some(size)
    Err(_) => None
  }
}

///|
pub fn Size::addr_of_int_exn(bits : Int) -> AddrSize raise SizeError {
  match Size::addr_of_int(bits) {
    Ok(size) => size
    Err(_) => raise UnsupportedAddressSize(bits)
  }
}

///|
pub fn Size::to_addr_size(self : Size) -> Result[AddrSize, String] {
  match self {
    R32 => Ok(Addr32)
    R64 => Ok(Addr64)
    _ => Err("unsupported address size: \{self.in_bits()}")
  }
}

///|
pub fn Size::to_addr_size_opt(self : Size) -> AddrSize? {
  match self.to_addr_size() {
    Ok(size) => Some(size)
    Err(_) => None
  }
}

///|
pub fn Size::to_addr_size_exn(self : Size) -> AddrSize raise SizeError {
  match self.to_addr_size() {
    Ok(size) => size
    Err(_) => raise UnsupportedAddressSizeValue(self)
  }
}

///|
pub fn WordSize::in_bits(self : WordSize) -> Int {
  match self {
    W32 => 32
    W64 => 64
  }
}

///|
pub fn WordSize::in_bytes(self : WordSize) -> Int {
  self.in_bits() / 8
}

///|
pub fn WordSize::to_string(self : WordSize) -> String {
  "u\{self.in_bits()}"
}

///|
pub fn WordSize::to_size(self : WordSize) -> Size {
  match self {
    W32 => R32
    W64 => R64
  }
}

///|
pub fn Size::addr_of_word_size(size : WordSize) -> AddrSize {
  match size {
    W32 => Addr32
    W64 => Addr64
  }
}

///|
pub fn Size::word_of_addr_size(size : AddrSize) -> WordSize {
  match size {
    Addr32 => W32
    Addr64 => W64
  }
}
