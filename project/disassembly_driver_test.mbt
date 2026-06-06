///|
test "project disassembly drivers register lookup and run" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x500UL,
    b"\x90\x90",
  )
  let driver = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-direct",
    description="unit disassembler",
    priority=10,
    run=project => {
      Ok(
        project
        .with_disassembly(project.disassembly().add_block(block))
        .set("disasm", "direct"),
      )
    },
  )
  match @project.register_disassembly_driver(driver) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_disassembly_driver("unit-disasm-direct") is Some(_))
  assert_true(
    @project.disassembly_driver_names().contains("unit-disasm-direct"),
  )
  assert_true(driver.description() == "unit disassembler")
  assert_true(driver.priority() == 10)
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.disassemble(driver="unit-disasm-direct") {
    Ok(next) => {
      assert_true(next.get("disasm") == Some("direct"))
      assert_true(next.disassembly().block_count() == 1)
      assert_true(next.disassembly().blocks()[0].min_addr() == 0x500UL)
    }
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_disassembly_driver(driver) is Err(_))
}

///|
test "project registers built-in memory block disassembly driver" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.disassembly_driver_names().contains("memory-blocks"))
  assert_true(@project.disassembly_driver_names().contains("image-roots"))
  assert_true(@project.disassembly_driver_names().contains("function-symbols"))
  assert_true(@project.disassembly_driver_names().contains("entry-point"))
  assert_true(@project.disassembly_driver_names().contains("project-roots"))
  assert_true(@project.disassembly_driver_names().contains("raw-bytes"))
  assert_true(@project.disassembly_driver_names().contains("linear-sweep"))
  assert_true(@project.disassembly_driver_names().contains("basic"))
  match @project.find_disassembly_driver("image-roots") {
    Some(driver) => {
      assert_true(driver.priority() == -25)
      assert_true(driver.description().contains("image root"))
    }
    None => fail("missing image-root driver")
  }
  match @project.find_disassembly_driver("function-symbols") {
    Some(driver) => {
      assert_true(driver.priority() == -50)
      assert_true(driver.description().contains("function symbol"))
    }
    None => fail("missing function-symbol driver")
  }
  match @project.find_disassembly_driver("entry-point") {
    Some(driver) => {
      assert_true(driver.priority() == -75)
      assert_true(driver.description().contains("entry point"))
    }
    None => fail("missing entry-point driver")
  }
  match @project.find_disassembly_driver("project-roots") {
    Some(driver) => {
      assert_true(driver.priority() == -90)
      assert_true(driver.description().contains("project root"))
    }
    None => fail("missing project-root driver")
  }
  match @project.find_disassembly_driver("raw-bytes") {
    Some(driver) => {
      assert_true(driver.priority() == -95)
      assert_true(driver.description().contains("byte-granular"))
    }
    None => fail("missing raw-byte driver")
  }
  match @project.find_disassembly_driver("linear-sweep") {
    Some(driver) => {
      assert_true(driver.priority() == -96)
      assert_true(driver.description().contains("linear sweep"))
    }
    None => fail("missing linear-sweep driver")
  }
  match @project.find_disassembly_driver("basic") {
    Some(driver) => {
      assert_true(driver.priority() == -97)
      assert_true(driver.description().contains("Basic disassembler"))
    }
    None => fail("missing basic driver")
  }
  match @project.find_disassembly_driver("memory-blocks") {
    Some(driver) => {
      assert_true(driver.priority() == -100)
      assert_true(driver.description().contains("memory regions"))
    }
    None => fail("missing built-in driver")
  }
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x100UL,
    b"\x01\x02",
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x200UL,
    b"\x03",
  )
  let memory = @memory.MemMap::singleton(first, "code").add(second, "data")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  match project.disassemble(driver="memory-blocks") {
    Ok(next) => {
      assert_true(next.get("disassembler") == Some("memory-blocks"))
      let starts = next.disassembly().blocks().map(block => block.min_addr())
      assert_true(starts.contains(0x100UL))
      assert_true(starts.contains(0x200UL))
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown()).disassemble(
      driver="memory-blocks",
    )
    is Err(_),
  )
}

///|
test "project basic disassembly driver materializes Basic instructions" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7300UL,
    b"\x41\x42\x43",
  )
  let memory = @memory.MemMap::singleton(block, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  match project.disassemble(driver="basic") {
    Ok(disassembled) => {
      assert_true(disassembled.get("disassembler") == Some("basic"))
      assert_true(disassembled.disassembly().block_count() == 1)
      assert_true(disassembled.disassembly().instruction_count() == 3)
      let instructions = disassembled.disassembly().instructions_in(block)
      assert_true(instructions.length() == 3)
      assert_true(instructions[0].addr() == 0x7300UL)
      assert_true(instructions[0].code() == 0x41)
      assert_true(instructions[0].assembly() == ".byte 0x41")
      assert_true(instructions[0].encoding() == "raw")
      assert_true(instructions[1].addr() == 0x7301UL)
      assert_true(instructions[1].code() == 0x42)
      assert_true(instructions[2].addr() == 0x7302UL)
      assert_true(instructions[2].code() == 0x43)
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown()).disassemble(
      driver="basic",
    )
    is Err(_),
  )
  match
    @project.ProjectDisassemblyDriver::basic(backend="missing").run(project) {
    Err(reason) =>
      assert_true(reason == "unknown project disassembly basic backend missing")
    Ok(_) => fail("unknown Basic backend driver succeeded")
  }
}

///|
test "project linear-sweep disassembly driver materializes sweep instructions" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7200UL,
    b"\x55\xc3",
  )
  let memory = @memory.MemMap::singleton(block, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  match project.disassemble(driver="linear-sweep") {
    Ok(disassembled) => {
      assert_true(disassembled.get("disassembler") == Some("linear-sweep"))
      assert_true(disassembled.disassembly().block_count() == 1)
      assert_true(disassembled.disassembly().instruction_count() == 2)
      let instructions = disassembled.disassembly().instructions_in(block)
      assert_true(instructions.length() == 2)
      assert_true(instructions[0].addr() == 0x7200UL)
      assert_true(instructions[0].code() == 0x55)
      assert_true(instructions[0].name() == ".byte")
      assert_true(instructions[0].encoding() == "raw")
      assert_true(instructions[1].addr() == 0x7201UL)
      assert_true(instructions[1].code() == 0xc3)
      assert_true(instructions[1].assembly() == ".byte 0xc3")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown()).disassemble(
      driver="linear-sweep",
    )
    is Err(_),
  )
}

///|
test "project raw-byte disassembly driver materializes instruction records" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7100UL,
    b"\x90\xc3",
  )
  let memory = @memory.MemMap::singleton(block, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  match project.disassemble(driver="raw-bytes") {
    Ok(disassembled) => {
      assert_true(disassembled.get("disassembler") == Some("raw-bytes"))
      assert_true(disassembled.disassembly().block_count() == 1)
      assert_true(disassembled.disassembly().instruction_count() == 2)
      let instructions = disassembled.disassembly().instructions_in(block)
      assert_true(instructions.length() == 2)
      assert_true(instructions[0].addr() == 0x7100UL)
      assert_true(instructions[0].assembly() == ".byte 0x90")
      assert_true(instructions[0].bil() == "unknown 0x7100")
      assert_true(instructions[0].code() == 0x90)
      assert_true(instructions[0].name() == ".byte")
      assert_true(instructions[0].encoding() == "raw")
      assert_true(instructions[0].operand_count() == 1)
      assert_true(instructions[0].operands()[0].to_int() == Some(0x90))
      assert_true(instructions[1].addr() == 0x7101UL)
      assert_true(instructions[1].assembly() == ".byte 0xc3")
      assert_true(instructions[1].bil() == "unknown 0x7101")
      assert_true(instructions[1].code() == 0xc3)
      assert_true(instructions[1].operands()[0].to_int() == Some(0xc3))
      match block.view(from=0x7101UL, words=1) {
        Ok(second_byte) => {
          let tagged = disassembled.substitute(
            second_byte, "insn", "$insn@$insn_code[$insn_encoding]: $asm / $bil",
          )
          assert_true(
            tagged
            .memory()
            .lookup(0x7101UL)
            .any(entry => {
              entry.1 == "insn=.byte@0xc3[raw]: .byte 0xc3 / unknown 0x7101"
            }),
          )
        }
        Err(reason) => fail(reason)
      }
      let edge = @project.ProjectDisassemblyEdge::create(
        source=0x7101UL,
        target=0x7100UL,
        kind=JumpEdge,
      )
      let brancher = @project.ProjectBrancher::create(memory => {
        if memory.min_addr() == 0x7101UL && memory.length() == 1 {
          [edge]
        } else {
          []
        }
      })
      match disassembled.apply_brancher(brancher~) {
        Ok(branched) => {
          assert_true(branched.disassembly().edge_count() == 1)
          assert_true(branched.disassembly().has_edge(edge))
        }
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown()).disassemble(
      driver="raw-bytes",
    )
    is Err(_),
  )
}

///|
test "project root disassembly driver materializes roots from memory" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let code = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x8000UL,
    b"\xaa\xbb\xcc\xdd",
  )
  let data = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x9000UL,
    b"\xee",
  )
  let memory = @memory.MemMap::singleton(code, "code").add(data, "data")
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_memory(memory)
    .with_symbols([
      @image.Symbol::create(name="root", addr=0x8002UL, size=1),
      @image.Symbol::create(name="unmapped", addr=0x9900UL, size=1),
    ])
  match project.disassemble(driver="project-roots") {
    Ok(next) => {
      assert_true(next.get("disassembler") == Some("project-roots"))
      let blocks = next.disassembly().blocks()
      assert_true(blocks.length() == 1)
      assert_true(blocks[0].min_addr() == 0x8002UL)
      inspect(blocks[0].hexdump(), content="cc dd")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown())
    .with_memory(memory)
    .disassemble(driver="project-roots")
    is Err(_),
  )
  assert_true(
    @project.Project::empty(@core_theory.Target::unknown())
    .with_memory(memory)
    .with_symbols([@image.Symbol::create(name="missing", addr=0x9900UL)])
    .disassemble(driver="project-roots")
    is Err(_),
  )
  let image = @image.Image::from_segments(entry=0x8000UL, endian=LittleEndian, [
    @image.Segment::create(
      name=".text",
      endian=LittleEndian,
      addr=0x8000UL,
      b"\x01",
      executable=true,
    ),
  ])
  assert_true(
    @project.Project::from_image(image).disassemble(driver="project-roots")
    is Err(_),
  )
}

///|
test "project function-symbol disassembly driver materializes symbol blocks" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\xaa\xbb\xcc\xdd",
    executable=true,
  )
  let data_segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1100UL,
    b"\xee\xff",
  )
  let function_symbol = @image.Symbol::create(
    name="main",
    addr=0x1001UL,
    size=2,
    is_function=true,
  )
  let data_function_symbol = @image.Symbol::create(
    name="data_func",
    addr=0x1100UL,
    size=2,
    is_function=true,
  )
  let data_symbol = @image.Symbol::create(name="global", addr=0x1003UL, size=1)
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment, data_segment],
    symbols=[function_symbol, data_function_symbol, data_symbol],
  )
  let project = @project.Project::from_image(image)
  match project.disassemble(driver="function-symbols") {
    Ok(next) => {
      assert_true(next.get("disassembler") == Some("function-symbols"))
      let blocks = next.disassembly().blocks()
      assert_true(blocks.length() == 1)
      assert_true(blocks[0].min_addr() == 0x1001UL)
      inspect(blocks[0].hexdump(), content="bb cc")
    }
    Err(reason) => fail(reason)
  }
  let no_symbols = @project.Project::empty(@core_theory.Target::unknown())
  assert_true(no_symbols.disassemble(driver="function-symbols") is Err(_))
}

///|
test "project image-root disassembly driver materializes entry and symbol blocks" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1800UL,
    b"\x10\x20\x30\x40\x50",
    executable=true,
  )
  let data_segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1900UL,
    b"\x60\x70",
  )
  let function_symbol = @image.Symbol::create(
    name="main",
    addr=0x1802UL,
    size=2,
    is_function=true,
  )
  let data_symbol = @image.Symbol::create(name="table", addr=0x1804UL, size=1)
  let non_exec_symbol = @image.Symbol::create(
    name="global",
    addr=0x1900UL,
    size=2,
  )
  let image = @image.Image::from_segments(
    entry=0x1801UL,
    endian=LittleEndian,
    [segment, data_segment],
    symbols=[function_symbol, data_symbol, non_exec_symbol],
  )
  let project = @project.Project::from_image(image)
  match project.disassemble(driver="image-roots") {
    Ok(next) => {
      assert_true(next.get("disassembler") == Some("image-roots"))
      let blocks = next.disassembly().blocks()
      assert_true(blocks.length() == 3)
      assert_true(blocks[0].min_addr() == 0x1801UL)
      inspect(blocks[0].hexdump(), content="20 30 40 50")
      assert_true(blocks[1].min_addr() == 0x1802UL)
      inspect(blocks[1].hexdump(), content="30 40 50")
      assert_true(blocks[2].min_addr() == 0x1804UL)
      inspect(blocks[2].hexdump(), content="50")
    }
    Err(reason) => fail(reason)
  }
  match project.disassemble(driver="image-roots") {
    Ok(once) =>
      match once.disassemble(driver="image-roots") {
        Ok(twice) => assert_true(twice.disassembly().block_count() == 3)
        Err(reason) => fail(reason)
      }
    Err(reason) => fail(reason)
  }
  let unmapped = @project.Project::from_image(
    @image.Image::from_segments(entry=0x2800UL, endian=LittleEndian, [segment]),
  )
  assert_true(unmapped.disassemble(driver="image-roots") is Err(_))
  let stripped = @image.Image::from_segments(
    entry=0x1800UL,
    endian=LittleEndian,
    [segment],
  )
  let replacement = [
    @image.Symbol::create(name="debug_main", addr=0x1803UL, size=1),
  ]
  let enriched = @project.Project::from_image(stripped).with_symbols(
    replacement,
  )
  match enriched.disassemble(driver="image-roots") {
    Ok(next) => {
      let blocks = next.disassembly().blocks()
      assert_true(blocks.length() == 2)
      assert_true(blocks[0].min_addr() == 0x1800UL)
      inspect(blocks[0].hexdump(), content="10 20 30 40 50")
      assert_true(blocks[1].min_addr() == 0x1803UL)
      inspect(blocks[1].hexdump(), content="40 50")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project entry-point disassembly driver materializes mapped entry block" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x2000UL,
    b"\x11\x22\x33\x44",
    executable=true,
  )
  let image = @image.Image::from_segments(entry=0x2002UL, endian=LittleEndian, [
    segment,
  ])
  let project = @project.Project::from_image(image)
  match project.disassemble(driver="entry-point") {
    Ok(next) => {
      assert_true(next.get("disassembler") == Some("entry-point"))
      let blocks = next.disassembly().blocks()
      assert_true(blocks.length() == 1)
      assert_true(blocks[0].min_addr() == 0x2002UL)
      inspect(blocks[0].hexdump(), content="33 44")
    }
    Err(reason) => fail(reason)
  }
  let unmapped = @project.Project::from_image(
    @image.Image::from_segments(entry=0x3000UL, endian=LittleEndian, [segment]),
  )
  assert_true(unmapped.disassemble(driver="entry-point") is Err(_))
  let data_segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x4000UL,
    b"\x55\x66",
  )
  let non_exec_entry = @project.Project::from_image(
    @image.Image::from_segments(entry=0x4000UL, endian=LittleEndian, [
      data_segment,
    ]),
  )
  assert_true(non_exec_entry.disassemble(driver="entry-point") is Err(_))
}

///|
test "project disassembly drivers fall back by priority" {
  let failing = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-priority-high",
    priority=100,
    run=_ => Err("not this driver"),
  )
  let fallback = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-priority-low",
    priority=90,
    run=project => Ok(project.set("disasm-fallback", "yes")),
  )
  match @project.register_disassembly_driver(failing) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_disassembly_driver(fallback) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.disassembly_driver_names().contains("unit-disasm-priority-high"),
  )
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.disassemble_with_available() {
    Ok(next) => assert_true(next.get("disasm-fallback") == Some("yes"))
    Err(reason) => fail(reason)
  }
  assert_true(project.disassemble(driver="unit-disasm-missing") is Err(_))
}

///|
test "project disassembly driver candidate lists report every failure" {
  let first = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-fail-first",
    run=_ => Err("first reason"),
  )
  let second = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-fail-second",
    run=_ => Err("second reason"),
  )
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.disassemble_with_drivers([first, second]) {
    Ok(_) => fail("expected disassembly drivers to fail")
    Err(reason) => {
      assert_true(reason.contains("unit-disasm-fail-first: first reason"))
      assert_true(reason.contains("unit-disasm-fail-second: second reason"))
    }
  }
  assert_true(project.disassemble_with_drivers([]) is Err(_))
}
