///|
fn expect_section_buffer(
  value : Result[@dwarf.DwarfSectionBuffer, String],
) -> @dwarf.DwarfSectionBuffer raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_dwarf_data(
  value : Result[@dwarf.DwarfData, String],
) -> @dwarf.DwarfData raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn data_expect_abbrev_table(
  value : Result[@dwarf.DwarfAbbrevTable, String],
) -> @dwarf.DwarfAbbrevTable raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn data_expect_abbrev_entry(
  value : @dwarf.DwarfAbbrevEntry?,
) -> @dwarf.DwarfAbbrevEntry raise {
  match value {
    Some(value) => value
    None => fail("expected abbreviation entry")
  }
}

///|
fn expect_location_list(
  value : Result[@dwarf.DwarfLocationList, String],
) -> @dwarf.DwarfLocationList raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_range_list(
  value : Result[@dwarf.DwarfRangeList, String],
) -> @dwarf.DwarfRangeList raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_address_table(
  value : Result[@dwarf.DwarfAddressTable, String],
) -> @dwarf.DwarfAddressTable raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_string_offsets_table(
  value : Result[@dwarf.DwarfStringOffsetsTable, String],
) -> @dwarf.DwarfStringOffsetsTable raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_string_table(
  value : Result[@dwarf.DwarfStringTable, String],
) -> @dwarf.DwarfStringTable raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_unit_header(
  value : Result[@dwarf.DwarfInfoUnitHeader, String],
) -> @dwarf.DwarfInfoUnitHeader raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_unit_headers(
  value : Result[Array[@dwarf.DwarfInfoUnitHeader], String],
) -> Array[@dwarf.DwarfInfoUnitHeader] raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_dies(
  value : Result[Array[@dwarf.DwarfDie], String],
) -> Array[@dwarf.DwarfDie] raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
test "translated DWARF section data stores buffers by section" {
  let info = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"info"))
  let abbrev = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(b"abbrev", position=2),
  )
  let data = expect_dwarf_data(
    @dwarf.DwarfData::create(endian=BigEndian, sections=[
      (DwarfInfo, info),
      (DwarfAbbrev, abbrev),
    ]),
  )
  assert_true(data.endian() == BigEndian)
  assert_true(data.sections().length() == 2)
  assert_true(data.has_section(DwarfInfo))
  assert_true(!data.has_section(DwarfStr))
  let got_info = expect_section_buffer(data.section(DwarfInfo))
  assert_true(got_info.data() == b"info")
  assert_true(got_info.position() == 0)
  let got_abbrev = expect_section_buffer(data.section(DwarfAbbrev))
  assert_true(got_abbrev.data() == b"abbrev")
  assert_true(got_abbrev.position() == 2)
  assert_true(data.section(DwarfStr) is Err(_))
}

///|
test "translated DWARF data exposes abbreviation tables" {
  let abbrev_bytes = b"pad" +
    b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x00\x00" +
    b"\x00"
  let section = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(abbrev_bytes, position=3),
  )
  let data = expect_dwarf_data(
    @dwarf.DwarfData::create(endian=LittleEndian, sections=[
      (DwarfAbbrev, section),
    ]),
  )
  let table = data_expect_abbrev_table(data.abbrev_table())
  let entry = data_expect_abbrev_entry(table.lookup(1))
  assert_true(entry.tag() == DwarfSubprogram)
  assert_true(entry.fields().length() == 1)
  assert_true(entry.fields()[0].attr() == DwarfName)
  assert_true(entry.fields()[0].form() == DwarfString)
  let offset_data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, abbrev=abbrev_bytes),
  )
  let offset_table = data_expect_abbrev_table(
    offset_data.abbrev_table(offset=3),
  )
  assert_true(offset_table.lookup(1) is Some(_))
  let without_abbrev = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info=b"\x00"),
  )
  assert_true(without_abbrev.abbrev_table() is Err(_))
}

///|
test "translated DWARF section buffers read DWARF unit headers" {
  let legacy_info = b"\x08\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\xaa"
  let legacy_header = expect_unit_header(
    @dwarf.DwarfInfoUnitHeader::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(legacy_info)),
      endian=LittleEndian,
    ),
  )
  assert_true(legacy_header.kind() == DwarfInfoUnitLegacy)
  assert_true(legacy_header.unit_type() == None)
  assert_true(legacy_header.version() == 4)
  assert_true(legacy_header.dwarf_size() == W32)
  assert_true(legacy_header.address_size() == W32)
  assert_true(legacy_header.abbrev_offset() == 0)
  assert_true(legacy_header.unit_size() == 8)
  assert_true(legacy_header.start_offset() == 0)
  assert_true(legacy_header.header_end_offset() == 11)
  assert_true(legacy_header.body_offset() == 11)
  assert_true(legacy_header.end_offset() == 12)
  assert_true(legacy_header.next_offset() == 12)
  assert_true(legacy_header.is_supported())
  let skeleton_info = b"\x11\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x7f\x06\x05\x04\x03\x02\x01\x00" +
    b"\x00"
  let skeleton_header = expect_unit_header(
    @dwarf.DwarfInfoUnitHeader::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(skeleton_info)),
      endian=LittleEndian,
    ),
  )
  assert_true(skeleton_header.kind() == DwarfInfoUnitSkeleton)
  assert_true(skeleton_header.unit_type() == Some(4))
  assert_true(skeleton_header.header_end_offset() == 20)
  assert_true(skeleton_header.body_offset() == 20)
  assert_true(skeleton_header.end_offset() == 21)
  assert_true(skeleton_header.is_supported())
  let type_info = b"\x15\x00\x00\x00" +
    b"\x05\x00" +
    b"\x02" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x7f\x06\x05\x04\x03\x02\x01\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00"
  let type_header = expect_unit_header(
    @dwarf.DwarfInfoUnitHeader::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(type_info)),
      endian=LittleEndian,
    ),
  )
  assert_true(type_header.kind() == DwarfInfoUnitType)
  assert_true(type_header.unit_type() == Some(2))
  assert_true(type_header.header_end_offset() == 24)
  assert_true(type_header.body_offset() == 24)
  assert_true(type_header.end_offset() == 25)
  let short_skeleton = b"\x0f\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x7f\x06\x05\x04\x03\x02\x01\x00"
  assert_true(
    @dwarf.DwarfInfoUnitHeader::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(short_skeleton)),
      endian=LittleEndian,
    )
    is Err(_),
  )
}

///|
test "translated DWARF data enumerates unit headers and padding" {
  let unsupported = b"\x09\x00\x00\x00" +
    b"\x05\x00" +
    b"\x7f" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\xaa"
  let legacy = b"\x08\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\xbb"
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info=unsupported + legacy + b"\x00\x00\x00",
    ),
  )
  let headers = expect_unit_headers(data.unit_headers())
  assert_true(headers.length() == 2)
  assert_true(headers[0].kind() == DwarfInfoUnitUnknown(0x7f))
  assert_true(headers[0].unit_type() == Some(0x7f))
  assert_true(!headers[0].is_supported())
  assert_true(headers[0].header_end_offset() == 12)
  assert_true(headers[0].end_offset() == 13)
  assert_true(headers[1].kind() == DwarfInfoUnitLegacy)
  assert_true(headers[1].start_offset() == 13)
  assert_true(headers[1].end_offset() == 25)
  let second = expect_unit_header(data.unit_header(offset=13))
  assert_true(second.kind() == DwarfInfoUnitLegacy)
  let without_info = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, str=b"x\x00"),
  )
  assert_true(without_info.unit_headers() is Err(_))
}

///|
test "translated DWARF data exposes structural DIE records" {
  let abbrev = b"\x01\x11\x01" +
    b"\x03\x08" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x11\x01" +
    b"\x12\x06" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x15\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01cu\x00" +
    b"\x02" +
    b"\x10\x00\x00\x00" +
    b"\x05\x00\x00\x00" +
    b"\x00"
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~),
  )
  let dies = expect_dies(data.unit_dies())
  assert_true(dies.length() == 2)
  assert_true(dies[0].section_offset() == 11)
  assert_true(dies[0].unit_offset() == 11)
  assert_true(dies[0].depth() == 0)
  assert_true(dies[0].code() == 1)
  assert_true(dies[0].tag() == DwarfCompileUnit)
  assert_true(dies[0].has_children())
  assert_true(dies[0].attributes_offset() == 12)
  assert_true(dies[0].end_offset() == 15)
  assert_true(dies[0].fields().length() == 1)
  assert_true(dies[1].section_offset() == 15)
  assert_true(dies[1].unit_offset() == 15)
  assert_true(dies[1].depth() == 1)
  assert_true(dies[1].code() == 2)
  assert_true(dies[1].tag() == DwarfSubprogram)
  assert_true(!dies[1].has_children())
  assert_true(dies[1].attributes_offset() == 16)
  assert_true(dies[1].end_offset() == 24)
  assert_true(dies[1].entry().fields().length() == 2)
  assert_true(expect_dies(data.dies()).length() == 2)
  let broken = b"\x08\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x7f"
  let broken_data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info=broken, abbrev~),
  )
  assert_true(broken_data.unit_dies() is Err(_))
}

///|
test "translated DWARF section buffers read string tables" {
  let buffer = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(b"skip\x00name\x00tail\x00"),
  )
  let table = expect_string_table(@dwarf.DwarfStringTable::read(buffer))
  assert_true(table.base_offset() == 0)
  assert_true(table.data() == b"skip\x00name\x00tail\x00")
  assert_true(!table.is_empty())
  assert_true(table.string(5) == Ok("name"))
  assert_true(table.entries() == Ok([(0, "skip"), (5, "name"), (10, "tail")]))
  assert_true(table.strings() == Ok(["skip", "name", "tail"]))
  let suffix = expect_string_table(
    @dwarf.DwarfStringTable::read(buffer, offset=5),
  )
  assert_true(suffix.base_offset() == 5)
  assert_true(suffix.string(0) == Ok("name"))
  assert_true(suffix.entries() == Ok([(0, "name"), (5, "tail")]))
  let broken = expect_string_table(
    @dwarf.DwarfStringTable::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"broken")),
    ),
  )
  assert_true(broken.entries() is Err(_))
}

///|
test "translated DWARF data exposes debug and line string tables" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      str=b"debug\x00other\x00",
      line_str=b"line\x00file.mbt\x00",
    ),
  )
  let strings = expect_string_table(data.string_table())
  let line_strings = expect_string_table(data.line_string_table())
  assert_true(strings.strings() == Ok(["debug", "other"]))
  assert_true(line_strings.strings() == Ok(["line", "file.mbt"]))
  assert_true(data.debug_string() == Ok("debug"))
  assert_true(data.debug_string(offset=6) == Ok("other"))
  assert_true(data.line_string() == Ok("line"))
  assert_true(data.line_string(offset=5) == Ok("file.mbt"))
  let without_strings = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info=b"\x00"),
  )
  assert_true(without_strings.string_table() is Err(_))
  assert_true(without_strings.line_string_table() is Err(_))
}

///|
test "translated DWARF section buffers read raw address tables" {
  let addr = b"\xff\x00" + b"\x20\x00\x00\x00" + b"\x2c\x00\x00\x00"
  let buffer = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(addr))
  let table = expect_address_table(
    @dwarf.DwarfAddressTable::read(
      buffer,
      offset=2,
      endian=LittleEndian,
      addr_size=W32,
    ),
  )
  assert_true(table.version() == None)
  assert_true(table.address_size() == W32)
  assert_true(table.base_offset() == 2)
  assert_true(table.length() == 2)
  assert_true(!table.is_empty())
  assert_true(table.addresses() == [0x20UL, 0x2cUL])
  assert_true(table.address(1) == Ok(0x2cUL))
  assert_true(table.address(-1) is Err(_))
  assert_true(table.address(2) is Err(_))
}

///|
test "translated DWARF section buffers read DWARF5 address table contributions" {
  let addr = b"\x0c\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x20\x00\x00\x00" +
    b"\x2c\x00\x00\x00"
  let buffer = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(addr))
  let table = expect_address_table(
    @dwarf.DwarfAddressTable::read_contribution(buffer, endian=LittleEndian),
  )
  assert_true(table.version() == Some(5))
  assert_true(table.address_size() == W32)
  assert_true(table.base_offset() == 8)
  assert_true(table.addresses() == [0x20UL, 0x2cUL])
  assert_true(
    @dwarf.DwarfAddressTable::read_contribution(
      expect_section_buffer(
        @dwarf.DwarfSectionBuffer::create(b"\x04\x00\x00\x00\x05\x00\x04\x01"),
      ),
      endian=LittleEndian,
    )
    is Err(_),
  )
}

///|
test "translated DWARF data exposes address table readers" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=BigEndian,
      addr=b"\xff\x00\x00\x00\x00\x20",
    ),
  )
  let raw = expect_address_table(data.address_table(offset=2, addr_size=W32))
  assert_true(raw.addresses() == [0x20UL])
  let without_addr = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=BigEndian, info=b"\x00"),
  )
  assert_true(without_addr.address_table(addr_size=W32) is Err(_))
  assert_true(without_addr.address_table_contribution() is Err(_))
}

///|
test "translated DWARF section buffers read raw string-offset tables" {
  let offsets = b"\xff\x00" + b"\x00\x00\x00\x00" + b"\x05\x00\x00\x00"
  let buffer = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(offsets))
  let table = expect_string_offsets_table(
    @dwarf.DwarfStringOffsetsTable::read(
      buffer,
      offset=2,
      endian=LittleEndian,
      dwarf_size=W32,
    ),
  )
  let strings = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(b"skip\x00name\x00"),
  )
  assert_true(table.version() == None)
  assert_true(table.dwarf_size() == W32)
  assert_true(table.base_offset() == 2)
  assert_true(table.length() == 2)
  assert_true(!table.is_empty())
  assert_true(table.offsets() == [0, 5])
  assert_true(table.offset(1) == Ok(5))
  assert_true(table.offset(-1) is Err(_))
  assert_true(table.offset(2) is Err(_))
  assert_true(table.strings(strings) == Ok(["skip", "name"]))
  assert_true(table.string(strings, 1) == Ok("name"))
}

///|
test "translated DWARF section buffers read DWARF5 string-offset contributions" {
  let offsets = b"\x0c\x00\x00\x00" +
    b"\x05\x00" +
    b"\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x05\x00\x00\x00"
  let buffer = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(offsets))
  let table = expect_string_offsets_table(
    @dwarf.DwarfStringOffsetsTable::read_contribution(
      buffer,
      endian=LittleEndian,
    ),
  )
  assert_true(table.version() == Some(5))
  assert_true(table.dwarf_size() == W32)
  assert_true(table.base_offset() == 8)
  assert_true(table.offsets() == [0, 5])
  assert_true(
    @dwarf.DwarfStringOffsetsTable::read_contribution(
      expect_section_buffer(
        @dwarf.DwarfSectionBuffer::create(b"\x04\x00\x00\x00\x05\x00\x01\x00"),
      ),
      endian=LittleEndian,
    )
    is Err(_),
  )
}

///|
test "translated DWARF data exposes string-offset table readers" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=BigEndian,
      str_offsets=b"\xff\x00\x00\x00\x00\x05",
    ),
  )
  let raw = expect_string_offsets_table(
    data.string_offsets(offset=2, dwarf_size=W32),
  )
  assert_true(raw.offsets() == [5])
  let without_offsets = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=BigEndian, info=b"\x00"),
  )
  assert_true(without_offsets.string_offsets(dwarf_size=W32) is Err(_))
  assert_true(without_offsets.string_offsets_contribution() is Err(_))
}

///|
test "translated DWARF section buffers read DWARF5 rnglists entries" {
  let rnglists = b"\x05\x00\x10\x00\x00" +
    b"\x04\x10\x18" +
    b"\x06\x00\x20\x00\x00\x04\x20\x00\x00" +
    b"\x07\x00\x30\x00\x00\x05" +
    b"\x01\x03" +
    b"\x02\x01\x02" +
    b"\x03\x04\x06" +
    b"\x00"
  let buffer = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(rnglists),
  )
  let list = expect_range_list(
    @dwarf.DwarfRangeList::read(buffer, endian=LittleEndian, addr_size=W32),
  )
  assert_true(list.length() == 7)
  assert_true(!list.is_empty())
  assert_true(
    list.entries() ==
    [
      DwarfRangeBaseAddress(0x1000UL),
      DwarfRangeOffsetPair(0x10, 0x18),
      DwarfRangeStartEnd(0x2000UL, 0x2004UL),
      DwarfRangeStartLength(0x3000UL, 5),
      DwarfRangeBaseAddressx(3),
      DwarfRangeStartxEndx(1, 2),
      DwarfRangeStartxLength(4, 6),
    ],
  )
  assert_true(
    @dwarf.DwarfRangeList::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"\x08")),
      endian=LittleEndian,
      addr_size=W32,
    )
    is Err(_),
  )
}

///|
test "translated DWARF section buffers read DWARF4 ranges entries" {
  let ranges = b"\xff\xff\xff\xff\x00\x10\x00\x00" +
    b"\x10\x00\x00\x00\x18\x00\x00\x00" +
    b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let buffer = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(ranges))
  let list = expect_range_list(
    @dwarf.DwarfRangeList::read_ranges(
      buffer,
      endian=LittleEndian,
      addr_size=W32,
    ),
  )
  assert_true(list.length() == 2)
  assert_true(!list.is_empty())
  assert_true(
    list.entries() ==
    [DwarfRangeBaseAddress(0x1000UL), DwarfRangeOffsetPair(0x10, 0x18)],
  )
}

///|
test "translated DWARF data exposes ranges section reader" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=BigEndian,
      ranges=b"\xff\x00\xff\xff\xff\xff\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    ),
  )
  let list = expect_range_list(data.ranges(offset=2, addr_size=W32))
  assert_true(list.entries() == [DwarfRangeBaseAddress(0x2000UL)])
  let without_ranges = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=BigEndian, info=b"\x00"),
  )
  assert_true(without_ranges.ranges(addr_size=W32) is Err(_))
}

///|
test "translated DWARF data exposes rnglists section reader" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=BigEndian,
      rnglists=b"\xff\x00\x05\x00\x00\x20\x00\x00",
    ),
  )
  let list = expect_range_list(data.rnglist(offset=2, addr_size=W32))
  assert_true(list.entries() == [DwarfRangeBaseAddress(0x2000UL)])
  let without_rnglists = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=BigEndian, info=b"\x00"),
  )
  assert_true(without_rnglists.rnglist(addr_size=W32) is Err(_))
}

///|
test "translated DWARF section buffers read DWARF5 loclists entries" {
  let loclists = b"\x06\x00\x10\x00\x00" +
    b"\x04\x10\x18\x02\x91\x01" +
    b"\x07\x00\x20\x00\x00\x04\x20\x00\x00\x01\x50" +
    b"\x08\x00\x30\x00\x00\x05\x00" +
    b"\x05\x01\x9f" +
    b"\x01\x03" +
    b"\x02\x01\x02\x01\xaa" +
    b"\x03\x04\x06\x01\xbb" +
    b"\x00"
  let buffer = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(loclists),
  )
  let list = expect_location_list(
    @dwarf.DwarfLocationList::read(buffer, endian=LittleEndian, addr_size=W32),
  )
  assert_true(list.length() == 8)
  assert_true(!list.is_empty())
  assert_true(
    list.entries() ==
    [
      DwarfLocBaseAddress(0x1000UL),
      DwarfLocOffsetPair(0x10, 0x18, b"\x91\x01"),
      DwarfLocStartEnd(0x2000UL, 0x2004UL, b"\x50"),
      DwarfLocStartLength(0x3000UL, 5, b""),
      DwarfLocDefaultLocation(b"\x9f"),
      DwarfLocBaseAddressx(3),
      DwarfLocStartxEndx(1, 2, b"\xaa"),
      DwarfLocStartxLength(4, 6, b"\xbb"),
    ],
  )
  assert_true(
    @dwarf.DwarfLocationList::read(
      expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"\x09")),
      endian=LittleEndian,
      addr_size=W32,
    )
    is Err(_),
  )
}

///|
test "translated DWARF data exposes loclists section reader" {
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=BigEndian,
      loclists=b"\xff\x00\x06\x00\x00\x20\x00\x00",
    ),
  )
  let list = expect_location_list(data.loclist(offset=2, addr_size=W32))
  assert_true(list.entries() == [DwarfLocBaseAddress(0x2000UL)])
  let without_loclists = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(endian=BigEndian, info=b"\x00"),
  )
  assert_true(without_loclists.loclist(addr_size=W32) is Err(_))
}

///|
test "translated DWARF section source aliases select core sections" {
  let info = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"i"))
  let abbrev = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"a"))
  let str = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"s"))
  let data = expect_dwarf_data(
    @dwarf.DwarfData::create(endian=LittleEndian, sections=[
      (@dwarf.DwarfSection::info(), info),
      (@dwarf.DwarfSection::abbrev(), abbrev),
      (@dwarf.DwarfSection::str(), str),
    ]),
  )
  assert_true(@dwarf.DwarfSection::info() == DwarfInfo)
  assert_true(@dwarf.DwarfSection::abbrev() == DwarfAbbrev)
  assert_true(@dwarf.DwarfSection::str() == DwarfStr)
  assert_true(expect_section_buffer(data.section(DwarfInfo)).data() == b"i")
  assert_true(expect_section_buffer(data.section(DwarfAbbrev)).data() == b"a")
  assert_true(expect_section_buffer(data.section(DwarfStr)).data() == b"s")
}

///|
test "translated DWARF section buffers create inputs at stored positions" {
  let buffer = expect_section_buffer(
    @dwarf.DwarfSectionBuffer::create(b"\x00\x00\x2e", position=2),
  )
  let input = buffer.input()
  let (tag, input) = match input.read_tag() {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
  assert_true(tag == DwarfSubprogram)
  assert_true(input.position() == 3)
  let moved = expect_section_buffer(buffer.offset(-1))
  assert_true(moved.position() == 1)
  assert_true(moved.pos() == 1)
  assert_true(expect_section_buffer(buffer.with_off(-1)).pos() == 1)
  assert_true(expect_section_buffer(buffer.with_pos(3)).pos() == 3)
  assert_true(buffer.with_position(4) is Err(_))
  assert_true(buffer.with_pos(4) is Err(_))
  assert_true(@dwarf.DwarfSectionBuffer::create(b"x", position=-1) is Err(_))
}

///|
test "translated DWARF section data rejects duplicates and builds from bytes" {
  let info = expect_section_buffer(@dwarf.DwarfSectionBuffer::create(b"i"))
  assert_true(
    @dwarf.DwarfData::create(endian=LittleEndian, sections=[
      (DwarfInfo, info),
      (DwarfInfo, info),
    ])
    is Err(_),
  )
  let data = expect_dwarf_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info=b"info",
      abbrev=b"abbrev",
      str=b"names\x00",
      line_str=b"line-names\x00",
      str_offsets=b"\x00\x00\x00\x00",
      addr=b"\x00\x00\x00\x00\x05\x00\x04\x00",
      ranges=b"\x00\x00\x00\x00\x00\x00\x00\x00",
      rnglists=b"\x00",
      loclists=b"\x01\x00",
    ),
  )
  assert_true(data.has_section(DwarfInfo))
  assert_true(data.has_section(DwarfAbbrev))
  assert_true(data.has_section(DwarfStr))
  assert_true(data.has_section(DwarfLineStr))
  assert_true(data.has_section(DwarfStrOffsets))
  assert_true(data.has_section(DwarfAddr))
  assert_true(data.has_section(DwarfRanges))
  assert_true(data.has_section(DwarfRnglists))
  assert_true(data.has_section(DwarfLoclists))
  assert_true(
    expect_section_buffer(data.section(DwarfStr)).data() == b"names\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfLineStr)).data() ==
    b"line-names\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfStrOffsets)).data() ==
    b"\x00\x00\x00\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfAddr)).data() ==
    b"\x00\x00\x00\x00\x05\x00\x04\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfRanges)).data() ==
    b"\x00\x00\x00\x00\x00\x00\x00\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfRnglists)).data() == b"\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfLoclists)).data() == b"\x01\x00",
  )
}
