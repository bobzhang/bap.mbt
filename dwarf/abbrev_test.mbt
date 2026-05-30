///|
fn expect_abbrev_read(
  value : Result[(@dwarf.DwarfAbbrevTable, @dwarf.DwarfInput), String],
) -> (@dwarf.DwarfAbbrevTable, @dwarf.DwarfInput) raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_abbrev_table(
  value : Result[@dwarf.DwarfAbbrevTable, String],
) -> @dwarf.DwarfAbbrevTable raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_abbrev_entry(
  value : @dwarf.DwarfAbbrevEntry?,
) -> @dwarf.DwarfAbbrevEntry raise {
  match value {
    Some(value) => value
    None => fail("expected abbreviation entry")
  }
}

///|
test "translated DWARF abbreviation tables parse entries and terminators" {
  let bytes = b"\x01\x2e\x01" +
    b"\x03\x08" +
    b"\x11\x01" +
    b"\x12\x0d" +
    b"\x00\x00" +
    b"\x02\x11\x00" +
    b"\x03\x0e" +
    b"\x00\x00" +
    b"\x00tail"
  let (table, next) = expect_abbrev_read(
    @dwarf.DwarfAbbrevTable::read(@dwarf.DwarfInput::of_bytes(bytes)),
  )
  assert_true(next.position() == bytes.length() - 4)
  assert_true(table.entries().length() == 2)
  let subprogram = expect_abbrev_entry(table.lookup(1))
  assert_true(subprogram.tag() == DwarfSubprogram)
  assert_true(subprogram.has_children())
  assert_true(subprogram.captures_values())
  assert_true(subprogram.fields().length() == 3)
  assert_true(subprogram.fields()[0].attr() == DwarfName)
  assert_true(subprogram.fields()[0].form() == DwarfString)
  assert_true(
    subprogram.value_fields().map(field => field.value_kind()) ==
    [DwarfNameValue, DwarfLowPcValue, DwarfHighPcOffsetValue],
  )
  let compile_unit = expect_abbrev_entry(table.lookup(2))
  assert_true(compile_unit.tag() == DwarfCompileUnit)
  assert_true(!compile_unit.has_children())
  assert_true(!compile_unit.captures_values())
  assert_true(compile_unit.value_fields().is_empty())
}

///|
test "translated DWARF abbreviation parser supports offsets and unknown attrs" {
  let bytes = b"pad" + b"\x04\x03\x00" + b"\x7f\x08" + b"\x00\x00" + b"\x00"
  let table = expect_abbrev_table(
    @dwarf.DwarfAbbrevTable::of_bytes(bytes, offset=3),
  )
  let entry = expect_abbrev_entry(table.lookup(4))
  assert_true(entry.tag() == DwarfEntryPoint)
  assert_true(!entry.has_children())
  assert_true(entry.fields().length() == 1)
  assert_true(entry.fields()[0].attr() == DwarfUnknownAttr(0x7f))
  assert_true(entry.fields()[0].form() == DwarfString)
  assert_true(entry.fields()[0].value_kind() == DwarfIgnoredValue)
  assert_true(entry.value_fields().is_empty())
}

///|
test "translated DWARF abbreviation parser rejects duplicates and malformed fields" {
  let duplicate = b"\x01\x2e\x00\x00\x00" + b"\x01\x11\x00\x00\x00" + b"\x00"
  assert_true(
    @dwarf.DwarfAbbrevTable::read(@dwarf.DwarfInput::of_bytes(duplicate))
    is Err(_),
  )
  let unknown_form = b"\x01\x2e\x00\x03\x7f\x00\x00\x00"
  assert_true(
    @dwarf.DwarfAbbrevTable::read(@dwarf.DwarfInput::of_bytes(unknown_form))
    is Err(_),
  )
  let truncated = b"\x01\x2e\x00\x03"
  assert_true(
    @dwarf.DwarfAbbrevTable::read(@dwarf.DwarfInput::of_bytes(truncated))
    is Err(_),
  )
}

///|
test "translated DWARF abbreviation value classification follows BAP FBI inputs" {
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfName, form=DwarfStrp).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfHighPc, form=DwarfAddr).value_kind() ==
    DwarfHighPcAddressValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfHighPc,
      form=DwarfConst(DwarfFour),
    ).value_kind() ==
    DwarfHighPcOffsetValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLowPc, form=DwarfConst(DwarfFour)).value_kind() ==
    DwarfIgnoredValue,
  )
}
