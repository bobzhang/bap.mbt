// Constants of the PE/COFF specification (`winnt.h`) that the reader and
// the loaders use.

///|
pub const IMAGE_FILE_MACHINE_UNKNOWN : Int32 = 0x0

///|
pub const IMAGE_FILE_MACHINE_I386 : Int32 = 0x14c

///|
pub const IMAGE_FILE_MACHINE_AMD64 : Int32 = 0x8664

///|
pub const IMAGE_FILE_MACHINE_ARM : Int32 = 0x1c0

///|
pub const IMAGE_FILE_MACHINE_THUMB : Int32 = 0x1c2

///|
pub const IMAGE_FILE_MACHINE_ARMNT : Int32 = 0x1c4

///|
pub const IMAGE_FILE_MACHINE_ARM64 : Int32 = 0xaa64

///|
pub const IMAGE_FILE_MACHINE_POWERPC : Int32 = 0x1f0

///|
pub const IMAGE_FILE_MACHINE_R4000 : Int32 = 0x166

///|
pub const IMAGE_FILE_MACHINE_RISCV64 : Int32 = 0x5064

///|
pub const IMAGE_FILE_EXECUTABLE_IMAGE : Int32 = 0x2

///|
pub const IMAGE_FILE_DLL : Int32 = 0x2000

///|
pub const IMAGE_NT_OPTIONAL_HDR32_MAGIC : Int32 = 0x10b

///|
pub const IMAGE_NT_OPTIONAL_HDR64_MAGIC : Int32 = 0x20b

///|
pub const IMAGE_DIRECTORY_ENTRY_EXPORT : Int32 = 0

///|
pub const IMAGE_DIRECTORY_ENTRY_IMPORT : Int32 = 1

///|
pub const IMAGE_DIRECTORY_ENTRY_BASERELOC : Int32 = 5

///|
pub const IMAGE_DIRECTORY_ENTRY_IAT : Int32 = 12

///|
pub const IMAGE_SCN_CNT_CODE : UInt32 = 0x20

///|
pub const IMAGE_SCN_CNT_INITIALIZED_DATA : UInt32 = 0x40

///|
pub const IMAGE_SCN_CNT_UNINITIALIZED_DATA : UInt32 = 0x80

///|
pub const IMAGE_SCN_LNK_NRELOC_OVFL : UInt32 = 0x01000000

///|
pub const IMAGE_SCN_MEM_EXECUTE : UInt32 = 0x20000000

///|
pub const IMAGE_SCN_MEM_READ : UInt32 = 0x40000000

///|
pub const IMAGE_SCN_MEM_WRITE : UInt32 = 0x80000000

///|
pub const IMAGE_SYM_UNDEFINED : Int32 = 0

///|
pub const IMAGE_SYM_ABSOLUTE : Int32 = -1

///|
pub const IMAGE_SYM_DEBUG : Int32 = -2

///|
pub const IMAGE_SYM_CLASS_EXTERNAL : Int32 = 2

///|
pub const IMAGE_SYM_CLASS_STATIC : Int32 = 3

///|
pub const IMAGE_SYM_CLASS_FILE : Int32 = 0x67

///|
pub const IMAGE_SYM_DTYPE_FUNCTION : Int32 = 2
