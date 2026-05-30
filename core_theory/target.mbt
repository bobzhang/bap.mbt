///|
pub(all) enum Endianness {
  LittleEndian
  BigEndian
  BiEndian
} derive(Eq, Debug)

///|
pub(all) enum System {
  UnknownSystem
  Linux
  Darwin
  Windows
} derive(Eq, Debug)

///|
pub(all) enum Abi {
  UnknownAbi
  SysV
  GNU
  EABI
  MSVC
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
  PE
  Raw
} derive(Eq, Debug)

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
    Linux => "linux"
    Darwin => "darwin"
    Windows => "windows"
  }
}

///|
pub fn System::of_string(text : String) -> System? {
  match text.to_lower() {
    "unknown" => Some(UnknownSystem)
    "linux" | "gnu/linux" => Some(Linux)
    "darwin" | "macos" | "macosx" => Some(Darwin)
    "windows" | "win32" | "win64" => Some(Windows)
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
    MSVC => "msvc"
  }
}

///|
pub fn Abi::of_string(text : String) -> Abi? {
  match text.to_lower() {
    "unknown" => Some(UnknownAbi)
    "sysv" | "sys-v" | "system-v" => Some(SysV)
    "gnu" => Some(GNU)
    "eabi" => Some(EABI)
    "msvc" | "ms" => Some(MSVC)
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
    PE => "pe"
    Raw => "raw"
  }
}

///|
pub fn Filetype::of_string(text : String) -> Filetype? {
  match text.to_lower() {
    "unknown" => Some(UnknownFiletype)
    "elf" => Some(Elf)
    "macho" | "mach-o" | "mach_o" => Some(MachO)
    "pe" | "coff" | "pecoff" | "pe-coff" => Some(PE)
    "raw" | "bin" | "binary" => Some(Raw)
    _ => None
  }
}

///|
pub(all) enum Role {
  General
  StackPointer
  FramePointer
  ProgramCounter
  Status
  Argument
  ResultRegister
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
    bool_var("CF"),
    bool_var("PF"),
    bool_var("AF"),
    bool_var("ZF"),
    bool_var("SF"),
    bool_var("OF"),
  ]
}

///|
fn x86_32_vars() -> Array[Var] {
  let items = named_word_vars(32, [
    "EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP", "EIP", "EFLAGS",
  ])
  append_vars(items, named_word_vars(16, ["CS", "DS", "ES", "SS", "FS", "GS"]))
  append_vars(items, x86_flags())
  items.push(mem_var(32, 8, "mem"))
  items
}

///|
fn x86_64_vars() -> Array[Var] {
  let items = named_word_vars(64, [
    "RAX", "RBX", "RCX", "RDX", "RSI", "RDI", "RBP", "RSP", "RIP", "R8", "R9", "R10",
    "R11", "R12", "R13", "R14", "R15",
  ])
  append_vars(items, named_word_vars(16, ["CS", "DS", "ES", "SS", "FS", "GS"]))
  append_vars(items, x86_flags())
  items.push(mem_var(64, 8, "mem"))
  items
}

///|
fn arm32_vars() -> Array[Var] {
  let items = numbered_word_vars(32, "R", 16)
  append_vars(items, named_word_vars(32, ["SP", "LR", "PC", "CPSR"]))
  items.push(mem_var(32, 8, "mem"))
  items
}

///|
fn aarch64_vars() -> Array[Var] {
  let items = numbered_word_vars(64, "X", 31)
  append_vars(items, named_word_vars(64, ["SP", "PC"]))
  items.push(word_var(32, "NZCV"))
  items.push(mem_var(64, 8, "mem"))
  items
}

///|
fn mips_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "R", 32)
  append_vars(items, named_word_vars(bits, ["HI", "LO", "PC", "SP", "RA"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn sparc_vars(bits : Int) -> Array[Var] {
  let items = []
  for prefix in ["G", "O", "L", "I"] {
    append_vars(items, numbered_word_vars(bits, prefix, 8))
  }
  append_vars(items, named_word_vars(bits, ["PC", "NPC", "SP"]))
  items.push(mem_var(bits, 8, "mem"))
  items
}

///|
fn ppc_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "R", 32)
  append_vars(items, named_word_vars(bits, ["LR", "CTR", "PC", "SP"]))
  items.push(mem_var(bits, 8, "mem"))
  items
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
fn riscv_vars(bits : Int) -> Array[Var] {
  let items = numbered_word_vars(bits, "X", 32)
  append_vars(items, named_word_vars(bits, ["PC", "SP", "RA"]))
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
    StackPointer => ["sp", "esp", "rsp", "r13", "x31"]
    FramePointer => ["fp", "ebp", "rbp", "r11", "x8"]
    ProgramCounter => ["pc", "eip", "rip"]
    Status =>
      ["flags", "eflags", "cpsr", "nzcv", "cf", "pf", "af", "zf", "sf", "of"]
    Argument =>
      [
        "r0", "r1", "r2", "r3", "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "rdi",
        "rsi", "rdx", "rcx", "r8", "r9",
      ]
    ResultRegister => ["r0", "x0", "eax", "rax"]
  }
}

///|
fn name_has_role(name : String, role : Role) -> Bool {
  let lower = name.to_lower()
  target_role_names(role).contains(lower)
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
pub fn Target::with_alias_origin(self : Target, origin : AliasOrigin) -> Target {
  let items = self.alias_origins_value.copy()
  items.push(origin)
  { ..self, alias_origins_value: items }
}

///|
pub fn Target::find_var(self : Target, name : String) -> Var? {
  self.vars_value
  .search_by(item => item.ident() == name || item.name() == name)
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
pub fn Target::roles_of_var(_self : Target, variable : Var) -> Array[Role] {
  let roles = []
  for
    role in [
      StackPointer,
      FramePointer,
      ProgramCounter,
      Status,
      Argument,
      ResultRegister,
    ] {
    if name_has_role(variable.ident(), role) ||
      name_has_role(variable.name(), role) {
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
pub fn Target::role_aliases(_self : Target, role : Role) -> Array[String] {
  target_role_names(role)
}

///|
pub fn Target::data_addr_size(self : Target) -> Int {
  self.bits_value
}

///|
pub fn Target::code_addr_size(self : Target) -> Int {
  self.bits_value
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
    nicknames=[
      "x86-32", "x86_32", "ia32", "ia-32", "i186", "i286", "i386", "i486", "i586",
      "i686",
    ],
    bits=32,
    endianness=LittleEndian,
    vars=x86_32_vars(),
  )
}

///|
pub fn Target::x86_64() -> Target {
  Target::create(
    name=target_name("x86_64"),
    parent=Target::x86(),
    nicknames=["x86-64", "amd64", "x64", "x86_64h"],
    bits=64,
    endianness=LittleEndian,
    vars=x86_64_vars(),
  )
}

///|
pub fn Target::arm() -> Target {
  Target::create(
    name=target_name("arm"),
    nicknames=["aarch32", "armv4", "armv5", "armv6", "armv7", "xscale"],
    bits=32,
    endianness=LittleEndian,
    vars=arm32_vars(),
  )
}

///|
pub fn Target::armeb() -> Target {
  Target::create(
    name=target_name("armeb"),
    parent=Target::arm(),
    nicknames=["armv4eb", "armv5eb", "armv6eb", "armv7eb", "aarch32eb"],
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
    nicknames=["thumbv4", "thumbv5", "thumbv6", "thumbv7"],
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
    nicknames=["thumbv4eb", "thumbv5eb", "thumbv6eb", "thumbv7eb"],
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
    nicknames=["arm64", "armv8"],
    bits=64,
    endianness=LittleEndian,
    vars=aarch64_vars(),
  )
}

///|
pub fn Target::aarch64_be() -> Target {
  Target::create(
    name=target_name("aarch64_be"),
    parent=Target::armeb(),
    nicknames=["arm64eb", "armv8eb"],
    bits=64,
    endianness=BigEndian,
    vars=aarch64_vars(),
  )
}

///|
pub fn Target::mips() -> Target {
  Target::create(
    name=target_name("mips"),
    nicknames=["mips32"],
    bits=32,
    endianness=BigEndian,
    vars=mips_vars(32),
  )
}

///|
pub fn Target::mipsel() -> Target {
  Target::create(
    name=target_name("mipsel"),
    parent=Target::mips(),
    nicknames=["mips32el"],
    bits=32,
    endianness=LittleEndian,
    vars=mips_vars(32),
  )
}

///|
pub fn Target::mips64() -> Target {
  Target::create(
    name=target_name("mips64"),
    parent=Target::mips(),
    bits=64,
    endianness=BigEndian,
    vars=mips_vars(64),
  )
}

///|
pub fn Target::mips64el() -> Target {
  Target::create(
    name=target_name("mips64el"),
    parent=Target::mips64(),
    bits=64,
    endianness=LittleEndian,
    vars=mips_vars(64),
  )
}

///|
pub fn Target::powerpc() -> Target {
  Target::create(
    name=target_name("powerpc"),
    nicknames=["ppc"],
    bits=32,
    endianness=BigEndian,
    vars=ppc_vars(32),
  )
}

///|
pub fn Target::powerpc64() -> Target {
  Target::create(
    name=target_name("powerpc64"),
    parent=Target::powerpc(),
    nicknames=["ppc64", "ppu"],
    bits=64,
    endianness=BigEndian,
    vars=ppc_vars(64),
  )
}

///|
pub fn Target::powerpc64le() -> Target {
  Target::create(
    name=target_name("powerpc64le"),
    parent=Target::powerpc64(),
    nicknames=["ppc64le"],
    bits=64,
    endianness=LittleEndian,
    vars=ppc_vars(64),
  )
}

///|
pub fn Target::riscv32() -> Target {
  Target::create(
    name=target_name("riscv32"),
    nicknames=["riscv"],
    bits=32,
    endianness=LittleEndian,
    vars=riscv_vars(32),
  )
}

///|
pub fn Target::riscv64() -> Target {
  Target::create(
    name=target_name("riscv64"),
    parent=Target::riscv32(),
    bits=64,
    endianness=LittleEndian,
    vars=riscv_vars(64),
  )
}

///|
pub fn Target::sparc() -> Target {
  Target::create(
    name=target_name("sparc"),
    bits=32,
    endianness=BigEndian,
    vars=sparc_vars(32),
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
    nicknames=["s390x"],
    bits=64,
    endianness=BigEndian,
    vars=systemz_vars(),
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
pub fn common_targets() -> Array[Target] {
  [
    Target::x86(),
    Target::x86_64(),
    Target::arm(),
    Target::armeb(),
    Target::thumb(),
    Target::thumbeb(),
    Target::aarch64(),
    Target::aarch64_be(),
    Target::mips(),
    Target::mipsel(),
    Target::mips64(),
    Target::mips64el(),
    Target::powerpc(),
    Target::powerpc64(),
    Target::powerpc64le(),
    Target::riscv32(),
    Target::riscv64(),
    Target::sparc(),
    Target::sparcv9(),
    Target::nvptx(),
    Target::nvptx64(),
    Target::hexagon(),
    Target::r600(),
    Target::systemz(),
    Target::xcore(),
  ]
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
pub fn get_target(query : String) -> Result[Target, String] {
  match find_target(query) {
    Some(target) => Ok(target)
    None => Err("unknown target \{query}")
  }
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
  target_family(parent).filter(target => {
    target_system_matches(target.system(), system, strict) &&
    target_abi_matches(target.abi(), abi, strict) &&
    target_fabi_matches(target.fabi(), fabi, strict) &&
    target_filetype_matches(target.filetype(), filetype, strict)
  })
}

///|
pub fn Target::select(
  parent? : Target,
  system? : System,
  abi? : Abi,
  fabi? : Fabi,
  filetype? : Filetype,
  strict? : Bool = false,
  unique? : Bool = false,
) -> Result[Target, String] {
  let matches = Target::filter(
    parent?,
    system?,
    abi?,
    fabi?,
    filetype?,
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
pub fn target_family(parent : Target) -> Array[Target] {
  declared_targets().filter(target => target.belongs(parent))
}

///|
pub fn target_families() -> Array[Array[Target]] {
  let families = []
  for target in declared_targets() {
    match target.parent() {
      Some(_) => ()
      None => families.push(target_family(target))
    }
  }
  families
}
