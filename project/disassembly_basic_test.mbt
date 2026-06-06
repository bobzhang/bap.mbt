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
test "translated BAP basic disassembly decodes x86_64 llvm samples" {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86_64", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
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

  let sequence = b"\x48\x83\xec\x08" +
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
  assert_true(insns.map(item => item.0.length()) == [4, 5, 3, 4, 1])
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
