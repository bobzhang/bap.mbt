///|
fn relocatable_object() -> Bytes {
  let strtab = b"\x00main\x00counter\x00"
  let symtab = concat([
    sym64(0, 0, 0, 0, 0, 0),
    sym64(1, 0x12, 0, 1, 0, 2),
    sym64(6, 0x11, 2, 2, 0, 4),
  ])
  let rela = le64([1, (2UL << 32) | 4UL, (-4L).reinterpret_as_uint64()])
  build_elf(typ=1, sections=[
    tsection(".text", 1, b"\x55\xc3", flags=6, align=16),
    tsection(".data", 1, b"\x01\x02\x03\x04", flags=3, align=8),
    tsection(".bss", 8, b"\x00\x00\x00\x00\x00\x00\x00\x00", flags=3, align=8),
    tsection(".symtab", 2, symtab, link=5, info=1, align=8, entsize=24),
    tsection(".strtab", 3, strtab),
    tsection(".rela.text", 4, rela, link=4, info=1, align=8, entsize=24),
    tsection(".comment", 1, b"GCC\x00", flags=0x30, entsize=1),
  ])
}

///|
test "raw reader parses relocatable objects without program headers" {
  let data = relocatable_object()
  let elf = @elf.from_bytes(data).unwrap()
  debug_inspect(
    (elf.e_class, elf.e_data, elf.e_type, elf.e_machine, elf.e_osabi),
    content="(ELFCLASS64, ELFDATA2LSB, ET_REL, EM_X86_64, ELFOSABI_SYSV)",
  )
  assert_eq(elf.e_version, 1)
  assert_eq(elf.e_file_version, 1)
  assert_eq(elf.e_ehsize, 64)
  assert_true(elf.e_segments.is_empty())
  assert_eq(elf.e_phtab.entry_num, 0)
  assert_eq(elf.e_sections.length(), 9)
  assert_eq(elf.e_shstrndx, 8)
  debug_inspect(
    @elf.section_names(data, elf),
    content=(
      #|[
      #|  Some(""),
      #|  Some(".text"),
      #|  Some(".data"),
      #|  Some(".bss"),
      #|  Some(".symtab"),
      #|  Some(".strtab"),
      #|  Some(".rela.text"),
      #|  Some(".comment"),
      #|  Some(".shstrtab"),
      #|]
    ),
  )
  let text = elf.e_sections[1]
  debug_inspect(
    text,
    content=(
      #|{
      #|  sh_name: 1,
      #|  sh_type: SHT_PROGBITS,
      #|  sh_flags: [SHF_EXECINSTR, SHF_ALLOC],
      #|  sh_addr: 0,
      #|  sh_size: 2,
      #|  sh_link: 0,
      #|  sh_info: 0,
      #|  sh_addralign: 16,
      #|  sh_entsize: 0,
      #|  sh_offset: 64,
      #|}
    ),
  )
  assert_true(text.is_alloc() && text.is_executable() && !text.is_writable())
  assert_eq(text.flags_bits(), 6UL)
  assert_eq(@elf.string_of_section(data, text).unwrap(), b"\x55\xc3")
  let bss = elf.e_sections[3]
  assert_true(bss.sh_type is SHT_NOBITS && bss.sh_size == 8UL)
  // unknown flag bits are kept as extension flags
  let comment = elf.e_sections[7]
  debug_inspect(comment.sh_flags, content="[SHF_EXT(5), SHF_EXT(4)]")
  assert_eq(comment.flags_bits(), 0x30UL)
  assert_true(
    @elf.find_section(data, elf, ".rela.text") is Some(s) &&
    s.sh_type is SHT_RELA,
  )
  assert_true(@elf.find_section(data, elf, ".missing") is None)
}

///|
test "raw reader reads symbol and relocation tables" {
  let data = relocatable_object()
  let elf = @elf.from_bytes(data).unwrap()
  let symtab = elf.e_sections[4]
  let symbols = @elf.symbols(data, elf, symtab).unwrap()
  debug_inspect(
    symbols.map(s => {
      (
        @elf.symbol_name(data, elf, symtab, s).unwrap(),
        s.st_bind(),
        s.st_type(),
        s.st_visibility(),
        s.st_shndx,
        s.st_size,
      )
    }),
    content=(
      #|[
      #|  ("", 0, 0, 0, 0, 0),
      #|  ("main", 1, 2, 0, 1, 2),
      #|  ("counter", 1, 1, 2, 2, 4),
      #|]
    ),
  )
  let relocations = @elf.relocations(data, elf, elf.e_sections[6]).unwrap()
  assert_eq(relocations.length(), 1)
  let rel = relocations[0]
  assert_eq(rel.r_offset, 1UL)
  assert_eq(rel.r_sym(elf.e_class), 2U)
  assert_eq(rel.r_type(elf.e_class), 4U)
  assert_eq(rel.r_addend, Some(-4L))
  // a symbol table that isn't entry-aligned is rejected
  let broken = { ..symtab, sh_size: 25, }
  assert_true(@elf.symbols(data, elf, broken) is Err(_))
  assert_eq(@elf.string_at(b"\x00abc\x00"[:], 1), Ok("abc"))
  assert_true(@elf.string_at(b"\x00abc"[:], 1) is Err(_))
}

///|
test "raw reader keeps program header physical addresses and alignment" {
  let code = b"\x90\x90\xc3"
  let start = contents_offset(2)
  let data = build_elf(
    entry=0x401000,
    phdrs=[
      {
        typ: 1,
        flags: 5,
        offset: start,
        vaddr: 0x401000,
        paddr: 0x8000,
        filesz: 3,
        memsz: 0x10,
        align: 0x1000,
      },
      {
        typ: 0x6474e551, // PT_GNU_STACK
        flags: 6,
        offset: 0,
        vaddr: 0,
        paddr: 0,
        filesz: 0,
        memsz: 0,
        align: 16,
      },
    ],
    tail=code,
  )
  let elf = @elf.from_bytes(data).unwrap()
  // no section header table at all, as in stripped (sstrip) executables
  assert_true(elf.e_sections.is_empty())
  assert_eq(elf.e_shtab.table_offset, 0UL)
  assert_eq(elf.e_entry, 0x401000UL)
  debug_inspect(
    elf.e_segments,
    content=(
      #|[
      #|  {
      #|    p_type: PT_LOAD,
      #|    p_flags: [PF_R, PF_X],
      #|    p_vaddr: 4198400,
      #|    p_paddr: 32768,
      #|    p_align: 4096,
      #|    p_memsz: 16,
      #|    p_filesz: 3,
      #|    p_offset: 176,
      #|  },
      #|  {
      #|    p_type: PT_OTHER(1685382481),
      #|    p_flags: [PF_R, PF_W],
      #|    p_vaddr: 0,
      #|    p_paddr: 0,
      #|    p_align: 16,
      #|    p_memsz: 0,
      #|    p_filesz: 0,
      #|    p_offset: 0,
      #|  },
      #|]
    ),
  )
  let load = elf.e_segments[0]
  assert_true(load.is_readable() && load.is_executable() && !load.is_writable())
  assert_eq(load.flags_bits(), 5U)
  assert_eq(@elf.string_of_segment(data, load).unwrap(), code)
}

///|
test "raw reader preserves unknown enumeration values" {
  let data = build_elf(
    typ=0xfe00,
    machine=0x1234,
    osabi=0x42,
    flags=0x5000402,
    sections=[
      tsection(".gnu.hash", 0x6ffffff6, b"\x00\x00\x00\x00", flags=0x200002),
    ],
  )
  let elf = @elf.from_bytes(data).unwrap()
  debug_inspect(
    (elf.e_type, elf.e_machine, elf.e_osabi, elf.e_flags),
    content="(ET_EXT(65024), EM_EXT(4660), ELFOSABI_EXT(66), 83887106)",
  )
  let hash = elf.e_sections[1]
  debug_inspect(hash.sh_type, content="SHT_EXT(1879048182)")
  debug_inspect(hash.sh_flags, content="[SHF_EXT(21), SHF_ALLOC]")
  // the enumerations round trip through their raw encodings
  assert_eq(elf.e_machine.to_int(), 0x1234)
  assert_eq(elf.e_type.to_int(), 0xfe00)
  assert_eq(@elf.EMachine::of_int(183), EM_AARCH64)
  assert_eq(@elf.EMachine::of_int(0x3e).to_int(), 0x3e)
  assert_eq(@elf.EOsabi::of_int(3), ELFOSABI_LINUX)
  assert_eq(@elf.PType::of_int(4), PT_NOTE)
  assert_eq(@elf.ShType::of_int(11).to_int(), 11U)
  assert_eq(@elf.PFlag::of_bits(0x80000007), [PF_EXT(31), PF_R, PF_W, PF_X])
  assert_eq(@elf.PFlag::to_bits([PF_EXT(31), PF_R, PF_W, PF_X]), 0x80000007)
}

///|
test "raw reader parses 32-bit big-endian core files" {
  let note = b"\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x01CORE\x00\x00\x00\x00"
  let data = build_elf(
    is64=false,
    big=true,
    typ=4,
    machine=8,
    phdrs=[
      {
        typ: 4,
        flags: 0,
        offset: contents_offset(1, is64=false),
        vaddr: 0,
        paddr: 0,
        filesz: note.length().to_uint64(),
        memsz: 0,
        align: 4,
      },
    ],
    tail=note,
  )
  let elf = @elf.from_bytes(data).unwrap()
  debug_inspect(
    (elf.e_class, elf.e_data, elf.e_type, elf.e_machine),
    content="(ELFCLASS32, ELFDATA2MSB, ET_CORE, EM_MIPS)",
  )
  assert_eq(elf.endian(), BigEndian)
  assert_eq(elf.bits(), 32)
  assert_eq(elf.e_ehsize, 52)
  assert_true(elf.e_segments[0].p_type is PT_NOTE)
  assert_eq(@elf.string_of_segment(data, elf.e_segments[0]).unwrap(), note)
}

///|
test "raw reader parses 32-bit sections and symbols" {
  let data = build_elf(is64=false, typ=1, machine=3, sections=[
    tsection(".text", 1, b"\xc3", flags=6, addr=0x80000000, align=4),
  ])
  let elf = @elf.from_bytes(data).unwrap()
  // 32-bit addresses are zero-extended
  assert_eq(elf.e_sections[1].sh_addr, 0x80000000UL)
  assert_eq(@elf.section_name(data, elf, elf.e_sections[1]), Ok(".text"))
}

///|
test "raw reader honors the data position and length" {
  let object = relocatable_object()
  let data = concat([b"garbage!", object, b"trailer"])
  let elf = @elf.from_bytes(data, pos=8, len=object.length()).unwrap()
  assert_true(elf == @elf.from_bytes(object).unwrap())
  assert_eq(@elf.section_name(data, elf, elf.e_sections[1], pos=8), Ok(".text"))
  assert_eq(
    @elf.string_of_section(data, elf.e_sections[1], pos=8).unwrap(),
    b"\x55\xc3",
  )
  assert_true(@elf.from_bigstring(data, pos=8) is Ok(_))
  // tables beyond the given length are out of bounds
  assert_true(@elf.from_bytes(data, pos=8, len=object.length() - 1) is Err(_))
  assert_true(@elf.from_bytes(data, pos=data.length() + 1) is Err(_))
}

///|
test "raw reader resolves extended numbering" {
  let object = relocatable_object()
  let buf = object.to_array()
  let w : Writer = { buf, big: false, }
  let shoff = object[40:48]
    .to_array()
    .rev_fold(init=0UL, (acc, b) => (acc << 8) | b.to_uint64())
  // e_shnum = 0 and e_shstrndx = SHN_XINDEX: both come from section 0
  w.put(60, 2, 0)
  w.put(62, 2, 0xffff)
  w.put(shoff.to_int() + 32, 8, 9)
  w.put(shoff.to_int() + 40, 4, 8)
  let data = Bytes::from_array(w.buf)
  let elf = @elf.from_bytes(data).unwrap()
  assert_eq(elf.e_sections.length(), 9)
  assert_eq(elf.e_shstrndx, 8)
  assert_eq(@elf.section_name(data, elf, elf.e_sections[1]), Ok(".text"))
  // PN_XNUM without a section table can't be resolved
  let w : Writer = { buf: build_elf().to_array(), big: false, }
  w.put(56, 2, 0xffff)
  assert_eq(
    @elf.from_bytes(Bytes::from_array(w.buf)),
    Err("extended ELF program table is missing"),
  )
}

///|
test "raw reader rejects malformed inputs" {
  assert_eq(@elf.from_bytes(b"not an elf file!"), Err("not an ELF file"))
  assert_eq(@elf.from_bytes(b"\x7fELF"), Err("truncated ELF header"))
  let header = build_elf().to_array()
  header[4] = b'\x03'
  assert_eq(
    @elf.from_bytes(Bytes::from_array(header)),
    Err("unsupported ELF class: 3"),
  )
  let header = build_elf().to_array()
  header[5] = b'\x00'
  assert_eq(
    @elf.from_bytes(Bytes::from_array(header)),
    Err("unsupported ELF data encoding: 0"),
  )
  assert_eq(
    @elf.from_bytes(build_elf()[0:40].to_owned()),
    Err("truncated ELF header"),
  )
  // a section table that doesn't fit the file
  let object = relocatable_object()
  assert_eq(
    @elf.from_bytes(object[0:object.length() - 1].to_owned()),
    Err("ELF section table is out of bounds"),
  )
  // entries smaller than the class' headers
  let w : Writer = { buf: object.to_array(), big: false, }
  w.put(58, 2, 32)
  assert_eq(
    @elf.from_bytes(Bytes::from_array(w.buf)),
    Err("ELF section headers are too small"),
  )
  // an invalid name table index is not an error of the reader
  let w : Writer = { buf: object.to_array(), big: false, }
  w.put(62, 2, 42)
  let elf = @elf.from_bytes(Bytes::from_array(w.buf)).unwrap()
  assert_true(
    @elf.section_name(Bytes::from_array(w.buf), elf, elf.e_sections[1])
    is Err(_),
  )
}
