// Generated from upstream lib/bap_elf/elf_types.ml and elf_parse.ml value
// mappings; the unknown-value constructors keep the raw encoding.

///|
/// The OS/ABI of an ELF file (`EI_OSABI`, upstream `e_osabi`).
pub(all) enum EOsabi {
  ELFOSABI_SYSV
  ELFOSABI_HPUX
  ELFOSABI_NETBSD
  ELFOSABI_LINUX
  ELFOSABI_SOLARIS
  ELFOSABI_AIX
  ELFOSABI_IRIX
  ELFOSABI_FREEBSD
  ELFOSABI_TRU64
  ELFOSABI_MODESTO
  ELFOSABI_OPENBSD
  ELFOSABI_ARM_AEABI
  ELFOSABI_ARM
  ELFOSABI_STANDALONE
  ELFOSABI_EXT(Int)
} derive(Eq, Compare, Debug)

///|
pub extend EOsabi with Eq::{equal, not_equal}

///|
pub extend EOsabi with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend EOsabi with Debug::{to_repr}

///|
/// Decodes an `EI_OSABI` byte; values without a named constructor are kept as
/// `ELFOSABI_EXT`, so decoding is lossless.
pub fn EOsabi::of_int(value : Int) -> EOsabi {
  match value {
    0 => ELFOSABI_SYSV
    1 => ELFOSABI_HPUX
    2 => ELFOSABI_NETBSD
    3 => ELFOSABI_LINUX
    6 => ELFOSABI_SOLARIS
    7 => ELFOSABI_AIX
    8 => ELFOSABI_IRIX
    9 => ELFOSABI_FREEBSD
    10 => ELFOSABI_TRU64
    11 => ELFOSABI_MODESTO
    12 => ELFOSABI_OPENBSD
    64 => ELFOSABI_ARM_AEABI
    97 => ELFOSABI_ARM
    255 => ELFOSABI_STANDALONE
    other => ELFOSABI_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `EOsabi::of_int`).
pub fn EOsabi::to_int(self : EOsabi) -> Int {
  match self {
    ELFOSABI_SYSV => 0
    ELFOSABI_HPUX => 1
    ELFOSABI_NETBSD => 2
    ELFOSABI_LINUX => 3
    ELFOSABI_SOLARIS => 6
    ELFOSABI_AIX => 7
    ELFOSABI_IRIX => 8
    ELFOSABI_FREEBSD => 9
    ELFOSABI_TRU64 => 10
    ELFOSABI_MODESTO => 11
    ELFOSABI_OPENBSD => 12
    ELFOSABI_ARM_AEABI => 64
    ELFOSABI_ARM => 97
    ELFOSABI_STANDALONE => 255
    ELFOSABI_EXT(other) => other
  }
}

///|
/// The object file type (`e_type`, upstream `e_type`).
pub(all) enum EType {
  ET_NONE
  ET_REL
  ET_EXEC
  ET_DYN
  ET_CORE
  ET_EXT(Int)
} derive(Eq, Compare, Debug)

///|
pub extend EType with Eq::{equal, not_equal}

///|
pub extend EType with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend EType with Debug::{to_repr}

///|
/// Decodes an `e_type` half-word; values without a named constructor are kept as
/// `ET_EXT`, so decoding is lossless.
pub fn EType::of_int(value : Int) -> EType {
  match value {
    0 => ET_NONE
    1 => ET_REL
    2 => ET_EXEC
    3 => ET_DYN
    4 => ET_CORE
    other => ET_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `EType::of_int`).
pub fn EType::to_int(self : EType) -> Int {
  match self {
    ET_NONE => 0
    ET_REL => 1
    ET_EXEC => 2
    ET_DYN => 3
    ET_CORE => 4
    ET_EXT(other) => other
  }
}

///|
/// The target machine (`e_machine`, upstream `e_machine`).
pub(all) enum EMachine {
  EM_NONE
  EM_M32
  EM_SPARC
  EM_386
  EM_68K
  EM_88K
  EM_860
  EM_MIPS
  EM_S370
  EM_MIPS_RS3_LE
  EM_PARISC
  EM_VPP500
  EM_SPARC32PLUS
  EM_960
  EM_PPC
  EM_PPC64
  EM_S390
  EM_V800
  EM_FR20
  EM_RH32
  EM_RCE
  EM_ARM
  EM_ALPHA
  EM_SH
  EM_SPARCV9
  EM_TRICORE
  EM_ARC
  EM_H8_300
  EM_H8_300H
  EM_H8S
  EM_H8_500
  EM_IA_64
  EM_MIPS_X
  EM_COLDFIRE
  EM_68HC12
  EM_MMA
  EM_PCP
  EM_NCPU
  EM_NDR1
  EM_STARCORE
  EM_ME16
  EM_ST100
  EM_TINYJ
  EM_X86_64
  EM_PDSP
  EM_FX66
  EM_ST9PLUS
  EM_ST7
  EM_68HC16
  EM_68HC11
  EM_68HC08
  EM_68HC05
  EM_SVX
  EM_ST19
  EM_VAX
  EM_CRIS
  EM_JAVELIN
  EM_FIREPATH
  EM_ZSP
  EM_MMIX
  EM_HUANY
  EM_PRISM
  EM_AVR
  EM_FR30
  EM_D10V
  EM_D30V
  EM_V850
  EM_M32R
  EM_MN10300
  EM_MN10200
  EM_PJ
  EM_OPENRISC
  EM_ARC_A5
  EM_XTENSA
  EM_AARCH64
  EM_TILEPRO
  EM_MICROBLAZE
  EM_TILEGX
  EM_EXT(Int)
} derive(Eq, Compare, Debug)

///|
pub extend EMachine with Eq::{equal, not_equal}

///|
pub extend EMachine with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend EMachine with Debug::{to_repr}

///|
/// Decodes an `e_machine` half-word; values without a named constructor are kept as
/// `EM_EXT`, so decoding is lossless.
pub fn EMachine::of_int(value : Int) -> EMachine {
  match value {
    0 => EM_NONE
    1 => EM_M32
    2 => EM_SPARC
    3 => EM_386
    4 => EM_68K
    5 => EM_88K
    7 => EM_860
    8 => EM_MIPS
    9 => EM_S370
    10 => EM_MIPS_RS3_LE
    15 => EM_PARISC
    17 => EM_VPP500
    18 => EM_SPARC32PLUS
    19 => EM_960
    20 => EM_PPC
    21 => EM_PPC64
    22 => EM_S390
    36 => EM_V800
    37 => EM_FR20
    38 => EM_RH32
    39 => EM_RCE
    40 => EM_ARM
    41 => EM_ALPHA
    42 => EM_SH
    43 => EM_SPARCV9
    44 => EM_TRICORE
    45 => EM_ARC
    46 => EM_H8_300
    47 => EM_H8_300H
    48 => EM_H8S
    49 => EM_H8_500
    50 => EM_IA_64
    51 => EM_MIPS_X
    52 => EM_COLDFIRE
    53 => EM_68HC12
    54 => EM_MMA
    55 => EM_PCP
    56 => EM_NCPU
    57 => EM_NDR1
    58 => EM_STARCORE
    59 => EM_ME16
    60 => EM_ST100
    61 => EM_TINYJ
    62 => EM_X86_64
    63 => EM_PDSP
    66 => EM_FX66
    67 => EM_ST9PLUS
    68 => EM_ST7
    69 => EM_68HC16
    70 => EM_68HC11
    71 => EM_68HC08
    72 => EM_68HC05
    73 => EM_SVX
    74 => EM_ST19
    75 => EM_VAX
    76 => EM_CRIS
    77 => EM_JAVELIN
    78 => EM_FIREPATH
    79 => EM_ZSP
    80 => EM_MMIX
    81 => EM_HUANY
    82 => EM_PRISM
    83 => EM_AVR
    84 => EM_FR30
    85 => EM_D10V
    86 => EM_D30V
    87 => EM_V850
    88 => EM_M32R
    89 => EM_MN10300
    90 => EM_MN10200
    91 => EM_PJ
    92 => EM_OPENRISC
    93 => EM_ARC_A5
    94 => EM_XTENSA
    183 => EM_AARCH64
    188 => EM_TILEPRO
    189 => EM_MICROBLAZE
    191 => EM_TILEGX
    other => EM_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `EMachine::of_int`).
pub fn EMachine::to_int(self : EMachine) -> Int {
  match self {
    EM_NONE => 0
    EM_M32 => 1
    EM_SPARC => 2
    EM_386 => 3
    EM_68K => 4
    EM_88K => 5
    EM_860 => 7
    EM_MIPS => 8
    EM_S370 => 9
    EM_MIPS_RS3_LE => 10
    EM_PARISC => 15
    EM_VPP500 => 17
    EM_SPARC32PLUS => 18
    EM_960 => 19
    EM_PPC => 20
    EM_PPC64 => 21
    EM_S390 => 22
    EM_V800 => 36
    EM_FR20 => 37
    EM_RH32 => 38
    EM_RCE => 39
    EM_ARM => 40
    EM_ALPHA => 41
    EM_SH => 42
    EM_SPARCV9 => 43
    EM_TRICORE => 44
    EM_ARC => 45
    EM_H8_300 => 46
    EM_H8_300H => 47
    EM_H8S => 48
    EM_H8_500 => 49
    EM_IA_64 => 50
    EM_MIPS_X => 51
    EM_COLDFIRE => 52
    EM_68HC12 => 53
    EM_MMA => 54
    EM_PCP => 55
    EM_NCPU => 56
    EM_NDR1 => 57
    EM_STARCORE => 58
    EM_ME16 => 59
    EM_ST100 => 60
    EM_TINYJ => 61
    EM_X86_64 => 62
    EM_PDSP => 63
    EM_FX66 => 66
    EM_ST9PLUS => 67
    EM_ST7 => 68
    EM_68HC16 => 69
    EM_68HC11 => 70
    EM_68HC08 => 71
    EM_68HC05 => 72
    EM_SVX => 73
    EM_ST19 => 74
    EM_VAX => 75
    EM_CRIS => 76
    EM_JAVELIN => 77
    EM_FIREPATH => 78
    EM_ZSP => 79
    EM_MMIX => 80
    EM_HUANY => 81
    EM_PRISM => 82
    EM_AVR => 83
    EM_FR30 => 84
    EM_D10V => 85
    EM_D30V => 86
    EM_V850 => 87
    EM_M32R => 88
    EM_MN10300 => 89
    EM_MN10200 => 90
    EM_PJ => 91
    EM_OPENRISC => 92
    EM_ARC_A5 => 93
    EM_XTENSA => 94
    EM_AARCH64 => 183
    EM_TILEPRO => 188
    EM_MICROBLAZE => 189
    EM_TILEGX => 191
    EM_EXT(other) => other
  }
}

///|
/// The type of a program header (`p_type`, upstream `p_type`).
pub(all) enum PType {
  PT_NULL
  PT_LOAD
  PT_DYNAMIC
  PT_INTERP
  PT_NOTE
  PT_SHLIB
  PT_PHDR
  PT_OTHER(UInt)
} derive(Eq, Compare, Debug)

///|
pub extend PType with Eq::{equal, not_equal}

///|
pub extend PType with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend PType with Debug::{to_repr}

///|
/// Decodes a `p_type` word; values without a named constructor are kept as
/// `PT_OTHER`, so decoding is lossless.
pub fn PType::of_int(value : UInt) -> PType {
  match value {
    0 => PT_NULL
    1 => PT_LOAD
    2 => PT_DYNAMIC
    3 => PT_INTERP
    4 => PT_NOTE
    5 => PT_SHLIB
    6 => PT_PHDR
    other => PT_OTHER(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `PType::of_int`).
pub fn PType::to_int(self : PType) -> UInt {
  match self {
    PT_NULL => 0
    PT_LOAD => 1
    PT_DYNAMIC => 2
    PT_INTERP => 3
    PT_NOTE => 4
    PT_SHLIB => 5
    PT_PHDR => 6
    PT_OTHER(other) => other
  }
}

///|
/// The type of a section header (`sh_type`, upstream `sh_type`).
pub(all) enum ShType {
  SHT_NULL
  SHT_PROGBITS
  SHT_SYMTAB
  SHT_STRTAB
  SHT_RELA
  SHT_HASH
  SHT_DYNAMIC
  SHT_NOTE
  SHT_NOBITS
  SHT_REL
  SHT_SHLIB
  SHT_DYNSYM
  SHT_EXT(UInt)
} derive(Eq, Compare, Debug)

///|
pub extend ShType with Eq::{equal, not_equal}

///|
pub extend ShType with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend ShType with Debug::{to_repr}

///|
/// Decodes an `sh_type` word; values without a named constructor are kept as
/// `SHT_EXT`, so decoding is lossless.
pub fn ShType::of_int(value : UInt) -> ShType {
  match value {
    0 => SHT_NULL
    1 => SHT_PROGBITS
    2 => SHT_SYMTAB
    3 => SHT_STRTAB
    4 => SHT_RELA
    5 => SHT_HASH
    6 => SHT_DYNAMIC
    7 => SHT_NOTE
    8 => SHT_NOBITS
    9 => SHT_REL
    10 => SHT_SHLIB
    11 => SHT_DYNSYM
    other => SHT_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `ShType::of_int`).
pub fn ShType::to_int(self : ShType) -> UInt {
  match self {
    SHT_NULL => 0
    SHT_PROGBITS => 1
    SHT_SYMTAB => 2
    SHT_STRTAB => 3
    SHT_RELA => 4
    SHT_HASH => 5
    SHT_DYNAMIC => 6
    SHT_NOTE => 7
    SHT_NOBITS => 8
    SHT_REL => 9
    SHT_SHLIB => 10
    SHT_DYNSYM => 11
    SHT_EXT(other) => other
  }
}

///|
/// A program header flag (upstream `p_flag`): the constructors name
/// flag bits, `PF_EXT(n)` is any other set bit `n`.
pub(all) enum PFlag {
  PF_X
  PF_W
  PF_R
  PF_EXT(Int)
} derive(Eq, Compare, Debug)

///|
pub extend PFlag with Eq::{equal, not_equal}

///|
pub extend PFlag with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend PFlag with Debug::{to_repr}

///|
/// Decodes a `p_flags` bit index; values without a named constructor are kept as
/// `PF_EXT`, so decoding is lossless.
pub fn PFlag::of_int(value : Int) -> PFlag {
  match value {
    0 => PF_X
    1 => PF_W
    2 => PF_R
    other => PF_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `PFlag::of_int`).
pub fn PFlag::to_int(self : PFlag) -> Int {
  match self {
    PF_X => 0
    PF_W => 1
    PF_R => 2
    PF_EXT(other) => other
  }
}

///|
/// A section header flag (upstream `sh_flag`): the constructors name
/// flag bits, `SHF_EXT(n)` is any other set bit `n`.
pub(all) enum ShFlag {
  SHF_WRITE
  SHF_ALLOC
  SHF_EXECINSTR
  SHF_EXT(Int)
} derive(Eq, Compare, Debug)

///|
pub extend ShFlag with Eq::{equal, not_equal}

///|
pub extend ShFlag with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend ShFlag with Debug::{to_repr}

///|
/// Decodes an `sh_flags` bit index; values without a named constructor are kept as
/// `SHF_EXT`, so decoding is lossless.
pub fn ShFlag::of_int(value : Int) -> ShFlag {
  match value {
    0 => SHF_WRITE
    1 => SHF_ALLOC
    2 => SHF_EXECINSTR
    other => SHF_EXT(other)
  }
}

///|
/// The raw encoding of the value (the inverse of `ShFlag::of_int`).
pub fn ShFlag::to_int(self : ShFlag) -> Int {
  match self {
    SHF_WRITE => 0
    SHF_ALLOC => 1
    SHF_EXECINSTR => 2
    SHF_EXT(other) => other
  }
}
