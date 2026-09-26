///|
/// The COFF file header (`IMAGE_FILE_HEADER`).
pub(all) struct FileHeader {
  machine : Int
  number_of_sections : Int
  time_date_stamp : UInt
  pointer_to_symbol_table : UInt
  number_of_symbols : UInt
  size_of_optional_header : Int
  characteristics : Int
} derive(Eq, Debug)

///|
/// A data directory of the optional header (`IMAGE_DATA_DIRECTORY`).
pub(all) struct DataDirectory {
  virtual_address : UInt
  size : UInt
} derive(Eq, Debug)

///|
/// The PE optional header (`IMAGE_OPTIONAL_HEADER32` / `64`).
pub(all) struct OptionalHeader {
  /// `0x10b` (PE32) or `0x20b` (PE32+)
  magic : Int
  major_linker_version : Int
  minor_linker_version : Int
  size_of_code : UInt
  size_of_initialized_data : UInt
  size_of_uninitialized_data : UInt
  address_of_entry_point : UInt
  base_of_code : UInt
  /// PE32 only (zero in PE32+)
  base_of_data : UInt
  image_base : UInt64
  section_alignment : UInt
  file_alignment : UInt
  major_operating_system_version : Int
  minor_operating_system_version : Int
  major_image_version : Int
  minor_image_version : Int
  major_subsystem_version : Int
  minor_subsystem_version : Int
  win32_version_value : UInt
  size_of_image : UInt
  size_of_headers : UInt
  checksum : UInt
  subsystem : Int
  dll_characteristics : Int
  size_of_stack_reserve : UInt64
  size_of_stack_commit : UInt64
  size_of_heap_reserve : UInt64
  size_of_heap_commit : UInt64
  loader_flags : UInt
  number_of_rva_and_sizes : UInt
  data_directories : Array[DataDirectory]
} derive(Eq, Debug)

///|
/// A section header (`IMAGE_SECTION_HEADER`); `name` is the raw 8-byte
/// name (see `section_name` for long names of object files).
pub(all) struct SectionHeader {
  name : String
  virtual_size : UInt
  virtual_address : UInt
  size_of_raw_data : UInt
  pointer_to_raw_data : UInt
  pointer_to_relocations : UInt
  pointer_to_linenumbers : UInt
  number_of_relocations : Int
  number_of_linenumbers : Int
  characteristics : UInt
} derive(Eq, Debug)

///|
/// A symbol table record (`IMAGE_SYMBOL`); auxiliary records are skipped
/// and counted in `number_of_aux_symbols`.
pub(all) struct Symbol {
  /// the index of the record in the symbol table
  index : Int
  name : String
  value : UInt
  /// one-based section number, or `IMAGE_SYM_UNDEFINED` (0),
  /// `IMAGE_SYM_ABSOLUTE` (-1), `IMAGE_SYM_DEBUG` (-2)
  section_number : Int
  typ : Int
  storage_class : Int
  number_of_aux_symbols : Int
} derive(Eq, Debug)

///|
/// A relocation of a section (`IMAGE_RELOCATION`).
pub(all) struct Relocation {
  virtual_address : UInt
  symbol_table_index : UInt
  typ : Int
} derive(Eq, Debug)

///|
/// An imported function: by name (with its hint) or by ordinal.
pub(all) struct ImportEntry {
  name : String?
  ordinal : Int?
  hint : Int
  /// the RVA of the import address table slot of the function
  iat_rva : UInt
} derive(Eq, Debug)

///|
/// An import directory entry (`IMAGE_IMPORT_DESCRIPTOR`) with its
/// functions.
pub(all) struct Import {
  dll : String
  lookup_table_rva : UInt
  address_table_rva : UInt
  entries : Array[ImportEntry]
} derive(Eq, Debug)

///|
/// An exported function (an entry of the export address table).
pub(all) struct Export {
  /// the name, if the function is exported by name
  name : String?
  /// the biased ordinal (`ordinal_base` + index)
  ordinal : UInt
  rva : UInt
  /// the forwarder string, if the RVA points into the export directory
  forwarder : String?
} derive(Eq, Debug)

///|
/// The export directory (`IMAGE_EXPORT_DIRECTORY`) with its functions.
pub(all) struct Exports {
  dll : String
  ordinal_base : UInt
  exports : Array[Export]
} derive(Eq, Debug)

///|
/// A parsed PE image or COFF object file.
pub(all) struct Coff {
  /// the offset of the PE signature (`e_lfanew`), for PE images
  pe_offset : Int?
  header : FileHeader
  optional_header : OptionalHeader?
  sections : Array[SectionHeader]
} derive(Eq, Debug)

///|
pub extend FileHeader with Eq::{equal, not_equal}

///|
pub extend FileHeader with Debug::{to_repr}

///|
pub extend DataDirectory with Eq::{equal, not_equal}

///|
pub extend DataDirectory with Debug::{to_repr}

///|
pub extend OptionalHeader with Eq::{equal, not_equal}

///|
pub extend OptionalHeader with Debug::{to_repr}

///|
pub extend SectionHeader with Eq::{equal, not_equal}

///|
pub extend SectionHeader with Debug::{to_repr}

///|
pub extend Symbol with Eq::{equal, not_equal}

///|
pub extend Symbol with Debug::{to_repr}

///|
pub extend Relocation with Eq::{equal, not_equal}

///|
pub extend Relocation with Debug::{to_repr}

///|
pub extend ImportEntry with Eq::{equal, not_equal}

///|
pub extend ImportEntry with Debug::{to_repr}

///|
pub extend Import with Eq::{equal, not_equal}

///|
pub extend Import with Debug::{to_repr}

///|
pub extend Export with Eq::{equal, not_equal}

///|
pub extend Export with Debug::{to_repr}

///|
pub extend Exports with Eq::{equal, not_equal}

///|
pub extend Exports with Debug::{to_repr}

///|
pub extend Coff with Eq::{equal, not_equal}

///|
pub extend Coff with Debug::{to_repr}
