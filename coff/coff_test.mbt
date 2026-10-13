///|
fn[T] ok(r : Result[T, String]) -> T raise {
  match r {
    Ok(x) => x
    Err(e) => fail(e)
  }
}

///|
fn hex(x : UInt32) -> String {
  "0x" + x.to_string(radix=16)
}

///|
test "PE32+ image: headers and sections" {
  let data = @objects.x86_64_pe()
  assert_true(@coff.is_pe(data))
  assert_true(@coff.is_coff(data))
  assert_true(!@coff.is_coff_object(data))
  let c = ok(@coff.parse(data))
  assert_eq(c.pe_offset, Some(0x40))
  debug_inspect(
    c.header,
    content=(
      #|{
      #|  machine: 34404,
      #|  number_of_sections: 2,
      #|  time_date_stamp: 0,
      #|  pointer_to_symbol_table: 2048,
      #|  number_of_symbols: 5,
      #|  size_of_optional_header: 240,
      #|  characteristics: 34,
      #|}
    ),
  )
  guard c.optional_header is Some(h) else { fail("no optional header") }
  assert_eq(h.magic, @coff.IMAGE_NT_OPTIONAL_HDR64_MAGIC)
  assert_eq(h.address_of_entry_point, 0x1000)
  assert_eq(h.image_base, 0x140000000)
  assert_eq(h.size_of_image, 0x3000)
  assert_eq(h.size_of_stack_reserve, 0x100000)
  assert_eq(h.data_directories.length(), 16)
  assert_true(c.is_pe32_plus())
  assert_true(c.is_executable())
  assert_true(!c.is_relocatable())
  assert_eq(c.bytes_in_address(), 8)
  assert_eq(c.image_base(), 0x140000000)
  inspect(
    c.sections
    .map(s => {
      "\{s.name} va=\{hex(s.virtual_address)}+\{hex(s.virtual_size)} raw=\{hex(s.pointer_to_raw_data)}+\{hex(s.size_of_raw_data)} \{hex(s.characteristics)}"
    })
    .join("\n"),
    content=(
      #|.text va=0x1000+0x17 raw=0x400+0x200 0x60000020
      #|.rdata va=0x2000+0x200 raw=0x600+0x200 0x40000040
    ),
  )
  assert_eq(c.rva_to_offset(0x1004), Some(0x404))
  assert_eq(c.rva_to_offset(0x2180), Some(0x780))
  assert_eq(c.rva_to_offset(0x3000), None)
  assert_eq(c.rva_to_offset(0x10), Some(0x10))
  assert_eq(c.section_of_rva(0x1016).map(s => s.name), Some(".text"))
  assert_eq(c.section_of_rva(0x1017).map(s => s.name), None)
  debug_inspect(
    c.data_directory(@coff.IMAGE_DIRECTORY_ENTRY_IAT),
    content="Some({ virtual_address: 8576, size: 16 })",
  )
  debug_inspect(
    c.data_directory(@coff.IMAGE_DIRECTORY_ENTRY_BASERELOC),
    content="None",
  )
}

///|
test "PE32+ image: symbols, imports and exports" {
  let data = @objects.x86_64_pe()
  let c = ok(@coff.parse(data))
  inspect(
    ok(@coff.symbols(data, c))
    .map(s => {
      "\{s.index} \{s.name} value=\{hex(s.value)} sect=\{s.section_number} type=\{s.typ} class=\{s.storage_class} aux=\{s.number_of_aux_symbols} fn=\{s.is_function_definition()}"
    })
    .join("\n"),
    content=(
      #|0 .file value=0x0 sect=-2 type=0 class=103 aux=1 fn=false
      #|2 main value=0x0 sect=1 type=32 class=2 aux=0 fn=true
      #|3 long_function_foo value=0xe sect=1 type=32 class=2 aux=0 fn=true
      #|4 tablesym value=0x100 sect=2 type=0 class=2 aux=0 fn=false
    ),
  )
  debug_inspect(
    ok(@coff.imports(data, c)),
    content=(
      #|[
      #|  {
      #|    dll: "KERNEL32.dll",
      #|    lookup_table_rva: 8512,
      #|    address_table_rva: 8576,
      #|    entries: [{ name: Some("ExitProcess"), ordinal: None, hint: 288, iat_rva: 8576 }],
      #|  },
      #|]
    ),
  )
  debug_inspect(
    ok(@coff.exports(data, c)),
    content=(
      #|Some(
      #|  {
      #|    dll: "fixture.exe",
      #|    ordinal_base: 1,
      #|    exports: [
      #|      { name: Some("main"), ordinal: 1, rva: 4096, forwarder: None },
      #|      { name: Some("foo"), ordinal: 2, rva: 4110, forwarder: None },
      #|    ],
      #|  },
      #|)
    ),
  )
  for section in c.sections {
    debug_inspect(ok(@coff.relocations(data, c, section)), content="[]")
  }
}

///|
test "COFF object: sections, symbols and relocations" {
  let data = @objects.i386_coff_object()
  assert_true(!@coff.is_pe(data))
  assert_true(@coff.is_coff_object(data))
  let c = ok(@coff.parse(data))
  assert_eq(c.pe_offset, None)
  assert_eq(c.optional_header, None)
  assert_true(c.is_relocatable())
  assert_true(!c.is_executable())
  assert_eq(c.image_base(), 0)
  assert_eq(c.bytes_in_address(), 4)
  inspect(c.sections.map(s => s.name).join(","), content=".text,.data")
  inspect(
    ok(@coff.symbols(data, c)).map(s => s.name).join(","),
    content=".file,_main,_puts",
  )
  debug_inspect(
    ok(@coff.relocations(data, c, c.sections[0])),
    content="[{ virtual_address: 1, symbol_table_index: 3, typ: 20 }]",
  )
  assert_eq(ok(@coff.section_name(data, c, c.sections[0])), ".text")
  debug_inspect(ok(@coff.imports(data, c)), content="[]")
  debug_inspect(ok(@coff.exports(data, c)), content="None")
}

///|
test "COFF object: long section names and relocation overflow" {
  let bytes = @objects.i386_coff_object().to_array()
  // name the .data section "/4" and give the string table an entry
  let name = b"/4\x00\x00\x00\x00\x00\x00"
  for i, b in name {
    bytes[60 + i] = b
  }
  let table = b"\x10\x00\x00\x00.data$long\x00\x00"
  for _ in 0..<4 {
    ignore(bytes.pop())
  }
  for b in table {
    bytes.push(b)
  }
  let data = Bytes::from_array(bytes)
  let c = ok(@coff.parse(data))
  assert_eq(c.sections[1].name, "/4")
  assert_eq(ok(@coff.section_name(data, c, c.sections[1])), ".data$long")
  // an extended relocation count: the first entry holds the count
  let bytes = @objects.i386_coff_object().to_array()
  bytes[20 + 32] = b'\xff'
  bytes[20 + 33] = b'\xff'
  bytes[20 + 39] = b'\x61' // IMAGE_SCN_LNK_NRELOC_OVFL | MEM_EXECUTE | ...
  let data = Bytes::from_array(bytes)
  let c = ok(@coff.parse(data))
  debug_inspect(
    @coff.relocations(data, c, c.sections[0]),
    content=(
      #|Ok([])
    ),
  )
}

///|
test "malformed files" {
  debug_inspect(@coff.parse(b"\x7fELF"), content="Err(\"not a PE/COFF file\")")
  let data = @objects.x86_64_pe()
  debug_inspect(
    @coff.parse(data[:0x100].to_owned()),
    content="Err(\"PE optional header is out of bounds\")",
  )
  let c = ok(@coff.parse(data))
  debug_inspect(
    @coff.symbols(data[:0x820].to_owned(), c),
    content="Err(\"COFF symbol table is out of bounds\")",
  )
  debug_inspect(
    @coff.imports(data[:0x700].to_owned(), c),
    content="Err(\"PE/COFF field is out of bounds\")",
  )
}
