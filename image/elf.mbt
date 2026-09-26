///|
priv enum ImageElfClass {
  ImageElf32
  ImageElf64
}

///|
/// The loader view of the file header, projected from the raw `@elf`
/// header.
priv struct ImageElfHeader {
  endian : @bitvec.Endian
  class : ImageElfClass
  osabi : Int
  typ : Int
  machine : Int
  entry : UInt64
  section_name_index : Int
}

///|
/// Projects a raw program header into the loader view, checking that its
/// file range and sizes fit in `Int`.
fn image_elf_program_header_of_raw(
  segment : @elf.Segment,
) -> Result[ImageElfProgramHeader, String] {
  let offset = match
    image_elf_uint_to_int(segment.p_offset, "ELF segment offset") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let filesz = match
    image_elf_uint_to_int(segment.p_filesz, "ELF segment file size") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let memsz = match
    image_elf_uint_to_int(segment.p_memsz, "ELF segment memory size") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok({
    typ: segment.p_type.to_int().reinterpret_as_int(),
    flags: segment.flags_bits().reinterpret_as_int(),
    offset,
    vaddr: segment.p_vaddr,
    filesz,
    memsz,
  })
}

///|
/// Projects a raw section header into the loader view, checking that its
/// file range and sizes fit in `Int`.
fn image_elf_section_header_of_raw(
  section : @elf.Section,
) -> Result[ImageElfSectionHeader, String] {
  let offset = match
    image_elf_uint_to_int(section.sh_offset, "ELF section offset") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match image_elf_uint_to_int(section.sh_size, "ELF section size") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entsize = match
    image_elf_uint_to_int(section.sh_entsize, "ELF section entry size") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok({
    name_offset: section.sh_name.reinterpret_as_int(),
    typ: section.sh_type.to_int().reinterpret_as_int(),
    flags: section.flags_bits(),
    link: section.sh_link.reinterpret_as_int(),
    addr: section.sh_addr,
    offset,
    size,
    entsize,
  })
}

///|
/// Parses an ELF file with the raw reader and projects it into the loader
/// view (upstream `elf_loader` over `Elf.from_bigstring`), enforcing the
/// loader's stricter requirements: a current file version and a valid
/// section name table index.
fn image_elf_parse(
  data : Bytes,
) -> Result[
  (
    @elf.Elf,
    ImageElfHeader,
    Array[ImageElfProgramHeader],
    Array[ImageElfSectionHeader],
  ),
  String,
] {
  let elf = match @elf.from_bytes(data) {
    Ok(elf) => elf
    Err(reason) => return Err(reason)
  }
  if elf.e_version != 1 {
    return Err("unsupported ELF version")
  }
  let section_count = elf.e_sections.length()
  let has_sections = section_count > 0
  if !has_sections && elf.e_shtab.table_offset != 0UL {
    return Err("ELF section table is invalid")
  }
  if (!has_sections && elf.e_shstrndx != 0) ||
    (has_sections && elf.e_shstrndx >= section_count) {
    return Err("ELF section name table index is out of bounds")
  }
  let header : ImageElfHeader = {
    endian: elf.endian(),
    class: match elf.e_class {
      ELFCLASS32 => ImageElf32
      ELFCLASS64 => ImageElf64
    },
    osabi: elf.e_osabi.to_int(),
    typ: elf.e_type.to_int(),
    machine: elf.e_machine.to_int(),
    entry: elf.e_entry,
    section_name_index: elf.e_shstrndx,
  }
  let programs = []
  for segment in elf.e_segments {
    match image_elf_program_header_of_raw(segment) {
      Ok(program) => programs.push(program)
      Err(reason) => return Err(reason)
    }
  }
  let sections = []
  for section in elf.e_sections {
    match image_elf_section_header_of_raw(section) {
      Ok(header) => sections.push(header)
      Err(reason) => return Err(reason)
    }
  }
  Ok((elf, header, programs, sections))
}

///|
priv struct ImageElfProgramHeader {
  typ : Int
  flags : Int
  offset : Int
  vaddr : UInt64
  filesz : Int
  memsz : Int
}

///|
priv struct ImageElfSectionHeader {
  name_offset : Int
  typ : Int
  flags : UInt64
  link : Int
  addr : UInt64
  offset : Int
  size : Int
  entsize : Int
}

///|
priv struct ImageElfSymbolEntry {
  name : String?
  shndx : Int
  value : UInt64
  size : Int
  info : Int
}

///|
priv struct ImageElfRelocationEntry {
  offset : UInt64
  symbol_index : Int
  typ : Int
  addend : Int64?
  memory_addend : Bool
}

///|
priv struct ImageElfDynamicRelocationTable {
  addr : UInt64?
  size : Int?
  entry_size : Int?
}

///|
priv struct ImageElfDynamicMetadata {
  required_libraries : Array[String]
  rpaths : Array[String]
  runpaths : Array[String]
  soname : String?
}

///|
fn image_elf_read_uint(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[UInt64, String] {
  if offset < 0 || bytes < 0 || offset + bytes > data.length() {
    return Err("truncated ELF input")
  }
  let mut value = 0UL
  for i in 0..<bytes {
    let shift = match endian {
      LittleEndian => i * 8
      BigEndian => (bytes - 1 - i) * 8
    }
    value = value | (data[offset + i].to_int().to_uint64() << shift)
  }
  Ok(value)
}

///|
fn image_elf_uint_to_int(value : UInt64, what : String) -> Result[Int, String] {
  if value > 2147483647UL {
    Err("\{what} does not fit in Int")
  } else {
    Ok(value.to_int())
  }
}

///|
fn image_elf_read_int(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
  what : String,
) -> Result[Int, String] {
  match image_elf_read_uint(data, offset, bytes, endian) {
    Ok(value) => image_elf_uint_to_int(value, what)
    Err(reason) => Err(reason)
  }
}

///|
fn image_elf_read_u64(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[UInt64, String] {
  image_elf_read_uint(data, offset, bytes, endian)
}

///|
fn image_elf_section_data(
  data : Bytes,
  offset : Int,
  size : Int,
) -> Result[Bytes, String] {
  if offset < 0 || size < 0 {
    return Err("ELF section range is invalid")
  }
  let start64 = offset.to_uint64()
  let size64 = size.to_uint64()
  let data_size64 = data.length().to_uint64()
  if start64 > data_size64 || size64 > data_size64 - start64 {
    return Err("ELF section range is out of bounds")
  }
  Ok(data[offset:offset + size].to_owned())
}

///|
fn image_elf_cstring(data : Bytes, offset : Int) -> Result[String, String] {
  if offset < 0 || offset >= data.length() {
    return Err("ELF string offset is out of bounds")
  }
  let mut end = offset
  while end < data.length() && data[end] != b'\x00' {
    end = end + 1
  }
  if end >= data.length() {
    return Err("ELF string is not null-terminated")
  }
  try @utf8.decode(data[offset:end]) catch {
    _ => Err("ELF string is not valid UTF-8")
  } noraise {
    text => Ok(text)
  }
}

///|
fn image_elf_section_name(
  names : Bytes?,
  section : ImageElfSectionHeader,
) -> Result[String?, String] {
  match names {
    Some(names) =>
      match image_elf_cstring(names, section.name_offset) {
        Ok(name) => if name.length() == 0 { Ok(None) } else { Ok(Some(name)) }
        Err(reason) => Err(reason)
      }
    None => Ok(None)
  }
}

///|
fn image_elf_segment_data(
  data : Bytes,
  program : ImageElfProgramHeader,
) -> Result[Bytes, String] {
  if program.offset < 0 || program.filesz < 0 || program.memsz < 0 {
    return Err("ELF segment range is invalid")
  }
  if program.filesz > program.memsz {
    return Err("ELF segment file size exceeds memory size")
  }
  let start64 = program.offset.to_uint64()
  let size64 = program.filesz.to_uint64()
  let data_size64 = data.length().to_uint64()
  if start64 > data_size64 || size64 > data_size64 - start64 {
    return Err("ELF segment file range is out of bounds")
  }
  if program.memsz == program.filesz {
    Ok(data[program.offset:program.offset + program.filesz].to_owned())
  } else {
    let bytes = Array::make(program.memsz, b'\x00')
    for i in 0..<program.filesz {
      bytes[i] = data[program.offset + i]
    }
    Ok(Bytes::from_array(bytes))
  }
}

///|
fn image_elf_symbol_count(
  section : ImageElfSectionHeader,
) -> Result[Int, String] {
  if section.entsize <= 0 {
    Err("ELF symbol section entry size is invalid")
  } else if section.size % section.entsize != 0 {
    Err("ELF symbol section size is not entry-aligned")
  } else {
    Ok(section.size / section.entsize)
  }
}

///|
fn image_elf_symbol_entry_size(header : ImageElfHeader) -> Int {
  match header.class {
    ImageElf32 => 16
    ImageElf64 => 24
  }
}

///|
fn image_elf_parse_symbol_entry(
  data : Bytes,
  header : ImageElfHeader,
  symbol_table : ImageElfSectionHeader,
  string_table : Bytes,
  index : Int,
) -> Result[ImageElfSymbolEntry, String] {
  let base = symbol_table.offset + index * symbol_table.entsize
  image_elf_parse_symbol_entry_at(data, header, string_table, base)
}

///|
fn image_elf_parse_symbol_entry_at(
  data : Bytes,
  header : ImageElfHeader,
  string_table : Bytes,
  base : Int,
) -> Result[ImageElfSymbolEntry, String] {
  let name_offset = image_elf_read_int(
    data,
    base,
    4,
    header.endian,
    "ELF symbol name offset",
  )
  let info = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 12, 1, header.endian, "ELF symbol info")
    ImageElf64 =>
      image_elf_read_int(data, base + 4, 1, header.endian, "ELF symbol info")
  }
  let shndx = match header.class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        base + 14,
        2,
        header.endian,
        "ELF symbol section",
      )
    ImageElf64 =>
      image_elf_read_int(data, base + 6, 2, header.endian, "ELF symbol section")
  }
  let value = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 4, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 8, 8, header.endian)
  }
  let size = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 8, 4, header.endian, "ELF symbol size")
    ImageElf64 =>
      image_elf_read_int(data, base + 16, 8, header.endian, "ELF symbol size")
  }
  match (name_offset, info, shndx, value, size) {
    (Ok(name_offset), Ok(info), Ok(shndx), Ok(value), Ok(size)) => {
      let name = if name_offset == 0 {
        None
      } else {
        match image_elf_cstring(string_table, name_offset) {
          Ok(text) => if text.length() == 0 { None } else { Some(text) }
          Err(reason) => return Err(reason)
        }
      }
      Ok({ name, shndx, value, size, info, })
    }
    (Err(reason), _, _, _, _)
    | (_, Err(reason), _, _, _)
    | (_, _, Err(reason), _, _)
    | (_, _, _, Err(reason), _)
    | (_, _, _, _, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_symbol_entry_symbol(entry : ImageElfSymbolEntry) -> Symbol? {
  match entry.name {
    Some(name) if entry.shndx != 0 =>
      Some(
        Symbol::create(
          name~,
          addr=entry.value,
          size=entry.size,
          is_function=(entry.info & 0x0f) == 2,
        ),
      )
    _ => None
  }
}

///|
fn image_elf_symbol_table_entries(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  symbol_table : ImageElfSectionHeader,
) -> Result[Array[ImageElfSymbolEntry], String] {
  let string_section = match section_headers.get(symbol_table.link) {
    Some(section) => section
    None => return Err("ELF symbol string table link is out of bounds")
  }
  let strings = match
    image_elf_section_data(data, string_section.offset, string_section.size) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count = match image_elf_symbol_count(symbol_table) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entries : Array[ImageElfSymbolEntry] = []
  for i in 0..<count {
    match image_elf_parse_symbol_entry(data, header, symbol_table, strings, i) {
      Ok(entry) => entries.push(entry)
      Err(reason) => return Err(reason)
    }
  }
  Ok(entries)
}

///|
fn image_elf_symbol_table_symbols(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  symbol_table : ImageElfSectionHeader,
) -> Result[Array[Symbol], String] {
  let entries = match
    image_elf_symbol_table_entries(data, header, section_headers, symbol_table) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let symbols : Array[Symbol] = []
  for entry in entries {
    match image_elf_symbol_entry_symbol(entry) {
      Some(symbol) => symbols.push(symbol)
      None => ()
    }
  }
  Ok(symbols)
}

///|
fn image_elf_symbol_table_values(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  symbol_table : ImageElfSectionHeader,
) -> Result[Array[SymbolValue], String] {
  let entries = match
    image_elf_symbol_table_entries(data, header, section_headers, symbol_table) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let values : Array[SymbolValue] = []
  for entry in entries {
    match entry.name {
      Some(_) if entry.shndx != 0 =>
        values.push(SymbolValue::create(addr=entry.value, value=entry.value))
      _ => ()
    }
  }
  Ok(values)
}

///|
fn image_elf_relocation_count(
  section : ImageElfSectionHeader,
) -> Result[Int, String] {
  if section.entsize <= 0 {
    Err("ELF relocation section entry size is invalid")
  } else if section.size % section.entsize != 0 {
    Err("ELF relocation section size is not entry-aligned")
  } else {
    Ok(section.size / section.entsize)
  }
}

///|
fn image_elf_parse_relocation_entry(
  data : Bytes,
  header : ImageElfHeader,
  relocation_section : ImageElfSectionHeader,
  index : Int,
) -> Result[ImageElfRelocationEntry, String] {
  let base = relocation_section.offset + index * relocation_section.entsize
  image_elf_parse_relocation_entry_at(
    data,
    header,
    base,
    relocation_section.typ == 4,
  )
}

///|
fn image_elf_parse_relocation_info(
  header : ImageElfHeader,
  info : UInt64,
) -> Result[(Int, Int), String] {
  let symbol_index = match header.class {
    ImageElf32 =>
      image_elf_uint_to_int(info >> 8, "ELF relocation symbol index")
    ImageElf64 =>
      image_elf_uint_to_int(info >> 32, "ELF relocation symbol index")
  }
  let typ = match header.class {
    ImageElf32 => image_elf_uint_to_int(info & 0xffUL, "ELF relocation type")
    ImageElf64 =>
      image_elf_uint_to_int(info & 0xffffffffUL, "ELF relocation type")
  }
  match (symbol_index, typ) {
    (Ok(symbol_index), Ok(typ)) => Ok((symbol_index, typ))
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_sign_extend(value : UInt64, bits : Int) -> Int64 {
  if bits >= 64 {
    value.reinterpret_as_int64()
  } else {
    let sign = 1UL << (bits - 1)
    let extended = if (value & sign) != 0UL {
      value | (UInt64::lnot(0UL) << bits)
    } else {
      value
    }
    extended.reinterpret_as_int64()
  }
}

///|
fn image_elf_read_addend(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[Int64, String] {
  match image_elf_read_uint(data, offset, bytes, endian) {
    Ok(value) => Ok(image_elf_sign_extend(value, bytes * 8))
    Err(reason) => Err(reason)
  }
}

///|
fn image_elf_parse_relocation_entry_at(
  data : Bytes,
  header : ImageElfHeader,
  base : Int,
  has_addend : Bool,
) -> Result[ImageElfRelocationEntry, String] {
  let offset = match header.class {
    ImageElf32 => image_elf_read_u64(data, base, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base, 8, header.endian)
  }
  let info = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 4, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 8, 8, header.endian)
  }
  let addend = if has_addend {
    match header.class {
      ImageElf32 => image_elf_read_addend(data, base + 8, 4, header.endian)
      ImageElf64 => image_elf_read_addend(data, base + 16, 8, header.endian)
    }
  } else {
    Ok(0L)
  }
  match (offset, info) {
    (Ok(offset), Ok(info)) =>
      match (image_elf_parse_relocation_info(header, info), addend) {
        (Ok((symbol_index, typ)), Ok(addend)) =>
          Ok({
            offset,
            symbol_index,
            typ,
            addend: if has_addend {
              Some(addend)
            } else {
              None
            },
            memory_addend: !has_addend,
          })
        (Err(reason), _) | (_, Err(reason)) => Err(reason)
      }
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_is_relative_relocation(header : ImageElfHeader, typ : Int) -> Bool {
  match header.machine {
    0x04 => typ == 22 // R_68K_RELATIVE
    0x02 | 0x2b => typ == 22 // R_SPARC_RELATIVE
    0x03 | 0x3e => typ == 8 // R_386_RELATIVE / R_X86_64_RELATIVE
    0x08 | 0x0a => typ == 3 // R_MIPS_REL32
    0x14 | 0x15 => typ == 22 // R_PPC_RELATIVE / R_PPC64_RELATIVE
    0x16 => typ == 12 // R_390_RELATIVE
    0x28 => typ == 23 // R_ARM_RELATIVE
    0x2d | 0x5d | 0xc3 => typ == 56 // R_ARC_RELATIVE
    0x5e => typ == 5 // R_XTENSA_RELATIVE
    0xa4 => typ == 35 // R_HEX_RELATIVE
    0xb7 => typ == 1027 || typ == 183 // R_AARCH64_RELATIVE / R_AARCH64_P32_RELATIVE
    0xe0 => typ == 13 // R_AMDGPU_RELATIVE64
    0xf3 => typ == 3 // R_RISCV_RELATIVE
    0xfb => typ == 17 // R_VE_RELATIVE
    0xfc => typ == 9 // R_CKCORE_RELATIVE
    0x102 => typ == 3 // R_LARCH_RELATIVE
    _ => false
  }
}

///|
fn image_elf_relocation_section_symbols(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  relocation_section : ImageElfSectionHeader,
) -> Result[Array[ImageElfSymbolEntry], String] {
  let symbol_table = match section_headers.get(relocation_section.link) {
    Some(section) => section
    None => return Err("ELF relocation symbol table link is out of bounds")
  }
  if symbol_table.typ != 2 && symbol_table.typ != 11 {
    return Err("ELF relocation section does not link to a symbol table")
  }
  image_elf_symbol_table_entries(data, header, section_headers, symbol_table)
}

///|
fn image_elf_relocations(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
) -> Result[(Array[Relocation], Array[ExternalReference]), String] {
  let relocations : Array[Relocation] = []
  let external_references : Array[ExternalReference] = []
  for section in section_headers {
    if section.typ == 4 || section.typ == 9 {
      let symbol_entries = match
        image_elf_relocation_section_symbols(
          data, header, section_headers, section,
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let count = match image_elf_relocation_count(section) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      for i in 0..<count {
        let entry = match
          image_elf_parse_relocation_entry(data, header, section, i) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        if image_elf_is_relative_relocation(header, entry.typ) {
          relocations.push(
            Relocation::create(
              fixup=entry.offset,
              addend?=entry.addend,
              memory_addend=entry.memory_addend,
              relative=true,
            ),
          )
        } else if entry.symbol_index != 0 {
          let symbol = match symbol_entries.get(entry.symbol_index) {
            Some(value) => value
            None => return Err("ELF relocation symbol index is out of bounds")
          }
          match symbol.name {
            Some(name) =>
              if symbol.shndx == 0 {
                external_references.push(
                  ExternalReference::create(addr=entry.offset, name~),
                )
              } else {
                relocations.push(
                  Relocation::create(
                    fixup=entry.offset,
                    target=symbol.value,
                    addend?=entry.addend,
                    memory_addend=entry.memory_addend,
                  ),
                )
              }
            None => ()
          }
        }
      }
    }
  }
  Ok((relocations, external_references))
}

///|
fn image_elf_has_relocation_sections(
  section_headers : Array[ImageElfSectionHeader],
) -> Bool {
  section_headers.any(section => section.typ == 4 || section.typ == 9)
}

///|
fn image_elf_relocation_entry_size(
  header : ImageElfHeader,
  has_addend : Bool,
) -> Int {
  match (header.class, has_addend) {
    (ImageElf32, false) => 8
    (ImageElf32, true) => 12
    (ImageElf64, false) => 16
    (ImageElf64, true) => 24
  }
}

///|
fn image_elf_dynamic_relocation_table_empty() -> ImageElfDynamicRelocationTable {
  { addr: None, size: None, entry_size: None, }
}

///|
fn image_elf_dynamic_relocation_table_entries(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
  table : ImageElfDynamicRelocationTable,
  has_addend : Bool,
  name : String,
) -> Result[Array[ImageElfRelocationEntry], String] {
  match (table.addr, table.size) {
    (Some(addr), Some(size)) if size > 0 => {
      let entry_size = match table.entry_size {
        Some(value) => value
        None => image_elf_relocation_entry_size(header, has_addend)
      }
      let minimum_entry_size = image_elf_relocation_entry_size(
        header, has_addend,
      )
      if entry_size < minimum_entry_size {
        return Err("\{name} entry size is invalid")
      }
      if size % entry_size != 0 {
        return Err("\{name} size is not entry-aligned")
      }
      let table_offset = match
        image_elf_vaddr_range_offset(program_headers, addr, size, name) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let entries : Array[ImageElfRelocationEntry] = []
      for i in 0..<(size / entry_size) {
        match
          image_elf_parse_relocation_entry_at(
            data,
            header,
            table_offset + i * entry_size,
            has_addend,
          ) {
          Ok(entry) => entries.push(entry)
          Err(reason) => return Err(reason)
        }
      }
      Ok(entries)
    }
    (Some(_), Some(_)) => Ok([])
    (Some(_), None) | (None, Some(_)) => Err("\{name} metadata is incomplete")
    (None, None) => Ok([])
  }
}

///|
fn image_elf_dynamic_relr_word_bytes(header : ImageElfHeader) -> Int {
  match header.class {
    ImageElf32 => 4
    ImageElf64 => 8
  }
}

///|
fn image_elf_add_dynamic_relr_entry(
  relocations : Array[Relocation],
  fixup : UInt64,
) -> Unit {
  relocations.push(
    Relocation::create(fixup~, relative=true, memory_addend=true),
  )
}

///|
fn image_elf_dynamic_relr_relocations(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
  table : ImageElfDynamicRelocationTable,
) -> Result[Array[Relocation], String] {
  match (table.addr, table.size) {
    (Some(addr), Some(size)) if size > 0 => {
      let word_bytes = image_elf_dynamic_relr_word_bytes(header)
      let entry_size = match table.entry_size {
        Some(value) => value
        None => word_bytes
      }
      if entry_size < word_bytes {
        return Err("ELF dynamic RELR table entry size is invalid")
      }
      if size % entry_size != 0 {
        return Err("ELF dynamic RELR table size is not entry-aligned")
      }
      let table_offset = match
        image_elf_vaddr_range_offset(
          program_headers, addr, size, "ELF dynamic RELR table",
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let relocations : Array[Relocation] = []
      let mut next_fixup = 0UL
      let word_bits = word_bytes * 8
      for i in 0..<(size / entry_size) {
        let entry = match
          image_elf_read_u64(
            data,
            table_offset + i * entry_size,
            word_bytes,
            header.endian,
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        if (entry & 1UL) == 0UL {
          image_elf_add_dynamic_relr_entry(relocations, entry)
          next_fixup = entry + word_bytes.to_uint64()
        } else {
          let mut bits = entry >> 1
          for bit in 0..<(word_bits - 1) {
            if (bits & 1UL) != 0UL {
              image_elf_add_dynamic_relr_entry(
                relocations,
                next_fixup + bit.to_uint64() * word_bytes.to_uint64(),
              )
            }
            bits = bits >> 1
          }
          next_fixup = next_fixup +
            (word_bits - 1).to_uint64() * word_bytes.to_uint64()
        }
      }
      Ok(relocations)
    }
    (Some(_), Some(_)) => Ok([])
    (Some(_), None) | (None, Some(_)) =>
      Err("ELF dynamic RELR table metadata is incomplete")
    (None, None) => Ok([])
  }
}

///|
fn image_elf_dynamic_count(
  section : ImageElfSectionHeader,
) -> Result[Int, String] {
  if section.size == 0 {
    Ok(0)
  } else if section.entsize <= 0 {
    Err("ELF dynamic section entry size is invalid")
  } else if section.size % section.entsize != 0 {
    Err("ELF dynamic section size is not entry-aligned")
  } else {
    Ok(section.size / section.entsize)
  }
}

///|
fn image_elf_dynamic_entry_size(header : ImageElfHeader) -> Int {
  match header.class {
    ImageElf32 => 8
    ImageElf64 => 16
  }
}

///|
fn image_elf_parse_dynamic_entry_at(
  data : Bytes,
  header : ImageElfHeader,
  base : Int,
) -> Result[(UInt64, UInt64), String] {
  let tag = match header.class {
    ImageElf32 => image_elf_read_u64(data, base, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base, 8, header.endian)
  }
  let value = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 4, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 8, 8, header.endian)
  }
  match (tag, value) {
    (Ok(tag), Ok(value)) => Ok((tag, value))
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_parse_dynamic_entry(
  data : Bytes,
  header : ImageElfHeader,
  dynamic_section : ImageElfSectionHeader,
  index : Int,
) -> Result[(UInt64, UInt64), String] {
  image_elf_parse_dynamic_entry_at(
    data,
    header,
    dynamic_section.offset + index * dynamic_section.entsize,
  )
}

///|
fn image_elf_dynamic_metadata_empty() -> ImageElfDynamicMetadata {
  { required_libraries: [], rpaths: [], runpaths: [], soname: None, }
}

///|
fn ImageElfDynamicMetadata::merge(
  self : ImageElfDynamicMetadata,
  other : ImageElfDynamicMetadata,
) -> ImageElfDynamicMetadata {
  let libraries = self.required_libraries.copy()
  for name in other.required_libraries {
    libraries.push(name)
  }
  let rpaths = self.rpaths.copy()
  for path in other.rpaths {
    rpaths.push(path)
  }
  let runpaths = self.runpaths.copy()
  for path in other.runpaths {
    runpaths.push(path)
  }
  let soname = match self.soname {
    Some(_) => self.soname
    None => other.soname
  }
  { required_libraries: libraries, rpaths, runpaths, soname, }
}

///|
fn image_elf_dynamic_entry_uses_string(tag : UInt64) -> Bool {
  tag == 1UL || tag == 14UL || tag == 15UL || tag == 29UL
}

///|
fn image_elf_dynamic_entries_use_strings(
  entries : Array[(UInt64, UInt64)],
) -> Bool {
  entries.any(entry => image_elf_dynamic_entry_uses_string(entry.0))
}

///|
fn image_elf_dynamic_metadata_from_entries(
  entries : Array[(UInt64, UInt64)],
  strings : Bytes,
) -> Result[ImageElfDynamicMetadata, String] {
  let libraries : Array[String] = []
  let rpaths : Array[String] = []
  let runpaths : Array[String] = []
  let mut soname : String? = None
  for entry in entries {
    match entry {
      (0UL, _) => ()
      (tag, offset) if image_elf_dynamic_entry_uses_string(tag) => {
        let string_offset = match
          image_elf_uint_to_int(offset, "ELF dynamic string offset") {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        match image_elf_cstring(strings, string_offset) {
          Ok(name) =>
            match tag {
              1UL => libraries.push(name)
              14UL => if soname is None { soname = Some(name) }
              15UL => rpaths.push(name)
              29UL => runpaths.push(name)
              _ => ()
            }
          Err(reason) => return Err(reason)
        }
      }
      _ => ()
    }
  }
  Ok({ required_libraries: libraries, rpaths, runpaths, soname, })
}

///|
fn image_elf_dynamic_metadata_from_sections(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
) -> Result[(Bool, ImageElfDynamicMetadata), String] {
  let mut metadata = image_elf_dynamic_metadata_empty()
  let mut has_dynamic_section = false
  for section in section_headers {
    if section.typ == 6 {
      has_dynamic_section = true
      let string_section = match section_headers.get(section.link) {
        Some(value) => value
        None => return Err("ELF dynamic string table link is out of bounds")
      }
      if string_section.typ != 3 {
        return Err("ELF dynamic section does not link to a string table")
      }
      let strings = match
        image_elf_section_data(data, string_section.offset, string_section.size) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let count = match image_elf_dynamic_count(section) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let entries : Array[(UInt64, UInt64)] = []
      for i in 0..<count {
        if entries.is_empty() || entries[entries.length() - 1].0 != 0UL {
          match image_elf_parse_dynamic_entry(data, header, section, i) {
            Ok(entry) => entries.push(entry)
            Err(reason) => return Err(reason)
          }
        }
      }
      match image_elf_dynamic_metadata_from_entries(entries, strings) {
        Ok(value) => metadata = metadata.merge(value)
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok((has_dynamic_section, metadata))
}

///|
fn image_elf_dynamic_entries_from_program(
  data : Bytes,
  header : ImageElfHeader,
  program : ImageElfProgramHeader,
) -> Result[Array[(UInt64, UInt64)], String] {
  let entry_size = image_elf_dynamic_entry_size(header)
  if program.filesz == 0 {
    return Ok([])
  }
  if program.filesz % entry_size != 0 {
    return Err("ELF dynamic segment size is not entry-aligned")
  }
  let entries : Array[(UInt64, UInt64)] = []
  let count = program.filesz / entry_size
  for i in 0..<count {
    if entries.is_empty() || entries[entries.length() - 1].0 != 0UL {
      match
        image_elf_parse_dynamic_entry_at(
          data,
          header,
          program.offset + i * entry_size,
        ) {
        Ok(entry) => entries.push(entry)
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(entries)
}

///|
fn image_elf_uint_to_dynamic_size(
  value : UInt64,
  what : String,
) -> Result[Int, String] {
  image_elf_uint_to_int(value, what)
}

///|
fn image_elf_dynamic_symbol_entry(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
  symbol_table_addr : UInt64?,
  symbol_entry_size : Int?,
  strings : Bytes?,
  symbol_index : Int,
) -> Result[ImageElfSymbolEntry?, String] {
  match (symbol_table_addr, strings) {
    (Some(symbol_table_addr), Some(strings)) => {
      let entry_size = match symbol_entry_size {
        Some(value) => value
        None => image_elf_symbol_entry_size(header)
      }
      let minimum_entry_size = image_elf_symbol_entry_size(header)
      if entry_size < minimum_entry_size {
        return Err("ELF dynamic symbol entry size is invalid")
      }
      let symbol_addr = symbol_table_addr +
        symbol_index.to_uint64() * entry_size.to_uint64()
      let symbol_offset = match
        image_elf_vaddr_range_offset(
          program_headers, symbol_addr, entry_size, "ELF dynamic symbol",
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      match
        image_elf_parse_symbol_entry_at(data, header, strings, symbol_offset) {
        Ok(symbol) => Ok(Some(symbol))
        Err(reason) => Err(reason)
      }
    }
    _ => Ok(None)
  }
}

///|
fn image_elf_dynamic_external_or_target_relocation(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
  strings : Bytes?,
  symbol_table_addr : UInt64?,
  symbol_entry_size : Int?,
  entry : ImageElfRelocationEntry,
) -> Result[(Relocation?, ExternalReference?), String] {
  if entry.symbol_index == 0 {
    return Ok((None, None))
  }
  match
    image_elf_dynamic_symbol_entry(
      data,
      header,
      program_headers,
      symbol_table_addr,
      symbol_entry_size,
      strings,
      entry.symbol_index,
    ) {
    Ok(Some(symbol)) =>
      match symbol.name {
        Some(name) =>
          if symbol.shndx == 0 {
            Ok(
              (None, Some(ExternalReference::create(addr=entry.offset, name~))),
            )
          } else {
            Ok(
              (
                Some(
                  Relocation::create(
                    fixup=entry.offset,
                    target=symbol.value,
                    addend?=entry.addend,
                    memory_addend=entry.memory_addend,
                  ),
                ),
                None,
              ),
            )
          }
        None => Ok((None, None))
      }
    Ok(None) => Ok((None, None))
    Err(reason) => Err(reason)
  }
}

///|
fn image_elf_add_dynamic_relocation_entry(
  relocations : Array[Relocation],
  external_references : Array[ExternalReference],
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
  strings : Bytes?,
  symbol_table_addr : UInt64?,
  symbol_entry_size : Int?,
  entry : ImageElfRelocationEntry,
) -> Result[Unit, String] {
  if image_elf_is_relative_relocation(header, entry.typ) {
    relocations.push(
      Relocation::create(
        fixup=entry.offset,
        addend?=entry.addend,
        memory_addend=entry.memory_addend,
        relative=true,
      ),
    )
  } else {
    match
      image_elf_dynamic_external_or_target_relocation(
        data, header, program_headers, strings, symbol_table_addr, symbol_entry_size,
        entry,
      ) {
      Ok((Some(relocation), _)) => relocations.push(relocation)
      Ok((_, Some(reference))) => external_references.push(reference)
      Ok((None, None)) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok(())
}

///|
fn image_elf_dynamic_plt_table(
  addr : UInt64?,
  size : Int?,
  typ : UInt64?,
  rel_entry_size : Int?,
  rela_entry_size : Int?,
) -> Result[(ImageElfDynamicRelocationTable, Bool), String] {
  match (addr, size, typ) {
    (_, Some(0), _) => Ok((image_elf_dynamic_relocation_table_empty(), false))
    (None, None, None) =>
      Ok((image_elf_dynamic_relocation_table_empty(), false))
    (Some(addr), Some(size), Some(7UL)) =>
      Ok(
        (
          { addr: Some(addr), size: Some(size), entry_size: rela_entry_size, },
          true,
        ),
      )
    (Some(addr), Some(size), Some(17UL)) =>
      Ok(
        (
          { addr: Some(addr), size: Some(size), entry_size: rel_entry_size, },
          false,
        ),
      )
    (Some(_), Some(_), Some(kind)) =>
      Err("unsupported ELF PLT relocation type: \{kind}")
    _ => Err("ELF PLT relocation metadata is incomplete")
  }
}

///|
fn image_elf_dynamic_relocations_from_programs(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
) -> Result[(Array[Relocation], Array[ExternalReference]), String] {
  let relocations : Array[Relocation] = []
  let external_references : Array[ExternalReference] = []
  for program in program_headers {
    if program.typ == 2 {
      let entries = match
        image_elf_dynamic_entries_from_program(data, header, program) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let mut rel = image_elf_dynamic_relocation_table_empty()
      let mut rela = image_elf_dynamic_relocation_table_empty()
      let mut string_table_addr : UInt64? = None
      let mut string_table_size : Int? = None
      let mut symbol_table_addr : UInt64? = None
      let mut symbol_entry_size : Int? = None
      let mut plt_addr : UInt64? = None
      let mut plt_size : Int? = None
      let mut plt_type : UInt64? = None
      let mut relr = image_elf_dynamic_relocation_table_empty()
      for entry in entries {
        match entry {
          (2UL, value) =>
            match
              image_elf_uint_to_dynamic_size(value, "ELF PLT relocation size") {
              Ok(size) => plt_size = Some(size)
              Err(reason) => return Err(reason)
            }
          (5UL, value) => string_table_addr = Some(value)
          (6UL, value) => symbol_table_addr = Some(value)
          (7UL, value) => rela = { ..rela, addr: Some(value), }
          (8UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF RELA size") {
              Ok(size) => rela = { ..rela, size: Some(size), }
              Err(reason) => return Err(reason)
            }
          (9UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF RELA entry size") {
              Ok(size) => rela = { ..rela, entry_size: Some(size), }
              Err(reason) => return Err(reason)
            }
          (10UL, value) =>
            match
              image_elf_uint_to_dynamic_size(
                value, "ELF dynamic string table size",
              ) {
              Ok(size) => string_table_size = Some(size)
              Err(reason) => return Err(reason)
            }
          (11UL, value) =>
            match
              image_elf_uint_to_dynamic_size(
                value, "ELF dynamic symbol entry size",
              ) {
              Ok(size) => symbol_entry_size = Some(size)
              Err(reason) => return Err(reason)
            }
          (17UL, value) => rel = { ..rel, addr: Some(value), }
          (18UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF REL size") {
              Ok(size) => rel = { ..rel, size: Some(size), }
              Err(reason) => return Err(reason)
            }
          (19UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF REL entry size") {
              Ok(size) => rel = { ..rel, entry_size: Some(size), }
              Err(reason) => return Err(reason)
            }
          (20UL, value) => plt_type = Some(value)
          (23UL, value) => plt_addr = Some(value)
          (35UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF RELR size") {
              Ok(size) => relr = { ..relr, size: Some(size), }
              Err(reason) => return Err(reason)
            }
          (36UL, value) => relr = { ..relr, addr: Some(value), }
          (37UL, value) =>
            match image_elf_uint_to_dynamic_size(value, "ELF RELR entry size") {
              Ok(size) => relr = { ..relr, entry_size: Some(size), }
              Err(reason) => return Err(reason)
            }
          _ => ()
        }
      }
      let strings : Bytes? = match (string_table_addr, string_table_size) {
        (Some(addr), Some(size)) => {
          let string_offset = match
            image_elf_vaddr_range_offset(
              program_headers, addr, size, "ELF dynamic string table",
            ) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          match image_elf_section_data(data, string_offset, size) {
            Ok(value) => Some(value)
            Err(reason) => return Err(reason)
          }
        }
        _ => None
      }
      let rela_entries = match
        image_elf_dynamic_relocation_table_entries(
          data, header, program_headers, rela, true, "ELF dynamic RELA table",
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      for entry in rela_entries {
        match
          image_elf_add_dynamic_relocation_entry(
            relocations, external_references, data, header, program_headers, strings,
            symbol_table_addr, symbol_entry_size, entry,
          ) {
          Ok(_) => ()
          Err(reason) => return Err(reason)
        }
      }
      let rel_entries = match
        image_elf_dynamic_relocation_table_entries(
          data, header, program_headers, rel, false, "ELF dynamic REL table",
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      for entry in rel_entries {
        match
          image_elf_add_dynamic_relocation_entry(
            relocations, external_references, data, header, program_headers, strings,
            symbol_table_addr, symbol_entry_size, entry,
          ) {
          Ok(_) => ()
          Err(reason) => return Err(reason)
        }
      }
      let relr_entries = match
        image_elf_dynamic_relr_relocations(data, header, program_headers, relr) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      for relocation in relr_entries {
        relocations.push(relocation)
      }
      let (plt, plt_has_addend) = match
        image_elf_dynamic_plt_table(
          plt_addr,
          plt_size,
          plt_type,
          rel.entry_size,
          rela.entry_size,
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let plt_entries = match
        image_elf_dynamic_relocation_table_entries(
          data, header, program_headers, plt, plt_has_addend, "ELF dynamic PLT relocation table",
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      for entry in plt_entries {
        match
          image_elf_add_dynamic_relocation_entry(
            relocations, external_references, data, header, program_headers, strings,
            symbol_table_addr, symbol_entry_size, entry,
          ) {
          Ok(_) => ()
          Err(reason) => return Err(reason)
        }
      }
    }
  }
  Ok((relocations, external_references))
}

///|
fn image_elf_vaddr_range_offset(
  program_headers : Array[ImageElfProgramHeader],
  addr : UInt64,
  size : Int,
  what : String,
) -> Result[Int, String] {
  if size < 0 {
    return Err("\{what} size is invalid")
  }
  let size64 = size.to_uint64()
  for program in program_headers {
    if program.typ == 1 && program.filesz >= 0 && addr >= program.vaddr {
      let delta = addr - program.vaddr
      let segment_size = program.filesz.to_uint64()
      if delta <= segment_size && size64 <= segment_size - delta {
        let offset = program.offset.to_uint64() + delta
        return image_elf_uint_to_int(offset, "\{what} file offset")
      }
    }
  }
  Err("\{what} is out of bounds")
}

///|
fn image_elf_dynamic_metadata_from_programs(
  data : Bytes,
  header : ImageElfHeader,
  program_headers : Array[ImageElfProgramHeader],
) -> Result[ImageElfDynamicMetadata, String] {
  let mut metadata = image_elf_dynamic_metadata_empty()
  for program in program_headers {
    if program.typ == 2 {
      let entries = match
        image_elf_dynamic_entries_from_program(data, header, program) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if image_elf_dynamic_entries_use_strings(entries) {
        let mut strtab : UInt64? = None
        let mut strsz : Int? = None
        for entry in entries {
          match entry {
            (5UL, value) => strtab = Some(value)
            (10UL, value) =>
              match
                image_elf_uint_to_int(value, "ELF dynamic string table size") {
                Ok(size) => strsz = Some(size)
                Err(reason) => return Err(reason)
              }
            _ => ()
          }
        }
        let (strtab, strsz) = match (strtab, strsz) {
          (Some(strtab), Some(strsz)) => (strtab, strsz)
          _ =>
            return Err("ELF dynamic segment is missing string table metadata")
        }
        let string_offset = match
          image_elf_vaddr_range_offset(
            program_headers, strtab, strsz, "ELF dynamic string table",
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        let strings = match image_elf_section_data(data, string_offset, strsz) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        match image_elf_dynamic_metadata_from_entries(entries, strings) {
          Ok(value) => metadata = metadata.merge(value)
          Err(reason) => return Err(reason)
        }
      }
    }
  }
  Ok(metadata)
}

///|
fn image_elf_dynamic_metadata(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  program_headers : Array[ImageElfProgramHeader],
) -> Result[ImageElfDynamicMetadata, String] {
  match
    image_elf_dynamic_metadata_from_sections(data, header, section_headers) {
    Ok((true, metadata)) => Ok(metadata)
    Ok((false, _)) =>
      image_elf_dynamic_metadata_from_programs(data, header, program_headers)
    Err(reason) => Err(reason)
  }
}

///|
fn image_elf_symbols(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
) -> Result[Array[Symbol], String] {
  let symbols : Array[Symbol] = []
  for section in section_headers {
    if section.typ == 2 || section.typ == 11 {
      match
        image_elf_symbol_table_symbols(data, header, section_headers, section) {
        Ok(items) =>
          for symbol in items {
            symbols.push(symbol)
          }
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(symbols)
}

///|
fn image_elf_symbol_values(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
) -> Result[Array[SymbolValue], String] {
  let values : Array[SymbolValue] = []
  for section in section_headers {
    if section.typ == 2 || section.typ == 11 {
      match
        image_elf_symbol_table_values(data, header, section_headers, section) {
        Ok(items) =>
          for item in items {
            values.push(item)
          }
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(values)
}

///|
fn image_elf_target_endian(endian : @bitvec.Endian) -> @core_theory.Endianness {
  match endian {
    LittleEndian => LittleEndian
    BigEndian => BigEndian
  }
}

///|
fn image_elf_target_system(osabi : Int) -> @core_theory.System? {
  match osabi {
    1 => Some(HPUX)
    2 => Some(NetBSD)
    3 => Some(Linux)
    6 => Some(Solaris)
    7 => Some(AIX)
    8 => Some(IRIX)
    9 => Some(FreeBSD)
    10 => Some(Tru64)
    11 => Some(Modesto)
    12 => Some(OpenBSD)
    255 => Some(NoSystem)
    _ => None
  }
}

///|
fn image_elf_target_abi(osabi : Int) -> @core_theory.Abi? {
  match osabi {
    0 => Some(SysV)
    3 => Some(GNU)
    64 => Some(EABI)
    _ => None
  }
}

///|
fn image_elf_known_target(
  name : String,
  fallback : @core_theory.Target,
) -> @core_theory.Target {
  match @core_theory.lookup_target(name) {
    Some(target) => target
    None => fallback
  }
}

///|
fn image_elf_target(header : ImageElfHeader) -> @core_theory.Target {
  let base = match header.machine {
    0x02 =>
      match header.class {
        ImageElf64 => @core_theory.Target::sparcv9()
        ImageElf32 => @core_theory.Target::sparc()
      }
    0x03 => @core_theory.Target::x86()
    0x08 =>
      match (header.class, header.endian) {
        (ImageElf64, LittleEndian) => @core_theory.Target::mips64el()
        (ImageElf64, BigEndian) => @core_theory.Target::mips64()
        (ImageElf32, LittleEndian) => @core_theory.Target::mipsel()
        (ImageElf32, BigEndian) => @core_theory.Target::mips()
      }
    0x0a => @core_theory.Target::mipsel()
    0x12 => @core_theory.Target::sparc()
    0x14 =>
      match header.endian {
        LittleEndian => @core_theory.Target::powerpcle()
        BigEndian => @core_theory.Target::powerpc()
      }
    0x15 =>
      match header.endian {
        LittleEndian => @core_theory.Target::powerpc64le()
        BigEndian => @core_theory.Target::powerpc64()
      }
    0x16 => @core_theory.Target::systemz()
    0x28 =>
      match header.endian {
        LittleEndian =>
          image_elf_known_target("armv7", @core_theory.Target::arm())
        BigEndian =>
          image_elf_known_target("armv7eb", @core_theory.Target::armeb())
      }
    0x2b => @core_theory.Target::sparcv9()
    0x3e => @core_theory.Target::x86_64()
    0xa4 => @core_theory.Target::hexagon()
    0xb7 =>
      match header.endian {
        LittleEndian => @core_theory.Target::aarch64()
        BigEndian => @core_theory.Target::aarch64_be()
      }
    0xbe =>
      match header.class {
        ImageElf64 => @core_theory.Target::nvptx64()
        ImageElf32 => @core_theory.Target::nvptx()
      }
    0xcb => @core_theory.Target::xcore()
    0xe0 => @core_theory.Target::r600()
    0xf3 =>
      match header.class {
        ImageElf64 => @core_theory.Target::riscv64()
        ImageElf32 => @core_theory.Target::riscv32()
      }
    0x102 =>
      match header.class {
        ImageElf64 => @core_theory.Target::loongarch64()
        ImageElf32 => @core_theory.Target::loongarch32()
      }
    _ =>
      @core_theory.Target::unknown().with_bits(
        match header.class {
          ImageElf32 => 32
          ImageElf64 => 64
        },
      )
  }
  let target = base
    .with_endianness(image_elf_target_endian(header.endian))
    .with_filetype(Elf)
  let target = match image_elf_target_system(header.osabi) {
    Some(system) => target.with_system(system)
    None => target
  }
  match image_elf_target_abi(header.osabi) {
    Some(abi) => target.with_abi(abi)
    None => target
  }
}

///|
fn image_elf_flag_set(flags : Int, flag : Int) -> Bool {
  (flags & flag) != 0
}

///|
fn image_elf_section_flag_set(
  section : ImageElfSectionHeader,
  flag : UInt64,
) -> Bool {
  (section.flags & flag) != 0UL
}

///|
fn image_elf_section_segment_name(index : Int, name : String?) -> String {
  match name {
    Some(name) => name
    None => ".section\{index}"
  }
}

///|
fn image_elf_section_segment_data(
  data : Bytes,
  section : ImageElfSectionHeader,
) -> Result[Bytes, String] {
  if section.size < 0 {
    return Err("ELF section range is invalid")
  }
  if section.typ == 8 {
    Ok(Bytes::new(section.size))
  } else {
    image_elf_section_data(data, section.offset, section.size)
  }
}

///|
fn image_elf_alloc_section_segments(
  data : Bytes,
  header : ImageElfHeader,
  section_headers : Array[ImageElfSectionHeader],
  section_names : Array[String?],
) -> Result[Array[Segment], String] {
  let segments : Array[Segment] = []
  for i in 0..<section_headers.length() {
    let section = section_headers[i]
    if image_elf_section_flag_set(section, 2UL) && section.size > 0 {
      match image_elf_section_segment_data(data, section) {
        Ok(segment_data) =>
          segments.push(
            Segment::create(
              name=image_elf_section_segment_name(i, section_names[i]),
              endian=header.endian,
              addr=section.addr,
              segment_data,
              offset=section.offset,
              readable=true,
              writable=image_elf_section_flag_set(section, 1UL),
              executable=image_elf_section_flag_set(section, 4UL),
            ),
          )
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(segments)
}

///|
fn image_elf_interpreter(
  data : Bytes,
  program_headers : Array[ImageElfProgramHeader],
) -> Result[String?, String] {
  for program in program_headers {
    if program.typ == 3 {
      let bytes = match
        image_elf_section_data(data, program.offset, program.filesz) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      match image_elf_cstring(bytes, 0) {
        Ok(value) => return Ok(Some(value))
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(None)
}

///|
fn image_elf_base_address(segments : Array[Segment]) -> UInt64? {
  if segments.is_empty() {
    None
  } else {
    let mut base = segments[0].addr()
    for segment in segments[1:] {
      if segment.addr() < base {
        base = segment.addr()
      }
    }
    Some(base)
  }
}

///|
fn image_elf_load(data : Bytes) -> Result[(Image, Array[String]), String] {
  match image_elf_parse(data) {
    Ok((raw, header, program_headers, section_headers)) => {
      let names : Bytes? = if section_headers.is_empty() ||
        header.section_name_index == 0 {
        None
      } else {
        match section_headers.get(header.section_name_index) {
          Some(section) =>
            match image_elf_section_data(data, section.offset, section.size) {
              Ok(value) => Some(value)
              Err(reason) => return Err(reason)
            }
          None => return Err("ELF section name table index is out of bounds")
        }
      }
      let section_names : Array[String?] = []
      for section in section_headers {
        match image_elf_section_name(names, section) {
          Ok(name) => section_names.push(name)
          Err(reason) => return Err(reason)
        }
      }
      let sections : Array[Section] = []
      for i in 0..<section_headers.length() {
        let section = section_headers[i]
        match section_names[i] {
          Some(name) if section.size > 0 =>
            sections.push(
              Section::create(name~, addr=section.addr, size=section.size),
            )
          _ => ()
        }
      }
      let symbols = match image_elf_symbols(data, header, section_headers) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let symbol_values = match
        image_elf_symbol_values(data, header, section_headers) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let (relocations, external_references) = match
        image_elf_relocations(data, header, section_headers) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if !image_elf_has_relocation_sections(section_headers) {
        let (dynamic_relocations, dynamic_references) = match
          image_elf_dynamic_relocations_from_programs(
            data, header, program_headers,
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        for relocation in dynamic_relocations {
          relocations.push(relocation)
        }
        for reference in dynamic_references {
          external_references.push(reference)
        }
      }
      let dynamic_metadata = match
        image_elf_dynamic_metadata(
          data, header, section_headers, program_headers,
        ) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let interpreter = match image_elf_interpreter(data, program_headers) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let segments : Array[Segment] = []
      for program in program_headers {
        if program.typ == 1 && program.memsz > 0 {
          match image_elf_segment_data(data, program) {
            Ok(segment_data) =>
              segments.push(
                Segment::create(
                  name=".load\{segments.length()}",
                  endian=header.endian,
                  addr=program.vaddr,
                  segment_data,
                  offset=program.offset,
                  readable=image_elf_flag_set(program.flags, 4),
                  writable=image_elf_flag_set(program.flags, 2),
                  executable=image_elf_flag_set(program.flags, 1),
                ),
              )
            Err(reason) => return Err(reason)
          }
        }
      }
      let segments = if segments.is_empty() {
        match
          image_elf_alloc_section_segments(
            data, header, section_headers, section_names,
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
      } else {
        segments
      }
      if segments.is_empty() {
        return Err("ELF file has no loadable segments or allocatable sections")
      }
      let base_address = image_elf_base_address(segments)
      Ok(
        (
          Image::from_segments(
            entry=header.entry,
            endian=header.endian,
            segments,
            sections~,
            symbols~,
            relocations~,
            external_references~,
            required_libraries=dynamic_metadata.required_libraries,
            rpaths=dynamic_metadata.rpaths,
            runpaths=dynamic_metadata.runpaths,
            symbol_values~,
            interpreter?,
            soname?=dynamic_metadata.soname,
            is_executable=header.typ == 2,
            base_address?,
            target=image_elf_target(header),
          ).with_loader_facts(image_elf_loader_facts(data, raw)),
          [],
        ),
      )
    }
    Err(reason) => Err(reason)
  }
}

///|
pub fn ImageBackend::elf() -> ImageBackend {
  ImageBackend::create(
    name="elf",
    description="ELF executable image",
    extensions=["elf", "o", "so"],
    priority=30,
    load=image_elf_load,
  )
}
