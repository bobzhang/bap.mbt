///|
fn expect_functions(
  value : Result[Array[@dwarf.DwarfFunction], String],
) -> Array[@dwarf.DwarfFunction] raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_fbi_data(
  value : Result[@dwarf.DwarfData, String],
) -> @dwarf.DwarfData raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
test "translated DWARF FBI extracts function with inline name and relative high pc" {
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
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "main")
  assert_true(functions[0].low_pc() == 0x10UL)
  assert_true(functions[0].high_pc() == Some(0x15UL))
}

///|
test "translated DWARF FBI extracts string-table names and absolute high pc" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x0e" +
    b"\x11\x01" +
    b"\x12\x01" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x15\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"\x05\x00\x00\x00" +
    b"\x20\x00\x00\x00" +
    b"\x30\x00\x00\x00" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"skip\x00puts\x00",
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "puts")
  assert_true(functions[0].low_pc() == 0x20UL)
  assert_true(functions[0].high_pc() == Some(0x30UL))
}

///|
test "translated DWARF FBI resolves indirect value forms" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x16" +
    b"\x11\x01" +
    b"\x12\x16" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x19\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"\x08" +
    b"indirect\x00" +
    b"\x40\x00\x00\x00" +
    b"\x0b" +
    b"\x04" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "indirect")
  assert_true(functions[0].low_pc() == 0x40UL)
  assert_true(functions[0].high_pc() == Some(0x44UL))
}

///|
test "translated DWARF FBI skips degenerate and non-function DIEs" {
  let abbrev = b"\x01\x11\x01" +
    b"\x03\x08" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x1b\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"unit\x00" +
    b"\x02" +
    b"missing-low\x00" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  assert_true(expect_functions(data.functions()).is_empty())
}

///|
test "translated DWARF FBI reports missing sections and unknown abbrev codes" {
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info=b"\x00\x00\x00\x00",
      abbrev=b"",
    ),
  )
  assert_true(data.functions() is Err(_))
  let abbrev = b"\x00"
  let info = b"\x08\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x7f"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  assert_true(data.functions() is Err(_))
}
