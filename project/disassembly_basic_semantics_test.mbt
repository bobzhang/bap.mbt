///|
fn semantic_word128(hex : String) -> @types.Word raise {
  @types.Word::from_string("0x" + hex + ":128u")
}

///|
fn semantic_word32(value : UInt64) -> @types.Word raise {
  @types.Word::of_uint64(width=32, value)
}

///|
fn semantic_decode_x86(
  bytes : Bytes,
) -> @project.ProjectDisassemblyInstruction raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6000UL,
    bytes,
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) =>
      match result.instruction() {
        Some(instruction) => instruction
        None => fail("missing decoded instruction")
      }
    Err(reason) => fail(reason)
  }
}

///|
fn semantic_decode_x86_state(
  bytes : Bytes,
  start~ : UInt64,
) -> @project.ProjectDisassemblyState raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  let basic_state = disasm.run(memory)
  let instructions : Array[@project.ProjectDisassemblyInstruction] = []
  for item in basic_state.insns() {
    match item.1 {
      Some(instruction) => instructions.push(instruction)
      None => ()
    }
  }
  @project.ProjectDisassemblyState::create(blocks=[memory], instructions~)
}

///|
fn semantic_xmm_state(
  xmm0 : @types.Word,
  xmm1 : @types.Word,
) -> @project.ProjectX86SimdState {
  @project.ProjectX86SimdState::create(registers=[
    ("xmm0", xmm0),
    ("xmm1", xmm1),
  ])
}

///|
fn assert_x86_simd_result(
  label : String,
  bytes : Bytes,
  state : @project.ProjectX86SimdState,
  register : String,
  expected : @types.Word,
) -> Unit raise {
  let instruction = semantic_decode_x86(bytes)
  match instruction.apply_x86_simd(state) {
    Ok(next) => assert_true(next.get_register(register) == Some(expected))
    Err(reason) => fail(label + ": " + reason)
  }
}

///|
test "project Basic x86 SIMD semantics execute packed compare fixtures" {
  let ascending = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let endpoints = semantic_word128("0f000000000000000000000000000000")
  assert_x86_simd_result(
    "pcmpeqb",
    b"\x66\x0f\x74\xc8",
    semantic_xmm_state(ascending, endpoints),
    "xmm1",
    semantic_word128("ff0000000000000000000000000000ff"),
  )
  assert_x86_simd_result(
    "pcmpgtb",
    b"\x66\x0f\x64\xc8",
    semantic_xmm_state(endpoints, ascending),
    "xmm1",
    semantic_word128("00ffffffffffffffffffffffffffff00"),
  )
}

///|
test "project Basic x86 SIMD semantics execute packed min max fixtures" {
  let bytes_source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let bytes_dest = semantic_word128("ff0000000000000000000000000000ff")
  assert_x86_simd_result(
    "pminub",
    b"\x66\x0f\xda\xc8",
    semantic_xmm_state(bytes_source, bytes_dest),
    "xmm1",
    semantic_word128("0f000000000000000000000000000000"),
  )
  assert_x86_simd_result(
    "pminsb",
    b"\x66\x0f\x38\x38\xc8",
    semantic_xmm_state(bytes_source, bytes_dest),
    "xmm1",
    bytes_dest,
  )
  assert_x86_simd_result(
    "pmaxub",
    b"\x66\x0f\xde\xc8",
    semantic_xmm_state(bytes_source, bytes_dest),
    "xmm1",
    semantic_word128("ff0e0d0c0b0a090807060504030201ff"),
  )
  assert_x86_simd_result(
    "pmaxsb",
    b"\x66\x0f\x38\x3c\xc8",
    semantic_xmm_state(bytes_source, bytes_dest),
    "xmm1",
    bytes_source,
  )

  let word_source = semantic_word128("8f0e00000b0a09080506050403040100")
  let word_dest = semantic_word128("0f000d0c000000000706050503020000")
  let samples : Array[(String, Bytes, @types.Word)] = [
    (
      "pmaxuw",
      b"\x66\x0f\x38\x3e\xc8",
      semantic_word128("8f0e0d0c0b0a09080706050503040100"),
    ),
    (
      "pmaxsw",
      b"\x66\x0f\xee\xc8",
      semantic_word128("0f000d0c0b0a09080706050503040100"),
    ),
    (
      "pminuw",
      b"\x66\x0f\x38\x3a\xc8",
      semantic_word128("0f000000000000000506050403020000"),
    ),
    (
      "pminsw",
      b"\x66\x0f\xea\xc8",
      semantic_word128("8f0e0000000000000506050403020000"),
    ),
    (
      "pminud",
      b"\x66\x0f\x38\x3b\xc8",
      semantic_word128("0f000d0c000000000506050403020000"),
    ),
    (
      "pminsd",
      b"\x66\x0f\x38\x39\xc8",
      semantic_word128("8f0e0000000000000506050403020000"),
    ),
    (
      "pmaxud",
      b"\x66\x0f\x38\x3f\xc8",
      semantic_word128("8f0e00000b0a09080706050503040100"),
    ),
    (
      "pmaxsd",
      b"\x66\x0f\x38\x3d\xc8",
      semantic_word128("0f000d0c0b0a09080706050503040100"),
    ),
  ]
  for sample in samples {
    assert_x86_simd_result(
      sample.0,
      sample.1,
      semantic_xmm_state(word_source, word_dest),
      "xmm1",
      sample.2,
    )
  }
}

///|
test "project Basic x86 SIMD semantics execute packed bit fixtures" {
  let source = semantic_word128("0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f")
  let dest = semantic_word128("00ff00ff00ff00ff00ff00ff00ff00ff")
  assert_x86_simd_result(
    "pand",
    b"\x66\x0f\xdb\xc8",
    semantic_xmm_state(source, dest),
    "xmm1",
    semantic_word128("000f000f000f000f000f000f000f000f"),
  )
  assert_x86_simd_result(
    "pandn",
    b"\x66\x0f\xdf\xc8",
    semantic_xmm_state(source, dest),
    "xmm1",
    semantic_word128("0f000f000f000f000f000f000f000f00"),
  )
  assert_x86_simd_result(
    "por",
    b"\x66\x0f\xeb\xc8",
    semantic_xmm_state(source, dest),
    "xmm1",
    semantic_word128("0fff0fff0fff0fff0fff0fff0fff0fff"),
  )
  assert_x86_simd_result(
    "pxor",
    b"\x66\x0f\xef\xc8",
    semantic_xmm_state(source, dest),
    "xmm1",
    semantic_word128("0ff00ff00ff00ff00ff00ff00ff00ff0"),
  )
}

///|
test "project Basic x86 SIMD semantics execute pmovmskb fixtures" {
  let source = semantic_word128("807f8001800080807f7f000000008080")
  let instruction = semantic_decode_x86(b"\x66\x0f\xd7\xc8")
  let state = @project.ProjectX86SimdState::create(registers=[("xmm0", source)])
  match instruction.apply_x86_simd(state) {
    Ok(next) =>
      assert_true(next.get_register("ecx") == Some(semantic_word32(0xab03UL)))
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic x86 SIMD semantics execute packed average fixtures" {
  assert_x86_simd_result(
    "pavgb",
    b"\x66\x0f\xe0\xc8",
    semantic_xmm_state(
      semantic_word128("01010101010101010101010101010101"),
      semantic_word128("ff00ff00ff00ff00ff00ff00ff00ff00"),
    ),
    "xmm1",
    semantic_word128("80018001800180018001800180018001"),
  )
  assert_x86_simd_result(
    "pavgw",
    b"\x66\x0f\xe3\xc8",
    semantic_xmm_state(
      semantic_word128("00010001000100010001000100010001"),
      semantic_word128("ffff0000ffff0000ffff0000ffff0000"),
    ),
    "xmm1",
    semantic_word128("80000001800000018000000180000001"),
  )
}

///|
test "project Basic x86 SIMD semantics execute packed add subtract fixtures" {
  let ones8 = semantic_word128("01010101010101010101010101010101")
  let ones16 = semantic_word128("00010001000100010001000100010001")
  let ones32 = semantic_word128("00000001000000010000000100000001")
  let ones64 = semantic_word128("00000000000000010000000000000001")
  let zero = semantic_word128("00000000000000000000000000000000")
  let ones = semantic_word128("ffffffffffffffffffffffffffffffff")
  let samples : Array[(String, Bytes, @types.Word, @types.Word, @types.Word)] = [
    ("psubb", b"\x66\x0f\xf8\xc8", ones8, zero, ones),
    ("psubw", b"\x66\x0f\xf9\xc8", ones16, zero, ones),
    ("psubd", b"\x66\x0f\xfa\xc8", ones32, zero, ones),
    ("psubq", b"\x66\x0f\xfb\xc8", ones64, zero, ones),
    ("paddb", b"\x66\x0f\xfc\xc8", ones8, ones, zero),
    ("paddw", b"\x66\x0f\xfd\xc8", ones16, ones, zero),
    ("paddd", b"\x66\x0f\xfe\xc8", ones32, ones, zero),
    ("paddq", b"\x66\x0f\xd4\xc8", ones64, ones, zero),
  ]
  for sample in samples {
    assert_x86_simd_result(
      sample.0,
      sample.1,
      semantic_xmm_state(sample.2, sample.3),
      "xmm1",
      sample.4,
    )
  }
}

///|
test "project Basic x86 SIMD semantics execute pshufb register fixtures" {
  let origin = semantic_word128("504f4e4d4c4b4a494847464544434241")
  let samples : Array[(String, @types.Word, @types.Word)] = [
    ("identity", semantic_word128("0f0e0d0c0b0a09080706050403020100"), origin),
    (
      "last three byte one",
      semantic_word128("0f0e0d0c0b0a09080706050403010101"),
      semantic_word128("504f4e4d4c4b4a494847464544424242"),
    ),
    (
      "first three byte one",
      semantic_word128("0101010c0b0a09080706050403020100"),
      semantic_word128("4242424d4c4b4a494847464544434241"),
    ),
    (
      "last three zero",
      semantic_word128("0f0e0d0c0b0a09080706050403808080"),
      semantic_word128("504f4e4d4c4b4a494847464544000000"),
    ),
  ]
  for sample in samples {
    assert_x86_simd_result(
      "pshufb " + sample.0,
      b"\x66\x0f\x38\x00\xc1",
      semantic_xmm_state(origin, sample.1),
      "xmm0",
      sample.2,
    )
  }
}

///|
test "project Basic x86 SIMD semantics checks pshufb memory alignment" {
  let origin = semantic_word128("504f4e4d4c4b4a494847464544434241")
  let mask = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let instruction = semantic_decode_x86(b"\x66\x0f\x38\x00\x00")
  let aligned = 0x42424220UL
  let aligned_state = @project.ProjectX86SimdState::create(
    registers=[("xmm0", origin), ("eax", semantic_word32(aligned))],
    vector_memory=[(aligned, mask)],
  )
  match instruction.apply_x86_simd(aligned_state) {
    Ok(next) => assert_true(next.get_register("XMM0") == Some(origin))
    Err(reason) => fail(reason)
  }

  let unaligned = 0x42424242UL
  let unaligned_state = @project.ProjectX86SimdState::create(registers=[
    ("xmm0", origin),
    ("eax", semantic_word32(unaligned)),
  ])
  match instruction.apply_x86_simd(unaligned_state) {
    Err(reason) => assert_true(reason.contains("not 16-byte aligned"))
    Ok(_) => fail("unaligned pshufb memory operand succeeded")
  }
}

///|
test "project Basic x86 SIMD semantics runs decoded instruction streams" {
  let source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let dest = semantic_word128("ff0000000000000000000000000000ff")
  let bytes = b"\x66\x0f\xda\xc8" + b"\x66\x0f\xde\xc8"
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6100UL,
    bytes,
  )
  let basic_state = disasm.run(memory)
  assert_true(basic_state.insns().length() == 2)
  assert_true(basic_state.insns().map(item => item.0.length()) == [4, 4])
  match basic_state.apply_x86_simd(semantic_xmm_state(source, dest)) {
    Ok(next) => assert_true(next.get_register("xmm1") == Some(source))
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic x86 SIMD stream errors include instruction address" {
  let source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let dest = semantic_word128("ff0000000000000000000000000000ff")
  let disasm = match
    @project.ProjectDisassemblyBasic::create("x86", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6200UL,
    b"\x66\x0f\xda\xc8\xeb\xfe",
  )
  let basic_state = disasm.run(memory)
  assert_true(basic_state.insns().length() == 2)
  match basic_state.apply_x86_simd(semantic_xmm_state(source, dest)) {
    Err(reason) => {
      assert_true(reason.contains("JMP_1"))
      assert_true(reason.contains("0x6204"))
    }
    Ok(_) => fail("unsupported instruction stream succeeded")
  }
}

///|
test "project disassembly state applies decoded x86 SIMD semantics" {
  let source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let dest = semantic_word128("ff0000000000000000000000000000ff")
  let disassembly = semantic_decode_x86_state(
    b"\x66\x0f\xda\xc8" + b"\x66\x0f\xde\xc8",
    start=0x6300UL,
  )
  assert_true(disassembly.instruction_count() == 2)
  match disassembly.apply_x86_simd(semantic_xmm_state(source, dest)) {
    Ok(next) => assert_true(next.get_register("xmm1") == Some(source))
    Err(reason) => fail(reason)
  }
}

///|
test "project facade applies decoded x86 SIMD semantics" {
  let source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let dest = semantic_word128("ff0000000000000000000000000000ff")
  let disassembly = semantic_decode_x86_state(
    b"\x66\x0f\xda\xc8" + b"\x66\x0f\xde\xc8",
    start=0x6400UL,
  )
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    disassembly,
  )
  match project.apply_x86_simd(semantic_xmm_state(source, dest)) {
    Ok(next) => assert_true(next.get_register("xmm1") == Some(source))
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly x86 SIMD facade keeps stream error context" {
  let source = semantic_word128("0f0e0d0c0b0a09080706050403020100")
  let dest = semantic_word128("ff0000000000000000000000000000ff")
  let disassembly = semantic_decode_x86_state(
    b"\x66\x0f\xda\xc8\xeb\xfe",
    start=0x6500UL,
  )
  match disassembly.apply_x86_simd(semantic_xmm_state(source, dest)) {
    Err(reason) => {
      assert_true(reason.contains("JMP_1"))
      assert_true(reason.contains("0x6504"))
    }
    Ok(_) => fail("unsupported project disassembly stream succeeded")
  }
}
