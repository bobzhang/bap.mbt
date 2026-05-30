///|
fn expect_elf_image(
  value : Result[(@image.Image, Array[String]), String],
) -> (@image.Image, Array[String]) raise {
  match value {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
}

///|
fn image_elf_test_set_u16_le(
  buffer : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  buffer[offset] = (value & 0xff).to_byte()
  buffer[offset + 1] = ((value >> 8) & 0xff).to_byte()
}

///|
fn image_elf_test_set_u32_le(
  buffer : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  for i in 0..<4 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xff).to_byte()
  }
}

///|
fn image_elf_test_set_u64_le(
  buffer : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  for i in 0..<8 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xffUL).to_int().to_byte()
  }
}

///|
fn image_elf_test_write_bytes(
  buffer : Array[Byte],
  offset : Int,
  data : Bytes,
) -> Unit {
  for i in 0..<data.length() {
    buffer[offset + i] = data[i]
  }
}

///|
fn image_elf_test_write_section64(
  buffer : Array[Byte],
  index : Int,
  name_offset : Int,
  typ : Int,
  flags : UInt64,
  addr : UInt64,
  offset : Int,
  size : Int,
  link : Int,
  entsize : Int,
) -> Unit {
  let base = 120 + index * 64
  image_elf_test_set_u32_le(buffer, base, name_offset)
  image_elf_test_set_u32_le(buffer, base + 4, typ)
  image_elf_test_set_u64_le(buffer, base + 8, flags)
  image_elf_test_set_u64_le(buffer, base + 16, addr)
  image_elf_test_set_u64_le(buffer, base + 24, offset.to_uint64())
  image_elf_test_set_u64_le(buffer, base + 32, size.to_uint64())
  image_elf_test_set_u32_le(buffer, base + 40, link)
  image_elf_test_set_u64_le(buffer, base + 56, entsize.to_uint64())
}

///|
fn image_elf_test_write_symbol64(
  buffer : Array[Byte],
  offset : Int,
  name_offset : Int,
  info : Int,
  shndx : Int,
  value : UInt64,
  size : UInt64,
) -> Unit {
  image_elf_test_set_u32_le(buffer, offset, name_offset)
  buffer[offset + 4] = info.to_byte()
  image_elf_test_set_u16_le(buffer, offset + 6, shndx)
  image_elf_test_set_u64_le(buffer, offset + 8, value)
  image_elf_test_set_u64_le(buffer, offset + 16, size)
}

///|
fn image_elf_test_make_x86_64() -> Bytes {
  let shstr = b"\x00.shstrtab\x00.text\x00.debug_info\x00.symtab\x00.strtab\x00"
  let text = b"\x90\xc3\xcc\x00"
  let debug_info = b"debug"
  let strtab = b"\x00main\x00data_object\x00"
  let shstr_offset = 120 + 6 * 64
  let text_offset = shstr_offset + shstr.length()
  let debug_offset = text_offset + text.length()
  let symtab_offset = debug_offset + debug_info.length()
  let strtab_offset = symtab_offset + 72
  let total = strtab_offset + strtab.length()
  let buffer = Array::make(total, b'\x00')
  image_elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  image_elf_test_set_u16_le(buffer, 16, 2)
  image_elf_test_set_u16_le(buffer, 18, 0x3e)
  image_elf_test_set_u32_le(buffer, 20, 1)
  image_elf_test_set_u64_le(buffer, 24, 0x400000UL)
  image_elf_test_set_u64_le(buffer, 32, 64UL)
  image_elf_test_set_u64_le(buffer, 40, 120UL)
  image_elf_test_set_u16_le(buffer, 52, 64)
  image_elf_test_set_u16_le(buffer, 54, 56)
  image_elf_test_set_u16_le(buffer, 56, 1)
  image_elf_test_set_u16_le(buffer, 58, 64)
  image_elf_test_set_u16_le(buffer, 60, 6)
  image_elf_test_set_u16_le(buffer, 62, 1)
  image_elf_test_set_u32_le(buffer, 64, 1)
  image_elf_test_set_u32_le(buffer, 68, 5)
  image_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 80, 0x400000UL)
  image_elf_test_set_u64_le(buffer, 96, text.length().to_uint64())
  image_elf_test_set_u64_le(buffer, 104, 6UL)
  image_elf_test_write_section64(
    buffer,
    1,
    1,
    3,
    0UL,
    0UL,
    shstr_offset,
    shstr.length(),
    0,
    0,
  )
  image_elf_test_write_section64(
    buffer,
    2,
    11,
    1,
    6UL,
    0x400000UL,
    text_offset,
    text.length(),
    0,
    0,
  )
  image_elf_test_write_section64(
    buffer,
    3,
    17,
    1,
    0UL,
    0UL,
    debug_offset,
    debug_info.length(),
    0,
    0,
  )
  image_elf_test_write_section64(
    buffer, 4, 29, 2, 0UL, 0UL, symtab_offset, 72, 5, 24,
  )
  image_elf_test_write_section64(
    buffer,
    5,
    37,
    3,
    0UL,
    0UL,
    strtab_offset,
    strtab.length(),
    0,
    0,
  )
  image_elf_test_write_bytes(buffer, shstr_offset, shstr)
  image_elf_test_write_bytes(buffer, text_offset, text)
  image_elf_test_write_bytes(buffer, debug_offset, debug_info)
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 24,
    1,
    0x12,
    2,
    0x400000UL,
    2UL,
  )
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 48,
    6,
    0x11,
    2,
    0x400002UL,
    1UL,
  )
  image_elf_test_write_bytes(buffer, strtab_offset, strtab)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_without_sections() -> Bytes {
  let text = b"\x55\xc3"
  let text_offset = 64 + 56
  let total = text_offset + text.length()
  let buffer = Array::make(total, b'\x00')
  image_elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  image_elf_test_set_u16_le(buffer, 16, 2)
  image_elf_test_set_u16_le(buffer, 18, 0x3e)
  image_elf_test_set_u32_le(buffer, 20, 1)
  image_elf_test_set_u64_le(buffer, 24, 0x500000UL)
  image_elf_test_set_u64_le(buffer, 32, 64UL)
  image_elf_test_set_u16_le(buffer, 52, 64)
  image_elf_test_set_u16_le(buffer, 54, 56)
  image_elf_test_set_u16_le(buffer, 56, 1)
  image_elf_test_set_u32_le(buffer, 64, 1)
  image_elf_test_set_u32_le(buffer, 68, 5)
  image_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 80, 0x500000UL)
  image_elf_test_set_u64_le(buffer, 96, text.length().to_uint64())
  image_elf_test_set_u64_le(buffer, 104, 4UL)
  image_elf_test_write_bytes(buffer, text_offset, text)
  Bytes::from_array(buffer)
}

///|
test "image ELF backend loads program segments and sections" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.find_backend("elf") is Some(_))
  assert_true(@image.backend_names_for_extension("elf").contains("elf"))
  assert_true(@image.backend_names_for_extension("so").contains("elf"))
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(image_elf_test_make_x86_64(), backend="elf"),
  )
  assert_true(warnings.is_empty())
  assert_true(image.entry_point() == 0x400000UL)
  assert_true(image.endian() == LittleEndian)
  match image.target() {
    Some(target) => {
      assert_true(target.matches("x86_64"))
      assert_true(target.filetype() == Elf)
    }
    None => fail("expected ELF target")
  }
  let segments = image.segments()
  assert_true(segments.length() == 1)
  assert_true(segments[0].name() == ".load0")
  assert_true(segments[0].addr() == 0x400000UL)
  assert_true(segments[0].size() == 6)
  assert_true(segments[0].offset() > 0)
  assert_true(segments[0].is_readable())
  assert_true(!segments[0].is_writable())
  assert_true(segments[0].is_executable())
  assert_true(image.memory().lookup(0x400005UL).length() == 1)
  inspect(segments[0].memory().hexdump(), content="90 c3 cc 00 00 00")
  let sections = image.sections()
  assert_true(sections.any(section => section.name() == ".text"))
  assert_true(sections.any(section => section.name() == ".debug_info"))
  assert_true(image.sections_of_segment(segments[0]).length() == 1)
  let symbols = image.symbols()
  assert_true(symbols.length() == 2)
  let main_symbol = match symbols.search_by(symbol => symbol.name() == "main") {
    Some(index) => symbols[index]
    None => fail("expected main symbol")
  }
  assert_true(main_symbol.addr() == 0x400000UL)
  assert_true(main_symbol.size() == 2)
  assert_true(main_symbol.is_function())
  match image.memory_of_symbol(main_symbol) {
    Some((memory, rest)) => {
      assert_true(rest.length() == 0)
      inspect(memory.hexdump(), content="90 c3")
    }
    None => fail("expected main symbol memory")
  }
  let data_symbol = match
    symbols.search_by(symbol => symbol.name() == "data_object") {
    Some(index) => symbols[index]
    None => fail("expected data object symbol")
  }
  assert_true(data_symbol.addr() == 0x400002UL)
  assert_true(data_symbol.size() == 1)
  assert_true(!data_symbol.is_function())
  assert_true(image.symbols_of_segment(segments[0]).length() == 2)
}

///|
test "image ELF backend loads files without section headers" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_without_sections(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.entry_point() == 0x500000UL)
  assert_true(image.sections().is_empty())
  assert_true(image.symbols().is_empty())
  let segments = image.segments()
  assert_true(segments.length() == 1)
  assert_true(segments[0].addr() == 0x500000UL)
  assert_true(segments[0].size() == 4)
  assert_true(segments[0].is_executable())
  inspect(segments[0].memory().hexdump(), content="55 c3 00 00")
}

///|
test "image ELF backend participates in filename discovery" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes_for_filename(
      image_elf_test_make_x86_64(),
      filename="libunit.SO",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.arch().matches("x86_64"))
}

///|
test "image ELF backend rejects malformed inputs" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.Image::of_bytes(b"not elf", backend="elf") is Err(_))
  assert_true(
    @image.Image::of_bytes(b"\x7fELF\x02\x01\x01", backend="elf") is Err(_),
  )
}
