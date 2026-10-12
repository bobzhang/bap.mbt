///|
fn expect_elf_data(
  value : Result[@dwarf.DwarfData, String],
) -> @dwarf.DwarfData raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_elf_section(
  value : Result[@dwarf.DwarfSectionBuffer, String],
) -> @dwarf.DwarfSectionBuffer raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_elf_functions(
  value : Result[Array[@dwarf.DwarfFunction], String],
) -> Array[@dwarf.DwarfFunction] raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn elf_test_set_u16_le(
  buffer : Array[Byte],
  offset : Int32,
  value : Int32,
) -> Unit {
  buffer[offset] = (value & 0xff).to_byte()
  buffer[offset + 1] = ((value >> 8) & 0xff).to_byte()
}

///|
fn elf_test_set_u32_le(
  buffer : Array[Byte],
  offset : Int32,
  value : Int32,
) -> Unit {
  for i in 0..<4 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xff).to_byte()
  }
}

///|
fn elf_test_set_u64_le(
  buffer : Array[Byte],
  offset : Int32,
  value : UInt64,
) -> Unit {
  for i in 0..<8 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xffUL).to_int().to_byte()
  }
}

///|
fn elf_test_set_u16_be(
  buffer : Array[Byte],
  offset : Int32,
  value : Int32,
) -> Unit {
  buffer[offset] = ((value >> 8) & 0xff).to_byte()
  buffer[offset + 1] = (value & 0xff).to_byte()
}

///|
fn elf_test_set_u32_be(
  buffer : Array[Byte],
  offset : Int32,
  value : Int32,
) -> Unit {
  for i in 0..<4 {
    buffer[offset + i] = ((value >> ((3 - i) * 8)) & 0xff).to_byte()
  }
}

///|
fn elf_test_write_bytes(
  buffer : Array[Byte],
  offset : Int32,
  data : Bytes,
) -> Unit {
  for i in 0..<data.length() {
    buffer[offset + i] = data[i]
  }
}

///|
fn elf_test_write_section32_be(
  buffer : Array[Byte],
  index : Int32,
  name_offset : Int32,
  typ : Int32,
  file_offset : Int32,
  size : Int32,
) -> Unit {
  let base = 52 + index * 40
  elf_test_set_u32_be(buffer, base, name_offset)
  elf_test_set_u32_be(buffer, base + 4, typ)
  elf_test_set_u32_be(buffer, base + 16, file_offset)
  elf_test_set_u32_be(buffer, base + 20, size)
}

///|
fn elf_test_write_section64(
  buffer : Array[Byte],
  index : Int32,
  name_offset : Int32,
  typ : Int32,
  file_offset : Int32,
  size : Int32,
) -> Unit {
  let base = 64 + index * 64
  elf_test_set_u32_le(buffer, base, name_offset)
  elf_test_set_u32_le(buffer, base + 4, typ)
  elf_test_set_u64_le(buffer, base + 24, file_offset.to_uint64())
  elf_test_set_u64_le(buffer, base + 32, size.to_uint64())
}

///|
fn elf_test_make_elf32_be_debug(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00"
  let data_offset = 52 + 5 * 40
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let total = str_offset + str.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x01'
  buffer[5] = b'\x02'
  buffer[6] = b'\x01'
  elf_test_set_u16_be(buffer, 16, 1)
  elf_test_set_u16_be(buffer, 18, 0x14)
  elf_test_set_u32_be(buffer, 20, 1)
  elf_test_set_u32_be(buffer, 32, 52)
  elf_test_set_u16_be(buffer, 40, 52)
  elf_test_set_u16_be(buffer, 46, 40)
  elf_test_set_u16_be(buffer, 48, 5)
  elf_test_set_u16_be(buffer, 50, 1)
  elf_test_write_section32_be(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section32_be(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section32_be(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section32_be(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00"
  let data_offset = 64 + 5 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let total = str_offset + str.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 5)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_extended_tables(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
) -> Bytes {
  let source = elf_test_make_elf64_debug(info, abbrev, str)
  let buffer = Array::make(source.length(), b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  elf_test_set_u16_le(buffer, 60, 0)
  elf_test_set_u16_le(buffer, 62, 0xffff)
  elf_test_set_u64_le(buffer, 64 + 32, 5UL)
  elf_test_set_u32_le(buffer, 64 + 40, 1)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_str_offsets(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  str_offsets : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_str_offsets\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let str_offsets_offset = str_offset + str.length()
  let total = str_offsets_offset + str_offsets.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(
    buffer,
    5,
    48,
    1,
    str_offsets_offset,
    str_offsets.length(),
  )
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, str_offsets_offset, str_offsets)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_line_str(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  line_str : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_line_str\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let line_str_offset = str_offset + str.length()
  let total = line_str_offset + line_str.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, line_str_offset, line_str.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, line_str_offset, line_str)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_ranges(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  ranges : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_ranges\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let ranges_offset = str_offset + str.length()
  let total = ranges_offset + ranges.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, ranges_offset, ranges.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, ranges_offset, ranges)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_rnglists(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  rnglists : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_rnglists\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let rnglists_offset = str_offset + str.length()
  let total = rnglists_offset + rnglists.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, rnglists_offset, rnglists.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, rnglists_offset, rnglists)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_loclists(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  loclists : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_loclists\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let loclists_offset = str_offset + str.length()
  let total = loclists_offset + loclists.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, loclists_offset, loclists.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, loclists_offset, loclists)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_loc(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  loc : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_loc\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let loc_offset = str_offset + str.length()
  let total = loc_offset + loc.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, loc_offset, loc.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, loc_offset, loc)
  Bytes::from_array(buffer)
}

///|
fn elf_test_make_elf64_debug_with_addr(
  info : Bytes,
  abbrev : Bytes,
  str : Bytes,
  addr : Bytes,
) -> Bytes {
  let shstr = b"\x00.shstrtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_addr\x00"
  let data_offset = 64 + 6 * 64
  let shstr_offset = data_offset
  let info_offset = shstr_offset + shstr.length()
  let abbrev_offset = info_offset + info.length()
  let str_offset = abbrev_offset + abbrev.length()
  let addr_offset = str_offset + str.length()
  let total = addr_offset + addr.length()
  let buffer = Array::make(total, b'\x00')
  elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  elf_test_set_u16_le(buffer, 16, 1)
  elf_test_set_u16_le(buffer, 18, 0x3e)
  elf_test_set_u32_le(buffer, 20, 1)
  elf_test_set_u64_le(buffer, 40, 64UL)
  elf_test_set_u16_le(buffer, 52, 64)
  elf_test_set_u16_le(buffer, 58, 64)
  elf_test_set_u16_le(buffer, 60, 6)
  elf_test_set_u16_le(buffer, 62, 1)
  elf_test_write_section64(buffer, 1, 1, 3, shstr_offset, shstr.length())
  elf_test_write_section64(buffer, 2, 11, 1, info_offset, info.length())
  elf_test_write_section64(buffer, 3, 23, 1, abbrev_offset, abbrev.length())
  elf_test_write_section64(buffer, 4, 37, 1, str_offset, str.length())
  elf_test_write_section64(buffer, 5, 48, 1, addr_offset, addr.length())
  elf_test_write_bytes(buffer, shstr_offset, shstr)
  elf_test_write_bytes(buffer, info_offset, info)
  elf_test_write_bytes(buffer, abbrev_offset, abbrev)
  elf_test_write_bytes(buffer, str_offset, str)
  elf_test_write_bytes(buffer, addr_offset, addr)
  Bytes::from_array(buffer)
}

///|
test "translated DWARF data extracts debug sections from ELF32 big-endian" {
  let info = b"be-info"
  let abbrev = b"be-abbrev"
  let str = b"be-names\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf32_be_debug(info, abbrev, str),
    ),
  )
  assert_true(data.endian() == BigEndian)
  assert_true(expect_elf_section(data.section(DwarfInfo)).data() == info)
  assert_true(expect_elf_section(data.section(DwarfAbbrev)).data() == abbrev)
  assert_true(expect_elf_section(data.section(DwarfStr)).data() == str)
}

///|
test "translated DWARF data extracts debug sections from ELF64" {
  let info = b"info"
  let abbrev = b"abbrev"
  let str = b"names\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug(info, abbrev, str),
    ),
  )
  assert_true(data.endian() == LittleEndian)
  assert_true(expect_elf_section(data.section(DwarfInfo)).data() == info)
  assert_true(expect_elf_section(data.section(DwarfAbbrev)).data() == abbrev)
  assert_true(expect_elf_section(data.section(DwarfStr)).data() == str)
}

///|
test "translated DWARF data handles ELF extended section tables" {
  let info = b"info"
  let abbrev = b"abbrev"
  let str = b"names\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_extended_tables(info, abbrev, str),
    ),
  )
  assert_true(data.endian() == LittleEndian)
  assert_true(expect_elf_section(data.section(DwarfInfo)).data() == info)
  assert_true(expect_elf_section(data.section(DwarfAbbrev)).data() == abbrev)
  assert_true(expect_elf_section(data.section(DwarfStr)).data() == str)
}

///|
test "translated DWARF FBI reads ranges from ELF debug sections" {
  let abbrev = b"\x01\x11\x01" +
    b"\x11\x01" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x17" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x19\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"\x00\x40\x00\x00" +
    b"\x02" +
    b"elfrng\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00"
  let ranges = b"\x02\x00\x00\x00" +
    b"\x08\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00\x00\x00\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_ranges(info, abbrev, b"", ranges),
    ),
  )
  assert_true(expect_elf_section(data.section(DwarfRanges)).data() == ranges)
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "elfrng")
  assert_true(functions[0].low_pc() == 0x4002UL)
  assert_true(functions[0].high_pc() == Some(0x4008UL))
}

///|
test "translated DWARF FBI reads rnglists from ELF debug sections" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x17" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x14\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"elfv5\x00" +
    b"\x0c\x00\x00\x00" +
    b"\x00"
  let rnglists = b"\x12\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x00\x00\x00\x00" +
    b"\x06" +
    b"\x70\x00\x00\x00" +
    b"\x78\x00\x00\x00" +
    b"\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_rnglists(info, abbrev, b"", rnglists),
    ),
  )
  assert_true(
    expect_elf_section(data.section(DwarfRnglists)).data() == rnglists,
  )
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "elfv5")
  assert_true(functions[0].low_pc() == 0x70UL)
  assert_true(functions[0].high_pc() == Some(0x78UL))
}

///|
test "translated DWARF data extracts loclists from ELF debug sections" {
  let info = b"info"
  let abbrev = b"abbrev"
  let loclists = b"\x0c\x00\x00\x00\x05\x00\x04\x00\x00\x00\x00\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_loclists(info, abbrev, b"", loclists),
    ),
  )
  assert_true(expect_elf_section(data.section(DwarfInfo)).data() == info)
  assert_true(expect_elf_section(data.section(DwarfAbbrev)).data() == abbrev)
  assert_true(
    expect_elf_section(data.section(DwarfLoclists)).data() == loclists,
  )
}

///|
test "translated DWARF data extracts DWARF4 loc from ELF debug sections" {
  let info = b"info"
  let abbrev = b"abbrev"
  let loc = b"\x10\x00\x00\x00\x18\x00\x00\x00\x01\x00\x50" +
    b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_loc(info, abbrev, b"", loc),
    ),
  )
  assert_true(expect_elf_section(data.section(DwarfInfo)).data() == info)
  assert_true(expect_elf_section(data.section(DwarfAbbrev)).data() == abbrev)
  assert_true(expect_elf_section(data.section(DwarfLoc)).data() == loc)
  let list = expect_location_list(data.loc(addr_size=W32))
  assert_true(list.entries() == [DwarfLocOffsetPair(0x10, 0x18, b"\x50")])
}

///|
test "translated DWARF FBI reads addr table from ELF debug sections" {
  let abbrev = b"\x01\x11\x01" +
    b"\x73\x17" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x11\x29" +
    b"\x12\x29" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x19\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x08\x00\x00\x00" +
    b"\x02" +
    b"elfaddr\x00" +
    b"\x00" +
    b"\x01" +
    b"\x00"
  let addr = b"\x0c\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\xb0\x00\x00\x00" +
    b"\xba\x00\x00\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_addr(info, abbrev, b"", addr),
    ),
  )
  assert_true(expect_elf_section(data.section(DwarfAddr)).data() == addr)
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "elfaddr")
  assert_true(functions[0].low_pc() == 0xb0UL)
  assert_true(functions[0].high_pc() == Some(0xbaUL))
}

///|
test "translated DWARF FBI reads indexed strings from ELF debug sections" {
  let abbrev = b"\x01\x11\x01" +
    b"\x72\x17" +
    b"\x03\x25" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x25" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x16\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x04\x00\x00\x00" +
    b"\x00" +
    b"\x02" +
    b"\x00" +
    b"\xa0\x00\x00\x00" +
    b"\x04" +
    b"\x00"
  let str = b"skip\x00elfx\x00"
  let str_offsets = b"\x00\x00\x00\x00\x05\x00\x00\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_str_offsets(info, abbrev, str, str_offsets),
    ),
  )
  assert_true(
    expect_elf_section(data.section(DwarfStrOffsets)).data() == str_offsets,
  )
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "elfx")
  assert_true(functions[0].low_pc() == 0xa0UL)
  assert_true(functions[0].high_pc() == Some(0xa4UL))
}

///|
test "translated DWARF FBI reads line strings from ELF debug sections" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x1f" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x13\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x05\x00\x00\x00" +
    b"\x44\x00\x00\x00" +
    b"\x08" +
    b"\x00"
  let line_str = b"skip\x00elfline\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug_with_line_str(info, abbrev, b"", line_str),
    ),
  )
  assert_true(expect_elf_section(data.section(DwarfLineStr)).data() == line_str)
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "elfline")
  assert_true(functions[0].low_pc() == 0x44UL)
  assert_true(functions[0].high_pc() == Some(0x4cUL))
}

///|
test "translated DWARF FBI reads function data from ELF debug sections" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x13\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"main\x00" +
    b"\x10\x00\x00\x00" +
    b"\x05" +
    b"\x00"
  let data = expect_elf_data(
    @dwarf.DwarfData::from_elf_bytes(
      elf_test_make_elf64_debug(info, abbrev, b""),
    ),
  )
  let functions = expect_elf_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "main")
  assert_true(functions[0].low_pc() == 0x10UL)
  assert_true(functions[0].high_pc() == Some(0x15UL))
}

///|
test "translated DWARF ELF extraction rejects invalid inputs" {
  assert_true(@dwarf.DwarfData::from_elf_bytes(b"not elf") is Err(_))
  let truncated = b"\x7fELF\x02\x01\x01"
  assert_true(@dwarf.DwarfData::from_elf_bytes(truncated) is Err(_))
}
