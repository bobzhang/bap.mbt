///|
test "project disassembly basic exposes backend registry and constructors" {
  let names = @project.ProjectDisassemblyBasic::available_backends()
  assert_true(names.contains("llvm"))
  assert_true(names.contains("raw"))
  match
    @project.register_disassembly_basic_backend_if_absent(
      name="unit-basic",
      description="unit test backend",
    ) {
    Ok(true) | Ok(false) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.disassembly_basic_backends().contains("unit-basic"))
  match @project.register_disassembly_basic_backend(name="unit-basic") {
    Err(reason) =>
      assert_true(
        reason ==
        "project disassembly basic backend unit-basic is already registered",
      )
    Ok(_) => fail("duplicate backend registration succeeded")
  }
  match
    @project.ProjectDisassemblyBasic::create(
      "unknown-triple",
      backend="unit-basic",
      cpu="cpu0",
      attrs="+feature",
      debug_level=2,
    ) {
    Ok(disasm) => {
      assert_true(disasm.backend() == "unit-basic")
      assert_true(disasm.triple() == "unknown-triple")
      assert_true(disasm.cpu() == "cpu0")
      assert_true(disasm.attrs() == "+feature")
      assert_true(disasm.debug_level() == 2)
      assert_true(!disasm.stores_asm())
      assert_true(!disasm.stores_kinds())
      let configured = disasm.store_asm().store_kinds()
      assert_true(configured.stores_asm())
      assert_true(configured.stores_kinds())
      configured.close()
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectDisassemblyBasic::create("unknown", backend="missing") {
    Err(reason) => assert_true(reason == "Unknown backend: missing")
    Ok(_) => fail("unknown backend creation succeeded")
  }
}

///|
test "project disassembly basic decodes one instruction and remainder" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xd000UL,
    b"\x7f\x80",
  )
  match @project.ProjectDisassemblyBasic::create("unit", backend="raw") {
    Ok(disasm) =>
      match disasm.insn_of_mem(memory) {
        Ok(result) => {
          assert_true(result.memory().min_addr() == 0xd000UL)
          assert_true(result.memory().length() == 1)
          match result.instruction() {
            Some(instruction) => {
              assert_true(instruction.addr() == 0xd000UL)
              assert_true(instruction.code() == 0x7f)
              assert_true(instruction.name() == ".byte")
              assert_true(instruction.assembly() == ".byte 0x7f")
            }
            None => fail("missing decoded instruction")
          }
          assert_true(!result.remainder().is_finished())
          match result.remainder().memory() {
            Some(left) => {
              assert_true(left.min_addr() == 0xd001UL)
              assert_true(left.length() == 1)
            }
            None => fail("missing left memory")
          }
        }
        Err(reason) => fail(reason)
      }
    Err(reason) => fail(reason)
  }
  let empty = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xd100UL,
    b"",
  )
  match @project.ProjectDisassemblyBasic::create("unit", backend="raw") {
    Ok(disasm) =>
      match disasm.insn_of_mem(empty) {
        Ok(result) => {
          match result.instruction() {
            None => ()
            Some(_) => fail("unexpected instruction for empty memory")
          }
          assert_true(result.remainder().is_finished())
        }
        Err(reason) => fail(reason)
      }
    Err(reason) => fail(reason)
  }
}

///|
fn basic_instruction_strings(
  instruction : @project.ProjectDisassemblyInstruction,
) -> Array[String] {
  let parts = [instruction.name()]
  for operand in instruction.operands() {
    parts.push(operand.to_string())
  }
  parts
}

///|
fn basic_arm_strlen_bytes() -> Bytes {
  b"\x04\xb0\x2d\xe5" +
  b"\x00\xb0\x8d\xe2" +
  b"\x14\xd0\x4d\xe2" +
  b"\x10\x00\x0b\xe5" +
  b"\x00\x30\xa0\xe3" +
  b"\x08\x30\x0b\xe5" +
  b"\x05\x00\x00\xea" +
  b"\x10\x30\x1b\xe5" +
  b"\x01\x30\x83\xe2" +
  b"\x10\x30\x0b\xe5" +
  b"\x08\x30\x1b\xe5" +
  b"\x01\x30\x83\xe2" +
  b"\x08\x30\x0b\xe5" +
  b"\x10\x30\x1b\xe5" +
  b"\x00\x00\x53\xe3" +
  b"\xf6\xff\xff\x1a" +
  b"\x08\x30\x1b\xe5" +
  b"\x03\x00\xa0\xe1" +
  b"\x00\xd0\x4b\xe2" +
  b"\x04\xb0\x9d\xe4" +
  b"\x1e\xff\x2f\xe1"
}

///|
test "translated BAP basic disassembly decodes x86_64 llvm samples" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86_64", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let samples : Array[
    (Bytes, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (b"\x90", ["NOOP"], []),
    (b"\x48\x83\xec\x08", ["SUB64ri8", "RSP", "RSP", "0x8"], []),
    (b"\xb8\x78\x56\x34\x12", ["MOV32ri", "EAX", "0x12345678"], []),
    (
      b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11",
      ["MOV64ri", "RAX", "0x1122334455667788"],
      [],
    ),
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
      ["RET64"],
      [
        ProjectReturn,
        ProjectBarrier,
        ProjectTerminator,
        ProjectMayAffectControlFlow,
      ],
    ),
  ]
  for sample in samples {
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe000UL,
      sample.0,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.0.length())
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.1)
            assert_true(instruction.kinds() == sample.2)
          }
          None => fail("missing x86_64 llvm instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }

  let sequence = b"\x90" +
    b"\x48\x83\xec\x08" +
    b"\xb8\x78\x56\x34\x12" +
    b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11" +
    b"\xe8\x47\xee\xff\xff" +
    b"\x8b\x40\x10" +
    b"\x48\x83\xc4\x08" +
    b"\xc3"
  let run_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xe100UL,
    sequence,
  )
  let (insns, end_addr) = disasm
    .store_kinds()
    .run(run_memory, init=(), return_=_ => ([], 0UL), stopped=(s, _) => {
      (s.insns(), s.addr())
    })
  assert_true(insns.length() == samples.length())
  assert_true(insns.map(item => item.0.length()) == [1, 4, 5, 10, 5, 3, 4, 1])
  assert_true(end_addr == 0xe100UL + sequence.length().to_uint64())
  for i in 0..<samples.length() {
    match insns[i].1 {
      Some(instruction) => {
        assert_true(basic_instruction_strings(instruction) == samples[i].1)
        assert_true(instruction.kinds() == samples[i].2)
      }
      None => fail("missing run instruction")
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 ENDBR noops" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86", b"\xf3\x0f\x1e\xfb", 4, ["ENDBR32"]),
    ("x86_64", b"\xf3\x0f\x1e\xfa", 4, ["ENDBR64"]),
    ("x86_64", b"\xf3\x0f\x1e\xfb", 4, ["ENDBR32"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe130UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds().is_empty())
          }
          None => fail("missing x86 ENDBR instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 flag controls" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86", b"\xf8", 1, ["CLC"]),
    ("x86", b"\xf9", 1, ["STC"]),
    ("x86", b"\xf5", 1, ["CMC"]),
    ("x86", b"\xfc", 1, ["CLD"]),
    ("x86", b"\xfd", 1, ["STD"]),
    ("x86", b"\x9e", 1, ["SAHF"]),
    ("x86", b"\x9f", 1, ["LAHF"]),
    ("x86_64", b"\xf8", 1, ["CLC"]),
    ("x86_64", b"\xfd", 1, ["STD"]),
    ("x86_64", b"\x9e", 1, ["SAHF"]),
    ("x86_64", b"\x9f", 1, ["LAHF"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe140UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds().is_empty())
          }
          None => fail("missing x86 flag-control instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 random instructions" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86", b"\x0f\xc7\xf1", 3, ["RDRAND32r", "ECX"]),
    ("x86", b"\x66\x0f\xc7\xf1", 4, ["RDRAND16r", "CX"]),
    ("x86", b"\x0f\xc7\xf8", 3, ["RDSEED32r", "EAX"]),
    ("x86_64", b"\x49\x0f\xc7\xf1", 4, ["RDRAND64r", "R9"]),
    ("x86_64", b"\x41\x0f\xc7\xf8", 4, ["RDSEED32r", "R8D"]),
    ("x86_64", b"\x66\x41\x0f\xc7\xf8", 5, ["RDSEED16r", "R8W"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe170UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds().is_empty())
          }
          None => fail("missing x86 random instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 memory cmp-test rr fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x48\x39\x4d\xf8",
      4,
      ["CMP64mr", "RBP", "0x1", "Nil", "-0x8", "Nil", "RCX"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x48\x3b\x45\xf8",
      4,
      ["CMP64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x39\x4d\xfc",
      3,
      ["CMP32mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "ECX"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\x39\x4d\xfc",
      4,
      ["CMP16mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "CX"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x3a\x4d\xfc",
      3,
      ["CMP8rm", "CL", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x48\x85\x4d\xf8",
      4,
      ["TEST64mr", "RBP", "0x1", "Nil", "-0x8", "Nil", "RCX"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x84\x4d\xfc",
      3,
      ["TEST8mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "CL"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\x85\x4d\xfc",
      4,
      ["TEST16mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "CX"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe288UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 memory cmp/test instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 mul fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xf6\xe1", 2, ["MUL8r", "CL"], []),
    ("x86", b"\xf7\xe1", 2, ["MUL32r", "ECX"], []),
    ("x86", b"\x66\xf7\xe1", 3, ["MUL16r", "CX"], []),
    ("x86_64", b"\x48\xf7\xe1", 3, ["MUL64r", "RCX"], []),
    ("x86_64", b"\x49\xf7\xe0", 3, ["MUL64r", "R8"], []),
    (
      "x86_64",
      b"\x48\xf7\x65\xf8",
      4,
      ["MUL64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\xf7\x65\xfc",
      3,
      ["MUL32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\xf7\x65\xfc",
      4,
      ["MUL16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe2a0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 mul instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 one-operand imul fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xf6\xe9", 2, ["IMUL8r", "CL"], []),
    ("x86", b"\xf7\xe9", 2, ["IMUL32r", "ECX"], []),
    ("x86", b"\x66\xf7\xe9", 3, ["IMUL16r", "CX"], []),
    ("x86_64", b"\x48\xf7\xe9", 3, ["IMUL64r", "RCX"], []),
    ("x86_64", b"\x49\xf7\xe8", 3, ["IMUL64r", "R8"], []),
    (
      "x86_64",
      b"\x48\xf7\x6d\xf8",
      4,
      ["IMUL64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\xf7\x6d\xfc",
      3,
      ["IMUL32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\xf7\x6d\xfc",
      4,
      ["IMUL16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe2b0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 one-operand imul instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 div-idiv fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xf6\xf1", 2, ["DIV8r", "CL"], []),
    ("x86", b"\xf7\xf1", 2, ["DIV32r", "ECX"], []),
    ("x86", b"\x66\xf7\xf1", 3, ["DIV16r", "CX"], []),
    ("x86_64", b"\x48\xf7\xf1", 3, ["DIV64r", "RCX"], []),
    ("x86_64", b"\x49\xf7\xf0", 3, ["DIV64r", "R8"], []),
    (
      "x86_64",
      b"\x48\xf7\x75\xf8",
      4,
      ["DIV64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\xf7\x75\xfc",
      3,
      ["DIV32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\xf7\x75\xfc",
      4,
      ["DIV16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    ("x86", b"\xf6\xf9", 2, ["IDIV8r", "CL"], []),
    ("x86", b"\xf7\xf9", 2, ["IDIV32r", "ECX"], []),
    ("x86", b"\x66\xf7\xf9", 3, ["IDIV16r", "CX"], []),
    ("x86_64", b"\x48\xf7\xf9", 3, ["IDIV64r", "RCX"], []),
    ("x86_64", b"\x49\xf7\xf8", 3, ["IDIV64r", "R8"], []),
    (
      "x86_64",
      b"\x48\xf7\x7d\xf8",
      4,
      ["IDIV64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\xf7\x7d\xfc",
      3,
      ["IDIV32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\xf7\x7d\xfc",
      4,
      ["IDIV16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe2c0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 div/idiv instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 memory inc-dec fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x48\xff\x45\xf8",
      4,
      ["INC64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\xff\x4d\xfc",
      3,
      ["DEC32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\x66\xff\x45\xfc",
      4,
      ["INC16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\x66\xff\x4d\xfc",
      4,
      ["DEC16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x41\xfe\x40\x01",
      4,
      ["INC8m", "R8", "0x1", "Nil", "0x1", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe2a0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 memory inc-dec instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 memory not-neg fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x48\xf7\x55\xf8",
      4,
      ["NOT64m", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\xf7\x5d\xfc",
      3,
      ["NEG32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\x66\xf7\x55\xfc",
      4,
      ["NOT16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\x66\xf7\x5d\xfc",
      4,
      ["NEG16m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x41\xf6\x58\x01",
      4,
      ["NEG8m", "R8", "0x1", "Nil", "0x1", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe2c0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 memory not-neg instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register mov fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x48\x89\xe5", 3, ["MOV64rr", "RBP", "RSP"], []),
    ("x86_64", b"\x48\x8b\xec", 3, ["MOV64rr_REV", "RBP", "RSP"], []),
    ("x86_64", b"\x4c\x89\xc0", 3, ["MOV64rr", "RAX", "R8"], []),
    ("x86_64", b"\x4d\x8b\xc8", 3, ["MOV64rr_REV", "R9", "R8"], []),
    ("x86_64", b"\x66\x41\x8b\xc0", 4, ["MOV16rr_REV", "AX", "R8W"], []),
    ("x86_64", b"\x40\x88\xe0", 3, ["MOV8rr", "AL", "SPL"], []),
    ("x86_64", b"\x44\x8a\xc0", 3, ["MOV8rr_REV", "R8B", "AL"], []),
    ("x86", b"\x89\xe5", 2, ["MOV32rr", "EBP", "ESP"], []),
    ("x86", b"\x8b\xec", 2, ["MOV32rr_REV", "EBP", "ESP"], []),
    ("x86", b"\x66\x89\xd8", 3, ["MOV16rr", "AX", "BX"], []),
    ("x86", b"\x66\x8b\xc1", 3, ["MOV16rr_REV", "AX", "CX"], []),
    ("x86", b"\x88\xe0", 2, ["MOV8rr", "AL", "AH"], []),
    ("x86", b"\x8a\xe0", 2, ["MOV8rr_REV", "AH", "AL"], []),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1a0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 register mov instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 movsx movzx fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x48\x0f\xb6\xc1", 4, ["MOVZX64rr8", "RAX", "CL"], []),
    ("x86_64", b"\x4d\x0f\xb7\xc1", 4, ["MOVZX64rr16", "R8", "R9W"], []),
    ("x86_64", b"\x40\x0f\xb6\xc4", 4, ["MOVZX32rr8", "EAX", "SPL"], []),
    (
      "x86_64",
      b"\x48\x0f\xbe\x45\xfc",
      5,
      ["MOVSX64rm8", "RAX", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    ("x86_64", b"\x48\x63\xc1", 3, ["MOVSX64rr32", "RAX", "ECX"], []),
    ("x86_64", b"\x4d\x63\xc1", 3, ["MOVSX64rr32", "R8", "R9D"], []),
    ("x86_64", b"\x63\xc1", 2, ["MOVSX32rr32", "EAX", "ECX"], []),
    (
      "x86_64",
      b"\x48\x63\x45\xfc",
      4,
      ["MOVSX64rm32", "RAX", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    ("x86_64", b"\x66\x41\x0f\xb6\xc0", 5, ["MOVZX16rr8", "AX", "R8B"], []),
    ("x86", b"\x0f\xb6\xc1", 3, ["MOVZX32rr8", "EAX", "CL"], []),
    ("x86", b"\x66\x0f\xb6\xc1", 4, ["MOVZX16rr8", "AX", "CL"], []),
    ("x86", b"\x0f\xbe\xc4", 3, ["MOVSX32rr8", "EAX", "AH"], []),
    ("x86", b"\x66\x0f\xbe\xc4", 4, ["MOVSX16rr8", "AX", "AH"], []),
    (
      "x86",
      b"\x66\x0f\xbe\x45\xfc",
      5,
      ["MOVSX16rm8", "AX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x0f\xbf\x45\xfc",
      4,
      ["MOVSX32rm16", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1c0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 movsx/movzx instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 popcnt fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xf3\x0f\xb8\xc1", 4, ["POPCNT32rr", "EAX", "ECX"], []),
    ("x86", b"\x66\xf3\x0f\xb8\xc1", 5, ["POPCNT16rr", "AX", "CX"], []),
    (
      "x86",
      b"\x66\xf3\x0f\xb8\x45\xfc",
      6,
      ["POPCNT16rm", "AX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\xf3\x0f\xb8\x45\xfc",
      5,
      ["POPCNT32rm", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    ("x86_64", b"\xf3\x48\x0f\xb8\xc1", 5, ["POPCNT64rr", "RAX", "RCX"], []),
    ("x86_64", b"\xf3\x4d\x0f\xb8\xc8", 5, ["POPCNT64rr", "R9", "R8"], []),
    (
      "x86_64",
      b"\xf3\x48\x0f\xb8\x45\xf8",
      6,
      ["POPCNT64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1e0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 popcnt instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 lzcnt tzcnt fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xf3\x0f\xbc\xc1", 4, ["TZCNT32rr", "EAX", "ECX"], []),
    ("x86", b"\x66\xf3\x0f\xbd\xc1", 5, ["LZCNT16rr", "AX", "CX"], []),
    (
      "x86",
      b"\xf3\x0f\xbd\x45\xfc",
      5,
      ["LZCNT32rm", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    ("x86_64", b"\xf3\x48\x0f\xbc\xc1", 5, ["TZCNT64rr", "RAX", "RCX"], []),
    ("x86_64", b"\xf3\x4d\x0f\xbd\xc8", 5, ["LZCNT64rr", "R9", "R8"], []),
    ("x86_64", b"\x66\xf3\x45\x0f\xbc\xc1", 6, ["TZCNT16rr", "R8W", "R9W"], []),
    (
      "x86_64",
      b"\xf3\x48\x0f\xbd\x45\xf8",
      6,
      ["LZCNT64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1e8UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 lzcnt/tzcnt instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 accumulator sign-extension fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x48\x98", 2, ["CDQE"], []),
    ("x86_64", b"\x98", 1, ["CWDE"], []),
    ("x86_64", b"\x66\x98", 2, ["CBW"], []),
    ("x86_64", b"\x48\x99", 2, ["CQO"], []),
    ("x86_64", b"\x99", 1, ["CDQ"], []),
    ("x86", b"\x98", 1, ["CWDE"], []),
    ("x86", b"\x66\x98", 2, ["CBW"], []),
    ("x86", b"\x99", 1, ["CDQ"], []),
    ("x86", b"\x66\x99", 2, ["CWD"], []),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1c8UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 accumulator sign-extension instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 memory mov fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x48\x8b\x45\xf8",
      4,
      ["MOV64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x48\x89\x45\xf8",
      4,
      ["MOV64mr", "RBP", "0x1", "Nil", "-0x8", "Nil", "RAX"],
      [ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x48\x89\x04\x24",
      4,
      ["MOV64mr", "RSP", "0x1", "Nil", "0x0", "Nil", "RAX"],
      [ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x48\x8b\x44\x88\x10",
      5,
      ["MOV64rm", "RAX", "RAX", "0x4", "RCX", "0x10", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x44\x8a\x45\xfc",
      4,
      ["MOV8rm", "R8B", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x66\x8b\x45\xfc",
      4,
      ["MOV16rm", "AX", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x44\x88\x45\xfc",
      4,
      ["MOV8mr", "RBP", "0x1", "Nil", "-0x4", "Nil", "R8B"],
      [ProjectMayStore],
    ),
    (
      "x86",
      b"\x8b\x45\xfc",
      3,
      ["MOV32rm", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\x8b\x45\xfc",
      4,
      ["MOV16rm", "AX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x89\x45\xfc",
      3,
      ["MOV32mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "EAX"],
      [ProjectMayStore],
    ),
    (
      "x86",
      b"\x66\x89\x4d\xfc",
      4,
      ["MOV16mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "CX"],
      [ProjectMayStore],
    ),
    (
      "x86",
      b"\x8a\x45\xfc",
      3,
      ["MOV8rm", "AL", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x88\x45\xfc",
      3,
      ["MOV8mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "AL"],
      [ProjectMayStore],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1c0UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 memory mov instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 movbe fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86",
      b"\x0f\x38\xf0\x45\xfc",
      5,
      ["MOVBE32rm", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x66\x0f\x38\xf0\x45\xfc",
      6,
      ["MOVBE16rm", "AX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86",
      b"\x0f\x38\xf1\x4d\xfc",
      5,
      ["MOVBE32mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "ECX"],
      [ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x48\x0f\x38\xf0\x45\xf8",
      6,
      ["MOVBE64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\x4c\x0f\x38\xf1\x45\xf8",
      6,
      ["MOVBE64mr", "RBP", "0x1", "Nil", "-0x8", "Nil", "R8"],
      [ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x66\x44\x0f\x38\xf0\x45\xfc",
      7,
      ["MOVBE16rm", "R8W", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad],
    ),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1c1UL,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.2)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.3)
            assert_true(instruction.kinds() == sample.4)
          }
          None => fail("missing x86 movbe instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes ARM llvm strlen fixture" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("armv7", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let bytes = basic_arm_strlen_bytes()
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x840cUL,
    bytes,
  )
  let (insns, end_addr) = disasm
    .store_kinds()
    .run(memory, init=(), return_=_ => ([], 0UL), stopped=(s, _) => {
      (s.insns(), s.addr())
    })
  assert_true(insns.length() == 21)
  assert_true(end_addr == 0x840cUL + bytes.length().to_uint64())
  for item in insns {
    assert_true(item.0.length() == 4)
  }
  match insns[0].1 {
    Some(instruction) => {
      assert_true(
        basic_instruction_strings(instruction) ==
        ["STR_PRE_IMM", "FP", "SP", "-0x4"],
      )
      assert_true(instruction.has_kind(ProjectMayStore))
    }
    None => fail("missing ARM pre-index store")
  }
  match insns[1].1 {
    Some(instruction) =>
      assert_true(
        basic_instruction_strings(instruction) == ["ADDri", "FP", "SP", "0x0"],
      )
    None => fail("missing ARM add immediate")
  }
  match insns[6].1 {
    Some(instruction) => {
      assert_true(instruction.addr() == 0x8424UL)
      assert_true(instruction.name() == "B")
      assert_true(instruction.has_kind(ProjectUnconditionalBranch))
      assert_true(instruction.operands()[0].to_int64() == Some(0x8440L))
    }
    None => fail("missing ARM unconditional branch")
  }
  match insns[15].1 {
    Some(instruction) => {
      assert_true(instruction.addr() == 0x8448UL)
      assert_true(instruction.name() == "BNE")
      assert_true(instruction.has_kind(ProjectConditionalBranch))
      assert_true(instruction.operands()[0].to_int64() == Some(0x8428L))
    }
    None => fail("missing ARM conditional branch")
  }
  match insns[14].1 {
    Some(instruction) =>
      assert_true(
        basic_instruction_strings(instruction) == ["CMPri", "R3", "0x0"],
      )
    None => fail("missing ARM compare immediate")
  }
  match insns[19].1 {
    Some(instruction) => {
      assert_true(
        basic_instruction_strings(instruction) ==
        ["LDR_POST_IMM", "FP", "SP", "0x4"],
      )
      assert_true(instruction.has_kind(ProjectMayLoad))
    }
    None => fail("missing ARM post-index load")
  }
  match insns[20].1 {
    Some(instruction) => {
      assert_true(basic_instruction_strings(instruction) == ["BX", "LR"])
      assert_true(instruction.has_kind(ProjectReturn))
      assert_true(instruction.has_kind(ProjectTerminator))
    }
    None => fail("missing ARM return")
  }
}

///|
test "project disassembly basic run exposes state helpers and stop predicates" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xd200UL,
    b"\x01\x02\x03",
  )
  match @project.ProjectDisassemblyBasic::create("unit", backend="raw") {
    Ok(disasm) => {
      // without callbacks the whole memory is decoded and `stopped` sees
      // every instruction
      let summary = disasm.run(memory, init="init", return_=data => [data], stopped=(
        state,
        data,
      ) => {
        let with_preds = state.with_preds([
          @project.ProjectDisassemblyBasicPred::valid(),
          @project.ProjectDisassemblyBasicPred::valid(),
        ])
        let switched = state.switch(disasm.store_asm())
        // `last` lists the most recent instruction first
        let last = state.last(2).map(item => item.0.min_addr())
        [
          data,
          state.disasm().backend(),
          state.memory().min_addr().to_string(radix=16),
          state.preds().length().to_string(),
          with_preds.preds().map(pred => pred.to_string()).join(","),
          switched.disasm().stores_asm().to_string(),
          state.addr().to_string(radix=16),
          state.insns().length().to_string(),
          last.map(addr => addr.to_string(radix=16)).join(","),
        ]
      })
      assert_eq(summary, [
        "init", "raw", "d200", "0", "valid", "true", "d203", "3", "d202,d201",
      ])
      // a stop predicate hands every matching instruction to `hit`, which
      // continues with `step` and ends with `stop`
      let visited = disasm.run(
        memory,
        stop_on=[@project.ProjectDisassemblyBasicPred::valid()],
        init=[],
        return_=addrs => addrs,
        hit=(state, mem, insn, addrs) => {
          // the instruction is the only one decoded by this step
          if insn.addr() == mem.min_addr() && state.insns().length() == 1 {
            addrs.push(mem.min_addr())
          }
          if addrs.length() == 2 {
            state.stop(addrs)
          } else {
            state.step(addrs)
          }
        },
      )
      assert_eq(visited, [0xd200UL, 0xd201UL])
      // `jump` restarts at another memory, `back` returns to the position
      // kept in the history
      let jumped = disasm.run(
        memory,
        backlog=1,
        stop_on=[@project.ProjectDisassemblyBasicPred::valid()],
        init=[],
        return_=addrs => addrs,
        hit=(state, mem, _, addrs) => {
          addrs.push(mem.min_addr())
          match addrs.length() {
            1 =>
              match memory.view(from=0xd202UL) {
                Ok(rest) => state.jump(rest, addrs)
                Err(_) => state.stop(addrs)
              }
            2 => state.back(addrs)
            _ => state.stop(addrs)
          }
        },
      )
      assert_eq(jumped, [0xd200UL, 0xd202UL, 0xd202UL])
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly basic reports invalid instructions" {
  guard @project.ProjectDisassemblyBasic::create("x86_64", backend="llvm")
    is Ok(disasm) else {
    fail("no x86_64 disassembler")
  }
  // 0x06 (PUSH ES) is invalid in 64-bit mode
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xd300UL,
    b"\x90\x06\x90",
  )
  guard memory.view(from=0xd301UL) is Ok(invalid) &&
    disasm.insn_of_mem(invalid) is Ok(result) else {
    fail("insn_of_mem failed")
  }
  assert_true(result.instruction() is None)
  assert_eq(result.memory().length(), 1)
  assert_true(
    result.remainder().memory().map(m => m.min_addr()) == Some(0xd302UL),
  )
  // without an `invalid` callback the invalid instruction is skipped
  let insns = disasm.run(memory, init=(), return_=_ => [], stopped=(s, _) => {
    s.insns()
  })
  assert_eq(insns.map(item => item.1.map(insn => insn.name())), [
    Some("NOOP"),
    None,
    Some("NOOP"),
  ])
  // with one, it decides how to continue
  let invalid_at = disasm.run(memory, init=0UL, return_=addr => addr, invalid=(
    state,
    mem,
    _,
  ) => state.stop(mem.min_addr()))
  assert_eq(invalid_at, 0xd301UL)
}

///|
test "project disassembly basic lookup custom and with_disasm wrappers" {
  // the built-in llvm backend provides the x86 and ARM encodings
  match
    @project.ProjectDisassemblyBasic::lookup(
      @core_theory.Target::x86_64(),
      @core_theory.Language::llvm_x86_64(),
    ) {
    Ok(disasm) => {
      assert_true(disasm.backend() == "llvm")
      assert_true(disasm.encoding() == "llvm-x86_64")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.ProjectDisassemblyBasic::registered_encodings().contains(
      @core_theory.Language::llvm_a32().to_string(),
    ),
  )
  // there is no disassembler for an unknown encoding until one is registered
  let language = @core_theory.Language::of_string("basic-test-encoding")
  assert_true(
    @project.ProjectDisassemblyBasic::lookup(
      @core_theory.Target::unknown(),
      language,
    )
    is Err(_),
  )
  assert_true(
    @project.ProjectDisassemblyBasic::register(language, target => {
      Ok(
        @project.ProjectDisassemblyBasic::custom(
          target,
          language,
          backend="raw",
        ),
      )
    })
    is Ok(_),
  )
  assert_true(
    @project.ProjectDisassemblyBasic::register(language, _ => Err("again"))
    is Err(_),
  )
  match
    @project.ProjectDisassemblyBasic::lookup(
      @core_theory.Target::unknown(),
      language,
    ) {
    Ok(disasm) => {
      assert_true(disasm.backend() == "raw")
      assert_true(disasm.triple().contains("unknown"))
    }
    Err(reason) => fail(reason)
  }
  let custom = @project.ProjectDisassemblyBasic::custom(
    @core_theory.Target::unknown(),
    @core_theory.Language::unknown(),
    backend="custom-backend",
  )
  assert_true(custom.backend() == "custom-backend")
  match
    @project.ProjectDisassemblyBasic::with_disasm("unit", backend="raw", disasm => {
      Ok(disasm.backend() + ":" + disasm.triple())
    }) {
    Ok(text) => assert_true(text == "raw:unit")
    Err(reason) => fail(reason)
  }
  // the llvm backend rejects the targets it cannot decode
  assert_true(
    @project.ProjectDisassemblyBasic::create("mips", backend="llvm") is Err(_),
  )
}
