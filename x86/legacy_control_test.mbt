// Stack, control flow, conditional and string instructions of the legacy
// lifter.

///|
test "legacy push/pop/pushf/popf/leave" {
  // push rbx
  let o = exec64(b"\x53", regs=[
    ("RSP", STACK + 0x100),
    ("RBX", 0x1122334455667788),
  ])
  assert_eq(get_word(o, "RSP"), STACK + 0xf8)
  assert_eq(load_mem(o, STACK + 0xf8, 8), 0x1122334455667788)
  // push -1 (6a ib, sign-extended to 64 bits)
  let o = exec64(b"\x6a\xff", regs=[("RSP", STACK + 0x100)])
  assert_eq(load_mem(o, STACK + 0xf8, 8), 0xffffffffffffffff)
  // push imm32 in 32-bit mode
  let o = exec32(b"\x68\x78\x56\x34\x12", regs=[("ESP", STACK + 0x100)])
  assert_eq(load_mem(o, STACK + 0xfc, 4), 0x12345678)
  // push rsp pushes the old value
  let o = exec64(b"\x54", regs=[("RSP", STACK + 0x100)])
  assert_eq(load_mem(o, STACK + 0xf8, 8), STACK + 0x100)
  // pop rax
  let o = exec64(b"\x58", regs=[("RSP", STACK + 0x10)])
  assert_eq(get_word(o, "RAX"), load_mem(o, STACK + 0x10, 8))
  assert_eq(get_word(o, "RSP"), STACK + 0x18)
  // pop esp: no increment (32-bit mode)
  let o = exec32(b"\x5c", regs=[("ESP", STACK + 0x10)])
  assert_eq(get_word(o, "ESP"), load_mem(o, STACK + 0x10, 4))
  // push qword [rbx] (ff /6)
  let o = exec64(b"\xff\x33", regs=[("RSP", STACK + 0x100), ("RBX", DATA)])
  assert_eq(load_mem(o, STACK + 0xf8, 8), load_mem(o, DATA, 8))
  // pushfd/popfd round trip of the modeled flags (32-bit mode)
  inspect(
    bil_text(lift32(b"\x9d")),
    content=(
      #|%v_1:imm32 := load(mem:mem32x8, ESP:imm32):imm32
      #|ESP:imm32 := (ESP:imm32 + 4:32u)
      #|OF:imm1 := extract[11:11](%v_1:imm32)
      #|DF:imm1 := extract[10:10](%v_1:imm32)
      #|SF:imm1 := extract[7:7](%v_1:imm32)
      #|ZF:imm1 := extract[6:6](%v_1:imm32)
      #|AF:imm1 := extract[4:4](%v_1:imm32)
      #|PF:imm1 := extract[2:2](%v_1:imm32)
      #|CF:imm1 := extract[0:0](%v_1:imm32)
    ),
  )
  let o = exec32(b"\x9d", regs=[("ESP", STACK)])
  let image = load_mem(o, STACK, 4)
  assert_eq(get_flag(o, "CF").to_uint64(), image & 1)
  assert_eq(get_flag(o, "OF").to_uint64(), (image >> 11) & 1)
  // pushf stores unknown bits: the stored value is undefined
  let o = exec32(b"\x9c", regs=[("ESP", STACK + 0x100)])
  assert_eq(o.undefined.contains("mem"), true)
  // leave
  let o = exec64(b"\xc9", regs=[("RBP", STACK + 0x20), ("RSP", 0)])
  assert_eq(get_word(o, "RSP"), STACK + 0x28)
  assert_eq(get_word(o, "RBP"), load_mem(o, STACK + 0x20, 8))
}

///|
test "legacy call/ret/jmp" {
  // call rel32 at 0x400000: pushes 0x400005 and jumps to 0x400105
  inspect(
    bil_text(lift64(b"\xe8\x00\x01\x00\x00")),
    content=(
      #|RSP:imm64 := (RSP:imm64 - 8:64u)
      #|mem:mem64x8 := store(mem:mem64x8, RSP:imm64, 0x400005:64u)
      #|jmp 0x400105:64u
    ),
  )
  let o = exec64(b"\xe8\x00\x01\x00\x00", regs=[("RSP", STACK + 0x100)])
  assert_eq(o.jump, Some(0x400105))
  assert_eq(load_mem(o, STACK + 0xf8, 8), 0x400005)
  // call rax (indirect: the target is read before RSP changes)
  let o = exec64(b"\xff\xd0", regs=[("RSP", STACK + 0x100), ("RAX", 0x1234)])
  assert_eq(o.jump, Some(0x1234))
  assert_eq(load_mem(o, STACK + 0xf8, 8), 0x400002)
  // call dword [esp + 4] (32-bit mode)
  let o = exec32(b"\xff\x54\x24\x04", regs=[("ESP", STACK)])
  assert_eq(o.jump, Some(load_mem(o, STACK + 4, 4)))
  // ret
  let o = exec64(b"\xc3", regs=[("RSP", STACK)])
  assert_eq(o.jump, Some(load_mem(o, STACK, 8)))
  assert_eq(get_word(o, "RSP"), STACK + 8)
  // ret 0x10
  let o = exec32(b"\xc2\x10\x00", regs=[("ESP", STACK)])
  assert_eq(get_word(o, "ESP"), STACK + 0x14)
  // rep ret is accepted
  let o = exec64(b"\xf3\xc3", regs=[("RSP", STACK)])
  assert_eq(get_word(o, "RSP"), STACK + 8)
  // far ret is not modeled
  assert_eq(
    @x86.legacy_failure(X8664, b"\xcb", addr=0),
    Some("no semantics: long retn not supported"),
  )
  // jmp rel8 backwards
  let o = exec64(b"\xeb\xfe", addr=0x401000)
  assert_eq(o.jump, Some(0x401000))
  // jmp rel32
  let o = exec32(b"\xe9\x00\x00\x00\x80", addr=0x1000)
  assert_eq(o.jump, Some(0x80001005))
  // jmp qword [rip + 0] reads the target from memory
  let o = exec64(b"\xff\x25\x00\x00\x00\x00", addr=DATA - 6)
  assert_eq(o.jump, Some(load_mem(o, DATA, 8)))
}

///|
test "legacy jcc/setcc/jecxz" {
  // je +0x10: flag_bits bit 3 is ZF
  let o = exec64(b"\x74\x10", addr=0x1000, flag_bits=0b1000)
  assert_eq(o.jump, Some(0x1012))
  let o = exec64(b"\x74\x10", addr=0x1000)
  assert_eq(o.jump, None)
  // jl (SF != OF) with SF = 1, OF = 0
  let o = exec64(b"\x0f\x8c\x00\x01\x00\x00", addr=0x1000, flag_bits=0b10000)
  assert_eq(o.jump, Some(0x1106))
  // jbe (CF | ZF) not taken
  let o = exec64(b"\x76\x00", addr=0x1000)
  assert_eq(o.jump, None)
  // jg: ZF = 0 and SF = OF
  let o = exec64(b"\x7f\x02", addr=0x1000, flag_bits=0b110000)
  assert_eq(o.jump, Some(0x1004))
  // setne al
  let o = exec64(b"\x0f\x95\xc0", regs=[("RAX", 0xff00)])
  assert_eq(get_word(o, "RAX"), 0xff01)
  // setb byte [rbx]
  let o = exec64(b"\x0f\x92\x03", regs=[("RBX", DATA)], flag_bits=1)
  assert_eq(load_mem(o, DATA, 1), 1)
  // jecxz (e3) in 32-bit mode
  let o = exec32(b"\xe3\x05", regs=[("ECX", 0)], addr=0x1000)
  assert_eq(o.jump, Some(0x1007))
  let o = exec32(b"\xe3\x05", regs=[("ECX", 1)], addr=0x1000)
  assert_eq(o.jump, None)
}

///|
test "legacy string instructions" {
  // movsb forward
  let o = exec64(b"\xa4", regs=[("RSI", DATA), ("RDI", DATA + 0x100)])
  assert_eq(load_mem(o, DATA + 0x100, 1), load_mem(o, DATA, 1))
  assert_eq((get_word(o, "RSI"), get_word(o, "RDI")), (DATA + 1, DATA + 0x101))
  // movsd backward (DF = 1)
  let o = exec32(
    b"\xa5",
    regs=[("ESI", DATA + 8), ("EDI", DATA + 0x100)],
    flag_bits=0b1000000,
  )
  assert_eq((get_word(o, "ESI"), get_word(o, "EDI")), (DATA + 4, DATA + 0xfc))
  // rep movsq copies RCX quadwords
  inspect(
    bil_text(lift64(b"\xf3\x48\xa5")),
    content=(
      #|%v_1:imm1 := 1:1u
      #|while ((RCX:imm64 != 0:64u) & %v_1:imm1) do 4 stmts
    ),
  )
  let o = exec64(b"\xf3\x48\xa5", regs=[
    ("RSI", DATA),
    ("RDI", DATA + 0x100),
    ("RCX", 3),
  ])
  assert_eq(get_word(o, "RCX"), 0)
  assert_eq(load_mem(o, DATA + 0x110, 8), load_mem(o, DATA + 0x10, 8))
  assert_eq(get_word(o, "RDI"), DATA + 0x118)
  // rep stosd
  let o = exec32(b"\xf3\xab", regs=[
    ("EDI", DATA),
    ("ECX", 4),
    ("EAX", 0xdeadbeef),
  ])
  assert_eq(load_mem(o, DATA + 12, 4), 0xdeadbeef)
  assert_eq(get_word(o, "EDI"), DATA + 16)
  // repne stos is not modeled
  assert_eq(
    @x86.legacy_failure(X86, b"\xf2\xab", addr=0),
    Some("no semantics: unsupported prefix for stos"),
  )
  // repne scasb finds a byte (like strlen)
  let data = exec64(b"\x90")
  let target = load_mem(data, DATA + 5, 1)
  let o = exec64(b"\xf2\xae", regs=[
    ("RDI", DATA),
    ("RCX", 100),
    ("RAX", target),
  ])
  // stops after the first match
  let found = get_word(o, "RDI") - 1
  assert_eq(load_mem(o, found, 1), target)
  assert_eq(get_flag(o, "ZF"), 1)
  // repe cmpsb stops at the first difference
  let o = exec64(b"\xf3\xa6", regs=[
    ("RSI", DATA),
    ("RDI", DATA + 1),
    ("RCX", 10),
  ])
  assert_eq(get_word(o, "RCX"), 9)
  assert_eq(get_flag(o, "ZF"), 0)
  // lodsb is not modeled by the legacy lifter
  assert_eq(
    @x86.legacy_failure(X8664, b"\xac", addr=0),
    Some("no semantics: unsupported single opcode: ac"),
  )
}

///|
test "legacy system and x87 instructions" {
  assert_eq(bil_text(lift64(b"\x90")), "")
  assert_eq(bil_text(lift64(b"\x0f\x1f\x44\x00\x00")), "")
  assert_eq(bil_text(lift64(b"\xf4")), "")
  assert_eq(exec64(b"\xcc").exn, Some(3))
  assert_eq(exec32(b"\xcd\x80").exn, Some(0x80))
  inspect(
    bil_text(lift64(b"\x0f\x05")),
    content=(
      #|special @attribute:(bap:call syscall)
    ),
  )
  inspect(
    bil_text(lift32(b"\x0f\x34")),
    content=(
      #|special @attribute:(bap:call syscall)
    ),
  )
  // syscall is only decoded in 64-bit mode
  assert_eq(
    @x86.legacy_failure(X86, b"\x0f\x05", addr=0),
    Some("no semantics: unsupported opcode: 0f 5"),
  )
  inspect(
    bil_text(lift64(b"\x0f\xa2")),
    content=(
      #|RAX:imm64 := pad:64[unknown(cpuid:imm32)]
      #|RBX:imm64 := pad:64[unknown(cpuid:imm32)]
      #|RCX:imm64 := pad:64[unknown(cpuid:imm32)]
      #|RDX:imm64 := pad:64[unknown(cpuid:imm32)]
    ),
  )
  let o = exec64(b"\x0f\x31")
  assert_eq(o.undefined.contains("RAX"), true)
  // fnstcw word [rbx] / fldcw word [rbx]
  let o = exec64(b"\xd9\x3b", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 2), 0x37f)
  let o = exec64(b"\xd9\x2b", regs=[("RBX", DATA)])
  assert_eq(get_word(o, "FPU_CONTROL"), load_mem(o, DATA, 2))
  // stmxcsr / ldmxcsr
  let o = exec64(b"\x0f\xae\x1b", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 4), 0x1f80)
  let o = exec64(b"\x0f\xae\x13", regs=[("RBX", DATA)])
  assert_eq(get_word(o, "MXCSR"), load_mem(o, DATA, 4))
  // the x87 register stack is not modeled by the legacy lifter
  assert_eq(
    @x86.legacy_failure(X86, b"\xdd\x1c\x24", addr=0),
    Some("no semantics: unsupported FPU flags"),
  )
  assert_eq(
    @x86.legacy_failure(X86, b"\xdb\x2c\x24", addr=0),
    Some("no semantics: unsupported FPU register stack"),
  )
  assert_eq(
    @x86.legacy_failure(X86, b"\xd8\xc1", addr=0),
    Some("no semantics: unsupported opcode: d8/0"),
  )
}

///|
test "legacy errors" {
  // truncated instruction
  assert_eq(
    @x86.legacy_failure(X8664, b"\x48\x8b", addr=0),
    Some("invalid instruction: truncated instruction"),
  )
  // lea with a register operand
  assert_eq(
    @x86.legacy_failure(X8664, b"\x8d\xc0", addr=0),
    Some("invalid instruction: invalid lea (must be address)"),
  )
  // lifting raises Unsupported for both
  let raised = try @x86.lift_legacy(X8664, b"\x8d\xc0", addr=0) catch {
    @mc.Unsupported(opcode~, target~) => "\{opcode} \{target}"
    e => "other: \{e.message()}"
  } noraise {
    _ => "lifted"
  }
  assert_eq(raised, "x86 x86_64")
  assert_eq(@x86.legacy_length(X8664, b"\x48\x8b\x43\x08\x90", addr=0), Some(4))
  assert_eq(@x86.legacy_length(X8664, b"\x8d\xc0", addr=0), None)
}
