///|
/// An x86-64 executable whose function `main` shares its address with a
/// source file symbol (`STT_FILE`, as compilers emit at address 0 in
/// objects), a section symbol and an ARM-style mapping symbol (`$x`).
fn image_elf_test_make_with_marker_symbols() -> Bytes {
  let shstr = b"\x00.shstrtab\x00.text\x00.symtab\x00.strtab\x00"
  let text = b"\x90\xc3\xcc\x00"
  let strtab = b"\x00main\x00t.c\x00$x\x00"
  let symbols = 5
  let shstr_offset = 120 + 5 * 64
  let text_offset = shstr_offset + shstr.length()
  let symtab_offset = text_offset + text.length()
  let strtab_offset = symtab_offset + symbols * 24
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
  image_elf_test_set_u16_le(buffer, 60, 5)
  image_elf_test_set_u16_le(buffer, 62, 1)
  image_elf_test_set_u32_le(buffer, 64, 1)
  image_elf_test_set_u32_le(buffer, 68, 5)
  image_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 80, 0x400000UL)
  image_elf_test_set_u64_le(buffer, 96, text.length().to_uint64())
  image_elf_test_set_u64_le(buffer, 104, text.length().to_uint64())
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
    2,
    0UL,
    0UL,
    symtab_offset,
    symbols * 24,
    4,
    24,
  )
  image_elf_test_write_section64(
    buffer,
    4,
    25,
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
  // t.c: STT_FILE, SHN_ABS
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 24,
    6,
    0x04,
    0xfff1,
    0x400000UL,
    0UL,
  )
  // the .text section symbol: STT_SECTION
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 48,
    0,
    0x03,
    2,
    0x400000UL,
    0UL,
  )
  // $x: STT_NOTYPE mapping symbol
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 72,
    10,
    0x00,
    2,
    0x400000UL,
    0UL,
  )
  // main: STB_GLOBAL, STT_FUNC
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 96,
    1,
    0x12,
    2,
    0x400000UL,
    2UL,
  )
  image_elf_test_write_bytes(buffer, strtab_offset, strtab)
  Bytes::from_array(buffer)
}

///|
test "image ELF backend omits file, section and mapping symbols" {
  guard @image.register_builtin_backends() is Ok(_) else {
    fail("registration failed")
  }
  let (image, _) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_with_marker_symbols(),
      backend="elf",
    ),
  )
  // only `main` names the code at 0x400000, so it is not ambiguous
  inspect(
    image
    .symbols()
    .map(sym => "\{sym.name()}@\{sym.addr().to_string(radix=16)}")
    .join(" "),
    content="main@400000",
  )
}
