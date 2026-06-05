///|
fn[T] expect_input_read(
  value : Result[(T, @dwarf.DwarfInput), String],
) -> (T, @dwarf.DwarfInput) raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn expect_input(
  value : Result[@dwarf.DwarfInput, String],
) -> @dwarf.DwarfInput raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
test "translated DWARF input reads bytes strings and cursor positions" {
  let input = @dwarf.DwarfInput::of_bytes(b"\x01hello\x00z")
  let (byte, input) = expect_input_read(input.read_byte())
  assert_true(byte == 1)
  assert_true(input.position() == 1)
  let (text, input) = expect_input_read(input.read_cstring())
  assert_true(text == "hello")
  assert_true(input.position() == 7)
  let (last, input) = expect_input_read(input.read_byte())
  assert_true(last == 0x7a)
  assert_true(input.remaining() == 0)
  assert_true(input.read_byte() is Err(_))
  assert_true(
    @dwarf.DwarfInput::of_bytes(b"unterminated").read_cstring() is Err(_),
  )
}

///|
test "translated DWARF input reads endian addresses and signed integers" {
  let bytes = b"\x01\x02\x03\x04\xff\xfe\xff\xff\xff\xfe"
  let input = @dwarf.DwarfInput::of_bytes(bytes)
  let (little_addr, _) = expect_input_read(
    input.read_address(endian=LittleEndian, size=W32),
  )
  assert_true(little_addr == 0x04030201UL)
  let (big_addr, input) = expect_input_read(
    input.read_address(endian=BigEndian, size=W32),
  )
  assert_true(big_addr == 0x01020304UL)
  let (neg16, input) = expect_input_read(input.read_int16(endian=BigEndian))
  assert_true(neg16 == -2)
  let (neg32, _) = expect_input_read(
    input.read_int64(endian=BigEndian, size=W32),
  )
  assert_true(neg32 == -2L)
}

///|
test "translated DWARF input decodes tags attributes forms and LEB128 codes" {
  let input = @dwarf.DwarfInput::of_bytes(
    b"\x2e\x0b\x3c\x02\x55\x6e\x87\x40\x31\x40\x47\x72\x73\xb2\x42\xb3\x42\x74\x8c\x01\x09\x25\x26\x27\x28\x1a\x1b\x81\x3e\x82\x3e\x29\x2a\x2b\x2c\x1e\x1f\x20\x21\x22\x23\x1d\x1c\x24\xa0\x3e\xa1\x3e\x0c\x0d\x0f\x10\x7f",
  )
  let (tag, input) = expect_input_read(input.read_tag())
  assert_true(tag == DwarfSubprogram)
  let (tag, input) = expect_input_read(input.read_tag())
  assert_true(tag == DwarfLexicalBlock)
  let (tag, input) = expect_input_read(input.read_tag())
  assert_true(tag == DwarfPartialUnit)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfLocation)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfRanges)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfLinkageName)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfLinkageName)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfAbstractOrigin)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfFrameBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfSpecification)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfStrOffsetsBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfAddrBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfRangesBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfAddrBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfRnglistsBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfLoclistsBase)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfBlock(DwarfLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexOne))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexTwo))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexThree))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexFour))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexOne))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexTwo))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexThree))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexFour))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfData16)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfLineStrp)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRefSig8)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfImplicitConst(0L))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfLoclistx)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRnglistx)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrpSup)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRefSup4)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRefSup8)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRefAlt)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrpAlt)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfFlag)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfSignedConst(DwarfLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfConst(DwarfLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfRefAddr)
  let (code, input) = expect_input_read(input.read_code())
  assert_true(code == 127)
  assert_true(input.remaining() == 0)
  assert_true(@dwarf.DwarfInput::of_bytes(b"\x7f").read_form() is Err(_))
}

///|
test "translated DWARF source-style type aliases construct values" {
  assert_true(@dwarf.DwarfLenspec::leb128() == DwarfLeb128)
  assert_true(@dwarf.DwarfLenspec::one() == DwarfOne)
  assert_true(@dwarf.DwarfLenspec::two() == DwarfTwo)
  assert_true(@dwarf.DwarfLenspec::four() == DwarfFour)
  assert_true(@dwarf.DwarfLenspec::eight() == DwarfEight)
  assert_true(@dwarf.DwarfTag::entry_point() == DwarfEntryPoint)
  assert_true(@dwarf.DwarfTag::compile_unit() == DwarfCompileUnit)
  assert_true(@dwarf.DwarfTag::partial_unit() == DwarfPartialUnit)
  assert_true(@dwarf.DwarfTag::inlined_subroutine() == DwarfInlinedSubroutine)
  assert_true(@dwarf.DwarfTag::subprogram() == DwarfSubprogram)
  assert_true(@dwarf.DwarfTag::unknown(7) == DwarfUnknownTag(7))
  assert_true(@dwarf.DwarfAttr::name() == DwarfName)
  assert_true(@dwarf.DwarfAttr::location() == DwarfLocation)
  assert_true(@dwarf.DwarfAttr::frame_base() == DwarfFrameBase)
  assert_true(@dwarf.DwarfAttr::low_pc() == DwarfLowPc)
  assert_true(@dwarf.DwarfAttr::high_pc() == DwarfHighPc)
  assert_true(@dwarf.DwarfAttr::entry_pc() == DwarfEntryPc)
  assert_true(@dwarf.DwarfAttr::loclists_base() == DwarfLoclistsBase)
  assert_true(@dwarf.DwarfAttr::unknown(9) == DwarfUnknownAttr(9))
  assert_true(@dwarf.DwarfForm::addr() == DwarfAddr)
  assert_true(@dwarf.DwarfForm::block(DwarfTwo) == DwarfBlock(DwarfTwo))
  assert_true(@dwarf.DwarfForm::const_(DwarfFour) == DwarfConst(DwarfFour))
  assert_true(@dwarf.DwarfForm::flag_present() == DwarfFlagPresent)
  assert_true(@dwarf.DwarfForm::string() == DwarfString)
  assert_true(@dwarf.DwarfForm::strp() == DwarfStrp)
  assert_true(@dwarf.DwarfForm::ref_(DwarfEight) == DwarfRef(DwarfEight))
  assert_true(@dwarf.DwarfForm::indirect() == DwarfIndirect)
  assert_true(@dwarf.DwarfForm::offset() == DwarfOffset)
  assert_true(@dwarf.DwarfForm::expr() == DwarfExpr)
  assert_true(@dwarf.DwarfForm::sig_() == DwarfRefSig8)
}

///|
test "translated DWARF input reader facade exposes primitive readers" {
  let input = @dwarf.DwarfInput::of_bytes(
    b"\x7f\x2e\x11\x01hi\x00\x04\x00\x04\x04\x00\x00\x00\x05\x00\x00\x00\x03abc\x05",
  )
  let (byte, input) = expect_input_read(
    @dwarf.DwarfInputReader::char().run(input),
  )
  assert_true(byte == 0x7f)
  let (tag, input) = expect_input_read(
    @dwarf.DwarfInputReader::tag().run(input),
  )
  assert_true(tag == DwarfSubprogram)
  let (attr, input) = expect_input_read(
    @dwarf.DwarfInputReader::attr().run(input),
  )
  assert_true(attr == DwarfLowPc)
  let (form, input) = expect_input_read(
    @dwarf.DwarfInputReader::form().run(input),
  )
  assert_true(form == DwarfAddr)
  let (text, input) = expect_input_read(
    @dwarf.DwarfInputReader::string().run(input),
  )
  assert_true(text == "hi")
  let (version, input) = expect_input_read(
    @dwarf.DwarfInputReader::version().run(input),
  )
  assert_true(version == 4)
  let (addr_size, input) = expect_input_read(
    @dwarf.DwarfInputReader::address_size().run(input),
  )
  assert_true(addr_size == W32)
  let ((word_size, unit_size), input) = expect_input_read(
    @dwarf.DwarfInputReader::unit_size(endian=LittleEndian).run(input),
  )
  assert_true(word_size == W32)
  assert_true(unit_size == 4)
  let (offset, input) = expect_input_read(
    @dwarf.DwarfInputReader::offset(endian=LittleEndian, size=W32).run(input),
  )
  assert_true(offset == 5)
  let (block, input) = expect_input_read(
    @dwarf.DwarfInputReader::block(lenspec=DwarfOne, endian=LittleEndian).run(
      input,
    ),
  )
  assert_true(block == b"abc")
  let (value, input) = expect_input_read(
    @dwarf.DwarfInputReader::const_(lenspec=DwarfOne, endian=LittleEndian).run(
      input,
    ),
  )
  assert_true(value == 5L)
  assert_true(input.remaining() == 0)
}

///|
test "translated DWARF input reader facade composes readers" {
  let input = @dwarf.DwarfInput::of_bytes(b"\x2ehi\x00\x00\x00\x05\x01\x7f")
  let reader = @dwarf.DwarfInputReader::pair(
    @dwarf.DwarfInputReader::tag(),
    @dwarf.DwarfInputReader::string().map(text => text + "!"),
  )
  let ((tag, text), input) = expect_input_read(reader.run(input))
  assert_true(tag == DwarfSubprogram)
  assert_true(text == "hi!")
  let (_, input) = expect_input_read(
    @dwarf.DwarfInputReader::skip_zeros().run(input),
  )
  assert_true(input.position() == 6)
  let (_, input) = expect_input_read(
    @dwarf.DwarfInputReader::skip(bytes=1).run(input),
  )
  assert_true(input.position() == 7)
  let (dropped, input) = expect_input_read(
    @dwarf.DwarfInputReader::char().drop().run(input),
  )
  assert_true(dropped is None)
  let (taken, input) = expect_input_read(
    @dwarf.DwarfInputReader::code().take().run(input),
  )
  assert_true(taken == Some(0x7f))
  assert_true(input.remaining() == 0)
  let (_, input) = expect_input_read(
    @dwarf.DwarfInputReader::char()
    .ignore_()
    .run(@dwarf.DwarfInput::of_bytes(b"\x01")),
  )
  assert_true(input.remaining() == 0)
}

///|
test "translated DWARF input reads unit metadata" {
  let short = @dwarf.DwarfInput::of_bytes(b"\x10\x00\x00\x00\x04\x00\x04")
  let ((size_kind, size), short) = expect_input_read(
    short.read_unit_size(endian=LittleEndian),
  )
  assert_true(size_kind == W32)
  assert_true(size == 16)
  let (version, short) = expect_input_read(short.read_version())
  assert_true(version == 4)
  let (addr_size, short) = expect_input_read(short.read_address_size())
  assert_true(addr_size == W32)
  assert_true(short.remaining() == 0)
  let long = @dwarf.DwarfInput::of_bytes(
    b"\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x08",
  )
  let ((size_kind, size), long) = expect_input_read(
    long.read_unit_size(endian=BigEndian),
  )
  assert_true(size_kind == W64)
  assert_true(size == 8)
  assert_true(long.remaining() == 0)
  assert_true(
    @dwarf.DwarfInput::of_bytes(b"\x03").read_address_size() is Err(_),
  )
}

///|
test "translated DWARF input skips zero padding and reads const blocks" {
  let padded = @dwarf.DwarfInput::of_bytes(b"\x00\x00\x05")
  let padded = expect_input(padded.skip_zeros())
  assert_true(padded.position() == 2)
  let (value, _) = expect_input_read(
    padded.read_const(lenspec=DwarfOne, endian=LittleEndian),
  )
  assert_true(value == 5L)
  let block_input = @dwarf.DwarfInput::of_bytes(b"\x03abc")
  let (block, block_input) = expect_input_read(
    block_input.read_block(lenspec=DwarfOne, endian=LittleEndian),
  )
  assert_true(block == b"abc")
  assert_true(block_input.remaining() == 0)
  let (empty, empty_input) = expect_input_read(
    @dwarf.DwarfInput::of_bytes(b"\x00").read_block(
      lenspec=DwarfOne,
      endian=LittleEndian,
    ),
  )
  assert_true(empty == b"")
  assert_true(empty_input.remaining() == 0)
}

///|
test "translated DWARF input reads fixed block lengths as unsigned" {
  let payload = Bytes::new(32768)
  let input = @dwarf.DwarfInput::of_bytes(b"\x00\x80" + payload)
  let (block, input) = expect_input_read(
    input.read_block(lenspec=DwarfTwo, endian=LittleEndian),
  )
  assert_true(block.length() == 32768)
  assert_true(input.remaining() == 0)
}
