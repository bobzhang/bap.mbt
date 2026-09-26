// Constants of the PE/COFF specification (`winnt.h`) that the reader and
// the loaders use.

///|
pub const IMAGE_FILE_MACHINE_UNKNOWN : Int = 0x0

///|
pub const IMAGE_FILE_MACHINE_I386 : Int = 0x14c

///|
pub const IMAGE_FILE_MACHINE_AMD64 : Int = 0x8664

///|
pub const IMAGE_FILE_MACHINE_ARM : Int = 0x1c0

///|
pub const IMAGE_FILE_MACHINE_THUMB : Int = 0x1c2

///|
pub const IMAGE_FILE_MACHINE_ARMNT : Int = 0x1c4

///|
pub const IMAGE_FILE_MACHINE_ARM64 : Int = 0xaa64

///|
pub const IMAGE_FILE_MACHINE_POWERPC : Int = 0x1f0

///|
pub const IMAGE_FILE_MACHINE_R4000 : Int = 0x166

///|
pub const IMAGE_FILE_MACHINE_RISCV64 : Int = 0x5064

///|
pub const IMAGE_FILE_EXECUTABLE_IMAGE : Int = 0x2

///|
pub const IMAGE_FILE_DLL : Int = 0x2000

///|
pub const IMAGE_NT_OPTIONAL_HDR32_MAGIC : Int = 0x10b

///|
pub const IMAGE_NT_OPTIONAL_HDR64_MAGIC : Int = 0x20b

///|
pub const IMAGE_DIRECTORY_ENTRY_EXPORT : Int = 0

///|
pub const IMAGE_DIRECTORY_ENTRY_IMPORT : Int = 1

///|
pub const IMAGE_DIRECTORY_ENTRY_BASERELOC : Int = 5

///|
pub const IMAGE_DIRECTORY_ENTRY_IAT : Int = 12

///|
pub const IMAGE_SCN_CNT_CODE : UInt = 0x20

///|
pub const IMAGE_SCN_CNT_INITIALIZED_DATA : UInt = 0x40

///|
pub const IMAGE_SCN_CNT_UNINITIALIZED_DATA : UInt = 0x80

///|
pub const IMAGE_SCN_LNK_NRELOC_OVFL : UInt = 0x01000000

///|
pub const IMAGE_SCN_MEM_EXECUTE : UInt = 0x20000000

///|
pub const IMAGE_SCN_MEM_READ : UInt = 0x40000000

///|
pub const IMAGE_SCN_MEM_WRITE : UInt = 0x80000000

///|
pub const IMAGE_SYM_UNDEFINED : Int = 0

///|
pub const IMAGE_SYM_ABSOLUTE : Int = -1

///|
pub const IMAGE_SYM_DEBUG : Int = -2

///|
pub const IMAGE_SYM_CLASS_EXTERNAL : Int = 2

///|
pub const IMAGE_SYM_CLASS_STATIC : Int = 3

///|
pub const IMAGE_SYM_CLASS_FILE : Int = 0x67

///|
pub const IMAGE_SYM_DTYPE_FUNCTION : Int = 2
