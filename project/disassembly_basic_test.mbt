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
    Err(reason) =>
      assert_true(reason == "unknown project disassembly basic backend missing")
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
      ["RET"],
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
  let state = disasm.store_kinds().run(run_memory)
  let insns = state.insns()
  assert_true(insns.length() == samples.length())
  assert_true(insns.map(item => item.0.length()) == [1, 4, 5, 10, 5, 3, 4, 1])
  assert_true(state.addr() == 0xe100UL + sequence.length().to_uint64())
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
test "translated BAP basic disassembly decodes x86 register add-sub immediates" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\x83\xe8\x01", 4, ["SUB64ri8", "RAX", "RAX", "0x1"]),
    ("x86_64", b"\x49\x83\xc0\x7f", 4, ["ADD64ri8", "R8", "R8", "0x7f"]),
    ("x86_64", b"\x48\x83\xc0\xff", 4, ["ADD64ri8", "RAX", "RAX", "-0x1"]),
    ("x86_64", b"\x41\x83\xc0\x01", 4, ["ADD32ri8", "R8D", "R8D", "0x1"]),
    ("x86_64", b"\x41\x80\xc0\xff", 4, ["ADD8ri8", "R8B", "R8B", "0xff"]),
    ("x86", b"\x83\xe8\x01", 3, ["SUB32ri8", "EAX", "EAX", "0x1"]),
    ("x86", b"\x83\xc0\x7f", 3, ["ADD32ri8", "EAX", "EAX", "0x7f"]),
    ("x86", b"\x80\xe8\x80", 3, ["SUB8ri8", "AL", "AL", "0x80"]),
    ("x86", b"\x04\xff", 2, ["ADD8ri8", "AL", "AL", "0xff"]),
    (
      "x86_64",
      b"\x48\x81\xc0\x78\x56\x34\x12",
      7,
      ["ADD64ri32", "RAX", "RAX", "0x12345678"],
    ),
    (
      "x86_64",
      b"\x48\x05\x78\x56\x34\x12",
      6,
      ["ADD64ri32", "RAX", "RAX", "0x12345678"],
    ),
    (
      "x86_64",
      b"\x49\x81\xe8\xff\xff\xff\xff",
      7,
      ["SUB64ri32", "R8", "R8", "-0x1"],
    ),
    ("x86", b"\x2d\xff\xff\xff\xff", 5, ["SUB32ri32", "EAX", "EAX", "-0x1"]),
    (
      "x86",
      b"\x81\xe9\x00\x00\x00\x80",
      6,
      ["SUB32ri32", "ECX", "ECX", "-0x80000000"],
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
      start=0xe200UL,
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
          None => fail("missing x86 add-sub instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register logical immediates" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\x83\xc8\x0f", 4, ["OR64ri8", "RAX", "RAX", "0xf"]),
    ("x86_64", b"\x49\x83\xe0\x7f", 4, ["AND64ri8", "R8", "R8", "0x7f"]),
    ("x86_64", b"\x49\x83\xf0\x01", 4, ["XOR64ri8", "R8", "R8", "0x1"]),
    ("x86_64", b"\x41\x83\xc8\x01", 4, ["OR32ri8", "R8D", "R8D", "0x1"]),
    ("x86_64", b"\x41\x80\xf0\x01", 4, ["XOR8ri8", "R8B", "R8B", "0x1"]),
    ("x86", b"\x83\xc8\x0f", 3, ["OR32ri8", "EAX", "EAX", "0xf"]),
    ("x86", b"\x83\xe1\x7f", 3, ["AND32ri8", "ECX", "ECX", "0x7f"]),
    ("x86", b"\x83\xf2\xff", 3, ["XOR32ri8", "EDX", "EDX", "-0x1"]),
    ("x86", b"\x80\xc8\x0f", 3, ["OR8ri8", "AL", "AL", "0xf"]),
    ("x86", b"\x80\xe1\x7f", 3, ["AND8ri8", "CL", "CL", "0x7f"]),
    ("x86", b"\x34\x80", 2, ["XOR8ri8", "AL", "AL", "0x80"]),
    (
      "x86_64",
      b"\x48\x81\xc8\x78\x56\x34\x12",
      7,
      ["OR64ri32", "RAX", "RAX", "0x12345678"],
    ),
    (
      "x86_64",
      b"\x48\x0d\x78\x56\x34\x12",
      6,
      ["OR64ri32", "RAX", "RAX", "0x12345678"],
    ),
    ("x86", b"\x81\xe1\xff\x00\x00\x00", 6, ["AND32ri32", "ECX", "ECX", "0xff"]),
    ("x86", b"\x25\xff\x00\x00\x00", 5, ["AND32ri32", "EAX", "EAX", "0xff"]),
    (
      "x86_64",
      b"\x49\x81\xf0\x00\x01\x00\x00",
      7,
      ["XOR64ri32", "R8", "R8", "0x100"],
    ),
    (
      "x86_64",
      b"\x48\x35\x00\x01\x00\x00",
      6,
      ["XOR64ri32", "RAX", "RAX", "0x100"],
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
      start=0xe260UL,
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
          None => fail("missing x86 logical immediate instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 cmp and test fixtures" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\x83\xf8\x01", 4, ["CMP64ri8", "RAX", "0x1"]),
    ("x86_64", b"\x49\x83\xf8\xff", 4, ["CMP64ri8", "R8", "-0x1"]),
    ("x86_64", b"\x41\x80\xf8\xff", 4, ["CMP8ri8", "R8B", "0xff"]),
    ("x86", b"\x83\xf9\x00", 3, ["CMP32ri8", "ECX", "0x0"]),
    ("x86", b"\x80\xf8\x80", 3, ["CMP8ri8", "AL", "0x80"]),
    ("x86", b"\x3c\xff", 2, ["CMP8ri8", "AL", "0xff"]),
    (
      "x86_64",
      b"\x48\x81\xf8\x78\x56\x34\x12",
      7,
      ["CMP64ri32", "RAX", "0x12345678"],
    ),
    (
      "x86_64",
      b"\x48\x3d\x78\x56\x34\x12",
      6,
      ["CMP64ri32", "RAX", "0x12345678"],
    ),
    ("x86", b"\x81\xf9\xff\xff\xff\xff", 6, ["CMP32ri32", "ECX", "-0x1"]),
    ("x86", b"\x3d\xff\xff\xff\xff", 5, ["CMP32ri32", "EAX", "-0x1"]),
    ("x86_64", b"\x48\x39\xd8", 3, ["CMP64rr", "RAX", "RBX"]),
    ("x86_64", b"\x48\x3b\xc8", 3, ["CMP64rr_REV", "RCX", "RAX"]),
    ("x86", b"\x39\xd8", 2, ["CMP32rr", "EAX", "EBX"]),
    ("x86_64", b"\x44\x38\xc0", 3, ["CMP8rr", "AL", "R8B"]),
    ("x86", b"\x38\xe0", 2, ["CMP8rr", "AL", "AH"]),
    ("x86", b"\x3a\xc8", 2, ["CMP8rr_REV", "CL", "AL"]),
    ("x86_64", b"\x48\x85\xc0", 3, ["TEST64rr", "RAX", "RAX"]),
    ("x86_64", b"\x4d\x85\xc8", 3, ["TEST64rr", "R8", "R9"]),
    ("x86_64", b"\x44\x84\xc0", 3, ["TEST8rr", "AL", "R8B"]),
    ("x86", b"\x85\xc0", 2, ["TEST32rr", "EAX", "EAX"]),
    ("x86", b"\x84\xe0", 2, ["TEST8rr", "AL", "AH"]),
    (
      "x86_64",
      b"\x48\xa9\x78\x56\x34\x12",
      6,
      ["TEST64ri32", "RAX", "0x12345678"],
    ),
    ("x86_64", b"\xa8\x80", 2, ["TEST8ri8", "AL", "0x80"]),
    ("x86", b"\xa9\xff\x00\x00\x00", 5, ["TEST32ri32", "EAX", "0xff"]),
    ("x86", b"\xa8\xff", 2, ["TEST8ri8", "AL", "0xff"]),
    ("x86_64", b"\x49\xf7\xc0\xff\xff\xff\xff", 7, ["TEST64ri32", "R8", "-0x1"]),
    ("x86_64", b"\x41\xf6\xc0\xff", 4, ["TEST8ri8", "R8B", "0xff"]),
    (
      "x86",
      b"\xf7\xc1\x00\x00\x00\x80",
      6,
      ["TEST32ri32", "ECX", "-0x80000000"],
    ),
    ("x86", b"\xf6\xc4\x80", 3, ["TEST8ri8", "AH", "0x80"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe280UL,
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
          None => fail("missing x86 cmp/test instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register inc-dec fixtures" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\xff\xc0", 3, ["INC64r", "RAX"]),
    ("x86_64", b"\x49\xff\xc0", 3, ["INC64r", "R8"]),
    ("x86_64", b"\x48\xff\xc8", 3, ["DEC64r", "RAX"]),
    ("x86_64", b"\x41\xff\xc8", 3, ["DEC32r", "R8D"]),
    ("x86", b"\x40", 1, ["INC32r", "EAX"]),
    ("x86", b"\x49", 1, ["DEC32r", "ECX"]),
    ("x86", b"\xff\xc0", 2, ["INC32r", "EAX"]),
    ("x86", b"\xff\xc9", 2, ["DEC32r", "ECX"]),
    ("x86", b"\xfe\xc0", 2, ["INC8r", "AL"]),
    ("x86", b"\xfe\xc9", 2, ["DEC8r", "CL"]),
    ("x86", b"\xfe\xc4", 2, ["INC8r", "AH"]),
    ("x86_64", b"\x41\xfe\xc0", 3, ["INC8r", "R8B"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe290UL,
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
          None => fail("missing x86 inc-dec instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register not-neg fixtures" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\xf7\xd0", 3, ["NOT64r", "RAX"]),
    ("x86_64", b"\x49\xf7\xd0", 3, ["NOT64r", "R8"]),
    ("x86_64", b"\x48\xf7\xd8", 3, ["NEG64r", "RAX"]),
    ("x86_64", b"\x41\xf7\xd8", 3, ["NEG32r", "R8D"]),
    ("x86", b"\xf7\xd0", 2, ["NOT32r", "EAX"]),
    ("x86", b"\xf7\xd9", 2, ["NEG32r", "ECX"]),
    ("x86", b"\xf6\xd0", 2, ["NOT8r", "AL"]),
    ("x86", b"\xf6\xdc", 2, ["NEG8r", "AH"]),
    ("x86_64", b"\x41\xf6\xd8", 3, ["NEG8r", "R8B"]),
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
            assert_true(instruction.kinds().is_empty())
          }
          None => fail("missing x86 not-neg instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register add-sub rr fixtures" {
  let samples : Array[(String, Bytes, Int, Array[String])] = [
    ("x86_64", b"\x48\x01\xd8", 3, ["ADD64rr", "RAX", "RBX"]),
    ("x86_64", b"\x4d\x01\xc8", 3, ["ADD64rr", "R8", "R9"]),
    ("x86_64", b"\x48\x03\xc8", 3, ["ADD64rr_REV", "RCX", "RAX"]),
    ("x86_64", b"\x48\x29\xd8", 3, ["SUB64rr", "RAX", "RBX"]),
    ("x86_64", b"\x48\x2b\xc8", 3, ["SUB64rr_REV", "RCX", "RAX"]),
    ("x86_64", b"\x45\x29\xc8", 3, ["SUB32rr", "R8D", "R9D"]),
    ("x86_64", b"\x44\x00\xc0", 3, ["ADD8rr", "AL", "R8B"]),
    ("x86_64", b"\x45\x28\xc8", 3, ["SUB8rr", "R8B", "R9B"]),
    ("x86", b"\x01\xd8", 2, ["ADD32rr", "EAX", "EBX"]),
    ("x86", b"\x2b\xc8", 2, ["SUB32rr_REV", "ECX", "EAX"]),
    ("x86", b"\x00\xd8", 2, ["ADD8rr", "AL", "BL"]),
    ("x86", b"\x2a\xc8", 2, ["SUB8rr_REV", "CL", "AL"]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe280UL,
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
          None => fail("missing x86 add-sub rr instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register logical fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x48\x31\xc0", 3, ["XOR64rr", "RAX", "RAX"], []),
    ("x86_64", b"\x4d\x31\xc8", 3, ["XOR64rr", "R8", "R9"], []),
    ("x86_64", b"\x48\x33\xc8", 3, ["XOR64rr_REV", "RCX", "RAX"], []),
    ("x86_64", b"\x48\x09\xd8", 3, ["OR64rr", "RAX", "RBX"], []),
    ("x86_64", b"\x48\x23\xc8", 3, ["AND64rr_REV", "RCX", "RAX"], []),
    ("x86_64", b"\x44\x08\xc0", 3, ["OR8rr", "AL", "R8B"], []),
    ("x86_64", b"\x45\x30\xc8", 3, ["XOR8rr", "R8B", "R9B"], []),
    ("x86", b"\x31\xc0", 2, ["XOR32rr", "EAX", "EAX"], []),
    ("x86", b"\x09\xd8", 2, ["OR32rr", "EAX", "EBX"], []),
    ("x86", b"\x23\xc8", 2, ["AND32rr_REV", "ECX", "EAX"], []),
    ("x86", b"\x08\xd8", 2, ["OR8rr", "AL", "BL"], []),
    ("x86", b"\x20\xe0", 2, ["AND8rr", "AL", "AH"], []),
    ("x86", b"\x32\xc8", 2, ["XOR8rr_REV", "CL", "AL"], []),
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
          None => fail("missing x86 logical instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register push fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x55", 1, ["PUSH64r", "RBP"], [ProjectMayStore]),
    ("x86_64", b"\x54", 1, ["PUSH64r", "RSP"], [ProjectMayStore]),
    ("x86_64", b"\x41\x50", 2, ["PUSH64r", "R8"], [ProjectMayStore]),
    ("x86", b"\x55", 1, ["PUSH32r", "EBP"], [ProjectMayStore]),
    ("x86", b"\x54", 1, ["PUSH32r", "ESP"], [ProjectMayStore]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe180UL,
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
          None => fail("missing x86 push instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 immediate push fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x6a\x01", 2, ["PUSH64i8", "0x1"], [ProjectMayStore]),
    ("x86_64", b"\x6a\xff", 2, ["PUSH64i8", "-0x1"], [ProjectMayStore]),
    (
      "x86_64",
      b"\x68\x78\x56\x34\x12",
      5,
      ["PUSH64i32", "0x12345678"],
      [ProjectMayStore],
    ),
    ("x86_64", b"\x40\x6a\x7f", 3, ["PUSH64i8", "0x7f"], [ProjectMayStore]),
    ("x86", b"\x6a\x7f", 2, ["PUSH32i8", "0x7f"], [ProjectMayStore]),
    (
      "x86",
      b"\x68\x78\x56\x34\x12",
      5,
      ["PUSH32i32", "0x12345678"],
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
      start=0xe190UL,
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
          None => fail("missing x86 immediate push instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 ModRM push fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\xff\xf0", 2, ["PUSH64r", "RAX"], [ProjectMayStore]),
    (
      "x86_64",
      b"\xff\x70\x10",
      3,
      ["PUSH64m", "RAX", "0x1", "Nil", "0x10", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    ("x86", b"\xff\xf0", 2, ["PUSH32r", "EAX"], [ProjectMayStore]),
    (
      "x86",
      b"\xff\x75\xfc",
      3,
      ["PUSH32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
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
          None => fail("missing x86 ModRM push instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 group 5 control fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\xff\xd0",
      2,
      ["CALL64r", "RAX"],
      [ProjectCall, ProjectMayAffectControlFlow],
    ),
    (
      "x86_64",
      b"\xff\x50\x10",
      3,
      ["CALL64m", "RAX", "0x1", "Nil", "0x10", "Nil"],
      [ProjectCall, ProjectMayAffectControlFlow, ProjectMayLoad],
    ),
    (
      "x86_64",
      b"\xff\xe0",
      2,
      ["JMP64r", "RAX"],
      [ProjectUnconditionalBranch, ProjectMayAffectControlFlow],
    ),
    (
      "x86_64",
      b"\xff\x60\x10",
      3,
      ["JMP64m", "RAX", "0x1", "Nil", "0x10", "Nil"],
      [ProjectUnconditionalBranch, ProjectMayAffectControlFlow, ProjectMayLoad],
    ),
    (
      "x86",
      b"\xff\xd0",
      2,
      ["CALL32r", "EAX"],
      [ProjectCall, ProjectMayAffectControlFlow],
    ),
    (
      "x86",
      b"\xff\x65\xfc",
      3,
      ["JMP32m", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectUnconditionalBranch, ProjectMayAffectControlFlow, ProjectMayLoad],
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
      start=0xe1b0UL,
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
          None => fail("missing x86 group 5 control instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 register pop fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x5d", 1, ["POP64r", "RBP"], [ProjectMayLoad]),
    ("x86_64", b"\x5c", 1, ["POP64r", "RSP"], [ProjectMayLoad]),
    ("x86_64", b"\x41\x58", 2, ["POP64r", "R8"], [ProjectMayLoad]),
    ("x86", b"\x5d", 1, ["POP32r", "EBP"], [ProjectMayLoad]),
    ("x86", b"\x5c", 1, ["POP32r", "ESP"], [ProjectMayLoad]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe190UL,
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
          None => fail("missing x86 pop instruction")
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
    ("x86_64", b"\x40\x88\xe0", 3, ["MOV8rr", "AL", "SPL"], []),
    ("x86_64", b"\x44\x8a\xc0", 3, ["MOV8rr_REV", "R8B", "AL"], []),
    ("x86", b"\x89\xe5", 2, ["MOV32rr", "EBP", "ESP"], []),
    ("x86", b"\x8b\xec", 2, ["MOV32rr_REV", "EBP", "ESP"], []),
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
test "translated BAP basic disassembly decodes x86 byte immediate mov fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86", b"\xb0\x7f", 2, ["MOV8ri", "AL", "0x7f"], []),
    ("x86", b"\xb4\x80", 2, ["MOV8ri", "AH", "0x80"], []),
    ("x86_64", b"\x40\xb4\x01", 3, ["MOV8ri", "SPL", "0x1"], []),
    ("x86_64", b"\x41\xb0\xff", 3, ["MOV8ri", "R8B", "0xff"], []),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1b0UL,
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
          None => fail("missing x86 byte immediate mov instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 xchg fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\x48\x90", 2, ["XCHG64rr", "RAX", "RAX"], []),
    ("x86_64", b"\x48\x91", 2, ["XCHG64rr", "RAX", "RCX"], []),
    ("x86_64", b"\x49\x90", 2, ["XCHG64rr", "RAX", "R8"], []),
    ("x86_64", b"\x48\x87\xd8", 3, ["XCHG64rr", "RBX", "RAX"], []),
    ("x86_64", b"\x40\x86\xe0", 3, ["XCHG8rr", "SPL", "AL"], []),
    ("x86_64", b"\x44\x86\xc0", 3, ["XCHG8rr", "R8B", "AL"], []),
    (
      "x86_64",
      b"\x48\x87\x45\xf8",
      4,
      ["XCHG64rm", "RAX", "RBP", "0x1", "Nil", "-0x8", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x44\x86\x45\xfc",
      4,
      ["XCHG8rm", "R8B", "RBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    ("x86", b"\x91", 1, ["XCHG32rr", "EAX", "ECX"], []),
    ("x86", b"\x87\xd8", 2, ["XCHG32rr", "EBX", "EAX"], []),
    ("x86", b"\x86\xe0", 2, ["XCHG8rr", "AH", "AL"], []),
    (
      "x86",
      b"\x87\x45\xfc",
      3,
      ["XCHG32rm", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [ProjectMayLoad, ProjectMayStore],
    ),
    (
      "x86",
      b"\x86\x45\xfc",
      3,
      ["XCHG8rm", "AL", "EBP", "0x1", "Nil", "-0x4", "Nil"],
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
      start=0xe1b8UL,
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
          None => fail("missing x86 xchg instruction")
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
    ("x86", b"\x0f\xb6\xc1", 3, ["MOVZX32rr8", "EAX", "CL"], []),
    ("x86", b"\x0f\xbe\xc4", 3, ["MOVSX32rr8", "EAX", "AH"], []),
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
      b"\x89\x45\xfc",
      3,
      ["MOV32mr", "EBP", "0x1", "Nil", "-0x4", "Nil", "EAX"],
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
test "translated BAP basic disassembly decodes x86 immediate mov r/m fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x49\xc7\xc0\xff\xff\xff\xff",
      7,
      ["MOV64ri32", "R8", "-0x1"],
      [],
    ),
    ("x86_64", b"\x41\xc6\xc0\xff", 4, ["MOV8ri", "R8B", "0xff"], []),
    ("x86_64", b"\x40\xc6\xc4\x01", 4, ["MOV8ri", "SPL", "0x1"], []),
    ("x86", b"\xc6\xc4\x80", 3, ["MOV8ri", "AH", "0x80"], []),
    (
      "x86_64",
      b"\x48\xc7\x45\xf8\x01\x00\x00\x00",
      8,
      ["MOV64mi", "RBP", "0x1", "Nil", "-0x8", "Nil", "0x1"],
      [ProjectMayStore],
    ),
    (
      "x86_64",
      b"\x41\xc6\x40\x01\x80",
      5,
      ["MOV8mi", "R8", "0x1", "Nil", "0x1", "Nil", "0x80"],
      [ProjectMayStore],
    ),
    ("x86", b"\xc7\xc0\xff\xff\xff\xff", 6, ["MOV32ri", "EAX", "-0x1"], []),
    (
      "x86",
      b"\xc7\x45\xfc\x78\x56\x34\x12",
      7,
      ["MOV32mi", "EBP", "0x1", "Nil", "-0x4", "Nil", "0x12345678"],
      [ProjectMayStore],
    ),
    (
      "x86",
      b"\xc6\x45\xfc\x7f",
      4,
      ["MOV8mi", "EBP", "0x1", "Nil", "-0x4", "Nil", "0x7f"],
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
          None => fail("missing x86 immediate mov r/m instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 lea fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      "x86_64",
      b"\x48\x8d\x00",
      3,
      ["LEA64r", "RAX", "RAX", "0x1", "Nil", "0x0", "Nil"],
      [],
    ),
    (
      "x86_64",
      b"\x48\x8d\x44\x88\x10",
      5,
      ["LEA64r", "RAX", "RAX", "0x4", "RCX", "0x10", "Nil"],
      [],
    ),
    (
      "x86_64",
      b"\x41\x8d\x40\x01",
      4,
      ["LEA32r", "EAX", "R8", "0x1", "Nil", "0x1", "Nil"],
      [],
    ),
    (
      "x86",
      b"\x8d\x45\xfc",
      3,
      ["LEA32r", "EAX", "EBP", "0x1", "Nil", "-0x4", "Nil"],
      [],
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
      start=0xe1d0UL,
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
          None => fail("missing x86 lea instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 leave fixtures" {
  let samples : Array[
    (String, Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    ("x86_64", b"\xc9", 1, ["LEAVE64"], [ProjectMayLoad]),
    ("x86", b"\xc9", 1, ["LEAVE"], [ProjectMayLoad]),
  ]
  for sample in samples {
    let disasm = match
      @project.ProjectDisassemblyBasic::create(sample.0, backend="llvm") {
      Ok(disasm) => disasm
      Err(reason) => fail(reason)
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe1b0UL,
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
          None => fail("missing x86 leave instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 llvm short jump fixture" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xaUL,
    b"\xeb\xfe",
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) => {
      assert_true(result.memory().length() == 2)
      assert_true(result.remainder().is_finished())
      match result.instruction() {
        Some(instruction) => {
          assert_true(
            basic_instruction_strings(instruction) == ["JMP_1", "0xa"],
          )
          assert_true(instruction.assembly() == "jmp -0x2")
          assert_true(instruction.bil() == "jmp 0xa")
          assert_true(instruction.has_kind(ProjectUnconditionalBranch))
          assert_true(instruction.has_kind(ProjectMayAffectControlFlow))
          assert_true(instruction.operands()[0].to_int64() == Some(0xaL))
        }
        None => fail("missing x86 short jump instruction")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP basic disassembly decodes x86 llvm near jump fixture" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xaUL,
    b"\xe9\x01\x00\x00\x00",
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) => {
      assert_true(result.memory().length() == 5)
      assert_true(result.remainder().is_finished())
      match result.instruction() {
        Some(instruction) => {
          assert_true(
            basic_instruction_strings(instruction) == ["JMP_4", "0x10"],
          )
          assert_true(instruction.assembly() == "jmp 0x1")
          assert_true(instruction.bil() == "jmp 0x10")
          assert_true(instruction.has_kind(ProjectUnconditionalBranch))
          assert_true(instruction.has_kind(ProjectMayAffectControlFlow))
          assert_true(instruction.operands()[0].to_int64() == Some(0x10L))
        }
        None => fail("missing x86 near jump instruction")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP basic disassembly decodes x86 conditional jump fixtures" {
  let samples : Array[
    (String, Bytes, UInt64, Int, Array[String], String, String, Int64),
  ] = [
    (
      "x86",
      b"\x75\xfe",
      0xaUL,
      2,
      ["JNE_1", "0xa"],
      "jcc -0x2",
      "if jcc then jmp 0xa",
      0xaL,
    ),
    (
      "x86",
      b"\x0f\x8f\x01\x00\x00\x00",
      0x10UL,
      6,
      ["JG_4", "0x17"],
      "jcc 0x1",
      "if jcc then jmp 0x17",
      0x17L,
    ),
    (
      "x86_64",
      b"\x74\x03",
      0x20UL,
      2,
      ["JE_1", "0x25"],
      "jcc 0x3",
      "if jcc then jmp 0x25",
      0x25L,
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
      start=sample.2,
      sample.1,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.3)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.4)
            assert_true(instruction.assembly() == sample.5)
            assert_true(instruction.bil() == sample.6)
            assert_true(instruction.has_kind(ProjectConditionalBranch))
            assert_true(instruction.has_kind(ProjectMayAffectControlFlow))
            assert_true(instruction.operands()[0].to_int64() == Some(sample.7))
          }
          None => fail("missing x86 conditional jump instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
}

///|
test "translated BAP basic disassembly decodes x86 llvm call and return fixtures" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let samples : Array[
    (Bytes, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (
      b"\xe8\x01\x00\x00\x00",
      ["CALLpcrel32", "0x1"],
      [ProjectCall, ProjectMayAffectControlFlow],
    ),
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
  for sample in samples {
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xe200UL,
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
          None => fail("missing x86 llvm control-transfer instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }

  let sequence = b"\xe8\x01\x00\x00\x00" + b"\xc3"
  let run_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xe210UL,
    sequence,
  )
  let state = disasm.store_kinds().run(run_memory)
  let insns = state.insns()
  assert_true(insns.length() == samples.length())
  assert_true(insns.map(item => item.0.length()) == [5, 1])
  assert_true(state.addr() == 0xe210UL + sequence.length().to_uint64())
  for i in 0..<samples.length() {
    match insns[i].1 {
      Some(instruction) => {
        assert_true(basic_instruction_strings(instruction) == samples[i].1)
        assert_true(instruction.kinds() == samples[i].2)
      }
      None => fail("missing x86 run instruction")
    }
  }
}

///|
test "translated BAP basic disassembly recognizes x86 SIMD fixture opcodes" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let samples : Array[
    (Bytes, Int, Array[String], Array[@project.ProjectInstructionKind]),
  ] = [
    (b"\x66\x0f\x74\xc8", 4, ["PCMPEQB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x64\xc8", 4, ["PCMPGTB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\xda\xc8", 4, ["PMINUB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x38\xc8", 5, ["PMINSB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\xde\xc8", 4, ["PMAXUB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3c\xc8", 5, ["PMAXSB", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3e\xc8", 5, ["PMAXUW", "XMM1", "XMM0"], []),
    (b"\x66\x0f\xee\xc8", 4, ["PMAXSW", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3a\xc8", 5, ["PMINUW", "XMM1", "XMM0"], []),
    (b"\x66\x0f\xea\xc8", 4, ["PMINSW", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3b\xc8", 5, ["PMINUD", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x39\xc8", 5, ["PMINSD", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3f\xc8", 5, ["PMAXUD", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x3d\xc8", 5, ["PMAXSD", "XMM1", "XMM0"], []),
    (b"\x66\x0f\x38\x00\xc1", 5, ["PSHUFB", "XMM0", "XMM1"], []),
    (b"\x66\x0f\x38\x00\x00", 5, ["PSHUFB", "XMM0", "EAX"], [ProjectMayLoad]),
  ]
  for sample in samples {
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0xf000UL,
      sample.0,
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) => {
        assert_true(result.memory().length() == sample.1)
        assert_true(result.remainder().is_finished())
        match result.instruction() {
          Some(instruction) => {
            assert_true(basic_instruction_strings(instruction) == sample.2)
            assert_true(instruction.kinds() == sample.3)
          }
          None => fail("missing x86 SIMD fixture instruction")
        }
      }
      Err(reason) => fail(reason)
    }
  }
  let sequence = samples.fold(init=b"", (bytes, sample) => bytes + sample.0)
  let run_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xf100UL,
    sequence,
  )
  let state = disasm.store_kinds().run(run_memory)
  let insns = state.insns()
  assert_true(insns.length() == samples.length())
  assert_true(state.addr() == 0xf100UL + sequence.length().to_uint64())
  for i in 0..<samples.length() {
    match insns[i].1 {
      Some(instruction) => {
        assert_true(insns[i].0.length() == samples[i].1)
        assert_true(basic_instruction_strings(instruction) == samples[i].2)
        assert_true(instruction.kinds() == samples[i].3)
      }
      None => fail("missing x86 SIMD run instruction")
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
  let state = disasm.store_kinds().run(memory)
  let insns = state.insns()
  assert_true(insns.length() == 21)
  assert_true(state.addr() == 0x840cUL + bytes.length().to_uint64())
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
      let state = disasm.run(memory)
      assert_true(state.disasm().backend() == "raw")
      assert_true(state.memory().min_addr() == 0xd200UL)
      assert_true(state.addr() == 0xd203UL)
      assert_true(state.preds().is_empty())
      assert_true(state.insns().length() == 3)
      assert_true(state.last(2).length() == 2)
      assert_true(state.last(2)[0].0.min_addr() == 0xd201UL)
      let with_preds = state.with_preds([
        @project.ProjectDisassemblyBasicPred::valid(),
      ])
      assert_true(with_preds.preds().length() == 1)
      assert_true(with_preds.preds()[0].to_string() == "valid")
      let switched = state.switch(disasm.store_asm())
      assert_true(switched.disasm().stores_asm())
      let stopped = disasm.run(memory, stop_on=[
        @project.ProjectDisassemblyBasicPred::valid(),
      ])
      assert_true(stopped.insns().length() == 1)
      assert_true(stopped.addr() == 0xd201UL)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly basic lookup custom and with_disasm wrappers" {
  match
    @project.ProjectDisassemblyBasic::lookup(
      @core_theory.Target::unknown(),
      @core_theory.Language::unknown(),
      backend="raw",
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
}
