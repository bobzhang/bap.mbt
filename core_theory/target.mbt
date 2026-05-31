///|
pub(all) enum Endianness {
  LittleEndian
  BigEndian
  BiEndian
} derive(Eq, Debug)

///|
pub(all) enum System {
  UnknownSystem
  HPUX
  NetBSD
  Linux
  Solaris
  AIX
  IRIX
  Darwin
  VxWorks
  FreeBSD
  Tru64
  Modesto
  OpenBSD
  Windows
  MSDOS
  UEFI
  NoSystem
} derive(Eq, Debug)

///|
pub(all) enum Abi {
  UnknownAbi
  SysV
  GNU
  EABI
  GNUEABI
  CDecl
  Pascal
  FortranAbi
  StdCall
  FastCall
  ThisCall
  VectorCall
  Watcom
  MSVC
  SMC
  HVC
} derive(Eq, Debug)

///|
pub(all) enum Fabi {
  UnknownFabi
  Soft
  Hard
} derive(Eq, Debug)

///|
pub(all) enum Filetype {
  UnknownFiletype
  Elf
  MachO
  COFF
  PE
  AOut
  Raw
} derive(Eq, Debug)

///|
struct TargetOptions {
  values_value : Map[String, String]
}

///|
pub fn Endianness::to_string(self : Endianness) -> String {
  match self {
    LittleEndian => "little"
    BigEndian => "big"
    BiEndian => "bi"
  }
}

///|
pub fn Endianness::of_string(text : String) -> Endianness? {
  match text.to_lower() {
    "little" | "little-endian" | "le" => Some(LittleEndian)
    "big" | "big-endian" | "be" => Some(BigEndian)
    "bi" | "bi-endian" | "both" => Some(BiEndian)
    _ => None
  }
}

///|
pub fn System::to_string(self : System) -> String {
  match self {
    UnknownSystem => "unknown"
    HPUX => "hpux"
    NetBSD => "netbsd"
    Linux => "linux"
    Solaris => "solaris"
    AIX => "aix"
    IRIX => "irix"
    Darwin => "darwin"
    VxWorks => "vxworks"
    FreeBSD => "freebsd"
    Tru64 => "tru64"
    Modesto => "modesto"
    OpenBSD => "openbsd"
    Windows => "windows"
    MSDOS => "msdos"
    UEFI => "uefi"
    NoSystem => "none"
  }
}

///|
pub fn System::of_string(text : String) -> System? {
  match text.to_lower() {
    "unknown" => Some(UnknownSystem)
    "hpux" | "hp-ux" => Some(HPUX)
    "netbsd" | "net-bsd" => Some(NetBSD)
    "linux" | "gnu/linux" => Some(Linux)
    "solaris" | "sunos" => Some(Solaris)
    "aix" => Some(AIX)
    "irix" => Some(IRIX)
    "darwin" | "macos" | "macosx" => Some(Darwin)
    "vxworks" | "vx-works" => Some(VxWorks)
    "freebsd" | "free-bsd" => Some(FreeBSD)
    "tru64" | "tru-64" | "osf1" => Some(Tru64)
    "modesto" => Some(Modesto)
    "openbsd" | "open-bsd" => Some(OpenBSD)
    "windows" | "win32" | "win64" => Some(Windows)
    "msdos" | "ms-dos" | "dos" => Some(MSDOS)
    "uefi" => Some(UEFI)
    "none" | "baremetal" | "bare-metal" => Some(NoSystem)
    _ => None
  }
}

///|
pub fn Abi::to_string(self : Abi) -> String {
  match self {
    UnknownAbi => "unknown"
    SysV => "sysv"
    GNU => "gnu"
    EABI => "eabi"
    GNUEABI => "gnueabi"
    CDecl => "cdecl"
    Pascal => "pascal"
    FortranAbi => "fortran"
    StdCall => "stdcall"
    FastCall => "fastcall"
    ThisCall => "thiscall"
    VectorCall => "vectorcall"
    Watcom => "watcom"
    MSVC => "ms"
    SMC => "smc"
    HVC => "hvc"
  }
}

///|
pub fn Abi::of_string(text : String) -> Abi? {
  match text.to_lower() {
    "unknown" => Some(UnknownAbi)
    "sysv" | "sys-v" | "system-v" => Some(SysV)
    "gnu" => Some(GNU)
    "eabi" => Some(EABI)
    "gnueabi" | "gnu-eabi" => Some(GNUEABI)
    "cdecl" | "c-decl" => Some(CDecl)
    "pascal" => Some(Pascal)
    "fortran" => Some(FortranAbi)
    "stdcall" | "std-call" => Some(StdCall)
    "fastcall" | "fast-call" => Some(FastCall)
    "thiscall" | "this-call" => Some(ThisCall)
    "vectorcall" | "vector-call" => Some(VectorCall)
    "watcom" => Some(Watcom)
    "msvc" | "ms" => Some(MSVC)
    "smc" => Some(SMC)
    "hvc" => Some(HVC)
    _ => None
  }
}

///|
pub fn Fabi::to_string(self : Fabi) -> String {
  match self {
    UnknownFabi => "unknown"
    Soft => "soft"
    Hard => "hard"
  }
}

///|
pub fn Fabi::of_string(text : String) -> Fabi? {
  match text.to_lower() {
    "unknown" => Some(UnknownFabi)
    "soft" | "soft-float" => Some(Soft)
    "hard" | "hard-float" => Some(Hard)
    _ => None
  }
}

///|
pub fn Filetype::to_string(self : Filetype) -> String {
  match self {
    UnknownFiletype => "unknown"
    Elf => "elf"
    MachO => "macho"
    COFF => "coff"
    PE => "pe"
    AOut => "aout"
    Raw => "raw"
  }
}

///|
pub fn Filetype::of_string(text : String) -> Filetype? {
  match text.to_lower() {
    "unknown" => Some(UnknownFiletype)
    "elf" => Some(Elf)
    "macho" | "mach-o" | "mach_o" => Some(MachO)
    "coff" => Some(COFF)
    "pe" | "pecoff" | "pe-coff" => Some(PE)
    "aout" | "a.out" | "a-out" => Some(AOut)
    "raw" | "bin" | "binary" => Some(Raw)
    _ => None
  }
}

///|
pub fn TargetOptions::empty() -> TargetOptions {
  { values_value: {} }
}

///|
pub fn TargetOptions::of_map(values : Map[String, String]) -> TargetOptions {
  { values_value: values.copy() }
}

///|
pub fn TargetOptions::singleton(key : String, value : String) -> TargetOptions {
  let values : Map[String, String] = {}
  values[key] = value
  { values_value: values }
}

///|
pub fn TargetOptions::entries(self : TargetOptions) -> Array[(String, String)] {
  let entries = []
  for entry in self.values_value {
    entries.push(entry)
  }
  entries.sort_by((left, right) => left.0.compare(right.0))
  entries
}

///|
pub fn TargetOptions::get(self : TargetOptions, key : String) -> String? {
  self.values_value.get(key)
}

///|
pub fn TargetOptions::is_empty(self : TargetOptions) -> Bool {
  self.values_value.length() == 0
}

///|
pub fn TargetOptions::with_value(
  self : TargetOptions,
  key : String,
  value : String,
) -> TargetOptions {
  let values = self.values_value.copy()
  values[key] = value
  { values_value: values }
}

///|
pub fn TargetOptions::matches(
  self : TargetOptions,
  constraint : TargetOptions,
  strict? : Bool = false,
) -> Bool {
  if strict && self.values_value.length() != constraint.values_value.length() {
    return false
  }
  for entry in constraint.values_value {
    if self.values_value.get(entry.0) != Some(entry.1) {
      return false
    }
  }
  true
}

///|
pub fn TargetOptions::to_string(self : TargetOptions) -> String {
  [ for entry in self.entries() => "+\{entry.0}=\{entry.1}" ].join("")
}

///|
pub(all) enum Role {
  General
  IntegerRegister
  FloatingRegister
  VectorRegister
  StackPointer
  FramePointer
  ProgramCounter
  Status
  Constant
  ZeroRegister
  LinkRegister
  ThreadPointer
  Argument
  ResultRegister
  CallerSaved
  CalleeSaved
  Reserved
} derive(Eq, Debug)

///|
pub(all) enum AliasOrigin {
  RegisterAlias(aliased~ : Var, source~ : Var)
  SubRegister(aliased~ : Var, source~ : Var, lo~ : Int, hi~ : Int)
  BitSetAlias(aliased~ : Var, bits~ : Array[Var])
  UnknownAlias(aliased~ : Var)
}

///|
struct Target {
  name_value : @knowledge.Name
  parent_value : Target?
  nicknames_value : Array[String]
  bits_value : Int
  byte_value : Int
  endianness_value : Endianness
  system_value : System
  abi_value : Abi
  fabi_value : Fabi
  filetype_value : Filetype
  options_value : TargetOptions
  vars_value : Array[Var]
  alias_origins_value : Array[AliasOrigin]
}

///|
let target_registry : Map[String, Target] = {}

///|
fn same_target_name(lhs : String, rhs : String) -> Bool {
  lhs.to_lower() == rhs.to_lower()
}

///|
fn target_has_name(target : Target, query : String) -> Bool {
  same_target_name(target.name_value.unqualified(), query) ||
  same_target_name(target.name_value.show(), query) ||
  target.nicknames_value.any(nick => same_target_name(nick, query))
}

///|
fn target_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="target")
}

///|
fn word_var(bits : Int, name : String) -> Var {
  Var::create(Sort::bitv(bits), name)
}

///|
fn bool_var(name : String) -> Var {
  Var::create(Sort::bool(), name)
}

///|
fn mem_var(addr_bits : Int, byte_bits : Int, name : String) -> Var {
  Var::create(
    Sort::mem(Sort::bitv(addr_bits), Sort::bitv(byte_bits)),
    name,
    is_mutable=true,
  )
}

///|
fn named_word_vars(bits : Int, names : Array[String]) -> Array[Var] {
  [
    for name in names => word_var(bits, name)
  ]
}

///|
fn numbered_word_vars(bits : Int, prefix : String, count : Int) -> Array[Var] {
  [
    for i in 0..<count => word_var(bits, "\{prefix}\{i}")
  ]
}

///|
fn append_vars(items : Array[Var], more : Array[Var]) -> Unit {
  for item in more {
    items.push(item)
  }
}

///|
fn x86_flags() -> Array[Var] {
  [
    for name in x86_flag_names() => bool_var(name)
  ]
}

///|
fn x86_flag_names() -> Array[String] {
  [
    "CF", "EFLAGS_1", "PF", "EFLAGS_3", "AF", "EFLAGS_5", "ZF", "SF", "TF", "IF",
    "DF", "OF", "IOPLL", "IOPLH", "NT", "MD", "RF", "VM", "AC", "VIF", "VIP", "ID",
    "EFLAGS_22", "EFLAGS_23", "EFLAGS_24", "EFLAGS_25", "EFLAGS_26", "EFLAGS_27",
    "EFLAGS_28", "EFLAGS_29", "AES", "AI",
  ]
}

///|
fn x86_segment_names(include_fs_gs : Bool) -> Array[String] {
  if include_fs_gs {
    ["CS", "DS", "ES", "SS", "FS", "GS"]
  } else {
    ["CS", "DS", "ES", "SS"]
  }
}

///|
fn x86_32_gpr_names() -> Array[String] {
  ["EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP"]
}

///|
fn x86_16_gpr_names() -> Array[String] {
  ["AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP"]
}

///|
fn x86_8_low_gpr_names() -> Array[String] {
  ["AL", "BL", "CL", "DL"]
}

///|
fn x86_8_high_gpr_names() -> Array[String] {
  ["AH", "BH", "CH", "DH"]
}

///|
fn x86_64_gpr_names() -> Array[String] {
  [
    "RAX", "RBX", "RCX", "RDX", "RSI", "RDI", "RBP", "RSP", "R8", "R9", "R10", "R11",
    "R12", "R13", "R14", "R15",
  ]
}

///|
fn x86_64_gpr32_alias_names() -> Array[String] {
  [
    "EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP", "R8D", "R9D", "R10D",
    "R11D", "R12D", "R13D", "R14D", "R15D",
  ]
}

///|
fn x86_64_gpr16_alias_names() -> Array[String] {
  [
    "AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP", "R8W", "R9W", "R10W", "R11W",
    "R12W", "R13W", "R14W", "R15W",
  ]
}

///|
fn x86_64_gpr8_alias_names() -> Array[String] {
  [
    "AL", "BL", "CL", "DL", "SIL", "DIL", "BPL", "SPL", "R8B", "R9B", "R10B", "R11B",
    "R12B", "R13B", "R14B", "R15B",
  ]
}

///|
fn lower_names(names : Array[String]) -> Array[String] {
  [
    for name in names => name.to_lower()
  ]
}

///|
fn x86_32_alias_origins() -> Array[AliasOrigin] {
  let items : Array[AliasOrigin] = []
  let bases = x86_32_gpr_names()
  let words = x86_16_gpr_names()
  for i in 0..<bases.length() {
    items.push(
      AliasOrigin::subregister(
        word_var(16, words[i]),
        word_var(32, bases[i]),
        lo=0,
        hi=15,
      ),
    )
  }
  let lows = x86_8_low_gpr_names()
  let highs = x86_8_high_gpr_names()
  for i in 0..<lows.length() {
    items.push(
      AliasOrigin::subregister(
        word_var(8, lows[i]),
        word_var(32, bases[i]),
        lo=0,
        hi=7,
      ),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(8, highs[i]),
        word_var(32, bases[i]),
        lo=8,
        hi=15,
      ),
    )
  }
  items.push(AliasOrigin::bit_set(word_var(32, "EFLAGS"), x86_flags()))
  items.push(
    AliasOrigin::bit_set(word_var(2, "IOPL"), [
      bool_var("IOPLH"),
      bool_var("IOPLL"),
    ]),
  )
  items
}

///|
fn x86_64_alias_origins() -> Array[AliasOrigin] {
  let items : Array[AliasOrigin] = []
  let bases = x86_64_gpr_names()
  let dwords = x86_64_gpr32_alias_names()
  let words = x86_64_gpr16_alias_names()
  let bytes = x86_64_gpr8_alias_names()
  for i in 0..<bases.length() {
    let base = word_var(64, bases[i])
    items.push(
      AliasOrigin::subregister(word_var(32, dwords[i]), base, lo=0, hi=31),
    )
    items.push(
      AliasOrigin::subregister(word_var(16, words[i]), base, lo=0, hi=15),
    )
    items.push(
      AliasOrigin::subregister(word_var(8, bytes[i]), base, lo=0, hi=7),
    )
  }
  let highs = x86_8_high_gpr_names()
  for i in 0..<highs.length() {
    items.push(
      AliasOrigin::subregister(
        word_var(8, highs[i]),
        word_var(64, bases[i]),
        lo=8,
        hi=15,
      ),
    )
  }
  for i in 0..<16 {
    items.push(
      AliasOrigin::subregister(
        word_var(128, "XMM\{i}"),
        word_var(256, "YMM\{i}"),
        lo=0,
        hi=127,
      ),
    )
  }
  items.push(AliasOrigin::bit_set(word_var(32, "EFLAGS"), x86_flags()))
  items.push(
    AliasOrigin::bit_set(word_var(2, "IOPL"), [
      bool_var("IOPLH"),
      bool_var("IOPLL"),
    ]),
  )
  items
}

///|
fn x86_32_vars() -> Array[Var] {
  x86_i686_vars()
}

///|
fn x86_16_alias_origins() -> Array[AliasOrigin] {
  let items : Array[AliasOrigin] = []
  let bases = ["AX", "BX", "CX", "DX"]
  let lows = x86_8_low_gpr_names()
  let highs = x86_8_high_gpr_names()
  for i in 0..<bases.length() {
    items.push(
      AliasOrigin::subregister(
        word_var(8, lows[i]),
        word_var(16, bases[i]),
        lo=0,
        hi=7,
      ),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(8, highs[i]),
        word_var(16, bases[i]),
        lo=8,
        hi=15,
      ),
    )
  }
  let indexes = ["SI", "DI", "BP", "SP"]
  let index8 = ["SIL", "DIL", "BPL", "SPL"]
  for i in 0..<indexes.length() {
    items.push(
      AliasOrigin::subregister(
        word_var(8, index8[i]),
        word_var(16, indexes[i]),
        lo=0,
        hi=7,
      ),
    )
  }
  items.push(AliasOrigin::bit_set(word_var(32, "EFLAGS"), x86_flags()))
  items.push(
    AliasOrigin::bit_set(word_var(2, "IOPL"), [
      bool_var("IOPLH"),
      bool_var("IOPLL"),
    ]),
  )
  items
}

///|
fn x86_16_vars() -> Array[Var] {
  let items = named_word_vars(16, x86_16_gpr_names())
  append_vars(items, named_word_vars(8, x86_8_low_gpr_names()))
  append_vars(items, named_word_vars(8, x86_8_high_gpr_names()))
  append_vars(items, named_word_vars(8, ["SIL", "DIL", "BPL", "SPL"]))
  append_vars(items, named_word_vars(16, x86_segment_names(false)))
  append_vars(items, named_word_vars(32, ["EFLAGS"]))
  items.push(word_var(2, "IOPL"))
  append_vars(items, x86_flags())
  items.push(mem_var(16, 8, "mem"))
  items
}

///|
fn x86_i386_vars() -> Array[Var] {
  let items = named_word_vars(32, x86_32_gpr_names())
  append_vars(items, named_word_vars(32, ["EIP", "EFLAGS"]))
  append_vars(items, named_word_vars(16, x86_16_gpr_names()))
  append_vars(items, named_word_vars(8, x86_8_low_gpr_names()))
  append_vars(items, named_word_vars(8, x86_8_high_gpr_names()))
  append_vars(items, named_word_vars(16, x86_segment_names(true)))
  items.push(word_var(2, "IOPL"))
  append_vars(items, x86_flags())
  items.push(mem_var(32, 8, "mem"))
  items
}

///|
fn x86_i486_vars() -> Array[Var] {
  let items = x86_i386_vars()
  append_vars(items, numbered_word_vars(80, "ST", 8))
  items
}

///|
fn x86_i586_vars() -> Array[Var] {
  let items = x86_i486_vars()
  append_vars(items, numbered_word_vars(64, "MM", 8))
  items
}

///|
fn x86_i686_vars() -> Array[Var] {
  let items = x86_i586_vars()
  append_vars(items, numbered_word_vars(128, "XMM", 8))
  items
}

///|
fn x86_64_vars() -> Array[Var] {
  let items = named_word_vars(64, x86_64_gpr_names())
  append_vars(items, named_word_vars(64, ["RIP", "RFLAGS"]))
  append_vars(items, named_word_vars(32, x86_64_gpr32_alias_names()))
  append_vars(items, named_word_vars(32, ["EFLAGS", "MXCSR"]))
  append_vars(items, named_word_vars(16, x86_64_gpr16_alias_names()))
  append_vars(items, named_word_vars(8, x86_64_gpr8_alias_names()))
  append_vars(items, named_word_vars(8, x86_8_high_gpr_names()))
  append_vars(items, named_word_vars(16, x86_segment_names(false)))
  items.push(word_var(2, "IOPL"))
  append_vars(items, numbered_word_vars(80, "ST", 8))
  append_vars(items, numbered_word_vars(64, "MM", 8))
  append_vars(items, numbered_word_vars(256, "YMM", 16))
  append_vars(items, numbered_word_vars(128, "XMM", 16))
  append_vars(items, x86_flags())
  items.push(mem_var(64, 8, "mem"))
  items
}

///|
fn arm32_vars() -> Array[Var] {
  let items = numbered_word_vars(32, "R", 16)
  append_vars(items, numbered_word_vars(64, "D", 32))
  append_vars(items, named_word_vars(32, ["SP", "LR", "PC", "CPSR"]))
  append_vars(items, arm32_flags())
  items.push(mem_var(32, 8, "mem"))
  items
}

///|
fn arm32_flags() -> Array[Var] {
  [
    for name in ["NF", "ZF", "CF", "VF", "QF"] => bool_var(name)
  ]
}

///|
fn aarch64_flags() -> Array[Var] {
  [
    for name in ["NF", "ZF", "CF", "VF"] => bool_var(name)
  ]
}

///|
fn arm32_alias_origins() -> Array[AliasOrigin] {
  [
    AliasOrigin::register(word_var(32, "SP"), word_var(32, "R13")),
    AliasOrigin::register(word_var(32, "LR"), word_var(32, "R14")),
    AliasOrigin::register(word_var(32, "PC"), word_var(32, "R15")),
    AliasOrigin::bit_set(word_var(32, "CPSR"), arm32_flags()),
  ]
}

///|
fn aarch64_vars() -> Array[Var] {
  let items = numbered_word_vars(64, "R", 32)
  append_vars(items, numbered_word_vars(64, "X", 32))
  append_vars(items, numbered_word_vars(32, "W", 32))
  append_vars(items, numbered_word_vars(128, "V", 32))
  append_vars(items, numbered_word_vars(128, "Q", 32))
  append_vars(items, numbered_word_vars(64, "D", 32))
  append_vars(items, numbered_word_vars(32, "S", 32))
  append_vars(items, numbered_word_vars(16, "H", 32))
  append_vars(items, numbered_word_vars(8, "B", 32))
  append_vars(items, named_word_vars(64, ["FP", "LR", "ZR", "XZR"]))
  append_vars(items, named_word_vars(32, ["WSP", "WZR"]))
  append_vars(items, named_word_vars(64, ["SP", "PC"]))
  items.push(word_var(32, "NZCV"))
  append_vars(items, aarch64_flags())
  items.push(mem_var(64, 8, "mem"))
  items
}

///|
fn aarch64_alias_origins() -> Array[AliasOrigin] {
  let items : Array[AliasOrigin] = []
  for i in 0..<32 {
    items.push(
      AliasOrigin::register(word_var(64, "X\{i}"), word_var(64, "R\{i}")),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(32, "W\{i}"),
        word_var(64, "R\{i}"),
        lo=0,
        hi=31,
      ),
    )
    items.push(
      AliasOrigin::register(word_var(128, "Q\{i}"), word_var(128, "V\{i}")),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(64, "D\{i}"),
        word_var(128, "V\{i}"),
        lo=0,
        hi=63,
      ),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(32, "S\{i}"),
        word_var(128, "V\{i}"),
        lo=0,
        hi=31,
      ),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(16, "H\{i}"),
        word_var(128, "V\{i}"),
        lo=0,
        hi=15,
      ),
    )
    items.push(
      AliasOrigin::subregister(
        word_var(8, "B\{i}"),
        word_var(128, "V\{i}"),
        lo=0,
        hi=7,
      ),
    )
  }
  items.push(AliasOrigin::register(word_var(64, "FP"), word_var(64, "X29")))
  items.push(AliasOrigin::register(word_var(64, "LR"), word_var(64, "X30")))
  items.push(AliasOrigin::register(word_var(64, "SP"), word_var(64, "X31")))
  items.push(
    AliasOrigin::subregister(
      word_var(32, "WSP"),
      word_var(64, "SP"),
      lo=0,
      hi=31,
    ),
  )
  items.push(AliasOrigin::unknown(word_var(64, "XZR")))
  items.push(AliasOrigin::register(word_var(64, "ZR"), word_var(64, "XZR")))
  items.push(AliasOrigin::bit_set(word_var(32, "NZCV"), aarch64_flags()))
  items.push(
    AliasOrigin::subregister(
      word_var(32, "WZR"),
      word_var(64, "XZR"),
      lo=0,
      hi=31,
    ),
  )
  items
}

///|
fn mips_gpr_alias_names() -> Array[String] {
  [
    "ZERO", "AT", "V0", "V1", "A0", "A1", "A2", "A3", "T0", "T1", "T2", "T3", "T4",
    "T5", "T6", "T7", "S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7", "T8", "T9",
    "K0", "K1", "GP", "SP", "FP", "RA",
  ]
}

///|
fn mips_alias_vars(bits : Int) -> Array[Var] {
  [
    for name in mips_gpr_alias_names() => word_var(bits, name)
  ]
}

///|
fn mips_alias_origins(bits : Int) -> Array[AliasOrigin] {
  let names = mips_gpr_alias_names()
  [
    for i in 0..<names.length() => {
      AliasOrigin::register(word_var(bits, names[i]), word_var(bits, "R\{i}"))
    }
  ]
}

///|
fn mips_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "R", 32)
  append_vars(items, numbered_word_vars(bits, "F", 32))
  append_vars(items, mips_alias_vars(bits))
  append_vars(items, named_word_vars(bits, ["HI", "LO", "PC"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn riscv_gpr_alias_names() -> Array[String] {
  [
    "ZERO", "RA", "SP", "GP", "TP", "T0", "T1", "T2", "S0", "S1", "A0", "A1", "A2",
    "A3", "A4", "A5", "A6", "A7", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
    "S10", "S11", "T3", "T4", "T5", "T6",
  ]
}

///|
fn riscv_alias_vars(bits : Int) -> Array[Var] {
  [
    for name in riscv_gpr_alias_names() => word_var(bits, name)
  ]
}

///|
fn riscv_alias_origins(bits : Int) -> Array[AliasOrigin] {
  let names = riscv_gpr_alias_names()
  [
    for i in 0..<names.length() => {
      AliasOrigin::register(word_var(bits, names[i]), word_var(bits, "X\{i}"))
    }
  ]
}

///|
fn sparc_vars(bits : Int) -> Array[Var] {
  let items = []
  for prefix in ["G", "O", "L", "I"] {
    append_vars(items, numbered_word_vars(bits, prefix, 8))
  }
  append_vars(items, numbered_word_vars(32, "F", 32))
  append_vars(items, named_word_vars(bits, ["PC", "NPC", "SP", "FP"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn sparc_alias_origins(bits : Int) -> Array[AliasOrigin] {
  [
    AliasOrigin::register(word_var(bits, "SP"), word_var(bits, "O6")),
    AliasOrigin::register(word_var(bits, "FP"), word_var(bits, "I6")),
  ]
}

///|
fn ppc_cr_flag_vars() -> Array[Var] {
  let items = []
  for group in 0..<=7 {
    for suffix in ["UN", "EQ", "GT", "LT"] {
      items.push(bool_var("CR\{group}\{suffix}"))
    }
  }
  items
}

///|
fn ppc_flag_vars() -> Array[Var] {
  let items = [
    for name in ["SO", "CA", "OV", "CA32", "OV32", "C", "FL", "FE", "FG", "FU"] => {
      bool_var(name)
    }
  ]
  append_vars(items, ppc_cr_flag_vars())
  items
}

///|
fn ppc_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "R", 32)
  append_vars(items, numbered_word_vars(64, "F", 32))
  append_vars(items, numbered_word_vars(128, "V", 32))
  append_vars(items, ppc_flag_vars())
  append_vars(
    items,
    named_word_vars(bits, ["CTR", "LR", "TAR", "PC", "SP", "ZERO"]),
  )
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn ppc_alias_origins(bits : Int) -> Array[AliasOrigin] {
  [AliasOrigin::register(word_var(bits, "SP"), word_var(bits, "R1"))]
}

///|
fn numbered_pc_mem_vars(bits : Int, prefix : String, count : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, prefix, count)
  append_vars(items, named_word_vars(bits, ["PC"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn systemz_vars() -> Array[Var] {
  let items = numbered_word_vars(64, "R", 16)
  append_vars(items, numbered_word_vars(64, "F", 16))
  append_vars(items, named_word_vars(64, ["PC", "SP"]))
  items.push(mem_var(64, 8, "mem"))
  items
}

///|
fn systemz_alias_origins() -> Array[AliasOrigin] {
  [AliasOrigin::register(word_var(64, "SP"), word_var(64, "R15"))]
}

///|
fn riscv_family_vars() -> Array[Var] {
  []
}

///|
fn riscv_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "X", 32)
  append_vars(items, numbered_word_vars(bits, "F", 32))
  append_vars(items, riscv_alias_vars(bits))
  append_vars(items, named_word_vars(bits, ["PC"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn find_in_targets(items : Array[Target], query : String) -> Target? {
  for target in items {
    if target_has_name(target, query) {
      return Some(target)
    }
  }
  None
}

///|
fn target_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister | FloatingRegister | VectorRegister => []
    StackPointer => ["sp", "esp", "rsp"]
    FramePointer => ["fp", "ebp", "rbp"]
    ProgramCounter => ["pc", "eip", "rip"]
    Status =>
      ["flags", "eflags", "cpsr", "nzcv", "cf", "pf", "af", "zf", "sf", "of"]
    Constant => ["zero"]
    ZeroRegister => ["zero"]
    LinkRegister => ["lr", "ra"]
    ThreadPointer => ["tp"]
    Argument =>
      [
        "r0", "r1", "r2", "r3", "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "rdi",
        "rsi", "rdx", "rcx", "r8", "r9",
      ]
    ResultRegister => ["r0", "x0", "eax", "rax"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn role_names(prefix : String, first : Int, last : Int) -> Array[String] {
  [
    for i in first..<=last => "\{prefix}\{i}"
  ]
}

///|
fn concat_role_names(groups : Array[Array[String]]) -> Array[String] {
  let items = []
  for group in groups {
    for name in group {
      items.push(name)
    }
  }
  items
}

///|
fn x86_64_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        lower_names(x86_64_gpr_names()),
        lower_names(x86_64_gpr32_alias_names()),
        lower_names(x86_64_gpr16_alias_names()),
        lower_names(x86_64_gpr8_alias_names()),
        lower_names(x86_8_high_gpr_names()),
        lower_names(x86_segment_names(false)),
      ])
    FloatingRegister =>
      concat_role_names([role_names("st", 0, 7), role_names("mm", 0, 7)])
    VectorRegister =>
      concat_role_names([role_names("xmm", 0, 15), role_names("ymm", 0, 15)])
    StackPointer => ["rsp", "esp", "sp", "spl"]
    FramePointer => ["rbp", "ebp", "bp", "bpl"]
    ProgramCounter => ["rip"]
    Status =>
      concat_role_names([
        ["eflags", "rflags", "mxcsr", "iopl"],
        lower_names(x86_flag_names()),
      ])
    Constant | ZeroRegister | LinkRegister | ThreadPointer => []
    Argument => ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
    ResultRegister => ["rax", "rdx", "eax", "edx", "ax", "dx", "al", "dl"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn x86_16_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        lower_names(x86_16_gpr_names()),
        lower_names(x86_8_low_gpr_names()),
        lower_names(x86_8_high_gpr_names()),
        ["sil", "dil", "bpl", "spl"],
        lower_names(x86_segment_names(false)),
      ])
    FloatingRegister => []
    VectorRegister => []
    StackPointer => ["sp", "spl"]
    FramePointer => ["bp", "bpl"]
    ProgramCounter => []
    Status =>
      concat_role_names([["eflags", "iopl"], lower_names(x86_flag_names())])
    Constant | ZeroRegister | LinkRegister | ThreadPointer => []
    Argument => []
    ResultRegister => ["ax", "dx", "al", "dl"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn x86_32_cpu_role_names(
  role : Role,
  st~ : Bool,
  mmx~ : Bool,
  xmm~ : Bool,
) -> Array[String] {
  match role {
    FloatingRegister => {
      let groups = []
      if st {
        groups.push(role_names("st", 0, 7))
      }
      if mmx {
        groups.push(role_names("mm", 0, 7))
      }
      concat_role_names(groups)
    }
    VectorRegister => if xmm { role_names("xmm", 0, 7) } else { [] }
    _ => x86_32_role_names(role)
  }
}

///|
fn x86_32_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        lower_names(x86_32_gpr_names()),
        lower_names(x86_16_gpr_names()),
        lower_names(x86_8_low_gpr_names()),
        lower_names(x86_8_high_gpr_names()),
        lower_names(x86_segment_names(true)),
      ])
    FloatingRegister =>
      concat_role_names([role_names("st", 0, 7), role_names("mm", 0, 7)])
    VectorRegister => role_names("xmm", 0, 7)
    StackPointer => ["esp", "sp"]
    FramePointer => ["ebp", "bp"]
    ProgramCounter => ["eip"]
    Status =>
      concat_role_names([["eflags", "iopl"], lower_names(x86_flag_names())])
    Constant | ZeroRegister | LinkRegister | ThreadPointer => []
    Argument => []
    ResultRegister => ["eax", "edx", "ax", "dx", "al", "dl"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn arm32_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister => concat_role_names([role_names("r", 0, 12), ["sp", "lr"]])
    FloatingRegister => role_names("d", 0, 31)
    VectorRegister => []
    StackPointer => ["sp"]
    FramePointer => ["r11"]
    ProgramCounter => ["pc"]
    Status => ["cpsr", "nf", "zf", "cf", "vf", "qf"]
    Constant | ZeroRegister | ThreadPointer => []
    LinkRegister => ["lr", "r14"]
    Argument => ["r0", "r1", "r2", "r3"]
    ResultRegister => ["r0", "r1"]
    CallerSaved => ["r0", "r1", "r2", "r3", "r12", "lr"]
    CalleeSaved => ["r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11", "sp"]
    Reserved => []
  }
}

///|
fn aarch64_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        role_names("x", 0, 31),
        role_names("w", 0, 31),
        role_names("r", 0, 31),
        ["sp", "wsp"],
      ])
    FloatingRegister =>
      concat_role_names([
        role_names("d", 0, 31),
        role_names("s", 0, 31),
        role_names("h", 0, 31),
        role_names("b", 0, 31),
      ])
    VectorRegister =>
      concat_role_names([role_names("v", 0, 31), role_names("q", 0, 31)])
    StackPointer => ["sp", "wsp", "x31", "r31"]
    FramePointer => ["fp", "x29", "r29"]
    ProgramCounter => ["pc"]
    Status => ["nzcv", "nf", "zf", "cf", "vf"]
    Constant | ZeroRegister => ["zr", "xzr", "wzr"]
    ThreadPointer => []
    LinkRegister => ["lr", "x30", "r30"]
    Argument =>
      concat_role_names([
        role_names("x", 0, 7),
        role_names("r", 0, 7),
        role_names("v", 0, 7),
      ])
    ResultRegister => ["x0", "x1", "r0", "r1", "v0", "v1"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn mips_role_names(bits : Int, role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        role_names("r", 0, 31),
        [
          for name in mips_gpr_alias_names() => name.to_lower()
        ],
      ])
    FloatingRegister => role_names("f", 0, 31)
    VectorRegister => []
    StackPointer => ["sp", "r29"]
    FramePointer => ["fp", "r30"]
    ProgramCounter => ["pc"]
    Status => []
    Constant => ["zero", "r0"]
    ZeroRegister => ["zero", "r0"]
    LinkRegister => ["ra", "r31"]
    ThreadPointer => []
    Argument =>
      if bits == 64 {
        concat_role_names([role_names("r", 4, 11), role_names("f", 1, 8)])
      } else {
        concat_role_names([role_names("r", 4, 7), role_names("f", 1, 4)])
      }
    ResultRegister => ["v0", "r2", "f0"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => ["k0", "k1", "r26", "r27"]
  }
}

///|
fn powerpc_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister => role_names("r", 0, 31)
    FloatingRegister => role_names("f", 0, 31)
    VectorRegister => role_names("v", 0, 31)
    StackPointer => ["sp", "r1"]
    FramePointer => []
    ProgramCounter => ["pc"]
    Status =>
      concat_role_names([
        ["so", "ca", "ov", "ca32", "ov32", "c", "fl", "fe", "fg", "fu"],
        [
          for group in 0..<=7 => "cr\{group}eq"
        ],
        [
          for group in 0..<=7 => "cr\{group}lt"
        ],
        [
          for group in 0..<=7 => "cr\{group}gt"
        ],
        [
          for group in 0..<=7 => "cr\{group}un"
        ],
      ])
    Constant => ["zero"]
    ZeroRegister => ["zero"]
    LinkRegister => ["lr"]
    ThreadPointer => []
    Argument =>
      concat_role_names([role_names("r", 3, 10), role_names("f", 1, 8)])
    ResultRegister => ["r3", "r4", "f0"]
    CallerSaved =>
      concat_role_names([["r0"], role_names("r", 3, 12), role_names("f", 0, 13)])
    CalleeSaved =>
      concat_role_names([
        ["r1"],
        role_names("r", 14, 31),
        role_names("f", 14, 31),
      ])
    Reserved => ["r2"]
  }
}

///|
fn riscv_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        role_names("x", 0, 31),
        [
          for name in riscv_gpr_alias_names() => name.to_lower()
        ],
      ])
    FloatingRegister => role_names("f", 0, 31)
    VectorRegister => []
    StackPointer => ["sp", "x2"]
    FramePointer => ["fp", "s0", "x8"]
    ProgramCounter => ["pc"]
    Status => []
    Constant => ["zero", "x0"]
    ZeroRegister => ["zero", "x0"]
    LinkRegister => ["ra", "x1"]
    ThreadPointer => ["gp", "x3"]
    Argument =>
      concat_role_names([
        role_names("x", 10, 17),
        role_names("f", 10, 17),
        role_names("a", 0, 7),
      ])
    ResultRegister =>
      concat_role_names([
        role_names("x", 10, 12),
        role_names("f", 10, 12),
        role_names("a", 0, 2),
      ])
    CallerSaved =>
      concat_role_names([
        ["ra", "x1"],
        role_names("x", 5, 7),
        role_names("x", 10, 17),
        role_names("x", 28, 31),
        role_names("f", 0, 7),
        role_names("f", 10, 17),
        role_names("f", 28, 31),
      ])
    CalleeSaved =>
      concat_role_names([
        ["sp", "x2"],
        role_names("x", 8, 9),
        role_names("x", 18, 27),
        role_names("f", 8, 9),
        role_names("f", 18, 27),
      ])
    Reserved => []
  }
}

///|
fn sparc_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister =>
      concat_role_names([
        role_names("g", 0, 7),
        role_names("o", 0, 7),
        role_names("l", 0, 7),
        role_names("i", 0, 7),
      ])
    FloatingRegister => role_names("f", 0, 31)
    VectorRegister => []
    StackPointer => ["sp", "o6"]
    FramePointer => ["fp", "i6"]
    ProgramCounter => ["pc", "npc"]
    Status => []
    Constant | ZeroRegister | ThreadPointer => []
    LinkRegister => ["o7", "i7"]
    Argument => role_names("o", 0, 5)
    ResultRegister => ["o0", "o1"]
    CallerSaved => concat_role_names([role_names("o", 0, 7), ["g1"]])
    CalleeSaved =>
      concat_role_names([role_names("l", 0, 7), role_names("i", 0, 7)])
    Reserved => []
  }
}

///|
fn systemz_role_names(role : Role) -> Array[String] {
  match role {
    General => []
    IntegerRegister => role_names("r", 0, 15)
    FloatingRegister => role_names("f", 0, 15)
    VectorRegister => []
    StackPointer => ["sp", "r15"]
    FramePointer => []
    ProgramCounter => ["pc"]
    Status => []
    Constant | ZeroRegister | ThreadPointer => []
    LinkRegister => ["r14"]
    Argument => role_names("r", 2, 6)
    ResultRegister => ["r2", "f0"]
    CallerSaved => []
    CalleeSaved => []
    Reserved => []
  }
}

///|
fn target_specific_role_names(target : Target, role : Role) -> Array[String]? {
  if target.belongs(Target::x86_64()) {
    Some(x86_64_role_names(role))
  } else if target.belongs(Target::i686()) {
    Some(x86_32_cpu_role_names(role, st=true, mmx=true, xmm=true))
  } else if target.belongs(Target::i586()) {
    Some(x86_32_cpu_role_names(role, st=true, mmx=true, xmm=false))
  } else if target.belongs(Target::i486()) {
    Some(x86_32_cpu_role_names(role, st=true, mmx=false, xmm=false))
  } else if target.belongs(Target::i386()) {
    Some(x86_32_cpu_role_names(role, st=false, mmx=false, xmm=false))
  } else if target.belongs(Target::i86()) {
    Some(x86_16_role_names(role))
  } else if target.belongs(Target::x86()) {
    Some(x86_32_role_names(role))
  } else if target.belongs(Target::aarch64()) ||
    target.belongs(Target::aarch64_be()) {
    Some(aarch64_role_names(role))
  } else if target.belongs(Target::arm()) || target.belongs(Target::armeb()) {
    Some(arm32_role_names(role))
  } else if target.belongs(Target::mips_family()) {
    Some(mips_role_names(target.bits(), role))
  } else if target.belongs(Target::powerpc_family()) {
    Some(powerpc_role_names(role))
  } else if target.belongs(Target::riscv()) {
    Some(riscv_role_names(role))
  } else if target.belongs(Target::sparc()) {
    Some(sparc_role_names(role))
  } else if target.belongs(Target::systemz()) {
    Some(systemz_role_names(role))
  } else {
    None
  }
}

///|
fn target_role_names_for(target : Target, role : Role) -> Array[String] {
  match target_specific_role_names(target, role) {
    Some(names) => names
    None => target_role_names(role)
  }
}

///|
fn target_name_has_role(target : Target, name : String, role : Role) -> Bool {
  let lower = name.to_lower()
  target_role_names_for(target, role).contains(lower)
}

///|
fn add_role(roles : Array[Role], role : Role) -> Unit {
  if !roles.contains(role) {
    roles.push(role)
  }
}

///|
pub fn AliasOrigin::register(aliased : Var, source : Var) -> AliasOrigin {
  RegisterAlias(aliased~, source~)
}

///|
pub fn AliasOrigin::subregister(
  aliased : Var,
  source : Var,
  lo~ : Int,
  hi~ : Int,
) -> AliasOrigin {
  SubRegister(aliased~, source~, lo~, hi~)
}

///|
pub fn AliasOrigin::bit_set(aliased : Var, bits : Array[Var]) -> AliasOrigin {
  BitSetAlias(aliased~, bits=bits.copy())
}

///|
pub fn AliasOrigin::unknown(aliased : Var) -> AliasOrigin {
  UnknownAlias(aliased~)
}

///|
pub fn AliasOrigin::aliased(self : AliasOrigin) -> Var {
  match self {
    RegisterAlias(aliased~, ..)
    | SubRegister(aliased~, ..)
    | BitSetAlias(aliased~, ..)
    | UnknownAlias(aliased~) => aliased
  }
}

///|
pub fn AliasOrigin::source(self : AliasOrigin) -> Var? {
  match self {
    RegisterAlias(source~, ..) | SubRegister(source~, ..) => Some(source)
    BitSetAlias(_) | UnknownAlias(_) => None
  }
}

///|
pub fn AliasOrigin::range(self : AliasOrigin) -> (Int, Int)? {
  match self {
    SubRegister(lo~, hi~, ..) => Some((lo, hi))
    RegisterAlias(_) | BitSetAlias(_) | UnknownAlias(_) => None
  }
}

///|
pub fn AliasOrigin::bits(self : AliasOrigin) -> Array[Var] {
  match self {
    BitSetAlias(bits~, ..) => bits.copy()
    RegisterAlias(_) | SubRegister(_) | UnknownAlias(_) => []
  }
}

///|
pub fn Target::unknown() -> Target {
  {
    name_value: @knowledge.Name::create("unknown", pkg="target"),
    parent_value: None,
    nicknames_value: [],
    bits_value: 0,
    byte_value: 8,
    endianness_value: BiEndian,
    system_value: UnknownSystem,
    abi_value: UnknownAbi,
    fabi_value: UnknownFabi,
    filetype_value: UnknownFiletype,
    options_value: TargetOptions::empty(),
    vars_value: [],
    alias_origins_value: [],
  }
}

///|
pub fn Target::create(
  name~ : @knowledge.Name,
  parent? : Target,
  nicknames? : Array[String],
  bits? : Int,
  byte? : Int,
  endianness? : Endianness,
  system? : System,
  abi? : Abi,
  fabi? : Fabi,
  filetype? : Filetype,
  options? : TargetOptions,
  vars? : Array[Var],
  alias_origins? : Array[AliasOrigin],
) -> Target {
  {
    name_value: name,
    parent_value: parent,
    nicknames_value: match nicknames {
      Some(items) => items.copy()
      None => []
    },
    bits_value: match bits {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.bits()
          None => 0
        }
    },
    byte_value: match byte {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.byte()
          None => 8
        }
    },
    endianness_value: match endianness {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.endianness()
          None => BiEndian
        }
    },
    system_value: match system {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.system()
          None => UnknownSystem
        }
    },
    abi_value: match abi {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.abi()
          None => UnknownAbi
        }
    },
    fabi_value: match fabi {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.fabi()
          None => UnknownFabi
        }
    },
    filetype_value: match filetype {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.filetype()
          None => UnknownFiletype
        }
    },
    options_value: match options {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.options()
          None => TargetOptions::empty()
        }
    },
    vars_value: match vars {
      Some(items) => items.copy()
      None =>
        match parent {
          Some(target) => target.vars()
          None => []
        }
    },
    alias_origins_value: match alias_origins {
      Some(items) => items.copy()
      None =>
        match parent {
          Some(target) => target.alias_origins()
          None => []
        }
    },
  }
}

///|
pub fn Target::name(self : Target) -> @knowledge.Name {
  self.name_value
}

///|
pub fn Target::parent(self : Target) -> Target? {
  self.parent_value
}

///|
pub fn Target::nicknames(self : Target) -> Array[String] {
  self.nicknames_value.copy()
}

///|
pub fn Target::bits(self : Target) -> Int {
  self.bits_value
}

///|
pub fn Target::byte(self : Target) -> Int {
  self.byte_value
}

///|
pub fn Target::endianness(self : Target) -> Endianness {
  self.endianness_value
}

///|
pub fn Target::system(self : Target) -> System {
  self.system_value
}

///|
pub fn Target::abi(self : Target) -> Abi {
  self.abi_value
}

///|
pub fn Target::fabi(self : Target) -> Fabi {
  self.fabi_value
}

///|
pub fn Target::filetype(self : Target) -> Filetype {
  self.filetype_value
}

///|
pub fn Target::options(self : Target) -> TargetOptions {
  self.options_value
}

///|
pub fn Target::vars(self : Target) -> Array[Var] {
  self.vars_value.copy()
}

///|
pub fn Target::alias_origins(self : Target) -> Array[AliasOrigin] {
  self.alias_origins_value.copy()
}

///|
pub fn Target::with_var(self : Target, item : Var) -> Target {
  let items = self.vars_value.copy()
  items.push(item)
  { ..self, vars_value: items }
}

///|
pub fn Target::with_vars(self : Target, more : Array[Var]) -> Target {
  let items = self.vars_value.copy()
  append_vars(items, more)
  { ..self, vars_value: items }
}

///|
pub fn Target::with_bits(self : Target, bits : Int) -> Target {
  { ..self, bits_value: bits }
}

///|
pub fn Target::with_endianness(
  self : Target,
  endianness : Endianness,
) -> Target {
  { ..self, endianness_value: endianness }
}

///|
pub fn Target::with_system(self : Target, system : System) -> Target {
  { ..self, system_value: system }
}

///|
pub fn Target::with_abi(self : Target, abi : Abi) -> Target {
  { ..self, abi_value: abi }
}

///|
pub fn Target::with_fabi(self : Target, fabi : Fabi) -> Target {
  { ..self, fabi_value: fabi }
}

///|
pub fn Target::with_filetype(self : Target, filetype : Filetype) -> Target {
  { ..self, filetype_value: filetype }
}

///|
pub fn Target::with_options(self : Target, options : TargetOptions) -> Target {
  { ..self, options_value: options }
}

///|
pub fn Target::with_option(
  self : Target,
  key : String,
  value : String,
) -> Target {
  { ..self, options_value: self.options_value.with_value(key, value) }
}

///|
pub fn Target::with_alias_origin(self : Target, origin : AliasOrigin) -> Target {
  let items = self.alias_origins_value.copy()
  items.push(origin)
  { ..self, alias_origins_value: items }
}

///|
pub fn Target::find_var(self : Target, name : String) -> Var? {
  self.vars_value
  .search_by(item => {
    same_target_name(item.ident(), name) || same_target_name(item.name(), name)
  })
  .map(i => self.vars_value[i])
}

///|
pub fn Target::origin_of_var(self : Target, variable : Var) -> AliasOrigin? {
  self.alias_origins_value
  .search_by(origin => origin.aliased().same(variable))
  .map(i => self.alias_origins_value[i])
}

///|
pub fn Target::origin_of_name(self : Target, name : String) -> AliasOrigin? {
  match self.find_var(name) {
    Some(variable) => self.origin_of_var(variable)
    None => None
  }
}

///|
pub fn Target::roles_of_var(self : Target, variable : Var) -> Array[Role] {
  let roles = []
  for
    role in [
      StackPointer,
      IntegerRegister,
      FloatingRegister,
      VectorRegister,
      FramePointer,
      ProgramCounter,
      Status,
      Constant,
      ZeroRegister,
      LinkRegister,
      ThreadPointer,
      Argument,
      ResultRegister,
      CallerSaved,
      CalleeSaved,
      Reserved,
    ] {
    if target_name_has_role(self, variable.ident(), role) ||
      target_name_has_role(self, variable.name(), role) {
      add_role(roles, role)
    }
  }
  if roles.is_empty() {
    [General]
  } else {
    roles
  }
}

///|
pub fn Target::vars_with_role(self : Target, role : Role) -> Array[Var] {
  self.vars_value.filter(variable => self.roles_of_var(variable).contains(role))
}

///|
pub fn Target::find_role(self : Target, role : Role) -> Var? {
  match
    self.vars_value.search_by(variable => {
      self.roles_of_var(variable).contains(role)
    }) {
    Some(i) => Some(self.vars_value[i])
    None => None
  }
}

///|
pub fn Target::role_aliases(self : Target, role : Role) -> Array[String] {
  target_role_names_for(self, role)
}

///|
pub fn Target::data_addr_size(self : Target) -> Int {
  self.bits_value
}

///|
pub fn Target::data_addr(
  self : Target,
  value : @bitvec.BitVec,
) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::create(value, self.data_addr_size())
}

///|
pub fn Target::code_addr_size(self : Target) -> Int {
  self.bits_value
}

///|
pub fn Target::code_addr(
  self : Target,
  value : @bitvec.BitVec,
) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::create(value, self.code_addr_size())
}

///|
pub fn Target::data_word(
  self : Target,
  value : @bitvec.BitVec,
) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::create(value, self.bits())
}

///|
pub fn Target::is_unknown(self : Target) -> Bool {
  self.name_value == @knowledge.Name::create("unknown", pkg="target")
}

///|
pub fn Target::matching(self : Target, query : String) -> Target? {
  if target_has_name(self, query) {
    Some(self)
  } else {
    match self.parent_value {
      Some(parent) => parent.matching(query)
      None => None
    }
  }
}

///|
pub fn Target::matches(self : Target, query : String) -> Bool {
  match self.matching(query) {
    Some(_) => true
    None => false
  }
}

///|
pub fn Target::belongs(self : Target, parent : Target) -> Bool {
  if parent.is_unknown() {
    true
  } else if self.name_value == parent.name() {
    true
  } else {
    match self.parent_value {
      Some(next) => next.belongs(parent)
      None => false
    }
  }
}

///|
pub fn Target::order(self : Target, other : Target) -> @knowledge.PartialOrder {
  if self.name_value == other.name() {
    Equal
  } else if self.belongs(other) {
    Less
  } else if other.belongs(self) {
    Greater
  } else {
    Incomparable
  }
}

///|
fn collect_parents(target : Target, items : Array[Target]) -> Unit {
  match target.parent() {
    Some(parent) => {
      collect_parents(parent, items)
      items.push(parent)
    }
    None => ()
  }
}

///|
pub fn Target::parents(self : Target) -> Array[Target] {
  let items = []
  collect_parents(self, items)
  items
}

///|
pub fn Target::x86() -> Target {
  Target::create(
    name=target_name("x86"),
    nicknames=["x86-32", "x86_32", "ia32", "ia-32"],
    bits=32,
    endianness=LittleEndian,
    vars=x86_32_vars(),
    alias_origins=x86_32_alias_origins(),
  )
}

///|
pub fn Target::i86() -> Target {
  Target::create(
    name=target_name("i86"),
    parent=Target::x86(),
    nicknames=["8086"],
    bits=16,
    endianness=LittleEndian,
    vars=x86_16_vars(),
    alias_origins=x86_16_alias_origins(),
  )
}

///|
pub fn Target::i186() -> Target {
  Target::create(name=target_name("i186"), parent=Target::i86(), nicknames=[
    "80186", "186",
  ])
}

///|
pub fn Target::i286() -> Target {
  Target::create(name=target_name("i286"), parent=Target::i186(), nicknames=[
    "80286", "286",
  ])
}

///|
pub fn Target::i386() -> Target {
  Target::create(
    name=target_name("i386"),
    parent=Target::i286(),
    nicknames=["386", "80386"],
    bits=32,
    vars=x86_i386_vars(),
    alias_origins=x86_32_alias_origins(),
  )
}

///|
pub fn Target::i486() -> Target {
  Target::create(
    name=target_name("i486"),
    parent=Target::i386(),
    nicknames=["486", "80486"],
    vars=x86_i486_vars(),
    alias_origins=x86_32_alias_origins(),
  )
}

///|
pub fn Target::i586() -> Target {
  Target::create(
    name=target_name("i586"),
    parent=Target::i486(),
    nicknames=["586", "80586", "p5"],
    vars=x86_i586_vars(),
    alias_origins=x86_32_alias_origins(),
  )
}

///|
pub fn Target::i686() -> Target {
  Target::create(
    name=target_name("i686"),
    parent=Target::i586(),
    nicknames=["686", "80686", "p6"],
    vars=x86_i686_vars(),
    alias_origins=x86_32_alias_origins(),
  )
}

///|
pub fn Target::x86_64() -> Target {
  Target::create(
    name=target_name("x86_64"),
    parent=Target::i686(),
    nicknames=["x86-64", "amd64", "x64", "x86_64h"],
    bits=64,
    endianness=LittleEndian,
    vars=x86_64_vars(),
    alias_origins=x86_64_alias_origins(),
  )
}

///|
fn with_endian_suffix(names : Array[String], suffix : String) -> Array[String] {
  names + [ for name in names => "\{name}+\{suffix}" ]
}

///|
fn arm32_le_nicknames() -> Array[String] {
  let names = [
    "armv4", "armv4t", "armv5", "armv5t", "armv5te", "armv5tej", "armv6", "armv6t2",
    "armv6z", "armv6k", "armv6-m", "armv7", "armv7-a", "armv7+fp", "armv7-a+fp",
    "armv8-a+aarch32", "armv8-m+aarch32", "armv8-r+aarch32",
  ]
  ["aarch32"] + with_endian_suffix(names, "le") + ["xscale"]
}

///|
fn arm32_be_nicknames() -> Array[String] {
  let names = [
    "armv4", "armv4t", "armv5", "armv5t", "armv5te", "armv5tej", "armv6", "armv6t2",
    "armv6z", "armv6k", "armv6-m", "armv7", "armv7-a", "armv7+fp", "armv7-a+fp",
    "armv8-a+aarch32", "armv8-m+aarch32", "armv8-r+aarch32",
  ]
  ["armv4eb", "armv5eb", "armv6eb", "armv7eb", "aarch32eb"] +
  [
    for name in names => "\{name}+be"
  ]
}

///|
fn aarch64_version_nicknames() -> Array[String] {
  [
    "armv8", "armv8-a", "armv8.1-a", "armv8.2-a", "armv8.3-a", "armv8.4-a", "armv8.5-a",
    "armv8.6-a", "armv9-a",
  ]
}

///|
pub fn Target::arm() -> Target {
  Target::create(
    name=target_name("arm"),
    nicknames=arm32_le_nicknames(),
    bits=32,
    endianness=LittleEndian,
    vars=arm32_vars(),
    alias_origins=arm32_alias_origins(),
  )
}

///|
pub fn Target::armeb() -> Target {
  Target::create(
    name=target_name("armeb"),
    parent=Target::arm(),
    nicknames=arm32_be_nicknames(),
    bits=32,
    endianness=BigEndian,
    vars=arm32_vars(),
  )
}

///|
pub fn Target::thumb() -> Target {
  Target::create(
    name=target_name("thumb"),
    parent=Target::arm(),
    nicknames=[
      "thumbv4", "thumbv5", "thumbv6", "thumbv7", "armv7-m", "armv7-m+le",
    ],
    bits=32,
    endianness=LittleEndian,
    vars=arm32_vars(),
  )
}

///|
pub fn Target::thumbeb() -> Target {
  Target::create(
    name=target_name("thumbeb"),
    parent=Target::armeb(),
    nicknames=["thumbv4eb", "thumbv5eb", "thumbv6eb", "thumbv7eb", "armv7-m+be"],
    bits=32,
    endianness=BigEndian,
    vars=arm32_vars(),
  )
}

///|
pub fn Target::aarch64() -> Target {
  Target::create(
    name=target_name("aarch64"),
    parent=Target::arm(),
    nicknames=["arm64"] + with_endian_suffix(aarch64_version_nicknames(), "le"),
    bits=64,
    endianness=LittleEndian,
    vars=aarch64_vars(),
    alias_origins=aarch64_alias_origins(),
  )
}

///|
pub fn Target::aarch64_be() -> Target {
  Target::create(
    name=target_name("aarch64_be"),
    parent=Target::armeb(),
    nicknames=["arm64_be", "arm64eb", "armv8eb"] +
      [
        for name in aarch64_version_nicknames() => "\{name}+be"
      ],
    bits=64,
    endianness=BigEndian,
    vars=aarch64_vars(),
    alias_origins=aarch64_alias_origins(),
  )
}

///|
pub fn Target::mips() -> Target {
  Target::create(
    name=target_name("mips"),
    parent=Target::mips_family(),
    nicknames=["mipseb", "mips32", "mips32eb", "mipsbe", "mips32be"],
    bits=32,
    endianness=BigEndian,
    vars=mips_vars(32),
    alias_origins=mips_alias_origins(32),
  )
}

///|
pub fn Target::mips_family() -> Target {
  Target::create(name=target_name("mips-family"))
}

///|
pub fn Target::mipsbi() -> Target {
  Target::create(
    name=target_name("mipsbi"),
    parent=Target::mips_family(),
    nicknames=["mips32bi"],
    bits=32,
    endianness=BiEndian,
    vars=mips_vars(32),
    alias_origins=mips_alias_origins(32),
  )
}

///|
pub fn Target::mipsel() -> Target {
  Target::create(
    name=target_name("mipsel"),
    parent=Target::mips_family(),
    nicknames=["mipsle", "mips32le", "mips32el"],
    bits=32,
    endianness=LittleEndian,
    vars=mips_vars(32),
    alias_origins=mips_alias_origins(32),
  )
}

///|
pub fn Target::mips64bi() -> Target {
  Target::create(
    name=target_name("mips64bi"),
    parent=Target::mips_family(),
    bits=64,
    endianness=BiEndian,
    vars=mips_vars(64),
    alias_origins=mips_alias_origins(64),
  )
}

///|
pub fn Target::mips64() -> Target {
  Target::create(
    name=target_name("mips64"),
    parent=Target::mips_family(),
    nicknames=["mips64eb", "mips64be"],
    bits=64,
    endianness=BigEndian,
    vars=mips_vars(64),
    alias_origins=mips_alias_origins(64),
  )
}

///|
pub fn Target::mips64el() -> Target {
  Target::create(
    name=target_name("mips64el"),
    parent=Target::mips_family(),
    nicknames=["mips64le", "misp64le"],
    bits=64,
    endianness=LittleEndian,
    vars=mips_vars(64),
    alias_origins=mips_alias_origins(64),
  )
}

///|
pub fn Target::powerpc() -> Target {
  Target::create(
    name=target_name("powerpc"),
    parent=Target::powerpc_family(),
    nicknames=[
      "powerpc32+eb", "ppc", "powerpc32", "ppc32", "powerpc32be", "ppc32be", "power",
      "power32",
    ],
    bits=32,
    endianness=BigEndian,
    vars=ppc_vars(32),
    alias_origins=ppc_alias_origins(32),
  )
}

///|
pub fn Target::powerpc_family() -> Target {
  Target::create(name=target_name("powerpc-family"))
}

///|
pub fn Target::powerpcbi() -> Target {
  Target::create(
    name=target_name("powerpcbi"),
    parent=Target::powerpc_family(),
    nicknames=["powerpc32bi", "ppc32bi", "powerpc32+bi"],
    bits=32,
    endianness=BiEndian,
    vars=ppc_vars(32),
    alias_origins=ppc_alias_origins(32),
  )
}

///|
pub fn Target::powerpcle() -> Target {
  Target::create(
    name=target_name("powerpcle"),
    parent=Target::powerpc_family(),
    nicknames=[
      "powerpc32+le", "ppcle", "ppcel", "powerpc32le", "powerpc32el", "ppc32le",
      "ppc32el",
    ],
    bits=32,
    endianness=LittleEndian,
    vars=ppc_vars(32),
    alias_origins=ppc_alias_origins(32),
  )
}

///|
pub fn Target::powerpc64bi() -> Target {
  Target::create(
    name=target_name("powerpc64bi"),
    parent=Target::powerpc_family(),
    nicknames=["powerpc64+bi", "power64bi"],
    bits=64,
    endianness=BiEndian,
    vars=ppc_vars(64),
    alias_origins=ppc_alias_origins(64),
  )
}

///|
pub fn Target::powerpc64() -> Target {
  Target::create(
    name=target_name("powerpc64"),
    parent=Target::powerpc_family(),
    nicknames=[
      "ppc64", "ppu", "power64", "powerpc64eb", "powerpc64be", "ppc64eb", "ppc64be",
      "power64eb", "power64be",
    ],
    bits=64,
    endianness=BigEndian,
    vars=ppc_vars(64),
    alias_origins=ppc_alias_origins(64),
  )
}

///|
pub fn Target::powerpc64le() -> Target {
  Target::create(
    name=target_name("powerpc64le"),
    parent=Target::powerpc_family(),
    nicknames=[
      "powerpc64el", "powerpc64+le", "ppc64le", "ppc64el", "power64el", "power64le",
    ],
    bits=64,
    endianness=LittleEndian,
    vars=ppc_vars(64),
    alias_origins=ppc_alias_origins(64),
  )
}

///|
pub fn Target::riscv() -> Target {
  Target::create(
    name=target_name("riscv"),
    bits=0,
    endianness=LittleEndian,
    vars=riscv_family_vars(),
  )
}

///|
pub fn Target::riscv32() -> Target {
  Target::create(
    name=target_name("riscv32"),
    parent=Target::riscv(),
    bits=32,
    endianness=LittleEndian,
    vars=riscv_vars(32),
    alias_origins=riscv_alias_origins(32),
  )
}

///|
pub fn Target::riscv64() -> Target {
  Target::create(
    name=target_name("riscv64"),
    parent=Target::riscv(),
    bits=64,
    endianness=LittleEndian,
    vars=riscv_vars(64),
    alias_origins=riscv_alias_origins(64),
  )
}

///|
pub fn Target::sparc() -> Target {
  Target::create(
    name=target_name("sparc"),
    bits=32,
    endianness=BigEndian,
    vars=sparc_vars(32),
    alias_origins=sparc_alias_origins(32),
  )
}

///|
pub fn Target::sparcv9() -> Target {
  Target::create(
    name=target_name("sparcv9"),
    parent=Target::sparc(),
    nicknames=["sparc64"],
    bits=64,
    endianness=BigEndian,
    vars=sparc_vars(64),
    alias_origins=sparc_alias_origins(64),
  )
}

///|
pub fn Target::nvptx() -> Target {
  Target::create(
    name=target_name("nvptx"),
    bits=32,
    endianness=LittleEndian,
    vars=numbered_pc_mem_vars(32, "R", 32),
  )
}

///|
pub fn Target::nvptx64() -> Target {
  Target::create(
    name=target_name("nvptx64"),
    parent=Target::nvptx(),
    bits=64,
    endianness=LittleEndian,
    vars=numbered_pc_mem_vars(64, "R", 32),
  )
}

///|
pub fn Target::hexagon() -> Target {
  Target::create(
    name=target_name("hexagon"),
    bits=32,
    endianness=LittleEndian,
    vars=numbered_pc_mem_vars(32, "R", 32),
  )
}

///|
pub fn Target::r600() -> Target {
  Target::create(
    name=target_name("r600"),
    bits=32,
    endianness=LittleEndian,
    vars=numbered_pc_mem_vars(32, "R", 32),
  )
}

///|
pub fn Target::systemz() -> Target {
  Target::create(
    name=target_name("systemz"),
    bits=64,
    endianness=BigEndian,
    vars=systemz_vars(),
    alias_origins=systemz_alias_origins(),
  )
}

///|
pub fn Target::systemz9() -> Target {
  Target::create(
    name=target_name("systemz9"),
    parent=Target::systemz(),
    nicknames=["s390x"],
    bits=64,
    endianness=BigEndian,
    vars=systemz_vars(),
    alias_origins=systemz_alias_origins(),
  )
}

///|
pub fn Target::xcore() -> Target {
  Target::create(
    name=target_name("xcore"),
    bits=32,
    endianness=LittleEndian,
    vars=numbered_pc_mem_vars(32, "R", 16),
  )
}

///|
fn append_target_variants(
  items : Array[Target],
  parent : Target,
  systems : Array[System],
  filetypes : Array[Filetype],
  abis : Array[Abi],
) -> Unit {
  let options = TargetOptions::empty()
  for system in systems {
    for filetype in filetypes {
      for abi in abis {
        if !target_variant_is_empty(system, abi, UnknownFabi, filetype, options) {
          items.push(
            target_variant(parent, system, abi, UnknownFabi, filetype, options),
          )
        }
      }
    }
  }
}

///|
fn append_target_variants_with_fabis(
  items : Array[Target],
  parent : Target,
  systems : Array[System],
  filetypes : Array[Filetype],
  abis : Array[Abi],
  fabis : Array[Fabi],
) -> Unit {
  let options = TargetOptions::empty()
  for system in systems {
    for filetype in filetypes {
      for abi in abis {
        for fabi in fabis {
          if !target_variant_is_empty(system, abi, fabi, filetype, options) {
            items.push(
              target_variant(parent, system, abi, fabi, filetype, options),
            )
          }
        }
      }
    }
  }
}

///|
fn append_x86_target_variants(items : Array[Target]) -> Unit {
  let x86 = Target::x86()
  let x86_64 = Target::x86_64()
  append_target_variants(
    items,
    x86,
    [UnknownSystem],
    [COFF, AOut, Elf, MachO],
    [GNU, CDecl, StdCall, FastCall, Watcom, MSVC],
  )
  append_target_variants(
    items,
    x86_64,
    [UnknownSystem],
    [COFF, AOut, Elf, MachO],
    [GNU, MSVC],
  )
  append_target_variants(
    items,
    x86,
    [Linux, FreeBSD, OpenBSD],
    [UnknownFiletype, AOut, COFF, Elf],
    [GNU, CDecl],
  )
  append_target_variants(
    items,
    x86_64,
    [Linux, FreeBSD, OpenBSD],
    [UnknownFiletype, AOut, COFF, Elf],
    [GNU, CDecl],
  )
  append_target_variants(items, x86, [Darwin], [UnknownFiletype, MachO], [GNU])
  append_target_variants(items, x86_64, [Darwin], [UnknownFiletype, MachO], [
    GNU,
  ])
  append_target_variants(items, x86, [Windows], [UnknownFiletype, COFF], [
    MSVC,
    CDecl,
    FastCall,
    Pascal,
    FortranAbi,
    Watcom,
  ])
  append_target_variants(items, x86_64, [Windows], [UnknownFiletype, COFF], [
    MSVC,
  ])
  append_target_variants(items, x86, [UEFI], [UnknownFiletype, COFF], [CDecl])
  append_target_variants(items, x86_64, [UEFI], [UnknownFiletype, COFF], [MSVC])
}

///|
fn append_arm_target_variants(items : Array[Target]) -> Unit {
  append_target_variants_with_fabis(
    items,
    Target::arm(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::armeb(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::thumb(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::thumbeb(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::arm(),
    [UEFI],
    [UnknownFiletype, COFF],
    [SMC],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::arm(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNUEABI, GNU],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::armeb(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNUEABI, GNU],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::thumb(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNUEABI, GNU],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::thumbeb(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNUEABI, GNU],
    [UnknownFabi, Hard],
  )
  append_target_variants_with_fabis(
    items,
    Target::arm(),
    [Darwin],
    [UnknownFiletype, MachO],
    [EABI],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::thumb(),
    [Darwin],
    [UnknownFiletype, MachO],
    [EABI],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64_be(),
    [UnknownSystem, NoSystem],
    [UnknownFiletype],
    [EABI],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64(),
    [UEFI],
    [UnknownFiletype, COFF],
    [SMC],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNU],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64_be(),
    [Linux],
    [UnknownFiletype, Elf],
    [GNU],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64(),
    [Darwin],
    [UnknownFiletype, MachO],
    [EABI],
    [UnknownFabi],
  )
  append_target_variants_with_fabis(
    items,
    Target::aarch64(),
    [Windows],
    [UnknownFiletype, COFF],
    [EABI],
    [UnknownFabi],
  )
}

///|
fn append_mips_target_variants(items : Array[Target]) -> Unit {
  for
    parent in [
      Target::mips(),
      Target::mipsel(),
      Target::mips64(),
      Target::mips64el(),
    ] {
    append_target_variants(
      items,
      parent,
      [UnknownSystem, Linux, FreeBSD, OpenBSD],
      [UnknownFiletype, Elf],
      [UnknownAbi, GNU],
    )
  }
}

///|
fn append_powerpc_target_variants(items : Array[Target]) -> Unit {
  for
    parent in [
      Target::powerpc(),
      Target::powerpcle(),
      Target::powerpc64(),
      Target::powerpc64le(),
    ] {
    append_target_variants(
      items,
      parent,
      [UnknownSystem, Linux, FreeBSD, OpenBSD, VxWorks],
      [UnknownFiletype, Elf, MachO],
      [UnknownAbi, GNU],
    )
  }
}

///|
pub fn common_targets() -> Array[Target] {
  let items = [
    Target::x86(),
    Target::i86(),
    Target::i186(),
    Target::i286(),
    Target::i386(),
    Target::i486(),
    Target::i586(),
    Target::i686(),
    Target::x86_64(),
    Target::arm(),
    Target::armeb(),
    Target::thumb(),
    Target::thumbeb(),
    Target::aarch64(),
    Target::aarch64_be(),
    Target::mips_family(),
    Target::mipsbi(),
    Target::mips(),
    Target::mipsel(),
    Target::mips64bi(),
    Target::mips64(),
    Target::mips64el(),
    Target::powerpc_family(),
    Target::powerpcbi(),
    Target::powerpc(),
    Target::powerpcle(),
    Target::powerpc64bi(),
    Target::powerpc64(),
    Target::powerpc64le(),
    Target::riscv(),
    Target::riscv32(),
    Target::riscv64(),
    Target::sparc(),
    Target::sparcv9(),
    Target::nvptx(),
    Target::nvptx64(),
    Target::hexagon(),
    Target::r600(),
    Target::systemz(),
    Target::systemz9(),
    Target::xcore(),
  ]
  append_x86_target_variants(items)
  append_arm_target_variants(items)
  append_mips_target_variants(items)
  append_powerpc_target_variants(items)
  items
}

///|
pub fn register_target(target : Target) -> Result[Unit, String] {
  let key = target.name().show()
  if find_in_targets(common_targets(), key) is Some(_) {
    Err("target \{key} is a built-in target")
  } else if find_target(target.name().unqualified()) is Some(_) {
    Err("target \{target.name().unqualified()} is already registered")
  } else if target_registry.contains(key) {
    Err("target \{key} is already registered")
  } else {
    for nick in target.nicknames() {
      if find_target(nick) is Some(_) {
        return Err("target nickname \{nick} is already registered")
      }
    }
    target_registry[key] = target
    Ok(())
  }
}

///|
pub fn Target::register(target : Target) -> Result[Unit, String] {
  register_target(target)
}

///|
pub fn registered_targets() -> Array[Target] {
  let items = []
  target_registry.each((_, target) => items.push(target))
  items
}

///|
pub fn declared_targets() -> Array[Target] {
  let items = common_targets()
  for target in registered_targets() {
    items.push(target)
  }
  items
}

///|
pub fn Target::declared() -> Array[Target] {
  declared_targets()
}

///|
pub fn find_target(query : String) -> Target? {
  match find_in_targets(registered_targets(), query) {
    Some(target) => Some(target)
    None =>
      if target_has_name(Target::unknown(), query) {
        Some(Target::unknown())
      } else {
        find_in_targets(common_targets(), query)
      }
  }
}

///|
pub fn Target::lookup(query : String) -> Target? {
  find_target(query)
}

///|
pub fn get_target(query : String) -> Result[Target, String] {
  match find_target(query) {
    Some(target) => Ok(target)
    None => Err("unknown target \{query}")
  }
}

///|
pub fn Target::get(query : String) -> Result[Target, String] {
  get_target(query)
}

///|
fn target_system_matches(
  actual : System,
  constraint : System,
  strict : Bool,
) -> Bool {
  if strict {
    actual == constraint
  } else {
    constraint == UnknownSystem || actual == constraint
  }
}

///|
fn target_abi_matches(actual : Abi, constraint : Abi, strict : Bool) -> Bool {
  if strict {
    actual == constraint
  } else {
    constraint == UnknownAbi || actual == constraint
  }
}

///|
fn target_fabi_matches(actual : Fabi, constraint : Fabi, strict : Bool) -> Bool {
  if strict {
    actual == constraint
  } else {
    constraint == UnknownFabi || actual == constraint
  }
}

///|
fn target_filetype_matches(
  actual : Filetype,
  constraint : Filetype,
  strict : Bool,
) -> Bool {
  if strict {
    actual == constraint
  } else {
    constraint == UnknownFiletype || actual == constraint
  }
}

///|
pub fn Target::filter(
  parent? : Target,
  system? : System,
  abi? : Abi,
  fabi? : Fabi,
  filetype? : Filetype,
  options? : TargetOptions,
  strict? : Bool = false,
) -> Array[Target] {
  let parent = match parent {
    Some(target) => target
    None => Target::unknown()
  }
  let system = match system {
    Some(value) => value
    None => UnknownSystem
  }
  let abi = match abi {
    Some(value) => value
    None => UnknownAbi
  }
  let fabi = match fabi {
    Some(value) => value
    None => UnknownFabi
  }
  let filetype = match filetype {
    Some(value) => value
    None => UnknownFiletype
  }
  let options = match options {
    Some(value) => value
    None => TargetOptions::empty()
  }
  target_family(parent).filter(target => {
    target_system_matches(target.system(), system, strict) &&
    target_abi_matches(target.abi(), abi, strict) &&
    target_fabi_matches(target.fabi(), fabi, strict) &&
    target_filetype_matches(target.filetype(), filetype, strict) &&
    target.options().matches(options, strict~)
  })
}

///|
pub fn Target::select(
  parent? : Target,
  system? : System,
  abi? : Abi,
  fabi? : Fabi,
  filetype? : Filetype,
  options? : TargetOptions,
  strict? : Bool = false,
  unique? : Bool = false,
) -> Result[Target, String] {
  let matches = Target::filter(
    parent?,
    system?,
    abi?,
    fabi?,
    filetype?,
    options?,
    strict~,
  )
  match matches {
    [] => Err("Target.select - no matching target")
    [target] => Ok(target)
    [target, ..] =>
      if unique {
        Err("Target.select - more than one target matches the constraints")
      } else {
        Ok(target)
      }
  }
}

///|
fn target_system_component(system : System) -> String {
  match system {
    UnknownSystem => ""
    _ => system.to_string()
  }
}

///|
fn target_abi_component(abi : Abi) -> String {
  match abi {
    UnknownAbi => ""
    _ => abi.to_string()
  }
}

///|
fn target_fabi_component(fabi : Fabi) -> String {
  match fabi {
    UnknownFabi => ""
    _ => fabi.to_string()
  }
}

///|
fn target_filetype_component(filetype : Filetype) -> String {
  match filetype {
    UnknownFiletype => ""
    _ => filetype.to_string()
  }
}

///|
fn target_variant_name(
  parent : Target,
  system : System,
  abi : Abi,
  fabi : Fabi,
  filetype : Filetype,
  options : TargetOptions,
) -> String {
  let parts = []
  let system_part = target_system_component(system)
  if system_part != "" {
    parts.push(system_part)
  }
  let abi_part = target_abi_component(abi) + target_fabi_component(fabi)
  if abi_part != "" {
    parts.push(abi_part)
  }
  let filetype_part = target_filetype_component(filetype)
  if filetype_part != "" {
    parts.push(filetype_part)
  }
  let fields = if parts.is_empty() { "" } else { "-\{parts.join("-")}" }
  parent.name().unqualified() + fields + options.to_string()
}

///|
fn target_variant_is_empty(
  system : System,
  abi : Abi,
  fabi : Fabi,
  filetype : Filetype,
  options : TargetOptions,
) -> Bool {
  system == UnknownSystem &&
  abi == UnknownAbi &&
  fabi == UnknownFabi &&
  filetype == UnknownFiletype &&
  options.is_empty()
}

///|
fn target_variant(
  parent : Target,
  system : System,
  abi : Abi,
  fabi : Fabi,
  filetype : Filetype,
  options : TargetOptions,
) -> Target {
  Target::create(
    name=@knowledge.Name::create(
      target_variant_name(parent, system, abi, fabi, filetype, options),
      pkg=parent.name().pkg(),
    ),
    parent~,
    system~,
    abi~,
    fabi~,
    filetype~,
    options~,
  )
}

///|
pub fn Target::register_variants(
  parent : Target,
  systems? : Array[System],
  abis? : Array[Abi],
  fabis? : Array[Fabi],
  filetypes? : Array[Filetype],
  options? : Array[TargetOptions],
) -> Result[Array[Target], String] {
  let systems = match systems {
    Some(values) => values
    None => [UnknownSystem]
  }
  let abis = match abis {
    Some(values) => values
    None => [UnknownAbi]
  }
  let fabis = match fabis {
    Some(values) => values
    None => [UnknownFabi]
  }
  let filetypes = match filetypes {
    Some(values) => values
    None => [UnknownFiletype]
  }
  let options = match options {
    Some(values) => values
    None => [TargetOptions::empty()]
  }
  let created = []
  for system in systems {
    for abi in abis {
      for fabi in fabis {
        for filetype in filetypes {
          for opts in options {
            if !target_variant_is_empty(system, abi, fabi, filetype, opts) {
              let target = target_variant(
                parent, system, abi, fabi, filetype, opts,
              )
              match register_target(target) {
                Ok(_) => created.push(target)
                Err(reason) => return Err(reason)
              }
            }
          }
        }
      }
    }
  }
  Ok(created)
}

///|
fn target_family_compare(left : Target, right : Target) -> Int {
  if left.name().show() == right.name().show() {
    0
  } else if left.belongs(right) {
    1
  } else if right.belongs(left) {
    -1
  } else {
    left.name().unqualified().compare(right.name().unqualified())
  }
}

///|
fn sort_target_family(targets : Array[Target]) -> Array[Target] {
  let result = targets.copy()
  result.sort_by(target_family_compare)
  result
}

///|
fn target_array_contains(targets : Array[Target], target : Target) -> Bool {
  targets.any(item => item.name().show() == target.name().show())
}

///|
fn grandest_target_in(target : Target, universe : Array[Target]) -> Target {
  for parent in target.parents() {
    if target_array_contains(universe, parent) {
      return parent
    }
  }
  target
}

///|
fn target_partition_compare(left : Array[Target], right : Array[Target]) -> Int {
  match (left.get(0), right.get(0)) {
    (Some(lhs), Some(rhs)) =>
      lhs.name().unqualified().compare(rhs.name().unqualified())
    (Some(_), None) => -1
    (None, Some(_)) => 1
    (None, None) => 0
  }
}

///|
pub fn Target::family(parent : Target) -> Array[Target] {
  sort_target_family(
    declared_targets().filter(target => target.belongs(parent)),
  )
}

///|
pub fn Target::partition(targets : Array[Target]) -> Array[Array[Target]] {
  let groups : Array[(Target, Array[Target])] = []
  for target in targets {
    let root = grandest_target_in(target, targets)
    match
      groups.search_by(group => group.0.name().show() == root.name().show()) {
      Some(index) => groups[index].1.push(target)
      None => groups.push((root, [target]))
    }
  }
  let result = [ for group in groups => sort_target_family(group.1) ]
  result.sort_by(target_partition_compare)
  result
}

///|
pub fn target_family(parent : Target) -> Array[Target] {
  Target::family(parent)
}

///|
pub fn target_families() -> Array[Array[Target]] {
  Target::partition(declared_targets())
}

///|
pub fn Target::families() -> Array[Array[Target]] {
  target_families()
}
