///|
test "project input from bytes builds raw memory image" {
  let target = @core_theory.Target::unknown()
  let input = @project.ProjectInput::from_bytes(
    target~,
    b"\x01\x02\x03",
    endian=LittleEndian,
    base=0x200UL,
    filename="raw.bin",
  )
  let project = @project.Project::from_input(input)
  assert_true(project.filename() == Some("raw.bin"))
  assert_true(project.memory().lookup(0x201UL).length() == 1)
  match project.image() {
    Some(image) => assert_true(image.base_address() == Some(0x200UL))
    None => fail("expected raw image")
  }
}

///|
test "project raw bytes reject empty input and use target metadata" {
  let target = @core_theory.Target::sparc()
  assert_true(@project.ProjectInput::raw_bytes(target~, b"") is Err(_))
  assert_true(
    @project.ProjectInput::raw_bytes(target~, b"\x01", offset=2) is Err(_),
  )
  assert_true(
    @project.ProjectInput::raw_bytes(target~, b"\x01", length=2) is Err(_),
  )
  match
    @project.ProjectInput::raw_bytes(
      target~,
      b"\x00\x01\x02\x03",
      base=0x300UL,
      offset=1,
      length=2,
      entry=0x301UL,
      filename="raw.bin",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("raw.bin"))
      assert_true(project.memory().lookup(0x300UL).length() == 1)
      assert_true(project.memory().lookup(0x302UL).is_empty())
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == BigEndian)
          assert_true(image.entry_point() == 0x301UL)
          assert_true(image.base_address() == Some(0x300UL))
          let segments = image.segments()
          assert_true(segments.length() == 1)
          assert_true(segments[0].name() == "bap.user")
          assert_true(segments[0].offset() == 1)
          assert_true(segments[0].memory().to_bytes() == b"\x01\x02")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input create combines code and data memory" {
  let target = @core_theory.Target::unknown()
  let code_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x400UL,
    b"\x90",
  )
  let data_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x500UL,
    b"\x01\x02",
  )
  let code = @memory.MemMap::singleton(code_memory, "code")
  let data = @memory.MemMap::singleton(data_memory, "data")
  let input = @project.ProjectInput::create(
    target~,
    filename="split.bin",
    code~,
    data~,
  )
  let project = @project.Project::from_input(input)
  assert_true(project.filename() == Some("split.bin"))
  assert_true(project.memory().lookup(0x400UL).any(entry => entry.1 == "code"))
  assert_true(project.memory().lookup(0x501UL).any(entry => entry.1 == "data"))
}

///|
test "project input from bigstring and string use checked raw bytes" {
  let target = @core_theory.Target::x86_64()
  assert_true(@project.ProjectInput::from_bigstring(target~, b"") is Err(_))
  assert_true(@project.ProjectInput::from_string(target~, "") is Err(_))
  match
    @project.ProjectInput::from_bigstring(
      target~,
      b"\xaa\xbb",
      base=0x600UL,
      entry=0x601UL,
      filename="raw.bin",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("raw.bin"))
      assert_true(
        project.image().map(image => image.entry_point()) == Some(0x601UL),
      )
      assert_true(project.memory().lookup(0x601UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::from_string(
      target~,
      "Aé",
      base=0x700UL,
      offset=1,
      length=2,
      filename="text.bin",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("text.bin"))
      assert_true(project.memory().lookup(0x700UL).length() == 1)
      assert_true(project.memory().lookup(0x702UL).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input finish hook can finalize project storage" {
  let target = @core_theory.Target::unknown()
  let input = @project.ProjectInput::custom(target~, finish=project => {
    project.set("finished", "true")
  })
  let project = @project.Project::from_input(input)
  assert_true(project.get("finished") == Some("true"))
}

///|
test "project input custom symbols persist into projects" {
  let target = @core_theory.Target::unknown()
  let symbols = [@image.Symbol::create(name="custom", addr=0x80UL, size=1)]
  let input = @project.ProjectInput::custom(target~, symbols~)
  symbols.push(@image.Symbol::create(name="mutated", addr=0x81UL))
  assert_true(input.symbols().length() == 1)
  let project = @project.Project::from_input(input)
  assert_true(project.symbols().length() == 1)
  assert_true(project.symbols()[0].name() == "custom")
}

///|
test "project create from input applies disassembly source providers" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6200UL,
    b"\xaa\xbb\xcc",
  )
  let input = @project.ProjectInput::custom(
    target=@core_theory.Target::unknown(),
    memory=@memory.MemMap::singleton(block, "code"),
  )
  let driver_source : @project.ProjectDisassemblySource[
    @project.ProjectDisassemblyDriver,
  ] = @project.ProjectDisassemblySource::single(
    @project.ProjectDisassemblyDriver::project_roots(),
  )
  let rooter_source : @project.ProjectDisassemblySource[@project.ProjectRooter] = @project.ProjectDisassemblySource::single(
    @project.ProjectRooter::create([0x6201UL]),
  )
  let symbolizer = @project.ProjectSymbolizer::create(addr => {
    if addr == 0x6201UL {
      Some("selected_root")
    } else {
      None
    }
  })
  let symbolizer_source : @project.ProjectDisassemblySource[
    @project.ProjectSymbolizer,
  ] = @project.ProjectDisassemblySource::single(symbolizer)
  match
    @project.Project::create_from_input(
      input,
      driver_source~,
      rooter=rooter_source,
      symbolizer=symbolizer_source,
    ) {
    Ok(project) => {
      assert_true(project.get("disassembler") == Some("project-roots"))
      assert_true(project.disassembly().block_count() == 1)
      assert_true(project.disassembly().blocks()[0].min_addr() == 0x6201UL)
      let subs = project.program().subs()
      assert_true(subs.length() == 1)
      assert_true(subs[0].sub_name() == "selected_root")
    }
    Err(reason) => fail(reason)
  }
  let failing_driver_source : @project.ProjectDisassemblySource[
    @project.ProjectDisassemblyDriver,
  ] = @project.ProjectDisassemblySource::error("driver unavailable")
  match
    @project.Project::create_from_input(
      input,
      driver_source=failing_driver_source,
    ) {
    Err(reason) =>
      assert_true(
        reason == "project disassembly driver source failed: driver unavailable",
      )
    Ok(_) => fail("unexpected project creation success")
  }
}

///|
test "project create from input named resolves source registries" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6400UL,
    b"\x01\x02",
  )
  let input = @project.ProjectInput::custom(
    target=@core_theory.Target::unknown(),
    memory=@memory.MemMap::singleton(block, "code"),
  )
  @project.register_disassembly_driver_source_value(
    name="unit-create-driver-source",
    @project.ProjectDisassemblyDriver::memory_blocks(),
  )
  @project.register_brancher_source_value(
    name="unit-create-brancher-source",
    @project.ProjectBrancher::of_edges([
      @project.ProjectDisassemblyEdge::create(
        source=0x6400UL,
        target=0x6401UL,
        kind=FallEdge,
      ),
    ]),
  )
  @project.register_reconstructor_source_value(
    name="unit-create-reconstructor-source",
    @project.ProjectReconstructor::create(project => {
      Ok(
        project.set(
          "edge-count",
          project.disassembly().edge_count().to_string(),
        ),
      )
    }),
  )
  match
    @project.Project::create_from_input_named(
      input,
      driver_source="unit-create-driver-source",
      brancher="unit-create-brancher-source",
      reconstructor="unit-create-reconstructor-source",
    ) {
    Ok(project) => {
      assert_true(project.get("disassembler") == Some("memory-blocks"))
      assert_true(project.get("edge-count") == Some("1"))
      assert_true(project.disassembly().edge_count() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::create_from_input_named(
      input,
      driver_source="missing-create-driver-source",
    )
    is Err(_),
  )
}

///|
test "project create from loader composes loaded input with sources" {
  let loader = @project.ProjectInputLoader::create(name="unit-create-loader", load=data => {
    Ok(
      @project.ProjectInput::from_bytes(
        target=@core_theory.Target::unknown(),
        data,
        endian=LittleEndian,
        base=0x6600UL,
        filename="loaded.bin",
      ),
    )
  })
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let driver_source : @project.ProjectDisassemblySource[
    @project.ProjectDisassemblyDriver,
  ] = @project.ProjectDisassemblySource::single(
    @project.ProjectDisassemblyDriver::memory_blocks(),
  )
  let symbolizer_source : @project.ProjectDisassemblySource[
    @project.ProjectSymbolizer,
  ] = @project.ProjectDisassemblySource::single(
    @project.ProjectSymbolizer::create(addr => {
      if addr == 0x6600UL {
        Some("loaded_block")
      } else {
        None
      }
    }),
  )
  match
    @project.Project::create_from_loader(
      b"\x01\x02",
      loader="unit-create-loader",
      driver_source~,
      symbolizer=symbolizer_source,
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("loaded.bin"))
      assert_true(project.get("disassembler") == Some("memory-blocks"))
      assert_true(project.disassembly().block_count() == 1)
      assert_true(project.program().subs()[0].sub_name() == "loaded_block")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project create for filename named composes loader and sources" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-create-filename-loader",
    extensions=["csource"],
    priority=50,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x6800UL,
          filename="sample.csource",
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  @project.register_disassembly_driver_source_value(
    name="unit-create-filename-driver-source",
    @project.ProjectDisassemblyDriver::memory_blocks(),
  )
  @project.register_symbolizer_source_value(
    name="unit-create-filename-symbolizer-source",
    @project.ProjectSymbolizer::create(addr => {
      if addr == 0x6800UL {
        Some("filename_block")
      } else {
        None
      }
    }).set_path("sample.csource"),
  )
  match
    @project.Project::create_for_filename_named(
      b"\x03",
      filename="sample.csource",
      driver_source="unit-create-filename-driver-source",
      symbolizer="unit-create-filename-symbolizer-source",
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("sample.csource"))
      assert_true(project.get("disassembler") == Some("memory-blocks"))
      assert_true(project.program().subs()[0].sub_name() == "filename_block")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::create_from_loader_named(
      b"\x04",
      loader="missing-create-loader",
    )
    is Err(_),
  )
}

///|
test "project input loaders register and load bytes" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-raw",
    description="raw project input",
    extensions=["raw"],
    priority=10,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x40UL,
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_input_loader("unit-project-raw") is Some(_))
  assert_true(@project.available_input_loaders().contains("unit-project-raw"))
  assert_true(loader.description() == "raw project input")
  assert_true(loader.extensions() == ["raw"])
  assert_true(loader.priority() == 10)
  assert_true(loader.supports_extension("raw"))
  match @project.ProjectInput::load(b"\xff", loader="unit-project-raw") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x40UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.Project::load(b"\xfe", loader="unit-project-raw") {
    Ok(project) => assert_true(project.memory().lookup(0x40UL).length() == 1)
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_input_loader(loader) is Err(_))
}

///|
test "project input exposes BAP-style loader registry aliases" {
  match
    @project.ProjectInput::register_loader(
      name="unit-project-alias",
      description="BAP-style project input alias",
      extensions=["pia"],
      priority=11,
      load=data => {
        Ok(
          @project.ProjectInput::from_bytes(
            target=@core_theory.Target::unknown(),
            data,
            endian=LittleEndian,
            base=0x140UL,
          ),
        )
      },
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.ProjectInput::find_loader("unit-project-alias") {
    Some(loader) => {
      assert_true(loader.description() == "BAP-style project input alias")
      assert_true(loader.extensions() == ["pia"])
      assert_true(loader.priority() == 11)
    }
    None => fail("expected registered project input loader")
  }
  assert_true(
    @project.ProjectInput::available_loaders().contains("unit-project-alias"),
  )
  assert_true(
    @project.input_loader_names_for_extension("pia").contains(
      "unit-project-alias",
    ),
  )
  match @project.ProjectInput::load(b"\x01\x02", loader="unit-project-alias") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x140UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
fn unit_project_image_backend() -> @image.ImageBackend {
  @image.ImageBackend::create(
    name="unit-project-image-backend",
    description="project image fallback",
    extensions=["pimg"],
    priority=10,
    load=data => {
      let segment = @image.Segment::create(
        name=".image",
        endian=LittleEndian,
        addr=0x440UL,
        data,
        readable=true,
        executable=true,
      )
      Ok(
        (
          @image.Image::from_segments(entry=0x440UL, endian=LittleEndian, [
            segment,
          ]),
          [],
        ),
      )
    },
  )
}

///|
fn project_elf_test_set_u16_le(
  buffer : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  buffer[offset] = (value & 0xff).to_byte()
  buffer[offset + 1] = ((value >> 8) & 0xff).to_byte()
}

///|
fn project_elf_test_set_u32_le(
  buffer : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  for i in 0..<4 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xff).to_byte()
  }
}

///|
fn project_elf_test_set_u64_le(
  buffer : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  for i in 0..<8 {
    buffer[offset + i] = ((value >> (i * 8)) & 0xffUL).to_int().to_byte()
  }
}

///|
fn project_elf_test_write_bytes(
  buffer : Array[Byte],
  offset : Int,
  data : Bytes,
) -> Unit {
  for i in 0..<data.length() {
    buffer[offset + i] = data[i]
  }
}

///|
fn project_elf_test_write_section64(
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
  project_elf_test_set_u32_le(buffer, base, name_offset)
  project_elf_test_set_u32_le(buffer, base + 4, typ)
  project_elf_test_set_u64_le(buffer, base + 8, flags)
  project_elf_test_set_u64_le(buffer, base + 16, addr)
  project_elf_test_set_u64_le(buffer, base + 24, offset.to_uint64())
  project_elf_test_set_u64_le(buffer, base + 32, size.to_uint64())
  project_elf_test_set_u32_le(buffer, base + 40, link)
  project_elf_test_set_u64_le(buffer, base + 56, entsize.to_uint64())
}

///|
fn project_elf_test_write_symbol64(
  buffer : Array[Byte],
  offset : Int,
  name_offset : Int,
  info : Int,
  shndx : Int,
  value : UInt64,
  size : UInt64,
) -> Unit {
  project_elf_test_set_u32_le(buffer, offset, name_offset)
  buffer[offset + 4] = info.to_byte()
  project_elf_test_set_u16_le(buffer, offset + 6, shndx)
  project_elf_test_set_u64_le(buffer, offset + 8, value)
  project_elf_test_set_u64_le(buffer, offset + 16, size)
}

///|
fn project_elf_test_make_x86_64() -> Bytes {
  let shstr = b"\x00.shstrtab\x00.text\x00.symtab\x00.strtab\x00.debug_info\x00.debug_abbrev\x00.debug_str\x00.debug_str_offsets\x00"
  let text = b"\x55\xc3"
  let strtab = b"\x00project_main\x00"
  let debug_info = b"\x13\x00\x00\x00" +
    b"\x04\x00" +
    b"\x00\x00\x00\x00" +
    b"\x08" +
    b"\x01" +
    b"\x00" +
    b"\x00\x10\x40\x00\x00\x00\x00\x00" +
    b"\x02" +
    b"\x00"
  let debug_abbrev = b"\x01\x2e\x00" +
    b"\x03\x25" +
    b"\x11\x01" +
    b"\x12\x0b" +
    b"\x00\x00" +
    b"\x00"
  let debug_str = b"dwarf_main\x00"
  let debug_str_offsets = b"\x00\x00\x00\x00"
  let shstr_offset = 120 + 9 * 64
  let text_offset = shstr_offset + shstr.length()
  let symtab_offset = text_offset + text.length()
  let strtab_offset = symtab_offset + 48
  let debug_info_offset = strtab_offset + strtab.length()
  let debug_abbrev_offset = debug_info_offset + debug_info.length()
  let debug_str_offset = debug_abbrev_offset + debug_abbrev.length()
  let debug_str_offsets_offset = debug_str_offset + debug_str.length()
  let total = debug_str_offsets_offset + debug_str_offsets.length()
  let buffer = Array::make(total, b'\x00')
  project_elf_test_write_bytes(buffer, 0, b"\x7fELF")
  buffer[4] = b'\x02'
  buffer[5] = b'\x01'
  buffer[6] = b'\x01'
  project_elf_test_set_u16_le(buffer, 16, 2)
  project_elf_test_set_u16_le(buffer, 18, 0x3e)
  project_elf_test_set_u32_le(buffer, 20, 1)
  project_elf_test_set_u64_le(buffer, 24, 0x401000UL)
  project_elf_test_set_u64_le(buffer, 32, 64UL)
  project_elf_test_set_u64_le(buffer, 40, 120UL)
  project_elf_test_set_u16_le(buffer, 52, 64)
  project_elf_test_set_u16_le(buffer, 54, 56)
  project_elf_test_set_u16_le(buffer, 56, 1)
  project_elf_test_set_u16_le(buffer, 58, 64)
  project_elf_test_set_u16_le(buffer, 60, 9)
  project_elf_test_set_u16_le(buffer, 62, 1)
  project_elf_test_set_u32_le(buffer, 64, 1)
  project_elf_test_set_u32_le(buffer, 68, 5)
  project_elf_test_set_u64_le(buffer, 72, text_offset.to_uint64())
  project_elf_test_set_u64_le(buffer, 80, 0x401000UL)
  project_elf_test_set_u64_le(buffer, 96, text.length().to_uint64())
  project_elf_test_set_u64_le(buffer, 104, text.length().to_uint64())
  project_elf_test_write_section64(
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
  project_elf_test_write_section64(
    buffer,
    2,
    11,
    1,
    6UL,
    0x401000UL,
    text_offset,
    text.length(),
    0,
    0,
  )
  project_elf_test_write_section64(
    buffer, 3, 17, 2, 0UL, 0UL, symtab_offset, 48, 4, 24,
  )
  project_elf_test_write_section64(
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
  project_elf_test_write_section64(
    buffer,
    5,
    33,
    1,
    0UL,
    0UL,
    debug_info_offset,
    debug_info.length(),
    0,
    0,
  )
  project_elf_test_write_section64(
    buffer,
    6,
    45,
    1,
    0UL,
    0UL,
    debug_abbrev_offset,
    debug_abbrev.length(),
    0,
    0,
  )
  project_elf_test_write_section64(
    buffer,
    7,
    59,
    1,
    0UL,
    0UL,
    debug_str_offset,
    debug_str.length(),
    0,
    0,
  )
  project_elf_test_write_section64(
    buffer,
    8,
    70,
    1,
    0UL,
    0UL,
    debug_str_offsets_offset,
    debug_str_offsets.length(),
    0,
    0,
  )
  project_elf_test_write_bytes(buffer, shstr_offset, shstr)
  project_elf_test_write_bytes(buffer, text_offset, text)
  project_elf_test_write_symbol64(
    buffer,
    symtab_offset + 24,
    1,
    0x12,
    2,
    0x401000UL,
    2UL,
  )
  project_elf_test_write_bytes(buffer, strtab_offset, strtab)
  project_elf_test_write_bytes(buffer, debug_info_offset, debug_info)
  project_elf_test_write_bytes(buffer, debug_abbrev_offset, debug_abbrev)
  project_elf_test_write_bytes(buffer, debug_str_offset, debug_str)
  project_elf_test_write_bytes(
    buffer, debug_str_offsets_offset, debug_str_offsets,
  )
  Bytes::from_array(buffer)
}

///|
test "project input loading falls back to image backends" {
  let backend = unit_project_image_backend()
  match @image.register_backend(name=backend.name(), backend) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.available_input_loaders().contains(backend.name()))
  assert_true(
    @project.input_loader_names_for_extension("pimg").contains(backend.name()),
  )
  match @project.ProjectInput::load(b"\x7f", loader=backend.name()) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::load(
      b"\x7f",
      loader=backend.name(),
      target=@core_theory.Target::sparc(),
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.Project::load(
      b"\x7f",
      loader=backend.name(),
      target=@core_theory.Target::sparc(),
    ) {
    Ok(project) => {
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::load_for_filename(b"\x7f", filename="sample.pimg") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("sample.pimg"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::load_for_filename(
      b"\x7f",
      filename="sample.pimg",
      target=@core_theory.Target::sparc(),
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("sample.pimg"))
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.Project::load_for_filename(
      b"\x7f",
      filename="sample.pimg",
      target=@core_theory.Target::sparc(),
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("sample.pimg"))
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project built-in image loaders include ELF input" {
  match @project.register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.available_input_loaders().contains("elf"))
  assert_true(@project.input_loader_names_for_extension("elf").contains("elf"))
  match
    @project.ProjectInput::load_for_filename(
      project_elf_test_make_x86_64(),
      filename="unit.elf",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("unit.elf"))
      assert_true(project.target().matches("x86_64"))
      assert_true(project.memory().lookup(0x401000UL).length() == 1)
      let symbols = project.symbols()
      assert_true(symbols.length() == 2)
      assert_true(symbols[0].name() == "project_main")
      assert_true(symbols[0].addr() == 0x401000UL)
      assert_true(symbols[0].is_function())
      assert_true(symbols[1].name() == "dwarf_main")
      assert_true(symbols[1].addr() == 0x401000UL)
      assert_true(symbols[1].size() == 2)
      assert_true(symbols[1].is_function())
      assert_true(symbols[1].is_debug())
      match project.image() {
        Some(image) => {
          assert_true(image.segments()[0].name() == ".load0")
          assert_true(
            image.sections().any(section => section.name() == ".text"),
          )
          assert_true(
            image.sections().any(section => section.name() == ".debug_info"),
          )
          assert_true(image.symbols()[0].name() == "project_main")
        }
        None => fail("expected ELF image")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project registers built-in image loaders for raw and Ogre input" {
  match @project.register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.available_input_loaders().contains("raw"))
  assert_true(@project.available_input_loaders().contains("ogre"))
  assert_true(@project.find_input_loader("raw") is Some(_))
  assert_true(@project.input_loader_names_for_extension("bin").contains("raw"))
  assert_true(
    @project.input_loader_names_for_extension("ogre").contains("ogre"),
  )
  match @project.ProjectInput::load(b"\xaa\xbb", loader="raw") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.target().matches("x86_64"))
      assert_true(project.memory().lookup(0UL).length() == 1)
      match project.image() {
        Some(image) => {
          assert_true(image.entry_point() == 0UL)
          assert_true(image.base_address() == Some(0UL))
          assert_true(image.segments()[0].name() == "bap.user")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
  }
  let spec = "(declare arch (name str))" +
    " (declare bits (size int))" +
    " (declare entry-point (addr int))" +
    " (declare is-little-endian (flag bool))" +
    " (arch riscv64)" +
    " (bits 64)" +
    " (entry-point 0)" +
    " (is-little-endian true)"
  match
    @project.ProjectInput::load_for_filename(
      @utf8.encode(spec),
      filename="sample.ogre",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("sample.ogre"))
      assert_true(project.target().matches("riscv64"))
      match project.image() {
        Some(image) => {
          assert_true(image.entry_point() == 0UL)
          assert_true(image.addr_size() == 64)
        }
        None => fail("expected Ogre image")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input loaders resolve by filename extension priority" {
  let low = @project.ProjectInputLoader::create(
    name="unit-project-low-priority",
    extensions=["unit"],
    priority=1,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x10UL,
        ),
      )
    },
  )
  let high = @project.ProjectInputLoader::create(
    name="unit-project-high-priority",
    extensions=["unit"],
    priority=100,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x90UL,
        ),
      )
    },
  )
  match @project.register_input_loader(low) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_input_loader(high) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.input_loader_names_for_extension("unit") ==
    ["unit-project-high-priority", "unit-project-low-priority"],
  )
  match
    @project.ProjectInput::load_for_filename(b"\x01", filename="sample.UNIT") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x90UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.Project::load_for_filename(b"\x02", filename="sample.UNIT") {
    Ok(project) => assert_true(project.memory().lookup(0x90UL).length() == 1)
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.ProjectInput::load_for_filename(b"", filename="no_extension")
    is Err(_),
  )
}

///|
test "project input filename loading falls back to image backend after loader failures" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-failing-mixed-loader",
    extensions=["mixunit"],
    priority=100,
    load=_ => Err("project loader failed"),
  )
  let backend = @image.ImageBackend::create(
    name="unit-project-mixed-image-backend",
    extensions=["mixunit"],
    priority=1,
    load=data => {
      let segment = @image.Segment::create(
        name=".fallback",
        endian=LittleEndian,
        addr=0x880UL,
        data,
        readable=true,
        executable=true,
      )
      Ok(
        (
          @image.Image::from_segments(entry=0x880UL, endian=LittleEndian, [
            segment,
          ]),
          [],
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.register_backend(name=backend.name(), backend) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.input_loader_names_for_extension("mixunit") ==
    ["unit-project-failing-mixed-loader", "unit-project-mixed-image-backend"],
  )
  match
    @project.ProjectInput::load_for_filename(b"\x7f", filename="sample.mixunit") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("sample.mixunit"))
      assert_true(project.memory().lookup(0x880UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input file loading reports read errors" {
  assert_true(
    @project.ProjectInput::load_file(
      "__bap_mbt_missing_project__",
      loader="unit-project-raw",
    )
    is Err(_),
  )
}
