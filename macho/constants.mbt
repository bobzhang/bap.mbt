// Constants of `<mach-o/loader.h>`, `<mach-o/nlist.h>`, `<mach-o/fat.h>`
// and `<mach/machine.h>` that the reader and the loaders use.

///|
/// `MH_MAGIC`: a 32-bit Mach-O file in the byte order of the reader.
pub const MH_MAGIC : UInt = 0xfeedface

///|
/// `MH_MAGIC_64`: a 64-bit Mach-O file.
pub const MH_MAGIC_64 : UInt = 0xfeedfacf

///|
/// `FAT_MAGIC`: a universal binary with 32-bit slice offsets (big endian).
pub const FAT_MAGIC : UInt = 0xcafebabe

///|
/// `FAT_MAGIC_64`: a universal binary with 64-bit slice offsets.
pub const FAT_MAGIC_64 : UInt = 0xcafebabf

///|
/// `CPU_ARCH_ABI64`: the 64-bit flag of a CPU type.
pub const CPU_ARCH_ABI64 : Int = 0x01000000

///|
pub const CPU_TYPE_X86 : Int = 7

///|
pub const CPU_TYPE_X86_64 : Int = 0x01000007

///|
pub const CPU_TYPE_ARM : Int = 12

///|
pub const CPU_TYPE_ARM64 : Int = 0x0100000c

///|
/// `CPU_TYPE_ARM64_32`: arm64 code with 32-bit pointers.
pub const CPU_TYPE_ARM64_32 : Int = 0x0200000c

///|
pub const CPU_TYPE_POWERPC : Int = 18

///|
pub const CPU_TYPE_POWERPC64 : Int = 0x01000012

///|
pub const CPU_SUBTYPE_ARM64E : Int = 2

///|
pub const CPU_SUBTYPE_X86_64_H : Int = 8

///|
pub const MH_OBJECT : Int = 0x1

///|
pub const MH_EXECUTE : Int = 0x2

///|
pub const MH_PRELOAD : Int = 0x5

///|
pub const MH_DYLIB : Int = 0x6

///|
pub const MH_BUNDLE : Int = 0x8

///|
/// `LC_REQ_DYLD`: the load command flag that dyld must understand.
pub const LC_REQ_DYLD : UInt = 0x80000000

///|
pub const LC_SEGMENT : UInt = 0x1

///|
pub const LC_SYMTAB : UInt = 0x2

///|
pub const LC_THREAD : UInt = 0x4

///|
pub const LC_UNIXTHREAD : UInt = 0x5

///|
pub const LC_DYSYMTAB : UInt = 0xb

///|
pub const LC_LOAD_DYLIB : UInt = 0xc

///|
pub const LC_ID_DYLIB : UInt = 0xd

///|
pub const LC_LOAD_DYLINKER : UInt = 0xe

///|
pub const LC_SEGMENT_64 : UInt = 0x19

///|
pub const LC_UUID : UInt = 0x1b

///|
pub const LC_LOAD_WEAK_DYLIB : UInt = 0x80000018

///|
pub const LC_REEXPORT_DYLIB : UInt = 0x8000001f

///|
pub const LC_LAZY_LOAD_DYLIB : UInt = 0x20

///|
pub const LC_LOAD_UPWARD_DYLIB : UInt = 0x80000023

///|
pub const LC_FUNCTION_STARTS : UInt = 0x26

///|
pub const LC_MAIN : UInt = 0x80000028

///|
/// `VM_PROT_READ`
pub const VM_PROT_READ : Int = 0x1

///|
/// `VM_PROT_WRITE`
pub const VM_PROT_WRITE : Int = 0x2

///|
/// `VM_PROT_EXECUTE`
pub const VM_PROT_EXECUTE : Int = 0x4

///|
/// `SECTION_TYPE`: the type bits of section flags.
pub const SECTION_TYPE : UInt = 0xff

///|
pub const S_ZEROFILL : UInt = 0x1

///|
pub const S_NON_LAZY_SYMBOL_POINTERS : UInt = 0x6

///|
pub const S_LAZY_SYMBOL_POINTERS : UInt = 0x7

///|
pub const S_SYMBOL_STUBS : UInt = 0x8

///|
pub const S_GB_ZEROFILL : UInt = 0xc

///|
pub const S_LAZY_DYLIB_SYMBOL_POINTERS : UInt = 0x10

///|
pub const S_THREAD_LOCAL_VARIABLE_POINTERS : UInt = 0x14

///|
pub const S_ATTR_PURE_INSTRUCTIONS : UInt = 0x80000000

///|
pub const S_ATTR_SOME_INSTRUCTIONS : UInt = 0x400

///|
/// `N_STAB`: the symbol is a debugging (stab) entry.
pub const N_STAB : Int = 0xe0

///|
/// `N_TYPE`: the type bits of `n_type`.
pub const N_TYPE : Int = 0x0e

///|
/// `N_EXT`: the symbol is external.
pub const N_EXT : Int = 0x01

///|
pub const N_UNDF : Int = 0x0

///|
pub const N_ABS : Int = 0x2

///|
pub const N_SECT : Int = 0xe

///|
pub const N_INDR : Int = 0xa

///|
/// `INDIRECT_SYMBOL_LOCAL`: an indirect symbol table entry of a local
/// (non-external) symbol.
pub const INDIRECT_SYMBOL_LOCAL : UInt = 0x80000000

///|
/// `INDIRECT_SYMBOL_ABS`: an indirect symbol table entry of an absolute
/// symbol.
pub const INDIRECT_SYMBOL_ABS : UInt = 0x40000000
