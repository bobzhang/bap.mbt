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
