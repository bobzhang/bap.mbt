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
    b"\x2e\x0b\x55\x6e\x72\x73\x74\x09\x25\x1a\x1b\x29\x2c\x1e\x1f\x21\x22\x23\x1d\x1c\x7f",
  )
  let (tag, input) = expect_input_read(input.read_tag())
  assert_true(tag == DwarfSubprogram)
  let (tag, input) = expect_input_read(input.read_tag())
  assert_true(tag == DwarfLexicalBlock)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfRanges)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfLinkageName)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfStrOffsetsBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfAddrBase)
  let (attr, input) = expect_input_read(input.read_attr())
  assert_true(attr == DwarfRnglistsBase)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfBlock(DwarfLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexOne))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfStrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexLeb128))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexOne))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfAddrx(DwarfIndexFour))
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfData16)
  let (form, input) = expect_input_read(input.read_form())
  assert_true(form == DwarfLineStrp)
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
  let (code, input) = expect_input_read(input.read_code())
  assert_true(code == 127)
  assert_true(input.remaining() == 0)
  assert_true(@dwarf.DwarfInput::of_bytes(b"\x7f").read_form() is Err(_))
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
  assert_true(
    @dwarf.DwarfInput::of_bytes(b"\x00").read_block(
      lenspec=DwarfOne,
      endian=LittleEndian,
    )
    is Err(_),
  )
}
