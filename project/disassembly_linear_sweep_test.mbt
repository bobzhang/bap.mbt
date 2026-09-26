///|
test "project disassembly linear sweep with the raw backend emits byte-granular instructions" {
  assert_true(
    @project.ProjectDisassemblyLinearSweep::create(backend="llvm").backend() ==
    "llvm",
  )
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xc000UL,
    b"\x90\xc3",
  )
  match
    @project.ProjectDisassemblyLinearSweep::sweep(
      @core_theory.Target::unknown(),
      memory,
      backend="raw",
    ) {
    Ok(items) => {
      assert_true(items.length() == 2)
      assert_true(items[0].0.min_addr() == 0xc000UL)
      assert_true(items[0].0.length() == 1)
      match items[0].1 {
        Some(instruction) => {
          assert_true(instruction.addr() == 0xc000UL)
          assert_true(instruction.code() == 0x90)
          assert_true(instruction.name() == ".byte")
          assert_true(instruction.encoding() == "raw")
          assert_true(instruction.assembly() == ".byte 0x90")
          assert_true(instruction.bil() == "unknown 0xc000")
          assert_true(instruction.operands().length() == 1)
          assert_true(instruction.operands()[0].to_int64() == Some(0x90L))
        }
        None => fail("missing first instruction")
      }
      match items[1].1 {
        Some(instruction) => {
          assert_true(instruction.addr() == 0xc001UL)
          assert_true(instruction.code() == 0xc3)
          assert_true(instruction.assembly() == ".byte 0xc3")
        }
        None => fail("missing second instruction")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly linear sweep supports empty memory and exn wrapper" {
  let empty = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xc100UL,
    b"",
  )
  match
    @project.ProjectDisassemblyLinearSweep::sweep(
      @core_theory.Target::x86_64(),
      empty,
      backend="llvm",
    ) {
    Ok(items) => assert_true(items.is_empty())
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xc110UL,
    b"\x01",
  )
  let items = @project.ProjectDisassemblyLinearSweep::sweep_exn(
    @core_theory.Target::unknown(),
    memory,
    backend="raw",
  )
  assert_true(items.length() == 1)
  match items[0].1 {
    Some(instruction) => assert_true(instruction.code() == 1)
    None => fail("missing exn-wrapper instruction")
  }
}

///|
test "project linear sweep wrapper uses project target" {
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xc200UL,
    b"\xff",
  )
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.linear_sweep(memory, backend="raw") {
    Ok(items) => {
      assert_true(items.length() == 1)
      match items[0].1 {
        Some(instruction) => {
          assert_true(instruction.addr() == 0xc200UL)
          assert_true(instruction.code() == 0xff)
        }
        None => fail("missing project wrapper instruction")
      }
    }
    Err(reason) => fail(reason)
  }
  let checked = project.linear_sweep_exn(memory, backend="raw")
  assert_true(checked.length() == 1)
}

///|
test "project linear sweep lists the invalid instructions of the llvm backend" {
  // push rbp; (bad); ret
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0xc300UL,
    b"\x55\x06\xc3",
  )
  let items = @project.ProjectDisassemblyLinearSweep::sweep_exn(
    @core_theory.Target::x86_64(),
    memory,
  )
  inspect(
    items
    .map(item => {
      let name = match item.1 {
        Some(insn) => insn.name()
        None => "invalid"
      }
      "\{item.0.min_addr().to_string(radix=16)}:\{name}"
    })
    .join(" "),
    content=(
      #|c300:PUSH64r c301:invalid c302:RET
    ),
  )
  // an encoding without a disassembler is an error
  assert_true(
    @project.ProjectDisassemblyLinearSweep::sweep(
      @core_theory.Target::unknown(),
      memory,
    )
    is Err(_),
  )
}
