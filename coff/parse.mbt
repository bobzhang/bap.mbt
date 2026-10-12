///|
/// A malformed PE/COFF input; public entry points report it as
/// `Err(message)`.
priv suberror Malformed {
  Malformed(String)
}

///|
fn[T] catch_malformed(f : () -> T raise Malformed) -> Result[T, String] {
  try f() catch {
    Malformed(reason) => Err(reason)
  } noraise {
    x => Ok(x)
  }
}

///|
fn check(
  data : BytesView,
  offset : Int32,
  bytes : Int32,
  what : String,
) -> Unit raise Malformed {
  if offset < 0 || bytes < 0 || offset > data.length() - bytes {
    raise Malformed("\{what} is out of bounds")
  }
}

///|
/// A little-endian unsigned integer of `bytes` bytes at `offset`.
fn read(
  data : BytesView,
  offset : Int32,
  bytes : Int32,
) -> UInt64 raise Malformed {
  check(data, offset, bytes, "PE/COFF field")
  let mut value = 0UL
  for i in 0..<bytes {
    value = value | (data[offset + i].to_uint64() << (i * 8))
  }
  value
}

///|
fn u8(data : BytesView, offset : Int32) -> Int32 raise Malformed {
  read(data, offset, 1).to_int()
}

///|
fn u16(data : BytesView, offset : Int32) -> Int32 raise Malformed {
  read(data, offset, 2).to_int()
}

///|
fn u32(data : BytesView, offset : Int32) -> UInt32 raise Malformed {
  read(data, offset, 4).to_uint()
}

///|
fn u64(data : BytesView, offset : Int32) -> UInt64 raise Malformed {
  read(data, offset, 8)
}

///|
fn decode_name(bytes : BytesView) -> String {
  @utf8.decode(bytes) catch {
    _ =>
      String::from_array(bytes.to_array().map(b => b.to_int().unsafe_to_char()))
  }
}

///|
/// A null-padded name of at most `size` bytes.
fn fixed_name(
  data : BytesView,
  offset : Int32,
  size : Int32,
) -> String raise Malformed {
  check(data, offset, size, "PE/COFF name")
  let mut stop = offset
  while stop < offset + size && data[stop] != b'\x00' {
    stop = stop + 1
  }
  decode_name(data[offset:stop])
}

///|
/// A null-terminated string at `offset`.
fn cstring(data : BytesView, offset : Int32) -> String raise Malformed {
  if offset < 0 || offset >= data.length() {
    raise Malformed("PE/COFF string offset is out of bounds")
  }
  let mut stop = offset
  while stop < data.length() && data[stop] != b'\x00' {
    stop = stop + 1
  }
  decode_name(data[offset:stop])
}

///|
/// The offset of the PE signature (`e_lfanew`) if `data` is a PE image:
/// an `MZ` DOS header whose `e_lfanew` points at `PE\0\0`.
fn pe_signature(data : BytesView) -> Int32? {
  if data.length() < 0x40 || data[0] != b'M' || data[1] != b'Z' {
    return None
  }
  let off = (u32(data, 0x3c) catch { _ => return None }).reinterpret_as_int()
  if off < 0 || off > data.length() - 24 {
    return None
  }
  if data[off] == b'P' &&
    data[off + 1] == b'E' &&
    data[off + 2] == b'\x00' &&
    data[off + 3] == b'\x00' {
    Some(off)
  } else {
    None
  }
}

///|
/// Whether `data` is a PE image (`MZ` ... `PE\0\0`).
pub fn is_pe(data : BytesView) -> Bool {
  pe_signature(data) is Some(_)
}

///|
/// The machines whose COFF object files are recognized by their first
/// bytes (as `llvm::identify_magic` does).
fn is_object_machine(machine : Int32) -> Bool {
  match machine {
    IMAGE_FILE_MACHINE_I386
    | IMAGE_FILE_MACHINE_AMD64
    | IMAGE_FILE_MACHINE_ARM
    | IMAGE_FILE_MACHINE_THUMB
    | IMAGE_FILE_MACHINE_ARMNT
    | IMAGE_FILE_MACHINE_ARM64
    | IMAGE_FILE_MACHINE_POWERPC
    | IMAGE_FILE_MACHINE_R4000
    | IMAGE_FILE_MACHINE_RISCV64 => true
    _ => false
  }
}

///|
/// Whether `data` is a COFF object file: a known machine and a file header
/// without an optional header whose section table fits the file.
pub fn is_coff_object(data : BytesView) -> Bool {
  if data.length() < 20 {
    return false
  }
  let ok = try {
    let machine = u16(data, 0)
    let nsections = u16(data, 2)
    let optional = u16(data, 16)
    is_object_machine(machine) &&
    optional == 0 &&
    nsections > 0 &&
    20 + nsections * 40 <= data.length()
  } catch {
    _ => false
  }
  ok
}

///|
/// Whether `data` is a PE image or a COFF object file.
pub fn is_coff(data : BytesView) -> Bool {
  is_pe(data) || is_coff_object(data)
}

///|
fn parse_file_header(
  data : BytesView,
  off : Int32,
) -> FileHeader raise Malformed {
  check(data, off, 20, "COFF file header")
  {
    machine: u16(data, off),
    number_of_sections: u16(data, off + 2),
    time_date_stamp: u32(data, off + 4),
    pointer_to_symbol_table: u32(data, off + 8),
    number_of_symbols: u32(data, off + 12),
    size_of_optional_header: u16(data, off + 16),
    characteristics: u16(data, off + 18),
  }
}

///|
fn parse_optional_header(
  data : BytesView,
  off : Int32,
  size : Int32,
) -> OptionalHeader raise Malformed {
  check(data, off, size, "PE optional header")
  let magic = u16(data, off)
  let plus = match magic {
    IMAGE_NT_OPTIONAL_HDR32_MAGIC => false
    IMAGE_NT_OPTIONAL_HDR64_MAGIC => true
    _ => raise Malformed("unknown PE optional header magic \{magic}")
  }
  let fixed = if plus { 112 } else { 96 }
  if size < fixed {
    raise Malformed("PE optional header is too small")
  }
  // the fields after `base_of_code` are shifted by 4 in PE32+ (no
  // `base_of_data`, 8-byte image base) and the four stack/heap sizes are
  // 8 bytes wide
  let word = (o : Int32) => {
    if plus {
      u64(data, off + o)
    } else {
      u32(data, off + o).to_uint64()
    }
  }
  let (image_base, stack) = if plus {
    (u64(data, off + 24), 72)
  } else {
    (u32(data, off + 28).to_uint64(), 72)
  }
  let w = if plus { 8 } else { 4 }
  let after = stack + 4 * w
  let count = u32(data, off + after + 4)
  let directories = []
  let n = count.reinterpret_as_int()
  if n < 0 || n > (size - fixed) / 8 {
    raise Malformed("PE optional header has too many data directories")
  }
  for i in 0..<n {
    let d = off + fixed + i * 8
    directories.push({ virtual_address: u32(data, d), size: u32(data, d + 4), })
  }
  {
    magic,
    major_linker_version: u8(data, off + 2),
    minor_linker_version: u8(data, off + 3),
    size_of_code: u32(data, off + 4),
    size_of_initialized_data: u32(data, off + 8),
    size_of_uninitialized_data: u32(data, off + 12),
    address_of_entry_point: u32(data, off + 16),
    base_of_code: u32(data, off + 20),
    base_of_data: if plus {
      0
    } else {
      u32(data, off + 24)
    },
    image_base,
    section_alignment: u32(data, off + 32),
    file_alignment: u32(data, off + 36),
    major_operating_system_version: u16(data, off + 40),
    minor_operating_system_version: u16(data, off + 42),
    major_image_version: u16(data, off + 44),
    minor_image_version: u16(data, off + 46),
    major_subsystem_version: u16(data, off + 48),
    minor_subsystem_version: u16(data, off + 50),
    win32_version_value: u32(data, off + 52),
    size_of_image: u32(data, off + 56),
    size_of_headers: u32(data, off + 60),
    checksum: u32(data, off + 64),
    subsystem: u16(data, off + 68),
    dll_characteristics: u16(data, off + 70),
    size_of_stack_reserve: word(stack),
    size_of_stack_commit: word(stack + w),
    size_of_heap_reserve: word(stack + 2 * w),
    size_of_heap_commit: word(stack + 3 * w),
    loader_flags: u32(data, off + after),
    number_of_rva_and_sizes: count,
    data_directories: directories,
  }
}

///|
fn parse_section_header(
  data : BytesView,
  off : Int32,
) -> SectionHeader raise Malformed {
  check(data, off, 40, "COFF section header")
  {
    name: fixed_name(data, off, 8),
    virtual_size: u32(data, off + 8),
    virtual_address: u32(data, off + 12),
    size_of_raw_data: u32(data, off + 16),
    pointer_to_raw_data: u32(data, off + 20),
    pointer_to_relocations: u32(data, off + 24),
    pointer_to_linenumbers: u32(data, off + 28),
    number_of_relocations: u16(data, off + 32),
    number_of_linenumbers: u16(data, off + 34),
    characteristics: u32(data, off + 36),
  }
}

///|
fn parse_exn(data : Bytes) -> Coff raise Malformed {
  let pe_offset = pe_signature(data)
  let header_off = match pe_offset {
    Some(off) => off + 4
    None =>
      if is_coff_object(data) {
        0
      } else {
        raise Malformed("not a PE/COFF file")
      }
  }
  let header = parse_file_header(data, header_off)
  let optional_off = header_off + 20
  let optional_header = if header.size_of_optional_header > 0 {
    Some(
      parse_optional_header(data, optional_off, header.size_of_optional_header),
    )
  } else {
    None
  }
  let table = optional_off + header.size_of_optional_header
  let sections = []
  for i in 0..<header.number_of_sections {
    sections.push(parse_section_header(data, table + i * 40))
  }
  { pe_offset, header, optional_header, sections, }
}

///|
/// Parses a PE image (DOS stub, PE signature, file and optional headers,
/// section table) or a COFF object file (upstream
/// `llvm::object::COFFObjectFile`).
pub fn parse(data : Bytes) -> Result[Coff, String] {
  catch_malformed(() => parse_exn(data))
}

///|
/// The preferred load address (`ImageBase`); zero for object files.
pub fn Coff::image_base(self : Coff) -> UInt64 {
  match self.optional_header {
    Some(h) => h.image_base
    None => 0UL
  }
}

///|
/// Whether the file is an executable image (`IMAGE_FILE_EXECUTABLE_IMAGE`).
pub fn Coff::is_executable(self : Coff) -> Bool {
  (self.header.characteristics & IMAGE_FILE_EXECUTABLE_IMAGE) != 0
}

///|
/// Whether the file is a relocatable object (it has no optional header,
/// as `COFFObjectFile::isRelocatableObject`).
pub fn Coff::is_relocatable(self : Coff) -> Bool {
  self.optional_header is None
}

///|
/// Whether the optional header is PE32+ (64-bit).
pub fn Coff::is_pe32_plus(self : Coff) -> Bool {
  self.optional_header is Some({ magic: IMAGE_NT_OPTIONAL_HDR64_MAGIC, .. })
}

///|
/// The number of bytes of an address: 8 for PE32+ and 64-bit object
/// machines, 4 otherwise.
pub fn Coff::bytes_in_address(self : Coff) -> Int32 {
  match self.optional_header {
    Some(h) => if h.magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC { 8 } else { 4 }
    None =>
      match self.header.machine {
        IMAGE_FILE_MACHINE_AMD64 | IMAGE_FILE_MACHINE_ARM64 => 8
        _ => 4
      }
  }
}

///|
/// The data directory `index`, if present and non-empty.
pub fn Coff::data_directory(self : Coff, index : Int32) -> DataDirectory? {
  match self.optional_header {
    Some(h) =>
      match h.data_directories.get(index) {
        Some(d) if d.virtual_address != 0 => Some(d)
        _ => None
      }
    None => None
  }
}

///|
/// The file offset of a relative virtual address, if a section (or the
/// headers) maps it.
pub fn Coff::rva_to_offset(self : Coff, rva : UInt32) -> Int32? {
  for s in self.sections {
    let size = if s.virtual_size > s.size_of_raw_data {
      s.virtual_size
    } else {
      s.size_of_raw_data
    }
    if s.virtual_address <= rva && rva - s.virtual_address < size {
      let delta = rva - s.virtual_address
      if delta < s.size_of_raw_data {
        return Some((s.pointer_to_raw_data + delta).reinterpret_as_int())
      } else {
        return None
      }
    }
  }
  match self.optional_header {
    Some(h) if rva < h.size_of_headers => Some(rva.reinterpret_as_int())
    _ => None
  }
}

///|
/// The section whose virtual range (`VirtualAddress`, `VirtualSize`)
/// contains the RVA.
pub fn Coff::section_of_rva(self : Coff, rva : UInt32) -> SectionHeader? {
  for s in self.sections {
    if s.virtual_address <= rva && rva - s.virtual_address < s.virtual_size {
      return Some(s)
    }
  }
  None
}

///|
/// The offset of the string table (right after the symbol table).
fn Coff::string_table_offset(self : Coff) -> Int32 {
  (self.header.pointer_to_symbol_table + self.header.number_of_symbols * 18).reinterpret_as_int()
}

///|
fn string_table_entry(
  data : Bytes,
  coff : Coff,
  offset : Int32,
) -> String raise Malformed {
  let table = coff.string_table_offset()
  let size = u32(data, table).reinterpret_as_int()
  if offset < 4 || offset >= size {
    raise Malformed("COFF string table offset is out of bounds")
  }
  cstring(data[:table + size], table + offset)
}

///|
/// The name of a section: the raw name, or the string table entry of a
/// `/nnn` long name of an object file.
pub fn section_name(
  data : Bytes,
  coff : Coff,
  section : SectionHeader,
) -> Result[String, String] {
  catch_malformed(() => {
    if section.name is ['/', .. rest] &&
      coff.header.pointer_to_symbol_table != 0 {
      match parse_decimal(rest.to_owned()) {
        Some(n) => string_table_entry(data, coff, n)
        None => section.name
      }
    } else {
      section.name
    }
  })
}

///|
fn parse_decimal(text : String) -> Int32? {
  if text.is_empty() {
    return None
  }
  let mut n = 0
  for c in text {
    if c < '0' || c > '9' || n > 100000000 {
      return None
    }
    n = n * 10 + (c.to_int() - '0'.to_int())
  }
  Some(n)
}

///|
fn symbols_exn(data : Bytes, coff : Coff) -> Array[Symbol] raise Malformed {
  let off = coff.header.pointer_to_symbol_table.reinterpret_as_int()
  let count = coff.header.number_of_symbols.reinterpret_as_int()
  if off == 0 || count == 0 {
    return []
  }
  if off < 0 || count < 0 || count > (data.length() - off) / 18 {
    raise Malformed("COFF symbol table is out of bounds")
  }
  let symbols = []
  let mut i = 0
  while i < count {
    let e = off + i * 18
    let name = if u32(data, e) == 0 {
      string_table_entry(data, coff, u32(data, e + 4).reinterpret_as_int()) catch {
        _ => ""
      }
    } else {
      fixed_name(data, e, 8)
    }
    let section = u16(data, e + 12)
    let aux = u8(data, e + 17)
    symbols.push({
      index: i,
      name,
      value: u32(data, e + 8),
      section_number: if section >= 0x8000 {
        section - 0x10000
      } else {
        section
      },
      typ: u16(data, e + 14),
      storage_class: u8(data, e + 16),
      number_of_aux_symbols: aux,
    })
    i = i + 1 + aux
  }
  symbols
}

///|
/// The symbol table records (without the auxiliary records), with their
/// names.
pub fn symbols(data : Bytes, coff : Coff) -> Result[Array[Symbol], String] {
  catch_malformed(() => symbols_exn(data, coff))
}

///|
/// Whether the symbol is a function definition (as
/// `COFFSymbolRef::isFunctionDefinition`): an external symbol of a
/// function type defined in a section.
pub fn Symbol::is_function_definition(self : Symbol) -> Bool {
  self.storage_class == IMAGE_SYM_CLASS_EXTERNAL &&
  (self.typ & 0xf) == 0 &&
  ((self.typ >> 4) & 0x3) == IMAGE_SYM_DTYPE_FUNCTION &&
  self.section_number > 0
}

///|
/// The relocations of a section (with the `IMAGE_SCN_LNK_NRELOC_OVFL`
/// extended count).
pub fn relocations(
  data : Bytes,
  _coff : Coff,
  section : SectionHeader,
) -> Result[Array[Relocation], String] {
  catch_malformed(() => {
    let mut off = section.pointer_to_relocations.reinterpret_as_int()
    let mut count = section.number_of_relocations
    if count == 0 {
      return []
    }
    if (section.characteristics & IMAGE_SCN_LNK_NRELOC_OVFL) != 0 &&
      count == 0xffff {
      // the first relocation holds the real count (including itself)
      count = u32(data, off).reinterpret_as_int() - 1
      off = off + 10
    }
    if off < 0 || count < 0 || count > (data.length() - off) / 10 {
      raise Malformed("COFF relocation table is out of bounds")
    }
    let relocations : Array[Relocation] = []
    for i in 0..<count {
      relocations.push({
        virtual_address: u32(data, off + i * 10),
        symbol_table_index: u32(data, off + i * 10 + 4),
        typ: u16(data, off + i * 10 + 8),
      })
    }
    relocations
  })
}

///|
fn rva_string(
  data : Bytes,
  coff : Coff,
  rva : UInt32,
) -> String raise Malformed {
  match coff.rva_to_offset(rva) {
    Some(off) => cstring(data, off)
    None => raise Malformed("PE RVA \{rva} is not mapped")
  }
}

///|
fn rva_offset(coff : Coff, rva : UInt32) -> Int32 raise Malformed {
  match coff.rva_to_offset(rva) {
    Some(off) => off
    None => raise Malformed("PE RVA \{rva} is not mapped")
  }
}

///|
/// The largest number of import descriptors or thunks that are read.
let max_table_entries : Int32 = 1 << 20

///|
fn imports_exn(data : Bytes, coff : Coff) -> Array[Import] raise Malformed {
  guard coff.data_directory(IMAGE_DIRECTORY_ENTRY_IMPORT) is Some(dir) else {
    return []
  }
  let base = rva_offset(coff, dir.virtual_address)
  let width = coff.bytes_in_address()
  let imports = []
  for i in 0..<max_table_entries {
    let d = base + i * 20
    let lookup = u32(data, d)
    let name_rva = u32(data, d + 12)
    let iat = u32(data, d + 16)
    if lookup == 0 && name_rva == 0 && iat == 0 {
      break
    }
    let dll = rva_string(data, coff, name_rva)
    let table = if lookup != 0 { lookup } else { iat }
    let toff = rva_offset(coff, table)
    let entries = []
    for j in 0..<max_table_entries {
      let thunk = read(data, toff + j * width, width)
      if thunk == 0UL {
        break
      }
      let slot = iat + (j * width).reinterpret_as_uint()
      let by_ordinal = thunk >> (width * 8 - 1) != 0UL
      if by_ordinal {
        entries.push({
          name: None,
          ordinal: Some((thunk & 0xffffUL).to_int()),
          hint: 0,
          iat_rva: slot,
        })
      } else {
        let hint_rva = (thunk & 0x7fffffffUL).to_uint()
        let hoff = rva_offset(coff, hint_rva)
        entries.push({
          name: Some(cstring(data, hoff + 2)),
          ordinal: None,
          hint: u16(data, hoff),
          iat_rva: slot,
        })
      }
    }
    imports.push({
      dll,
      lookup_table_rva: lookup,
      address_table_rva: iat,
      entries,
    })
  }
  imports
}

///|
/// The import directory: the imported libraries with their functions.
pub fn imports(data : Bytes, coff : Coff) -> Result[Array[Import], String] {
  catch_malformed(() => imports_exn(data, coff))
}

///|
fn exports_exn(data : Bytes, coff : Coff) -> Exports? raise Malformed {
  guard coff.data_directory(IMAGE_DIRECTORY_ENTRY_EXPORT) is Some(dir) else {
    return None
  }
  let d = rva_offset(coff, dir.virtual_address)
  check(data, d, 40, "PE export directory")
  let dll = rva_string(data, coff, u32(data, d + 12)) catch { _ => "" }
  let ordinal_base = u32(data, d + 16)
  let nfunctions = u32(data, d + 20).reinterpret_as_int()
  let nnames = u32(data, d + 24).reinterpret_as_int()
  if nfunctions < 0 ||
    nfunctions > max_table_entries ||
    nnames < 0 ||
    nnames > max_table_entries {
    raise Malformed("PE export directory is too large")
  }
  let functions = if nfunctions == 0 {
    []
  } else {
    let eat = rva_offset(coff, u32(data, d + 28))
    [
      for i in 0..<nfunctions => u32(data, eat + i * 4)
    ]
  }
  let names : Array[String?] = Array::make(nfunctions, None)
  if nnames > 0 {
    let name_table = rva_offset(coff, u32(data, d + 32))
    let ordinals = rva_offset(coff, u32(data, d + 36))
    for j in 0..<nnames {
      let index = u16(data, ordinals + j * 2)
      if index < nfunctions {
        names[index] = Some(
          rva_string(data, coff, u32(data, name_table + j * 4)),
        )
      }
    }
  }
  let low = dir.virtual_address
  let exports = []
  for i, rva in functions {
    if rva == 0 {
      continue
    }
    let forwarder = if rva >= low && rva - low < dir.size {
      Some(rva_string(data, coff, rva))
    } else {
      None
    }
    exports.push({
      name: names[i],
      ordinal: ordinal_base + i.reinterpret_as_uint(),
      rva,
      forwarder,
    })
  }
  Some({ dll, ordinal_base, exports, })
}

///|
/// The export directory, if any: the exported functions with their names,
/// ordinals and RVAs (forwarded exports keep their forwarder strings).
pub fn exports(data : Bytes, coff : Coff) -> Result[Exports?, String] {
  catch_malformed(() => exports_exn(data, coff))
}
