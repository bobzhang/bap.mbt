///|
priv enum ImageElfClass {
  ImageElf32
  ImageElf64
}

///|
priv struct ImageElfHeader {
  endian : @bitvec.Endian
  class : ImageElfClass
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
  addr : UInt64
  offset : Int
  size : Int
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
  let min_header_size = match class {
    ImageElf32 => 52
    ImageElf64 => 64
  }
  if data.length() < min_header_size {
    return Err("truncated ELF header")
  }
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
      machine, entry, program_table_offset, program_header_size, program_count, section_table_offset,
      section_header_size, section_count, section_name_index,
    ) {
    (
      Ok(machine),
      Ok(entry),
      Ok(program_table_offset),
      Ok(program_header_size),
      Ok(program_count),
      Ok(section_table_offset),
      Ok(section_header_size),
      Ok(section_count),
      Ok(section_name_index),
    ) => {
      if program_count == 0xffff ||
        section_count == 0 ||
        section_name_index == 0xffff {
        return Err("extended ELF tables are not supported")
      }
      if section_name_index < 0 || section_name_index >= section_count {
        return Err("ELF section name table index is out of bounds")
      }
      let minimum_program_header = match class {
        ImageElf32 => 32
        ImageElf64 => 56
      }
      let minimum_section_header = match class {
        ImageElf32 => 40
        ImageElf64 => 64
      }
      if program_header_size < minimum_program_header {
        return Err("ELF program headers are too small")
      }
      if section_header_size < minimum_section_header {
        return Err("ELF section headers are too small")
      }
      match
        image_elf_check_table(
          data, program_table_offset, program_header_size, program_count, "ELF program table",
        ) {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      match
        image_elf_check_table(
          data, section_table_offset, section_header_size, section_count, "ELF section table",
        ) {
        Ok(_) =>
          Ok({
            endian,
            class,
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
        Err(reason) => Err(reason)
      }
    }
    (Err(reason), _, _, _, _, _, _, _, _)
    | (_, Err(reason), _, _, _, _, _, _, _)
    | (_, _, Err(reason), _, _, _, _, _, _)
    | (_, _, _, Err(reason), _, _, _, _, _)
    | (_, _, _, _, Err(reason), _, _, _, _)
    | (_, _, _, _, _, Err(reason), _, _, _)
    | (_, _, _, _, _, _, Err(reason), _, _)
    | (_, _, _, _, _, _, _, Err(reason), _)
    | (_, _, _, _, _, _, _, _, Err(reason)) => Err(reason)
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
  match (name_offset, addr, offset, size) {
    (Ok(name_offset), Ok(addr), Ok(offset), Ok(size)) =>
      Ok({ name_offset, addr, offset, size })
    (Err(reason), _, _, _)
    | (_, Err(reason), _, _)
    | (_, _, Err(reason), _)
    | (_, _, _, Err(reason)) => Err(reason)
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
fn image_elf_target_endian(endian : @bitvec.Endian) -> @core_theory.Endianness {
  match endian {
    LittleEndian => LittleEndian
    BigEndian => BigEndian
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
  base
  .with_endianness(image_elf_target_endian(header.endian))
  .with_filetype(Elf)
}

///|
fn image_elf_flag_set(flags : Int, flag : Int) -> Bool {
  (flags & flag) != 0
}

///|
fn image_elf_load(data : Bytes) -> Result[(Image, Array[String]), String] {
  match image_elf_parse_header(data) {
    Ok(header) => {
      let section_headers : Array[ImageElfSectionHeader] = []
      for i in 0..<header.section_count {
        match image_elf_parse_section_header(data, header, i) {
          Ok(section_header) => section_headers.push(section_header)
          Err(reason) => return Err(reason)
        }
      }
      let section_names = match section_headers.get(header.section_name_index) {
        Some(section) =>
          image_elf_section_data(data, section.offset, section.size)
        None => Err("ELF section name table index is out of bounds")
      }
      let mut names = b""
      match section_names {
        Ok(value) => names = value
        Err(reason) => return Err(reason)
      }
      let sections : Array[Section] = []
      for section in section_headers {
        match image_elf_cstring(names, section.name_offset) {
          Ok(name) =>
            if name.length() > 0 && section.size > 0 {
              sections.push(
                Section::create(name~, addr=section.addr, size=section.size),
              )
            }
          Err(reason) => return Err(reason)
        }
      }
      let segments : Array[Segment] = []
      for i in 0..<header.program_count {
        match image_elf_parse_program_header(data, header, i) {
          Ok(program) =>
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
          Err(reason) => return Err(reason)
        }
      }
      if segments.is_empty() {
        return Err("ELF file has no loadable segments")
      }
      Ok(
        (
          Image::from_segments(
            entry=header.entry,
            endian=header.endian,
            segments,
            sections~,
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
