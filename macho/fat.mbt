///|
/// The architecture count below which a `0xcafebabe` file is a universal
/// binary; a Java class file shares the magic and has its major version
/// (45 or more) there (as `llvm::identify_magic` decides).
let max_fat_archs : Int = 42

///|
/// The magic number and the architecture count of a universal binary.
fn fat_header(data : BytesView) -> (Bool, Int)? {
  if data.length() < 8 {
    return None
  }
  let r : Reader = { data: data.to_owned(), endian: BigEndian, }
  let magic = r.u32(0) catch { _ => return None }
  let count = r.u32(4) catch { _ => return None }
  if (magic == FAT_MAGIC || magic == FAT_MAGIC_64) &&
    count > 0 &&
    count.reinterpret_as_int() <= max_fat_archs {
    Some((magic == FAT_MAGIC_64, count.reinterpret_as_int()))
  } else {
    None
  }
}

///|
/// Whether `data` is a universal (fat) binary.
pub fn is_fat(data : BytesView) -> Bool {
  fat_header(data) is Some(_)
}

///|
/// The architectures of a universal binary (`fat_arch` / `fat_arch_64`
/// entries; the fat header is always big endian).
pub fn fat_archs(data : Bytes) -> Result[Array[FatArch], String] {
  catch_malformed(() => {
    guard fat_header(data) is Some((is64, count)) else {
      raise Malformed("not a universal binary")
    }
    let r : Reader = { data, endian: BigEndian, }
    let entry_size = if is64 { 32 } else { 20 }
    let archs : Array[FatArch] = []
    for i in 0..<count {
      let off = 8 + i * entry_size
      r.check(off, entry_size, "universal binary architecture")
      archs.push(
        if is64 {
          {
            cputype: r.u32(off).reinterpret_as_int(),
            cpusubtype: r.u32(off + 4).reinterpret_as_int(),
            offset: r.u64(off + 8),
            size: r.u64(off + 16),
            align: r.u32(off + 24),
          }
        } else {
          {
            cputype: r.u32(off).reinterpret_as_int(),
            cpusubtype: r.u32(off + 4).reinterpret_as_int(),
            offset: r.u32(off + 8).to_uint64(),
            size: r.u32(off + 12).to_uint64(),
            align: r.u32(off + 16),
          }
        },
      )
    }
    archs
  })
}

///|
/// The bytes of the thin Mach-O file of an architecture of a universal
/// binary.
pub fn fat_slice(data : Bytes, arch : FatArch) -> Result[Bytes, String] {
  let len = data.length().to_uint64()
  if arch.offset > len || arch.size > len - arch.offset {
    Err("universal binary architecture is out of bounds")
  } else {
    let start = arch.offset.to_int()
    Ok(data[start:start + arch.size.to_int()].to_owned())
  }
}

///|
/// The conventional name of a CPU type and subtype (as `lipo` and `otool`
/// print them): `x86_64`, `x86_64h`, `i386`, `arm64`, `arm64e`,
/// `arm64_32`, `armv7`, `armv7s`, `ppc`, ...
pub fn arch_name(cputype : Int, cpusubtype : Int) -> String {
  let subtype = cpusubtype & 0x00ffffff
  match cputype {
    CPU_TYPE_X86 => "i386"
    CPU_TYPE_X86_64 =>
      if subtype == CPU_SUBTYPE_X86_64_H {
        "x86_64h"
      } else {
        "x86_64"
      }
    CPU_TYPE_ARM64 =>
      if subtype == CPU_SUBTYPE_ARM64E {
        "arm64e"
      } else {
        "arm64"
      }
    CPU_TYPE_ARM64_32 => "arm64_32"
    CPU_TYPE_ARM =>
      match subtype {
        5 => "armv4t"
        6 => "armv6"
        7 => "armv5"
        8 => "xscale"
        9 => "armv7"
        10 => "armv7f"
        11 => "armv7s"
        12 => "armv7k"
        14 => "armv6m"
        15 => "armv7m"
        16 => "armv7em"
        _ => "arm"
      }
    CPU_TYPE_POWERPC => "ppc"
    CPU_TYPE_POWERPC64 => "ppc64"
    _ => "cpu\{cputype}"
  }
}
