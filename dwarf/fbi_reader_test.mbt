///|
/// Abbreviation 1: `DW_TAG_subprogram`, no children, `DW_AT_name`
/// (`DW_FORM_string`), `DW_AT_low_pc` (`DW_FORM_addr`), `DW_AT_high_pc`
/// (`DW_FORM_data1`).
let reader_abbrev : Bytes = b"\x01\x2e\x00\x03\x08\x11\x01\x12\x0b\x00\x00\x00"

///|
/// A DWARF4 32-bit compilation unit with one function DIE. With
/// `terminator = 0x7f` the DIE list ends with an unknown abbreviation code.
fn reader_unit(name : String, low : Byte, terminator~ : Byte = 0) -> Bytes {
  let body : Array[Byte] = [0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x01]
  for ch in name {
    body.push(ch.to_int().to_byte())
  }
  body.push(0x00)
  body.append([low, 0x00, 0x00, 0x00, 0x08, terminator])
  let unit : Array[Byte] = [body.length().to_byte(), 0x00, 0x00, 0x00]
  unit.append(body)
  Bytes::from_array(unit)
}

///|
/// A later unit whose only DIE uses an unknown abbreviation code.
let reader_bad_die_unit : Bytes = b"\x08\x00\x00\x00\x04\x00\x00\x00\x00\x00\x04\x7f"

///|
/// A later unit whose header points past the end of `.debug_abbrev`.
let reader_bad_header_unit : Bytes = b"\x07\x00\x00\x00\x04\x00\xff\x00\x00\x00\x04"

///|
fn reader_data(info : Bytes) -> @dwarf.DwarfData raise {
  match
    @dwarf.DwarfData::from_bytes(
      endian=LittleEndian,
      info~,
      abbrev=reader_abbrev,
      str=b"",
    ) {
    Ok(data) => data
    Err(reason) => fail(reason)
  }
}

///|
fn reader_names(functions : Array[@dwarf.DwarfFunction]) -> String {
  functions.map(f => "\{f.name()}@\{f.low_pc()}").join(",")
}

///|
test "DWARF FBI keeps functions recovered before a malformed later DIE" {
  let data = reader_data(
    reader_unit("main", 0x10) +
    reader_unit("helper", 0x20) +
    reader_bad_die_unit +
    reader_unit("lost", 0x30),
  )
  let scan = data.scan_functions()
  inspect(reader_names(scan.functions()), content="main@16,helper@32")
  inspect(scan.is_complete(), content="false")
  inspect(
    scan.diagnostics().join("\n"),
    content="DWARF parser stopped prematurely in the unit at .debug_info offset 48: unknown DWARF abbreviation code: 127; some symbols may be omitted",
  )
  // The eager wrapper returns the valid prefix instead of an error.
  match data.functions() {
    Ok(functions) =>
      inspect(reader_names(functions), content="main@16,helper@32")
    Err(reason) => fail(reason)
  }
  // The streamed enumeration yields the same prefix and reports the warning.
  let warnings = []
  let streamed = data
    .iter_functions(on_warning=w => warnings.push(w))
    .to_array()
  inspect(reader_names(streamed), content="main@16,helper@32")
  inspect(warnings.length(), content="1")
  // `DwarfFbi::create` succeeds: only the first unit is validated.
  match @dwarf.DwarfFbi::create(data) {
    Ok(fbi) => {
      inspect(
        fbi.functions().map(pair => pair.0).join(","),
        content="main,helper",
      )
      inspect(fbi.diagnostics().length(), content="1")
      inspect(
        fbi.iter().map(pair => pair.0).to_array().join(","),
        content="main,helper",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "DWARF FBI keeps functions of a unit truncated by a malformed DIE" {
  let data = reader_data(
    reader_unit("first", 0x10) +
    reader_unit("partial", 0x20, terminator=0x7f) +
    reader_unit("lost", 0x30),
  )
  let scan = data.scan_functions()
  inspect(reader_names(scan.functions()), content="first@16,partial@32")
  inspect(scan.diagnostics().length(), content="1")
}

///|
test "DWARF FBI stops at a malformed later unit header" {
  let data = reader_data(
    reader_unit("main", 0x10) +
    reader_bad_header_unit +
    reader_unit("lost", 0x30),
  )
  let scan = data.scan_functions()
  inspect(reader_names(scan.functions()), content="main@16")
  let diagnostics = scan.diagnostics()
  assert_eq(diagnostics.length(), 1)
  assert_true(
    diagnostics[0].has_prefix(
      "failed to move to the next DWARF unit at .debug_info offset 23:",
    ),
  )
  let warnings = []
  let streamed = data
    .iter_functions(on_warning=w => warnings.push(w))
    .to_array()
  inspect(reader_names(streamed), content="main@16")
  inspect(warnings.length(), content="1")
  // Truncated trailing unit length: also a header-level stop.
  let data = reader_data(reader_unit("main", 0x10) + b"\x13\x00")
  inspect(reader_names(data.scan_functions().functions()), content="main@16")
  inspect(data.scan_functions().diagnostics().length(), content="1")
}

///|
test "DWARF FBI create validates only the first unit header" {
  // A broken first header fails creation, like upstream `Fbi.create`.
  let data = reader_data(reader_bad_header_unit + reader_unit("main", 0x10))
  inspect(@dwarf.DwarfFbi::create(data) is Err(_), content="true")
  inspect(data.functions() is Err(_), content="true")
  // Missing required sections fail creation.
  match
    @dwarf.DwarfData::from_bytes(endian=LittleEndian, info=reader_unit("x", 1)) {
    Ok(no_abbrev) => {
      inspect(@dwarf.DwarfFbi::create(no_abbrev) is Err(_), content="true")
      let warnings = []
      let streamed = no_abbrev.iter_functions(on_warning=w => warnings.push(w))
      inspect(streamed.count(), content="0")
      inspect(warnings.length(), content="1")
    }
    Err(reason) => fail(reason)
  }
  // A complete scan has no diagnostics and matches the streamed enumeration.
  let data = reader_data(reader_unit("a", 0x10) + reader_unit("b", 0x20))
  let scan = data.scan_functions()
  inspect(scan.is_complete(), content="true")
  inspect(reader_names(scan.functions()), content="a@16,b@32")
  inspect(reader_names(data.iter_functions().to_array()), content="a@16,b@32")
}
