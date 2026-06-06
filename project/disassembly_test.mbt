///|
fn project_disasm_test_memory(start : UInt64, data : Bytes) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start~, data)
}

///|
fn project_disasm_test_instruction_strings(
  instruction : @project.ProjectDisassemblyInstruction,
) -> Array[String] {
  let parts = [instruction.name()]
  for operand in instruction.operands() {
    parts.push(operand.to_string())
  }
  parts
}

///|
test "project disasm constructs from cfg and enumerates instructions" {
  let memory = project_disasm_test_memory(0xe000UL, b"\x01")
  let instruction = @project.ProjectDisassemblyInstruction::create(
    memory,
    assembly=".byte 0x01",
    code=1,
  )
  match @project.ProjectDisassemblyBlock::create(memory, [instruction]) {
    Ok(block) => {
      let cfg = @project.ProjectDisassemblyCfg::create(nodes=[block])
      let disasm = @project.ProjectDisasm::create(cfg)
      assert_true(disasm.cfg().node_count() == 1)
      assert_true(disasm.insns().length() == 1)
      assert_true(disasm.insns()[0].1.code() == 1)
      assert_true(disasm.errors().is_empty())
      assert_true(!disasm.has_errors())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm of_mem reaches Basic llvm x86_64 fixture decoder" {
  let samples : Array[
    (Bytes, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (b"\x48\x83\xec\x08", ["SUB64ri8", "RSP", "RSP", "0x8"], []),
    (
      b"\xe8\x47\xee\xff\xff",
      ["CALL64pcrel32", "-0x11b9"],
      [ProjectCall, ProjectMayAffectControlFlow],
    ),
    (
      b"\x8b\x40\x10",
      ["MOV32rm", "EAX", "RAX", "0x1", "Nil", "0x10", "Nil"],
      [ProjectMayLoad],
    ),
    (b"\x48\x83\xc4\x08", ["ADD64ri8", "RSP", "RSP", "0x8"], []),
    (
      b"\xc3",
      ["RET"],
      [
        ProjectReturn,
        ProjectBarrier,
        ProjectTerminator,
        ProjectMayAffectControlFlow,
      ],
    ),
  ]
  let sequence = b"\x48\x83\xec\x08" +
    b"\xe8\x47\xee\xff\xff" +
    b"\x8b\x40\x10" +
    b"\x48\x83\xc4\x08" +
    b"\xc3"
  let memory = project_disasm_test_memory(0xe500UL, sequence)
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86_64(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      assert_true(disasm.project().get("disassembler") == Some("basic"))
      assert_true(disasm.disassembly().block_count() == 2)
      assert_true(disasm.disassembly().instruction_count() == samples.length())
      assert_true(disasm.cfg().node_count() == 2)
      assert_true(disasm.cfg().edge_count() == 1)
      assert_true(
        disasm.disassembly().blocks().map(block => block.min_addr()) ==
        [0xe500UL, 0xe509UL],
      )
      let insns = disasm.insns()
      assert_true(insns.length() == samples.length())
      assert_true(insns.map(item => item.0.length()) == [4, 5, 3, 4, 1])
      for i in 0..<samples.length() {
        assert_true(
          project_disasm_test_instruction_strings(insns[i].1) == samples[i].1,
        )
        assert_true(insns[i].1.kinds() == samples[i].2)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm Basic llvm decodes BAP call1 micro fixture" {
  let memory = project_disasm_test_memory(
    0xe600UL,
    b"\xe8\x01\x00\x00\x00" + b"\xc3" + b"\xc3" + b"\xc3",
  )
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86_64(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      let insns = disasm.insns()
      assert_true(insns.map(item => item.0.length()) == [5, 1, 1, 1])
      assert_true(
        project_disasm_test_instruction_strings(insns[0].1) ==
        ["CALL64pcrel32", "0x1"],
      )
      assert_true(
        insns[0].1.kinds() == [ProjectCall, ProjectMayAffectControlFlow],
      )
      for i in 1..<4 {
        assert_true(
          project_disasm_test_instruction_strings(insns[i].1) == ["RET"],
        )
        assert_true(insns[i].1.has_kind(ProjectReturn))
      }
      assert_true(disasm.disassembly().block_count() == 4)
      let cfg = disasm.cfg()
      assert_true(cfg.node_count() == 4)
      assert_true(cfg.edge_count() == 2)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0xe600UL, 0xe605UL, 0xe606UL, 0xe607UL],
      )
      assert_true(blocks.map(block => block.memory().length()) == [5, 1, 1, 1])
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing call target edge")
      }
      match cfg.edge(blocks[0], blocks[1]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing call fall-through edge")
      }
      assert_true(cfg.successors(blocks[1]).is_empty())
      assert_true(cfg.successors(blocks[2]).is_empty())
      assert_true(cfg.successors(blocks[3]).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm Basic llvm decodes x86 call1 micro fixture" {
  let memory = project_disasm_test_memory(
    0xe700UL,
    b"\xe8\x01\x00\x00\x00" + b"\xc3" + b"\xc3" + b"\xc3",
  )
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      let insns = disasm.insns()
      assert_true(insns.map(item => item.0.length()) == [5, 1, 1, 1])
      assert_true(
        project_disasm_test_instruction_strings(insns[0].1) ==
        ["CALLpcrel32", "0x1"],
      )
      assert_true(
        insns[0].1.kinds() == [ProjectCall, ProjectMayAffectControlFlow],
      )
      for i in 1..<4 {
        assert_true(
          project_disasm_test_instruction_strings(insns[i].1) == ["RET"],
        )
        assert_true(insns[i].1.has_kind(ProjectReturn))
      }
      assert_true(disasm.disassembly().block_count() == 4)
      let cfg = disasm.cfg()
      assert_true(cfg.node_count() == 4)
      assert_true(cfg.edge_count() == 2)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0xe700UL, 0xe705UL, 0xe706UL, 0xe707UL],
      )
      assert_true(blocks.map(block => block.memory().length()) == [5, 1, 1, 1])
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing x86 call target edge")
      }
      match cfg.edge(blocks[0], blocks[1]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing x86 call fall-through edge")
      }
      assert_true(cfg.successors(blocks[1]).is_empty())
      assert_true(cfg.successors(blocks[2]).is_empty())
      assert_true(cfg.successors(blocks[3]).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm Basic llvm splits x86 near jump target blocks" {
  let memory = project_disasm_test_memory(
    0xe800UL,
    b"\xe9\x01\x00\x00\x00" + b"\x90" + b"\xc3",
  )
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      let insns = disasm.insns()
      assert_true(insns.map(item => item.0.length()) == [5, 1, 1])
      assert_true(
        project_disasm_test_instruction_strings(insns[0].1) ==
        ["JMP_4", "0xe806"],
      )
      assert_true(insns[0].1.has_kind(ProjectUnconditionalBranch))
      assert_true(
        project_disasm_test_instruction_strings(insns[1].1) == ["NOOP"],
      )
      assert_true(
        project_disasm_test_instruction_strings(insns[2].1) == ["RET"],
      )
      assert_true(disasm.disassembly().block_count() == 3)
      let cfg = disasm.cfg()
      assert_true(cfg.node_count() == 3)
      assert_true(cfg.edge_count() == 2)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0xe800UL, 0xe805UL, 0xe806UL],
      )
      assert_true(blocks.map(block => block.memory().length()) == [5, 1, 1])
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing x86 near jump target edge")
      }
      assert_true(cfg.edge(blocks[0], blocks[1]) is None)
      match cfg.edge(blocks[1], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing x86 near jump fall-through edge")
      }
      assert_true(cfg.successors(blocks[2]).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm Basic llvm splits x86_64 push and jump blocks" {
  let memory = project_disasm_test_memory(
    0xe900UL,
    b"\x55" + b"\x54" + b"\xe9\x01\x00\x00\x00" + b"\x90" + b"\xc3",
  )
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86_64(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      let insns = disasm.insns()
      assert_true(insns.map(item => item.0.length()) == [1, 1, 5, 1, 1])
      assert_true(
        project_disasm_test_instruction_strings(insns[0].1) ==
        ["PUSH64r", "RBP"],
      )
      assert_true(insns[0].1.kinds() == [ProjectMayStore])
      assert_true(
        project_disasm_test_instruction_strings(insns[1].1) ==
        ["PUSH64r", "RSP"],
      )
      assert_true(insns[1].1.kinds() == [ProjectMayStore])
      assert_true(
        project_disasm_test_instruction_strings(insns[2].1) ==
        ["JMP_4", "0xe908"],
      )
      assert_true(disasm.disassembly().block_count() == 3)
      let cfg = disasm.cfg()
      assert_true(cfg.node_count() == 3)
      assert_true(cfg.edge_count() == 2)
      let blocks = cfg.nodes()
      assert_true(
        blocks.map(block => block.memory().min_addr()) ==
        [0xe900UL, 0xe907UL, 0xe908UL],
      )
      assert_true(blocks.map(block => block.memory().length()) == [7, 1, 1])
      match cfg.edge(blocks[0], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == JumpEdge)
        None => fail("missing x86_64 push/jump target edge")
      }
      assert_true(cfg.edge(blocks[0], blocks[1]) is None)
      match cfg.edge(blocks[1], blocks[2]) {
        Some(edge) => assert_true(edge.kind() == FallEdge)
        None => fail("missing x86_64 push/jump fall-through edge")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm Basic llvm decodes x86_64 pop epilogue" {
  let memory = project_disasm_test_memory(0xea00UL, b"\x5d\xc3")
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::x86_64(),
      memory,
      backend="basic",
    ) {
    Ok(disasm) => {
      let insns = disasm.insns()
      assert_true(insns.map(item => item.0.length()) == [1, 1])
      assert_true(
        project_disasm_test_instruction_strings(insns[0].1) == ["POP64r", "RBP"],
      )
      assert_true(insns[0].1.kinds() == [ProjectMayLoad])
      assert_true(
        project_disasm_test_instruction_strings(insns[1].1) == ["RET"],
      )
      assert_true(insns[1].1.has_kind(ProjectReturn))
      assert_true(disasm.disassembly().block_count() == 1)
      let cfg = disasm.cfg()
      assert_true(cfg.node_count() == 1)
      assert_true(cfg.edge_count() == 0)
      let blocks = cfg.nodes()
      assert_true(blocks.map(block => block.memory().min_addr()) == [0xea00UL])
      assert_true(blocks.map(block => block.memory().length()) == [2])
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project and library disasm accessors wrap existing state" {
  let memory = project_disasm_test_memory(0xe050UL, b"\xc3")
  let instruction = @project.ProjectDisassemblyInstruction::create(
    memory,
    assembly="ret",
    code=0xc3,
  )
  let state = @project.ProjectState::empty().with_disassembly(
    @project.ProjectDisassemblyState::empty()
    .add_block(memory)
    .add_instruction(instruction),
  )
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_state(
    state,
  )
  let project_disasm = project.disasm()
  assert_true(project_disasm.disassembly().block_count() == 1)
  assert_true(project_disasm.insns().length() == 1)
  assert_true(
    project_disasm.project().disassembly().instructions()[0].code() == 0xc3,
  )
  let library = @project.Library::create(
    name="libdisasm.so",
    target=@core_theory.Target::unknown(),
    memory=@memory.MemMap::singleton(memory, "code"),
    state~,
  )
  let library_disasm = library.disasm()
  assert_true(library_disasm.disassembly().instruction_count() == 1)
  assert_true(library_disasm.project().filename() == Some("libdisasm.so"))
  assert_true(library_disasm.project().memory().length() == 1)
}

///|
test "project disasm runs over memory and honors explicit brancher roots" {
  let memory = project_disasm_test_memory(0xe100UL, b"\x10\x20")
  let brancher = @project.ProjectBrancher::of_edges([
    @project.ProjectDisassemblyEdge::create(
      source=0xe100UL,
      target=0xe101UL,
      kind=JumpEdge,
    ),
  ])
  let rooter = @project.ProjectRooter::create([0xe100UL])
  match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::unknown(),
      memory,
      backend="raw-bytes",
      brancher~,
      rooter~,
    ) {
    Ok(disasm) => {
      assert_true(disasm.disassembly().block_count() == 1)
      assert_true(disasm.disassembly().instruction_count() == 2)
      assert_true(disasm.cfg().node_count() == 1)
      assert_true(disasm.disassembly().edge_count() == 1)
      assert_true(disasm.insns().length() == 2)
      assert_true(disasm.project().get("disassembler") == Some("raw-bytes"))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm constructs from image using executable roots" {
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0xe200UL,
    b"\x90\x91",
    executable=true,
    readable=true,
  )
  let data = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0xe300UL,
    b"\x01",
    executable=false,
    readable=true,
  )
  let image = @image.Image::from_segments(
    entry=0xe200UL,
    endian=LittleEndian,
    [text, data],
    target=@core_theory.Target::unknown(),
  )
  match @project.ProjectDisasm::of_image(image, backend="image-roots") {
    Ok(disasm) => {
      assert_true(disasm.disassembly().block_count() == 1)
      assert_true(disasm.disassembly().blocks()[0].min_addr() == 0xe200UL)
      assert_true(disasm.disassembly().instruction_count() == 0)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm merge unions state and appends errors" {
  let left_memory = project_disasm_test_memory(0xe400UL, b"\x01")
  let right_memory = project_disasm_test_memory(0xe410UL, b"\x02")
  let left = match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::unknown(),
      left_memory,
      backend="raw-bytes",
    ) {
    Ok(value) => value
    Err(reason) => fail(reason)
  }
  let right = match
    @project.ProjectDisasm::of_mem(
      @core_theory.Target::unknown(),
      right_memory,
      backend="raw-bytes",
    ) {
    Ok(value) =>
      @project.ProjectDisasm::from_project(value.project(), errors=[
        @project.ProjectDisassemblyRecError::failed_to_disasm(right_memory),
      ])
    Err(reason) => fail(reason)
  }
  let merged = left.merge(right)
  assert_true(merged.disassembly().block_count() == 2)
  assert_true(merged.disassembly().instruction_count() == 2)
  assert_true(merged.errors().length() == 1)
}

///|
test "project disasm checked and exn constructors report failures" {
  let empty = @project.Project::empty(@core_theory.Target::unknown())
  match @project.ProjectDisasm::of_project(empty, backend="missing") {
    Err(reason) =>
      assert_true(reason.contains("unknown project disassembly driver missing"))
    Ok(_) => fail("unexpected disassembly success")
  }
  try {
    let _ = @project.ProjectDisasm::of_project_exn(empty, backend="missing")
    fail("unexpected exn disassembly success")
  } catch {
    @project.ProjectDisasmFailure(reason) =>
      assert_true(reason.contains("unknown project disassembly driver missing"))
    _ => fail("unexpected disassembly exception")
  }
}
