///|
priv enum ImageElfClass {
  ImageElf32
  ImageElf64
}

///|
priv struct ImageElfHeader {
  endian : @bitvec.Endian
  class : ImageElfClass
  osabi : Int
  typ : Int
  machine : Int
  entry : UInt64
  program_table_offset : Int
  program_header_size : Int
  program_count : Int
  section_table_offset : Int
  section_header_size : Int
  section_count : Int
  section_name_index : Int
}

///|
priv struct ImageElfSectionZero {
  section_count : Int
  section_name_index : Int
  program_count : Int
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
}

///|
priv struct ImageElfDynamicMetadata {
  required_libraries : Array[String]
  rpaths : Array[String]
  runpaths : Array[String]
  soname : String?
}

///|
fn image_elf_minimum_section_header(class : ImageElfClass) -> Int {
  match class {
    ImageElf32 => 40
    ImageElf64 => 64
  }
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
fn image_elf_parse_section_zero(
  data : Bytes,
  class : ImageElfClass,
  endian : @bitvec.Endian,
  section_table_offset : Int,
  section_header_size : Int,
) -> Result[ImageElfSectionZero, String] {
  if section_table_offset == 0 {
    return Err("extended ELF section table is missing")
  }
  let minimum_section_header = image_elf_minimum_section_header(class)
  if section_header_size < minimum_section_header {
    return Err("ELF section headers are too small")
  }
  match
    image_elf_check_table(
      data, section_table_offset, section_header_size, 1, "ELF section table",
    ) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  let section_count = match class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        section_table_offset + 20,
        4,
        endian,
        "ELF extended section count",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        section_table_offset + 32,
        8,
        endian,
        "ELF extended section count",
      )
  }
  let section_name_index = match class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        section_table_offset + 24,
        4,
        endian,
        "ELF extended section name table index",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        section_table_offset + 40,
        4,
        endian,
        "ELF extended section name table index",
      )
  }
  let program_count = match class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        section_table_offset + 28,
        4,
        endian,
        "ELF extended program count",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        section_table_offset + 44,
        4,
        endian,
        "ELF extended program count",
      )
  }
  match (section_count, section_name_index, program_count) {
    (Ok(section_count), Ok(section_name_index), Ok(program_count)) =>
      Ok({ section_count, section_name_index, program_count })
    (Err(reason), _, _) | (_, Err(reason), _) | (_, _, Err(reason)) =>
      Err(reason)
  }
}

///|
fn image_elf_parse_header(data : Bytes) -> Result[ImageElfHeader, String] {
  if data.length() < 16 {
    return Err("truncated ELF header")
  }
  if data[0] != b'\x7f' || data[1] != b'E' || data[2] != b'L' || data[3] != b'F' {
    return Err("not an ELF file")
  }
  let class = match data[4].to_int() {
    1 => ImageElf32
    2 => ImageElf64
    other => return Err("unsupported ELF class: \{other}")
  }
  let endian : @bitvec.Endian = match data[5].to_int() {
    1 => LittleEndian
    2 => BigEndian
    other => return Err("unsupported ELF data encoding: \{other}")
  }
  if data[6].to_int() != 1 {
    return Err("unsupported ELF version")
  }
  let osabi = data[7].to_int()
  let min_header_size = match class {
    ImageElf32 => 52
    ImageElf64 => 64
  }
  if data.length() < min_header_size {
    return Err("truncated ELF header")
  }
  let typ = image_elf_read_int(data, 16, 2, endian, "ELF type")
  let machine = image_elf_read_int(data, 18, 2, endian, "ELF machine")
  let entry = match class {
    ImageElf32 => image_elf_read_u64(data, 24, 4, endian)
    ImageElf64 => image_elf_read_u64(data, 24, 8, endian)
  }
  let program_table_offset = match class {
    ImageElf32 =>
      image_elf_read_int(data, 28, 4, endian, "ELF program table offset")
    ImageElf64 =>
      image_elf_read_int(data, 32, 8, endian, "ELF program table offset")
  }
  let section_table_offset = match class {
    ImageElf32 =>
      image_elf_read_int(data, 32, 4, endian, "ELF section table offset")
    ImageElf64 =>
      image_elf_read_int(data, 40, 8, endian, "ELF section table offset")
  }
  let program_header_size = match class {
    ImageElf32 =>
      image_elf_read_int(data, 42, 2, endian, "ELF program header size")
    ImageElf64 =>
      image_elf_read_int(data, 54, 2, endian, "ELF program header size")
  }
  let program_count = match class {
    ImageElf32 => image_elf_read_int(data, 44, 2, endian, "ELF program count")
    ImageElf64 => image_elf_read_int(data, 56, 2, endian, "ELF program count")
  }
  let section_header_size = match class {
    ImageElf32 =>
      image_elf_read_int(data, 46, 2, endian, "ELF section header size")
    ImageElf64 =>
      image_elf_read_int(data, 58, 2, endian, "ELF section header size")
  }
  let section_count = match class {
    ImageElf32 => image_elf_read_int(data, 48, 2, endian, "ELF section count")
    ImageElf64 => image_elf_read_int(data, 60, 2, endian, "ELF section count")
  }
  let section_name_index = match class {
    ImageElf32 =>
      image_elf_read_int(data, 50, 2, endian, "ELF section name table index")
    ImageElf64 =>
      image_elf_read_int(data, 62, 2, endian, "ELF section name table index")
  }
  match
    (
      typ, machine, entry, program_table_offset, program_header_size, program_count,
      section_table_offset, section_header_size, section_count, section_name_index,
    ) {
    (
      Ok(typ),
      Ok(machine),
      Ok(entry),
      Ok(program_table_offset),
      Ok(program_header_size),
      Ok(raw_program_count),
      Ok(section_table_offset),
      Ok(section_header_size),
      Ok(raw_section_count),
      Ok(raw_section_name_index),
    ) => {
      let has_section_table = section_table_offset != 0
      let section_zero = if has_section_table &&
        (
          raw_section_count == 0 ||
          raw_section_name_index == 0xffff ||
          raw_program_count == 0xffff
        ) {
        match
          image_elf_parse_section_zero(
            data, class, endian, section_table_offset, section_header_size,
          ) {
          Ok(value) => Some(value)
          Err(reason) => return Err(reason)
        }
      } else {
        None
      }
      let program_count = match (raw_program_count, section_zero) {
        (0xffff, Some(section_zero)) => section_zero.program_count
        (0xffff, None) => return Err("extended ELF program table is missing")
        _ => raw_program_count
      }
      let section_count = match (raw_section_count, section_zero) {
        (0, Some(section_zero)) => section_zero.section_count
        _ => raw_section_count
      }
      let section_name_index = match (raw_section_name_index, section_zero) {
        (0xffff, Some(section_zero)) => section_zero.section_name_index
        (0xffff, None) => return Err("extended ELF section table is missing")
        _ => raw_section_name_index
      }
      let has_sections = section_count > 0
      if !has_sections && section_table_offset != 0 {
        return Err("ELF section table is invalid")
      }
      if !has_sections && section_name_index != 0 {
        return Err("ELF section name table index is out of bounds")
      }
      if has_sections &&
        (section_name_index < 0 || section_name_index >= section_count) {
        return Err("ELF section name table index is out of bounds")
      }
      let minimum_program_header = match class {
        ImageElf32 => 32
        ImageElf64 => 56
      }
      let minimum_section_header = image_elf_minimum_section_header(class)
      if program_count > 0 && program_header_size < minimum_program_header {
        return Err("ELF program headers are too small")
      }
      if has_sections && section_header_size < minimum_section_header {
        return Err("ELF section headers are too small")
      }
      match
        image_elf_check_table(
          data, program_table_offset, program_header_size, program_count, "ELF program table",
        ) {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      if has_sections {
        match
          image_elf_check_table(
            data, section_table_offset, section_header_size, section_count, "ELF section table",
          ) {
          Ok(_) => ()
          Err(reason) => return Err(reason)
        }
      }
      Ok({
        endian,
        class,
        osabi,
        typ,
        machine,
        entry,
        program_table_offset,
        program_header_size,
        program_count,
        section_table_offset,
        section_header_size,
        section_count,
        section_name_index,
      })
    }
    (Err(reason), _, _, _, _, _, _, _, _, _)
    | (_, Err(reason), _, _, _, _, _, _, _, _)
    | (_, _, Err(reason), _, _, _, _, _, _, _)
    | (_, _, _, Err(reason), _, _, _, _, _, _)
    | (_, _, _, _, Err(reason), _, _, _, _, _)
    | (_, _, _, _, _, Err(reason), _, _, _, _)
    | (_, _, _, _, _, _, Err(reason), _, _, _)
    | (_, _, _, _, _, _, _, Err(reason), _, _)
    | (_, _, _, _, _, _, _, _, Err(reason), _)
    | (_, _, _, _, _, _, _, _, _, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_check_table(
  data : Bytes,
  offset : Int,
  entry_size : Int,
  count : Int,
  name : String,
) -> Result[Unit, String] {
  if count == 0 {
    return Ok(())
  }
  if offset < 0 || entry_size < 0 || count < 0 {
    return Err("\{name} is invalid")
  }
  let offset64 = offset.to_uint64()
  let table_size64 = entry_size.to_uint64() * count.to_uint64()
  let data_size64 = data.length().to_uint64()
  if offset64 > data_size64 || table_size64 > data_size64 - offset64 {
    Err("\{name} is out of bounds")
  } else {
    Ok(())
  }
}

///|
fn image_elf_parse_program_header(
  data : Bytes,
  header : ImageElfHeader,
  index : Int,
) -> Result[ImageElfProgramHeader, String] {
  let base = header.program_table_offset + index * header.program_header_size
  let typ = image_elf_read_int(data, base, 4, header.endian, "ELF program type")
  let flags = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 24, 4, header.endian, "ELF program flags")
    ImageElf64 =>
      image_elf_read_int(data, base + 4, 4, header.endian, "ELF program flags")
  }
  let offset = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 4, 4, header.endian, "ELF segment offset")
    ImageElf64 =>
      image_elf_read_int(data, base + 8, 8, header.endian, "ELF segment offset")
  }
  let vaddr = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 8, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 16, 8, header.endian)
  }
  let filesz = match header.class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        base + 16,
        4,
        header.endian,
        "ELF segment file size",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        base + 32,
        8,
        header.endian,
        "ELF segment file size",
      )
  }
  let memsz = match header.class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        base + 20,
        4,
        header.endian,
        "ELF segment memory size",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        base + 40,
        8,
        header.endian,
        "ELF segment memory size",
      )
  }
  match (typ, flags, offset, vaddr, filesz, memsz) {
    (Ok(typ), Ok(flags), Ok(offset), Ok(vaddr), Ok(filesz), Ok(memsz)) =>
      Ok({ typ, flags, offset, vaddr, filesz, memsz })
    (Err(reason), _, _, _, _, _)
    | (_, Err(reason), _, _, _, _)
    | (_, _, Err(reason), _, _, _)
    | (_, _, _, Err(reason), _, _)
    | (_, _, _, _, Err(reason), _)
    | (_, _, _, _, _, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_program_headers(
  data : Bytes,
  header : ImageElfHeader,
) -> Result[Array[ImageElfProgramHeader], String] {
  let headers : Array[ImageElfProgramHeader] = []
  for i in 0..<header.program_count {
    match image_elf_parse_program_header(data, header, i) {
      Ok(program) => headers.push(program)
      Err(reason) => return Err(reason)
    }
  }
  Ok(headers)
}

///|
fn image_elf_parse_section_header(
  data : Bytes,
  header : ImageElfHeader,
  index : Int,
) -> Result[ImageElfSectionHeader, String] {
  let base = header.section_table_offset + index * header.section_header_size
  let name_offset = image_elf_read_int(
    data,
    base,
    4,
    header.endian,
    "ELF section name offset",
  )
  let typ = image_elf_read_int(
    data,
    base + 4,
    4,
    header.endian,
    "ELF section type",
  )
  let flags = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 8, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 8, 8, header.endian)
  }
  let addr = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 12, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 16, 8, header.endian)
  }
  let offset = match header.class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        base + 16,
        4,
        header.endian,
        "ELF section offset",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        base + 24,
        8,
        header.endian,
        "ELF section offset",
      )
  }
  let size = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 20, 4, header.endian, "ELF section size")
    ImageElf64 =>
      image_elf_read_int(data, base + 32, 8, header.endian, "ELF section size")
  }
  let link = match header.class {
    ImageElf32 =>
      image_elf_read_int(data, base + 24, 4, header.endian, "ELF section link")
    ImageElf64 =>
      image_elf_read_int(data, base + 40, 4, header.endian, "ELF section link")
  }
  let entsize = match header.class {
    ImageElf32 =>
      image_elf_read_int(
        data,
        base + 36,
        4,
        header.endian,
        "ELF section entry size",
      )
    ImageElf64 =>
      image_elf_read_int(
        data,
        base + 56,
        8,
        header.endian,
        "ELF section entry size",
      )
  }
  match (name_offset, typ, flags, link, addr, offset, size, entsize) {
    (
      Ok(name_offset),
      Ok(typ),
      Ok(flags),
      Ok(link),
      Ok(addr),
      Ok(offset),
      Ok(size),
      Ok(entsize),
    ) => Ok({ name_offset, typ, flags, link, addr, offset, size, entsize })
    (Err(reason), _, _, _, _, _, _, _)
    | (_, Err(reason), _, _, _, _, _, _)
    | (_, _, Err(reason), _, _, _, _, _)
    | (_, _, _, Err(reason), _, _, _, _)
    | (_, _, _, _, Err(reason), _, _, _)
    | (_, _, _, _, _, Err(reason), _, _)
    | (_, _, _, _, _, _, Err(reason), _)
    | (_, _, _, _, _, _, _, Err(reason)) => Err(reason)
  }
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
fn image_elf_parse_symbol_entry(
  data : Bytes,
  header : ImageElfHeader,
  symbol_table : ImageElfSectionHeader,
  string_table : Bytes,
  index : Int,
) -> Result[ImageElfSymbolEntry, String] {
  let base = symbol_table.offset + index * symbol_table.entsize
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
      Ok({ name, shndx, value, size, info })
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
  let offset = match header.class {
    ImageElf32 => image_elf_read_u64(data, base, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base, 8, header.endian)
  }
  let info = match header.class {
    ImageElf32 => image_elf_read_u64(data, base + 4, 4, header.endian)
    ImageElf64 => image_elf_read_u64(data, base + 8, 8, header.endian)
  }
  match (offset, info) {
    (Ok(offset), Ok(info)) => {
      let symbol_index = match header.class {
        ImageElf32 =>
          image_elf_uint_to_int(info >> 8, "ELF relocation symbol index")
        ImageElf64 =>
          image_elf_uint_to_int(info >> 32, "ELF relocation symbol index")
      }
      let typ = match header.class {
        ImageElf32 =>
          image_elf_uint_to_int(info & 0xffUL, "ELF relocation type")
        ImageElf64 =>
          image_elf_uint_to_int(info & 0xffffffffUL, "ELF relocation type")
      }
      match (symbol_index, typ) {
        (Ok(symbol_index), Ok(typ)) => Ok({ offset, symbol_index, typ })
        (Err(reason), _) | (_, Err(reason)) => Err(reason)
      }
    }
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
fn image_elf_is_relative_relocation(header : ImageElfHeader, typ : Int) -> Bool {
  match header.machine {
    0x03 | 0x3e => typ == 8 // R_386_RELATIVE / R_X86_64_RELATIVE
    0xb7 => typ == 1027 // R_AARCH64_RELATIVE
    0xf3 => typ == 3 // R_RISCV_RELATIVE
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
            Relocation::create(fixup=entry.offset, relative=true),
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
                  Relocation::create(fixup=entry.offset, target=symbol.value),
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
  { required_libraries: [], rpaths: [], runpaths: [], soname: None }
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
  { required_libraries: libraries, rpaths, runpaths, soname }
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
  Ok({ required_libraries: libraries, rpaths, runpaths, soname })
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
    3 => Some(Linux)
    9 => Some(FreeBSD)
    12 => Some(OpenBSD)
    255 => Some(NoSystem)
    _ => None
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
        LittleEndian => @core_theory.Target::arm()
        BigEndian => @core_theory.Target::armeb()
      }
    0x2b => @core_theory.Target::sparcv9()
    0x3e => @core_theory.Target::x86_64()
    0xb7 =>
      match header.endian {
        LittleEndian => @core_theory.Target::aarch64()
        BigEndian => @core_theory.Target::aarch64_be()
      }
    0xf3 =>
      match header.class {
        ImageElf64 => @core_theory.Target::riscv64()
        ImageElf32 => @core_theory.Target::riscv32()
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
  match image_elf_target_system(header.osabi) {
    Some(system) => target.with_system(system)
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
fn image_elf_load(data : Bytes) -> Result[(Image, Array[String]), String] {
  match image_elf_parse_header(data) {
    Ok(header) => {
      let program_headers = match image_elf_program_headers(data, header) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let section_headers : Array[ImageElfSectionHeader] = []
      for i in 0..<header.section_count {
        match image_elf_parse_section_header(data, header, i) {
          Ok(section_header) => section_headers.push(section_header)
          Err(reason) => return Err(reason)
        }
      }
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
            target=image_elf_target(header),
          ),
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
