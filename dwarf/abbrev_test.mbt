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
    b"\x03\x3c\x00" +
    b"\x00\x00" +
    b"\x00tail"
  let (table, next) = expect_abbrev_read(
    @dwarf.DwarfAbbrevTable::read(@dwarf.DwarfInput::of_bytes(bytes)),
  )
  assert_true(next.position() == bytes.length() - 4)
  assert_true(table.entries().length() == 3)
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
  let partial_unit = expect_abbrev_entry(table.lookup(3))
  assert_true(partial_unit.tag() == DwarfPartialUnit)
  assert_true(!partial_unit.has_children())
  assert_true(!partial_unit.captures_values())
  assert_true(partial_unit.value_fields().is_empty())
}

///|
test "translated DWARF abbreviation parser supports offsets and unknown attrs" {
  let bytes = b"pad" + b"\x04\x03\x00" + b"\x90\x01\x08" + b"\x00\x00" + b"\x00"
  let table = expect_abbrev_table(
    @dwarf.DwarfAbbrevTable::of_bytes(bytes, offset=3),
  )
  let entry = expect_abbrev_entry(table.lookup(4))
  assert_true(entry.tag() == DwarfEntryPoint)
  assert_true(!entry.has_children())
  assert_true(entry.fields().length() == 1)
  assert_true(entry.fields()[0].attr() == DwarfUnknownAttr(0x90))
  assert_true(entry.fields()[0].form() == DwarfString)
  assert_true(entry.fields()[0].value_kind() == DwarfIgnoredValue)
  assert_true(entry.value_fields().is_empty())
}

///|
test "translated DWARF abbreviation parser names standard type tags" {
  let bytes = b"\x06\x13\x01" + b"\x49\x13" + b"\x00\x00" + b"\x00"
  let table = expect_abbrev_table(@dwarf.DwarfAbbrevTable::of_bytes(bytes))
  let entry = expect_abbrev_entry(table.lookup(6))
  assert_true(entry.tag() == DwarfStructureType)
  assert_true(entry.has_children())
  assert_true(!entry.captures_values())
  assert_true(entry.fields().length() == 1)
  assert_true(entry.fields()[0].attr() == DwarfType)
  assert_true(entry.fields()[0].form() == DwarfRef(DwarfFour))
  assert_true(entry.fields()[0].value_kind() == DwarfIgnoredValue)
}

///|
test "translated DWARF abbreviation parser reads implicit constants" {
  let bytes = b"\x05\x2e\x00" +
    b"\x12\x21\x7e" +
    b"\x90\x01\x1e" +
    b"\x91\x01\x24" +
    b"\x00\x00" +
    b"\x00"
  let table = expect_abbrev_table(@dwarf.DwarfAbbrevTable::of_bytes(bytes))
  let entry = expect_abbrev_entry(table.lookup(5))
  assert_true(entry.tag() == DwarfSubprogram)
  assert_true(entry.fields().length() == 3)
  assert_true(entry.fields()[0].attr() == DwarfHighPc)
  assert_true(entry.fields()[0].form() == DwarfImplicitConst(-2L))
  assert_true(entry.fields()[0].value_kind() == DwarfHighPcOffsetValue)
  assert_true(entry.fields()[1].attr() == DwarfUnknownAttr(0x90))
  assert_true(entry.fields()[1].form() == DwarfData16)
  assert_true(entry.fields()[2].attr() == DwarfUnknownAttr(0x91))
  assert_true(entry.fields()[2].form() == DwarfRefSup8)
}

///|
test "translated DWARF abbreviation parser keeps indirect high pc fields" {
  let bytes = b"\x01\x2e\x00" +
    b"\x03\x08" +
    b"\x11\x01" +
    b"\x12\x16" +
    b"\x00\x00" +
    b"\x00"
  let table = expect_abbrev_table(@dwarf.DwarfAbbrevTable::of_bytes(bytes))
  let entry = expect_abbrev_entry(table.lookup(1))
  assert_true(entry.tag() == DwarfSubprogram)
  assert_true(entry.fields().length() == 3)
  assert_true(entry.fields()[2].attr() == DwarfHighPc)
  assert_true(entry.fields()[2].form() == DwarfIndirect)
  assert_true(entry.fields()[2].value_kind() == DwarfHighPcIndirectValue)
  assert_true(
    entry.value_fields().map(field => field.value_kind()) ==
    [DwarfNameValue, DwarfLowPcValue, DwarfHighPcIndirectValue],
  )
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
    @dwarf.DwarfAbbrevField::create(attr=DwarfName, form=DwarfStrpSup).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfName, form=DwarfStrpAlt).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfName,
      form=DwarfStrx(DwarfIndexOne),
    ).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfName, form=DwarfIndirect).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLinkageName, form=DwarfString).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLinkageName, form=DwarfStrpSup).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLinkageName, form=DwarfStrpAlt).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLinkageName, form=DwarfIndirect).value_kind() ==
    DwarfNameValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfSpecification,
      form=DwarfRef(DwarfFour),
    ).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfRefAddr).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfRefSup4).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfRefSup8).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfRefAlt).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfRefSig8).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSpecification, form=DwarfIndirect).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSibling, form=DwarfRef(DwarfFour)).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfSibling, form=DwarfRef(DwarfFour)).is_reference_field(),
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfType, form=DwarfRefSig8).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfType, form=DwarfRefSig8).is_reference_field(),
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfImport, form=DwarfRef(DwarfFour)).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfImport, form=DwarfRef(DwarfFour)).is_reference_field(),
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfCommonReference,
      form=DwarfRef(DwarfFour),
    ).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfContainingType, form=DwarfRefSig8).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfObjectPointer, form=DwarfRefAddr).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfObjectPointer, form=DwarfRefAddr).is_reference_field(),
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfCallOrigin,
      form=DwarfRef(DwarfFour),
    ).is_reference_field(),
  )
  let reference_capable_attrs : Array[@dwarf.DwarfAttr] = [
    DwarfByteSize,
    DwarfBitOffset,
    DwarfBitSize,
    DwarfStringLength,
    DwarfDefaultValue,
    DwarfLowerBound,
    DwarfBitStride,
    DwarfUpperBound,
    DwarfCount,
    DwarfPriority,
    DwarfAllocated,
    DwarfAssociated,
    DwarfByteStride,
    DwarfTrampoline,
    DwarfSmall,
  ]
  for attr in reference_capable_attrs {
    let field = @dwarf.DwarfAbbrevField::create(attr~, form=DwarfRef(DwarfFour))
    assert_true(field.value_kind() == DwarfIgnoredValue)
    assert_true(field.is_reference_field())
  }
  assert_true(
    !@dwarf.DwarfAbbrevField::create(attr=DwarfType, form=DwarfString).is_reference_field(),
  )
  assert_true(
    !@dwarf.DwarfAbbrevField::create(attr=DwarfName, form=DwarfRef(DwarfFour)).is_reference_field(),
  )
  assert_true(
    !@dwarf.DwarfAbbrevField::create(
      attr=DwarfDataLocation,
      form=DwarfRef(DwarfFour),
    ).is_reference_field(),
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfAbstractOrigin,
      form=DwarfRef(DwarfOne),
    ).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfAbstractOrigin,
      form=DwarfIndirect,
    ).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAbstractOrigin, form=DwarfRefSup4).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAbstractOrigin, form=DwarfRefSup8).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAbstractOrigin, form=DwarfRefAlt).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAbstractOrigin, form=DwarfRefSig8).value_kind() ==
    DwarfNameRefValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfHighPc, form=DwarfAddr).value_kind() ==
    DwarfHighPcAddressValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfHighPc,
      form=DwarfAddrx(DwarfIndexOne),
    ).value_kind() ==
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
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfHighPc,
      form=DwarfSignedConst(DwarfLeb128),
    ).value_kind() ==
    DwarfHighPcOffsetValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfHighPc, form=DwarfIndirect).value_kind() ==
    DwarfHighPcIndirectValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLowPc, form=DwarfConst(DwarfFour)).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLowPc, form=DwarfIndirect).value_kind() ==
    DwarfLowPcValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLowPc, form=DwarfFlag).value_kind() ==
    DwarfIgnoredValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfEntryPc, form=DwarfAddr).value_kind() ==
    DwarfEntryPcValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfEntryPc, form=DwarfIndirect).value_kind() ==
    DwarfEntryPcValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfStrOffsetsBase, form=DwarfOffset).value_kind() ==
    DwarfStrOffsetsBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(
      attr=DwarfStrOffsetsBase,
      form=DwarfIndirect,
    ).value_kind() ==
    DwarfStrOffsetsBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAddrBase, form=DwarfOffset).value_kind() ==
    DwarfAddrBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfAddrBase, form=DwarfIndirect).value_kind() ==
    DwarfAddrBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRangesBase, form=DwarfOffset).value_kind() ==
    DwarfRangesBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRangesBase, form=DwarfIndirect).value_kind() ==
    DwarfRangesBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRanges, form=DwarfOffset).value_kind() ==
    DwarfRangesValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRanges, form=DwarfRnglistx).value_kind() ==
    DwarfRangesValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRanges, form=DwarfIndirect).value_kind() ==
    DwarfRangesValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRnglistsBase, form=DwarfOffset).value_kind() ==
    DwarfRnglistsBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfRnglistsBase, form=DwarfIndirect).value_kind() ==
    DwarfRnglistsBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLoclistsBase, form=DwarfOffset).value_kind() ==
    DwarfLoclistsBaseValue,
  )
  assert_true(
    @dwarf.DwarfAbbrevField::create(attr=DwarfLoclistsBase, form=DwarfIndirect).value_kind() ==
    DwarfLoclistsBaseValue,
  )
}
