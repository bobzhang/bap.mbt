///|
fn basic_bil_decode(
  triple : String,
  bytes : Bytes,
  start~ : UInt64,
) -> @project.ProjectDisassemblyInstruction raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create(triple, backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
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
fn basic_bil_decode_state(
  bytes : Bytes,
  start~ : UInt64,
) -> @project.ProjectDisassemblyState raise {
  basic_bil_decode_state_with_triple("x86_64", bytes, start~)
}

///|
fn basic_bil_decode_state_with_triple(
  triple : String,
  bytes : Bytes,
  start~ : UInt64,
) -> @project.ProjectDisassemblyState raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create(triple, backend="llvm") {
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
fn basic_bil_arm_strlen_bytes() -> Bytes {
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
fn basic_bil_text(stmts : Array[@types.Stmt]) -> Array[String] {
  stmts.map(stmt => stmt.to_string())
}

///|
fn assert_basic_bil_text(
  stmts : Array[@types.Stmt],
  expected : Array[String],
) -> Unit raise {
  let actual = basic_bil_text(stmts)
  if actual != expected {
    fail("expected BIL " + expected.join(" | ") + ", got " + actual.join(" | "))
  }
}

///|
fn assert_string(actual : String, expected : String) -> Unit raise {
  if actual != expected {
    fail("expected " + expected + ", got " + actual)
  }
}

///|
test "project Basic BIL lift covers x86_64 stack arithmetic fixtures" {
  let noop = basic_bil_decode("x86_64", b"\x90", start=0x6ff0UL)
  match noop.lift_basic_bil() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let sub = basic_bil_decode("x86_64", b"\x48\x83\xec\x08", start=0x7000UL)
  match sub.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RSP:imm64 := (RSP:imm64 - 8:64u)"])
    Err(reason) => fail(reason)
  }

  let add = basic_bil_decode("x86_64", b"\x48\x83\xc4\x08", start=0x7004UL)
  match add.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RSP:imm64 := (RSP:imm64 + 8:64u)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register add-sub immediates" {
  let sub64 = basic_bil_decode("x86_64", b"\x48\x83\xe8\x01", start=0x7008UL)
  match sub64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 - 1:64u)"])
    Err(reason) => fail(reason)
  }

  let add64_ext = basic_bil_decode(
    "x86_64",
    b"\x49\x83\xc0\x08",
    start=0x700cUL,
  )
  match add64_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := (R8:imm64 + 8:64u)"])
    Err(reason) => fail(reason)
  }

  let add32 = basic_bil_decode("x86", b"\x83\xc0\x01", start=0x7010UL)
  match add32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := (EAX:imm32 + 1:32u)"])
    Err(reason) => fail(reason)
  }

  let sub32_ext = basic_bil_decode(
    "x86_64",
    b"\x41\x83\xe8\x01",
    start=0x7013UL,
  )
  match sub32_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8D:imm32 := (R8D:imm32 - 1:32u)"])
    Err(reason) => fail(reason)
  }

  let add64_ri32 = basic_bil_decode(
    "x86_64",
    b"\x48\x81\xc0\x78\x56\x34\x12",
    start=0x7014UL,
  )
  match add64_ri32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 + 0x12345678:64u)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register logical immediates" {
  let or64 = basic_bil_decode("x86_64", b"\x48\x83\xc8\x0f", start=0x7016UL)
  match or64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 | 0xF:64u)"])
    Err(reason) => fail(reason)
  }

  let and64_ext = basic_bil_decode(
    "x86_64",
    b"\x49\x83\xe0\x7f",
    start=0x701aUL,
  )
  match and64_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := (R8:imm64 & 0x7F:64u)"])
    Err(reason) => fail(reason)
  }

  let xor32 = basic_bil_decode("x86", b"\x83\xf2\x01", start=0x701eUL)
  match xor32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EDX:imm32 := (EDX:imm32 ^ 1:32u)"])
    Err(reason) => fail(reason)
  }

  let or64_ri32 = basic_bil_decode(
    "x86_64",
    b"\x48\x81\xc8\x78\x56\x34\x12",
    start=0x7020UL,
  )
  match or64_ri32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 | 0x12345678:64u)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register inc-dec ops" {
  let inc64 = basic_bil_decode("x86_64", b"\x48\xff\xc0", start=0x7022UL)
  match inc64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 + 1:64u)"])
    Err(reason) => fail(reason)
  }

  let inc64_ext = basic_bil_decode("x86_64", b"\x49\xff\xc0", start=0x7025UL)
  match inc64_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := (R8:imm64 + 1:64u)"])
    Err(reason) => fail(reason)
  }

  let dec32 = basic_bil_decode("x86", b"\x49", start=0x7028UL)
  match dec32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["ECX:imm32 := (ECX:imm32 - 1:32u)"])
    Err(reason) => fail(reason)
  }

  let dec32_ext = basic_bil_decode("x86_64", b"\x41\xff\xc8", start=0x7029UL)
  match dec32_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8D:imm32 := (R8D:imm32 - 1:32u)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register not-neg ops" {
  let not64 = basic_bil_decode("x86_64", b"\x48\xf7\xd0", start=0x702cUL)
  match not64.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := (not RAX:imm64)"])
    Err(reason) => fail(reason)
  }

  let not64_ext = basic_bil_decode("x86_64", b"\x49\xf7\xd0", start=0x702fUL)
  match not64_ext.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8:imm64 := (not R8:imm64)"])
    Err(reason) => fail(reason)
  }

  let neg32 = basic_bil_decode("x86", b"\xf7\xd9", start=0x7032UL)
  match neg32.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["ECX:imm32 := (neg ECX:imm32)"])
    Err(reason) => fail(reason)
  }

  let neg32_ext = basic_bil_decode("x86_64", b"\x41\xf7\xd8", start=0x7034UL)
  match neg32_ext.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8D:imm32 := (neg R8D:imm32)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register add-sub rr ops" {
  let add64 = basic_bil_decode("x86_64", b"\x48\x01\xd8", start=0x7017UL)
  match add64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := (RAX:imm64 + RBX:imm64)"])
    Err(reason) => fail(reason)
  }

  let add64_ext = basic_bil_decode("x86_64", b"\x4d\x01\xc8", start=0x701aUL)
  match add64_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := (R8:imm64 + R9:imm64)"])
    Err(reason) => fail(reason)
  }

  let sub32 = basic_bil_decode("x86", b"\x29\xd8", start=0x701dUL)
  match sub32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := (EAX:imm32 - EBX:imm32)"])
    Err(reason) => fail(reason)
  }

  let sub64_rev = basic_bil_decode("x86_64", b"\x48\x2b\xc8", start=0x701fUL)
  match sub64_rev.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RCX:imm64 := (RCX:imm64 - RAX:imm64)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register logical ops" {
  let xor_zero = basic_bil_decode("x86_64", b"\x48\x31\xc0", start=0x7017UL)
  match xor_zero.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := 0:64u"])
    Err(reason) => fail(reason)
  }

  let xor_ext = basic_bil_decode("x86_64", b"\x4d\x31\xc8", start=0x701aUL)
  match xor_ext.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := (R8:imm64 ^ R9:imm64)"])
    Err(reason) => fail(reason)
  }

  let or32 = basic_bil_decode("x86", b"\x09\xd8", start=0x701dUL)
  match or32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := (EAX:imm32 | EBX:imm32)"])
    Err(reason) => fail(reason)
  }

  let and64_rev = basic_bil_decode("x86_64", b"\x48\x23\xc8", start=0x701fUL)
  match and64_rev.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RCX:imm64 := (RCX:imm64 & RAX:imm64)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 cmp and test flag ops" {
  let cmp_imm = basic_bil_decode("x86_64", b"\x48\x83\xf8\x01", start=0x7021UL)
  match cmp_imm.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm64 := (RAX:imm64 - 1:64u)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (RAX:imm64 < 1:64u)")
      assert_true(stmts[2].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[3].to_string().contains("AF:imm1 := extract[4:4]"))
      assert_true(stmts[4].to_string().contains("PF:imm1 := (not low:1"))
      assert_string(stmts[5].to_string(), "SF:imm1 := high:1[%cmp_tmp:imm64]")
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:64u == %cmp_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmp_imm32 = basic_bil_decode(
    "x86_64",
    b"\x48\x81\xf8\x78\x56\x34\x12",
    start=0x7023UL,
  )
  match cmp_imm32.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm64 := (RAX:imm64 - 0x12345678:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "CF:imm1 := (RAX:imm64 < 0x12345678:64u)",
      )
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:64u == %cmp_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmp_rr = basic_bil_decode("x86", b"\x39\xd1", start=0x7025UL)
  match cmp_rr.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm32 := (ECX:imm32 - EDX:imm32)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (ECX:imm32 < EDX:imm32)")
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:32u == %cmp_tmp:imm32)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test_rr = basic_bil_decode("x86_64", b"\x48\x85\xc0", start=0x7027UL)
  match test_rr.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm64 := (RAX:imm64 & RAX:imm64)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[2].to_string(), "OF:imm1 := 0:1u")
      assert_true(stmts[3].to_string().contains("AF undefined after TEST"))
      assert_true(stmts[4].to_string().contains("PF:imm1 := (not low:1"))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:64u == %test_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test_imm = basic_bil_decode(
    "x86_64",
    b"\x48\xa9\x78\x56\x34\x12",
    start=0x702aUL,
  )
  match test_imm.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm64 := (RAX:imm64 & 0x12345678:64u)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[2].to_string(), "OF:imm1 := 0:1u")
      assert_true(stmts[3].to_string().contains("AF undefined after TEST"))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:64u == %test_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test_ext_imm = basic_bil_decode(
    "x86_64",
    b"\x49\xf7\xc0\xff\xff\xff\xff",
    start=0x7030UL,
  )
  match test_ext_imm.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm64 := (R8:imm64 & 0xFFFFFFFFFFFFFFFF:64u)",
      )
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:64u == %test_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register pushes" {
  let push_rbp = basic_bil_decode("x86_64", b"\x55", start=0x7010UL)
  match push_rbp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), RBP:imm64)", "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_rsp = basic_bil_decode("x86_64", b"\x54", start=0x7011UL)
  match push_rsp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), RSP:imm64)", "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_ebp = basic_bil_decode("x86", b"\x55", start=0x7012UL)
  match push_ebp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 4:32u), EBP:imm32)", "ESP:imm32 := (ESP:imm32 - 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_imm8 = basic_bil_decode("x86_64", b"\x6a\x01", start=0x7013UL)
  match push_imm8.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), 1:64u)", "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_imm32 = basic_bil_decode(
    "x86",
    b"\x68\x78\x56\x34\x12",
    start=0x7015UL,
  )
  match push_imm32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 4:32u), 0x12345678:32u)",
        "ESP:imm32 := (ESP:imm32 - 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_mem = basic_bil_decode("x86_64", b"\xff\x70\x10", start=0x701aUL)
  match push_mem.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm64)",
        "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register pops" {
  let pop_rbp = basic_bil_decode("x86_64", b"\x5d", start=0x7020UL)
  match pop_rbp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RBP:imm64 := load(mem:mem64x8, RSP:imm64):imm64", "RSP:imm64 := (RSP:imm64 + 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_rsp = basic_bil_decode("x86_64", b"\x5c", start=0x7021UL)
  match pop_rsp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RSP:imm64 := load(mem:mem64x8, RSP:imm64):imm64",
      ])
    Err(reason) => fail(reason)
  }

  let pop_ebp = basic_bil_decode("x86", b"\x5d", start=0x7022UL)
  match pop_ebp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EBP:imm32 := load(mem:mem32x8, ESP:imm32):imm32", "ESP:imm32 := (ESP:imm32 + 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_esp = basic_bil_decode("x86", b"\x5c", start=0x7023UL)
  match pop_esp.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ESP:imm32 := load(mem:mem32x8, ESP:imm32):imm32",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register moves" {
  let mov_rbp_rsp = basic_bil_decode("x86_64", b"\x48\x89\xe5", start=0x7030UL)
  match mov_rbp_rsp.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RBP:imm64 := RSP:imm64"])
    Err(reason) => fail(reason)
  }

  let mov_rev = basic_bil_decode("x86_64", b"\x48\x8b\xec", start=0x7033UL)
  match mov_rev.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RBP:imm64 := RSP:imm64"])
    Err(reason) => fail(reason)
  }

  let mov_ebp_esp = basic_bil_decode("x86", b"\x89\xe5", start=0x7036UL)
  match mov_ebp_esp.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["EBP:imm32 := ESP:imm32"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 xchg" {
  let xchg64 = basic_bil_decode("x86_64", b"\x48\x91", start=0x7038UL)
  match xchg64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm64 := RAX:imm64", "RAX:imm64 := RCX:imm64", "RCX:imm64 := %xchg_tmp:imm64",
      ])
    Err(reason) => fail(reason)
  }

  let xchg32 = basic_bil_decode("x86", b"\x87\xd8", start=0x703aUL)
  match xchg32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm32 := EBX:imm32", "EBX:imm32 := EAX:imm32", "EAX:imm32 := %xchg_tmp:imm32",
      ])
    Err(reason) => fail(reason)
  }

  let xchg_mem = basic_bil_decode("x86_64", b"\x48\x87\x45\xf8", start=0x703cUL)
  match xchg_mem.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm64 := RAX:imm64", "RAX:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), %xchg_tmp:imm64)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 movsx movzx" {
  let movzx64 = basic_bil_decode("x86_64", b"\x48\x0f\xb6\xc1", start=0x703fUL)
  match movzx64.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := pad:64[CL:imm8]"])
    Err(reason) => fail(reason)
  }

  let movzx_ext = basic_bil_decode(
    "x86_64",
    b"\x4d\x0f\xb7\xc1",
    start=0x7043UL,
  )
  match movzx_ext.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8:imm64 := pad:64[R9W:imm16]"])
    Err(reason) => fail(reason)
  }

  let movsx_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xbe\x45\xfc",
    start=0x7047UL,
  )
  match movsx_mem.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := extend:64[load(mem:mem64x8, (RBP:imm64 - 4:64u)):imm8]",
      ])
    Err(reason) => fail(reason)
  }

  let movsxd = basic_bil_decode("x86_64", b"\x48\x63\xc1", start=0x704bUL)
  match movsxd.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := extend:64[ECX:imm32]"])
    Err(reason) => fail(reason)
  }

  let movsxd_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x63\x45\xfc",
    start=0x704eUL,
  )
  match movsxd_mem.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := extend:64[load(mem:mem64x8, (RBP:imm64 - 4:64u)):imm32]",
      ])
    Err(reason) => fail(reason)
  }

  let movsx_same_width = basic_bil_decode("x86_64", b"\x63\xc1", start=0x7052UL)
  match movsx_same_width.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[ECX:imm32]"])
    Err(reason) => fail(reason)
  }

  let movsx32 = basic_bil_decode("x86", b"\x0f\xbe\xc4", start=0x704cUL)
  match movsx32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[AH:imm8]"])
    Err(reason) => fail(reason)
  }

  let movsx32_mem = basic_bil_decode("x86", b"\x0f\xbf\x45\xfc", start=0x704fUL)
  match movsx32_mem.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16]",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 accumulator sign-extension ops" {
  let cdqe = basic_bil_decode("x86_64", b"\x48\x98", start=0x7056UL)
  match cdqe.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := extend:64[EAX:imm32]"])
    Err(reason) => fail(reason)
  }

  let cwde = basic_bil_decode("x86", b"\x98", start=0x7058UL)
  match cwde.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[AX:imm16]"])
    Err(reason) => fail(reason)
  }

  let cbw = basic_bil_decode("x86", b"\x66\x98", start=0x7059UL)
  match cbw.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["AX:imm16 := extend:16[AL:imm8]"])
    Err(reason) => fail(reason)
  }

  let cqo = basic_bil_decode("x86_64", b"\x48\x99", start=0x705bUL)
  match cqo.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RDX:imm64 := high:64[extend:128[RAX:imm64]]",
      ])
    Err(reason) => fail(reason)
  }

  let cdq = basic_bil_decode("x86", b"\x99", start=0x705dUL)
  match cdq.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EDX:imm32 := high:32[extend:64[EAX:imm32]]",
      ])
    Err(reason) => fail(reason)
  }

  let cwd = basic_bil_decode("x86", b"\x66\x99", start=0x705eUL)
  match cwd.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["DX:imm16 := high:16[extend:32[AX:imm16]]"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 leave" {
  let leave64 = basic_bil_decode("x86_64", b"\xc9", start=0x7040UL)
  match leave64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RSP:imm64 := RBP:imm64", "RBP:imm64 := load(mem:mem64x8, RSP:imm64):imm64",
        "RSP:imm64 := (RSP:imm64 + 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let leave32 = basic_bil_decode("x86", b"\xc9", start=0x7041UL)
  match leave32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ESP:imm32 := EBP:imm32", "EBP:imm32 := load(mem:mem32x8, ESP:imm32):imm32",
        "ESP:imm32 := (ESP:imm32 + 4:32u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86_64 memory load fixture" {
  let mov_imm = basic_bil_decode(
    "x86_64",
    b"\xb8\x78\x56\x34\x12",
    start=0x70f0UL,
  )
  match mov_imm.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["EAX:imm32 := 0x12345678:32u"])
    Err(reason) => fail(reason)
  }

  let mov_imm64 = basic_bil_decode(
    "x86_64",
    b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x70f8UL,
  )
  match mov_imm64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := 0x1122334455667788:64u"])
    Err(reason) => fail(reason)
  }

  let mov_imm64_from_i32 = basic_bil_decode(
    "x86_64",
    b"\x49\xc7\xc0\xff\xff\xff\xff",
    start=0x70fcUL,
  )
  match mov_imm64_from_i32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := 0xFFFFFFFFFFFFFFFF:64u"])
    Err(reason) => fail(reason)
  }

  let mov = basic_bil_decode("x86_64", b"\x8b\x40\x10", start=0x7100UL)
  match mov.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let mov64 = basic_bil_decode("x86_64", b"\x48\x8b\x45\xf8", start=0x7104UL)
  match mov64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      ])
    Err(reason) => fail(reason)
  }

  let indexed = basic_bil_decode(
    "x86_64",
    b"\x48\x8b\x44\x88\x10",
    start=0x7108UL,
  )
  match indexed.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := load(mem:mem64x8, ((RAX:imm64 + (RCX:imm64 * 4:64u)) + 0x10:64u)):imm64",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 lea" {
  let lea64 = basic_bil_decode("x86_64", b"\x48\x8d\x00", start=0x710cUL)
  match lea64.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := RAX:imm64"])
    Err(reason) => fail(reason)
  }

  let indexed = basic_bil_decode(
    "x86_64",
    b"\x48\x8d\x44\x88\x10",
    start=0x710fUL,
  )
  match indexed.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := ((RAX:imm64 + (RCX:imm64 * 4:64u)) + 0x10:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let lea32 = basic_bil_decode("x86", b"\x8d\x45\xfc", start=0x7114UL)
  match lea32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := (EBP:imm32 - 4:32u)"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory stores" {
  let store64 = basic_bil_decode("x86_64", b"\x48\x89\x45\xf8", start=0x7110UL)
  match store64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), RAX:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let stack_store = basic_bil_decode(
    "x86_64",
    b"\x48\x89\x04\x24",
    start=0x7114UL,
  )
  match stack_store.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, RSP:imm64, RAX:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let store32 = basic_bil_decode("x86", b"\x89\x45\xfc", start=0x7118UL)
  match store32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), EAX:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let store_imm64 = basic_bil_decode(
    "x86_64",
    b"\x48\xc7\x45\xf8\x01\x00\x00\x00",
    start=0x711cUL,
  )
  match store_imm64.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), 1:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let store_imm32 = basic_bil_decode(
    "x86",
    b"\xc7\x45\xfc\x78\x56\x34\x12",
    start=0x7124UL,
  )
  match store_imm32.lift_basic_bil() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), 0x12345678:32u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers direct control transfers" {
  let jmp = basic_bil_decode("x86", b"\xeb\xfe", start=0x7200UL)
  match jmp.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::goto(), stmts[0]) == Some("0x7200"),
      )
      assert_string(stmts[1].to_string(), "jmp 0x7200:64u")
    }
    Err(reason) => fail(reason)
  }

  let near_jmp = basic_bil_decode(
    "x86",
    b"\xe9\x01\x00\x00\x00",
    start=0x7210UL,
  )
  match near_jmp.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::goto(), stmts[0]) == Some("0x7216"),
      )
      assert_string(stmts[1].to_string(), "jmp 0x7216:64u")
    }
    Err(reason) => fail(reason)
  }

  let jne = basic_bil_decode("x86", b"\x75\xfe", start=0x7202UL)
  match jne.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(not ZF:imm1)")
          assert_true(no.length() == 0)
          assert_true(yes.length() == 2)
          assert_true(
            @types.Stmt::decode(@types.Stmt::goto(), yes[0]) == Some("0x7202"),
          )
          assert_string(yes[1].to_string(), "jmp 0x7202:64u")
        }
        _ => fail("conditional x86 branch did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let jg = basic_bil_decode("x86", b"\x0f\x8f\x01\x00\x00\x00", start=0x7209UL)
  match jg.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(
            cond.to_string(),
            "(not (ZF:imm1 | (SF:imm1 ^ OF:imm1)))",
          )
          assert_true(no.length() == 0)
          assert_true(yes.length() == 2)
          assert_true(
            @types.Stmt::decode(@types.Stmt::goto(), yes[0]) == Some("0x7210"),
          )
          assert_string(yes[1].to_string(), "jmp 0x7210:64u")
        }
        _ => fail("near conditional x86 branch did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let call = basic_bil_decode("x86_64", b"\xe8\x47\xee\xff\xff", start=0x7300UL)
  match call.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[0]) == Some("0x614c"),
      )
      assert_string(stmts[1].to_string(), "jmp 0x614C:64u")
    }
    Err(reason) => fail(reason)
  }

  let call32 = basic_bil_decode("x86", b"\xe8\x01\x00\x00\x00", start=0x7310UL)
  match call32.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[0]) == Some("0x7316"),
      )
      assert_string(stmts[1].to_string(), "jmp 0x7316:32u")
    }
    Err(reason) => fail(reason)
  }

  let indirect_call = basic_bil_decode("x86_64", b"\xff\xd0", start=0x7320UL)
  match indirect_call.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[0]) == Some("indirect"),
      )
      assert_string(stmts[1].to_string(), "jmp RAX:imm64")
    }
    Err(reason) => fail(reason)
  }

  let indirect_jmp = basic_bil_decode("x86_64", b"\xff\x60\x10", start=0x7322UL)
  match indirect_jmp.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::goto(), stmts[0]) == Some("indirect"),
      )
      assert_string(
        stmts[1].to_string(),
        "jmp load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm64",
      )
    }
    Err(reason) => fail(reason)
  }

  let ret = basic_bil_decode("x86_64", b"\xc3", start=0x7400UL)
  match ret.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["special ret"])
    Err(reason) => fail(reason)
  }

  let ret32 = basic_bil_decode("x86", b"\xc3", start=0x7401UL)
  match ret32.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["special ret"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers ARM branch and return forms" {
  let branch = basic_bil_decode("armv7", b"\x05\x00\x00\xea", start=0x8424UL)
  match branch.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_true(
        @types.Stmt::decode(@types.Stmt::goto(), stmts[0]) == Some("0x8440"),
      )
      assert_string(stmts[1].to_string(), "jmp 0x8440:32u")
    }
    Err(reason) => fail(reason)
  }

  let conditional = basic_bil_decode(
    "armv7",
    b"\xf6\xff\xff\x1a",
    start=0x8448UL,
  )
  match conditional.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "ARM.NE:imm1")
          assert_true(no.length() == 0)
          assert_true(yes.length() == 2)
          assert_true(
            @types.Stmt::decode(@types.Stmt::goto(), yes[0]) == Some("0x8428"),
          )
          assert_string(yes[1].to_string(), "jmp 0x8428:32u")
        }
        _ => fail("conditional ARM branch did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let bx = basic_bil_decode("armv7", b"\x1e\xff\x2f\xe1", start=0x845cUL)
  match bx.lift_basic_bil() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["jmp LR:imm32"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift runs over ARM strlen fixture" {
  let disassembly = basic_bil_decode_state_with_triple(
    "armv7",
    basic_bil_arm_strlen_bytes(),
    start=0x840cUL,
  )
  match disassembly.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 24)
      assert_string(stmts[0].to_string(), "SP:imm32 := (SP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, SP:imm32, FP:imm32)",
      )
      assert_true(
        stmts.any(stmt => {
          stmt.to_string() == "ARM.NE:imm1 := (R3:imm32 != 0:32u)"
        }),
      )
      assert_true(stmts[17].to_string().has_prefix("if ARM.NE:imm1 then"))
      assert_string(stmts[23].to_string(), "jmp LR:imm32")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift runs over disassembly state and project" {
  let sequence = b"\x48\x83\xec\x08" +
    b"\xe8\x47\xee\xff\xff" +
    b"\x8b\x40\x10" +
    b"\x48\x83\xc4\x08" +
    b"\xc3"
  let disassembly = basic_bil_decode_state(sequence, start=0x7500UL)
  let blocks = disassembly.blocks_with_instructions()
  assert_true(blocks.length() == 1)
  match blocks[0].lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_true(stmts[0].to_string().contains("RSP:imm64 - 8:64u"))
      assert_true(stmts[5].to_string() == "special ret")
    }
    Err(reason) => fail(reason)
  }

  match disassembly.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_true(stmts[0].to_string().contains("RSP:imm64 - 8:64u"))
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[1]) == Some("0x6350"),
      )
      assert_true(stmts[3].to_string().contains("load(mem:mem64x8"))
      assert_true(stmts[5].to_string() == "special ret")
    }
    Err(reason) => fail(reason)
  }

  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    disassembly,
  )
  match project.lift_basic_bil() {
    Ok(stmts) => assert_true(stmts.length() == 6)
    Err(reason) => fail(reason)
  }

  let disasm = @project.ProjectDisasm::from_project(project)
  match disasm.lift_basic_bil() {
    Ok(stmts) => assert_true(stmts.length() == 6)
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift reports unsupported instruction context" {
  let raw = basic_bil_decode("x86_64", b"\x0f", start=0x7600UL)
  match raw.lift_basic_bil() {
    Err(reason) => assert_true(reason.contains("unsupported Basic BIL lift"))
    Ok(_) => fail("raw byte instruction lifted")
  }

  let disassembly = basic_bil_decode_state(b"\x0f", start=0x7600UL)
  let blocks = disassembly.blocks_with_instructions()
  assert_true(blocks.length() == 1)
  match blocks[0].lift_basic_bil() {
    Err(reason) => {
      assert_true(reason.contains(".byte"))
      assert_true(reason.contains("[0x7600,0x7600]"))
    }
    Ok(_) => fail("unsupported disassembly block lifted")
  }

  match disassembly.lift_basic_bil() {
    Err(reason) => {
      assert_true(reason.contains(".byte"))
      assert_true(reason.contains("0x7600"))
    }
    Ok(_) => fail("unsupported disassembly state lifted")
  }
}
