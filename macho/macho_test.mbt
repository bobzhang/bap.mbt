///|
fn parse_ok(data : Bytes) -> @macho.MachO raise {
  match @macho.parse(data) {
    Ok(m) => m
    Err(e) => fail(e)
  }
}

///|
fn[T] ok(r : Result[T, String]) -> T raise {
  match r {
    Ok(x) => x
    Err(e) => fail(e)
  }
}

///|
fn hex(x : UInt64) -> String {
  "0x" + x.to_string(radix=16)
}

///|
test "x86-64 executable: header and segments" {
  let data = @objects.x86_64_macho()
  assert_true(@macho.is_macho(data))
  assert_true(!@macho.is_fat(data))
  let m = parse_ok(data)
  debug_inspect(
    m.header,
    content=(
      #|{
      #|  is64: true,
      #|  endian: LittleEndian,
      #|  cputype: 16777223,
      #|  cpusubtype: 3,
      #|  filetype: 2,
      #|  ncmds: 9,
      #|  sizeofcmds: 808,
      #|  flags: 2097285,
      #|}
    ),
  )
  let segments = m
    .segments()
    .map(s => {
      "\{s.segname} \{hex(s.vmaddr)}+\{hex(s.vmsize)} @\{hex(s.fileoff)}+\{hex(s.filesize)} prot=\{s.initprot} " +
      s.sections.map(x => x.sectname).join(",")
    })
  inspect(
    segments.join("\n"),
    content=(
      #|__PAGEZERO 0x0+0x100000000 @0x0+0x0 prot=0 
      #|__TEXT 0x100000000+0x1000 @0x0+0x1000 prot=5 __text,__stubs
      #|__DATA 0x100001000+0x1000 @0x1000+0x10 prot=3 __got,__bss
      #|__LINKEDIT 0x100002000+0x1000 @0x1010+0x78 prot=1 
    ),
  )
  let sections = m.sections()
  assert_eq(sections.length(), 4)
  assert_true(sections[0].is_text() && sections[0].is_code())
  assert_true(sections[1].contains_symbol_stubs() && sections[1].is_code())
  assert_true(sections[2].contains_symbol_stubs() && !sections[2].is_code())
  assert_true(sections[3].is_zerofill())
  assert_eq(sections[1].reserved2, 6)
  assert_eq(m.is_executable(), true)
  assert_eq(m.image_base(), 0x100000000)
  assert_eq(m.main_entry_offset(), Some(0x400))
  assert_eq(m.address_of_offset(0x400), Some(0x100000400))
  assert_eq(m.address_of_offset(0x1008), Some(0x100001008))
  assert_eq(m.address_of_offset(0x2000), None)
  assert_eq(m.thread_entry(), None)
  debug_inspect(
    m.dylibs(),
    content=(
      #|[
      #|  {
      #|    cmd: 12,
      #|    name: "/usr/lib/libSystem.B.dylib",
      #|    timestamp: 2,
      #|    current_version: 86467587,
      #|    compatibility_version: 65536,
      #|  },
      #|]
    ),
  )
}

///|
test "x86-64 executable: symbols, indirect symbols and function starts" {
  let data = @objects.x86_64_macho()
  let m = parse_ok(data)
  let symbols = ok(@macho.symbols(data, m)).map(s => {
    "\{s.index} \{s.name} type=\{s.n_type} sect=\{s.n_sect} \{hex(s.n_value)} ext=\{s.is_external()} stab=\{s.is_stab()}"
  })
  inspect(
    symbols.join("\n"),
    content=(
      #|0 _foo type=14 sect=1 0x10000040e ext=false stab=false
      #|1 __mh_execute_header type=15 sect=1 0x100000000 ext=true stab=false
      #|2 _main type=15 sect=1 0x100000400 ext=true stab=false
      #|3 _exit type=1 sect=0 0x0 ext=true stab=false
    ),
  )
  debug_inspect(
    m.dysymtab().map(d => (d.nlocalsym, d.nextdefsym, d.nundefsym)),
    content="Some((1, 2, 1))",
  )
  debug_inspect(ok(@macho.indirect_symbols(data, m)), content="[3, 3]")
  inspect(
    ok(@macho.function_starts(data, m)).map(hex).join(" "),
    content="0x100000400 0x10000040e 0x100000411",
  )
  debug_inspect(ok(@macho.external_relocations(data, m)), content="[]")
}

///|
test "universal binary: architectures and slices" {
  let data = @objects.fat_macho()
  assert_true(@macho.is_fat(data))
  assert_true(!@macho.is_macho(data))
  let archs = ok(@macho.fat_archs(data))
  inspect(
    archs
    .map(a => {
      "\{@macho.arch_name(a.cputype, a.cpusubtype)} @\{hex(a.offset)}+\{hex(a.size)} align=\{a.align}"
    })
    .join("\n"),
    content=(
      #|x86_64 @0x1000+0x1088 align=12
      #|arm64e @0x3000+0x1030 align=12
    ),
  )
  let x86 = ok(@macho.fat_slice(data, archs[0]))
  assert_eq(x86, @objects.x86_64_macho())
  let arm = parse_ok(ok(@macho.fat_slice(data, archs[1])))
  assert_eq(arm.header.cputype, @macho.CPU_TYPE_ARM64)
  assert_eq(
    @macho.arch_name(arm.header.cputype, arm.header.cpusubtype),
    "arm64e",
  )
  // a Java class file shares the magic but has a huge "count"
  assert_true(!@macho.is_fat(b"\xca\xfe\xba\xbe\x00\x00\x00\x34"))
  let bad : @macho.FatArch = {
    cputype: 7,
    cpusubtype: 3,
    offset: 0x10000,
    size: 16,
    align: 0,
  }
  debug_inspect(
    @macho.fat_slice(data, bad),
    content="Err(\"universal binary architecture is out of bounds\")",
  )
}

///|
test "arch names" {
  inspect(
    [
      @macho.arch_name(7, 3),
      @macho.arch_name(0x01000007, 8),
      @macho.arch_name(0x0100000c, 0),
      @macho.arch_name(0x0200000c, 1),
      @macho.arch_name(12, 9),
      @macho.arch_name(12, 11),
      @macho.arch_name(18, 0),
      @macho.arch_name(0x01000012, 0),
    ].join(" "),
    content="i386 x86_64h arm64 arm64_32 armv7 armv7s ppc ppc64",
  )
}

///|
test "i386 executable: 32-bit commands and LC_UNIXTHREAD entry" {
  let data = @objects.i386_macho()
  let m = parse_ok(data)
  assert_eq(m.header.is64, false)
  assert_eq(m.header.cputype, @macho.CPU_TYPE_X86)
  assert_eq(m.thread_entry(), Some(0x1400))
  assert_eq(m.main_entry_offset(), None)
  assert_eq(m.symtab(), None)
  debug_inspect(ok(@macho.symbols(data, m)), content="[]")
  let text = m.sections()[0]
  inspect(
    "\{text.segname},\{text.sectname} \{hex(text.addr)}+\{hex(text.size)} @\{text.offset}",
    content="__TEXT,__text 0x1400+0x3 @1024",
  )
}

///|
test "relocatable object: section relocations" {
  let data = @objects.x86_64_macho_object()
  let m = parse_ok(data)
  assert_eq(m.header.filetype, @macho.MH_OBJECT)
  assert_eq(m.is_executable(), false)
  assert_eq(m.image_base(), 0)
  let text = m.sections()[0]
  debug_inspect(
    ok(@macho.relocations(data, m, text)),
    content=(
      #|[
      #|  {
      #|    r_word0: 1,
      #|    r_word1: 754974721,
      #|    r_address: 1,
      #|    r_symbolnum: 1,
      #|    r_pcrel: true,
      #|    r_length: 2,
      #|    r_extern: true,
      #|    r_type: 2,
      #|    r_scattered: false,
      #|  },
      #|]
    ),
  )
  inspect(
    ok(@macho.symbols(data, m)).map(s => s.name).join(","),
    content="_main,_puts",
  )
}

///|
test "malformed files" {
  debug_inspect(
    @macho.parse(b"\x7fELF"),
    content=(
      #|Err("not a Mach-O file")
    ),
  )
  let data = @objects.x86_64_macho()
  debug_inspect(
    @macho.parse(data[:100].to_owned()),
    content="Err(\"Mach-O load commands are out of bounds\")",
  )
  // a load command size that runs past the commands
  let bytes = data.to_array()
  bytes[36] = b'\xff'
  debug_inspect(
    @macho.parse(Bytes::from_array(bytes)),
    content="Err(\"Mach-O load command has an invalid size\")",
  )
  // a symbol table beyond the end of the file
  let m = parse_ok(data)
  debug_inspect(
    @macho.symbols(data[:0x1020].to_owned(), m),
    content="Err(\"Mach-O symbol table is out of bounds\")",
  )
}
