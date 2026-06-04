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
fn assert_single_memory_value(
  memory : @memory.MemMap[String],
  value : String,
) -> Unit raise {
  assert_true(memory.entries().length() == 1)
  let matches = memory.lookup(0x1000UL)
  assert_true(matches.length() == 1)
  assert_true(matches[0].1 == value)
}

///|
test "project exposes BAP memory knowledge slot" {
  let slot = @project.memory_slot()
  assert_true(slot.cls().same(@core_theory.ProgramUnit::cls()))
  assert_true(slot.owner().show() == "core:unit")
  assert_true(slot.name().show() == "bap:unit-memory")
  assert_true(slot.desc() == "annotated memory regions of the unit")
  assert_true(slot.persistent() is None)
  let domain = slot.domain()
  let empty : @memory.MemMap[String] = @memory.MemMap::empty()
  assert_true(domain.name().show() == "bap:unit-memory")
  assert_true(domain.empty() is Some(_))
  assert_true(domain.is_empty(empty))
  let memory = raw_segment().memory()
  let code = @memory.MemMap::singleton(memory, "code")
  assert_true(!domain.is_empty(code))
  assert_true(domain.order(empty, code) == Less)
  match domain.join(empty, code) {
    Ok(joined) => assert_single_memory_value(joined, "code")
    Err(_) => abort("expected empty memory map to join with code map")
  }
  match domain.join(code, empty) {
    Ok(joined) => assert_single_memory_value(joined, "code")
    Err(_) => abort("expected code map to join with empty memory map")
  }
  match domain.join(code, code) {
    Ok(joined) => assert_single_memory_value(joined, "code")
    Err(_) => abort("expected identical code maps to join")
  }
  let data = @memory.MemMap::singleton(memory, "data")
  assert_true(domain.join(code, data) is Err(_))
}

///|
fn assert_project_state_shape(
  state : @project.ProjectState,
  blocks : Int,
  subroutines : Int,
) -> Unit raise {
  assert_true(state.disassembly().block_count() == blocks)
  assert_true(state.subroutines().length() == subroutines)
}

///|
test "project state exposes BAP disassembly knowledge slot" {
  let slot = @project.ProjectState::slot()
  assert_true(slot.cls().same(@core_theory.ProgramUnit::cls()))
  assert_true(slot.owner().show() == "core:unit")
  assert_true(slot.name().show() == "bap:disassembly")
  assert_true(slot.desc() == "no description")
  assert_true(slot.persistent() is Some(_))
  let domain = slot.domain()
  let empty = @project.ProjectState::empty()
  assert_true(domain.name().show() == "bap:disassembly")
  assert_true(domain.empty() is Some(_))
  assert_true(domain.is_empty(empty))
  let state = @project.ProjectState::empty().with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(raw_segment().memory()),
  )
  assert_true(!domain.is_empty(state))
  assert_true(domain.inspect(state).contains(":number-of-basic-blocks 1"))
  assert_true(domain.inspect(state).contains(":number-of-subroutines 0"))
  assert_true(domain.order(empty, state) == Less)
  match domain.join(empty, state) {
    Ok(joined) => assert_project_state_shape(joined, 1, 0)
    Err(_) => abort("expected empty project state to join with disassembly")
  }
  match domain.join(state, empty) {
    Ok(joined) => assert_project_state_shape(joined, 1, 0)
    Err(_) => abort("expected project state to join with empty state")
  }
  match domain.join(state, state) {
    Ok(joined) => assert_project_state_shape(joined, 1, 0)
    Err(_) => abort("expected identical project states to join")
  }
  let other = state.add_subroutine(@types.Sub::create(name="slot-other"))
  assert_true(domain.order(state, other) == Incomparable)
  assert_true(domain.join(state, other) is Err(_))
  match slot.persistent() {
    Some(codec) =>
      match codec.decode(codec.encode(other)) {
        Ok(decoded) => {
          assert_project_state_shape(decoded, 1, 1)
          assert_true(decoded.subroutines()[0].sub_name() == "slot-other")
        }
        Err(reason) => fail(reason)
      }
    None => fail("missing project state persistent codec")
  }
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
test "project persistent codec round trips metadata and storage" {
  let storage = { "loader": "raw", "note": "a:b" }
  let flag = @types.Var::new(name="flag", typ=Imm(1))
  let x = @types.Var::new(name="x", typ=Imm(8))
  let y = @types.Var::new(name="y", typ=Imm(8), is_virtual=true)
  let entry_tid = @types.Tid::for_name("entry")
  let exit_tid = @types.Tid::for_name("exit")
  let arg = @types.Arg::create(
    x,
    Var(x),
    intent=In,
    tid=@types.Tid::for_name("arg"),
  )
  let def = @types.Def::create(
    y,
    Let(
      x,
      Int(@types.Word::of_int(width=8, 1)),
      BinOp(Plus, Var(x), Int(@types.Word::of_int(width=8, 2))),
    ),
    tid=@types.Tid::for_name("def"),
  ).set_attr(@types.Attr::new(key="origin", value="unit"))
  let phi = @types.Phi::of_list(
    y,
    [(entry_tid, Var(x)), (exit_tid, Unknown("incoming", Imm(8)))],
    tid=@types.Tid::for_name("phi"),
  )
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(exit_tid),
    cond=Ite(
      cond=Var(flag),
      yes=Int(@types.Word::b1()),
      no=Int(@types.Word::b0()),
    ),
    tid=@types.Tid::for_name("jmp"),
  )
  let entry_block = @types.Blk::create(
    phis=[phi],
    defs=[def],
    jmps=[jmp],
    tid=entry_tid,
  ).set_attr(@types.Attr::address(@types.Word::of_int(width=32, 0x8800)))
  let exit_block = @types.Blk::create(tid=exit_tid)
  let main_sub = @types.Sub::create(
    name="main",
    args=[arg],
    blks=[entry_block, exit_block],
    tid=@types.Tid::for_name("main"),
  ).set_attr(@types.Attr::new(key="semantic", value="entry-point"))
  let program = @types.Program::create(
    subs=[main_sub],
    tid=@types.Tid::for_name("program"),
  ).set_attr(@types.Attr::comment("round-trip"))
  let memory_block = @memory.Memory::from_bytes(
    endian=BigEndian,
    start=0x8800UL,
    b"\xaa\xbb",
  )
  let memory = @memory.MemMap::singleton(memory_block, "code:entry")
  let symbols = [
    @image.Symbol::create(
      name="main:entry",
      addr=0x8800UL,
      size=2,
      is_function=true,
      is_debug=true,
    ),
  ]
  let state_instruction = @project.ProjectDisassemblyInstruction::create(
    memory_block,
    assembly="mov r0, #1",
    bil="y := 1",
    code=0x01,
    name="mov",
    encoding="unit",
    kinds=[ProjectMayLoad, ProjectCall],
    operands=[
      @project.ProjectInstructionOperand::register(name="R0", code=1),
      @project.ProjectInstructionOperand::immediate(1L),
      @project.ProjectInstructionOperand::floating(1.5),
    ],
    subinstructions=[
      @project.ProjectDisassemblyInstruction::create(
        @memory.Memory::from_bytes(endian=BigEndian, start=0x8801UL, b"\xbb"),
        assembly="sub",
      ),
    ],
  )
  let state = @project.ProjectState::empty()
    .with_disassembly(
      @project.ProjectDisassemblyState::empty()
      .add_block(memory_block)
      .add_instruction(state_instruction)
      .add_edge(
        @project.ProjectDisassemblyEdge::create(
          source=0x8800UL,
          target=0x8801UL,
          kind=CondEdge,
        ),
      )
      .add_edge(@project.ProjectDisassemblyEdge::create(source=0x8801UL)),
    )
    .add_subroutine(main_sub)
  let library_program = @types.Program::create(
    subs=[
      @types.Sub::create(name="lib_entry", tid=@types.Tid::for_name("lib-sub")),
    ],
    tid=@types.Tid::for_name("lib-program"),
  )
  let library_state = @project.ProjectState::empty().with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(
      @memory.Memory::from_bytes(endian=LittleEndian, start=0x9900UL, b"\x11"),
    ),
  )
  let library_memory = @memory.MemMap::singleton(
    @memory.Memory::from_bytes(endian=LittleEndian, start=0x9900UL, b"\x11\x22"),
    "lib:code",
  )
  let library_unit = @core_theory.ProgramUnit::for_file(
    "libdemo.so",
    target=@core_theory.Target::x86_64(),
  )
  let libraries = [
    @project.Library::create(
      name="libdemo",
      target=@core_theory.Target::x86_64(),
      unit=library_unit,
      memory=library_memory,
      program=library_program,
      state=library_state,
      symbols=[
        @image.Symbol::create(
          name="lib_entry",
          addr=0x9900UL,
          size=2,
          is_function=true,
        ),
      ],
    ),
  ]
  let project = @project.Project::create(
    target=@core_theory.Target::x86_64(),
    filename="input:one",
    storage~,
    memory~,
    symbols~,
    libraries~,
    program~,
    state~,
  ).set("analysis", "done")
  symbols.push(@image.Symbol::create(name="mutated", addr=0x9000UL))
  libraries.push(
    @project.Library::create(
      name="mutated",
      target=@core_theory.Target::unknown(),
    ),
  )
  storage["loader"] = "mutated"
  let codec = @project.Project::persistent()
  let encoded = codec.encode(project)
  match codec.decode(encoded) {
    Ok(decoded) => {
      assert_true(decoded.target().equal(@core_theory.Target::x86_64()))
      assert_true(decoded.filename() == Some("input:one"))
      assert_true(decoded.get("filename") == Some("input:one"))
      assert_true(decoded.get("loader") == Some("raw"))
      assert_true(decoded.get("note") == Some("a:b"))
      assert_true(decoded.get("analysis") == Some("done"))
      let entries = decoded.memory().lookup(0x8801UL)
      assert_true(entries.length() == 1)
      assert_true(entries[0].1 == "code:entry")
      assert_true(entries[0].0.endian() == BigEndian)
      assert_true(entries[0].0.min_addr() == 0x8800UL)
      assert_true(entries[0].0.to_bytes() == b"\xaa\xbb")
      let decoded_symbols = decoded.symbols()
      assert_true(decoded_symbols.length() == 1)
      assert_true(decoded_symbols[0].name() == "main:entry")
      assert_true(decoded_symbols[0].addr() == 0x8800UL)
      assert_true(decoded_symbols[0].size() == 2)
      assert_true(decoded_symbols[0].is_function())
      assert_true(decoded_symbols[0].is_debug())
      assert_true(decoded.program().tid() == program.tid())
      assert_true(decoded.program().attrs() == program.attrs())
      assert_true(
        @types.Program::to_string(decoded.program()) ==
        @types.Program::to_string(program),
      )
      assert_true(decoded.state().disassembly().block_count() == 1)
      assert_true(decoded.state().disassembly().instruction_count() == 1)
      assert_true(decoded.state().disassembly().edge_count() == 2)
      let decoded_instruction = decoded.state().disassembly().instructions()[0]
      assert_true(decoded_instruction.assembly() == "mov r0, #1")
      assert_true(decoded_instruction.code() == 0x01)
      assert_true(decoded_instruction.name() == "mov")
      assert_true(decoded_instruction.encoding() == "unit")
      assert_true(decoded_instruction.kinds() == [ProjectCall, ProjectMayLoad])
      assert_true(decoded_instruction.operands().length() == 3)
      assert_true(
        decoded_instruction.operands()[0].register_name() == Some("R0"),
      )
      assert_true(decoded_instruction.operands()[1].to_int64() == Some(1L))
      assert_true(decoded_instruction.operands()[2].to_float() == Some(1.5))
      assert_true(decoded_instruction.subinstruction_count() == 1)
      assert_true(decoded.state().subroutines().length() == 1)
      assert_true(decoded.state().subroutines()[0].tid() == main_sub.tid())
      assert_true(
        @types.Sub::to_string(decoded.state().subroutines()[0]) ==
        @types.Sub::to_string(main_sub),
      )
      let decoded_libraries = decoded.libraries()
      assert_true(decoded_libraries.length() == 1)
      assert_true(decoded_libraries[0].name() == "libdemo")
      assert_true(
        decoded_libraries[0].target().equal(@core_theory.Target::x86_64()),
      )
      assert_true(decoded_libraries[0].unit().same(library_unit))
      let library_entries = decoded_libraries[0].memory().lookup(0x9901UL)
      assert_true(library_entries.length() == 1)
      assert_true(library_entries[0].1 == "lib:code")
      assert_true(library_entries[0].0.to_bytes() == b"\x11\x22")
      let library_symbols = decoded_libraries[0].symbols()
      assert_true(library_symbols.length() == 1)
      assert_true(library_symbols[0].name() == "lib_entry")
      assert_true(library_symbols[0].is_function())
      assert_true(
        @types.Program::to_string(decoded_libraries[0].program()) ==
        @types.Program::to_string(library_program),
      )
      assert_true(decoded_libraries[0].state().disassembly().block_count() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(codec.decode("1:x") is Err(_))
}

///|
test "project restore_state reports unsupported compatibility hook" {
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.restore_state() {
    Err(reason) =>
      assert_true(
        reason ==
        "Project.restore_state: this function should no be used. Please use the Toplevel module to save/restore the state.",
      )
    Ok(_) => fail("unexpected restore_state success")
  }
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
        "$symbol/$symbol_name@$symbol_addr/$symbol_min_addr-$symbol_max_addr in " +
        "$section_name@$section_addr/$section_min_addr-$section_max_addr " +
        "covers $addr/$min_addr-$max_addr and $missing",
      )
      assert_true(
        tagged
        .memory()
        .lookup(0x1001UL)
        .any(entry => {
          entry.1 ==
          "comment=entry/entry@0x1000/0x1000-0x1001 in " +
          ".text@0x1000/0x1000-0x1001 covers " +
          "0x1001/0x1001-0x1001 and missing"
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
    block, "block-comment", "$block/$block_name spans $block_addr/$block_min_addr-$block_max_addr",
  )
  assert_true(
    tagged
    .memory()
    .lookup(0x1000UL)
    .any(entry => {
      entry.1 ==
      "block-comment=blk_0x1000/blk_0x1000 spans 0x1000/0x1000-0x1001"
    }),
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
    code=0x90,
    name="nop",
    encoding="x86",
  )
  let project = @project.Project::empty(target).with_disassembly(
    @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_instruction(instruction),
  )
  match block.view(from=0x1001UL, words=1) {
    Ok(region) => {
      let tagged = project.substitute(
        region, "disasm-comment", "$insn@$insn_code[$insn_encoding]: $asm / $bil",
      )
      assert_true(
        tagged
        .memory()
        .lookup(0x1001UL)
        .any(entry => {
          entry.1 == "disasm-comment=nop@0x90[x86]: nop; ret / jmp 0x1001"
        }),
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly instructions replace by memory and support lookup" {
  let block = raw_segment().memory()
  match (block.view(words=1), block.view(from=0x1001UL, words=1)) {
    (Ok(first_byte), Ok(second_byte)) => {
      let first = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        assembly="old",
        bil="old-bil",
      )
      let replacement = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        assembly="new",
        bil="new-bil",
      )
      let second = @project.ProjectDisassemblyInstruction::create(
        second_byte,
        assembly="tail",
        bil="tail-bil",
      )
      let state = @project.ProjectDisassemblyState::empty()
        .add_instruction(first)
        .add_instruction(replacement)
        .add_instruction(second)
      assert_true(first.addr() == 0x1000UL)
      assert_true(first.contains(0x1000UL))
      assert_true(!first.contains(0x1001UL))
      assert_true(state.instruction_count() == 2)
      assert_true(state.has_instruction(first))
      assert_true(state.instructions()[0].assembly() == "new")
      assert_true(state.instructions()[1].assembly() == "tail")
      match state.instruction_at(0x1000UL) {
        Some(instruction) => {
          assert_true(instruction.assembly() == "new")
          assert_true(instruction.bil() == "new-bil")
        }
        None => fail("missing replacement instruction")
      }
      match state.instruction_for(second_byte) {
        Some(instruction) => assert_true(instruction.assembly() == "tail")
        None => fail("missing tail instruction")
      }
      let in_block = state.instructions_in(block)
      assert_true(in_block.length() == 2)
      assert_true(in_block[0].addr() == 0x1000UL)
      assert_true(in_block[1].addr() == 0x1001UL)
      assert_true(state.instructions_in(second_byte).length() == 1)
      assert_true(state.instruction_at(0x1002UL) is None)
      assert_true(state.instruction_for(block) is None)
      let created = @project.ProjectDisassemblyState::create(instructions=[
        first, replacement, second, second,
      ])
      assert_true(created.instruction_count() == 2)
      match created.instruction_at(0x1000UL) {
        Some(instruction) => assert_true(instruction.assembly() == "new")
        None => fail("missing created replacement instruction")
      }
      let replaced = @project.ProjectDisassemblyState::empty().with_instructions([
          first, replacement, second, second,
        ],
      )
      assert_true(replaced.instruction_count() == 2)
    }
    (Err(reason), _) | (_, Err(reason)) => fail(reason)
  }
}

///|
test "project disassembly block views expose BAP block accessors" {
  let block = raw_segment().memory()
  let other = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2000UL,
    b"\x01",
  )
  match (block.view(words=1), block.view(from=0x1001UL, words=1)) {
    (Ok(first_byte), Ok(second_byte)) => {
      let first = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        assembly="nop",
        code=0x90,
        name="nop",
      )
      let second = @project.ProjectDisassemblyInstruction::create(
        second_byte,
        assembly="ret",
        code=0xc3,
        name="ret",
      )
      let mutable_insns = [first, second]
      match @project.ProjectDisassemblyBlock::create(block, mutable_insns) {
        Ok(view) => {
          mutable_insns.push(first)
          assert_true(view.addr() == 0x1000UL)
          assert_true(view.memory().min_addr() == 0x1000UL)
          assert_true(view.leader().name() == "nop")
          assert_true(view.terminator().name() == "ret")
          assert_true(view.instruction_count() == 2)
          assert_true(view.instructions().length() == 2)
          let exposed = view.instructions()
          exposed.push(first)
          assert_true(view.instruction_count() == 2)
          let pairs = view.insns()
          assert_true(pairs.length() == 2)
          assert_true(pairs[0].0.min_addr() == 0x1000UL)
          assert_true(pairs[0].1.name() == "nop")
          assert_true(pairs[1].0.min_addr() == 0x1001UL)
          assert_true(pairs[1].1.name() == "ret")
          assert_true(view.to_string() == "[0x1000,0x1001]")
          match @project.ProjectDisassemblyBlock::create(other, [first]) {
            Ok(other_view) => {
              assert_true(view.compare(other_view) < 0)
              assert_true(!view.same(other_view))
            }
            Err(reason) => fail(reason)
          }
        }
        Err(reason) => fail(reason)
      }
      assert_true(@project.ProjectDisassemblyBlock::create(block, []) is Err(_))
      let state = @project.ProjectDisassemblyState::empty()
        .add_block(block)
        .add_block(other)
        .add_instruction(second)
        .add_instruction(first)
      match state.block_view(block) {
        Ok(view) => {
          assert_true(view.leader().addr() == 0x1000UL)
          assert_true(view.terminator().addr() == 0x1001UL)
        }
        Err(reason) => fail(reason)
      }
      assert_true(state.block_view(other) is Err(_))
      let views = state.blocks_with_instructions()
      assert_true(views.length() == 1)
      match state.block_view(block) {
        Ok(view) => assert_true(views[0].same(view))
        Err(reason) => fail(reason)
      }
    }
    (Err(reason), _) | (_, Err(reason)) => fail(reason)
  }
}

///|
test "project disassembly instructions carry BAP instruction metadata" {
  let block = raw_segment().memory()
  match (block.view(words=1), block.view(from=0x1001UL, words=1)) {
    (Ok(first_byte), Ok(second_byte)) => {
      let sub = @project.ProjectDisassemblyInstruction::create(
        second_byte,
        assembly="ret",
        code=0xc3,
        name="ret",
        encoding="x86",
      )
      let mutable_subs = [sub]
      let instruction = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        assembly="nop",
        bil="skip",
        code=0x90,
        name="nop",
        encoding="x86",
        subinstructions=mutable_subs,
      )
      mutable_subs.push(
        @project.ProjectDisassemblyInstruction::create(
          second_byte,
          code=0xcc,
          name="int3",
          encoding="x86",
        ),
      )
      assert_true(instruction.code() == 0x90)
      assert_true(instruction.name() == "nop")
      assert_true(instruction.encoding() == "x86")
      assert_true(instruction.subinstruction_count() == 1)
      assert_true(instruction.subinstructions()[0].name() == "ret")
      assert_true(instruction.subs()[0].code() == 0xc3)
      let returned_subs = instruction.subinstructions()
      returned_subs.push(sub)
      assert_true(instruction.subinstruction_count() == 1)
      let renamed = instruction.with_metadata(name="pause")
      assert_true(renamed.code() == 0x90)
      assert_true(renamed.name() == "pause")
      assert_true(renamed.encoding() == "x86")
      let recoded = renamed.with_metadata(code=0xf3, encoding="x86_64")
      assert_true(recoded.code() == 0xf3)
      assert_true(recoded.name() == "pause")
      assert_true(recoded.encoding() == "x86_64")
      assert_true(
        instruction.with_subinstructions([]).subinstruction_count() == 0,
      )
    }
    (Err(reason), _) | (_, Err(reason)) => fail(reason)
  }
}

///|
test "project disassembly instruction keys normalize operand tokens" {
  let block = raw_segment().memory()
  match (block.view(words=1), block.view(from=0x1001UL, words=1)) {
    (Ok(first_byte), Ok(second_byte)) => {
      let reg = @project.ProjectInstructionOperand::register(name="RAX", code=1)
      let first = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        code=0x90,
        name="nop",
        operands=[reg, @project.ProjectInstructionOperand::immediate(1L)],
      )
      let second = @project.ProjectDisassemblyInstruction::create(
        second_byte,
        code=0xc3,
        name="ret",
        operands=[@project.ProjectInstructionOperand::immediate(2L)],
      )
      let state = @project.ProjectDisassemblyState::empty()
        .add_block(block)
        .add_instruction(second)
        .add_instruction(first)
      match state.key_of_first_insns(block, len=2) {
        Some(key) => {
          assert_true(key.length() == 2)
          match key.nth(0) {
            Some(token) => {
              assert_true(token.code() == 0x90)
              assert_true(token.operand_count() == 2)
            }
            None => fail("missing first token")
          }
          match key.nth(1) {
            Some(token) => assert_true(token.code() == 0xc3)
            None => fail("missing second token")
          }
          assert_true(key.nth(2) is None)
          let exposed = key.tokens()
          exposed.push(@project.ProjectInstructionToken::create(code=0xcc))
          assert_true(key.length() == 2)
          let same_shape = @project.ProjectInstructionKey::of_instructions(
            [
              first.with_operands([
                @project.ProjectInstructionOperand::register(name="RAX", code=1),
                @project.ProjectInstructionOperand::immediate(99L),
                @project.ProjectInstructionOperand::floating(3.0),
              ]),
              second.with_operands([
                @project.ProjectInstructionOperand::immediate(100L),
                @project.ProjectInstructionOperand::register(
                  name="ignored",
                  code=9,
                ),
              ]),
            ],
            len=2,
          )
          match same_shape {
            Some(other) => assert_true(key.same_normalized(other))
            None => fail("missing normalized key")
          }
          let different_code = @project.ProjectInstructionKey::of_instructions(
            [first.with_metadata(code=0xcc), second],
            len=2,
          )
          match different_code {
            Some(other) => assert_true(!key.same_normalized(other))
            None => fail("missing different-code key")
          }
          let shorter = @project.ProjectInstructionKey::of_instructions(
            [first],
            len=1,
          )
          match shorter {
            Some(other) => assert_true(!key.same_normalized(other))
            None => fail("missing shorter key")
          }
        }
        None => fail("missing instruction key")
      }
      assert_true(state.key_of_first_insns(block, len=3) is None)
      assert_true(
        @project.ProjectInstructionKey::of_instructions([first], len=-1) is None,
      )
      let mutable_operands = [@project.ProjectInstructionOperand::immediate(7L)]
      let token = @project.ProjectInstructionToken::create(
        code=0x77,
        operands=mutable_operands,
      )
      mutable_operands.push(reg)
      assert_true(token.operand_count() == 1)
      let exposed_operands = token.operands()
      exposed_operands.push(reg)
      assert_true(token.operand_count() == 1)
    }
    (Err(reason), _) | (_, Err(reason)) => fail(reason)
  }
}

///|
test "project disassembly instructions carry BAP instruction kinds" {
  let block = raw_segment().memory()
  match block.view(words=1) {
    Ok(first_byte) => {
      let instruction = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        kinds=[
          ProjectMayStore,
          ProjectCall,
          ProjectMayStore,
          ProjectConditionalBranch,
        ],
      )
      assert_true(
        instruction.kinds().map(kind => kind.to_string()) ==
        ["conditional-branch", "call", "may-store"],
      )
      assert_true(instruction.has_kind(ProjectCall))
      assert_true(instruction.is_kind(ProjectCall))
      assert_true(instruction.may(ProjectMayStore))
      assert_true(instruction.is_branch())
      assert_true(instruction.affects_control_flow())
      assert_true(instruction.has_side_effect())
      let updated = instruction
        .must_not(ProjectCall)
        .should(ProjectMayLoad)
        .must(ProjectReturn)
        .should_not(ProjectMayStore)
      assert_true(!updated.has_kind(ProjectCall))
      assert_true(updated.has_kind(ProjectMayLoad))
      assert_true(updated.is_kind(ProjectReturn))
      assert_true(!updated.may(ProjectMayStore))
      assert_true(
        updated.kinds().map(kind => kind.to_string()) ==
        ["conditional-branch", "return", "may-load"],
      )
      assert_true(@project.ProjectIndirectBranch.is_branch())
      assert_true(!@project.ProjectMayLoad.affects_control_flow())
      assert_true(@project.ProjectMayLoad.has_side_effect())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly instructions carry BAP operands" {
  let block = raw_segment().memory()
  match block.view(words=1) {
    Ok(first_byte) => {
      let reg = @project.ProjectInstructionOperand::register(name="RAX", code=1)
      let imm = @project.ProjectInstructionOperand::immediate(0x1234L)
      let wide_imm = @project.ProjectInstructionOperand::immediate(0x80000000L)
      let fmm = @project.ProjectInstructionOperand::floating(1.5)
      let instruction = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        operands=[reg, imm, fmm],
      )
      assert_true(instruction.operand_count() == 3)
      assert_true(
        instruction.operands().map(operand => operand.to_string()) ==
        ["RAX", "0x1234", "1.5"],
      )
      assert_true(reg.register_code() == Some(1))
      assert_true(reg.register_name() == Some("RAX"))
      assert_true(imm.to_int64() == Some(0x1234L))
      assert_true(imm.to_int() == Some(0x1234))
      assert_true(
        imm.to_word(width=16) ==
        Some(try! @types.Word::of_int64(0x1234L, width=16)),
      )
      assert_true(wide_imm.to_int() is None)
      assert_true(fmm.to_float() == Some(1.5))
      assert_true(
        @project.ProjectInstructionOperand::immediate(7L).same_normalized(
          @project.ProjectInstructionOperand::immediate(99L),
        ),
      )
      let same_shape = instruction.with_operands([
        @project.ProjectInstructionOperand::register(name="RAX", code=1),
        @project.ProjectInstructionOperand::immediate(99L),
      ])
      assert_true(instruction.same_normalized_operands(same_shape))
      let different_reg = instruction.with_operands([
        @project.ProjectInstructionOperand::register(name="RBX", code=2),
        @project.ProjectInstructionOperand::immediate(99L),
      ])
      assert_true(!instruction.same_normalized_operands(different_reg))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly state removes blocks instructions and edges" {
  let block = raw_segment().memory()
  let other = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2000UL,
    b"\x03",
  )
  match block.view(words=1) {
    Ok(first_byte) => {
      let instruction = @project.ProjectDisassemblyInstruction::create(
        first_byte,
        assembly="head",
      )
      let other_instruction = @project.ProjectDisassemblyInstruction::create(
        other,
        assembly="other",
      )
      let edge = @project.ProjectDisassemblyEdge::create(
        source=0x1000UL,
        target=0x1001UL,
        kind=FallEdge,
      )
      let other_edge = @project.ProjectDisassemblyEdge::create(
        source=0x2000UL,
        target=0x2000UL,
        kind=JumpEdge,
      )
      let state = @project.ProjectDisassemblyState::empty()
        .add_block(block)
        .add_block(other)
        .add_instruction(instruction)
        .add_instruction(other_instruction)
        .add_edge(edge)
        .add_edge(other_edge)
      let without_edge = state.remove_edge(edge)
      assert_true(without_edge.edge_count() == 1)
      assert_true(!without_edge.has_edge(edge))
      assert_true(without_edge.has_edge(other_edge))
      let without_instruction = state.remove_instruction(instruction)
      assert_true(without_instruction.instruction_count() == 1)
      assert_true(without_instruction.instruction_at(0x1000UL) is None)
      assert_true(without_instruction.instruction_at(0x2000UL) is Some(_))
      let without_block = state.remove_block(block)
      assert_true(without_block.block_count() == 1)
      assert_true(!without_block.has_block(block))
      assert_true(without_block.has_block(other))
      assert_true(without_block.instruction_count() == 1)
      assert_true(without_block.instruction_at(0x1000UL) is None)
      assert_true(without_block.edge_count() == 1)
      assert_true(!without_block.has_edge(edge))
      assert_true(without_block.has_edge(other_edge))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly state exposes block-scoped edge lookup" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4000UL,
    b"\x01\x02\x03\x04",
  )
  let other = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5000UL,
    b"\x05\x06",
  )
  let from_interior = @project.ProjectDisassemblyEdge::create(
    source=0x4002UL,
    target=0x5001UL,
    kind=CondEdge,
  )
  let unknown_from_block = @project.ProjectDisassemblyEdge::create(
    source=0x4003UL,
    kind=JumpEdge,
  )
  let to_interior = @project.ProjectDisassemblyEdge::create(
    source=0x3000UL,
    target=0x4001UL,
    kind=FallEdge,
  )
  let outside = @project.ProjectDisassemblyEdge::create(
    source=0x6000UL,
    target=0x6001UL,
    kind=JumpEdge,
  )
  let state = @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_block(other)
    .add_edge(from_interior)
    .add_edge(unknown_from_block)
    .add_edge(to_interior)
    .add_edge(outside)
  let from_block = state.edges_from_block(block)
  assert_true(from_block.length() == 2)
  assert_true(from_block.any(edge => edge.source() == 0x4002UL))
  assert_true(from_block.any(edge => edge.source() == 0x4003UL))
  let to_block = state.edges_to_block(block)
  assert_true(to_block.length() == 1)
  assert_true(to_block[0].source() == 0x3000UL)
  let touching = state.edges_touching_block(block)
  assert_true(touching.length() == 3)
  assert_true(touching.any(edge => edge.source() == 0x4002UL))
  assert_true(touching.any(edge => edge.source() == 0x4003UL))
  assert_true(touching.any(edge => edge.target() == Some(0x4001UL)))
  assert_true(!touching.any(edge => edge.source() == 0x6000UL))
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
  let edge = @project.ProjectDisassemblyEdge::create(
    source=0x1000UL,
    target=0x1001UL,
    kind=FallEdge,
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(block)
    .add_block(same_block)
    .add_instruction(instruction)
    .add_edge(edge)
    .add_edge(edge)
  let created = @project.ProjectDisassemblyState::create(
    blocks=[block, same_block],
    edges=[edge, edge],
  )
  let replaced = @project.ProjectDisassemblyState::empty()
    .with_blocks([block, same_block])
    .with_edges([edge, edge])
  assert_true(created.block_count() == 1)
  assert_true(created.edge_count() == 1)
  assert_true(replaced.block_count() == 1)
  assert_true(replaced.edge_count() == 1)
  assert_true(disassembly.has_block(block))
  assert_true(disassembly.has_edge(edge))
  assert_true(disassembly.block_count() == 1)
  assert_true(disassembly.edge_count() == 1)
  let state = @project.ProjectState::empty()
    .with_disassembly(disassembly)
    .add_subroutine(sub)
  let project = @project.Project::empty(target).with_state(state)
  assert_true(project.state().subroutines().length() == 1)
  assert_true(project.disassembly().block_count() == 1)
  assert_true(project.disassembly().instruction_count() == 1)
  assert_true(project.disassembly().edge_count() == 1)
  assert_true(project.disassembly().blocks()[0].min_addr() == 0x1000UL)
  assert_true(project.disassembly().instructions()[0].assembly() == "ret")
  assert_true(project.disassembly().edges()[0].kind().to_string() == "fall")
  assert_true(project.disassembly().edges_from(0x1000UL).length() == 1)
  assert_true(project.disassembly().edges_to(0x1001UL).length() == 1)
  let cleared = project.with_disassembly(
    @project.ProjectDisassemblyState::empty(),
  )
  assert_true(cleared.disassembly().block_count() == 0)
  assert_true(cleared.disassembly().instruction_count() == 0)
  assert_true(cleared.disassembly().edge_count() == 0)
  let library = @project.Library::create(name="libstate", target~, state~)
  assert_true(library.state().subroutines().length() == 1)
  assert_true(library.disassembly().block_count() == 1)
  assert_true(library.disassembly().instruction_count() == 1)
  assert_true(library.disassembly().edge_count() == 1)
}
