///|
fn disasm_reconstructor_test_block(
  start : UInt64,
  bytes : Bytes,
  assembly? : String = "nop",
  kinds? : Array[@project.ProjectInstructionKind],
) -> @project.ProjectDisassemblyBlock raise {
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  let instruction = @project.ProjectDisassemblyInstruction::create(
    memory,
    assembly~,
    kinds?,
  )
  match @project.ProjectDisassemblyBlock::create(memory, [instruction]) {
    Ok(block) => block
    Err(reason) => fail(reason)
  }
}

///|
fn disasm_reconstructor_test_name(addr : UInt64) -> String {
  "sub_0x" + addr.to_string(radix=16)
}

///|
test "project disassembly reconstructor supports custom callbacks" {
  let block = disasm_reconstructor_test_block(0xb000UL, b"\x01")
  let cfg = @project.ProjectDisassemblyCfg::empty().insert_node(block)
  let reconstructor = @project.ProjectDisassemblyReconstructor::create(_ => {
    @project.ProjectDisassemblySymtab::create(functions=[
      @project.ProjectDisassemblyFunction::create(name="custom", entry=block),
    ])
  })
  let symtab = reconstructor.run(cfg)
  match symtab.find_by_name("custom") {
    Some(function) => {
      assert_true(function.addr() == 0xb000UL)
      assert_true(function.block_count() == 1)
    }
    None => fail("missing custom symbol")
  }
}

///|
test "project disassembly default reconstructor splits call destinations" {
  let entry = disasm_reconstructor_test_block(0xb100UL, b"\x01")
  let callsite = disasm_reconstructor_test_block(
    0xb110UL,
    b"\x02",
    assembly="call helper",
    kinds=[ProjectCall],
  )
  let helper = disasm_reconstructor_test_block(0xb120UL, b"\x03")
  let tail = disasm_reconstructor_test_block(0xb130UL, b"\x04")
  let cfg = @project.ProjectDisassemblyCfg::empty()
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=entry,
        dst=callsite,
        kind=FallEdge,
      ),
    )
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=callsite,
        dst=helper,
        kind=JumpEdge,
      ),
    )
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=callsite,
        dst=tail,
        kind=FallEdge,
      ),
    )
  let reconstructor = @project.ProjectDisassemblyReconstructor::default(
    disasm_reconstructor_test_name,
    [0xb100UL],
  )
  let symtab = reconstructor.run(cfg)
  assert_true(symtab.to_sequence().length() == 2)
  match symtab.find_by_start(0xb100UL) {
    Some(function) => {
      assert_true(function.name() == "sub_0xb100")
      assert_true(function.block_count() == 3)
      assert_true(function.contains_addr(0xb100UL))
      assert_true(function.contains_addr(0xb110UL))
      assert_true(function.contains_addr(0xb130UL))
      assert_true(!function.contains_addr(0xb120UL))
    }
    None => fail("missing entry function")
  }
  match symtab.find_by_start(0xb120UL) {
    Some(function) => {
      assert_true(function.name() == "sub_0xb120")
      assert_true(function.block_count() == 1)
    }
    None => fail("missing helper function")
  }
  assert_true(symtab.explicit_callee(0xb110UL) == Some("sub_0xb120"))
  assert_true(symtab.implicit_callee(0xb110UL) == None)
}

///|
test "project disassembly reconstructor groups symbols of blocks" {
  let entry = disasm_reconstructor_test_block(0xb200UL, b"\x01")
  let body = disasm_reconstructor_test_block(0xb210UL, b"\x02")
  let helper = disasm_reconstructor_test_block(0xb220UL, b"\x03")
  let cfg = @project.ProjectDisassemblyCfg::empty()
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=entry,
        dst=body,
        kind=FallEdge,
      ),
    )
    .insert_edge(
      @project.ProjectDisassemblyCfgEdge::create(
        src=body,
        dst=helper,
        kind=JumpEdge,
      ),
    )
  let reconstructor = @project.ProjectDisassemblyReconstructor::of_blocks([
    ("main", 0xb210UL, 0xb210UL),
    ("main", 0xb200UL, 0xb200UL),
    ("helper", 0xb220UL, 0xb220UL),
    ("missing", 0xffffUL, 0xffffUL),
  ])
  let symtab = reconstructor.run(cfg)
  assert_true(symtab.to_sequence().length() == 2)
  match symtab.find_by_name("missing") {
    None => ()
    Some(_) => fail("unexpected missing symbol")
  }
  match symtab.find_by_name("main") {
    Some(function) => {
      assert_true(function.addr() == 0xb200UL)
      assert_true(function.block_count() == 2)
      assert_true(
        function.blocks().map(block => block.addr()) == [0xb200UL, 0xb210UL],
      )
    }
    None => fail("missing main function")
  }
  match symtab.find_by_name("helper") {
    Some(function) => {
      assert_true(function.addr() == 0xb220UL)
      assert_true(function.block_count() == 1)
    }
    None => fail("missing helper function")
  }
}
