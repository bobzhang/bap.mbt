///|
/// The Mach-O header (`mach_header` / `mach_header_64`).
pub(all) struct Header {
  /// true for `MH_MAGIC_64` files
  is64 : Bool
  /// the byte order of the file
  endian : @bitvec.Endian
  cputype : Int32
  /// the CPU subtype with its capability bits
  cpusubtype : Int32
  filetype : Int32
  ncmds : Int32
  sizeofcmds : Int32
  flags : UInt32
} derive(Eq, Debug)

///|
/// A section of a segment command (`section` / `section_64`).
pub(all) struct Section {
  sectname : String
  segname : String
  addr : UInt64
  size : UInt64
  offset : UInt32
  align : UInt32
  reloff : UInt32
  nreloc : UInt32
  flags : UInt32
  reserved1 : UInt32
  reserved2 : UInt32
} derive(Eq, Debug)

///|
/// A segment command (`LC_SEGMENT` / `LC_SEGMENT_64`) with its sections.
pub(all) struct Segment {
  segname : String
  vmaddr : UInt64
  vmsize : UInt64
  fileoff : UInt64
  filesize : UInt64
  maxprot : Int32
  initprot : Int32
  flags : UInt32
  sections : Array[Section]
} derive(Eq, Debug)

///|
/// The symbol table command (`LC_SYMTAB`).
pub(all) struct Symtab {
  symoff : UInt32
  nsyms : UInt32
  stroff : UInt32
  strsize : UInt32
} derive(Eq, Debug)

///|
/// The dynamic symbol table command (`LC_DYSYMTAB`).
pub(all) struct Dysymtab {
  ilocalsym : UInt32
  nlocalsym : UInt32
  iextdefsym : UInt32
  nextdefsym : UInt32
  iundefsym : UInt32
  nundefsym : UInt32
  tocoff : UInt32
  ntoc : UInt32
  modtaboff : UInt32
  nmodtab : UInt32
  extrefsymoff : UInt32
  nextrefsyms : UInt32
  indirectsymoff : UInt32
  nindirectsyms : UInt32
  extreloff : UInt32
  nextrel : UInt32
  locreloff : UInt32
  nlocrel : UInt32
} derive(Eq, Debug)

///|
/// A dynamic library command (`LC_LOAD_DYLIB`, `LC_ID_DYLIB`, ...).
pub(all) struct Dylib {
  /// the load command (`LC_LOAD_DYLIB`, `LC_LOAD_WEAK_DYLIB`, ...)
  cmd : UInt32
  name : String
  timestamp : UInt32
  current_version : UInt32
  compatibility_version : UInt32
} derive(Eq, Debug)

///|
/// A load command.
pub(all) enum LoadCommand {
  /// `LC_SEGMENT` or `LC_SEGMENT_64`
  SegmentCommand(Segment)
  /// `LC_SYMTAB`
  SymtabCommand(Symtab)
  /// `LC_DYSYMTAB`
  DysymtabCommand(Dysymtab)
  /// `LC_MAIN`: the file (`__TEXT`) offset of the entry point
  MainCommand(entryoff~ : UInt64, stacksize~ : UInt64)
  /// `LC_THREAD` or `LC_UNIXTHREAD`: the thread states (flavor, state
  /// words as raw bytes)
  ThreadCommand(cmd~ : UInt32, states~ : Array[(UInt32, Bytes)])
  /// a dylib command
  DylibCommand(Dylib)
  /// `LC_LOAD_DYLINKER`
  DylinkerCommand(String)
  /// `LC_UUID`
  UuidCommand(Bytes)
  /// `LC_FUNCTION_STARTS` (a `linkedit_data_command`)
  FunctionStartsCommand(dataoff~ : UInt32, datasize~ : UInt32)
  /// any other command with its raw contents (after `cmd` and `cmdsize`)
  OtherCommand(cmd~ : UInt32, Bytes)
} derive(Eq, Debug)

///|
/// A symbol table entry (`nlist` / `nlist_64`) with its name.
pub(all) struct Nlist {
  /// the index of the entry in the symbol table
  index : Int32
  name : String
  n_type : Int32
  /// the one-based section number (`NO_SECT` = 0)
  n_sect : Int32
  n_desc : Int32
  n_value : UInt64
} derive(Eq, Debug)

///|
/// A relocation entry (`relocation_info`); scattered relocations keep
/// their raw words.
pub(all) struct Relocation {
  r_word0 : UInt32
  r_word1 : UInt32
  r_address : Int32
  /// a symbol table index if `r_extern`, a section number otherwise
  r_symbolnum : Int32
  r_pcrel : Bool
  r_length : Int32
  r_extern : Bool
  r_type : Int32
  r_scattered : Bool
} derive(Eq, Debug)

///|
/// A parsed (thin) Mach-O file.
pub(all) struct MachO {
  header : Header
  commands : Array[LoadCommand]
} derive(Eq, Debug)

///|
/// An architecture (slice) of a universal binary (`fat_arch` /
/// `fat_arch_64`).
pub(all) struct FatArch {
  cputype : Int32
  cpusubtype : Int32
  offset : UInt64
  size : UInt64
  align : UInt32
} derive(Eq, Debug)

///|
pub extend Header with Eq::{equal, not_equal}

///|
pub extend Header with Debug::{to_repr}

///|
pub extend Section with Eq::{equal, not_equal}

///|
pub extend Section with Debug::{to_repr}

///|
pub extend Segment with Eq::{equal, not_equal}

///|
pub extend Segment with Debug::{to_repr}

///|
pub extend Symtab with Eq::{equal, not_equal}

///|
pub extend Symtab with Debug::{to_repr}

///|
pub extend Dysymtab with Eq::{equal, not_equal}

///|
pub extend Dysymtab with Debug::{to_repr}

///|
pub extend Dylib with Eq::{equal, not_equal}

///|
pub extend Dylib with Debug::{to_repr}

///|
pub extend LoadCommand with Eq::{equal, not_equal}

///|
pub extend LoadCommand with Debug::{to_repr}

///|
pub extend Nlist with Eq::{equal, not_equal}

///|
pub extend Nlist with Debug::{to_repr}

///|
pub extend Relocation with Eq::{equal, not_equal}

///|
pub extend Relocation with Debug::{to_repr}

///|
pub extend MachO with Eq::{equal, not_equal}

///|
pub extend MachO with Debug::{to_repr}

///|
pub extend FatArch with Eq::{equal, not_equal}

///|
pub extend FatArch with Debug::{to_repr}
