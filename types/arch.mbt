///|
pub(all) enum Arch {
  X86
  X86_64
  Armv4
  Armv5
  Armv6
  Armv7
  Armv4eb
  Armv5eb
  Armv6eb
  Armv7eb
  Thumbv4
  Thumbv5
  Thumbv6
  Thumbv7
  Thumbv4eb
  Thumbv5eb
  Thumbv6eb
  Thumbv7eb
  Aarch64
  Aarch64_be
  Ppc
  Ppc64
  Ppc64le
  Mips
  Mipsel
  Mips64
  Mips64el
  Sparc
  Sparcv9
  Nvptx
  Nvptx64
  Hexagon
  R600
  Systemz
  Xcore
  UnknownArch
} derive(Eq, Debug)

///|
pub extend Arch with Eq::{not_equal}

///|
pub extend Arch with Debug::{to_repr}

///|
fn normalize_arch_name(text : String) -> String {
  match text.trim().to_lower() {
    "x86"
    | "x86-32"
    | "x86_32"
    | "ia32"
    | "ia-32"
    | "i386"
    | "i486"
    | "i586"
    | "i686" => "x86"
    "x86-64" | "x86_64" | "amd64" | "x64" | "x86_64h" => "x86_64"
    "powerpc" => "ppc"
    "arm" | "xscale" => "armv7"
    "thumb" => "thumbv7"
    "armeb" => "armv7eb"
    "thumbeb" => "thumbv7eb"
    "powerpc64" | "ppu" => "ppc64"
    "powerpc64le" => "ppc64le"
    "sparc64" => "sparcv9"
    "s390x" => "systemz"
    "arm64" => "aarch64"
    "arm64_be" => "aarch64_be"
    other => other.to_owned()
  }
}

///|
pub fn Arch::of_string(text : String) -> Arch? {
  match normalize_arch_name(text) {
    "x86" => Some(X86)
    "x86_64" => Some(X86_64)
    "armv4" => Some(Armv4)
    "armv5" => Some(Armv5)
    "armv6" => Some(Armv6)
    "armv7" => Some(Armv7)
    "armv4eb" => Some(Armv4eb)
    "armv5eb" => Some(Armv5eb)
    "armv6eb" => Some(Armv6eb)
    "armv7eb" => Some(Armv7eb)
    "thumbv4" => Some(Thumbv4)
    "thumbv5" => Some(Thumbv5)
    "thumbv6" => Some(Thumbv6)
    "thumbv7" => Some(Thumbv7)
    "thumbv4eb" => Some(Thumbv4eb)
    "thumbv5eb" => Some(Thumbv5eb)
    "thumbv6eb" => Some(Thumbv6eb)
    "thumbv7eb" => Some(Thumbv7eb)
    "aarch64" => Some(Aarch64)
    "aarch64_be" => Some(Aarch64_be)
    "ppc" => Some(Ppc)
    "ppc64" => Some(Ppc64)
    "ppc64le" => Some(Ppc64le)
    "mips" => Some(Mips)
    "mipsel" => Some(Mipsel)
    "mips64" => Some(Mips64)
    "mips64el" => Some(Mips64el)
    "sparc" => Some(Sparc)
    "sparcv9" => Some(Sparcv9)
    "nvptx" => Some(Nvptx)
    "nvptx64" => Some(Nvptx64)
    "hexagon" => Some(Hexagon)
    "r600" => Some(R600)
    "systemz" => Some(Systemz)
    "xcore" => Some(Xcore)
    "unknown" => Some(UnknownArch)
    _ => None
  }
}

///|
pub fn Arch::from_string(text : String) -> Arch {
  match Arch::of_string(text) {
    Some(arch) => arch
    None => UnknownArch
  }
}

///|
pub fn Arch::to_string(self : Arch) -> String {
  match self {
    X86 => "i386"
    X86_64 => "x86_64"
    Armv4 => "armv4"
    Armv5 => "armv5"
    Armv6 => "armv6"
    Armv7 => "armv7"
    Armv4eb => "armv4eb"
    Armv5eb => "armv5eb"
    Armv6eb => "armv6eb"
    Armv7eb => "armv7eb"
    Thumbv4 => "thumbv4"
    Thumbv5 => "thumbv5"
    Thumbv6 => "thumbv6"
    Thumbv7 => "thumbv7"
    Thumbv4eb => "thumbv4eb"
    Thumbv5eb => "thumbv5eb"
    Thumbv6eb => "thumbv6eb"
    Thumbv7eb => "thumbv7eb"
    Aarch64 => "aarch64"
    Aarch64_be => "aarch64_be"
    Ppc => "powerpc"
    Ppc64 => "powerpc64"
    Ppc64le => "powerpc64le"
    Mips => "mips"
    Mipsel => "mipsel"
    Mips64 => "mips64"
    Mips64el => "mips64el"
    Sparc => "sparc"
    Sparcv9 => "sparcv9"
    Nvptx => "nvptx"
    Nvptx64 => "nvptx64"
    Hexagon => "hexagon"
    R600 => "r600"
    Systemz => "s390x"
    Xcore => "xcore"
    UnknownArch => "unknown"
  }
}

///|
fn Arch::rank(self : Arch) -> Int32 {
  match self {
    Aarch64 => 0
    Aarch64_be => 1
    Armv4 => 2
    Armv5 => 3
    Armv6 => 4
    Armv7 => 5
    Armv4eb => 6
    Armv5eb => 7
    Armv6eb => 8
    Armv7eb => 9
    Thumbv4 => 10
    Thumbv5 => 11
    Thumbv6 => 12
    Thumbv7 => 13
    Thumbv4eb => 14
    Thumbv5eb => 15
    Thumbv6eb => 16
    Thumbv7eb => 17
    Hexagon => 18
    Mips => 19
    Mipsel => 20
    Mips64 => 21
    Mips64el => 22
    Nvptx => 23
    Nvptx64 => 24
    Ppc => 25
    Ppc64 => 26
    Ppc64le => 27
    R600 => 28
    Sparc => 29
    Sparcv9 => 30
    Systemz => 31
    X86 => 32
    X86_64 => 33
    Xcore => 34
    UnknownArch => 35
  }
}

///|
pub fn Arch::compare(self : Arch, other : Arch) -> Int32 {
  self.rank().compare(other.rank())
}

///|
pub fn Arch::equal(self : Arch, other : Arch) -> Bool {
  self == other
}

///|
pub fn Arch::addr_size(self : Arch) -> AddrSize {
  match self {
    Armv4
    | Armv5
    | Armv6
    | Armv7
    | Armv4eb
    | Armv5eb
    | Armv6eb
    | Armv7eb
    | Thumbv4
    | Thumbv5
    | Thumbv6
    | Thumbv7
    | Thumbv4eb
    | Thumbv5eb
    | Thumbv6eb
    | Thumbv7eb
    | X86
    | Ppc
    | Mips
    | Mipsel
    | Sparc
    | Nvptx
    | Hexagon
    | R600
    | Xcore
    | UnknownArch => Addr32
    Aarch64
    | Aarch64_be
    | Mips64el
    | Sparcv9
    | Ppc64le
    | X86_64
    | Ppc64
    | Nvptx64
    | Systemz
    | Mips64 => Addr64
  }
}

///|
pub fn Arch::endian(self : Arch) -> @bitvec.Endian {
  match self {
    Armv4eb
    | Armv5eb
    | Armv6eb
    | Armv7eb
    | Aarch64_be
    | Thumbv4eb
    | Thumbv5eb
    | Thumbv6eb
    | Thumbv7eb
    | Ppc
    | Ppc64
    | Mips
    | Mips64
    | Sparc
    | Sparcv9
    | Systemz => BigEndian
    Mipsel
    | Mips64el
    | Ppc64le
    | Armv4
    | Armv5
    | Armv6
    | Armv7
    | Thumbv4
    | Thumbv5
    | Thumbv6
    | Thumbv7
    | X86
    | X86_64
    | Aarch64
    | R600
    | Hexagon
    | Nvptx
    | Nvptx64
    | Xcore
    | UnknownArch => LittleEndian
  }
}
