///|
fn project_disasm_test_memory(start : UInt64, data : Bytes) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start~, data)
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
