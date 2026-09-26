///|
test "raw ELF reader exposes the headers the image loader projects" {
  let data = image_elf_test_make_x86_64()
  let elf = @elf.from_bytes(data).unwrap()
  debug_inspect(
    (elf.e_type, elf.e_machine, elf.e_osabi),
    content="(ET_EXEC, EM_X86_64, ELFOSABI_LINUX)",
  )
  debug_inspect(
    elf.e_segments,
    content=(
      #|[
      #|  {
      #|    p_type: PT_LOAD,
      #|    p_flags: [PF_R, PF_X],
      #|    p_vaddr: 4194304,
      #|    p_paddr: 0,
      #|    p_align: 0,
      #|    p_memsz: 6,
      #|    p_filesz: 4,
      #|    p_offset: 549,
      #|  },
      #|]
    ),
  )
  debug_inspect(
    @elf.section_names(data, elf),
    content=(
      #|[
      #|  Some(""),
      #|  Some(".shstrtab"),
      #|  Some(".text"),
      #|  Some(".debug_info"),
      #|  Some(".symtab"),
      #|  Some(".strtab"),
      #|]
    ),
  )
  let symtab = elf.e_sections[4]
  let names = @elf.symbols(data, elf, symtab)
    .unwrap()
    .map(s => @elf.symbol_name(data, elf, symtab, s).unwrap())
  debug_inspect(names, content="[\"\", \"main\", \"data_object\"]")
  // the relocatable fixture has no program headers
  let object = @elf.from_bytes(image_elf_test_make_x86_64_relocatable()).unwrap()
  assert_true(object.e_type is ET_REL && object.e_segments.is_empty())
  // and the stripped one has no section headers
  let stripped = @elf.from_bytes(image_elf_test_make_x86_64_without_sections()).unwrap()
  assert_true(
    stripped.e_sections.is_empty() && stripped.e_segments.length() == 1,
  )
}

///|
test "raw ELF reader accepts files the image loader rejects" {
  guard @image.register_builtin_backends() is Ok(_) else {
    fail("can't register builtin backends")
  }
  // a core-like file with a single note program header and no sections
  let source = image_elf_test_make_x86_64_without_sections()
  let buffer = source.to_array()
  image_elf_test_set_u16_le(buffer, 16, 4) // ET_CORE
  image_elf_test_set_u32_le(buffer, 64, 4) // PT_NOTE
  let core = Bytes::from_array(buffer)
  assert_true(@image.Image::of_bytes(core, backend="elf") is Err(_))
  let elf = @elf.from_bytes(core).unwrap()
  assert_true(elf.e_type is ET_CORE)
  assert_true(elf.e_segments[0].p_type is PT_NOTE)
  // an unknown machine still loads, with its raw value preserved
  let unknown = image_elf_test_rewrite_machine_osabi(
    image_elf_test_make_x86_64(),
    0x7777,
    0x33,
  )
  let elf = @elf.from_bytes(unknown).unwrap()
  debug_inspect(
    (elf.e_machine, elf.e_osabi),
    content="(EM_EXT(30583), ELFOSABI_EXT(51))",
  )
  assert_true(@image.Image::of_bytes(unknown, backend="elf") is Ok(_))
}

///|
test "image ELF specification keeps the raw program headers and sections" {
  guard @image.register_builtin_backends() is Ok(_) else {
    fail("can't register builtin backends")
  }
  let (image, _) = expect_elf_image(
    @image.Image::of_bytes(image_elf_test_make_x86_64(), backend="elf"),
  )
  let spec = image.spec()
  debug_inspect(
    spec.facts("llvm:elf-program-header").map(f => f.fields()),
    content=(
      #|[[("name", "00"), ("off", "549"), ("size", "4")]]
    ),
  )
  debug_inspect(
    spec.facts("llvm:elf-virtual-program-header").map(f => f.fields()),
    content=(
      #|[[("addr", "4194304"), ("name", "00"), ("size", "6")]]
    ),
  )
  debug_inspect(
    spec.facts("llvm:elf-program-header-flags").map(f => f.fields()),
    content=(
      #|[
      #|  [
      #|    ("ld", "true"),
      #|    ("name", "00"),
      #|    ("r", "true"),
      #|    ("w", "false"),
      #|    ("x", "true"),
      #|  ],
      #|]
    ),
  )
  debug_inspect(
    spec.facts("llvm:section-entry").map(f => f.fields()),
    content=(
      #|[
      #|  [("addr", "0"), ("name", ".strtab"), ("off", "630"), ("size", "18")],
      #|  [("addr", "0"), ("name", ".symtab"), ("off", "558"), ("size", "72")],
      #|  [
      #|    ("addr", "0"),
      #|    ("name", ".debug_info"),
      #|    ("off", "553"),
      #|    ("size", "5"),
      #|  ],
      #|  [
      #|    ("addr", "4194304"),
      #|    ("name", ".text"),
      #|    ("off", "549"),
      #|    ("size", "4"),
      #|  ],
      #|  [("addr", "0"), ("name", ".shstrtab"), ("off", "504"), ("size", "45")],
      #|]
    ),
  )
  debug_inspect(
    spec.facts("llvm:code-entry").map(f => f.fields()),
    content=(
      #|[[("name", ".text"), ("off", "549"), ("size", "4")]]
    ),
  )
  // the image-derived facts are still there
  assert_true(spec.facts("segment").length() == 1)
  assert_true(spec.facts("llvm:entry-point").length() == 1)
  // and they follow the image when it changes
  let extended = image.add_symbol(
    @image.Symbol::create(
      name="extra",
      addr=0x400003UL,
      size=1,
      is_function=true,
    ),
  )
  assert_true(
    extended.spec().facts("named-symbol").length() ==
    spec.facts("named-symbol").length() + 1,
  )
}
