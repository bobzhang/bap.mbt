///|
/// The file class (`EI_CLASS`, upstream `e_class`).
pub(all) enum EClass {
  ELFCLASS32
  ELFCLASS64
} derive(Eq, Compare, Debug)

///|
pub extend EClass with Eq::{equal, not_equal}

///|
pub extend EClass with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend EClass with Debug::{to_repr}

///|
/// The data encoding (`EI_DATA`, upstream `e_data`).
pub(all) enum EData {
  ELFDATA2LSB
  ELFDATA2MSB
} derive(Eq, Compare, Debug)

///|
pub extend EData with Eq::{equal, not_equal}

///|
pub extend EData with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend EData with Debug::{to_repr}

///|
/// The byte order of the encoding.
pub fn EData::endian(self : EData) -> @bitvec.Endian {
  match self {
    ELFDATA2LSB => LittleEndian
    ELFDATA2MSB => BigEndian
  }
}

///|
/// A program header (upstream `segment`), with every field of the file
/// entry.
///
/// Unlike upstream, which widens 32-bit fields with `Int64.of_int32` (and
/// thus sign-extends them), addresses, sizes and offsets are zero-extended
/// unsigned values.
pub(all) struct Segment {
  p_type : PType
  p_flags : Array[PFlag]
  p_vaddr : UInt64
  p_paddr : UInt64
  p_align : UInt64
  p_memsz : UInt64
  p_filesz : UInt64
  p_offset : UInt64
} derive(Eq, Compare, Debug)

///|
pub extend Segment with Eq::{equal, not_equal}

///|
pub extend Segment with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Segment with Debug::{to_repr}

///|
/// A section header (upstream `section`), with every field of the file
/// entry.
pub(all) struct Section {
  sh_name : UInt32
  sh_type : ShType
  sh_flags : Array[ShFlag]
  sh_addr : UInt64
  sh_size : UInt64
  sh_link : UInt32
  sh_info : UInt32
  sh_addralign : UInt64
  sh_entsize : UInt64
  sh_offset : UInt64
} derive(Eq, Compare, Debug)

///|
pub extend Section with Eq::{equal, not_equal}

///|
pub extend Section with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Section with Debug::{to_repr}

///|
/// The location of a header table (upstream `table_info`).
pub(all) struct TableInfo {
  table_offset : UInt64
  entry_size : Int32
  entry_num : Int32
} derive(Eq, Compare, Debug)

///|
pub extend TableInfo with Eq::{equal, not_equal}

///|
pub extend TableInfo with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend TableInfo with Debug::{to_repr}

///|
/// A parsed ELF file (upstream `Elf.t`).
///
/// The first fields are those of upstream `elf`; the file header fields
/// that upstream drops are kept too, so the header is represented
/// losslessly:
/// - `e_file_version` is the header `e_version` word (upstream's
///   `e_version` is the `EI_VERSION` identification byte);
/// - `e_flags` and `e_ehsize` are the processor flags and header size;
/// - `e_phtab` and `e_shtab` are the program and section header tables
///   (upstream `table_info`).
///
/// Extended numbering is resolved: when the header counts overflow
/// (`e_phnum == PN_XNUM`, `e_shnum == 0`, `e_shstrndx == SHN_XINDEX`), the
/// counts and `e_shstrndx` come from section header 0, and the table
/// infos hold the resolved counts.
pub(all) struct Elf {
  e_class : EClass
  e_data : EData
  e_version : Int32
  e_osabi : EOsabi
  e_abiver : Int32
  e_type : EType
  e_machine : EMachine
  e_entry : UInt64
  e_shstrndx : Int32
  e_sections : Array[Section]
  e_segments : Array[Segment]
  e_file_version : UInt32
  e_flags : UInt32
  e_ehsize : Int32
  e_phtab : TableInfo
  e_shtab : TableInfo
} derive(Eq, Compare, Debug)

///|
pub extend Elf with Eq::{equal, not_equal}

///|
pub extend Elf with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Elf with Debug::{to_repr}

///|
/// The byte order of the file.
pub fn Elf::endian(self : Elf) -> @bitvec.Endian {
  self.e_data.endian()
}

///|
/// The address size of the file in bits.
pub fn Elf::bits(self : Elf) -> Int32 {
  match self.e_class {
    ELFCLASS32 => 32
    ELFCLASS64 => 64
  }
}

///|
/// Decodes a flag word into its set bits (upstream `parse_flags`): the
/// flags are listed from the highest set bit to the lowest, as upstream
/// does.
fn[F] flags_of_bits(
  flag_of : (Int32) -> F,
  width : Int32,
  bits : UInt64,
) -> Array[F] {
  let flags = []
  for n = width - 1; n >= 0; n = n - 1 {
    if ((bits >> n) & 1UL) == 1UL {
      flags.push(flag_of(n))
    }
  }
  flags
}

///|
fn[F] bits_of_flags(to_bit : (F) -> Int32, flags : Array[F]) -> UInt64 {
  flags.fold(init=0UL, (bits, flag) => bits | (1UL << to_bit(flag)))
}

///|
/// The program flags word of a list of flags.
pub fn PFlag::to_bits(flags : Array[PFlag]) -> UInt32 {
  bits_of_flags(PFlag::to_int, flags).to_uint()
}

///|
/// Decodes a `p_flags` word.
pub fn PFlag::of_bits(bits : UInt32) -> Array[PFlag] {
  flags_of_bits(PFlag::of_int, 32, bits.to_uint64())
}

///|
/// The section flags word of a list of flags.
pub fn ShFlag::to_bits(flags : Array[ShFlag]) -> UInt64 {
  bits_of_flags(ShFlag::to_int, flags)
}

///|
/// Decodes an `sh_flags` word of the given width (32 or 64 bits).
pub fn ShFlag::of_bits(bits : UInt64, width~ : Int32 = 64) -> Array[ShFlag] {
  flags_of_bits(ShFlag::of_int, width, bits)
}

///|
/// The raw flags word of the program header.
pub fn Segment::flags_bits(self : Segment) -> UInt32 {
  PFlag::to_bits(self.p_flags)
}

///|
pub fn Segment::is_readable(self : Segment) -> Bool {
  self.p_flags.contains(PF_R)
}

///|
pub fn Segment::is_writable(self : Segment) -> Bool {
  self.p_flags.contains(PF_W)
}

///|
pub fn Segment::is_executable(self : Segment) -> Bool {
  self.p_flags.contains(PF_X)
}

///|
/// The raw flags word of the section header.
pub fn Section::flags_bits(self : Section) -> UInt64 {
  ShFlag::to_bits(self.sh_flags)
}

///|
/// Whether the section occupies memory during execution (`SHF_ALLOC`).
pub fn Section::is_alloc(self : Section) -> Bool {
  self.sh_flags.contains(SHF_ALLOC)
}

///|
pub fn Section::is_writable(self : Section) -> Bool {
  self.sh_flags.contains(SHF_WRITE)
}

///|
pub fn Section::is_executable(self : Section) -> Bool {
  self.sh_flags.contains(SHF_EXECINSTR)
}
