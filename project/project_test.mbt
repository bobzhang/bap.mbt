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
  let sub = @types.Sub::create(name="entry")
  let instruction = @project.ProjectDisassemblyInstruction::create(
    block,
    assembly="ret",
    bil="jmp LR",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_instruction(instruction)
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
