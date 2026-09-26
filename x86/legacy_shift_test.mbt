// Shifts, double shifts, rotates, bit tests and bit scans of the legacy
// lifter. Flags are shown as CF PF AF ZF SF OF DF.

///|
test "legacy shl/shr/sar" {
  // shl eax, 1 (d1 /4)
  let o = exec32(b"\xd1\xe0", regs=[("EAX", 0xc0000001)])
  assert_eq(get_word(o, "EAX"), 0x80000002)
  inspect(flags_text(o), content="CF=1 PF=0 AF=? ZF=0 SF=1 OF=0 DF=0")
  // shl eax, 4 (c1 /4 ib): OF undefined for counts > 1
  let o = exec32(b"\xc1\xe0\x04", regs=[("EAX", 0x1800000f)])
  assert_eq(get_word(o, "EAX"), 0x800000f0)
  inspect(flags_text(o), content="CF=1 PF=1 AF=? ZF=0 SF=1 OF=? DF=0")
  // shr eax, cl with cl = 33: the count is masked to 1
  let o = exec32(b"\xd3\xe8", regs=[("EAX", 0x80000003), ("ECX", 33)])
  assert_eq(get_word(o, "EAX"), 0x40000001)
  inspect(flags_text(o), content="CF=1 PF=0 AF=? ZF=0 SF=0 OF=1 DF=0")
  // sar eax, 1
  let o = exec32(b"\xd1\xf8", regs=[("EAX", 0x80000001)])
  assert_eq(get_word(o, "EAX"), 0xc0000000)
  inspect(flags_text(o), content="CF=1 PF=1 AF=? ZF=0 SF=1 OF=0 DF=0")
  // shl rax, cl with cl = 0 leaves the flags alone
  let o = exec64(
    b"\x48\xd3\xe0",
    regs=[("RAX", 5), ("RCX", 0x40)],
    flag_bits=0b1,
  )
  assert_eq(get_word(o, "RAX"), 5)
  inspect(flags_text(o), content="CF=1 PF=0 AF=0 ZF=0 SF=0 OF=0 DF=0")
  // shl byte [rbx], 1
  let before = load_mem(exec64(b"\x90"), DATA, 1)
  let o = exec64(b"\xd0\x23", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 1), (before << 1) & 0xff)
}

///|
test "legacy shld/shrd" {
  // shld eax, ebx, 8
  let o = exec32(b"\x0f\xa4\xd8\x08", regs=[
    ("EAX", 0x11223344),
    ("EBX", 0xaabbccdd),
  ])
  assert_eq(get_word(o, "EAX"), 0x223344aa)
  assert_eq(get_flag(o, "CF"), 1)
  // shrd eax, ebx, cl
  let o = exec32(b"\x0f\xad\xd8", regs=[
    ("EAX", 0x11223344),
    ("EBX", 0xaabbccdd),
    ("ECX", 4),
  ])
  assert_eq(get_word(o, "EAX"), 0xd1122334)
  assert_eq(get_flag(o, "CF"), 0)
}

///|
test "legacy rol/ror" {
  inspect(
    bil_text(lift32(b"\xd1\xc0")),
    content=(
      #|%v_1:imm32 := ((1:32u & 0x1F:32u) % 0x20:32u)
      #|EAX:imm32 := ((low:32[EAX:imm32] << %v_1:imm32) | (low:32[EAX:imm32] >> (0x20:32u - %v_1:imm32)))
      #|if (%v_1:imm32 == 0:32u) then 1 stmts else 1 stmts
    ),
  )
  // rol eax, 4
  let o = exec32(b"\xc1\xc0\x04", regs=[("EAX", 0x12345678)])
  assert_eq(get_word(o, "EAX"), 0x23456781)
  // ror al, 1
  let o = exec32(b"\xd0\xc8", regs=[("EAX", 0x03)])
  assert_eq(get_word(o, "EAX") & 0xff, 0x81)
  // upstream only updates CF when the count is zero (Intel: CF = the bit
  // rotated in when the count is not zero), so CF keeps its old value here
  let o = exec32(b"\xd1\xc0", regs=[("EAX", 0x80000000)])
  assert_eq(get_word(o, "EAX"), 1)
  assert_eq(get_flag(o, "CF"), 0)
  // rcl/rcr are not modeled upstream
  assert_eq(
    @x86.legacy_failure(X86, b"\xd1\xd0", addr=0),
    Some("no semantics: unsupported opcode: d1/2"),
  )
}

///|
test "legacy bt/bsf/bsr/tzcnt/lzcnt" {
  // bt eax, ebx (0f a3)
  let o = exec32(b"\x0f\xa3\xd8", regs=[("EAX", 0x10), ("EBX", 36)])
  assert_eq(get_flag(o, "CF"), 1)
  assert_eq(o.undefined.contains("OF"), true)
  // bt dword [ebx], 9 (0f ba /4 ib): bit 1 of the second byte
  let o = exec32(b"\x0f\xba\x23\x09", regs=[("EBX", DATA)])
  let byte = load_mem(o, DATA + 1, 1)
  assert_eq(get_flag(o, "CF").to_uint64(), (byte >> 1) & 1)
  // bts eax, 3 (0f ba /5) lifts as a plain bt upstream: EAX is unchanged
  let o = exec32(b"\x0f\xba\xe8\x03", regs=[("EAX", 0)])
  assert_eq(get_word(o, "EAX"), 0)
  // bsf eax, ebx
  let o = exec32(b"\x0f\xbc\xc3", regs=[("EBX", 0x50)])
  assert_eq(get_word(o, "EAX"), 4)
  assert_eq(get_flag(o, "ZF"), 0)
  // bsr eax, ebx
  let o = exec32(b"\x0f\xbd\xc3", regs=[("EBX", 0x50)])
  assert_eq(get_word(o, "EAX"), 6)
  // bsf with a zero source: ZF = 1, destination undefined
  let o = exec32(b"\x0f\xbc\xc3", regs=[("EBX", 0)])
  assert_eq(get_flag(o, "ZF"), 1)
  assert_eq(o.undefined.contains("EAX"), true)
  // tzcnt eax, ebx (f3 0f bc) with a zero source: EAX = 32, CF = 1
  let o = exec32(b"\xf3\x0f\xbc\xc3", regs=[("EBX", 0)])
  assert_eq(get_word(o, "EAX"), 32)
  assert_eq(get_flag(o, "CF"), 1)
  // lzcnt rax, rbx (f3 48 0f bd)
  let o = exec64(b"\xf3\x48\x0f\xbd\xc3", regs=[("RBX", 0x00ff)])
  assert_eq(get_word(o, "RAX"), 56)
  assert_eq(get_flag(o, "ZF"), 0)
}
