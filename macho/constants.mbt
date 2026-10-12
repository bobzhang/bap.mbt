// Constants of `<mach-o/loader.h>`, `<mach-o/nlist.h>`, `<mach-o/fat.h>`
// and `<mach/machine.h>` that the reader and the loaders use.

///|
/// `MH_MAGIC`: a 32-bit Mach-O file in the byte order of the reader.
pub const MH_MAGIC : UInt32 = 0xfeedface

///|
/// `MH_MAGIC_64`: a 64-bit Mach-O file.
pub const MH_MAGIC_64 : UInt32 = 0xfeedfacf

///|
/// `FAT_MAGIC`: a universal binary with 32-bit slice offsets (big endian).
pub const FAT_MAGIC : UInt32 = 0xcafebabe

///|
/// `FAT_MAGIC_64`: a universal binary with 64-bit slice offsets.
pub const FAT_MAGIC_64 : UInt32 = 0xcafebabf

///|
/// `CPU_ARCH_ABI64`: the 64-bit flag of a CPU type.
pub const CPU_ARCH_ABI64 : Int32 = 0x01000000

///|
pub const CPU_TYPE_X86 : Int32 = 7

///|
pub const CPU_TYPE_X86_64 : Int32 = 0x01000007

///|
pub const CPU_TYPE_ARM : Int32 = 12

///|
pub const CPU_TYPE_ARM64 : Int32 = 0x0100000c

///|
/// `CPU_TYPE_ARM64_32`: arm64 code with 32-bit pointers.
pub const CPU_TYPE_ARM64_32 : Int32 = 0x0200000c

///|
pub const CPU_TYPE_POWERPC : Int32 = 18

///|
pub const CPU_TYPE_POWERPC64 : Int32 = 0x01000012

///|
pub const CPU_SUBTYPE_ARM64E : Int32 = 2

///|
pub const CPU_SUBTYPE_X86_64_H : Int32 = 8

///|
pub const MH_OBJECT : Int32 = 0x1

///|
pub const MH_EXECUTE : Int32 = 0x2

///|
pub const MH_PRELOAD : Int32 = 0x5

///|
pub const MH_DYLIB : Int32 = 0x6

///|
pub const MH_BUNDLE : Int32 = 0x8

///|
/// `LC_REQ_DYLD`: the load command flag that dyld must understand.
pub const LC_REQ_DYLD : UInt32 = 0x80000000

///|
pub const LC_SEGMENT : UInt32 = 0x1

///|
pub const LC_SYMTAB : UInt32 = 0x2

///|
pub const LC_THREAD : UInt32 = 0x4

///|
pub const LC_UNIXTHREAD : UInt32 = 0x5

///|
pub const LC_DYSYMTAB : UInt32 = 0xb

///|
pub const LC_LOAD_DYLIB : UInt32 = 0xc

///|
pub const LC_ID_DYLIB : UInt32 = 0xd

///|
pub const LC_LOAD_DYLINKER : UInt32 = 0xe

///|
pub const LC_SEGMENT_64 : UInt32 = 0x19

///|
pub const LC_UUID : UInt32 = 0x1b

///|
pub const LC_LOAD_WEAK_DYLIB : UInt32 = 0x80000018

///|
pub const LC_REEXPORT_DYLIB : UInt32 = 0x8000001f

///|
pub const LC_LAZY_LOAD_DYLIB : UInt32 = 0x20

///|
pub const LC_LOAD_UPWARD_DYLIB : UInt32 = 0x80000023

///|
pub const LC_FUNCTION_STARTS : UInt32 = 0x26

///|
pub const LC_MAIN : UInt32 = 0x80000028

///|
/// `VM_PROT_READ`
pub const VM_PROT_READ : Int32 = 0x1

///|
/// `VM_PROT_WRITE`
pub const VM_PROT_WRITE : Int32 = 0x2

///|
/// `VM_PROT_EXECUTE`
pub const VM_PROT_EXECUTE : Int32 = 0x4

///|
/// `SECTION_TYPE`: the type bits of section flags.
pub const SECTION_TYPE : UInt32 = 0xff

///|
pub const S_ZEROFILL : UInt32 = 0x1

///|
pub const S_NON_LAZY_SYMBOL_POINTERS : UInt32 = 0x6

///|
pub const S_LAZY_SYMBOL_POINTERS : UInt32 = 0x7

///|
pub const S_SYMBOL_STUBS : UInt32 = 0x8

///|
pub const S_GB_ZEROFILL : UInt32 = 0xc

///|
pub const S_LAZY_DYLIB_SYMBOL_POINTERS : UInt32 = 0x10

///|
pub const S_THREAD_LOCAL_VARIABLE_POINTERS : UInt32 = 0x14

///|
pub const S_ATTR_PURE_INSTRUCTIONS : UInt32 = 0x80000000

///|
pub const S_ATTR_SOME_INSTRUCTIONS : UInt32 = 0x400

///|
/// `N_STAB`: the symbol is a debugging (stab) entry.
pub const N_STAB : Int32 = 0xe0

///|
/// `N_TYPE`: the type bits of `n_type`.
pub const N_TYPE : Int32 = 0x0e

///|
/// `N_EXT`: the symbol is external.
pub const N_EXT : Int32 = 0x01

///|
pub const N_UNDF : Int32 = 0x0

///|
pub const N_ABS : Int32 = 0x2

///|
pub const N_SECT : Int32 = 0xe

///|
pub const N_INDR : Int32 = 0xa

///|
/// `INDIRECT_SYMBOL_LOCAL`: an indirect symbol table entry of a local
/// (non-external) symbol.
pub const INDIRECT_SYMBOL_LOCAL : UInt32 = 0x80000000

///|
/// `INDIRECT_SYMBOL_ABS`: an indirect symbol table entry of an absolute
/// symbol.
pub const INDIRECT_SYMBOL_ABS : UInt32 = 0x40000000
