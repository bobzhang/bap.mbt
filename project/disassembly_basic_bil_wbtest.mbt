///|
fn basic_bil_decode(
  triple : String,
  bytes : Bytes,
  start~ : UInt64,
) -> ProjectDisassemblyInstruction raise {
  let disasm = match ProjectDisassemblyBasic::create(triple, backend="llvm") {
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
) -> ProjectDisassemblyState raise {
  basic_bil_decode_state_with_triple("x86_64", bytes, start~)
}

///|
fn basic_bil_decode_state_with_triple(
  triple : String,
  bytes : Bytes,
  start~ : UInt64,
) -> ProjectDisassemblyState raise {
  let disasm = match ProjectDisassemblyBasic::create(triple, backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  let insns = disasm.run(memory, init=(), return_=_ => [], stopped=(s, _) => {
    s.insns()
  })
  let instructions : Array[ProjectDisassemblyInstruction] = []
  for item in insns {
    match item.1 {
      Some(instruction) => instructions.push(instruction)
      None => ()
    }
  }
  ProjectDisassemblyState::create(blocks=[memory], instructions~)
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
fn assert_logical_flag_tail(
  stmts : Array[@types.Stmt],
  offset : Int,
  result : String,
  zero : String,
) -> Unit raise {
  assert_string(stmts[offset].to_string(), "CF:imm1 := 0:1u")
  assert_string(stmts[offset + 1].to_string(), "OF:imm1 := 0:1u")
  assert_true(
    stmts[offset + 2]
    .to_string()
    .contains("AF undefined after logical operation"),
  )
  assert_true(stmts[offset + 3].to_string().contains("PF:imm1 := (not low:1"))
  assert_true(stmts[offset + 3].to_string().contains(result))
  assert_string(stmts[offset + 4].to_string(), "SF:imm1 := high:1[\{result}]")
  assert_string(
    stmts[offset + 5].to_string(),
    "ZF:imm1 := (\{zero} == \{result})",
  )
}

///|
fn assert_addsub_flag_tail(
  stmts : Array[@types.Stmt],
  offset : Int,
  lhs : String,
  rhs : String,
  result : String,
  zero : String,
  is_add : Bool,
) -> Unit raise {
  if is_add {
    assert_string(stmts[offset].to_string(), "CF:imm1 := (\{result} < \{lhs})")
  } else {
    assert_string(stmts[offset].to_string(), "CF:imm1 := (\{lhs} < \{rhs})")
  }
  assert_true(stmts[offset + 1].to_string().contains("OF:imm1 :="))
  assert_true(stmts[offset + 1].to_string().contains(lhs))
  assert_true(stmts[offset + 1].to_string().contains(rhs))
  assert_true(stmts[offset + 1].to_string().contains(result))
  assert_true(stmts[offset + 2].to_string().contains("AF:imm1 := extract[4:4]"))
  assert_true(stmts[offset + 2].to_string().contains(lhs))
  assert_true(stmts[offset + 2].to_string().contains(rhs))
  assert_true(stmts[offset + 2].to_string().contains(result))
  assert_true(stmts[offset + 3].to_string().contains("PF:imm1 := (not low:1"))
  assert_true(stmts[offset + 3].to_string().contains(result))
  assert_string(stmts[offset + 4].to_string(), "SF:imm1 := high:1[\{result}]")
  assert_string(
    stmts[offset + 5].to_string(),
    "ZF:imm1 := (\{zero} == \{result})",
  )
}

///|
fn assert_incdec_flag_tail(
  stmts : Array[@types.Stmt],
  offset : Int,
  lhs : String,
  rhs : String,
  result : String,
  zero : String,
) -> Unit raise {
  assert_true(!stmts.any(stmt => stmt.to_string().has_prefix("CF:imm1 :=")))
  assert_true(stmts[offset].to_string().contains("OF:imm1 :="))
  assert_true(stmts[offset].to_string().contains(lhs))
  assert_true(stmts[offset].to_string().contains(rhs))
  assert_true(stmts[offset].to_string().contains(result))
  assert_true(stmts[offset + 1].to_string().contains("AF:imm1 := extract[4:4]"))
  assert_true(stmts[offset + 1].to_string().contains(lhs))
  assert_true(stmts[offset + 1].to_string().contains(rhs))
  assert_true(stmts[offset + 1].to_string().contains(result))
  assert_true(stmts[offset + 2].to_string().contains("PF:imm1 := (not low:1"))
  assert_true(stmts[offset + 2].to_string().contains(result))
  assert_string(stmts[offset + 3].to_string(), "SF:imm1 := high:1[\{result}]")
  assert_string(
    stmts[offset + 4].to_string(),
    "ZF:imm1 := (\{zero} == \{result})",
  )
}

///|
fn assert_shift_flag_update(
  stmt : @types.Stmt,
  cond_text : String,
  cf_text : String,
  count_text : String,
  one_text : String,
  result : String,
  zero : String,
  of_text : String,
) -> Unit raise {
  match stmt {
    If(cond~, yes~, no~) => {
      assert_string(cond.to_string(), cond_text)
      assert_true(no.is_empty())
      assert_true(yes.length() == 6)
      assert_string(yes[0].to_string(), cf_text)
      assert_string(yes[1].to_string(), "SF:imm1 := high:1[\{result}]")
      assert_string(yes[2].to_string(), "ZF:imm1 := (\{zero} == \{result})")
      assert_true(yes[3].to_string().contains("AF undefined after shift"))
      assert_true(yes[4].to_string().contains("PF:imm1 := (not low:1"))
      assert_true(yes[4].to_string().contains(result))
      match yes[5] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(\{count_text} == \{one_text})")
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), of_text)
          assert_true(no.length() == 1)
          assert_string(
            no[0].to_string(),
            "OF:imm1 := unknown(OF undefined after shift of more then 1 bit:imm1)",
          )
        }
        _ => fail("shift OF update did not lift to BIL if")
      }
    }
    _ => fail("shift flag update did not lift to BIL if")
  }
}

///|
fn assert_rotate_flag_update(
  stmt : @types.Stmt,
  cond_text : String,
  cf_text : String,
  count_text : String,
  one_text : String,
  of_text : String,
) -> Unit raise {
  match stmt {
    If(cond~, yes~, no~) => {
      assert_string(cond.to_string(), cond_text)
      assert_true(no.is_empty())
      assert_true(yes.length() == 2)
      assert_string(yes[0].to_string(), cf_text)
      match yes[1] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(\{count_text} == \{one_text})")
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), of_text)
          assert_true(no.length() == 1)
          assert_string(
            no[0].to_string(),
            "OF:imm1 := unknown(OF undefined after rotate of more then 1 bit:imm1)",
          )
        }
        _ => fail("rotate OF update did not lift to BIL if")
      }
    }
    _ => fail("rotate flag update did not lift to BIL if")
  }
}

///|
test "project Basic BIL lift covers x86_64 stack arithmetic fixtures" {
  let noop = basic_bil_decode("x86_64", b"\x90", start=0x6ff0UL)
  match noop.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let pause = basic_bil_decode("x86_64", b"\xf3\x90", start=0x6ff1UL)
  match pause.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let lfence = basic_bil_decode("x86_64", b"\x0f\xae\xe8", start=0x6ff3UL)
  match lfence.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let mfence = basic_bil_decode("x86_64", b"\x0f\xae\xf0", start=0x6ff6UL)
  match mfence.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let sfence = basic_bil_decode("x86_64", b"\x0f\xae\xf8", start=0x6ff9UL)
  match sfence.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let multi_noop = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\x1f\x84\x00\x00\x00\x00\x00",
    start=0x6ff1UL,
  )
  match multi_noop.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let fwait = basic_bil_decode("x86", b"\x9b", start=0x6ff2UL)
  match fwait.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let endbr64 = basic_bil_decode("x86_64", b"\xf3\x0f\x1e\xfa", start=0x6ffaUL)
  match endbr64.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let endbr32 = basic_bil_decode("x86", b"\xf3\x0f\x1e\xfb", start=0x6ffeUL)
  match endbr32.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let movsb = basic_bil_decode("x86_64", b"\xa4", start=0x6fffUL)
  match movsb.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, RDI:imm64, load(mem:mem64x8, RSI:imm64):imm8)",
        "RSI:imm64 := ite((DF:imm1 == 0:1u), (RSI:imm64 + 1:64u), (RSI:imm64 - 1:64u))",
        "RDI:imm64 := ite((DF:imm1 == 0:1u), (RDI:imm64 + 1:64u), (RDI:imm64 - 1:64u))",
      ])
    Err(reason) => fail(reason)
  }

  let movsw = basic_bil_decode("x86", b"\x66\xa5", start=0x7000UL)
  match movsw.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, EDI:imm32, load(mem:mem32x8, ESI:imm32):imm16)",
        "ESI:imm32 := ite((DF:imm1 == 0:1u), (ESI:imm32 + 2:32u), (ESI:imm32 - 2:32u))",
        "EDI:imm32 := ite((DF:imm1 == 0:1u), (EDI:imm32 + 2:32u), (EDI:imm32 - 2:32u))",
      ])
    Err(reason) => fail(reason)
  }

  let stosq = basic_bil_decode("x86_64", b"\x48\xab", start=0x7002UL)
  match stosq.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, RDI:imm64, RAX:imm64)", "RDI:imm64 := ite((DF:imm1 == 0:1u), (RDI:imm64 + 8:64u), (RDI:imm64 - 8:64u))",
      ])
    Err(reason) => fail(reason)
  }

  let cmpsb = basic_bil_decode("x86_64", b"\xa6", start=0x7003UL)
  match cmpsb.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(
        stmts[0].to_string(),
        "%cmps_src1:imm8 := load(mem:mem64x8, RSI:imm64):imm8",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmps_src2:imm8 := load(mem:mem64x8, RDI:imm64):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmps_tmp:imm8 := (%cmps_src1:imm8 - %cmps_src2:imm8)",
      )
      assert_string(
        stmts[3].to_string(),
        "RSI:imm64 := ite((DF:imm1 == 0:1u), (RSI:imm64 + 1:64u), (RSI:imm64 - 1:64u))",
      )
      assert_string(
        stmts[4].to_string(),
        "RDI:imm64 := ite((DF:imm1 == 0:1u), (RDI:imm64 + 1:64u), (RDI:imm64 - 1:64u))",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%cmps_src1:imm8", "%cmps_src2:imm8", "%cmps_tmp:imm8", "0:8u",
        false,
      )
    }
    Err(reason) => fail(reason)
  }

  let scasw = basic_bil_decode("x86", b"\x66\xaf", start=0x7004UL)
  match scasw.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%scas_src1:imm16 := AX:imm16")
      assert_string(
        stmts[1].to_string(),
        "%scas_src2:imm16 := load(mem:mem32x8, EDI:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%scas_tmp:imm16 := (%scas_src1:imm16 - %scas_src2:imm16)",
      )
      assert_string(
        stmts[3].to_string(),
        "EDI:imm32 := ite((DF:imm1 == 0:1u), (EDI:imm32 + 2:32u), (EDI:imm32 - 2:32u))",
      )
      assert_addsub_flag_tail(
        stmts, 4, "%scas_src1:imm16", "%scas_src2:imm16", "%scas_tmp:imm16", "0:16u",
        false,
      )
    }
    Err(reason) => fail(reason)
  }

  let rep_movsb = basic_bil_decode("x86_64", b"\xf3\xa4", start=0x7005UL)
  match rep_movsb.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      assert_string(stmts[0].to_string(), "%rep_continue:imm1 := 1:1u")
      match stmts[1] {
        While(cond~, body~) => {
          assert_string(
            cond.to_string(),
            "((RCX:imm64 != 0:64u) & %rep_continue:imm1)",
          )
          assert_true(body.length() == 4)
          assert_string(
            body[0].to_string(),
            "mem:mem64x8 := store(mem:mem64x8, RDI:imm64, load(mem:mem64x8, RSI:imm64):imm8)",
          )
          assert_string(body[3].to_string(), "RCX:imm64 := (RCX:imm64 - 1:64u)")
        }
        _ => fail("REP MOVS did not lift to BIL while")
      }
    }
    Err(reason) => fail(reason)
  }

  let repe_cmpsb = basic_bil_decode("x86_64", b"\xf3\xa6", start=0x7007UL)
  match repe_cmpsb.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      match stmts[1] {
        While(cond~, body~) => {
          assert_string(
            cond.to_string(),
            "((RCX:imm64 != 0:64u) & %rep_continue:imm1)",
          )
          assert_true(body.length() == 13)
          assert_string(
            body[0].to_string(),
            "%cmps_src1:imm8 := load(mem:mem64x8, RSI:imm64):imm8",
          )
          assert_string(
            body[11].to_string(),
            "RCX:imm64 := (RCX:imm64 - 1:64u)",
          )
          assert_string(body[12].to_string(), "%rep_continue:imm1 := ZF:imm1")
        }
        _ => fail("REPE CMPS did not lift to BIL while")
      }
    }
    Err(reason) => fail(reason)
  }

  let repne_scasw = basic_bil_decode("x86", b"\xf2\x66\xaf", start=0x7009UL)
  match repne_scasw.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      match stmts[1] {
        While(cond~, body~) => {
          assert_string(
            cond.to_string(),
            "((ECX:imm32 != 0:32u) & %rep_continue:imm1)",
          )
          assert_true(body.length() == 12)
          assert_string(body[0].to_string(), "%scas_src1:imm16 := AX:imm16")
          assert_string(
            body[10].to_string(),
            "ECX:imm32 := (ECX:imm32 - 1:32u)",
          )
          assert_string(
            body[11].to_string(),
            "%rep_continue:imm1 := (not ZF:imm1)",
          )
        }
        _ => fail("REPNE SCAS did not lift to BIL while")
      }
    }
    Err(reason) => fail(reason)
  }

  let sub = basic_bil_decode("x86_64", b"\x48\x83\xec\x08", start=0x7000UL)
  match sub.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm64 := RSP:imm64")
      assert_string(stmts[1].to_string(), "%sub_src:imm64 := 8:64u")
      assert_string(
        stmts[2].to_string(),
        "RSP:imm64 := (%sub_dst:imm64 - %sub_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm64", "%sub_src:imm64", "RSP:imm64", "0:64u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let add = basic_bil_decode("x86_64", b"\x48\x83\xc4\x08", start=0x7004UL)
  match add.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := RSP:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := 8:64u")
      assert_string(
        stmts[2].to_string(),
        "RSP:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "RSP:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 flag controls" {
  let clc = basic_bil_decode("x86", b"\xf8", start=0x7008UL)
  match clc.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["CF:imm1 := 0:1u"])
    Err(reason) => fail(reason)
  }

  let stc = basic_bil_decode("x86", b"\xf9", start=0x7009UL)
  match stc.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["CF:imm1 := 1:1u"])
    Err(reason) => fail(reason)
  }

  let cmc = basic_bil_decode("x86_64", b"\xf5", start=0x700aUL)
  match cmc.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["CF:imm1 := (not CF:imm1)"])
    Err(reason) => fail(reason)
  }

  let cld = basic_bil_decode("x86_64", b"\xfc", start=0x700bUL)
  match cld.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["DF:imm1 := 0:1u"])
    Err(reason) => fail(reason)
  }

  let std = basic_bil_decode("x86_64", b"\xfd", start=0x700cUL)
  match std.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["DF:imm1 := 1:1u"])
    Err(reason) => fail(reason)
  }

  let sahf = basic_bil_decode("x86", b"\x9e", start=0x700dUL)
  match sahf.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "SF:imm1 := extract[7:7](AH:imm8)", "ZF:imm1 := extract[6:6](AH:imm8)", "AF:imm1 := extract[4:4](AH:imm8)",
        "PF:imm1 := extract[2:2](AH:imm8)", "CF:imm1 := extract[0:0](AH:imm8)",
      ])
    Err(reason) => fail(reason)
  }

  let lahf = basic_bil_decode("x86_64", b"\x9f", start=0x700eUL)
  match lahf.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AH:imm8 := concat(concat(concat(concat(concat(concat(concat(SF:imm1, ZF:imm1), 0:1u), AF:imm1), 0:1u), PF:imm1), 1:1u), CF:imm1)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 flag stack transfers" {
  let pushf32 = basic_bil_decode("x86", b"\x9c", start=0x700fUL)
  match pushf32.project_basic_bil_lift() {
    Ok(stmts) => {
      let text = basic_bil_text(stmts)
      assert_true(text.length() == 2)
      assert_true(
        text[0].contains(
          "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 4:32u), concat(",
        ),
      )
      assert_true(text[0].contains("OF:imm1"))
      assert_true(text[0].contains("DF:imm1"))
      assert_true(text[0].contains("SF:imm1"))
      assert_true(text[0].contains("ZF:imm1"))
      assert_true(text[0].contains("AF:imm1"))
      assert_true(text[0].contains("PF:imm1"))
      assert_true(text[0].contains("CF:imm1"))
      assert_string(text[1], "ESP:imm32 := (ESP:imm32 - 4:32u)")
    }
    Err(reason) => fail(reason)
  }

  let pushf64 = basic_bil_decode("x86_64", b"\x9c", start=0x7010UL)
  match pushf64.project_basic_bil_lift() {
    Ok(stmts) => {
      let text = basic_bil_text(stmts)
      assert_true(text.length() == 2)
      assert_true(
        text[0].contains(
          "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), concat(",
        ),
      )
      assert_true(text[0].contains("OF:imm1"))
      assert_true(text[0].contains("DF:imm1"))
      assert_true(text[0].contains("CF:imm1"))
      assert_string(text[1], "RSP:imm64 := (RSP:imm64 - 8:64u)")
    }
    Err(reason) => fail(reason)
  }

  let pushf16 = basic_bil_decode("x86", b"\x66\x9c", start=0x7011UL)
  match pushf16.project_basic_bil_lift() {
    Ok(stmts) => {
      let text = basic_bil_text(stmts)
      assert_true(text.length() == 2)
      assert_true(
        text[0].contains(
          "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 2:32u), concat(",
        ),
      )
      assert_true(text[0].contains("OF:imm1"))
      assert_true(text[0].contains("DF:imm1"))
      assert_true(text[0].contains("CF:imm1"))
      assert_string(text[1], "ESP:imm32 := (ESP:imm32 - 2:32u)")
    }
    Err(reason) => fail(reason)
  }

  let pushf16_64 = basic_bil_decode("x86_64", b"\x66\x9c", start=0x7012UL)
  match pushf16_64.project_basic_bil_lift() {
    Ok(stmts) => {
      let text = basic_bil_text(stmts)
      assert_true(text.length() == 2)
      assert_true(
        text[0].contains(
          "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 2:64u), concat(",
        ),
      )
      assert_true(text[0].contains("OF:imm1"))
      assert_true(text[0].contains("DF:imm1"))
      assert_true(text[0].contains("CF:imm1"))
      assert_string(text[1], "RSP:imm64 := (RSP:imm64 - 2:64u)")
    }
    Err(reason) => fail(reason)
  }

  let popf32 = basic_bil_decode("x86", b"\x9d", start=0x7011UL)
  match popf32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%popf_flags:imm32 := load(mem:mem32x8, ESP:imm32):imm32", "ESP:imm32 := (ESP:imm32 + 4:32u)",
        "OF:imm1 := extract[11:11](%popf_flags:imm32)", "DF:imm1 := extract[10:10](%popf_flags:imm32)",
        "SF:imm1 := extract[7:7](%popf_flags:imm32)", "ZF:imm1 := extract[6:6](%popf_flags:imm32)",
        "AF:imm1 := extract[4:4](%popf_flags:imm32)", "PF:imm1 := extract[2:2](%popf_flags:imm32)",
        "CF:imm1 := extract[0:0](%popf_flags:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let popf16 = basic_bil_decode("x86", b"\x66\x9d", start=0x7013UL)
  match popf16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%popf_flags:imm16 := load(mem:mem32x8, ESP:imm32):imm16", "ESP:imm32 := (ESP:imm32 + 2:32u)",
        "OF:imm1 := extract[11:11](%popf_flags:imm16)", "DF:imm1 := extract[10:10](%popf_flags:imm16)",
        "SF:imm1 := extract[7:7](%popf_flags:imm16)", "ZF:imm1 := extract[6:6](%popf_flags:imm16)",
        "AF:imm1 := extract[4:4](%popf_flags:imm16)", "PF:imm1 := extract[2:2](%popf_flags:imm16)",
        "CF:imm1 := extract[0:0](%popf_flags:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let popf16_64 = basic_bil_decode("x86_64", b"\x66\x9d", start=0x7014UL)
  match popf16_64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%popf_flags:imm16 := load(mem:mem64x8, RSP:imm64):imm16", "RSP:imm64 := (RSP:imm64 + 2:64u)",
        "OF:imm1 := extract[11:11](%popf_flags:imm16)", "DF:imm1 := extract[10:10](%popf_flags:imm16)",
        "SF:imm1 := extract[7:7](%popf_flags:imm16)", "ZF:imm1 := extract[6:6](%popf_flags:imm16)",
        "AF:imm1 := extract[4:4](%popf_flags:imm16)", "PF:imm1 := extract[2:2](%popf_flags:imm16)",
        "CF:imm1 := extract[0:0](%popf_flags:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let popf64 = basic_bil_decode("x86_64", b"\x9d", start=0x7012UL)
  match popf64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%popf_flags:imm64 := load(mem:mem64x8, RSP:imm64):imm64", "RSP:imm64 := (RSP:imm64 + 8:64u)",
        "OF:imm1 := extract[11:11](%popf_flags:imm64)", "DF:imm1 := extract[10:10](%popf_flags:imm64)",
        "SF:imm1 := extract[7:7](%popf_flags:imm64)", "ZF:imm1 := extract[6:6](%popf_flags:imm64)",
        "AF:imm1 := extract[4:4](%popf_flags:imm64)", "PF:imm1 := extract[2:2](%popf_flags:imm64)",
        "CF:imm1 := extract[0:0](%popf_flags:imm64)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 interrupts" {
  let int3 = basic_bil_decode("x86", b"\xcc", start=0x7010UL)
  match int3.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["cpuexn 3"])
    Err(reason) => fail(reason)
  }

  let int80 = basic_bil_decode("x86", b"\xcd\x80", start=0x7011UL)
  match int80.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["cpuexn 128"])
    Err(reason) => fail(reason)
  }

  let ud2 = basic_bil_decode("x86", b"\x0f\x0b", start=0x7013UL)
  match ud2.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["cpuexn 6"])
    Err(reason) => fail(reason)
  }

  let int64 = basic_bil_decode("x86_64", b"\xcd\x03", start=0x7015UL)
  match int64.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["cpuexn 3"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 system instructions" {
  let hlt = basic_bil_decode("x86", b"\xf4", start=0x7014UL)
  match hlt.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let invd = basic_bil_decode("x86", b"\x0f\x08", start=0x7015UL)
  match invd.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let wbinvd = basic_bil_decode("x86", b"\x0f\x09", start=0x7017UL)
  match wbinvd.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let wrmsr = basic_bil_decode("x86", b"\x0f\x30", start=0x7019UL)
  match wrmsr.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let rdtsc = basic_bil_decode("x86_64", b"\x0f\x31", start=0x701bUL)
  match rdtsc.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(rdtsc:imm32)", "EDX:imm32 := unknown(rdtsc:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let rdmsr = basic_bil_decode("x86_64", b"\x0f\x32", start=0x701dUL)
  match rdmsr.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(rdmsr:imm32)", "EDX:imm32 := unknown(rdmsr:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let rdpmc = basic_bil_decode("x86_64", b"\x0f\x33", start=0x701fUL)
  match rdpmc.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(rdpmc:imm32)", "EDX:imm32 := unknown(rdpmc:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let rdtscp = basic_bil_decode("x86_64", b"\x0f\x01\xf9", start=0x7021UL)
  match rdtscp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(rdtscp:imm32)", "EDX:imm32 := unknown(rdtscp:imm32)",
        "ECX:imm32 := unknown(rdtscp:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let cpuid = basic_bil_decode("x86_64", b"\x0f\xa2", start=0x7024UL)
  match cpuid.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(cpuid:imm32)", "EBX:imm32 := unknown(cpuid:imm32)",
        "ECX:imm32 := unknown(cpuid:imm32)", "EDX:imm32 := unknown(cpuid:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let xgetbv = basic_bil_decode("x86", b"\x0f\x01\xd0", start=0x7026UL)
  match xgetbv.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(xgetbv:imm32)", "EDX:imm32 := unknown(xgetbv:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let monitor = basic_bil_decode("x86_64", b"\x0f\x01\xc8", start=0x7029UL)
  match monitor.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let mwait = basic_bil_decode("x86_64", b"\x0f\x01\xc9", start=0x702cUL)
  match mwait.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let mwaitx = basic_bil_decode("x86_64", b"\x0f\x01\xfb", start=0x702fUL)
  match mwaitx.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let syscall = basic_bil_decode("x86_64", b"\x0f\x05", start=0x7032UL)
  match syscall.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[0]) == Some("syscall"),
      )
    }
    Err(reason) => fail(reason)
  }

  let sysenter = basic_bil_decode("x86", b"\x0f\x34", start=0x7034UL)
  match sysenter.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[0]) == Some("syscall"),
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 port I/O instructions" {
  let in8 = basic_bil_decode("x86", b"\xe4\x80", start=0x7036UL)
  match in8.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AL:imm8 := unknown(in:imm8)"])
    Err(reason) => fail(reason)
  }

  let in16 = basic_bil_decode("x86", b"\x66\xed", start=0x7038UL)
  match in16.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AX:imm16 := unknown(in:imm16)"])
    Err(reason) => fail(reason)
  }

  let in32 = basic_bil_decode("x86_64", b"\x40\xed", start=0x703aUL)
  match in32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := unknown(in:imm32)"])
    Err(reason) => fail(reason)
  }

  let out8 = basic_bil_decode("x86", b"\xe6\x80", start=0x703cUL)
  match out8.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let out16 = basic_bil_decode("x86", b"\x66\xef", start=0x703eUL)
  match out16.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 random instructions" {
  let rdrand32 = basic_bil_decode("x86", b"\x0f\xc7\xf0", start=0x7020UL)
  match rdrand32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := unknown(rdrand:imm32)", "CF:imm1 := unknown(rdrand:imm1)",
        "OF:imm1 := 0:1u", "SF:imm1 := 0:1u", "ZF:imm1 := 0:1u", "AF:imm1 := 0:1u",
        "PF:imm1 := 0:1u",
      ])
    Err(reason) => fail(reason)
  }

  let rdrand64 = basic_bil_decode("x86_64", b"\x49\x0f\xc7\xf1", start=0x7023UL)
  match rdrand64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R9:imm64 := unknown(rdrand:imm64)", "CF:imm1 := unknown(rdrand:imm1)", "OF:imm1 := 0:1u",
        "SF:imm1 := 0:1u", "ZF:imm1 := 0:1u", "AF:imm1 := 0:1u", "PF:imm1 := 0:1u",
      ])
    Err(reason) => fail(reason)
  }

  let rdseed16 = basic_bil_decode(
    "x86_64",
    b"\x66\x41\x0f\xc7\xf8",
    start=0x7027UL,
  )
  match rdseed16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8W:imm16 := unknown(rdseed:imm16)", "CF:imm1 := unknown(rdseed:imm1)",
        "OF:imm1 := 0:1u", "SF:imm1 := 0:1u", "ZF:imm1 := 0:1u", "AF:imm1 := 0:1u",
        "PF:imm1 := 0:1u",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register add-sub immediates" {
  let sub64 = basic_bil_decode("x86_64", b"\x48\x83\xe8\x01", start=0x7008UL)
  match sub64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%sub_src:imm64 := 1:64u")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%sub_dst:imm64 - %sub_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm64", "%sub_src:imm64", "RAX:imm64", "0:64u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let add64_ext = basic_bil_decode(
    "x86_64",
    b"\x49\x83\xc0\x08",
    start=0x700cUL,
  )
  match add64_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := R8:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := 8:64u")
      assert_string(
        stmts[2].to_string(),
        "R8:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "R8:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add32 = basic_bil_decode("x86", b"\x83\xc0\x01", start=0x7010UL)
  match add32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm32 := EAX:imm32")
      assert_string(stmts[1].to_string(), "%add_src:imm32 := 1:32u")
      assert_string(
        stmts[2].to_string(),
        "EAX:imm32 := (%add_dst:imm32 + %add_src:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm32", "%add_src:imm32", "EAX:imm32", "0:32u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add16 = basic_bil_decode("x86", b"\x66\x83\xc0\x01", start=0x7011UL)
  match add16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm16 := AX:imm16")
      assert_string(stmts[1].to_string(), "%add_src:imm16 := 1:16u")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := (%add_dst:imm16 + %add_src:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm16", "%add_src:imm16", "AX:imm16", "0:16u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub32_ext = basic_bil_decode(
    "x86_64",
    b"\x41\x83\xe8\x01",
    start=0x7013UL,
  )
  match sub32_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm32 := R8D:imm32")
      assert_string(stmts[1].to_string(), "%sub_src:imm32 := 1:32u")
      assert_string(
        stmts[2].to_string(),
        "R8D:imm32 := (%sub_dst:imm32 - %sub_src:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm32", "%sub_src:imm32", "R8D:imm32", "0:32u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let add8_ext = basic_bil_decode("x86_64", b"\x41\x80\xc0\xff", start=0x7014UL)
  match add8_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm8 := R8B:imm8")
      assert_string(stmts[1].to_string(), "%add_src:imm8 := 0xFF:8u")
      assert_string(
        stmts[2].to_string(),
        "R8B:imm8 := (%add_dst:imm8 + %add_src:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm8", "%add_src:imm8", "R8B:imm8", "0:8u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub8_acc = basic_bil_decode("x86", b"\x2c\x80", start=0x7015UL)
  match sub8_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm8 := AL:imm8")
      assert_string(stmts[1].to_string(), "%sub_src:imm8 := 0x80:8u")
      assert_string(
        stmts[2].to_string(),
        "AL:imm8 := (%sub_dst:imm8 - %sub_src:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm8", "%sub_src:imm8", "AL:imm8", "0:8u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let add64_ri32 = basic_bil_decode(
    "x86_64",
    b"\x48\x81\xc0\x78\x56\x34\x12",
    start=0x7014UL,
  )
  match add64_ri32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := 0x12345678:64u")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "RAX:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add64_acc = basic_bil_decode(
    "x86_64",
    b"\x48\x05\x78\x56\x34\x12",
    start=0x7015UL,
  )
  match add64_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := 0x12345678:64u")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "RAX:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let adc64 = basic_bil_decode("x86_64", b"\x48\x83\xd0\x01", start=0x7016UL)
  match adc64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%adc_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%adc_src:imm64 := 1:64u")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := ((%adc_dst:imm64 + %adc_src:imm64) + pad:64[CF:imm1])",
      )
      assert_true(stmts[3].to_string().contains("CF:imm1 := extract[64:64]"))
      assert_true(stmts[3].to_string().contains("pad:65[%adc_dst:imm64]"))
      assert_true(stmts[4].to_string().contains("OF:imm1 :="))
      assert_true(stmts[5].to_string().contains("AF:imm1 := extract[4:4]"))
      assert_true(stmts[6].to_string().contains("PF:imm1 := (not low:1"))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[RAX:imm64]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:64u == RAX:imm64)")
    }
    Err(reason) => fail(reason)
  }

  let adc16_acc = basic_bil_decode("x86", b"\x66\x15\x34\x12", start=0x7017UL)
  match adc16_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%adc_dst:imm16 := AX:imm16")
      assert_string(stmts[1].to_string(), "%adc_src:imm16 := 0x1234:16u")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := ((%adc_dst:imm16 + %adc_src:imm16) + pad:16[CF:imm1])",
      )
      assert_true(stmts[3].to_string().contains("CF:imm1 := extract[16:16]"))
      assert_true(stmts[3].to_string().contains("pad:17[%adc_dst:imm16]"))
      assert_true(stmts[4].to_string().contains("OF:imm1 :="))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[AX:imm16]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:16u == AX:imm16)")
    }
    Err(reason) => fail(reason)
  }

  let sbb8 = basic_bil_decode("x86", b"\x80\xd8\x80", start=0x7018UL)
  match sbb8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sbb_src:imm8 := 0x80:8u")
      assert_string(stmts[1].to_string(), "%sbb_dst:imm8 := AL:imm8")
      assert_string(
        stmts[2].to_string(),
        "AL:imm8 := (%sbb_dst:imm8 - (%sbb_src:imm8 + pad:8[CF:imm1]))",
      )
      assert_true(stmts[3].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[4].to_string().contains("CF:imm1 := ("))
      assert_true(stmts[4].to_string().contains("%sbb_dst:imm8 <"))
      assert_true(stmts[5].to_string().contains("AF:imm1 := extract[4:4]"))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[AL:imm8]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:8u == AL:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let sbb16 = basic_bil_decode("x86", b"\x66\x81\xd8\x34\x12", start=0x7019UL)
  match sbb16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sbb_src:imm16 := 0x1234:16u")
      assert_string(stmts[1].to_string(), "%sbb_dst:imm16 := AX:imm16")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := (%sbb_dst:imm16 - (%sbb_src:imm16 + pad:16[CF:imm1]))",
      )
      assert_true(stmts[3].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[4].to_string().contains("CF:imm1 := ("))
      assert_true(stmts[4].to_string().contains("%sbb_dst:imm16 <"))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[AX:imm16]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:16u == AX:imm16)")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register logical immediates" {
  let or64 = basic_bil_decode("x86_64", b"\x48\x83\xc8\x0f", start=0x7016UL)
  match or64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "RAX:imm64 := (RAX:imm64 | 0xF:64u)")
      assert_logical_flag_tail(stmts, 1, "RAX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let and64_ext = basic_bil_decode(
    "x86_64",
    b"\x49\x83\xe0\x7f",
    start=0x701aUL,
  )
  match and64_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "R8:imm64 := (R8:imm64 & 0x7F:64u)")
      assert_logical_flag_tail(stmts, 1, "R8:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let xor32 = basic_bil_decode("x86", b"\x83\xf2\x01", start=0x701eUL)
  match xor32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "EDX:imm32 := (EDX:imm32 ^ 1:32u)")
      assert_logical_flag_tail(stmts, 1, "EDX:imm32", "0:32u")
    }
    Err(reason) => fail(reason)
  }

  let or8 = basic_bil_decode("x86", b"\x80\xc8\x0f", start=0x701fUL)
  match or8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AL:imm8 := (AL:imm8 | 0xF:8u)")
      assert_logical_flag_tail(stmts, 1, "AL:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }

  let and16_acc = basic_bil_decode("x86", b"\x66\x25\xff\x00", start=0x701fUL)
  match and16_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AX:imm16 := (AX:imm16 & 0xFF:16u)")
      assert_logical_flag_tail(stmts, 1, "AX:imm16", "0:16u")
    }
    Err(reason) => fail(reason)
  }

  let xor8_acc = basic_bil_decode("x86", b"\x34\x80", start=0x7020UL)
  match xor8_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AL:imm8 := (AL:imm8 ^ 0x80:8u)")
      assert_logical_flag_tail(stmts, 1, "AL:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }

  let or64_ri32 = basic_bil_decode(
    "x86_64",
    b"\x48\x81\xc8\x78\x56\x34\x12",
    start=0x7020UL,
  )
  match or64_ri32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "RAX:imm64 := (RAX:imm64 | 0x12345678:64u)",
      )
      assert_logical_flag_tail(stmts, 1, "RAX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let or64_acc = basic_bil_decode(
    "x86_64",
    b"\x48\x0d\x78\x56\x34\x12",
    start=0x7021UL,
  )
  match or64_acc.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "RAX:imm64 := (RAX:imm64 | 0x12345678:64u)",
      )
      assert_logical_flag_tail(stmts, 1, "RAX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory add-sub immediates" {
  let add64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x83\x45\xf8\x01",
    start=0x7022UL,
  )
  match add64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%add_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%add_dst:imm64 := load(mem:mem64x8, %add_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%add_src:imm64 := 1:64u")
      assert_string(
        stmts[3].to_string(),
        "%add_res:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %add_a:imm64, %add_res:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%add_dst:imm64", "%add_src:imm64", "%add_res:imm64", "0:64u",
        true,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub32_mem = basic_bil_decode(
    "x86",
    b"\x81\x6d\xfc\x78\x56\x34\x12",
    start=0x7027UL,
  )
  match sub32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sub_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sub_dst:imm32 := load(mem:mem32x8, %sub_a:imm32):imm32",
      )
      assert_string(stmts[2].to_string(), "%sub_src:imm32 := 0x12345678:32u")
      assert_string(
        stmts[3].to_string(),
        "%sub_res:imm32 := (%sub_dst:imm32 - %sub_src:imm32)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sub_a:imm32, %sub_res:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%sub_dst:imm32", "%sub_src:imm32", "%sub_res:imm32", "0:32u",
        false,
      )
    }
    Err(reason) => fail(reason)
  }

  let add16_mem = basic_bil_decode(
    "x86",
    b"\x66\x83\x45\xfc\x01",
    start=0x7029UL,
  )
  match add16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%add_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%add_dst:imm16 := load(mem:mem32x8, %add_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%add_src:imm16 := 1:16u")
      assert_string(
        stmts[3].to_string(),
        "%add_res:imm16 := (%add_dst:imm16 + %add_src:imm16)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %add_a:imm32, %add_res:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%add_dst:imm16", "%add_src:imm16", "%add_res:imm16", "0:16u",
        true,
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory add-sub rr operands" {
  let add64_mr = basic_bil_decode("x86_64", b"\x48\x01\x4d\xf8", start=0x702cUL)
  match add64_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%add_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%add_dst:imm64 := load(mem:mem64x8, %add_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%add_src:imm64 := RCX:imm64")
      assert_string(
        stmts[3].to_string(),
        "%add_res:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %add_a:imm64, %add_res:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%add_dst:imm64", "%add_src:imm64", "%add_res:imm64", "0:64u",
        true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add64_rm = basic_bil_decode("x86_64", b"\x48\x03\x45\xf8", start=0x702dUL)
  match add64_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := RAX:imm64")
      assert_string(
        stmts[1].to_string(),
        "%add_src:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "RAX:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub32_mr = basic_bil_decode("x86", b"\x29\x4d\xfc", start=0x702fUL)
  match sub32_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sub_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sub_dst:imm32 := load(mem:mem32x8, %sub_a:imm32):imm32",
      )
      assert_string(stmts[2].to_string(), "%sub_src:imm32 := ECX:imm32")
      assert_string(
        stmts[3].to_string(),
        "%sub_res:imm32 := (%sub_dst:imm32 - %sub_src:imm32)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sub_a:imm32, %sub_res:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%sub_dst:imm32", "%sub_src:imm32", "%sub_res:imm32", "0:32u",
        false,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub16_mr = basic_bil_decode("x86", b"\x66\x29\x4d\xfc", start=0x7030UL)
  match sub16_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sub_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sub_dst:imm16 := load(mem:mem32x8, %sub_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%sub_src:imm16 := CX:imm16")
      assert_string(
        stmts[3].to_string(),
        "%sub_res:imm16 := (%sub_dst:imm16 - %sub_src:imm16)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sub_a:imm32, %sub_res:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 5, "%sub_dst:imm16", "%sub_src:imm16", "%sub_res:imm16", "0:16u",
        false,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub8_rm = basic_bil_decode("x86", b"\x2a\x4d\xfc", start=0x7031UL)
  match sub8_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm8 := CL:imm8")
      assert_string(
        stmts[1].to_string(),
        "%sub_src:imm8 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "CL:imm8 := (%sub_dst:imm8 - %sub_src:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm8", "%sub_src:imm8", "CL:imm8", "0:8u", false,
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory adc-sbb immediates" {
  let adc64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x83\x55\xf8\x01",
    start=0x702eUL,
  )
  match adc64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%adc_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%adc_dst:imm64 := load(mem:mem64x8, %adc_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%adc_src:imm64 := 1:64u")
      assert_string(
        stmts[3].to_string(),
        "%adc_res:imm64 := ((%adc_dst:imm64 + %adc_src:imm64) + pad:64[CF:imm1])",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %adc_a:imm64, %adc_res:imm64)",
      )
      assert_true(stmts[5].to_string().contains("CF:imm1 := extract[64:64]"))
      assert_true(stmts[6].to_string().contains("OF:imm1 :="))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%adc_res:imm64]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:64u == %adc_res:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let sbb32_mem = basic_bil_decode("x86", b"\x83\x5d\xfc\x01", start=0x7033UL)
  match sbb32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sbb_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sbb_dst:imm32 := load(mem:mem32x8, %sbb_a:imm32):imm32",
      )
      assert_string(stmts[2].to_string(), "%sbb_src:imm32 := 1:32u")
      assert_string(
        stmts[3].to_string(),
        "%sbb_res:imm32 := (%sbb_dst:imm32 - (%sbb_src:imm32 + pad:32[CF:imm1]))",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sbb_a:imm32, %sbb_res:imm32)",
      )
      assert_true(stmts[5].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[6].to_string().contains("CF:imm1 := ("))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%sbb_res:imm32]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:32u == %sbb_res:imm32)",
      )
    }
    Err(reason) => fail(reason)
  }

  let adc16_mem = basic_bil_decode(
    "x86",
    b"\x66\x83\x55\xfc\x01",
    start=0x7034UL,
  )
  match adc16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%adc_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%adc_dst:imm16 := load(mem:mem32x8, %adc_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%adc_src:imm16 := 1:16u")
      assert_string(
        stmts[3].to_string(),
        "%adc_res:imm16 := ((%adc_dst:imm16 + %adc_src:imm16) + pad:16[CF:imm1])",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %adc_a:imm32, %adc_res:imm16)",
      )
      assert_true(stmts[5].to_string().contains("CF:imm1 := extract[16:16]"))
      assert_true(stmts[6].to_string().contains("OF:imm1 :="))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%adc_res:imm16]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:16u == %adc_res:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let sbb16_mem = basic_bil_decode(
    "x86",
    b"\x66\x81\x5d\xfc\x34\x12",
    start=0x7035UL,
  )
  match sbb16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sbb_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sbb_dst:imm16 := load(mem:mem32x8, %sbb_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%sbb_src:imm16 := 0x1234:16u")
      assert_string(
        stmts[3].to_string(),
        "%sbb_res:imm16 := (%sbb_dst:imm16 - (%sbb_src:imm16 + pad:16[CF:imm1]))",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sbb_a:imm32, %sbb_res:imm16)",
      )
      assert_true(stmts[5].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[6].to_string().contains("CF:imm1 := ("))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%sbb_res:imm16]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:16u == %sbb_res:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory adc-sbb rr operands" {
  let adc64_mr = basic_bil_decode("x86_64", b"\x48\x11\x4d\xf8", start=0x7038UL)
  match adc64_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%adc_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%adc_dst:imm64 := load(mem:mem64x8, %adc_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%adc_src:imm64 := RCX:imm64")
      assert_string(
        stmts[3].to_string(),
        "%adc_res:imm64 := ((%adc_dst:imm64 + %adc_src:imm64) + pad:64[CF:imm1])",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %adc_a:imm64, %adc_res:imm64)",
      )
      assert_true(stmts[5].to_string().contains("CF:imm1 := extract[64:64]"))
      assert_true(stmts[6].to_string().contains("OF:imm1 :="))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%adc_res:imm64]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:64u == %adc_res:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let adc64_rm = basic_bil_decode("x86_64", b"\x48\x13\x45\xf8", start=0x703aUL)
  match adc64_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%adc_dst:imm64 := RAX:imm64")
      assert_string(
        stmts[1].to_string(),
        "%adc_src:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := ((%adc_dst:imm64 + %adc_src:imm64) + pad:64[CF:imm1])",
      )
      assert_true(stmts[3].to_string().contains("CF:imm1 := extract[64:64]"))
      assert_true(stmts[4].to_string().contains("OF:imm1 :="))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[RAX:imm64]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:64u == RAX:imm64)")
    }
    Err(reason) => fail(reason)
  }

  let sbb32_rm = basic_bil_decode("x86", b"\x1b\x45\xfc", start=0x703cUL)
  match sbb32_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%sbb_src:imm32 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm32",
      )
      assert_string(stmts[1].to_string(), "%sbb_dst:imm32 := EAX:imm32")
      assert_string(
        stmts[2].to_string(),
        "EAX:imm32 := (%sbb_dst:imm32 - (%sbb_src:imm32 + pad:32[CF:imm1]))",
      )
      assert_true(stmts[3].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[4].to_string().contains("CF:imm1 := ("))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[EAX:imm32]")
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:32u == EAX:imm32)")
    }
    Err(reason) => fail(reason)
  }

  let adc16_mr = basic_bil_decode("x86", b"\x66\x11\x4d\xfc", start=0x703dUL)
  match adc16_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%adc_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%adc_dst:imm16 := load(mem:mem32x8, %adc_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%adc_src:imm16 := CX:imm16")
      assert_string(
        stmts[3].to_string(),
        "%adc_res:imm16 := ((%adc_dst:imm16 + %adc_src:imm16) + pad:16[CF:imm1])",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %adc_a:imm32, %adc_res:imm16)",
      )
      assert_true(stmts[5].to_string().contains("CF:imm1 := extract[16:16]"))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%adc_res:imm16]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:16u == %adc_res:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let sbb32_mr = basic_bil_decode("x86", b"\x19\x4d\xfc", start=0x703eUL)
  match sbb32_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%sbb_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%sbb_dst:imm32 := load(mem:mem32x8, %sbb_a:imm32):imm32",
      )
      assert_string(stmts[2].to_string(), "%sbb_src:imm32 := ECX:imm32")
      assert_string(
        stmts[3].to_string(),
        "%sbb_res:imm32 := (%sbb_dst:imm32 - (%sbb_src:imm32 + pad:32[CF:imm1]))",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %sbb_a:imm32, %sbb_res:imm32)",
      )
      assert_true(stmts[5].to_string().contains("OF:imm1 := high:1"))
      assert_true(stmts[6].to_string().contains("CF:imm1 := ("))
      assert_string(stmts[9].to_string(), "SF:imm1 := high:1[%sbb_res:imm32]")
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:32u == %sbb_res:imm32)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory logical rr operands" {
  let or64_mr = basic_bil_decode("x86_64", b"\x48\x09\x4d\xf8", start=0x7040UL)
  match or64_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm64 := load(mem:mem64x8, %logic_a:imm64):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm64 := (%logic_d:imm64 | RCX:imm64)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %logic_a:imm64, %logic_r:imm64)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let and64_rm = basic_bil_decode("x86_64", b"\x48\x23\x45\xf8", start=0x7044UL)
  match and64_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "RAX:imm64 := (RAX:imm64 & load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64)",
      )
      assert_logical_flag_tail(stmts, 1, "RAX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let xor32_mr = basic_bil_decode("x86", b"\x31\x4d\xfc", start=0x7048UL)
  match xor32_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm32 := load(mem:mem32x8, %logic_a:imm32):imm32",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm32 := (%logic_d:imm32 ^ ECX:imm32)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %logic_a:imm32, %logic_r:imm32)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm32", "0:32u")
    }
    Err(reason) => fail(reason)
  }

  let xor16_mr = basic_bil_decode("x86", b"\x66\x31\x4d\xfc", start=0x704aUL)
  match xor16_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm16 := load(mem:mem32x8, %logic_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm16 := (%logic_d:imm16 ^ CX:imm16)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %logic_a:imm32, %logic_r:imm16)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm16", "0:16u")
    }
    Err(reason) => fail(reason)
  }

  let or8_rm = basic_bil_decode("x86", b"\x0a\x4d\xfc", start=0x704cUL)
  match or8_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "CL:imm8 := (CL:imm8 | load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8)",
      )
      assert_logical_flag_tail(stmts, 1, "CL:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory logical and cmp immediates" {
  let or8_mem = basic_bil_decode(
    "x86_64",
    b"\x41\x80\x48\x01\x0f",
    start=0x702eUL,
  )
  match or8_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm64 := (R8:imm64 + 1:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm8 := load(mem:mem64x8, %logic_a:imm64):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm8 := (%logic_d:imm8 | 0xF:8u)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %logic_a:imm64, %logic_r:imm8)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }

  let xor32_mem = basic_bil_decode("x86", b"\x83\x75\xfc\xff", start=0x7033UL)
  match xor32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm32 := load(mem:mem32x8, %logic_a:imm32):imm32",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm32 := (%logic_d:imm32 ^ 0xFFFFFFFF:32u)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %logic_a:imm32, %logic_r:imm32)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm32", "0:32u")
    }
    Err(reason) => fail(reason)
  }

  let xor16_mem = basic_bil_decode(
    "x86",
    b"\x66\x83\x75\xfc\xff",
    start=0x7035UL,
  )
  match xor16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(
        stmts[0].to_string(),
        "%logic_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%logic_d:imm16 := load(mem:mem32x8, %logic_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%logic_r:imm16 := (%logic_d:imm16 ^ 0xFFFF:16u)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %logic_a:imm32, %logic_r:imm16)",
      )
      assert_logical_flag_tail(stmts, 4, "%logic_r:imm16", "0:16u")
    }
    Err(reason) => fail(reason)
  }

  let cmp32_mem = basic_bil_decode("x86", b"\x83\x7d\xfc\x01", start=0x7037UL)
  match cmp32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%cmp_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%cmp_d:imm32 := load(mem:mem32x8, %cmp_a:imm32):imm32",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmp_tmp:imm32 := (%cmp_d:imm32 - 1:32u)",
      )
      assert_string(stmts[3].to_string(), "CF:imm1 := (%cmp_d:imm32 < 1:32u)")
      assert_true(stmts[4].to_string().contains("OF:imm1 := high:1"))
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:32u == %cmp_tmp:imm32)",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmp16_mem = basic_bil_decode(
    "x86",
    b"\x66\x83\x7d\xfc\x01",
    start=0x7039UL,
  )
  match cmp16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%cmp_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%cmp_d:imm16 := load(mem:mem32x8, %cmp_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmp_tmp:imm16 := (%cmp_d:imm16 - 1:16u)",
      )
      assert_string(stmts[3].to_string(), "CF:imm1 := (%cmp_d:imm16 < 1:16u)")
      assert_true(stmts[4].to_string().contains("OF:imm1 := high:1"))
      assert_string(stmts[7].to_string(), "SF:imm1 := high:1[%cmp_tmp:imm16]")
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:16u == %cmp_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register inc-dec ops" {
  let inc64 = basic_bil_decode("x86_64", b"\x48\xff\xc0", start=0x7022UL)
  match inc64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%inc_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%inc_src:imm64 := 1:64u")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%inc_dst:imm64 + %inc_src:imm64)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%inc_dst:imm64", "%inc_src:imm64", "RAX:imm64", "0:64u",
      )
    }
    Err(reason) => fail(reason)
  }

  let inc64_ext = basic_bil_decode("x86_64", b"\x49\xff\xc0", start=0x7025UL)
  match inc64_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%inc_dst:imm64 := R8:imm64")
      assert_string(stmts[1].to_string(), "%inc_src:imm64 := 1:64u")
      assert_string(
        stmts[2].to_string(),
        "R8:imm64 := (%inc_dst:imm64 + %inc_src:imm64)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%inc_dst:imm64", "%inc_src:imm64", "R8:imm64", "0:64u",
      )
    }
    Err(reason) => fail(reason)
  }

  let dec32 = basic_bil_decode("x86", b"\x49", start=0x7028UL)
  match dec32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%dec_dst:imm32 := ECX:imm32")
      assert_string(stmts[1].to_string(), "%dec_src:imm32 := 1:32u")
      assert_string(
        stmts[2].to_string(),
        "ECX:imm32 := (%dec_dst:imm32 - %dec_src:imm32)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%dec_dst:imm32", "%dec_src:imm32", "ECX:imm32", "0:32u",
      )
    }
    Err(reason) => fail(reason)
  }

  let inc16 = basic_bil_decode("x86", b"\x66\x40", start=0x7028UL)
  match inc16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%inc_dst:imm16 := AX:imm16")
      assert_string(stmts[1].to_string(), "%inc_src:imm16 := 1:16u")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := (%inc_dst:imm16 + %inc_src:imm16)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%inc_dst:imm16", "%inc_src:imm16", "AX:imm16", "0:16u",
      )
    }
    Err(reason) => fail(reason)
  }

  let dec32_ext = basic_bil_decode("x86_64", b"\x41\xff\xc8", start=0x7029UL)
  match dec32_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%dec_dst:imm32 := R8D:imm32")
      assert_string(stmts[1].to_string(), "%dec_src:imm32 := 1:32u")
      assert_string(
        stmts[2].to_string(),
        "R8D:imm32 := (%dec_dst:imm32 - %dec_src:imm32)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%dec_dst:imm32", "%dec_src:imm32", "R8D:imm32", "0:32u",
      )
    }
    Err(reason) => fail(reason)
  }

  let dec16_modrm = basic_bil_decode("x86", b"\x66\xff\xc8", start=0x702aUL)
  match dec16_modrm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%dec_dst:imm16 := AX:imm16")
      assert_string(stmts[1].to_string(), "%dec_src:imm16 := 1:16u")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := (%dec_dst:imm16 - %dec_src:imm16)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%dec_dst:imm16", "%dec_src:imm16", "AX:imm16", "0:16u",
      )
    }
    Err(reason) => fail(reason)
  }

  let inc8 = basic_bil_decode("x86", b"\xfe\xc4", start=0x702aUL)
  match inc8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%inc_dst:imm8 := AH:imm8")
      assert_string(stmts[1].to_string(), "%inc_src:imm8 := 1:8u")
      assert_string(
        stmts[2].to_string(),
        "AH:imm8 := (%inc_dst:imm8 + %inc_src:imm8)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%inc_dst:imm8", "%inc_src:imm8", "AH:imm8", "0:8u",
      )
    }
    Err(reason) => fail(reason)
  }

  let dec8_ext = basic_bil_decode("x86_64", b"\x41\xfe\xc8", start=0x702bUL)
  match dec8_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%dec_dst:imm8 := R8B:imm8")
      assert_string(stmts[1].to_string(), "%dec_src:imm8 := 1:8u")
      assert_string(
        stmts[2].to_string(),
        "R8B:imm8 := (%dec_dst:imm8 - %dec_src:imm8)",
      )
      assert_incdec_flag_tail(
        stmts, 3, "%dec_dst:imm8", "%dec_src:imm8", "R8B:imm8", "0:8u",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory inc-dec ops" {
  let inc64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xff\x45\xf8",
    start=0x702cUL,
  )
  match inc64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%inc_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%inc_dst:imm64 := load(mem:mem64x8, %inc_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%inc_src:imm64 := 1:64u")
      assert_string(
        stmts[3].to_string(),
        "%inc_res:imm64 := (%inc_dst:imm64 + %inc_src:imm64)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %inc_a:imm64, %inc_res:imm64)",
      )
      assert_incdec_flag_tail(
        stmts, 5, "%inc_dst:imm64", "%inc_src:imm64", "%inc_res:imm64", "0:64u",
      )
    }
    Err(reason) => fail(reason)
  }

  let dec32_mem = basic_bil_decode("x86", b"\xff\x4d\xfc", start=0x7030UL)
  match dec32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%dec_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%dec_dst:imm32 := load(mem:mem32x8, %dec_a:imm32):imm32",
      )
      assert_string(stmts[2].to_string(), "%dec_src:imm32 := 1:32u")
      assert_string(
        stmts[3].to_string(),
        "%dec_res:imm32 := (%dec_dst:imm32 - %dec_src:imm32)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %dec_a:imm32, %dec_res:imm32)",
      )
      assert_incdec_flag_tail(
        stmts, 5, "%dec_dst:imm32", "%dec_src:imm32", "%dec_res:imm32", "0:32u",
      )
    }
    Err(reason) => fail(reason)
  }

  let inc16_mem = basic_bil_decode("x86", b"\x66\xff\x45\xfc", start=0x7031UL)
  match inc16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%inc_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%inc_dst:imm16 := load(mem:mem32x8, %inc_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%inc_src:imm16 := 1:16u")
      assert_string(
        stmts[3].to_string(),
        "%inc_res:imm16 := (%inc_dst:imm16 + %inc_src:imm16)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %inc_a:imm32, %inc_res:imm16)",
      )
      assert_incdec_flag_tail(
        stmts, 5, "%inc_dst:imm16", "%inc_src:imm16", "%inc_res:imm16", "0:16u",
      )
    }
    Err(reason) => fail(reason)
  }

  let inc8_mem = basic_bil_decode("x86_64", b"\x41\xfe\x40\x01", start=0x7033UL)
  match inc8_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%inc_a:imm64 := (R8:imm64 + 1:64u)")
      assert_string(
        stmts[1].to_string(),
        "%inc_dst:imm8 := load(mem:mem64x8, %inc_a:imm64):imm8",
      )
      assert_string(stmts[2].to_string(), "%inc_src:imm8 := 1:8u")
      assert_string(
        stmts[3].to_string(),
        "%inc_res:imm8 := (%inc_dst:imm8 + %inc_src:imm8)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %inc_a:imm64, %inc_res:imm8)",
      )
      assert_incdec_flag_tail(
        stmts, 5, "%inc_dst:imm8", "%inc_src:imm8", "%inc_res:imm8", "0:8u",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register not-neg ops" {
  let not64 = basic_bil_decode("x86_64", b"\x48\xf7\xd0", start=0x702cUL)
  match not64.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := (not RAX:imm64)"])
    Err(reason) => fail(reason)
  }

  let not64_ext = basic_bil_decode("x86_64", b"\x49\xf7\xd0", start=0x702fUL)
  match not64_ext.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8:imm64 := (not R8:imm64)"])
    Err(reason) => fail(reason)
  }

  let neg32 = basic_bil_decode("x86", b"\xf7\xd9", start=0x7032UL)
  match neg32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%neg_dst:imm32 := ECX:imm32")
      assert_string(
        stmts[1].to_string(),
        "ECX:imm32 := (0:32u - %neg_dst:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 2, "0:32u", "%neg_dst:imm32", "ECX:imm32", "0:32u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let neg32_ext = basic_bil_decode("x86_64", b"\x41\xf7\xd8", start=0x7034UL)
  match neg32_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%neg_dst:imm32 := R8D:imm32")
      assert_string(
        stmts[1].to_string(),
        "R8D:imm32 := (0:32u - %neg_dst:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 2, "0:32u", "%neg_dst:imm32", "R8D:imm32", "0:32u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let not8 = basic_bil_decode("x86", b"\xf6\xd0", start=0x7036UL)
  match not8.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AL:imm8 := (not AL:imm8)"])
    Err(reason) => fail(reason)
  }

  let not16 = basic_bil_decode("x86", b"\x66\xf7\xd0", start=0x7037UL)
  match not16.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AX:imm16 := (not AX:imm16)"])
    Err(reason) => fail(reason)
  }

  let neg16 = basic_bil_decode("x86", b"\x66\xf7\xd9", start=0x7038UL)
  match neg16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%neg_dst:imm16 := CX:imm16")
      assert_string(
        stmts[1].to_string(),
        "CX:imm16 := (0:16u - %neg_dst:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 2, "0:16u", "%neg_dst:imm16", "CX:imm16", "0:16u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let neg8_ext = basic_bil_decode("x86_64", b"\x41\xf6\xd8", start=0x7038UL)
  match neg8_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%neg_dst:imm8 := R8B:imm8")
      assert_string(stmts[1].to_string(), "R8B:imm8 := (0:8u - %neg_dst:imm8)")
      assert_addsub_flag_tail(
        stmts, 2, "0:8u", "%neg_dst:imm8", "R8B:imm8", "0:8u", false,
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory not-neg ops" {
  let not64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xf7\x55\xf8",
    start=0x7039UL,
  )
  match not64_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%unop_a:imm64 := (RBP:imm64 - 8:64u)", "%unop_d:imm64 := load(mem:mem64x8, %unop_a:imm64):imm64",
        "mem:mem64x8 := store(mem:mem64x8, %unop_a:imm64, (not %unop_d:imm64))",
      ])
    Err(reason) => fail(reason)
  }

  let neg32_mem = basic_bil_decode("x86", b"\xf7\x5d\xfc", start=0x703dUL)
  match neg32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%neg_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%neg_dst:imm32 := load(mem:mem32x8, %neg_a:imm32):imm32",
      )
      assert_string(
        stmts[2].to_string(),
        "%neg_res:imm32 := (0:32u - %neg_dst:imm32)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %neg_a:imm32, %neg_res:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 4, "0:32u", "%neg_dst:imm32", "%neg_res:imm32", "0:32u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let neg16_mem = basic_bil_decode("x86", b"\x66\xf7\x5d\xfc", start=0x703fUL)
  match neg16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%neg_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%neg_dst:imm16 := load(mem:mem32x8, %neg_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%neg_res:imm16 := (0:16u - %neg_dst:imm16)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %neg_a:imm32, %neg_res:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 4, "0:16u", "%neg_dst:imm16", "%neg_res:imm16", "0:16u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let neg8_mem = basic_bil_decode("x86_64", b"\x41\xf6\x58\x01", start=0x7040UL)
  match neg8_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%neg_a:imm64 := (R8:imm64 + 1:64u)")
      assert_string(
        stmts[1].to_string(),
        "%neg_dst:imm8 := load(mem:mem64x8, %neg_a:imm64):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "%neg_res:imm8 := (0:8u - %neg_dst:imm8)",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %neg_a:imm64, %neg_res:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 4, "0:8u", "%neg_dst:imm8", "%neg_res:imm8", "0:8u", false,
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register shift ops" {
  let shl8_one = basic_bil_decode("x86", b"\xd0\xe0", start=0x703aUL)
  match shl8_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm8 := AL:imm8")
      let count = "(1:8u & 0x1F:8u)"
      let result = "AL:imm8"
      assert_string(
        stmts[1].to_string(),
        "AL:imm8 := (%shift_was:imm8 << " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm8 >> (8:8u - \{count}))]",
        count,
        "1:8u",
        result,
        "0:8u",
        "OF:imm1 := high:1[(%shift_was:imm8 ^ AL:imm8)]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shr32_cl = basic_bil_decode("x86", b"\xd3\xe8", start=0x703cUL)
  match shr32_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm32 := EAX:imm32")
      let count = "(CL:imm8 & 0x1F:8u)"
      let result = "EAX:imm32"
      assert_string(
        stmts[1].to_string(),
        "EAX:imm32 := (%shift_was:imm32 >> " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm32 >> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:32u",
        "OF:imm1 := high:1[%shift_was:imm32]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shl16_one = basic_bil_decode("x86", b"\x66\xd1\xe0", start=0x703dUL)
  match shl16_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm16 := AX:imm16")
      let count = "(1:16u & 0x1F:16u)"
      let result = "AX:imm16"
      assert_string(
        stmts[1].to_string(),
        "AX:imm16 := (%shift_was:imm16 << " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:16u)",
        "CF:imm1 := low:1[(%shift_was:imm16 >> (0x10:16u - \{count}))]",
        count,
        "1:16u",
        result,
        "0:16u",
        "OF:imm1 := high:1[(%shift_was:imm16 ^ AX:imm16)]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shr16_cl = basic_bil_decode("x86", b"\x66\xd3\xe8", start=0x703dUL)
  match shr16_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm16 := AX:imm16")
      let count = "(CL:imm8 & 0x1F:8u)"
      let result = "AX:imm16"
      assert_string(
        stmts[1].to_string(),
        "AX:imm16 := (%shift_was:imm16 >> " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm16 >> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:16u",
        "OF:imm1 := high:1[%shift_was:imm16]",
      )
    }
    Err(reason) => fail(reason)
  }

  let sar8_imm = basic_bil_decode("x86", b"\xc0\xfc\x03", start=0x703eUL)
  match sar8_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm8 := AH:imm8")
      let count = "(3:8u & 0x1F:8u)"
      let result = "AH:imm8"
      assert_string(
        stmts[1].to_string(),
        "AH:imm8 := (%shift_was:imm8 a>> " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm8 a>> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:8u",
        "OF:imm1 := 0:1u",
      )
    }
    Err(reason) => fail(reason)
  }

  let shr64_cl = basic_bil_decode("x86_64", b"\x49\xd3\xe8", start=0x7041UL)
  match shr64_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm64 := R8:imm64")
      let count = "(CL:imm8 & 0x3F:8u)"
      let result = "R8:imm64"
      assert_string(
        stmts[1].to_string(),
        "R8:imm64 := (%shift_was:imm64 >> " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm64 >> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:64u",
        "OF:imm1 := high:1[%shift_was:imm64]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shl8_rex = basic_bil_decode("x86_64", b"\x40\xd0\xe4", start=0x7044UL)
  match shl8_rex.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shift_was:imm8 := SPL:imm8")
      let count = "(1:8u & 0x1F:8u)"
      let result = "SPL:imm8"
      assert_string(
        stmts[1].to_string(),
        "SPL:imm8 := (%shift_was:imm8 << " + count + ")",
      )
      assert_shift_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_was:imm8 >> (8:8u - \{count}))]",
        count,
        "1:8u",
        result,
        "0:8u",
        "OF:imm1 := high:1[(%shift_was:imm8 ^ SPL:imm8)]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shl64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xd1\x65\xf8",
    start=0x7045UL,
  )
  match shl64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%shift_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shift_d:imm64 := load(mem:mem64x8, %shift_a:imm64):imm64",
      )
      let count = "(1:64u & 0x3F:64u)"
      let result = "%shift_res:imm64"
      assert_string(
        stmts[2].to_string(),
        result + " := (%shift_d:imm64 << " + count + ")",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %shift_a:imm64, %shift_res:imm64)",
      )
      assert_shift_flag_update(
        stmts[4],
        "(\{count} != 0:64u)",
        "CF:imm1 := low:1[(%shift_d:imm64 >> (0x40:64u - \{count}))]",
        count,
        "1:64u",
        result,
        "0:64u",
        "OF:imm1 := high:1[(%shift_d:imm64 ^ %shift_res:imm64)]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shr32_mem_cl = basic_bil_decode("x86", b"\xd3\x6d\xfc", start=0x7049UL)
  match shr32_mem_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%shift_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shift_d:imm32 := load(mem:mem32x8, %shift_a:imm32):imm32",
      )
      let count = "(CL:imm8 & 0x1F:8u)"
      let result = "%shift_res:imm32"
      assert_string(
        stmts[2].to_string(),
        result + " := (%shift_d:imm32 >> " + count + ")",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %shift_a:imm32, %shift_res:imm32)",
      )
      assert_shift_flag_update(
        stmts[4],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_d:imm32 >> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:32u",
        "OF:imm1 := high:1[%shift_d:imm32]",
      )
    }
    Err(reason) => fail(reason)
  }

  let shl16_mem = basic_bil_decode("x86", b"\x66\xd1\x65\xfc", start=0x704aUL)
  match shl16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%shift_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shift_d:imm16 := load(mem:mem32x8, %shift_a:imm32):imm16",
      )
      let count = "(1:16u & 0x1F:16u)"
      let result = "%shift_res:imm16"
      assert_string(
        stmts[2].to_string(),
        result + " := (%shift_d:imm16 << " + count + ")",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %shift_a:imm32, %shift_res:imm16)",
      )
      assert_shift_flag_update(
        stmts[4],
        "(\{count} != 0:16u)",
        "CF:imm1 := low:1[(%shift_d:imm16 >> (0x10:16u - \{count}))]",
        count,
        "1:16u",
        result,
        "0:16u",
        "OF:imm1 := high:1[(%shift_d:imm16 ^ %shift_res:imm16)]",
      )
    }
    Err(reason) => fail(reason)
  }

  let sar8_mem_imm = basic_bil_decode(
    "x86_64",
    b"\x41\xc0\x78\x01\x04",
    start=0x704cUL,
  )
  match sar8_mem_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%shift_a:imm64 := (R8:imm64 + 1:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shift_d:imm8 := load(mem:mem64x8, %shift_a:imm64):imm8",
      )
      let count = "(4:8u & 0x1F:8u)"
      let result = "%shift_res:imm8"
      assert_string(
        stmts[2].to_string(),
        result + " := (%shift_d:imm8 a>> " + count + ")",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %shift_a:imm64, %shift_res:imm8)",
      )
      assert_shift_flag_update(
        stmts[4],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[(%shift_d:imm8 a>> (\{count} - 1:8u))]",
        count,
        "1:8u",
        result,
        "0:8u",
        "OF:imm1 := 0:1u",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 shld-shrd ops" {
  let shld32 = basic_bil_decode("x86", b"\x0f\xa4\xc8\x04", start=0x7045UL)
  match shld32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shiftd_was:imm32 := EAX:imm32")
      let result = "((ECX:imm32 >> (0x20:32u - (4:32u & 0x1F:32u))) | (%shiftd_was:imm32 << (4:32u & 0x1F:32u)))"
      assert_string(stmts[1].to_string(), "EAX:imm32 := " + result)
      match stmts[2] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((4:32u & 0x1F:32u) != 0:32u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := low:1[(%shiftd_was:imm32 >> (0x20:32u - (4:32u & 0x1F:32u)))]",
          )
          assert_string(yes[1].to_string(), "SF:imm1 := high:1[" + result + "]")
          assert_string(
            yes[2].to_string(),
            "ZF:imm1 := (0:32u == " + result + ")",
          )
          assert_true(yes[3].to_string().has_prefix("PF:imm1 := "))
          match yes[4] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "((4:32u & 0x1F:32u) == 1:32u)")
              assert_true(yes.length() == 1)
              assert_string(
                yes[0].to_string(),
                "OF:imm1 := high:1[(%shiftd_was:imm32 ^ " + result + ")]",
              )
              assert_true(no.length() == 1)
              assert_string(
                no[0].to_string(),
                "OF:imm1 := unknown(OF undefined after shiftd of more then 1 bit:imm1)",
              )
            }
            _ => fail("SHLD32 OF update did not lift to BIL if")
          }
        }
        _ => fail("SHLD32 flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shld16 = basic_bil_decode("x86", b"\x66\x0f\xa4\xc8\x04", start=0x7046UL)
  match shld16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shiftd_was:imm16 := AX:imm16")
      let result = "((CX:imm16 >> (0x10:16u - (4:16u & 0x1F:16u))) | (%shiftd_was:imm16 << (4:16u & 0x1F:16u)))"
      assert_string(stmts[1].to_string(), "AX:imm16 := " + result)
      match stmts[2] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((4:16u & 0x1F:16u) != 0:16u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := low:1[(%shiftd_was:imm16 >> (0x10:16u - (4:16u & 0x1F:16u)))]",
          )
          assert_string(yes[1].to_string(), "SF:imm1 := high:1[" + result + "]")
          assert_string(
            yes[2].to_string(),
            "ZF:imm1 := (0:16u == " + result + ")",
          )
          assert_true(yes[3].to_string().has_prefix("PF:imm1 := "))
          match yes[4] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "((4:16u & 0x1F:16u) == 1:16u)")
              assert_true(yes.length() == 1)
              assert_string(
                yes[0].to_string(),
                "OF:imm1 := high:1[(%shiftd_was:imm16 ^ " + result + ")]",
              )
              assert_true(no.length() == 1)
              assert_string(
                no[0].to_string(),
                "OF:imm1 := unknown(OF undefined after shiftd of more then 1 bit:imm1)",
              )
            }
            _ => fail("SHLD16 OF update did not lift to BIL if")
          }
        }
        _ => fail("SHLD16 flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shrd16 = basic_bil_decode("x86", b"\x66\x0f\xac\xd0\x03", start=0x7047UL)
  match shrd16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shiftd_was:imm16 := AX:imm16")
      let result = "((DX:imm16 << (0x10:16u - (3:16u & 0x1F:16u))) | (%shiftd_was:imm16 >> (3:16u & 0x1F:16u)))"
      assert_string(stmts[1].to_string(), "AX:imm16 := " + result)
      match stmts[2] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((3:16u & 0x1F:16u) != 0:16u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := high:1[(%shiftd_was:imm16 << (0x10:16u - (3:16u & 0x1F:16u)))]",
          )
          assert_string(yes[1].to_string(), "SF:imm1 := high:1[" + result + "]")
          match yes[4] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "((3:16u & 0x1F:16u) == 1:16u)")
              assert_true(yes.length() == 1)
              assert_true(no.length() == 1)
            }
            _ => fail("SHRD16 OF update did not lift to BIL if")
          }
        }
        _ => fail("SHRD16 flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shrd64 = basic_bil_decode("x86_64", b"\x4d\x0f\xad\xc8", start=0x7047UL)
  match shrd64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      assert_string(stmts[0].to_string(), "%shiftd_was:imm64 := R8:imm64")
      assert_true(
        stmts[1]
        .to_string()
        .contains(
          "R8:imm64 := ((R9:imm64 << (0x40:8u - (CL:imm8 & 0x3F:8u))) | (%shiftd_was:imm64 >> (CL:imm8 & 0x3F:8u)))",
        ),
      )
      match stmts[2] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((CL:imm8 & 0x3F:8u) != 0:8u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := high:1[(%shiftd_was:imm64 << (0x40:8u - (CL:imm8 & 0x3F:8u)))]",
          )
          match yes[4] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "((CL:imm8 & 0x3F:8u) == 1:8u)")
              assert_true(yes.length() == 1)
              assert_true(no.length() == 1)
            }
            _ => fail("SHRD64 OF update did not lift to BIL if")
          }
        }
        _ => fail("SHRD64 flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shld16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xa5\x4d\xfc",
    start=0x7048UL,
  )
  match shld16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 4)
      assert_string(
        stmts[0].to_string(),
        "%shiftd_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shiftd_was:imm16 := load(mem:mem32x8, %shiftd_a:imm32):imm16",
      )
      assert_true(
        stmts[2]
        .to_string()
        .contains(
          "mem:mem32x8 := store(mem:mem32x8, %shiftd_a:imm32, ((CX:imm16 >> (0x10:8u - (CL:imm8 & 0x1F:8u))) | (%shiftd_was:imm16 << (CL:imm8 & 0x1F:8u))))",
        ),
      )
      match stmts[3] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((CL:imm8 & 0x1F:8u) != 0:8u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := low:1[(%shiftd_was:imm16 >> (0x10:8u - (CL:imm8 & 0x1F:8u)))]",
          )
        }
        _ => fail("SHLD16 memory flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shrd16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xac\x55\xfc\x05",
    start=0x7049UL,
  )
  match shrd16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 4)
      assert_string(
        stmts[0].to_string(),
        "%shiftd_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shiftd_was:imm16 := load(mem:mem32x8, %shiftd_a:imm32):imm16",
      )
      assert_true(
        stmts[2]
        .to_string()
        .contains(
          "mem:mem32x8 := store(mem:mem32x8, %shiftd_a:imm32, ((DX:imm16 << (0x10:16u - (5:16u & 0x1F:16u))) | (%shiftd_was:imm16 >> (5:16u & 0x1F:16u))))",
        ),
      )
      match stmts[3] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((5:16u & 0x1F:16u) != 0:16u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
          assert_string(
            yes[0].to_string(),
            "CF:imm1 := high:1[(%shiftd_was:imm16 << (0x10:16u - (5:16u & 0x1F:16u)))]",
          )
        }
        _ => fail("SHRD16 memory flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let shrd64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xac\x55\xf8\x05",
    start=0x7049UL,
  )
  match shrd64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 4)
      assert_string(
        stmts[0].to_string(),
        "%shiftd_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%shiftd_was:imm64 := load(mem:mem64x8, %shiftd_a:imm64):imm64",
      )
      assert_true(
        stmts[2]
        .to_string()
        .contains(
          "mem:mem64x8 := store(mem:mem64x8, %shiftd_a:imm64, ((RDX:imm64 << (0x40:64u - (5:64u & 0x3F:64u))) | (%shiftd_was:imm64 >> (5:64u & 0x3F:64u))))",
        ),
      )
      match stmts[3] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "((5:64u & 0x3F:64u) != 0:64u)")
          assert_true(no.is_empty())
          assert_true(yes.length() == 5)
        }
        _ => fail("SHRD64 memory flag update did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 mxcsr ops" {
  let ldmxcsr32 = basic_bil_decode("x86", b"\x0f\xae\x55\xfc", start=0x704aUL)
  match ldmxcsr32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "MXCSR:imm32 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let stmxcsr64 = basic_bil_decode(
    "x86_64",
    b"\x0f\xae\x5d\xf8",
    start=0x704eUL,
  )
  match stmxcsr64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), MXCSR:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let ldmxcsr64_ext = basic_bil_decode(
    "x86_64",
    b"\x41\x0f\xae\x50\x10",
    start=0x7052UL,
  )
  match ldmxcsr64_ext.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "MXCSR:imm32 := load(mem:mem64x8, (R8:imm64 + 0x10:64u)):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let fldcw32 = basic_bil_decode("x86", b"\xd9\x6d\xfc", start=0x7053UL)
  match fldcw32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "FPU_CONTROL:imm16 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16",
      ])
    Err(reason) => fail(reason)
  }

  let fnstcw64 = basic_bil_decode("x86_64", b"\xd9\x7d\xf8", start=0x7054UL)
  match fnstcw64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), FPU_CONTROL:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let fldcw64_ext = basic_bil_decode(
    "x86_64",
    b"\x41\xd9\x68\x10",
    start=0x7055UL,
  )
  match fldcw64_ext.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "FPU_CONTROL:imm16 := load(mem:mem64x8, (R8:imm64 + 0x10:64u)):imm16",
      ])
    Err(reason) => fail(reason)
  }

  let clflush = basic_bil_decode(
    "x86_64",
    b"\x41\x0f\xae\x78\x10",
    start=0x7054UL,
  )
  match clflush.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let clflushopt = basic_bil_decode(
    "x86_64",
    b"\x66\x41\x0f\xae\x78\x10",
    start=0x7059UL,
  )
  match clflushopt.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let clwb = basic_bil_decode(
    "x86_64",
    b"\x66\x41\x0f\xae\x70\x10",
    start=0x705fUL,
  )
  match clwb.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let prefetch = basic_bil_decode(
    "x86_64",
    b"\x41\x0f\x18\x48\x10",
    start=0x7065UL,
  )
  match prefetch.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }

  let prefetchw = basic_bil_decode(
    "x86_64",
    b"\x41\x0f\x0d\x48\x10",
    start=0x706aUL,
  )
  match prefetchw.project_basic_bil_lift() {
    Ok(stmts) => assert_true(stmts.is_empty())
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 cmpxchg ops" {
  let cmpxchg32 = basic_bil_decode("x86", b"\x0f\xb1\xcb", start=0x7056UL)
  match cmpxchg32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_tmp:imm32 := (EAX:imm32 - EBX:imm32)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (EAX:imm32 < EBX:imm32)")
      assert_true(stmts[4].to_string().has_prefix("PF:imm1 := "))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:32u == %cmpxchg_tmp:imm32)",
      )
      assert_string(
        stmts[7].to_string(),
        "EBX:imm32 := ite(ZF:imm1, ECX:imm32, EBX:imm32)",
      )
      assert_string(
        stmts[8].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmpxchg8 = basic_bil_decode("x86", b"\x0f\xb0\xcb", start=0x7057UL)
  match cmpxchg8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_tmp:imm8 := (AL:imm8 - BL:imm8)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (AL:imm8 < BL:imm8)")
      assert_true(stmts[4].to_string().has_prefix("PF:imm1 := "))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:8u == %cmpxchg_tmp:imm8)",
      )
      assert_string(
        stmts[7].to_string(),
        "BL:imm8 := ite(ZF:imm1, CL:imm8, BL:imm8)",
      )
      assert_string(
        stmts[8].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmpxchg16 = basic_bil_decode("x86", b"\x66\x0f\xb1\xcb", start=0x7058UL)
  match cmpxchg16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_tmp:imm16 := (AX:imm16 - BX:imm16)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (AX:imm16 < BX:imm16)")
      assert_true(stmts[4].to_string().has_prefix("PF:imm1 := "))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:16u == %cmpxchg_tmp:imm16)",
      )
      assert_string(
        stmts[7].to_string(),
        "BX:imm16 := ite(ZF:imm1, CX:imm16, BX:imm16)",
      )
      assert_string(
        stmts[8].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmpxchg8_mem = basic_bil_decode(
    "x86_64",
    b"\x44\x0f\xb0\x45\xf8",
    start=0x7059UL,
  )
  match cmpxchg8_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmpxchg_d:imm8 := load(mem:mem64x8, %cmpxchg_a:imm64):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmpxchg_tmp:imm8 := (AL:imm8 - %cmpxchg_d:imm8)",
      )
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:8u == %cmpxchg_tmp:imm8)",
      )
      assert_string(
        stmts[9].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %cmpxchg_a:imm64, ite(ZF:imm1, R8B:imm8, %cmpxchg_d:imm8))",
      )
      assert_string(
        stmts[10].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmpxchg16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xb1\x4d\xfc",
    start=0x7059UL,
  )
  match cmpxchg16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmpxchg_d:imm16 := load(mem:mem32x8, %cmpxchg_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmpxchg_tmp:imm16 := (AX:imm16 - %cmpxchg_d:imm16)",
      )
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:16u == %cmpxchg_tmp:imm16)",
      )
      assert_string(
        stmts[9].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %cmpxchg_a:imm32, ite(ZF:imm1, CX:imm16, %cmpxchg_d:imm16))",
      )
      assert_string(
        stmts[10].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmpxchg64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xb1\x4d\xf8",
    start=0x7059UL,
  )
  match cmpxchg64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(
        stmts[0].to_string(),
        "%cmpxchg_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmpxchg_d:imm64 := load(mem:mem64x8, %cmpxchg_a:imm64):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmpxchg_tmp:imm64 := (RAX:imm64 - %cmpxchg_d:imm64)",
      )
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:64u == %cmpxchg_tmp:imm64)",
      )
      assert_string(
        stmts[9].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %cmpxchg_a:imm64, ite(ZF:imm1, RCX:imm64, %cmpxchg_d:imm64))",
      )
      assert_string(
        stmts[10].to_string(),
        "if ZF:imm1 then 0 stmts else 1 stmts",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 xadd ops" {
  let xadd32 = basic_bil_decode("x86", b"\x0f\xc1\xcb", start=0x705eUL)
  match xadd32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%xadd_src:imm32 := ECX:imm32")
      assert_string(stmts[1].to_string(), "%xadd_dst:imm32 := EBX:imm32")
      assert_string(
        stmts[2].to_string(),
        "%xadd_tmp:imm32 := (%xadd_dst:imm32 + %xadd_src:imm32)",
      )
      assert_string(stmts[3].to_string(), "ECX:imm32 := %xadd_dst:imm32")
      assert_string(stmts[4].to_string(), "EBX:imm32 := %xadd_tmp:imm32")
      assert_string(
        stmts[5].to_string(),
        "CF:imm1 := (%xadd_tmp:imm32 < %xadd_dst:imm32)",
      )
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:32u == %xadd_tmp:imm32)",
      )
    }
    Err(reason) => fail(reason)
  }

  let xadd8 = basic_bil_decode("x86", b"\x0f\xc0\xcb", start=0x705fUL)
  match xadd8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%xadd_src:imm8 := CL:imm8")
      assert_string(stmts[1].to_string(), "%xadd_dst:imm8 := BL:imm8")
      assert_string(
        stmts[2].to_string(),
        "%xadd_tmp:imm8 := (%xadd_dst:imm8 + %xadd_src:imm8)",
      )
      assert_string(stmts[3].to_string(), "CL:imm8 := %xadd_dst:imm8")
      assert_string(stmts[4].to_string(), "BL:imm8 := %xadd_tmp:imm8")
      assert_string(
        stmts[5].to_string(),
        "CF:imm1 := (%xadd_tmp:imm8 < %xadd_dst:imm8)",
      )
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:8u == %xadd_tmp:imm8)",
      )
    }
    Err(reason) => fail(reason)
  }

  let xadd16 = basic_bil_decode("x86", b"\x66\x0f\xc1\xcb", start=0x7060UL)
  match xadd16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 11)
      assert_string(stmts[0].to_string(), "%xadd_src:imm16 := CX:imm16")
      assert_string(stmts[1].to_string(), "%xadd_dst:imm16 := BX:imm16")
      assert_string(
        stmts[2].to_string(),
        "%xadd_tmp:imm16 := (%xadd_dst:imm16 + %xadd_src:imm16)",
      )
      assert_string(stmts[3].to_string(), "CX:imm16 := %xadd_dst:imm16")
      assert_string(stmts[4].to_string(), "BX:imm16 := %xadd_tmp:imm16")
      assert_string(
        stmts[5].to_string(),
        "CF:imm1 := (%xadd_tmp:imm16 < %xadd_dst:imm16)",
      )
      assert_string(
        stmts[10].to_string(),
        "ZF:imm1 := (0:16u == %xadd_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let xadd8_mem = basic_bil_decode(
    "x86_64",
    b"\x44\x0f\xc0\x45\xf8",
    start=0x7061UL,
  )
  match xadd8_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 12)
      assert_string(
        stmts[0].to_string(),
        "%xadd_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%xadd_dst:imm8 := load(mem:mem64x8, %xadd_a:imm64):imm8",
      )
      assert_string(stmts[2].to_string(), "%xadd_src:imm8 := R8B:imm8")
      assert_string(
        stmts[3].to_string(),
        "%xadd_tmp:imm8 := (%xadd_dst:imm8 + %xadd_src:imm8)",
      )
      assert_string(stmts[4].to_string(), "R8B:imm8 := %xadd_dst:imm8")
      assert_string(
        stmts[5].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %xadd_a:imm64, %xadd_tmp:imm8)",
      )
      assert_string(
        stmts[6].to_string(),
        "CF:imm1 := (%xadd_tmp:imm8 < %xadd_dst:imm8)",
      )
      assert_string(
        stmts[11].to_string(),
        "ZF:imm1 := (0:8u == %xadd_tmp:imm8)",
      )
    }
    Err(reason) => fail(reason)
  }

  let xadd16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xc1\x4d\xfc",
    start=0x7061UL,
  )
  match xadd16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 12)
      assert_string(
        stmts[0].to_string(),
        "%xadd_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%xadd_dst:imm16 := load(mem:mem32x8, %xadd_a:imm32):imm16",
      )
      assert_string(stmts[2].to_string(), "%xadd_src:imm16 := CX:imm16")
      assert_string(
        stmts[3].to_string(),
        "%xadd_tmp:imm16 := (%xadd_dst:imm16 + %xadd_src:imm16)",
      )
      assert_string(stmts[4].to_string(), "CX:imm16 := %xadd_dst:imm16")
      assert_string(
        stmts[5].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %xadd_a:imm32, %xadd_tmp:imm16)",
      )
      assert_string(
        stmts[6].to_string(),
        "CF:imm1 := (%xadd_tmp:imm16 < %xadd_dst:imm16)",
      )
      assert_string(
        stmts[11].to_string(),
        "ZF:imm1 := (0:16u == %xadd_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let xadd64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xc1\x4d\xf8",
    start=0x7061UL,
  )
  match xadd64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 12)
      assert_string(
        stmts[0].to_string(),
        "%xadd_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%xadd_dst:imm64 := load(mem:mem64x8, %xadd_a:imm64):imm64",
      )
      assert_string(stmts[2].to_string(), "%xadd_src:imm64 := RCX:imm64")
      assert_string(
        stmts[3].to_string(),
        "%xadd_tmp:imm64 := (%xadd_dst:imm64 + %xadd_src:imm64)",
      )
      assert_string(stmts[4].to_string(), "RCX:imm64 := %xadd_dst:imm64")
      assert_string(
        stmts[5].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %xadd_a:imm64, %xadd_tmp:imm64)",
      )
      assert_string(
        stmts[6].to_string(),
        "CF:imm1 := (%xadd_tmp:imm64 < %xadd_dst:imm64)",
      )
      assert_string(
        stmts[11].to_string(),
        "ZF:imm1 := (0:64u == %xadd_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 cmpxchg8b ops" {
  let cmpxchg8b = basic_bil_decode(
    "x86_64",
    b"\x0f\xc7\x4d\xf8",
    start=0x7066UL,
  )
  match cmpxchg8b.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%cmpxchg8b_a:imm64 := (RBP:imm64 - 8:64u)", "%cmpxchg8b_d:imm64 := load(mem:mem64x8, %cmpxchg8b_a:imm64):imm64",
        "%cmpxchg8b_eq:imm1 := (concat(EDX:imm32, EAX:imm32) == %cmpxchg8b_d:imm64)",
        "ZF:imm1 := %cmpxchg8b_eq:imm1", "mem:mem64x8 := store(mem:mem64x8, %cmpxchg8b_a:imm64, ite(%cmpxchg8b_eq:imm1, concat(ECX:imm32, EBX:imm32), %cmpxchg8b_d:imm64))",
        "if %cmpxchg8b_eq:imm1 then 0 stmts else 2 stmts",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 rotate ops" {
  let rol8_one = basic_bil_decode("x86", b"\xd0\xc0", start=0x7046UL)
  match rol8_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let masked = "(1:8u & 0x1F:8u)"
      let count = "(\{masked} % 8:8u)"
      assert_string(
        stmts[0].to_string(),
        "AL:imm8 := ((AL:imm8 << " +
        count +
        ") | (AL:imm8 >> (8:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{masked} != 0:8u)",
        "CF:imm1 := low:1[AL:imm8]",
        masked,
        "1:8u",
        "OF:imm1 := (high:1[AL:imm8] ^ low:1[AL:imm8])",
      )
    }
    Err(reason) => fail(reason)
  }

  let ror32_cl = basic_bil_decode("x86", b"\xd3\xc8", start=0x7048UL)
  match ror32_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let count = "(CL:imm8 & 0x1F:8u)"
      assert_string(
        stmts[0].to_string(),
        "EAX:imm32 := ((EAX:imm32 >> " +
        count +
        ") | (EAX:imm32 << (0x20:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[EAX:imm32]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[EAX:imm32] ^ high:1[(EAX:imm32 << 1:32u)])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rol16_one = basic_bil_decode("x86", b"\x66\xd1\xc0", start=0x7049UL)
  match rol16_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let masked = "(1:16u & 0x1F:16u)"
      let count = "(\{masked} % 0x10:16u)"
      assert_string(
        stmts[0].to_string(),
        "AX:imm16 := ((AX:imm16 << " +
        count +
        ") | (AX:imm16 >> (0x10:16u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{masked} != 0:16u)",
        "CF:imm1 := low:1[AX:imm16]",
        masked,
        "1:16u",
        "OF:imm1 := (high:1[AX:imm16] ^ low:1[AX:imm16])",
      )
    }
    Err(reason) => fail(reason)
  }

  let ror16_cl = basic_bil_decode("x86", b"\x66\xd3\xc8", start=0x7049UL)
  match ror16_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let masked = "(CL:imm8 & 0x1F:8u)"
      let count = "(\{masked} % 0x10:8u)"
      assert_string(
        stmts[0].to_string(),
        "AX:imm16 := ((AX:imm16 >> " +
        count +
        ") | (AX:imm16 << (0x10:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{masked} != 0:8u)",
        "CF:imm1 := high:1[AX:imm16]",
        masked,
        "1:8u",
        "OF:imm1 := (high:1[AX:imm16] ^ high:1[(AX:imm16 << 1:16u)])",
      )
    }
    Err(reason) => fail(reason)
  }

  let ror8_imm = basic_bil_decode("x86", b"\xc0\xcc\x03", start=0x704aUL)
  match ror8_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let masked = "(3:8u & 0x1F:8u)"
      let count = "(\{masked} % 8:8u)"
      assert_string(
        stmts[0].to_string(),
        "AH:imm8 := ((AH:imm8 >> " +
        count +
        ") | (AH:imm8 << (8:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{masked} != 0:8u)",
        "CF:imm1 := high:1[AH:imm8]",
        masked,
        "1:8u",
        "OF:imm1 := (high:1[AH:imm8] ^ high:1[(AH:imm8 << 1:8u)])",
      )
    }
    Err(reason) => fail(reason)
  }

  let ror64_cl = basic_bil_decode("x86_64", b"\x49\xd3\xc8", start=0x704dUL)
  match ror64_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let count = "(CL:imm8 & 0x3F:8u)"
      assert_string(
        stmts[0].to_string(),
        "R8:imm64 := ((R8:imm64 >> " +
        count +
        ") | (R8:imm64 << (0x40:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[R8:imm64]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[R8:imm64] ^ high:1[(R8:imm64 << 1:64u)])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rol8_rex = basic_bil_decode("x86_64", b"\x40\xd0\xc4", start=0x7050UL)
  match rol8_rex.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 2)
      let masked = "(1:8u & 0x1F:8u)"
      let count = "(\{masked} % 8:8u)"
      assert_string(
        stmts[0].to_string(),
        "SPL:imm8 := ((SPL:imm8 << " +
        count +
        ") | (SPL:imm8 >> (8:8u - " +
        count +
        ")))",
      )
      assert_rotate_flag_update(
        stmts[1],
        "(\{masked} != 0:8u)",
        "CF:imm1 := low:1[SPL:imm8]",
        masked,
        "1:8u",
        "OF:imm1 := (high:1[SPL:imm8] ^ low:1[SPL:imm8])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl8_one = basic_bil_decode("x86", b"\xd0\xd0", start=0x7051UL)
  match rcl8_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "((1:8u & 0x1F:8u) % 9:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm9 := ((concat(AL:imm8, CF:imm1) << " +
        count +
        ") | (concat(AL:imm8, CF:imm1) >> (9:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "AL:imm8 := extract[8:1](%rotate_carry_res:imm9)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm9]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[AL:imm8] ^ low:1[%rotate_carry_res:imm9])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcr32_cl = basic_bil_decode("x86", b"\xd3\xd8", start=0x7053UL)
  match rcr32_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "(CL:imm8 & 0x1F:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm33 := ((concat(CF:imm1, EAX:imm32) >> " +
        count +
        ") | (concat(CF:imm1, EAX:imm32) << (0x21:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "EAX:imm32 := extract[31:0](%rotate_carry_res:imm33)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[%rotate_carry_res:imm33]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[EAX:imm32] ^ extract[30:30](EAX:imm32))",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl16_one = basic_bil_decode("x86", b"\x66\xd1\xd0", start=0x7054UL)
  match rcl16_one.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "((1:16u & 0x1F:16u) % 0x11:16u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm17 := ((concat(AX:imm16, CF:imm1) << " +
        count +
        ") | (concat(AX:imm16, CF:imm1) >> (0x11:16u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "AX:imm16 := extract[16:1](%rotate_carry_res:imm17)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:16u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm17]",
        count,
        "1:16u",
        "OF:imm1 := (high:1[AX:imm16] ^ low:1[%rotate_carry_res:imm17])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcr16_cl = basic_bil_decode("x86", b"\x66\xd3\xd8", start=0x7054UL)
  match rcr16_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "((CL:imm8 & 0x1F:8u) % 0x11:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm17 := ((concat(CF:imm1, AX:imm16) >> " +
        count +
        ") | (concat(CF:imm1, AX:imm16) << (0x11:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "AX:imm16 := extract[15:0](%rotate_carry_res:imm17)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[%rotate_carry_res:imm17]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[AX:imm16] ^ extract[14:14](AX:imm16))",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl8_imm = basic_bil_decode("x86", b"\xc0\xd4\x03", start=0x7055UL)
  match rcl8_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "((3:8u & 0x1F:8u) % 9:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm9 := ((concat(AH:imm8, CF:imm1) << " +
        count +
        ") | (concat(AH:imm8, CF:imm1) >> (9:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "AH:imm8 := extract[8:1](%rotate_carry_res:imm9)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm9]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[AH:imm8] ^ low:1[%rotate_carry_res:imm9])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcr64_cl = basic_bil_decode("x86_64", b"\x49\xd3\xd8", start=0x7058UL)
  match rcr64_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "(CL:imm8 & 0x3F:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm65 := ((concat(CF:imm1, R8:imm64) >> " +
        count +
        ") | (concat(CF:imm1, R8:imm64) << (0x41:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "R8:imm64 := extract[63:0](%rotate_carry_res:imm65)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[%rotate_carry_res:imm65]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[R8:imm64] ^ extract[62:62](R8:imm64))",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl8_rex = basic_bil_decode("x86_64", b"\x40\xd0\xd4", start=0x705bUL)
  match rcl8_rex.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 3)
      let count = "((1:8u & 0x1F:8u) % 9:8u)"
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_res:imm9 := ((concat(SPL:imm8, CF:imm1) << " +
        count +
        ") | (concat(SPL:imm8, CF:imm1) >> (9:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[1].to_string(),
        "SPL:imm8 := extract[8:1](%rotate_carry_res:imm9)",
      )
      assert_rotate_flag_update(
        stmts[2],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm9]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[SPL:imm8] ^ low:1[%rotate_carry_res:imm9])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rol64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xd1\x45\xf8",
    start=0x705cUL,
  )
  match rol64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%rotate_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_d:imm64 := load(mem:mem64x8, %rotate_a:imm64):imm64",
      )
      let count = "(1:64u & 0x3F:64u)"
      let result = "%rotate_res:imm64"
      assert_string(
        stmts[2].to_string(),
        result +
        " := ((%rotate_d:imm64 << " +
        count +
        ") | (%rotate_d:imm64 >> (0x40:64u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %rotate_a:imm64, %rotate_res:imm64)",
      )
      assert_rotate_flag_update(
        stmts[4],
        "(\{count} != 0:64u)",
        "CF:imm1 := low:1[%rotate_res:imm64]",
        count,
        "1:64u",
        "OF:imm1 := (high:1[%rotate_res:imm64] ^ low:1[%rotate_res:imm64])",
      )
    }
    Err(reason) => fail(reason)
  }

  let ror32_mem_cl = basic_bil_decode("x86", b"\xd3\x4d\xfc", start=0x7060UL)
  match ror32_mem_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%rotate_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_d:imm32 := load(mem:mem32x8, %rotate_a:imm32):imm32",
      )
      let count = "(CL:imm8 & 0x1F:8u)"
      let result = "%rotate_res:imm32"
      assert_string(
        stmts[2].to_string(),
        result +
        " := ((%rotate_d:imm32 >> " +
        count +
        ") | (%rotate_d:imm32 << (0x20:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %rotate_a:imm32, %rotate_res:imm32)",
      )
      assert_rotate_flag_update(
        stmts[4],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[%rotate_res:imm32]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[%rotate_res:imm32] ^ high:1[(%rotate_res:imm32 << 1:32u)])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rol16_mem = basic_bil_decode("x86", b"\x66\xd1\x45\xfc", start=0x7061UL)
  match rol16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%rotate_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_d:imm16 := load(mem:mem32x8, %rotate_a:imm32):imm16",
      )
      let masked = "(1:16u & 0x1F:16u)"
      let count = "(\{masked} % 0x10:16u)"
      let result = "%rotate_res:imm16"
      assert_string(
        stmts[2].to_string(),
        result +
        " := ((%rotate_d:imm16 << " +
        count +
        ") | (%rotate_d:imm16 >> (0x10:16u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %rotate_a:imm32, %rotate_res:imm16)",
      )
      assert_rotate_flag_update(
        stmts[4],
        "(\{masked} != 0:16u)",
        "CF:imm1 := low:1[%rotate_res:imm16]",
        masked,
        "1:16u",
        "OF:imm1 := (high:1[%rotate_res:imm16] ^ low:1[%rotate_res:imm16])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rol8_mem_imm = basic_bil_decode(
    "x86_64",
    b"\x41\xc0\x40\x01\x04",
    start=0x7063UL,
  )
  match rol8_mem_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 5)
      assert_string(
        stmts[0].to_string(),
        "%rotate_a:imm64 := (R8:imm64 + 1:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_d:imm8 := load(mem:mem64x8, %rotate_a:imm64):imm8",
      )
      let masked = "(4:8u & 0x1F:8u)"
      let count = "(\{masked} % 8:8u)"
      let result = "%rotate_res:imm8"
      assert_string(
        stmts[2].to_string(),
        result +
        " := ((%rotate_d:imm8 << " +
        count +
        ") | (%rotate_d:imm8 >> (8:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %rotate_a:imm64, %rotate_res:imm8)",
      )
      assert_rotate_flag_update(
        stmts[4],
        "(\{masked} != 0:8u)",
        "CF:imm1 := low:1[%rotate_res:imm8]",
        masked,
        "1:8u",
        "OF:imm1 := (high:1[%rotate_res:imm8] ^ low:1[%rotate_res:imm8])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xd1\x55\xf8",
    start=0x7068UL,
  )
  match rcl64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_carry_d:imm64 := load(mem:mem64x8, %rotate_carry_a:imm64):imm64",
      )
      let count = "(1:64u & 0x3F:64u)"
      assert_string(
        stmts[2].to_string(),
        "%rotate_carry_res:imm65 := ((concat(%rotate_carry_d:imm64, CF:imm1) << " +
        count +
        ") | (concat(%rotate_carry_d:imm64, CF:imm1) >> (0x41:64u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "%rotate_carry_dst:imm64 := extract[64:1](%rotate_carry_res:imm65)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %rotate_carry_a:imm64, %rotate_carry_dst:imm64)",
      )
      assert_rotate_flag_update(
        stmts[5],
        "(\{count} != 0:64u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm65]",
        count,
        "1:64u",
        "OF:imm1 := (high:1[%rotate_carry_dst:imm64] ^ low:1[%rotate_carry_res:imm65])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcr32_mem_cl = basic_bil_decode("x86", b"\xd3\x5d\xfc", start=0x706cUL)
  match rcr32_mem_cl.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_carry_d:imm32 := load(mem:mem32x8, %rotate_carry_a:imm32):imm32",
      )
      let count = "(CL:imm8 & 0x1F:8u)"
      assert_string(
        stmts[2].to_string(),
        "%rotate_carry_res:imm33 := ((concat(CF:imm1, %rotate_carry_d:imm32) >> " +
        count +
        ") | (concat(CF:imm1, %rotate_carry_d:imm32) << (0x21:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "%rotate_carry_dst:imm32 := extract[31:0](%rotate_carry_res:imm33)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %rotate_carry_a:imm32, %rotate_carry_dst:imm32)",
      )
      assert_rotate_flag_update(
        stmts[5],
        "(\{count} != 0:8u)",
        "CF:imm1 := high:1[%rotate_carry_res:imm33]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[%rotate_carry_dst:imm32] ^ extract[30:30](%rotate_carry_dst:imm32))",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl16_mem = basic_bil_decode("x86", b"\x66\xd1\x55\xfc", start=0x706dUL)
  match rcl16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_carry_d:imm16 := load(mem:mem32x8, %rotate_carry_a:imm32):imm16",
      )
      let count = "((1:16u & 0x1F:16u) % 0x11:16u)"
      assert_string(
        stmts[2].to_string(),
        "%rotate_carry_res:imm17 := ((concat(%rotate_carry_d:imm16, CF:imm1) << " +
        count +
        ") | (concat(%rotate_carry_d:imm16, CF:imm1) >> (0x11:16u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "%rotate_carry_dst:imm16 := extract[16:1](%rotate_carry_res:imm17)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %rotate_carry_a:imm32, %rotate_carry_dst:imm16)",
      )
      assert_rotate_flag_update(
        stmts[5],
        "(\{count} != 0:16u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm17]",
        count,
        "1:16u",
        "OF:imm1 := (high:1[%rotate_carry_dst:imm16] ^ low:1[%rotate_carry_res:imm17])",
      )
    }
    Err(reason) => fail(reason)
  }

  let rcl8_mem_imm = basic_bil_decode(
    "x86_64",
    b"\x41\xc0\x50\x01\x04",
    start=0x706fUL,
  )
  match rcl8_mem_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 6)
      assert_string(
        stmts[0].to_string(),
        "%rotate_carry_a:imm64 := (R8:imm64 + 1:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%rotate_carry_d:imm8 := load(mem:mem64x8, %rotate_carry_a:imm64):imm8",
      )
      let count = "((4:8u & 0x1F:8u) % 9:8u)"
      assert_string(
        stmts[2].to_string(),
        "%rotate_carry_res:imm9 := ((concat(%rotate_carry_d:imm8, CF:imm1) << " +
        count +
        ") | (concat(%rotate_carry_d:imm8, CF:imm1) >> (9:8u - " +
        count +
        ")))",
      )
      assert_string(
        stmts[3].to_string(),
        "%rotate_carry_dst:imm8 := extract[8:1](%rotate_carry_res:imm9)",
      )
      assert_string(
        stmts[4].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, %rotate_carry_a:imm64, %rotate_carry_dst:imm8)",
      )
      assert_rotate_flag_update(
        stmts[5],
        "(\{count} != 0:8u)",
        "CF:imm1 := low:1[%rotate_carry_res:imm9]",
        count,
        "1:8u",
        "OF:imm1 := (high:1[%rotate_carry_dst:imm8] ^ low:1[%rotate_carry_res:imm9])",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register add-sub rr ops" {
  let add64 = basic_bil_decode("x86_64", b"\x48\x01\xd8", start=0x7017UL)
  match add64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := RBX:imm64")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "RAX:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add64_ext = basic_bil_decode("x86_64", b"\x4d\x01\xc8", start=0x701aUL)
  match add64_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm64 := R8:imm64")
      assert_string(stmts[1].to_string(), "%add_src:imm64 := R9:imm64")
      assert_string(
        stmts[2].to_string(),
        "R8:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm64", "%add_src:imm64", "R8:imm64", "0:64u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add8 = basic_bil_decode("x86", b"\x00\xe0", start=0x701bUL)
  match add8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm8 := AL:imm8")
      assert_string(stmts[1].to_string(), "%add_src:imm8 := AH:imm8")
      assert_string(
        stmts[2].to_string(),
        "AL:imm8 := (%add_dst:imm8 + %add_src:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm8", "%add_src:imm8", "AL:imm8", "0:8u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let add16 = basic_bil_decode("x86", b"\x66\x01\xd8", start=0x701cUL)
  match add16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%add_dst:imm16 := AX:imm16")
      assert_string(stmts[1].to_string(), "%add_src:imm16 := BX:imm16")
      assert_string(
        stmts[2].to_string(),
        "AX:imm16 := (%add_dst:imm16 + %add_src:imm16)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%add_dst:imm16", "%add_src:imm16", "AX:imm16", "0:16u", true,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub32 = basic_bil_decode("x86", b"\x29\xd8", start=0x701dUL)
  match sub32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm32 := EAX:imm32")
      assert_string(stmts[1].to_string(), "%sub_src:imm32 := EBX:imm32")
      assert_string(
        stmts[2].to_string(),
        "EAX:imm32 := (%sub_dst:imm32 - %sub_src:imm32)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm32", "%sub_src:imm32", "EAX:imm32", "0:32u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub64_rev = basic_bil_decode("x86_64", b"\x48\x2b\xc8", start=0x701fUL)
  match sub64_rev.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm64 := RCX:imm64")
      assert_string(stmts[1].to_string(), "%sub_src:imm64 := RAX:imm64")
      assert_string(
        stmts[2].to_string(),
        "RCX:imm64 := (%sub_dst:imm64 - %sub_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm64", "%sub_src:imm64", "RCX:imm64", "0:64u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let sub8_ext = basic_bil_decode("x86_64", b"\x45\x28\xc8", start=0x7020UL)
  match sub8_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sub_dst:imm8 := R8B:imm8")
      assert_string(stmts[1].to_string(), "%sub_src:imm8 := R9B:imm8")
      assert_string(
        stmts[2].to_string(),
        "R8B:imm8 := (%sub_dst:imm8 - %sub_src:imm8)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm8", "%sub_src:imm8", "R8B:imm8", "0:8u", false,
      )
    }
    Err(reason) => fail(reason)
  }

  let adc64_rr = basic_bil_decode("x86_64", b"\x48\x11\xd8", start=0x7021UL)
  match adc64_rr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%adc_dst:imm64 := RAX:imm64")
      assert_string(stmts[1].to_string(), "%adc_src:imm64 := RBX:imm64")
      assert_string(
        stmts[2].to_string(),
        "RAX:imm64 := ((%adc_dst:imm64 + %adc_src:imm64) + pad:64[CF:imm1])",
      )
      assert_true(stmts[3].to_string().contains("CF:imm1 := extract[64:64]"))
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:64u == RAX:imm64)")
    }
    Err(reason) => fail(reason)
  }

  let sbb32_rev = basic_bil_decode("x86", b"\x1b\xc8", start=0x7024UL)
  match sbb32_rev.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%sbb_src:imm32 := EAX:imm32")
      assert_string(stmts[1].to_string(), "%sbb_dst:imm32 := ECX:imm32")
      assert_string(
        stmts[2].to_string(),
        "ECX:imm32 := (%sbb_dst:imm32 - (%sbb_src:imm32 + pad:32[CF:imm1]))",
      )
      assert_true(stmts[4].to_string().contains("CF:imm1 := ("))
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:32u == ECX:imm32)")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 imul immediate ops" {
  let imul32 = basic_bil_decode("x86", b"\x6b\xc1\x05", start=0x7021UL)
  match imul32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm64 := (extend:64[ECX:imm32] * extend:64[5:32u])", "EAX:imm32 := low:32[%imul_tmp:imm64]",
        "OF:imm1 := (%imul_tmp:imm64 != extend:64[EAX:imm32])", "CF:imm1 := (%imul_tmp:imm64 != extend:64[EAX:imm32])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul16 = basic_bil_decode("x86", b"\x66\x6b\xc1\x02", start=0x7024UL)
  match imul16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm32 := (extend:32[CX:imm16] * extend:32[2:16u])", "AX:imm16 := low:16[%imul_tmp:imm32]",
        "OF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])", "CF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul16_mem = basic_bil_decode(
    "x86",
    b"\x66\x69\x45\xfc\x34\x12",
    start=0x7026UL,
  )
  match imul16_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm32 := (extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16] * extend:32[0x1234:16u])",
        "AX:imm16 := low:16[%imul_tmp:imm32]", "OF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])",
        "CF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x6b\x45\xf8\x03",
    start=0x7028UL,
  )
  match imul64_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm128 := (extend:128[load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64] * extend:128[3:64u])",
        "RAX:imm64 := low:64[%imul_tmp:imm128]", "OF:imm1 := (%imul_tmp:imm128 != extend:128[RAX:imm64])",
        "CF:imm1 := (%imul_tmp:imm128 != extend:128[RAX:imm64])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 imul register-memory ops" {
  let imul32 = basic_bil_decode("x86", b"\x0f\xaf\xc1", start=0x702dUL)
  match imul32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm64 := (extend:64[EAX:imm32] * extend:64[ECX:imm32])", "EAX:imm32 := low:32[%imul_tmp:imm64]",
        "OF:imm1 := (%imul_tmp:imm64 != extend:64[EAX:imm32])", "CF:imm1 := (%imul_tmp:imm64 != extend:64[EAX:imm32])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul16 = basic_bil_decode("x86", b"\x66\x0f\xaf\xc1", start=0x7030UL)
  match imul16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm32 := (extend:32[AX:imm16] * extend:32[CX:imm16])", "AX:imm16 := low:16[%imul_tmp:imm32]",
        "OF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])", "CF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xaf\x45\xfc",
    start=0x7032UL,
  )
  match imul16_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm32 := (extend:32[AX:imm16] * extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16])",
        "AX:imm16 := low:16[%imul_tmp:imm32]", "OF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])",
        "CF:imm1 := (%imul_tmp:imm32 != extend:32[AX:imm16])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xaf\x45\xf8",
    start=0x7034UL,
  )
  match imul64_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm128 := (extend:128[RAX:imm64] * extend:128[load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64])",
        "RAX:imm64 := low:64[%imul_tmp:imm128]", "OF:imm1 := (%imul_tmp:imm128 != extend:128[RAX:imm64])",
        "CF:imm1 := (%imul_tmp:imm128 != extend:128[RAX:imm64])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 mul ops" {
  let mul8 = basic_bil_decode("x86", b"\xf6\xe1", start=0x7039UL)
  match mul8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := (pad:16[AL:imm8] * pad:16[CL:imm8])", "OF:imm1 := (high:8[AX:imm16] != 0:8u)",
        "CF:imm1 := (high:8[AX:imm16] != 0:8u)", "SF:imm1 := unknown(SF is undefined after Mul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after Mul:imm1)", "AF:imm1 := unknown(AF is undefined after Mul:imm1)",
        "PF:imm1 := unknown(PF is undefined after Mul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let mul16 = basic_bil_decode("x86", b"\x66\xf7\xe1", start=0x703bUL)
  match mul16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%mul_tmp:imm32 := (pad:32[AX:imm16] * pad:32[CX:imm16])", "AX:imm16 := low:16[%mul_tmp:imm32]",
        "DX:imm16 := high:16[%mul_tmp:imm32]", "OF:imm1 := (high:16[%mul_tmp:imm32] != 0:16u)",
        "CF:imm1 := (high:16[%mul_tmp:imm32] != 0:16u)", "SF:imm1 := unknown(SF is undefined after Mul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after Mul:imm1)", "AF:imm1 := unknown(AF is undefined after Mul:imm1)",
        "PF:imm1 := unknown(PF is undefined after Mul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let mul16_mem = basic_bil_decode("x86", b"\x66\xf7\x65\xfc", start=0x703dUL)
  match mul16_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%mul_tmp:imm32 := (pad:32[AX:imm16] * pad:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16])",
        "AX:imm16 := low:16[%mul_tmp:imm32]", "DX:imm16 := high:16[%mul_tmp:imm32]",
        "OF:imm1 := (high:16[%mul_tmp:imm32] != 0:16u)", "CF:imm1 := (high:16[%mul_tmp:imm32] != 0:16u)",
        "SF:imm1 := unknown(SF is undefined after Mul:imm1)", "ZF:imm1 := unknown(ZF is undefined after Mul:imm1)",
        "AF:imm1 := unknown(AF is undefined after Mul:imm1)", "PF:imm1 := unknown(PF is undefined after Mul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let mul32 = basic_bil_decode("x86", b"\xf7\xe1", start=0x703eUL)
  match mul32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%mul_tmp:imm64 := (pad:64[EAX:imm32] * pad:64[ECX:imm32])", "EAX:imm32 := low:32[%mul_tmp:imm64]",
        "EDX:imm32 := high:32[%mul_tmp:imm64]", "OF:imm1 := (high:32[%mul_tmp:imm64] != 0:32u)",
        "CF:imm1 := (high:32[%mul_tmp:imm64] != 0:32u)", "SF:imm1 := unknown(SF is undefined after Mul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after Mul:imm1)", "AF:imm1 := unknown(AF is undefined after Mul:imm1)",
        "PF:imm1 := unknown(PF is undefined after Mul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let mul64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xf7\x65\xf8",
    start=0x7040UL,
  )
  match mul64_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%mul_tmp:imm128 := (pad:128[RAX:imm64] * pad:128[load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64])",
        "RAX:imm64 := low:64[%mul_tmp:imm128]", "RDX:imm64 := high:64[%mul_tmp:imm128]",
        "OF:imm1 := (high:64[%mul_tmp:imm128] != 0:64u)", "CF:imm1 := (high:64[%mul_tmp:imm128] != 0:64u)",
        "SF:imm1 := unknown(SF is undefined after Mul:imm1)", "ZF:imm1 := unknown(ZF is undefined after Mul:imm1)",
        "AF:imm1 := unknown(AF is undefined after Mul:imm1)", "PF:imm1 := unknown(PF is undefined after Mul:imm1)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 one-operand imul ops" {
  let imul8 = basic_bil_decode("x86", b"\xf6\xe9", start=0x7044UL)
  match imul8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := (extend:16[AL:imm8] * extend:16[CL:imm8])", "OF:imm1 := (AX:imm16 != extend:16[low:8[AX:imm16]])",
        "CF:imm1 := (AX:imm16 != extend:16[low:8[AX:imm16]])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul32 = basic_bil_decode("x86", b"\xf7\xe9", start=0x7046UL)
  match imul32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm64 := (extend:64[EAX:imm32] * extend:64[ECX:imm32])", "EAX:imm32 := low:32[%imul_tmp:imm64]",
        "EDX:imm32 := high:32[%imul_tmp:imm64]", "OF:imm1 := (%imul_tmp:imm64 != extend:64[low:32[%imul_tmp:imm64]])",
        "CF:imm1 := (%imul_tmp:imm64 != extend:64[low:32[%imul_tmp:imm64]])", "PF:imm1 := unknown(PF is undefined after imul:imm1)",
        "SF:imm1 := unknown(SF is undefined after imul:imm1)", "ZF:imm1 := unknown(ZF is undefined after imul:imm1)",
        "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul16_mem = basic_bil_decode("x86", b"\x66\xf7\x6d\xfc", start=0x7047UL)
  match imul16_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm32 := (extend:32[AX:imm16] * extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16])",
        "AX:imm16 := low:16[%imul_tmp:imm32]", "DX:imm16 := high:16[%imul_tmp:imm32]",
        "OF:imm1 := (%imul_tmp:imm32 != extend:32[low:16[%imul_tmp:imm32]])", "CF:imm1 := (%imul_tmp:imm32 != extend:32[low:16[%imul_tmp:imm32]])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let imul64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xf7\x6d\xf8",
    start=0x7048UL,
  )
  match imul64_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%imul_tmp:imm128 := (extend:128[RAX:imm64] * extend:128[load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64])",
        "RAX:imm64 := low:64[%imul_tmp:imm128]", "RDX:imm64 := high:64[%imul_tmp:imm128]",
        "OF:imm1 := (%imul_tmp:imm128 != extend:128[low:64[%imul_tmp:imm128]])",
        "CF:imm1 := (%imul_tmp:imm128 != extend:128[low:64[%imul_tmp:imm128]])",
        "PF:imm1 := unknown(PF is undefined after imul:imm1)", "SF:imm1 := unknown(SF is undefined after imul:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after imul:imm1)", "AF:imm1 := unknown(AF is undefined after imul:imm1)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 div-idiv ops" {
  let div8 = basic_bil_decode("x86", b"\xf6\xf1", start=0x704cUL)
  match div8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "%divisor:imm16 := pad:16[CL:imm8]", "%dividend:imm16 := AX:imm16", "if (%divisor:imm16 == 0:16u) then 1 stmts else 3 stmts",
        "CF:imm1 := unknown(CF is undefined after div:imm1)", "OF:imm1 := unknown(OF is undefined after div:imm1)",
        "SF:imm1 := unknown(SF is undefined after div:imm1)", "ZF:imm1 := unknown(ZF is undefined after div:imm1)",
        "AF:imm1 := unknown(AF is undefined after div:imm1)", "PF:imm1 := unknown(PF is undefined after div:imm1)",
      ])
      match stmts[2] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(%divisor:imm16 == 0:16u)")
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), "cpuexn 0")
          assert_string(
            no[0].to_string(),
            "%div:imm16 := (%dividend:imm16 / %divisor:imm16)",
          )
          assert_string(
            no[1].to_string(),
            "%rem:imm16 := (%dividend:imm16 % %divisor:imm16)",
          )
          match no[2] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "(high:8[%div:imm16] == 0:8u)")
              assert_true(yes.length() == 1)
              assert_string(
                yes[0].to_string(),
                "AX:imm16 := concat(low:8[%rem:imm16], low:8[%div:imm16])",
              )
              assert_true(no.length() == 1)
              assert_string(no[0].to_string(), "cpuexn 0")
            }
            _ => fail("DIV8 overflow check did not lift to BIL if")
          }
        }
        _ => fail("DIV8 zero-divisor check did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let div32 = basic_bil_decode("x86", b"\xf7\xf1", start=0x704eUL)
  match div32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "%divisor:imm64 := pad:64[ECX:imm32]", "%dividend:imm64 := concat(EDX:imm32, EAX:imm32)",
        "if (%divisor:imm64 == 0:64u) then 1 stmts else 3 stmts", "CF:imm1 := unknown(CF is undefined after div:imm1)",
        "OF:imm1 := unknown(OF is undefined after div:imm1)", "SF:imm1 := unknown(SF is undefined after div:imm1)",
        "ZF:imm1 := unknown(ZF is undefined after div:imm1)", "AF:imm1 := unknown(AF is undefined after div:imm1)",
        "PF:imm1 := unknown(PF is undefined after div:imm1)",
      ])
      match stmts[2] {
        If(yes=_, no~, ..) =>
          match no[2] {
            If(yes~, no~, ..) => {
              assert_true(yes.length() == 3)
              assert_string(
                yes[0].to_string(),
                "%div_result:imm64 := concat(low:32[%rem:imm64], low:32[%div:imm64])",
              )
              assert_string(
                yes[1].to_string(),
                "EAX:imm32 := low:32[%div_result:imm64]",
              )
              assert_string(
                yes[2].to_string(),
                "EDX:imm32 := high:32[%div_result:imm64]",
              )
              assert_true(no.length() == 1)
            }
            _ => fail("DIV32 overflow check did not lift to BIL if")
          }
        _ => fail("DIV32 zero-divisor check did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let div16_mem = basic_bil_decode("x86", b"\x66\xf7\x75\xfc", start=0x704fUL)
  match div16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "%divisor:imm32 := pad:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16]",
        "%dividend:imm32 := concat(DX:imm16, AX:imm16)", "if (%divisor:imm32 == 0:32u) then 1 stmts else 3 stmts",
        "CF:imm1 := unknown(CF is undefined after div:imm1)", "OF:imm1 := unknown(OF is undefined after div:imm1)",
        "SF:imm1 := unknown(SF is undefined after div:imm1)", "ZF:imm1 := unknown(ZF is undefined after div:imm1)",
        "AF:imm1 := unknown(AF is undefined after div:imm1)", "PF:imm1 := unknown(PF is undefined after div:imm1)",
      ])
      match stmts[2] {
        If(yes~, no~, ..) => {
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), "cpuexn 0")
          assert_string(
            no[0].to_string(),
            "%div:imm32 := (%dividend:imm32 / %divisor:imm32)",
          )
          assert_string(
            no[1].to_string(),
            "%rem:imm32 := (%dividend:imm32 % %divisor:imm32)",
          )
          match no[2] {
            If(cond~, yes~, no~) => {
              assert_string(cond.to_string(), "(high:16[%div:imm32] == 0:16u)")
              assert_true(yes.length() == 3)
              assert_string(
                yes[0].to_string(),
                "%div_result:imm32 := concat(low:16[%rem:imm32], low:16[%div:imm32])",
              )
              assert_string(
                yes[1].to_string(),
                "AX:imm16 := low:16[%div_result:imm32]",
              )
              assert_string(
                yes[2].to_string(),
                "DX:imm16 := high:16[%div_result:imm32]",
              )
              assert_true(no.length() == 1)
              assert_string(no[0].to_string(), "cpuexn 0")
            }
            _ => fail("DIV16 memory overflow check did not lift to BIL if")
          }
        }
        _ => fail("DIV16 memory zero-divisor check did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let idiv16_mem = basic_bil_decode("x86", b"\x66\xf7\x7d\xfc", start=0x7050UL)
  match idiv16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "%divisor:imm32 := extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16]",
        "%dividend:imm32 := concat(DX:imm16, AX:imm16)", "if (%divisor:imm32 == 0:32u) then 1 stmts else 3 stmts",
        "CF:imm1 := unknown(CF is undefined after idiv:imm1)", "OF:imm1 := unknown(OF is undefined after idiv:imm1)",
        "SF:imm1 := unknown(SF is undefined after idiv:imm1)", "ZF:imm1 := unknown(ZF is undefined after idiv:imm1)",
        "AF:imm1 := unknown(AF is undefined after idiv:imm1)", "PF:imm1 := unknown(PF is undefined after idiv:imm1)",
      ])
      match stmts[2] {
        If(yes~, no~, ..) => {
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), "cpuexn 0")
          assert_string(
            no[0].to_string(),
            "%div:imm32 := (%dividend:imm32 s/ %divisor:imm32)",
          )
          assert_string(
            no[1].to_string(),
            "%rem:imm32 := (%dividend:imm32 s% %divisor:imm32)",
          )
          match no[2] {
            If(cond~, yes~, no~) => {
              assert_string(
                cond.to_string(),
                "(%div:imm32 != extend:32[low:16[%div:imm32]])",
              )
              assert_true(yes.length() == 1)
              assert_string(yes[0].to_string(), "cpuexn 0")
              assert_true(no.length() == 3)
              assert_string(
                no[0].to_string(),
                "%div_result:imm32 := concat(low:16[%rem:imm32], low:16[%div:imm32])",
              )
              assert_string(
                no[1].to_string(),
                "AX:imm16 := low:16[%div_result:imm32]",
              )
              assert_string(
                no[2].to_string(),
                "DX:imm16 := high:16[%div_result:imm32]",
              )
            }
            _ => fail("IDIV16 memory overflow check did not lift to BIL if")
          }
        }
        _ => fail("IDIV16 memory zero-divisor check did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let idiv64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\xf7\x7d\xf8",
    start=0x7050UL,
  )
  match idiv64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "%divisor:imm128 := extend:128[load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64]",
        "%dividend:imm128 := concat(RDX:imm64, RAX:imm64)", "if (%divisor:imm128 == 0:128u) then 1 stmts else 3 stmts",
        "CF:imm1 := unknown(CF is undefined after idiv:imm1)", "OF:imm1 := unknown(OF is undefined after idiv:imm1)",
        "SF:imm1 := unknown(SF is undefined after idiv:imm1)", "ZF:imm1 := unknown(ZF is undefined after idiv:imm1)",
        "AF:imm1 := unknown(AF is undefined after idiv:imm1)", "PF:imm1 := unknown(PF is undefined after idiv:imm1)",
      ])
      match stmts[2] {
        If(yes~, no~, ..) => {
          assert_true(yes.length() == 1)
          assert_string(yes[0].to_string(), "cpuexn 0")
          assert_string(
            no[0].to_string(),
            "%div:imm128 := (%dividend:imm128 s/ %divisor:imm128)",
          )
          assert_string(
            no[1].to_string(),
            "%rem:imm128 := (%dividend:imm128 s% %divisor:imm128)",
          )
          match no[2] {
            If(cond~, yes~, no~) => {
              assert_string(
                cond.to_string(),
                "(%div:imm128 != extend:128[low:64[%div:imm128]])",
              )
              assert_true(yes.length() == 1)
              assert_string(yes[0].to_string(), "cpuexn 0")
              assert_true(no.length() == 3)
              assert_string(
                no[0].to_string(),
                "%div_result:imm128 := concat(low:64[%rem:imm128], low:64[%div:imm128])",
              )
              assert_string(
                no[1].to_string(),
                "RAX:imm64 := low:64[%div_result:imm128]",
              )
              assert_string(
                no[2].to_string(),
                "RDX:imm64 := high:64[%div_result:imm128]",
              )
            }
            _ => fail("IDIV64 overflow check did not lift to BIL if")
          }
        }
        _ => fail("IDIV64 zero-divisor check did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register logical ops" {
  let xor_zero = basic_bil_decode("x86_64", b"\x48\x31\xc0", start=0x7017UL)
  match xor_zero.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "RAX:imm64 := 0:64u")
      assert_logical_flag_tail(stmts, 1, "RAX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let xor_ext = basic_bil_decode("x86_64", b"\x4d\x31\xc8", start=0x701aUL)
  match xor_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "R8:imm64 := (R8:imm64 ^ R9:imm64)")
      assert_logical_flag_tail(stmts, 1, "R8:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let or32 = basic_bil_decode("x86", b"\x09\xd8", start=0x701dUL)
  match or32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "EAX:imm32 := (EAX:imm32 | EBX:imm32)",
      )
      assert_logical_flag_tail(stmts, 1, "EAX:imm32", "0:32u")
    }
    Err(reason) => fail(reason)
  }

  let or8 = basic_bil_decode("x86", b"\x08\xe0", start=0x701eUL)
  match or8.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AL:imm8 := (AL:imm8 | AH:imm8)")
      assert_logical_flag_tail(stmts, 1, "AL:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }

  let xor8_zero = basic_bil_decode("x86", b"\x30\xc0", start=0x701fUL)
  match xor8_zero.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AL:imm8 := 0:8u")
      assert_logical_flag_tail(stmts, 1, "AL:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }

  let xor16_zero = basic_bil_decode("x86", b"\x66\x31\xc0", start=0x7020UL)
  match xor16_zero.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "AX:imm16 := 0:16u")
      assert_logical_flag_tail(stmts, 1, "AX:imm16", "0:16u")
    }
    Err(reason) => fail(reason)
  }

  let and64_rev = basic_bil_decode("x86_64", b"\x48\x23\xc8", start=0x701fUL)
  match and64_rev.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "RCX:imm64 := (RCX:imm64 & RAX:imm64)",
      )
      assert_logical_flag_tail(stmts, 1, "RCX:imm64", "0:64u")
    }
    Err(reason) => fail(reason)
  }

  let and8_ext = basic_bil_decode("x86_64", b"\x45\x20\xc8", start=0x7020UL)
  match and8_ext.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(stmts[0].to_string(), "R8B:imm8 := (R8B:imm8 & R9B:imm8)")
      assert_logical_flag_tail(stmts, 1, "R8B:imm8", "0:8u")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 cmp and test flag ops" {
  let cmp_imm = basic_bil_decode("x86_64", b"\x48\x83\xf8\x01", start=0x7021UL)
  match cmp_imm.project_basic_bil_lift() {
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
  match cmp_imm32.project_basic_bil_lift() {
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

  let cmp8_imm = basic_bil_decode("x86", b"\x80\xf8\x80", start=0x7024UL)
  match cmp8_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm8 := (AL:imm8 - 0x80:8u)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (AL:imm8 < 0x80:8u)")
      assert_string(stmts[6].to_string(), "ZF:imm1 := (0:8u == %cmp_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let cmp_acc = basic_bil_decode(
    "x86_64",
    b"\x48\x3d\x78\x56\x34\x12",
    start=0x7024UL,
  )
  match cmp_acc.project_basic_bil_lift() {
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
    }
    Err(reason) => fail(reason)
  }

  let cmp_rr = basic_bil_decode("x86", b"\x39\xd1", start=0x7025UL)
  match cmp_rr.project_basic_bil_lift() {
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

  let cmp8_rr = basic_bil_decode("x86", b"\x38\xe0", start=0x7026UL)
  match cmp8_rr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm8 := (AL:imm8 - AH:imm8)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (AL:imm8 < AH:imm8)")
      assert_string(stmts[6].to_string(), "ZF:imm1 := (0:8u == %cmp_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let cmp16_rr = basic_bil_decode("x86", b"\x66\x39\xd8", start=0x7027UL)
  match cmp16_rr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%cmp_tmp:imm16 := (AX:imm16 - BX:imm16)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := (AX:imm16 < BX:imm16)")
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:16u == %cmp_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test_rr = basic_bil_decode("x86_64", b"\x48\x85\xc0", start=0x7027UL)
  match test_rr.project_basic_bil_lift() {
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

  let test8_rr = basic_bil_decode("x86", b"\x84\xe0", start=0x7028UL)
  match test8_rr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm8 := (AL:imm8 & AH:imm8)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[2].to_string(), "OF:imm1 := 0:1u")
      assert_true(stmts[3].to_string().contains("AF undefined after TEST"))
      assert_true(stmts[4].to_string().contains("PF:imm1 := (not low:1"))
      assert_string(stmts[6].to_string(), "ZF:imm1 := (0:8u == %test_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let test16_rr = basic_bil_decode("x86", b"\x66\x85\xc0", start=0x7029UL)
  match test16_rr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm16 := (AX:imm16 & AX:imm16)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[2].to_string(), "OF:imm1 := 0:1u")
      assert_true(stmts[3].to_string().contains("AF undefined after TEST"))
      assert_true(stmts[4].to_string().contains("PF:imm1 := (not low:1"))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:16u == %test_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test_imm = basic_bil_decode(
    "x86_64",
    b"\x48\xa9\x78\x56\x34\x12",
    start=0x702aUL,
  )
  match test_imm.project_basic_bil_lift() {
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

  let test16_imm = basic_bil_decode("x86", b"\x66\xa9\xff\x00", start=0x702dUL)
  match test16_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm16 := (AX:imm16 & 0xFF:16u)",
      )
      assert_string(stmts[1].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[2].to_string(), "OF:imm1 := 0:1u")
      assert_true(stmts[3].to_string().contains("AF undefined after TEST"))
      assert_string(
        stmts[6].to_string(),
        "ZF:imm1 := (0:16u == %test_tmp:imm16)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test8_imm = basic_bil_decode(
    "x86_64",
    b"\x41\xf6\xc0\xff",
    start=0x702fUL,
  )
  match test8_imm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 7)
      assert_string(
        stmts[0].to_string(),
        "%test_tmp:imm8 := (R8B:imm8 & 0xFF:8u)",
      )
      assert_string(stmts[6].to_string(), "ZF:imm1 := (0:8u == %test_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let test_ext_imm = basic_bil_decode(
    "x86_64",
    b"\x49\xf7\xc0\xff\xff\xff\xff",
    start=0x7030UL,
  )
  match test_ext_imm.project_basic_bil_lift() {
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
test "project Basic BIL lift covers x86 memory cmp-test rr operands" {
  let cmp64_mr = basic_bil_decode("x86_64", b"\x48\x39\x4d\xf8", start=0x7032UL)
  match cmp64_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(stmts[0].to_string(), "%cmp_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_string(
        stmts[1].to_string(),
        "%cmp_d:imm64 := load(mem:mem64x8, %cmp_a:imm64):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "%cmp_tmp:imm64 := (%cmp_d:imm64 - RCX:imm64)",
      )
      assert_string(
        stmts[3].to_string(),
        "CF:imm1 := (%cmp_d:imm64 < RCX:imm64)",
      )
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:64u == %cmp_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmp64_rm = basic_bil_decode("x86_64", b"\x48\x3b\x45\xf8", start=0x7036UL)
  match cmp64_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(
        stmts[0].to_string(),
        "%cmp_src:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmp_tmp:imm64 := (RAX:imm64 - %cmp_src:imm64)",
      )
      assert_string(
        stmts[2].to_string(),
        "CF:imm1 := (RAX:imm64 < %cmp_src:imm64)",
      )
      assert_string(
        stmts[7].to_string(),
        "ZF:imm1 := (0:64u == %cmp_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let cmp8_rm = basic_bil_decode("x86", b"\x3a\x4d\xfc", start=0x703aUL)
  match cmp8_rm.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(
        stmts[0].to_string(),
        "%cmp_src:imm8 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8",
      )
      assert_string(
        stmts[1].to_string(),
        "%cmp_tmp:imm8 := (CL:imm8 - %cmp_src:imm8)",
      )
      assert_string(stmts[7].to_string(), "ZF:imm1 := (0:8u == %cmp_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }

  let test64_mr = basic_bil_decode(
    "x86_64",
    b"\x48\x85\x4d\xf8",
    start=0x703eUL,
  )
  match test64_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%test_a:imm64 := (RBP:imm64 - 8:64u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%test_d:imm64 := load(mem:mem64x8, %test_a:imm64):imm64",
      )
      assert_string(
        stmts[2].to_string(),
        "%test_tmp:imm64 := (%test_d:imm64 & RCX:imm64)",
      )
      assert_string(stmts[3].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[4].to_string(), "OF:imm1 := 0:1u")
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (0:64u == %test_tmp:imm64)",
      )
    }
    Err(reason) => fail(reason)
  }

  let test8_mr = basic_bil_decode("x86", b"\x84\x4d\xfc", start=0x7042UL)
  match test8_mr.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 9)
      assert_string(
        stmts[0].to_string(),
        "%test_a:imm32 := (EBP:imm32 - 4:32u)",
      )
      assert_string(
        stmts[1].to_string(),
        "%test_d:imm8 := load(mem:mem32x8, %test_a:imm32):imm8",
      )
      assert_string(
        stmts[2].to_string(),
        "%test_tmp:imm8 := (%test_d:imm8 & CL:imm8)",
      )
      assert_string(stmts[8].to_string(), "ZF:imm1 := (0:8u == %test_tmp:imm8)")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register pushes" {
  let push_rbp = basic_bil_decode("x86_64", b"\x55", start=0x7010UL)
  match push_rbp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), RBP:imm64)", "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_rsp = basic_bil_decode("x86_64", b"\x54", start=0x7011UL)
  match push_rsp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), RSP:imm64)", "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_ebp = basic_bil_decode("x86", b"\x55", start=0x7012UL)
  match push_ebp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 4:32u), EBP:imm32)", "ESP:imm32 := (ESP:imm32 - 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_bp = basic_bil_decode("x86", b"\x66\x55", start=0x7012UL)
  match push_bp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 2:32u), BP:imm16)", "ESP:imm32 := (ESP:imm32 - 2:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_r8w = basic_bil_decode("x86_64", b"\x66\x41\x50", start=0x7012UL)
  match push_r8w.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 2:64u), R8W:imm16)", "RSP:imm64 := (RSP:imm64 - 2:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_imm8 = basic_bil_decode("x86_64", b"\x6a\x01", start=0x7013UL)
  match push_imm8.project_basic_bil_lift() {
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
  match push_imm32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 4:32u), 0x12345678:32u)",
        "ESP:imm32 := (ESP:imm32 - 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_imm16 = basic_bil_decode("x86", b"\x66\x68\x34\x12", start=0x7019UL)
  match push_imm16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (ESP:imm32 - 2:32u), 0x1234:16u)", "ESP:imm32 := (ESP:imm32 - 2:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_mem = basic_bil_decode("x86_64", b"\xff\x70\x10", start=0x701aUL)
  match push_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 8:64u), load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm64)",
        "RSP:imm64 := (RSP:imm64 - 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let push_mem16 = basic_bil_decode(
    "x86_64",
    b"\x66\xff\x70\x10",
    start=0x701bUL,
  )
  match push_mem16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RSP:imm64 - 2:64u), load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm16)",
        "RSP:imm64 := (RSP:imm64 - 2:64u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 register pops" {
  let pop_rbp = basic_bil_decode("x86_64", b"\x5d", start=0x7020UL)
  match pop_rbp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RBP:imm64 := load(mem:mem64x8, RSP:imm64):imm64", "RSP:imm64 := (RSP:imm64 + 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_rsp = basic_bil_decode("x86_64", b"\x5c", start=0x7021UL)
  match pop_rsp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RSP:imm64 := load(mem:mem64x8, RSP:imm64):imm64",
      ])
    Err(reason) => fail(reason)
  }

  let pop_ebp = basic_bil_decode("x86", b"\x5d", start=0x7022UL)
  match pop_ebp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EBP:imm32 := load(mem:mem32x8, ESP:imm32):imm32", "ESP:imm32 := (ESP:imm32 + 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_bp = basic_bil_decode("x86", b"\x66\x5d", start=0x7022UL)
  match pop_bp.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "BP:imm16 := load(mem:mem32x8, ESP:imm32):imm16", "ESP:imm32 := (ESP:imm32 + 2:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_r8w = basic_bil_decode("x86_64", b"\x66\x41\x58", start=0x7022UL)
  match pop_r8w.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8W:imm16 := load(mem:mem64x8, RSP:imm64):imm16", "RSP:imm64 := (RSP:imm64 + 2:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let pop_esp = basic_bil_decode("x86", b"\x5c", start=0x7023UL)
  match pop_esp.project_basic_bil_lift() {
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
  match mov_rbp_rsp.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RBP:imm64 := RSP:imm64"])
    Err(reason) => fail(reason)
  }

  let mov_rev = basic_bil_decode("x86_64", b"\x48\x8b\xec", start=0x7033UL)
  match mov_rev.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RBP:imm64 := RSP:imm64"])
    Err(reason) => fail(reason)
  }

  let mov_ebp_esp = basic_bil_decode("x86", b"\x89\xe5", start=0x7036UL)
  match mov_ebp_esp.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["EBP:imm32 := ESP:imm32"])
    Err(reason) => fail(reason)
  }

  let mov_ax_bx = basic_bil_decode("x86", b"\x66\x89\xd8", start=0x7039UL)
  match mov_ax_bx.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AX:imm16 := BX:imm16"])
    Err(reason) => fail(reason)
  }

  let mov_al_ah = basic_bil_decode("x86", b"\x88\xe0", start=0x7037UL)
  match mov_al_ah.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AL:imm8 := AH:imm8"])
    Err(reason) => fail(reason)
  }

  let mov_r8b_al = basic_bil_decode("x86_64", b"\x44\x8a\xc0", start=0x7038UL)
  match mov_r8b_al.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8B:imm8 := AL:imm8"])
    Err(reason) => fail(reason)
  }

  let movbe64 = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\x38\xf0\x45\xf8",
    start=0x703aUL,
  )
  match movbe64.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      ])
      match stmts[0] {
        Move(_, Load(endian~, ..)) => assert_true(endian == BigEndian)
        _ => fail("MOVBE64rm did not lift as a big-endian load")
      }
    }
    Err(reason) => fail(reason)
  }

  let movbe16_store = basic_bil_decode(
    "x86",
    b"\x66\x0f\x38\xf1\x4d\xfc",
    start=0x703bUL,
  )
  match movbe16_store.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), CX:imm16)",
      ])
      match stmts[0] {
        Move(_, Store(endian~, ..)) => assert_true(endian == BigEndian)
        _ => fail("MOVBE16mr did not lift as a big-endian store")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 xchg" {
  let xchg64 = basic_bil_decode("x86_64", b"\x48\x91", start=0x7038UL)
  match xchg64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm64 := RAX:imm64", "RAX:imm64 := RCX:imm64", "RCX:imm64 := %xchg_tmp:imm64",
      ])
    Err(reason) => fail(reason)
  }

  let xchg32 = basic_bil_decode("x86", b"\x87\xd8", start=0x703aUL)
  match xchg32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm32 := EBX:imm32", "EBX:imm32 := EAX:imm32", "EAX:imm32 := %xchg_tmp:imm32",
      ])
    Err(reason) => fail(reason)
  }

  let xchg16 = basic_bil_decode("x86", b"\x66\x87\xc8", start=0x7039UL)
  match xchg16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm16 := CX:imm16", "CX:imm16 := AX:imm16", "AX:imm16 := %xchg_tmp:imm16",
      ])
    Err(reason) => fail(reason)
  }

  let xchg8 = basic_bil_decode("x86", b"\x86\xe0", start=0x703bUL)
  match xchg8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm8 := AH:imm8", "AH:imm8 := AL:imm8", "AL:imm8 := %xchg_tmp:imm8",
      ])
    Err(reason) => fail(reason)
  }

  let xchg_mem = basic_bil_decode("x86_64", b"\x48\x87\x45\xf8", start=0x703cUL)
  match xchg_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm64 := RAX:imm64", "RAX:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), %xchg_tmp:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let xchg_mem16 = basic_bil_decode("x86", b"\x66\x87\x4d\xfc", start=0x703dUL)
  match xchg_mem16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm16 := CX:imm16", "CX:imm16 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16",
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), %xchg_tmp:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let xchg_mem8 = basic_bil_decode("x86", b"\x86\x45\xfc", start=0x703eUL)
  match xchg_mem8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%xchg_tmp:imm8 := AL:imm8", "AL:imm8 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8",
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), %xchg_tmp:imm8)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 movsx movzx" {
  let movzx64 = basic_bil_decode("x86_64", b"\x48\x0f\xb6\xc1", start=0x703fUL)
  match movzx64.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := pad:64[CL:imm8]"])
    Err(reason) => fail(reason)
  }

  let movzx_ext = basic_bil_decode(
    "x86_64",
    b"\x4d\x0f\xb7\xc1",
    start=0x7043UL,
  )
  match movzx_ext.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8:imm64 := pad:64[R9W:imm16]"])
    Err(reason) => fail(reason)
  }

  let movzx16 = basic_bil_decode("x86", b"\x66\x0f\xb6\xc1", start=0x7045UL)
  match movzx16.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AX:imm16 := pad:16[CL:imm8]"])
    Err(reason) => fail(reason)
  }

  let movsx16 = basic_bil_decode("x86", b"\x66\x0f\xbe\xc4", start=0x7046UL)
  match movsx16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["AX:imm16 := extend:16[AH:imm8]"])
    Err(reason) => fail(reason)
  }

  let movsx_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xbe\x45\xfc",
    start=0x7047UL,
  )
  match movsx_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := extend:64[load(mem:mem64x8, (RBP:imm64 - 4:64u)):imm8]",
      ])
    Err(reason) => fail(reason)
  }

  let movsx_mem16 = basic_bil_decode(
    "x86",
    b"\x66\x0f\xbe\x45\xfc",
    start=0x7048UL,
  )
  match movsx_mem16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := extend:16[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8]",
      ])
    Err(reason) => fail(reason)
  }

  let movsxd = basic_bil_decode("x86_64", b"\x48\x63\xc1", start=0x704bUL)
  match movsxd.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := extend:64[ECX:imm32]"])
    Err(reason) => fail(reason)
  }

  let movsxd_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x63\x45\xfc",
    start=0x704eUL,
  )
  match movsxd_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := extend:64[load(mem:mem64x8, (RBP:imm64 - 4:64u)):imm32]",
      ])
    Err(reason) => fail(reason)
  }

  let movsx_same_width = basic_bil_decode("x86_64", b"\x63\xc1", start=0x7052UL)
  match movsx_same_width.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[ECX:imm32]"])
    Err(reason) => fail(reason)
  }

  let movsx32 = basic_bil_decode("x86", b"\x0f\xbe\xc4", start=0x704cUL)
  match movsx32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[AH:imm8]"])
    Err(reason) => fail(reason)
  }

  let movsx32_mem = basic_bil_decode("x86", b"\x0f\xbf\x45\xfc", start=0x704fUL)
  match movsx32_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := extend:32[load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16]",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 bsf bsr" {
  let bsf32 = basic_bil_decode("x86", b"\x0f\xbc\xc1", start=0x7050UL)
  match bsf32.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "if (ECX:imm32 == 0:32u) then 2 stmts else 8 stmts", "CF:imm1 := unknown(bits:imm1)",
        "OF:imm1 := unknown(bits:imm1)", "SF:imm1 := unknown(bits:imm1)", "AF:imm1 := unknown(bits:imm1)",
        "PF:imm1 := unknown(bits:imm1)",
      ])
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(ECX:imm32 == 0:32u)")
          assert_true(yes.length() == 2)
          assert_string(yes[0].to_string(), "ZF:imm1 := 1:1u")
          assert_string(yes[1].to_string(), "EAX:imm32 := unknown(bits:imm32)")
          assert_true(no.length() == 8)
          assert_string(no[0].to_string(), "%bitscan:imm32 := ECX:imm32")
          assert_string(
            no[1].to_string(),
            "%bitscan:imm32 := ((%bitscan:imm32 & (neg %bitscan:imm32)) - 1:32u)",
          )
          assert_true(no[2].to_string().contains("0x55555555:32u"))
          assert_true(no[3].to_string().contains("0x33333333:32u"))
          assert_true(no[4].to_string().contains("0xF0F0F0F:32u"))
          assert_true(no[5].to_string().contains("0x1010101:32u"))
          assert_string(no[6].to_string(), "EAX:imm32 := %bitscan:imm32")
          assert_string(no[7].to_string(), "ZF:imm1 := 0:1u")
        }
        _ => fail("BSF32 did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let bsr64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xbd\x45\xf8",
    start=0x7051UL,
  )
  match bsr64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "if (load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64 == 0:64u) then 2 stmts else 14 stmts",
        "CF:imm1 := unknown(bits:imm1)", "OF:imm1 := unknown(bits:imm1)", "SF:imm1 := unknown(bits:imm1)",
        "AF:imm1 := unknown(bits:imm1)", "PF:imm1 := unknown(bits:imm1)",
      ])
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(
            cond.to_string(),
            "(load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64 == 0:64u)",
          )
          assert_true(yes.length() == 2)
          assert_string(yes[0].to_string(), "ZF:imm1 := 1:1u")
          assert_string(yes[1].to_string(), "RAX:imm64 := unknown(bits:imm64)")
          assert_true(no.length() == 14)
          assert_string(
            no[0].to_string(),
            "%bitscan:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
          )
          assert_string(
            no[1].to_string(),
            "%bitscan:imm64 := (%bitscan:imm64 | (%bitscan:imm64 >> 1:64u))",
          )
          assert_string(
            no[7].to_string(),
            "%bitscan:imm64 := (not %bitscan:imm64)",
          )
          assert_true(no[8].to_string().contains("0x5555555555555555:64u"))
          assert_true(no[11].to_string().contains("0x101010101010101:64u"))
          assert_string(
            no[12].to_string(),
            "RAX:imm64 := (%bitscan:imm64 ^ 0x3F:64u)",
          )
          assert_string(no[13].to_string(), "ZF:imm1 := 0:1u")
        }
        _ => fail("BSR64 memory did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let bsf16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xbc\x45\xfc",
    start=0x7052UL,
  )
  match bsf16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "if (load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16 == 0:16u) then 2 stmts else 8 stmts",
        "CF:imm1 := unknown(bits:imm1)", "OF:imm1 := unknown(bits:imm1)", "SF:imm1 := unknown(bits:imm1)",
        "AF:imm1 := unknown(bits:imm1)", "PF:imm1 := unknown(bits:imm1)",
      ])
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(
            cond.to_string(),
            "(load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16 == 0:16u)",
          )
          assert_true(yes.length() == 2)
          assert_string(yes[0].to_string(), "ZF:imm1 := 1:1u")
          assert_string(yes[1].to_string(), "AX:imm16 := unknown(bits:imm16)")
          assert_true(no.length() == 8)
          assert_string(
            no[0].to_string(),
            "%bitscan:imm16 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16",
          )
          assert_string(
            no[1].to_string(),
            "%bitscan:imm16 := ((%bitscan:imm16 & (neg %bitscan:imm16)) - 1:16u)",
          )
          assert_true(no[2].to_string().contains("0x5555:16u"))
          assert_true(no[3].to_string().contains("0x3333:16u"))
          assert_true(no[4].to_string().contains("0xF0F:16u"))
          assert_true(no[5].to_string().contains("0x101:16u"))
          assert_string(no[6].to_string(), "AX:imm16 := %bitscan:imm16")
          assert_string(no[7].to_string(), "ZF:imm1 := 0:1u")
        }
        _ => fail("BSF16 memory did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let bsr16 = basic_bil_decode("x86", b"\x66\x0f\xbd\xc1", start=0x7053UL)
  match bsr16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_basic_bil_text(stmts, [
        "if (CX:imm16 == 0:16u) then 2 stmts else 12 stmts", "CF:imm1 := unknown(bits:imm1)",
        "OF:imm1 := unknown(bits:imm1)", "SF:imm1 := unknown(bits:imm1)", "AF:imm1 := unknown(bits:imm1)",
        "PF:imm1 := unknown(bits:imm1)",
      ])
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(CX:imm16 == 0:16u)")
          assert_true(yes.length() == 2)
          assert_string(yes[1].to_string(), "AX:imm16 := unknown(bits:imm16)")
          assert_true(no.length() == 12)
          assert_string(no[0].to_string(), "%bitscan:imm16 := CX:imm16")
          assert_string(
            no[1].to_string(),
            "%bitscan:imm16 := (%bitscan:imm16 | (%bitscan:imm16 >> 1:16u))",
          )
          assert_string(
            no[4].to_string(),
            "%bitscan:imm16 := (%bitscan:imm16 | (%bitscan:imm16 >> 8:16u))",
          )
          assert_string(
            no[5].to_string(),
            "%bitscan:imm16 := (not %bitscan:imm16)",
          )
          assert_true(no[6].to_string().contains("0x5555:16u"))
          assert_string(
            no[10].to_string(),
            "AX:imm16 := (%bitscan:imm16 ^ 0xF:16u)",
          )
          assert_string(no[11].to_string(), "ZF:imm1 := 0:1u")
        }
        _ => fail("BSR16 did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 popcnt" {
  let popcnt32 = basic_bil_decode("x86", b"\xf3\x0f\xb8\xc1", start=0x7052UL)
  match popcnt32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ZF:imm1 := (0:32u == ECX:imm32)", "%popcnt:imm32 := ECX:imm32", "%popcnt:imm32 := (%popcnt:imm32 - ((%popcnt:imm32 >> 1:32u) & 0x55555555:32u))",
        "%popcnt:imm32 := ((%popcnt:imm32 & 0x33333333:32u) + ((%popcnt:imm32 >> 2:32u) & 0x33333333:32u))",
        "%popcnt:imm32 := ((%popcnt:imm32 + (%popcnt:imm32 >> 4:32u)) & 0xF0F0F0F:32u)",
        "%popcnt:imm32 := ((%popcnt:imm32 * 0x1010101:32u) >> 0x18:32u)", "EAX:imm32 := %popcnt:imm32",
        "CF:imm1 := 0:1u", "OF:imm1 := 0:1u", "SF:imm1 := 0:1u", "AF:imm1 := 0:1u",
        "PF:imm1 := 0:1u",
      ])
    Err(reason) => fail(reason)
  }

  let popcnt64_mem = basic_bil_decode(
    "x86_64",
    b"\xf3\x48\x0f\xb8\x45\xf8",
    start=0x7053UL,
  )
  match popcnt64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_string(
        stmts[0].to_string(),
        "ZF:imm1 := (0:64u == load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64)",
      )
      assert_string(
        stmts[1].to_string(),
        "%popcnt:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      )
      assert_true(stmts[2].to_string().contains("0x5555555555555555:64u"))
      assert_true(stmts[5].to_string().contains("0x101010101010101:64u"))
      assert_string(stmts[6].to_string(), "RAX:imm64 := %popcnt:imm64")
      assert_string(stmts[7].to_string(), "CF:imm1 := 0:1u")
      assert_string(stmts[11].to_string(), "PF:imm1 := 0:1u")
    }
    Err(reason) => fail(reason)
  }

  let popcnt16_mem = basic_bil_decode(
    "x86",
    b"\x66\xf3\x0f\xb8\x45\xfc",
    start=0x7055UL,
  )
  match popcnt16_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ZF:imm1 := (0:16u == load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16)", "%popcnt:imm16 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16",
        "%popcnt:imm16 := (%popcnt:imm16 - ((%popcnt:imm16 >> 1:16u) & 0x5555:16u))",
        "%popcnt:imm16 := ((%popcnt:imm16 & 0x3333:16u) + ((%popcnt:imm16 >> 2:16u) & 0x3333:16u))",
        "%popcnt:imm16 := ((%popcnt:imm16 + (%popcnt:imm16 >> 4:16u)) & 0xF0F:16u)",
        "%popcnt:imm16 := ((%popcnt:imm16 * 0x101:16u) >> 8:16u)", "AX:imm16 := %popcnt:imm16",
        "CF:imm1 := 0:1u", "OF:imm1 := 0:1u", "SF:imm1 := 0:1u", "AF:imm1 := 0:1u",
        "PF:imm1 := 0:1u",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 lzcnt tzcnt" {
  let tzcnt32 = basic_bil_decode("x86", b"\xf3\x0f\xbc\xc1", start=0x7056UL)
  match tzcnt32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%cntzero:imm32 := ECX:imm32", "%cntzero:imm32 := ((%cntzero:imm32 & (neg %cntzero:imm32)) - 1:32u)",
        "%cntzero:imm32 := (%cntzero:imm32 - ((%cntzero:imm32 >> 1:32u) & 0x55555555:32u))",
        "%cntzero:imm32 := ((%cntzero:imm32 & 0x33333333:32u) + ((%cntzero:imm32 >> 2:32u) & 0x33333333:32u))",
        "%cntzero:imm32 := ((%cntzero:imm32 + (%cntzero:imm32 >> 4:32u)) & 0xF0F0F0F:32u)",
        "%cntzero:imm32 := ((%cntzero:imm32 * 0x1010101:32u) >> 0x18:32u)", "EAX:imm32 := %cntzero:imm32",
        "CF:imm1 := (ECX:imm32 == 0:32u)", "ZF:imm1 := (%cntzero:imm32 == 0:32u)",
        "OF:imm1 := unknown(tzcnt:imm1)", "SF:imm1 := unknown(tzcnt:imm1)", "AF:imm1 := unknown(tzcnt:imm1)",
        "PF:imm1 := unknown(tzcnt:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let lzcnt64_mem = basic_bil_decode(
    "x86_64",
    b"\xf3\x48\x0f\xbd\x45\xf8",
    start=0x7057UL,
  )
  match lzcnt64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 19)
      assert_string(
        stmts[0].to_string(),
        "%cntzero:imm64 := load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64",
      )
      assert_string(
        stmts[1].to_string(),
        "%cntzero:imm64 := (%cntzero:imm64 | (%cntzero:imm64 >> 1:64u))",
      )
      assert_string(
        stmts[7].to_string(),
        "%cntzero:imm64 := (not %cntzero:imm64)",
      )
      assert_true(stmts[8].to_string().contains("0x5555555555555555:64u"))
      assert_true(stmts[11].to_string().contains("0x101010101010101:64u"))
      assert_string(stmts[12].to_string(), "RAX:imm64 := %cntzero:imm64")
      assert_string(
        stmts[13].to_string(),
        "CF:imm1 := (load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64 == 0:64u)",
      )
      assert_string(
        stmts[14].to_string(),
        "ZF:imm1 := (%cntzero:imm64 == 0:64u)",
      )
      assert_string(stmts[18].to_string(), "PF:imm1 := unknown(lzcnt:imm1)")
    }
    Err(reason) => fail(reason)
  }

  let tzcnt16 = basic_bil_decode(
    "x86_64",
    b"\x66\xf3\x45\x0f\xbc\xc1",
    start=0x7058UL,
  )
  match tzcnt16.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 13)
      assert_string(stmts[0].to_string(), "%cntzero:imm16 := R9W:imm16")
      assert_string(
        stmts[5].to_string(),
        "%cntzero:imm16 := ((%cntzero:imm16 * 0x101:16u) >> 8:16u)",
      )
      assert_string(stmts[6].to_string(), "R8W:imm16 := %cntzero:imm16")
      assert_string(stmts[7].to_string(), "CF:imm1 := (R9W:imm16 == 0:16u)")
      assert_string(
        stmts[8].to_string(),
        "ZF:imm1 := (%cntzero:imm16 == 0:16u)",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 bt-family" {
  let bt32 = basic_bil_decode("x86", b"\x0f\xa3\xc8", start=0x7054UL)
  match bt32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%btx_o:imm5 := low:5[ECX:imm32]", "CF:imm1 := low:1[(EAX:imm32 >> %btx_o:imm5)]",
        "OF:imm1 := unknown(bt:imm1)", "SF:imm1 := unknown(bt:imm1)", "AF:imm1 := unknown(bt:imm1)",
        "PF:imm1 := unknown(bt:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let bt16 = basic_bil_decode("x86", b"\x66\x0f\xa3\xc8", start=0x7055UL)
  match bt16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "%btx_o:imm4 := low:4[CX:imm16]", "CF:imm1 := low:1[(AX:imm16 >> %btx_o:imm4)]",
        "OF:imm1 := unknown(bt:imm1)", "SF:imm1 := unknown(bt:imm1)", "AF:imm1 := unknown(bt:imm1)",
        "PF:imm1 := unknown(bt:imm1)",
      ])
    Err(reason) => fail(reason)
  }

  let bts16 = basic_bil_decode("x86", b"\x66\x0f\xba\xe8\x03", start=0x7056UL)
  match bts16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "CF:imm1 := low:1[(AX:imm16 >> 3:4u)]", "OF:imm1 := unknown(bts:imm1)", "SF:imm1 := unknown(bts:imm1)",
        "AF:imm1 := unknown(bts:imm1)", "PF:imm1 := unknown(bts:imm1)", "AX:imm16 := (AX:imm16 | 8:16u)",
      ])
    Err(reason) => fail(reason)
  }

  let bts32 = basic_bil_decode("x86", b"\x0f\xba\xe8\x05", start=0x7055UL)
  match bts32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "CF:imm1 := low:1[(EAX:imm32 >> 5:5u)]", "OF:imm1 := unknown(bts:imm1)",
        "SF:imm1 := unknown(bts:imm1)", "AF:imm1 := unknown(bts:imm1)", "PF:imm1 := unknown(bts:imm1)",
        "EAX:imm32 := (EAX:imm32 | 0x20:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let btr32_mem = basic_bil_decode(
    "x86",
    b"\x0f\xba\x75\xfc\x05",
    start=0x7056UL,
  )
  match btr32_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%btx_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%btx_d:imm32 := load(mem:mem32x8, %btx_a:imm32):imm32",
      )
      assert_string(
        stmts[2].to_string(),
        "CF:imm1 := low:1[(%btx_d:imm32 >> 5:5u)]",
      )
      assert_string(stmts[6].to_string(), "PF:imm1 := unknown(btr:imm1)")
      assert_string(
        stmts[7].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %btx_a:imm32, (%btx_d:imm32 & (not 0x20:32u)))",
      )
    }
    Err(reason) => fail(reason)
  }

  let btr16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xba\x75\xfc\x05",
    start=0x7057UL,
  )
  match btr16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 8)
      assert_string(stmts[0].to_string(), "%btx_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_string(
        stmts[1].to_string(),
        "%btx_d:imm16 := load(mem:mem32x8, %btx_a:imm32):imm16",
      )
      assert_string(
        stmts[2].to_string(),
        "CF:imm1 := low:1[(%btx_d:imm16 >> 5:4u)]",
      )
      assert_string(stmts[6].to_string(), "PF:imm1 := unknown(btr:imm1)")
      assert_string(
        stmts[7].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, %btx_a:imm32, (%btx_d:imm16 & (not 0x20:16u)))",
      )
    }
    Err(reason) => fail(reason)
  }

  let btc64_mem = basic_bil_decode(
    "x86_64",
    b"\x48\x0f\xbb\x4d\xf8",
    start=0x7057UL,
  )
  match btc64_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%btx_a:imm64 := (RBP:imm64 - 8:64u)")
      assert_true(stmts[1].to_string().contains("RCX:imm64 a>> 6:64u"))
      assert_string(
        stmts[2].to_string(),
        "%btx_d:imm64 := load(mem:mem64x8, (%btx_a:imm64 + %btx_b:imm64)):imm64",
      )
      assert_string(stmts[3].to_string(), "%btx_o:imm6 := low:6[RCX:imm64]")
      assert_string(
        stmts[4].to_string(),
        "CF:imm1 := low:1[(%btx_d:imm64 >> %btx_o:imm6)]",
      )
      assert_string(stmts[8].to_string(), "PF:imm1 := unknown(btc:imm1)")
      assert_string(
        stmts[9].to_string(),
        "mem:mem64x8 := store(mem:mem64x8, (%btx_a:imm64 + %btx_b:imm64), (%btx_d:imm64 ^ (1:64u << %btx_o:imm6)))",
      )
    }
    Err(reason) => fail(reason)
  }

  let btc16_mem = basic_bil_decode(
    "x86",
    b"\x66\x0f\xbb\x4d\xfc",
    start=0x7058UL,
  )
  match btc16_mem.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 10)
      assert_string(stmts[0].to_string(), "%btx_a:imm32 := (EBP:imm32 - 4:32u)")
      assert_true(stmts[1].to_string().contains("CX:imm16 a>> 4:16u"))
      assert_string(
        stmts[2].to_string(),
        "%btx_d:imm16 := load(mem:mem32x8, (%btx_a:imm32 + %btx_b:imm32)):imm16",
      )
      assert_string(stmts[3].to_string(), "%btx_o:imm4 := low:4[CX:imm16]")
      assert_string(
        stmts[4].to_string(),
        "CF:imm1 := low:1[(%btx_d:imm16 >> %btx_o:imm4)]",
      )
      assert_string(stmts[8].to_string(), "PF:imm1 := unknown(btc:imm1)")
      assert_string(
        stmts[9].to_string(),
        "mem:mem32x8 := store(mem:mem32x8, (%btx_a:imm32 + %btx_b:imm32), (%btx_d:imm16 ^ (1:16u << %btx_o:imm4)))",
      )
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 setcc" {
  let sete = basic_bil_decode("x86", b"\x0f\x94\xc0", start=0x7053UL)
  match sete.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AL:imm8 := pad:8[ZF:imm1]"])
    Err(reason) => fail(reason)
  }

  let setne = basic_bil_decode("x86", b"\x0f\x95\xc3", start=0x7054UL)
  match setne.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["BL:imm8 := pad:8[(not ZF:imm1)]"])
    Err(reason) => fail(reason)
  }

  let setb_ext = basic_bil_decode("x86_64", b"\x41\x0f\x92\xc0", start=0x7055UL)
  match setb_ext.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8B:imm8 := pad:8[CF:imm1]"])
    Err(reason) => fail(reason)
  }

  let setg_mem = basic_bil_decode("x86_64", b"\x0f\x9f\x45\xf8", start=0x7057UL)
  match setg_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, (RBP:imm64 - 8:64u), pad:8[(not (ZF:imm1 | (SF:imm1 ^ OF:imm1)))])",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 cmovcc" {
  let cmove = basic_bil_decode("x86", b"\x0f\x44\xc1", start=0x7058UL)
  match cmove.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := ite(ZF:imm1, ECX:imm32, EAX:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let cmove16 = basic_bil_decode("x86", b"\x66\x0f\x44\xc1", start=0x7058UL)
  match cmove16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := ite(ZF:imm1, CX:imm16, AX:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let cmovne_mem = basic_bil_decode("x86", b"\x0f\x45\x45\xfc", start=0x7059UL)
  match cmovne_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := ite((not ZF:imm1), load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm32, EAX:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let cmovne_mem16 = basic_bil_decode(
    "x86",
    b"\x66\x0f\x45\x45\xfc",
    start=0x7059UL,
  )
  match cmovne_mem16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := ite((not ZF:imm1), load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16, AX:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let cmova64 = basic_bil_decode("x86_64", b"\x48\x0f\x47\xc1", start=0x705aUL)
  match cmova64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := ite((not (CF:imm1 | ZF:imm1)), RCX:imm64, RAX:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let cmovl16 = basic_bil_decode(
    "x86_64",
    b"\x66\x45\x0f\x4c\xc1",
    start=0x705aUL,
  )
  match cmovl16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8W:imm16 := ite((SF:imm1 ^ OF:imm1), R9W:imm16, R8W:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let cmovg_mem = basic_bil_decode(
    "x86_64",
    b"\x4c\x0f\x4f\x45\xf8",
    start=0x705bUL,
  )
  match cmovg_mem.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8:imm64 := ite((not (ZF:imm1 | (SF:imm1 ^ OF:imm1))), load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm64, R8:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let cmovg_mem16 = basic_bil_decode(
    "x86_64",
    b"\x66\x44\x0f\x4f\x45\xf8",
    start=0x705bUL,
  )
  match cmovg_mem16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8W:imm16 := ite((not (ZF:imm1 | (SF:imm1 ^ OF:imm1))), load(mem:mem64x8, (RBP:imm64 - 8:64u)):imm16, R8W:imm16)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 bswap" {
  let bswap32 = basic_bil_decode("x86", b"\x0f\xc8", start=0x7059UL)
  match bswap32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := concat(concat(concat(extract[7:0](EAX:imm32), extract[15:8](EAX:imm32)), extract[23:16](EAX:imm32)), extract[31:24](EAX:imm32))",
      ])
    Err(reason) => fail(reason)
  }

  let bswap64 = basic_bil_decode("x86_64", b"\x49\x0f\xc8", start=0x705aUL)
  match bswap64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "R8:imm64 := concat(concat(concat(concat(concat(concat(concat(extract[7:0](R8:imm64), extract[15:8](R8:imm64)), extract[23:16](R8:imm64)), extract[31:24](R8:imm64)), extract[39:32](R8:imm64)), extract[47:40](R8:imm64)), extract[55:48](R8:imm64)), extract[63:56](R8:imm64))",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 accumulator sign-extension ops" {
  let cdqe = basic_bil_decode("x86_64", b"\x48\x98", start=0x7056UL)
  match cdqe.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := extend:64[EAX:imm32]"])
    Err(reason) => fail(reason)
  }

  let cwde = basic_bil_decode("x86", b"\x98", start=0x7058UL)
  match cwde.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := extend:32[AX:imm16]"])
    Err(reason) => fail(reason)
  }

  let cbw = basic_bil_decode("x86", b"\x66\x98", start=0x7059UL)
  match cbw.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["AX:imm16 := extend:16[AL:imm8]"])
    Err(reason) => fail(reason)
  }

  let cqo = basic_bil_decode("x86_64", b"\x48\x99", start=0x705bUL)
  match cqo.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RDX:imm64 := high:64[extend:128[RAX:imm64]]",
      ])
    Err(reason) => fail(reason)
  }

  let cdq = basic_bil_decode("x86", b"\x99", start=0x705dUL)
  match cdq.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EDX:imm32 := high:32[extend:64[EAX:imm32]]",
      ])
    Err(reason) => fail(reason)
  }

  let cwd = basic_bil_decode("x86", b"\x66\x99", start=0x705eUL)
  match cwd.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["DX:imm16 := high:16[extend:32[AX:imm16]]"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 accumulator absolute mov" {
  let mov8_load = basic_bil_decode(
    "x86",
    b"\xa0\x04\x03\x02\x01",
    start=0x705fUL,
  )
  match mov8_load.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AL:imm8 := load(mem:mem32x8, 0x1020304:32u):imm8",
      ])
    Err(reason) => fail(reason)
  }

  let mov32_load = basic_bil_decode(
    "x86",
    b"\xa1\x78\x56\x34\x12",
    start=0x7060UL,
  )
  match mov32_load.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := load(mem:mem32x8, 0x12345678:32u):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let mov16_load = basic_bil_decode(
    "x86",
    b"\x66\xa1\x78\x56\x34\x12",
    start=0x7065UL,
  )
  match mov16_load.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := load(mem:mem32x8, 0x12345678:32u):imm16",
      ])
    Err(reason) => fail(reason)
  }

  let mov32_store = basic_bil_decode(
    "x86",
    b"\xa3\x78\x56\x34\x12",
    start=0x7061UL,
  )
  match mov32_store.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, 0x12345678:32u, EAX:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let mov16_store = basic_bil_decode(
    "x86",
    b"\x66\xa3\x78\x56\x34\x12",
    start=0x7066UL,
  )
  match mov16_store.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, 0x12345678:32u, AX:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let mov32_load_64 = basic_bil_decode(
    "x86_64",
    b"\xa1\x78\x56\x34\x12\x00\x00\x00\x00",
    start=0x7062UL,
  )
  match mov32_load_64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := load(mem:mem64x8, 0x12345678:64u):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let mov64_load = basic_bil_decode(
    "x86_64",
    b"\x48\xa1\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x7063UL,
  )
  match mov64_load.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := load(mem:mem64x8, 0x1122334455667788:64u):imm64",
      ])
    Err(reason) => fail(reason)
  }

  let mov16_load_64 = basic_bil_decode(
    "x86_64",
    b"\x66\xa1\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x7067UL,
  )
  match mov16_load_64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := load(mem:mem64x8, 0x1122334455667788:64u):imm16",
      ])
    Err(reason) => fail(reason)
  }

  let mov64_store = basic_bil_decode(
    "x86_64",
    b"\x48\xa3\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x7064UL,
  )
  match mov64_store.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, 0x1122334455667788:64u, RAX:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let mov16_store_64 = basic_bil_decode(
    "x86_64",
    b"\x66\xa3\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x7068UL,
  )
  match mov16_store_64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, 0x1122334455667788:64u, AX:imm16)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 leave" {
  let leave64 = basic_bil_decode("x86_64", b"\xc9", start=0x7040UL)
  match leave64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RSP:imm64 := RBP:imm64", "RBP:imm64 := load(mem:mem64x8, RSP:imm64):imm64",
        "RSP:imm64 := (RSP:imm64 + 8:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let leave32 = basic_bil_decode("x86", b"\xc9", start=0x7041UL)
  match leave32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ESP:imm32 := EBP:imm32", "EBP:imm32 := load(mem:mem32x8, ESP:imm32):imm32",
        "ESP:imm32 := (ESP:imm32 + 4:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let leave16 = basic_bil_decode("x86", b"\x66\xc9", start=0x7042UL)
  match leave16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "ESP:imm32 := EBP:imm32", "BP:imm16 := load(mem:mem32x8, ESP:imm32):imm16",
        "ESP:imm32 := (ESP:imm32 + 2:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let leave16_64 = basic_bil_decode("x86_64", b"\x66\xc9", start=0x7043UL)
  match leave16_64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RSP:imm64 := RBP:imm64", "BP:imm16 := load(mem:mem64x8, RSP:imm64):imm16",
        "RSP:imm64 := (RSP:imm64 + 2:64u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86_64 memory load fixture" {
  let mov_imm8 = basic_bil_decode("x86", b"\xb0\x7f", start=0x70eeUL)
  match mov_imm8.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AL:imm8 := 0x7F:8u"])
    Err(reason) => fail(reason)
  }

  let mov_imm8_ext = basic_bil_decode("x86_64", b"\x41\xb0\xff", start=0x70efUL)
  match mov_imm8_ext.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8B:imm8 := 0xFF:8u"])
    Err(reason) => fail(reason)
  }

  let mov_imm8_rm = basic_bil_decode(
    "x86_64",
    b"\x41\xc6\xc0\xff",
    start=0x70edUL,
  )
  match mov_imm8_rm.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["R8B:imm8 := 0xFF:8u"])
    Err(reason) => fail(reason)
  }

  let mov_imm = basic_bil_decode(
    "x86_64",
    b"\xb8\x78\x56\x34\x12",
    start=0x70f0UL,
  )
  match mov_imm.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["EAX:imm32 := 0x12345678:32u"])
    Err(reason) => fail(reason)
  }

  let mov_imm16 = basic_bil_decode("x86", b"\x66\xb8\x34\x12", start=0x70f4UL)
  match mov_imm16.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["AX:imm16 := 0x1234:16u"])
    Err(reason) => fail(reason)
  }

  let mov_imm64 = basic_bil_decode(
    "x86_64",
    b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11",
    start=0x70f8UL,
  )
  match mov_imm64.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["RAX:imm64 := 0x1122334455667788:64u"])
    Err(reason) => fail(reason)
  }

  let mov_imm64_from_i32 = basic_bil_decode(
    "x86_64",
    b"\x49\xc7\xc0\xff\xff\xff\xff",
    start=0x70fcUL,
  )
  match mov_imm64_from_i32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["R8:imm64 := 0xFFFFFFFFFFFFFFFF:64u"])
    Err(reason) => fail(reason)
  }

  let mov = basic_bil_decode("x86_64", b"\x8b\x40\x10", start=0x7100UL)
  match mov.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "EAX:imm32 := load(mem:mem64x8, (RAX:imm64 + 0x10:64u)):imm32",
      ])
    Err(reason) => fail(reason)
  }

  let mov8 = basic_bil_decode("x86", b"\x8a\x45\xfc", start=0x7102UL)
  match mov8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AL:imm8 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm8",
      ])
    Err(reason) => fail(reason)
  }

  let mov16 = basic_bil_decode("x86", b"\x66\x8b\x45\xfc", start=0x7103UL)
  match mov16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "AX:imm16 := load(mem:mem32x8, (EBP:imm32 - 4:32u)):imm16",
      ])
    Err(reason) => fail(reason)
  }

  let mov64 = basic_bil_decode("x86_64", b"\x48\x8b\x45\xf8", start=0x7104UL)
  match mov64.project_basic_bil_lift() {
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
  match indexed.project_basic_bil_lift() {
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
  match lea64.project_basic_bil_lift() {
    Ok(stmts) => assert_basic_bil_text(stmts, ["RAX:imm64 := RAX:imm64"])
    Err(reason) => fail(reason)
  }

  let indexed = basic_bil_decode(
    "x86_64",
    b"\x48\x8d\x44\x88\x10",
    start=0x710fUL,
  )
  match indexed.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "RAX:imm64 := ((RAX:imm64 + (RCX:imm64 * 4:64u)) + 0x10:64u)",
      ])
    Err(reason) => fail(reason)
  }

  let lea32 = basic_bil_decode("x86", b"\x8d\x45\xfc", start=0x7114UL)
  match lea32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["EAX:imm32 := (EBP:imm32 - 4:32u)"])
    Err(reason) => fail(reason)
  }

  let lea16 = basic_bil_decode("x86", b"\x66\x8d\x45\xfc", start=0x7118UL)
  match lea16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, ["AX:imm16 := low:16[(EBP:imm32 - 4:32u)]"])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers x86 memory stores" {
  let store64 = basic_bil_decode("x86_64", b"\x48\x89\x45\xf8", start=0x7110UL)
  match store64.project_basic_bil_lift() {
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
  match stack_store.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem64x8 := store(mem:mem64x8, RSP:imm64, RAX:imm64)",
      ])
    Err(reason) => fail(reason)
  }

  let store32 = basic_bil_decode("x86", b"\x89\x45\xfc", start=0x7118UL)
  match store32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), EAX:imm32)",
      ])
    Err(reason) => fail(reason)
  }

  let store16 = basic_bil_decode("x86", b"\x66\x89\x4d\xfc", start=0x7119UL)
  match store16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), CX:imm16)",
      ])
    Err(reason) => fail(reason)
  }

  let store8 = basic_bil_decode("x86", b"\x88\x45\xfc", start=0x711aUL)
  match store8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), AL:imm8)",
      ])
    Err(reason) => fail(reason)
  }

  let store_imm64 = basic_bil_decode(
    "x86_64",
    b"\x48\xc7\x45\xf8\x01\x00\x00\x00",
    start=0x711cUL,
  )
  match store_imm64.project_basic_bil_lift() {
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
  match store_imm32.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), 0x12345678:32u)",
      ])
    Err(reason) => fail(reason)
  }

  let store_imm16 = basic_bil_decode(
    "x86",
    b"\x66\xc7\x45\xfc\x34\x12",
    start=0x712aUL,
  )
  match store_imm16.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), 0x1234:16u)",
      ])
    Err(reason) => fail(reason)
  }

  let store_imm8 = basic_bil_decode("x86", b"\xc6\x45\xfc\x7f", start=0x712cUL)
  match store_imm8.project_basic_bil_lift() {
    Ok(stmts) =>
      assert_basic_bil_text(stmts, [
        "mem:mem32x8 := store(mem:mem32x8, (EBP:imm32 - 4:32u), 0x7F:8u)",
      ])
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift covers direct control transfers" {
  let jmp = basic_bil_decode("x86", b"\xeb\xfe", start=0x7200UL)
  match jmp.project_basic_bil_lift() {
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
  match near_jmp.project_basic_bil_lift() {
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
  match jne.project_basic_bil_lift() {
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
  match jg.project_basic_bil_lift() {
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

  let jecxz = basic_bil_decode("x86", b"\xe3\xfe", start=0x7211UL)
  match jecxz.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(ECX:imm32 == 0:32u)")
          assert_true(no.length() == 0)
          assert_true(yes.length() == 2)
          assert_true(
            @types.Stmt::decode(@types.Stmt::goto(), yes[0]) == Some("0x7211"),
          )
          assert_string(yes[1].to_string(), "jmp 0x7211:64u")
        }
        _ => fail("x86 jecxz branch did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  let jrcxz = basic_bil_decode("x86_64", b"\xe3\x03", start=0x7220UL)
  match jrcxz.project_basic_bil_lift() {
    Ok(stmts) => {
      assert_true(stmts.length() == 1)
      match stmts[0] {
        If(cond~, yes~, no~) => {
          assert_string(cond.to_string(), "(RCX:imm64 == 0:64u)")
          assert_true(no.length() == 0)
          assert_true(yes.length() == 2)
          assert_true(
            @types.Stmt::decode(@types.Stmt::goto(), yes[0]) == Some("0x7225"),
          )
          assert_string(yes[1].to_string(), "jmp 0x7225:64u")
        }
        _ => fail("x86_64 jrcxz branch did not lift to BIL if")
      }
    }
    Err(reason) => fail(reason)
  }

  // calls push the return address and jump to the callee (upstream x86
  // semantics); the Basic `call` hint precedes the jump
  let lift_text = (triple : String, bytes : Bytes, start : UInt64) => {
    try {
      let insn = basic_bil_decode(triple, bytes, start~)
      match insn.project_basic_bil_lift() {
        Ok(stmts) =>
          "\{insn.name()}:\n" +
          stmts.map(stmt => "  " + stmt.to_string()).join("\n")
        Err(reason) => "\{insn.name()}: \{reason}"
      }
    } catch {
      err => "decoding failed: \{err}"
    }
  }
  inspect(
    [
      lift_text("x86_64", b"\xe8\x47\xee\xff\xff", 0x7300UL),
      lift_text("x86", b"\xe8\x01\x00\x00\x00", 0x7310UL),
      lift_text("x86_64", b"\xff\xd0", 0x7320UL),
      lift_text("x86_64", b"\xff\x14\x24", 0x7330UL),
    ].join("\n"),
    content=(
      #|CALL64pcrel32:
      #|  RSP:imm64 := (RSP:imm64 - 8:64u)
      #|  mem:mem64x8 := store(mem:mem64x8, RSP:imm64, 0x7305:64u)
      #|  special @attribute:(bap:call 0x614c)
      #|  jmp 0x614C:64u
      #|CALLpcrel32:
      #|  ESP:imm32 := (ESP:imm32 - 4:32u)
      #|  mem:mem32x8 := store(mem:mem32x8, ESP:imm32, 0x7315:32u)
      #|  special @attribute:(bap:call 0x7316)
      #|  jmp 0x7316:32u
      #|CALL64r:
      #|  %call_target:imm64 := RAX:imm64
      #|  RSP:imm64 := (RSP:imm64 - 8:64u)
      #|  mem:mem64x8 := store(mem:mem64x8, RSP:imm64, 0x7322:64u)
      #|  special @attribute:(bap:call indirect)
      #|  jmp %call_target:imm64
      #|CALL64m:
      #|  %call_target:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 - 8:64u)
      #|  mem:mem64x8 := store(mem:mem64x8, RSP:imm64, 0x7333:64u)
      #|  special @attribute:(bap:call indirect)
      #|  jmp %call_target:imm64
    ),
  )
  let indirect_jmp = basic_bil_decode("x86_64", b"\xff\x60\x10", start=0x7322UL)
  match indirect_jmp.project_basic_bil_lift() {
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
  // returns pop the return address (and the immediate number of bytes) and
  // jump to it; far returns also pop the code segment selector slot
  inspect(
    [
      lift_text("x86_64", b"\xc3", 0x7400UL),
      lift_text("x86", b"\xc3", 0x7401UL),
      lift_text("x86", b"\xc2\x08\x00", 0x7402UL),
      lift_text("x86", b"\xcb", 0x7402UL),
      lift_text("x86", b"\xca\x10\x00", 0x7402UL),
      lift_text("x86_64", b"\xc2\x08\x00", 0x7402UL),
      lift_text("x86_64", b"\xcb", 0x7402UL),
      lift_text("x86_64", b"\xca\x10\x00", 0x7402UL),
    ].join("\n"),
    content=(
      #|RET64:
      #|  %ret_addr:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 + 8:64u)
      #|  jmp %ret_addr:imm64
      #|RET32:
      #|  %ret_addr:imm32 := load(mem:mem32x8, ESP:imm32):imm32
      #|  ESP:imm32 := (ESP:imm32 + 4:32u)
      #|  jmp %ret_addr:imm32
      #|RETI32:
      #|  %ret_addr:imm32 := load(mem:mem32x8, ESP:imm32):imm32
      #|  ESP:imm32 := (ESP:imm32 + 4:32u)
      #|  ESP:imm32 := (ESP:imm32 + 8:32u)
      #|  jmp %ret_addr:imm32
      #|LRET32:
      #|  %ret_addr:imm32 := load(mem:mem32x8, ESP:imm32):imm32
      #|  ESP:imm32 := (ESP:imm32 + 8:32u)
      #|  jmp %ret_addr:imm32
      #|LRETI32:
      #|  %ret_addr:imm32 := load(mem:mem32x8, ESP:imm32):imm32
      #|  ESP:imm32 := (ESP:imm32 + 8:32u)
      #|  ESP:imm32 := (ESP:imm32 + 0x10:32u)
      #|  jmp %ret_addr:imm32
      #|RETI64:
      #|  %ret_addr:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 + 8:64u)
      #|  RSP:imm64 := (RSP:imm64 + 8:64u)
      #|  jmp %ret_addr:imm64
      #|LRET32:
      #|  %ret_addr:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 + 0x10:64u)
      #|  jmp %ret_addr:imm64
      #|LRETI32:
      #|  %ret_addr:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 + 0x10:64u)
      #|  RSP:imm64 := (RSP:imm64 + 0x10:64u)
      #|  jmp %ret_addr:imm64
    ),
  )
}

///|
test "project Basic BIL lift covers ARM branch and return forms" {
  let branch = basic_bil_decode("armv7", b"\x05\x00\x00\xea", start=0x8424UL)
  match branch.project_basic_bil_lift() {
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
  match conditional.project_basic_bil_lift() {
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
  match bx.project_basic_bil_lift() {
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
      assert_true(stmts.length() == 26)
      assert_string(stmts[0].to_string(), "%sub_dst:imm64 := RSP:imm64")
      assert_string(stmts[1].to_string(), "%sub_src:imm64 := 8:64u")
      assert_string(
        stmts[2].to_string(),
        "RSP:imm64 := (%sub_dst:imm64 - %sub_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 3, "%sub_dst:imm64", "%sub_src:imm64", "RSP:imm64", "0:64u", false,
      )
      assert_true(stmts[25].to_string() == "jmp %ret_addr:imm64")
    }
    Err(reason) => fail(reason)
  }

  match disassembly.lift_basic_bil() {
    Ok(stmts) => {
      assert_true(stmts.length() == 26)
      assert_string(stmts[0].to_string(), "%sub_dst:imm64 := RSP:imm64")
      assert_true(
        @types.Stmt::decode(@types.Stmt::call(), stmts[11]) == Some("0x6350"),
      )
      assert_true(stmts[13].to_string().contains("load(mem:mem64x8"))
      assert_string(stmts[14].to_string(), "%add_dst:imm64 := RSP:imm64")
      assert_string(stmts[15].to_string(), "%add_src:imm64 := 8:64u")
      assert_string(
        stmts[16].to_string(),
        "RSP:imm64 := (%add_dst:imm64 + %add_src:imm64)",
      )
      assert_addsub_flag_tail(
        stmts, 17, "%add_dst:imm64", "%add_src:imm64", "RSP:imm64", "0:64u", true,
      )
      assert_true(stmts[25].to_string() == "jmp %ret_addr:imm64")
    }
    Err(reason) => fail(reason)
  }

  let project = Project::empty(@core_theory.Target::unknown()).with_disassembly(
    disassembly,
  )
  match project.lift_basic_bil() {
    Ok(stmts) => assert_true(stmts.length() == 26)
    Err(reason) => fail(reason)
  }

  let disasm = ProjectDisasm::from_project(project)
  match disasm.lift_basic_bil() {
    Ok(stmts) => assert_true(stmts.length() == 26)
    Err(reason) => fail(reason)
  }
}

///|
test "project Basic BIL lift reports unsupported instruction context" {
  // a lone 0x0f is an invalid instruction for the llvm backend
  let disasm = match ProjectDisassemblyBasic::create("x86_64", backend="llvm") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7600UL,
    b"\x0f",
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) => assert_true(result.instruction() is None)
    Err(reason) => fail(reason)
  }
  // the raw backend decodes it as a `.byte` pseudo instruction, which has
  // no Basic BIL
  let raw_disasm = match
    ProjectDisassemblyBasic::create("x86_64", backend="raw") {
    Ok(disasm) => disasm
    Err(reason) => fail(reason)
  }
  let raw = match raw_disasm.insn_of_mem(memory) {
    Ok(result) =>
      match result.instruction() {
        Some(insn) => insn
        None => fail("missing raw instruction")
      }
    Err(reason) => fail(reason)
  }
  match raw.lift_basic_bil() {
    Err(reason) => assert_true(reason.contains("unsupported Basic BIL lift"))
    Ok(_) => fail("raw byte instruction lifted")
  }
  let disassembly = ProjectDisassemblyState::create(blocks=[memory], instructions=[
    raw,
  ])
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
