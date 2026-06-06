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
  image_elf_test_write_section64_at(
    buffer, 120, index, name_offset, typ, flags, addr, offset, size, link, entsize,
  )
}

///|
fn image_elf_test_write_section64_at(
  buffer : Array[Byte],
  section_table_offset : Int,
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
  let base = section_table_offset + index * 64
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
fn image_elf_test_write_rela64(
  buffer : Array[Byte],
  offset : Int,
  relocation_offset : UInt64,
  symbol_index : Int,
  typ : Int,
  addend? : Int64 = 0L,
) -> Unit {
  image_elf_test_set_u64_le(buffer, offset, relocation_offset)
  image_elf_test_set_u64_le(
    buffer,
    offset + 8,
    (symbol_index.to_uint64() << 32) | typ.to_uint64(),
  )
  image_elf_test_set_u64_le(buffer, offset + 16, addend.reinterpret_as_uint64())
}

///|
fn image_elf_test_write_rel64(
  buffer : Array[Byte],
  offset : Int,
  relocation_offset : UInt64,
  symbol_index : Int,
  typ : Int,
) -> Unit {
  image_elf_test_set_u64_le(buffer, offset, relocation_offset)
  image_elf_test_set_u64_le(
    buffer,
    offset + 8,
    (symbol_index.to_uint64() << 32) | typ.to_uint64(),
  )
}

///|
fn image_elf_test_write_dynamic64(
  buffer : Array[Byte],
  offset : Int,
  tag : UInt64,
  value : UInt64,
) -> Unit {
  image_elf_test_set_u64_le(buffer, offset, tag)
  image_elf_test_set_u64_le(buffer, offset + 8, value)
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
  buffer[7] = b'\x03'
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
fn image_elf_test_make_x86_64_with_relocations() -> Bytes {
  let shstr = b"\x00.shstrtab\x00.text\x00.symtab\x00.strtab\x00.rela.text\x00.rel.text\x00"
  let text = b"\x90\xc3\xcc\x00"
  let strtab = b"\x00main\x00target\x00puts\x00"
  let shstr_offset = 120 + 7 * 64
  let text_offset = shstr_offset + shstr.length()
  let symtab_offset = text_offset + text.length()
  let strtab_offset = symtab_offset + 96
  let rela_offset = strtab_offset + strtab.length()
  let rel_offset = rela_offset + 72
  let total = rel_offset + 16
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
  image_elf_test_set_u16_le(buffer, 60, 7)
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
    buffer, 3, 17, 2, 0UL, 0UL, symtab_offset, 96, 4, 24,
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
  image_elf_test_write_section64(
    buffer, 5, 33, 4, 0UL, 0UL, rela_offset, 72, 3, 24,
  )
  image_elf_test_write_section64(
    buffer, 6, 44, 9, 0UL, 0UL, rel_offset, 16, 3, 16,
  )
  image_elf_test_write_bytes(buffer, shstr_offset, shstr)
  image_elf_test_write_bytes(buffer, text_offset, text)
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
    0x12,
    2,
    0x400002UL,
    1UL,
  )
  image_elf_test_write_symbol64(
    buffer,
    symtab_offset + 72,
    13,
    0x12,
    0,
    0UL,
    0UL,
  )
  image_elf_test_write_bytes(buffer, strtab_offset, strtab)
  image_elf_test_write_rela64(buffer, rela_offset, 0x400000UL, 2, 4, addend=4L)
  image_elf_test_write_rela64(buffer, rela_offset + 24, 0x400001UL, 3, 4)
  image_elf_test_write_rela64(
    buffer,
    rela_offset + 48,
    0x400003UL,
    0,
    8,
    addend=-8L,
  )
  image_elf_test_write_rel64(buffer, rel_offset, 0x400002UL, 2, 4)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_rewrite_machine_relative_type(
  data : Bytes,
  machine : Int,
  relative_type : Int,
) -> Bytes {
  let buffer = Array::make(data.length(), b'\x00')
  for i in 0..<data.length() {
    buffer[i] = data[i]
  }
  image_elf_test_set_u16_le(buffer, 18, machine)
  let shstr = b"\x00.shstrtab\x00.text\x00.symtab\x00.strtab\x00.rela.text\x00.rel.text\x00"
  let text = b"\x90\xc3\xcc\x00"
  let strtab = b"\x00main\x00target\x00puts\x00"
  let shstr_offset = 120 + 7 * 64
  let text_offset = shstr_offset + shstr.length()
  let symtab_offset = text_offset + text.length()
  let strtab_offset = symtab_offset + 96
  let rela_offset = strtab_offset + strtab.length()
  // The third RELA entry in image_elf_test_make_x86_64_with_relocations is
  // the symbol-free relative relocation at 0x400003.
  image_elf_test_set_u32_le(buffer, rela_offset + 48 + 8, relative_type)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_with_dynamic_libraries() -> Bytes {
  let section_table_offset = 64 + 2 * 56
  let shstr = b"\x00.shstrtab\x00.text\x00.interp\x00.dynamic\x00.dynstr\x00"
  let text = b"\x90\xc3"
  let interp = b"/lib64/ld-linux-x86-64.so.2\x00"
  let dynstr = b"\x00libc.so.6\x00libm.so.6\x00libdemo.so\x00/opt/lib\x00$ORIGIN/lib\x00"
  let shstr_offset = section_table_offset + 6 * 64
  let text_offset = shstr_offset + shstr.length()
  let interp_offset = text_offset + text.length()
  let dynamic_offset = interp_offset + interp.length()
  let dynstr_offset = dynamic_offset + 96
  let total = dynstr_offset + dynstr.length()
  let buffer = Array::make(total, b'\x00')
  image_elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  image_elf_test_set_u16_le(buffer, 16, 3)
  image_elf_test_set_u16_le(buffer, 18, 0x3e)
  image_elf_test_set_u32_le(buffer, 20, 1)
  image_elf_test_set_u64_le(buffer, 24, 0x400000UL)
  image_elf_test_set_u64_le(buffer, 32, 64UL)
  image_elf_test_set_u64_le(buffer, 40, section_table_offset.to_uint64())
  image_elf_test_set_u16_le(buffer, 52, 64)
  image_elf_test_set_u16_le(buffer, 54, 56)
  image_elf_test_set_u16_le(buffer, 56, 2)
  image_elf_test_set_u16_le(buffer, 58, 64)
  image_elf_test_set_u16_le(buffer, 60, 6)
  image_elf_test_set_u16_le(buffer, 62, 1)
  image_elf_test_set_u32_le(buffer, 64, 1)
  image_elf_test_set_u32_le(buffer, 68, 5)
  image_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 80, 0x400000UL)
  image_elf_test_set_u64_le(buffer, 96, text.length().to_uint64())
  image_elf_test_set_u64_le(buffer, 104, text.length().to_uint64())
  image_elf_test_set_u32_le(buffer, 120, 3)
  image_elf_test_set_u32_le(buffer, 124, 4)
  image_elf_test_set_u64_le(buffer, 128, interp_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 136, 0x400200UL)
  image_elf_test_set_u64_le(buffer, 152, interp.length().to_uint64())
  image_elf_test_set_u64_le(buffer, 160, interp.length().to_uint64())
  image_elf_test_write_section64_at(
    buffer,
    section_table_offset,
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
  image_elf_test_write_section64_at(
    buffer,
    section_table_offset,
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
  image_elf_test_write_section64_at(
    buffer,
    section_table_offset,
    3,
    17,
    1,
    2UL,
    0x400200UL,
    interp_offset,
    interp.length(),
    0,
    0,
  )
  image_elf_test_write_section64_at(
    buffer, section_table_offset, 4, 25, 6, 0UL, 0UL, dynamic_offset, 96, 5, 16,
  )
  image_elf_test_write_section64_at(
    buffer,
    section_table_offset,
    5,
    34,
    3,
    0UL,
    0UL,
    dynstr_offset,
    dynstr.length(),
    0,
    0,
  )
  image_elf_test_write_bytes(buffer, shstr_offset, shstr)
  image_elf_test_write_bytes(buffer, text_offset, text)
  image_elf_test_write_bytes(buffer, interp_offset, interp)
  image_elf_test_write_dynamic64(buffer, dynamic_offset, 1UL, 1UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 16, 1UL, 11UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 32, 14UL, 21UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 48, 15UL, 32UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 64, 29UL, 41UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 80, 0UL, 0UL)
  image_elf_test_write_bytes(buffer, dynstr_offset, dynstr)
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
fn image_elf_test_make_x86_64_dynamic_without_sections() -> Bytes {
  let text = b"\x55\xc3"
  let dynstr = b"\x00libx.so\x00libstrip.so\x00/strip/lib\x00$ORIGIN/strip\x00puts\x00printf\x00local\x00"
  let dynamic_size = 240
  let text_offset = 64 + 2 * 56
  let dynamic_offset = text_offset + text.length()
  let dynsym_offset = dynamic_offset + dynamic_size
  let dynstr_offset = dynsym_offset + 96
  let rela_offset = dynstr_offset + dynstr.length()
  let jmprel_offset = rela_offset + 72
  let base_addr = 0x600000UL
  let dynamic_addr = base_addr + (dynamic_offset - text_offset).to_uint64()
  let dynsym_addr = base_addr + (dynsym_offset - text_offset).to_uint64()
  let dynstr_addr = base_addr + (dynstr_offset - text_offset).to_uint64()
  let rela_addr = base_addr + (rela_offset - text_offset).to_uint64()
  let jmprel_addr = base_addr + (jmprel_offset - text_offset).to_uint64()
  let total = jmprel_offset + 24
  let load_size = total - text_offset
  let buffer = Array::make(total, b'\x00')
  image_elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  image_elf_test_set_u16_le(buffer, 16, 3)
  image_elf_test_set_u16_le(buffer, 18, 0x3e)
  image_elf_test_set_u32_le(buffer, 20, 1)
  image_elf_test_set_u64_le(buffer, 24, base_addr)
  image_elf_test_set_u64_le(buffer, 32, 64UL)
  image_elf_test_set_u16_le(buffer, 52, 64)
  image_elf_test_set_u16_le(buffer, 54, 56)
  image_elf_test_set_u16_le(buffer, 56, 2)
  image_elf_test_set_u32_le(buffer, 64, 1)
  image_elf_test_set_u32_le(buffer, 68, 5)
  image_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 80, base_addr)
  image_elf_test_set_u64_le(buffer, 96, load_size.to_uint64())
  image_elf_test_set_u64_le(buffer, 104, load_size.to_uint64())
  image_elf_test_set_u32_le(buffer, 120, 2)
  image_elf_test_set_u32_le(buffer, 124, 4)
  image_elf_test_set_u64_le(buffer, 128, dynamic_offset.to_uint64())
  image_elf_test_set_u64_le(buffer, 136, dynamic_addr)
  image_elf_test_set_u64_le(buffer, 152, dynamic_size.to_uint64())
  image_elf_test_set_u64_le(buffer, 160, dynamic_size.to_uint64())
  image_elf_test_write_bytes(buffer, text_offset, text)
  image_elf_test_write_dynamic64(buffer, dynamic_offset, 5UL, dynstr_addr)
  image_elf_test_write_dynamic64(
    buffer,
    dynamic_offset + 16,
    10UL,
    dynstr.length().to_uint64(),
  )
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 32, 6UL, dynsym_addr)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 48, 11UL, 24UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 64, 7UL, rela_addr)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 80, 8UL, 72UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 96, 9UL, 24UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 112, 1UL, 1UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 128, 14UL, 9UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 144, 15UL, 21UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 160, 29UL, 32UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 176, 2UL, 24UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 192, 20UL, 7UL)
  image_elf_test_write_dynamic64(
    buffer,
    dynamic_offset + 208,
    23UL,
    jmprel_addr,
  )
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 224, 0UL, 0UL)
  image_elf_test_write_symbol64(
    buffer,
    dynsym_offset + 24,
    46,
    0x12,
    0,
    0UL,
    0UL,
  )
  image_elf_test_write_symbol64(
    buffer,
    dynsym_offset + 48,
    51,
    0x12,
    0,
    0UL,
    0UL,
  )
  image_elf_test_write_symbol64(
    buffer,
    dynsym_offset + 72,
    58,
    0x12,
    1,
    0x600040UL,
    8UL,
  )
  image_elf_test_write_bytes(buffer, dynstr_offset, dynstr)
  image_elf_test_write_rela64(
    buffer,
    rela_offset,
    0x600001UL,
    0,
    8,
    addend=0x30L,
  )
  image_elf_test_write_rela64(buffer, rela_offset + 24, 0x600008UL, 1, 7)
  image_elf_test_write_rela64(
    buffer,
    rela_offset + 48,
    0x600018UL,
    3,
    7,
    addend=0x10L,
  )
  image_elf_test_write_rela64(buffer, jmprel_offset, 0x600010UL, 2, 7)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_dynamic_without_sections_rel_plt() -> Bytes {
  let source = image_elf_test_make_x86_64_dynamic_without_sections()
  let buffer = Array::make(source.length(), b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  let text_offset = 64 + 2 * 56
  let dynamic_offset = text_offset + b"\x55\xc3".length()
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 176, 2UL, 16UL)
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 192, 20UL, 17UL)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_dynamic_without_sections_relr() -> Bytes {
  let source = image_elf_test_make_x86_64_dynamic_without_sections()
  let text_offset = 64 + 2 * 56
  let dynamic_offset = text_offset + b"\x55\xc3".length()
  let relr_offset = source.length()
  let relr_size = 16
  let total = source.length() + relr_size
  let base_addr = 0x600000UL
  let relr_addr = base_addr + (relr_offset - text_offset).to_uint64()
  let load_size = total - text_offset
  let buffer = Array::make(total, b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  image_elf_test_set_u64_le(buffer, 96, load_size.to_uint64())
  image_elf_test_set_u64_le(buffer, 104, load_size.to_uint64())
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 112, 36UL, relr_addr)
  image_elf_test_write_dynamic64(
    buffer,
    dynamic_offset + 128,
    35UL,
    relr_size.to_uint64(),
  )
  image_elf_test_write_dynamic64(buffer, dynamic_offset + 144, 37UL, 8UL)
  image_elf_test_set_u64_le(buffer, relr_offset, 0x600018UL)
  image_elf_test_set_u64_le(buffer, relr_offset + 8, 0x0bUL)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_without_section_names() -> Bytes {
  let source = image_elf_test_make_x86_64()
  let buffer = Array::make(source.length(), b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  image_elf_test_set_u16_le(buffer, 62, 0)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_relocatable() -> Bytes {
  let source = image_elf_test_make_x86_64()
  let buffer = Array::make(source.length(), b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  image_elf_test_set_u16_le(buffer, 16, 1)
  image_elf_test_set_u64_le(buffer, 24, 0UL)
  image_elf_test_set_u64_le(buffer, 32, 0UL)
  image_elf_test_set_u16_le(buffer, 54, 0)
  image_elf_test_set_u16_le(buffer, 56, 0)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_make_x86_64_extended_tables() -> Bytes {
  let source = image_elf_test_make_x86_64()
  let buffer = Array::make(source.length(), b'\x00')
  for i in 0..<source.length() {
    buffer[i] = source[i]
  }
  image_elf_test_set_u16_le(buffer, 56, 0xffff)
  image_elf_test_set_u16_le(buffer, 60, 0)
  image_elf_test_set_u16_le(buffer, 62, 0xffff)
  image_elf_test_set_u64_le(buffer, 120 + 32, 6UL)
  image_elf_test_set_u32_le(buffer, 120 + 40, 1)
  image_elf_test_set_u32_le(buffer, 120 + 44, 1)
  Bytes::from_array(buffer)
}

///|
fn image_elf_test_rewrite_machine_osabi(
  data : Bytes,
  machine : Int,
  osabi : Int,
) -> Bytes {
  let buffer = Array::make(data.length(), b'\x00')
  for i in 0..<data.length() {
    buffer[i] = data[i]
  }
  buffer[7] = osabi.to_byte()
  image_elf_test_set_u16_le(buffer, 18, machine)
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
  assert_true(image.is_executable() == Some(true))
  assert_true(image.base_address() == Some(0x400000UL))
  assert_true(image.endian() == LittleEndian)
  match image.target() {
    Some(target) => {
      assert_true(target.matches("x86_64"))
      assert_true(target.filetype() == Elf)
      assert_true(target.system() == Linux)
      assert_true(target.abi() == GNU)
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
  let symbol_values = image.symbol_values()
  assert_true(symbol_values.length() == 2)
  assert_true(symbol_values.any(value => value.addr() == 0x400000UL))
  assert_true(symbol_values.any(value => value.value() == 0x400002UL))
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
test "image ELF backend refines target system and ABI from OSABI" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let cases : Array[
    (String, Int, Int, String, String, @core_theory.System, @core_theory.Abi),
  ] = [
    ("sysv", 0x3e, 0, "x86_64", "target:x86_64", UnknownSystem, SysV),
    ("hpux", 0x3e, 1, "x86_64", "target:x86_64", HPUX, UnknownAbi),
    ("netbsd", 0x3e, 2, "x86_64", "target:x86_64", NetBSD, UnknownAbi),
    ("linux", 0x3e, 3, "x86_64", "target:x86_64", Linux, GNU),
    ("solaris", 0x3e, 6, "x86_64", "target:x86_64", Solaris, UnknownAbi),
    ("aix", 0x3e, 7, "x86_64", "target:x86_64", AIX, UnknownAbi),
    ("irix", 0x3e, 8, "x86_64", "target:x86_64", IRIX, UnknownAbi),
    ("tru64", 0x3e, 10, "x86_64", "target:x86_64", Tru64, UnknownAbi),
    ("modesto", 0x3e, 11, "x86_64", "target:x86_64", Modesto, UnknownAbi),
    ("mips-rs3-le", 0x0a, 0, "mipsel", "target:mipsel", UnknownSystem, SysV),
    ("sparc32plus", 0x12, 0, "sparc", "target:sparc", UnknownSystem, SysV),
    ("arm-aeabi", 0x28, 64, "armv7", "target:armv7+le", UnknownSystem, EABI),
    ("hexagon", 0xa4, 0, "hexagon", "target:hexagon", UnknownSystem, SysV),
    (
      "loongarch-linux",
      0x102,
      3,
      "loongarch64",
      "target:loongarch64",
      Linux,
      GNU,
    ),
  ]
  for case in cases {
    let (name, machine, osabi, arch, target_name, system, abi) = case
    let (image, warnings) = expect_elf_image(
      @image.Image::of_bytes(
        image_elf_test_rewrite_machine_osabi(
          image_elf_test_make_x86_64(),
          machine,
          osabi,
        ),
        backend="elf",
      ),
    )
    assert_true(warnings.is_empty())
    match image.target() {
      Some(target) => {
        assert_true(target.matches(arch))
        assert_eq(target.name().show(), target_name)
        assert_true(target.filetype() == Elf)
        assert_true(target.system() == system)
        assert_true(target.abi() == abi)
      }
      None => fail("expected ELF target for " + name)
    }
  }
}

///|
test "image ELF backend resolves extended table counts" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_extended_tables(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.sections().any(section => section.name() == ".text"))
  assert_true(image.sections().any(section => section.name() == ".debug_info"))
  assert_true(image.symbols().any(symbol => symbol.name() == "main"))
  assert_true(image.segments().length() == 1)
  assert_true(image.segments()[0].addr() == 0x400000UL)
}

///|
test "image ELF backend extracts relocation metadata" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_with_relocations(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.symbols().length() == 2)
  assert_true(image.symbols().any(symbol => symbol.name() == "main"))
  assert_true(image.symbols().any(symbol => symbol.name() == "target"))
  let relocations = image.relocations()
  assert_true(relocations.length() == 3)
  let absolute = match
    relocations.search_by(relocation => relocation.fixup() == 0x400000UL) {
    Some(index) => relocations[index]
    None => fail("expected absolute relocation")
  }
  assert_true(absolute.target() == Some(0x400002UL))
  assert_true(absolute.addend() == Some(4L))
  assert_true(!absolute.uses_memory_addend())
  assert_true(!absolute.is_relative())
  let implicit = match
    relocations.search_by(relocation => relocation.fixup() == 0x400002UL) {
    Some(index) => relocations[index]
    None => fail("expected REL relocation")
  }
  assert_true(implicit.target() == Some(0x400002UL))
  assert_true(implicit.addend() == None)
  assert_true(implicit.uses_memory_addend())
  assert_true(!implicit.is_relative())
  let relative = match
    relocations.search_by(relocation => relocation.fixup() == 0x400003UL) {
    Some(index) => relocations[index]
    None => fail("expected relative relocation")
  }
  assert_true(relative.target() == None)
  assert_true(relative.addend() == Some(-8L))
  assert_true(!relative.uses_memory_addend())
  assert_true(relative.is_relative())
  let references = image.external_references()
  assert_true(references.length() == 1)
  assert_true(references[0].addr() == 0x400001UL)
  assert_true(references[0].name() == "puts")
}

///|
test "image ELF backend recognizes architecture-relative relocation types" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let cases : Array[(String, Int, Int)] = [
    ("m68k", 0x04, 22),
    ("sparc", 0x02, 22),
    ("sparcv9", 0x2b, 22),
    ("mips", 0x08, 3),
    ("mips-rs3-le", 0x0a, 3),
    ("powerpc", 0x14, 22),
    ("powerpc64", 0x15, 22),
    ("systemz", 0x16, 12),
    ("arm", 0x28, 23),
    ("arc", 0x2d, 56),
    ("arc-compact", 0x5d, 56),
    ("xtensa", 0x5e, 5),
    ("hexagon", 0xa4, 35),
    ("aarch64", 0xb7, 1027),
    ("aarch64-p32", 0xb7, 183),
    ("arc-compact2", 0xc3, 56),
    ("amdgpu", 0xe0, 13),
    ("riscv", 0xf3, 3),
    ("ve", 0xfb, 17),
    ("csky", 0xfc, 9),
    ("loongarch", 0x102, 3),
  ]
  for case in cases {
    let (name, machine, typ) = case
    let fixture = image_elf_test_rewrite_machine_relative_type(
      image_elf_test_make_x86_64_with_relocations(),
      machine,
      typ,
    )
    let (image, warnings) = expect_elf_image(
      @image.Image::of_bytes(fixture, backend="elf"),
    )
    assert_true(warnings.is_empty())
    let relocation = match
      image
      .relocations()
      .search_by(relocation => relocation.fixup() == 0x400003UL) {
      Some(index) => image.relocations()[index]
      None => fail("expected relative relocation for " + name)
    }
    assert_true(relocation.target() == None)
    assert_true(relocation.addend() == Some(-8L))
    assert_true(!relocation.uses_memory_addend())
    assert_true(relocation.is_relative())
  }
}

///|
test "image ELF backend extracts dynamic link metadata" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_with_dynamic_libraries(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.required_libraries() == ["libc.so.6", "libm.so.6"])
  assert_true(image.interpreter() == Some("/lib64/ld-linux-x86-64.so.2"))
  assert_true(image.soname() == Some("libdemo.so"))
  assert_true(image.rpaths() == ["/opt/lib"])
  assert_true(image.runpaths() == ["$ORIGIN/lib"])
}

///|
test "image ELF backend loads symbol tables without section names" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_without_section_names(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.sections().is_empty())
  let symbols = image.symbols()
  assert_true(symbols.length() == 2)
  assert_true(symbols.any(symbol => symbol.name() == "main"))
  assert_true(symbols.any(symbol => symbol.name() == "data_object"))
  assert_true(image.symbols_of_segment(image.segments()[0]).length() == 2)
}

///|
test "image ELF backend maps alloc sections when program headers are absent" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_relocatable(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.entry_point() == 0UL)
  assert_true(image.is_executable() == Some(false))
  let segments = image.segments()
  assert_true(segments.length() == 1)
  assert_true(segments[0].name() == ".text")
  assert_true(segments[0].addr() == 0x400000UL)
  assert_true(segments[0].offset() > 0)
  assert_true(segments[0].is_readable())
  assert_true(!segments[0].is_writable())
  assert_true(segments[0].is_executable())
  inspect(segments[0].memory().hexdump(), content="90 c3 cc 00")
  assert_true(image.sections_of_segment(segments[0]).length() == 1)
  let main_symbol = match
    image.symbols().search_by(symbol => symbol.name() == "main") {
    Some(index) => image.symbols()[index]
    None => fail("expected main symbol")
  }
  match image.memory_of_symbol(main_symbol) {
    Some((memory, rest)) => {
      assert_true(rest.length() == 0)
      inspect(memory.hexdump(), content="90 c3")
    }
    None => fail("expected main symbol memory")
  }
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
test "image ELF backend extracts PT_DYNAMIC metadata without section headers" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_dynamic_without_sections(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  assert_true(image.sections().is_empty())
  assert_true(image.symbols().is_empty())
  assert_true(image.segments().length() == 1)
  assert_true(image.segments()[0].addr() == 0x600000UL)
  assert_true(image.base_address() == Some(0x600000UL))
  assert_true(image.required_libraries() == ["libx.so"])
  assert_true(image.soname() == Some("libstrip.so"))
  assert_true(image.rpaths() == ["/strip/lib"])
  assert_true(image.runpaths() == ["$ORIGIN/strip"])
  let relocations = image.relocations()
  assert_true(relocations.length() == 2)
  let relative = match
    relocations.search_by(relocation => relocation.fixup() == 0x600001UL) {
    Some(index) => relocations[index]
    None => fail("expected relative dynamic relocation")
  }
  assert_true(relative.addend() == Some(0x30L))
  assert_true(!relative.uses_memory_addend())
  assert_true(relative.is_relative())
  let targeted = match
    relocations.search_by(relocation => relocation.fixup() == 0x600018UL) {
    Some(index) => relocations[index]
    None => fail("expected dynamic symbol target relocation")
  }
  assert_true(targeted.target() == Some(0x600040UL))
  assert_true(targeted.addend() == Some(0x10L))
  assert_true(!targeted.uses_memory_addend())
  assert_true(!targeted.is_relative())
  let references = image.external_references()
  assert_true(references.length() == 2)
  assert_true(references[0].addr() == 0x600008UL)
  assert_true(references[0].name() == "puts")
  assert_true(references[1].addr() == 0x600010UL)
  assert_true(references[1].name() == "printf")
  match image.with_applied_relocations() {
    Ok(applied) => {
      match applied.segments()[0].memory().load(0x600001UL, width=64) {
        Ok(word) => assert_true(word.to_uint64() == 0x600030UL)
        Err(reason) => fail(reason)
      }
      match applied.segments()[0].memory().load(0x600018UL, width=64) {
        Ok(word) => assert_true(word.to_uint64() == 0x600050UL)
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "image ELF backend extracts DT_REL PLT relocations without section headers" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_dynamic_without_sections_rel_plt(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  let references = image.external_references()
  assert_true(references.length() == 2)
  assert_true(references[0].addr() == 0x600008UL)
  assert_true(references[0].name() == "puts")
  assert_true(references[1].addr() == 0x600010UL)
  assert_true(references[1].name() == "printf")
}

///|
test "image ELF backend extracts DT_RELR relocations without section headers" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let (image, warnings) = expect_elf_image(
    @image.Image::of_bytes(
      image_elf_test_make_x86_64_dynamic_without_sections_relr(),
      backend="elf",
    ),
  )
  assert_true(warnings.is_empty())
  let relr = image
    .relocations()
    .filter(relocation => {
      relocation.is_relative() && relocation.fixup() >= 0x600018UL
    })
  assert_true(
    relr.map(relocation => relocation.fixup()) ==
    [0x600018UL, 0x600020UL, 0x600030UL],
  )
  for relocation in relr {
    assert_true(relocation.is_relative())
    assert_true(relocation.uses_memory_addend())
    assert_true(relocation.target() == None)
    assert_true(relocation.addend() == None)
  }
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
