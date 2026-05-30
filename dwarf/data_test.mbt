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
  assert_true(buffer.with_position(4) is Err(_))
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
      str_offsets=b"\x00\x00\x00\x00",
    ),
  )
  assert_true(data.has_section(DwarfInfo))
  assert_true(data.has_section(DwarfAbbrev))
  assert_true(data.has_section(DwarfStr))
  assert_true(data.has_section(DwarfStrOffsets))
  assert_true(
    expect_section_buffer(data.section(DwarfStr)).data() == b"names\x00",
  )
  assert_true(
    expect_section_buffer(data.section(DwarfStrOffsets)).data() ==
    b"\x00\x00\x00\x00",
  )
}
