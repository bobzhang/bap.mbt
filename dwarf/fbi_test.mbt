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
test "translated DWARF FBI ignores zero padding after units" {
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
    b"\x00" +
    b"\x00\x00\x00\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "main")
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
test "translated DWARF FBI falls back to linkage names" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x6e\x08" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x15\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"linked\x00" +
    b"\xb0\x00\x00\x00" +
    b"\x03" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "linked")
  assert_true(functions[0].low_pc() == 0xb0UL)
  assert_true(functions[0].high_pc() == Some(0xb3UL))
}

///|
test "translated DWARF FBI extracts indexed string-table names" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x25" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x0f\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"\x01" +
    b"\x70\x00\x00\x00" +
    b"\x06" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"skip\x00strxfn\x00",
      str_offsets=b"\x00\x00\x00\x00\x05\x00\x00\x00",
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "strxfn")
  assert_true(functions[0].low_pc() == 0x70UL)
  assert_true(functions[0].high_pc() == Some(0x76UL))
}

///|
test "translated DWARF FBI applies DWARF5 string offsets base" {
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
    b"\x90\x00\x00\x00" +
    b"\x05" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"skip\x00based\x00",
      str_offsets=b"\x00\x00\x00\x00\x05\x00\x00\x00",
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "based")
  assert_true(functions[0].low_pc() == 0x90UL)
  assert_true(functions[0].high_pc() == Some(0x95UL))
}

///|
test "translated DWARF FBI resolves DWARF5 addrx function bounds" {
  let abbrev = b"\x01\x11\x01" +
    b"\x73\x17" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x11\x29" +
    b"\x12\x29" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x17\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x08\x00\x00\x00" +
    b"\x02" +
    b"addrx\x00" +
    b"\x00" +
    b"\x01" +
    b"\x00"
  let addr = b"\x0c\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x20\x00\x00\x00" +
    b"\x2c\x00\x00\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      addr~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "addrx")
  assert_true(functions[0].low_pc() == 0x20UL)
  assert_true(functions[0].high_pc() == Some(0x2cUL))
}

///|
test "translated DWARF FBI summarizes debug ranges" {
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
    b"\x00\x10\x00\x00" +
    b"\x02" +
    b"ranges\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00"
  let ranges = b"\x10\x00\x00\x00" +
    b"\x14\x00\x00\x00" +
    b"\x20\x00\x00\x00" +
    b"\x28\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00\x00\x00\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      ranges~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "ranges")
  assert_true(functions[0].low_pc() == 0x1010UL)
  assert_true(functions[0].high_pc() == Some(0x1028UL))
}

///|
test "translated DWARF FBI honors debug ranges base selection" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x17" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x12\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"base\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00"
  let ranges = b"\xff\xff\xff\xff" +
    b"\x00\x30\x00\x00" +
    b"\x04\x00\x00\x00" +
    b"\x09\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00\x00\x00\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      ranges~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "base")
  assert_true(functions[0].low_pc() == 0x3004UL)
  assert_true(functions[0].high_pc() == Some(0x3009UL))
}

///|
test "translated DWARF FBI keeps nested range bases scoped" {
  let abbrev = b"\x01\x11\x01" +
    b"\x11\x01" +
    b"\x00\x00" +
    b"\x02\x0b\x01" +
    b"\x11\x01" +
    b"\x00\x00" +
    b"\x03\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x17" +
    b"\x00\x00" +
    b"\x04\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x17" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x2b\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"\x00\x10\x00\x00" +
    b"\x02" +
    b"\x00\x30\x00\x00" +
    b"\x03" +
    b"child\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00" +
    b"\x04" +
    b"sibling\x00" +
    b"\x10\x00\x00\x00" +
    b"\x00"
  let ranges = b"\x10\x00\x00\x00" +
    b"\x18\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x20\x00\x00\x00" +
    b"\x28\x00\x00\x00" +
    b"\x00\x00\x00\x00" +
    b"\x00\x00\x00\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      ranges~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 2)
  assert_true(functions[0].name() == "child")
  assert_true(functions[0].low_pc() == 0x3010UL)
  assert_true(functions[0].high_pc() == Some(0x3018UL))
  assert_true(functions[1].name() == "sibling")
  assert_true(functions[1].low_pc() == 0x1020UL)
  assert_true(functions[1].high_pc() == Some(0x1028UL))
}

///|
test "translated DWARF FBI summarizes DWARF5 rnglists offsets" {
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
    b"rngv5\x00" +
    b"\x0c\x00\x00\x00" +
    b"\x00"
  let rnglists = b"\x18\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x00\x00\x00\x00" +
    b"\x06" +
    b"\x30\x00\x00\x00" +
    b"\x38\x00\x00\x00" +
    b"\x07" +
    b"\x40\x00\x00\x00" +
    b"\x05" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      rnglists~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "rngv5")
  assert_true(functions[0].low_pc() == 0x30UL)
  assert_true(functions[0].high_pc() == Some(0x45UL))
}

///|
test "translated DWARF FBI resolves DWARF5 rnglistx through base table" {
  let abbrev = b"\x01\x11\x01" +
    b"\x11\x01" +
    b"\x74\x17" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x23" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x19\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x00\x10\x00\x00" +
    b"\x0c\x00\x00\x00" +
    b"\x02" +
    b"rngx\x00" +
    b"\x00" +
    b"\x00"
  let rnglists = b"\x15\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x01\x00\x00\x00" +
    b"\x04\x00\x00\x00" +
    b"\x05" +
    b"\x00\x20\x00\x00" +
    b"\x04" +
    b"\x10" +
    b"\x18" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      rnglists~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "rngx")
  assert_true(functions[0].low_pc() == 0x2010UL)
  assert_true(functions[0].high_pc() == Some(0x2018UL))
}

///|
test "translated DWARF FBI summarizes address-indexed DWARF5 rnglists" {
  let abbrev = b"\x01\x11\x01" +
    b"\x73\x17" +
    b"\x74\x17" +
    b"\x00\x00" +
    b"\x02\x2e\x00" +
    b"\x03\x08" +
    b"\x55\x23" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x1b\x00\x00\x00" +
    b"\x05\x00" +
    b"\x01" +
    b"\x04" +
    b"\x00\x00\x00\x00" +
    b"\x01" +
    b"\x08\x00\x00\x00" +
    b"\x0c\x00\x00\x00" +
    b"\x02" +
    b"addrng\x00" +
    b"\x00" +
    b"\x00"
  let addr = b"\x14\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x00\x20\x00\x00" +
    b"\x00\x30\x00\x00" +
    b"\x10\x30\x00\x00" +
    b"\x00\x40\x00\x00"
  let rnglists = b"\x18\x00\x00\x00" +
    b"\x05\x00" +
    b"\x04" +
    b"\x00" +
    b"\x01\x00\x00\x00" +
    b"\x04\x00\x00\x00" +
    b"\x01" +
    b"\x00" +
    b"\x04" +
    b"\x10" +
    b"\x18" +
    b"\x02" +
    b"\x01" +
    b"\x02" +
    b"\x03" +
    b"\x03" +
    b"\x05" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev~,
      str=b"",
      addr~,
      rnglists~,
    ),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "addrng")
  assert_true(functions[0].low_pc() == 0x2010UL)
  assert_true(functions[0].high_pc() == Some(0x4005UL))
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
test "translated DWARF FBI accepts entry pc when low pc is absent" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x52\x01" +
    b"\x12\x01" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x17\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"entry\x00" +
    b"\x50\x00\x00\x00" +
    b"\x60\x00\x00\x00" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "entry")
  assert_true(functions[0].low_pc() == 0x50UL)
  assert_true(functions[0].high_pc() == Some(0x60UL))
}

///|
test "translated DWARF FBI keeps low pc as relative high pc base" {
  let abbrev = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x11\x01" +
    b"\x52\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let info = b"\x19\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x04" +
    b"\x01" +
    b"offset\x00" +
    b"\x20\x00\x00\x00" +
    b"\x24\x00\x00\x00" +
    b"\x08" +
    b"\x00"
  let data = expect_fbi_data(
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info~, abbrev~, str=b""),
  )
  let functions = expect_functions(data.functions())
  assert_true(functions.length() == 1)
  assert_true(functions[0].name() == "offset")
  assert_true(functions[0].low_pc() == 0x20UL)
  assert_true(functions[0].high_pc() == Some(0x28UL))
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
