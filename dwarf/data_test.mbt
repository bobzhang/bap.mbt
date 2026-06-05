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
