///|
priv enum DwarfElfClass {
  DwarfElf32
  DwarfElf64
}

///|
priv struct DwarfElfHeader {
  endian : @bitvec.Endian
  class : DwarfElfClass
  section_table_offset : Int
  section_header_size : Int
  section_count : Int
  section_name_index : Int
}

///|
priv struct DwarfElfSectionZero {
  section_count : Int
  section_name_index : Int
}

///|
priv struct DwarfElfSectionHeader {
  name_offset : Int
  file_offset : Int
  size : Int
}

///|
fn dwarf_elf_minimum_section_header(class : DwarfElfClass) -> Int {
  match class {
    DwarfElf32 => 40
    DwarfElf64 => 64
  }
}

///|
fn dwarf_elf_read_uint(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[UInt64, String] {
  if offset < 0 {
    return Err("invalid ELF offset")
  }
  match
    DwarfInput::of_bytes(data).with_position(offset).read_uint(bytes, endian) {
    Ok((value, _)) => Ok(value)
    Err(_) => Err("truncated ELF input")
  }
}

///|
fn dwarf_elf_uint_to_int(value : UInt64, what : String) -> Result[Int, String] {
  if value > 2147483647UL {
    Err("\{what} does not fit in Int")
  } else {
    Ok(value.to_int())
  }
}

///|
fn dwarf_elf_read_int(
  data : Bytes,
  offset : Int,
  bytes : Int,
  endian : @bitvec.Endian,
  what : String,
) -> Result[Int, String] {
  match dwarf_elf_read_uint(data, offset, bytes, endian) {
    Ok(value) => dwarf_elf_uint_to_int(value, what)
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_elf_parse_section_zero(
  data : Bytes,
  class : DwarfElfClass,
  endian : @bitvec.Endian,
  section_table_offset : Int,
  section_header_size : Int,
) -> Result[DwarfElfSectionZero, String] {
  if section_table_offset == 0 {
    return Err("ELF file has no section table")
  }
  let minimum_section_header = dwarf_elf_minimum_section_header(class)
  if section_header_size < minimum_section_header {
    return Err("ELF section headers are too small")
  }
  let table_offset64 = section_table_offset.to_uint64()
  let table_size64 = section_header_size.to_uint64()
  let data_size64 = data.length().to_uint64()
  if table_offset64 > data_size64 || table_size64 > data_size64 - table_offset64 {
    return Err("ELF section table is out of bounds")
  }
  let section_count = match class {
    DwarfElf32 =>
      dwarf_elf_read_int(
        data,
        section_table_offset + 20,
        4,
        endian,
        "ELF extended section count",
      )
    DwarfElf64 =>
      dwarf_elf_read_int(
        data,
        section_table_offset + 32,
        8,
        endian,
        "ELF extended section count",
      )
  }
  let section_name_index = match class {
    DwarfElf32 =>
      dwarf_elf_read_int(
        data,
        section_table_offset + 24,
        4,
        endian,
        "ELF extended section name table index",
      )
    DwarfElf64 =>
      dwarf_elf_read_int(
        data,
        section_table_offset + 40,
        4,
        endian,
        "ELF extended section name table index",
      )
  }
  match (section_count, section_name_index) {
    (Ok(section_count), Ok(section_name_index)) =>
      Ok({ section_count, section_name_index })
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
fn dwarf_elf_section_of_name(name : String) -> DwarfSection? {
  match name {
    ".debug_info" => Some(DwarfInfo)
    ".debug_abbrev" => Some(DwarfAbbrev)
    ".debug_str" => Some(DwarfStr)
    ".debug_line_str" => Some(DwarfLineStr)
    ".debug_str_offsets" => Some(DwarfStrOffsets)
    ".debug_addr" => Some(DwarfAddr)
    ".debug_ranges" => Some(DwarfRanges)
    ".debug_rnglists" => Some(DwarfRnglists)
    ".debug_loclists" => Some(DwarfLoclists)
    ".debug_loc" => Some(DwarfLoc)
    _ => None
  }
}

///|
fn dwarf_elf_parse_header(data : Bytes) -> Result[DwarfElfHeader, String] {
  if data.length() < 16 {
    return Err("truncated ELF header")
  }
  if data[0] != b'\x7f' || data[1] != b'E' || data[2] != b'L' || data[3] != b'F' {
    return Err("not an ELF file")
  }
  let class = match data[4].to_int() {
    1 => DwarfElf32
    2 => DwarfElf64
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
  let min_header_size = match class {
    DwarfElf32 => 52
    DwarfElf64 => 64
  }
  if data.length() < min_header_size {
    return Err("truncated ELF header")
  }
  let section_table_offset = match class {
    DwarfElf32 =>
      dwarf_elf_read_int(data, 32, 4, endian, "ELF section table offset")
    DwarfElf64 =>
      dwarf_elf_read_int(data, 40, 8, endian, "ELF section table offset")
  }
  let section_header_size = match class {
    DwarfElf32 =>
      dwarf_elf_read_int(data, 46, 2, endian, "ELF section header size")
    DwarfElf64 =>
      dwarf_elf_read_int(data, 58, 2, endian, "ELF section header size")
  }
  let section_count = match class {
    DwarfElf32 => dwarf_elf_read_int(data, 48, 2, endian, "ELF section count")
    DwarfElf64 => dwarf_elf_read_int(data, 60, 2, endian, "ELF section count")
  }
  let section_name_index = match class {
    DwarfElf32 =>
      dwarf_elf_read_int(data, 50, 2, endian, "ELF section name table index")
    DwarfElf64 =>
      dwarf_elf_read_int(data, 62, 2, endian, "ELF section name table index")
  }
  match
    (
      section_table_offset, section_header_size, section_count, section_name_index,
    ) {
    (
      Ok(section_table_offset),
      Ok(section_header_size),
      Ok(raw_section_count),
      Ok(raw_section_name_index),
    ) => {
      if section_table_offset == 0 {
        return Err("ELF file has no section table")
      }
      let section_zero = if raw_section_count == 0 ||
        raw_section_name_index == 0xffff {
        match
          dwarf_elf_parse_section_zero(
            data, class, endian, section_table_offset, section_header_size,
          ) {
          Ok(value) => Some(value)
          Err(reason) => return Err(reason)
        }
      } else {
        None
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
      if section_count == 0 {
        return Err("ELF file has no section table")
      }
      if section_name_index < 0 || section_name_index >= section_count {
        return Err("ELF section name table index is out of bounds")
      }
      let minimum_section_header = dwarf_elf_minimum_section_header(class)
      if section_header_size < minimum_section_header {
        return Err("ELF section headers are too small")
      }
      let table_offset64 = section_table_offset.to_uint64()
      let table_size64 = section_header_size.to_uint64() *
        section_count.to_uint64()
      let data_size64 = data.length().to_uint64()
      if table_offset64 > data_size64 ||
        table_size64 > data_size64 - table_offset64 {
        return Err("ELF section table is out of bounds")
      }
      Ok({
        endian,
        class,
        section_table_offset,
        section_header_size,
        section_count,
        section_name_index,
      })
    }
    (Err(reason), _, _, _)
    | (_, Err(reason), _, _)
    | (_, _, Err(reason), _)
    | (_, _, _, Err(reason)) => Err(reason)
  }
}

///|
fn dwarf_elf_parse_section_header(
  data : Bytes,
  header : DwarfElfHeader,
  index : Int,
) -> Result[DwarfElfSectionHeader, String] {
  let base = header.section_table_offset + index * header.section_header_size
  let name_offset = dwarf_elf_read_int(
    data,
    base,
    4,
    header.endian,
    "ELF section name offset",
  )
  let file_offset = match header.class {
    DwarfElf32 =>
      dwarf_elf_read_int(
        data,
        base + 16,
        4,
        header.endian,
        "ELF section offset",
      )
    DwarfElf64 =>
      dwarf_elf_read_int(
        data,
        base + 24,
        8,
        header.endian,
        "ELF section offset",
      )
  }
  let size = match header.class {
    DwarfElf32 =>
      dwarf_elf_read_int(data, base + 20, 4, header.endian, "ELF section size")
    DwarfElf64 =>
      dwarf_elf_read_int(data, base + 32, 8, header.endian, "ELF section size")
  }
  match (name_offset, file_offset, size) {
    (Ok(name_offset), Ok(file_offset), Ok(size)) =>
      Ok({ name_offset, file_offset, size })
    (Err(reason), _, _) | (_, Err(reason), _) | (_, _, Err(reason)) =>
      Err(reason)
  }
}

///|
fn dwarf_elf_section_data(
  data : Bytes,
  section : DwarfElfSectionHeader,
) -> Result[Bytes, String] {
  if section.file_offset < 0 || section.size < 0 {
    return Err("ELF section range is invalid")
  }
  let start64 = section.file_offset.to_uint64()
  let size64 = section.size.to_uint64()
  let data_size64 = data.length().to_uint64()
  if start64 > data_size64 || size64 > data_size64 - start64 {
    return Err("ELF section range is out of bounds")
  }
  Ok(data[section.file_offset:section.file_offset + section.size].to_owned())
}

///|
fn dwarf_elf_section_name(
  names : Bytes,
  offset : Int,
) -> Result[String, String] {
  if offset < 0 || offset >= names.length() {
    return Err("ELF section name offset is out of bounds")
  }
  let mut end = offset
  while end < names.length() && names[end] != b'\x00' {
    end = end + 1
  }
  if end >= names.length() {
    return Err("ELF section name is not null-terminated")
  }
  try @utf8.decode(names[offset:end]) catch {
    _ => Err("ELF section name is not valid UTF-8")
  } noraise {
    name => Ok(name)
  }
}

///|
pub fn DwarfData::from_elf_bytes(data : Bytes) -> Result[DwarfData, String] {
  match dwarf_elf_parse_header(data) {
    Ok(header) => {
      let section_headers : Array[DwarfElfSectionHeader] = []
      for i in 0..<header.section_count {
        match dwarf_elf_parse_section_header(data, header, i) {
          Ok(section_header) => section_headers.push(section_header)
          Err(reason) => return Err(reason)
        }
      }
      let names = match
        dwarf_elf_section_data(data, section_headers[header.section_name_index]) {
        Ok(names) => names
        Err(reason) => return Err(reason)
      }
      let mut info : Bytes? = None
      let mut abbrev : Bytes? = None
      let mut str : Bytes? = None
      let mut line_str : Bytes? = None
      let mut str_offsets : Bytes? = None
      let mut addr : Bytes? = None
      let mut ranges : Bytes? = None
      let mut rnglists : Bytes? = None
      let mut loclists : Bytes? = None
      let mut loc : Bytes? = None
      for section_header in section_headers {
        match dwarf_elf_section_name(names, section_header.name_offset) {
          Ok(name) =>
            match dwarf_elf_section_of_name(name) {
              Some(DwarfInfo) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => info = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfAbbrev) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => abbrev = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfStr) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => str = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfLineStr) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => line_str = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfStrOffsets) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => str_offsets = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfAddr) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => addr = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfRanges) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => ranges = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfRnglists) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => rnglists = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfLoclists) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => loclists = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              Some(DwarfLoc) =>
                match dwarf_elf_section_data(data, section_header) {
                  Ok(bytes) => loc = Some(bytes)
                  Err(reason) => return Err(reason)
                }
              None => ()
            }
          Err(reason) => return Err(reason)
        }
      }
      DwarfData::from_bytes(
        endian=header.endian,
        info?,
        abbrev?,
        str?,
        line_str?,
        str_offsets?,
        addr?,
        ranges?,
        rnglists?,
        loclists?,
        loc?,
      )
    }
    Err(reason) => Err(reason)
  }
}
