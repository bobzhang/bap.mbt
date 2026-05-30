///|
fn raw_segment() -> @image.Segment {
  @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x90\xc3",
    executable=true,
  )
}

///|
test "project can be created from image memory" {
  let target = @core_theory.Target::unknown()
  let symbol = @image.Symbol::create(
    name="entry",
    addr=0x1000UL,
    size=2,
    is_function=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    symbols=[symbol],
    filename="tiny.bin",
    target~,
  )
  let project = @project.Project::from_image(image)
  assert_true(project.target().is_unknown())
  assert_true(project.arch().is_unknown())
  assert_true(project.filename() == Some("tiny.bin"))
  assert_true(project.has("filename"))
  assert_true(project.get("filename") == Some("tiny.bin"))
  assert_true(project.image() is Some(_))
  assert_true(project.memory().lookup(0x1000UL).length() == 1)
  assert_true(project.symbols().length() == 1)
  assert_true(project.symbols()[0].name() == "entry")
  assert_true(project.specification().fact_count("arch") == 1)
}

///|
test "project preserves image loader specifications" {
  let target = @core_theory.Target::unknown()
  let spec = @image.OgreDoc::from_target(@core_theory.Target::x86_64())
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    target~,
    spec~,
  )
  let project = @project.Project::from_image(image)
  assert_true(project.specification().fact_count("bits") == 1)
  assert_true(
    project.specification().facts("bits")[0].value("size") == Some("64"),
  )
}

///|
test "project exposes image relocation metadata" {
  let target = @core_theory.Target::unknown()
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    relocations=[
      @image.Relocation::create(fixup=0x1001UL, target=0x2000UL),
      @image.Relocation::create(fixup=0x1002UL, relative=true),
    ],
    external_references=[
      @image.ExternalReference::create(addr=0x1003UL, name="puts"),
    ],
    required_libraries=["libc.so.6"],
    rpaths=["/opt/lib"],
    runpaths=["$ORIGIN/lib"],
    symbol_values=[@image.SymbolValue::create(addr=0x1000UL, value=0x80UL)],
    interpreter="/lib64/ld-linux-x86-64.so.2",
    soname="libdemo.so",
    load_bias=-16L,
    is_executable=true,
    base_address=0x1000UL,
    target~,
  )
  let project = @project.Project::from_image(image)
  assert_true(project.base_address() == Some(0x1000UL))
  assert_true(project.relocations().length() == 2)
  assert_true(project.relocations()[0].target() == Some(0x2000UL))
  assert_true(project.relocations()[1].is_relative())
  assert_true(project.external_references().length() == 1)
  assert_true(project.external_references()[0].name() == "puts")
  assert_true(project.required_libraries() == ["libc.so.6"])
  assert_true(project.rpaths() == ["/opt/lib"])
  assert_true(project.runpaths() == ["$ORIGIN/lib"])
  assert_true(project.symbol_values().length() == 1)
  assert_true(project.symbol_values()[0].value() == 0x80UL)
  assert_true(project.interpreter() == Some("/lib64/ld-linux-x86-64.so.2"))
  assert_true(project.soname() == Some("libdemo.so"))
  assert_true(project.load_bias() == Some(-16L))
  assert_true(project.is_executable() == Some(true))
  let empty = @project.Project::empty(target)
  assert_true(empty.base_address() == None)
  assert_true(empty.relocations().is_empty())
  assert_true(empty.external_references().is_empty())
  assert_true(empty.required_libraries().is_empty())
  assert_true(empty.rpaths().is_empty())
  assert_true(empty.runpaths().is_empty())
  assert_true(empty.symbol_values().is_empty())
  assert_true(empty.interpreter() == None)
  assert_true(empty.soname() == None)
  assert_true(empty.load_bias() == None)
  assert_true(empty.is_executable() == None)
}

///|
test "project applies image relocations and refreshes memory" {
  let target = @core_theory.Target::x86_64()
  let segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00",
    writable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    relocations=[
      @image.Relocation::create(fixup=0x1000UL, target=0x4000UL),
      @image.Relocation::create(fixup=0x1008UL, relative=true),
    ],
    base_address=0x2000UL,
    target~,
  )
  let project = @project.Project::from_image(image)
  match project.with_applied_relocations() {
    Ok(applied) => {
      match applied.image() {
        Some(image) =>
          inspect(
            image.segments()[0].memory().hexdump(),
            content="00 40 00 00 00 00 00 00 08 20 00 00 00 00 00 00",
          )
        None => fail("expected image")
      }
      match
        applied.memory().lookup(0x1000UL)[0].0.view(from=0x1000UL, words=16) {
        Ok(memory) =>
          inspect(
            memory.hexdump(),
            content="00 40 00 00 00 00 00 00 08 20 00 00 00 00 00 00",
          )
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project storage and memory tags are persistent updates" {
  let target = @core_theory.Target::unknown()
  let project = @project.Project::empty(target).set("loader", "raw")
  assert_true(project.has("loader"))
  assert_true(project.get("loader") == Some("raw"))
  let replacement = { "filename": "tiny.bin", "loader": "ogre" }
  let replaced = project.with_storage(replacement)
  replacement["loader"] = "mutated"
  assert_true(replaced.get("filename") == Some("tiny.bin"))
  assert_true(replaced.get("loader") == Some("ogre"))
  let cleared = project.del("loader")
  assert_true(!cleared.has("loader"))
  let tagged = cleared.tag_memory(raw_segment().memory(), "code")
  assert_true(tagged.memory().lookup(0x1001UL).length() == 1)
  let replacement_symbols = [
    @image.Symbol::create(name="alt", addr=0x1001UL, size=1),
  ]
  let with_symbols = tagged.with_symbols(replacement_symbols)
  replacement_symbols.push(@image.Symbol::create(name="mutated", addr=0x1002UL))
  assert_true(with_symbols.symbols().length() == 1)
  assert_true(with_symbols.symbols()[0].name() == "alt")
}

///|
test "project substitutes memory annotation placeholders" {
  let target = @core_theory.Target::unknown()
  let section = @image.Section::create(name=".text", addr=0x1000UL, size=2)
  let symbol = @image.Symbol::create(name="entry", addr=0x1000UL, size=2)
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    sections=[section],
    symbols=[symbol],
    target~,
  )
  match raw_segment().memory().view(from=0x1001UL, words=1) {
    Ok(region) => {
      let project = @project.Project::from_image(image)
      let tagged = project.substitute(
        region,
        "comment",
        "$symbol_name@$symbol_addr-$symbol_max_addr in " +
        "$section_name@$section_addr-$section_max_addr " +
        "covers $addr-$max_addr and $missing",
      )
      assert_true(
        tagged
        .memory()
        .lookup(0x1001UL)
        .any(entry => {
          entry.1 ==
          "comment=entry@0x1000-0x1001 in .text@0x1000-0x1001 " +
          "covers 0x1001-0x1001 and missing"
        }),
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project substitutes filename placeholders" {
  let target = @core_theory.Target::unknown()
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    filename="tiny.bin",
    target~,
  )
  let tagged = @project.Project::from_image(image).substitute(
    raw_segment().memory(),
    "source",
    "$filename",
  )
  assert_true(
    tagged.memory().lookup(0x1000UL).any(entry => entry.1 == "source=tiny.bin"),
  )
}

///|
test "project substitutes disassembly block placeholders" {
  let target = @core_theory.Target::unknown()
  let block = raw_segment().memory()
  let project = @project.Project::empty(target).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(block),
  )
  let tagged = project.substitute(
    block, "block-comment", "$block_name spans $block_addr-$block_max_addr",
  )
  assert_true(
    tagged
    .memory()
    .lookup(0x1000UL)
    .any(entry => entry.1 == "block-comment=blk_0x1000 spans 0x1000-0x1001"),
  )
}

///|
test "project substitutes disassembly instruction text placeholders" {
  let target = @core_theory.Target::unknown()
  let block = raw_segment().memory()
  let instruction = @project.ProjectDisassemblyInstruction::create(
    block,
    assembly="nop; ret",
    bil="jmp 0x1001",
  )
  let project = @project.Project::empty(target).with_disassembly(
    @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_instruction(instruction),
  )
  match block.view(from=0x1001UL, words=1) {
    Ok(region) => {
      let tagged = project.substitute(region, "disasm-comment", "$asm / $bil")
      assert_true(
        tagged
        .memory()
        .lookup(0x1001UL)
        .any(entry => entry.1 == "disasm-comment=nop; ret / jmp 0x1001"),
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project maps programs and stores libraries" {
  let target = @core_theory.Target::unknown()
  let sub = @types.Sub::create(name="main")
  let program = @types.Program::create().append_sub(sub)
  let project = @project.Project::empty(target).map_program(_ => program)
  assert_true(project.program().subs().length() == 1)
  let library = @project.Library::create(
    name="libc",
    target~,
    memory=@memory.MemMap::singleton(raw_segment().memory(), "lib-code"),
    symbols=[@image.Symbol::create(name="lib_start", addr=0x1000UL)],
  )
  let with_library = project.add_library(library)
  assert_true(with_library.libraries().length() == 1)
  assert_true(with_library.libraries()[0].name() == "libc")
  assert_true(with_library.libraries()[0].unit().path() == Some("libc"))
  assert_true(with_library.libraries()[0].symbols().length() == 1)
  assert_true(with_library.libraries()[0].arch().is_unknown())
  assert_true(
    with_library.libraries()[0].specification().fact_count("arch") == 1,
  )
  let explicit_unit = @core_theory.ProgramUnit::for_file(
    "libexplicit.so",
    target=@core_theory.Target::x86_64(),
  )
  let explicit_library = @project.Library::create(
    name="libexplicit",
    target~,
    unit=explicit_unit,
  )
  assert_true(explicit_library.unit().same(explicit_unit))
}

///|
test "project and libraries carry disassembly state" {
  let target = @core_theory.Target::unknown()
  let block = raw_segment().memory()
  let same_block = raw_segment().memory()
  let sub = @types.Sub::create(name="entry")
  let instruction = @project.ProjectDisassemblyInstruction::create(
    block,
    assembly="ret",
    bil="jmp LR",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_block(same_block)
    .add_instruction(instruction)
  let created = @project.ProjectDisassemblyState::create(blocks=[
    block, same_block,
  ])
  let replaced = @project.ProjectDisassemblyState::empty().with_blocks([
    block, same_block,
  ])
  assert_true(created.block_count() == 1)
  assert_true(replaced.block_count() == 1)
  assert_true(disassembly.has_block(block))
  assert_true(disassembly.block_count() == 1)
  let state = @project.ProjectState::empty()
    .with_disassembly(disassembly)
    .add_subroutine(sub)
  let project = @project.Project::empty(target).with_state(state)
  assert_true(project.state().subroutines().length() == 1)
  assert_true(project.disassembly().block_count() == 1)
  assert_true(project.disassembly().instruction_count() == 1)
  assert_true(project.disassembly().blocks()[0].min_addr() == 0x1000UL)
  assert_true(project.disassembly().instructions()[0].assembly() == "ret")
  let cleared = project.with_disassembly(
    @project.ProjectDisassemblyState::empty(),
  )
  assert_true(cleared.disassembly().block_count() == 0)
  assert_true(cleared.disassembly().instruction_count() == 0)
  let library = @project.Library::create(name="libstate", target~, state~)
  assert_true(library.state().subroutines().length() == 1)
  assert_true(library.disassembly().block_count() == 1)
  assert_true(library.disassembly().instruction_count() == 1)
}
