// Arithmetic and logic instructions of the legacy lifter; the expected
// values follow the Intel SDM. Flags are shown as CF PF AF ZF SF OF DF.

///|
test "legacy add: BIL and flags" {
  // add eax, ebx (32-bit mode)
  inspect(
    bil_text(lift32(b"\x01\xd8")),
    content=(
      #|%v_1:imm32 := low:32[EAX:imm32]
      #|%v_2:imm32 := low:32[EBX:imm32]
      #|EAX:imm32 := (low:32[EAX:imm32] + %v_2:imm32)
      #|CF:imm1 := (low:32[EAX:imm32] < %v_1:imm32)
      #|OF:imm1 := ((high:1[%v_1:imm32] == high:1[%v_2:imm32]) & (high:1[%v_1:imm32] ^ high:1[low:32[EAX:imm32]]))
      #|AF:imm1 := (0x10:32u == (0x10:32u & ((low:32[EAX:imm32] ^ %v_1:imm32) ^ %v_2:imm32)))
      #|PF:imm1 := (not low:1[let %v_3:imm32 = ((low:32[EAX:imm32] >> 4:32u) ^ low:32[EAX:imm32]) in let %v_3:imm32 = ((%v_3:imm32 >> 2:32u) ^ %v_3:imm32) in ((%v_3:imm32 >> 1:32u) ^ %v_3:imm32)])
      #|SF:imm1 := high:1[low:32[EAX:imm32]]
      #|ZF:imm1 := (0:32u == low:32[EAX:imm32])
    ),
  )
  // 0x7fffffff + 1: signed overflow, AF, PF (0x00 has even parity), SF
  let o = exec32(b"\x01\xd8", regs=[("EAX", 0x7fffffff), ("EBX", 1)])
  assert_eq(get_word(o, "EAX"), 0x80000000)
  inspect(flags_text(o), content="CF=0 PF=1 AF=1 ZF=0 SF=1 OF=1 DF=0")
  // 0xffffffff + 1: carry and zero
  let o = exec32(b"\x01\xd8", regs=[("EAX", 0xffffffff), ("EBX", 1)])
  assert_eq(get_word(o, "EAX"), 0)
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=1 SF=0 OF=0 DF=0")
  // add al, 0x7f with al = 0x01 (04 ib)
  let o = exec64(b"\x04\x7f", regs=[("RAX", 0x101)])
  assert_eq(get_word(o, "RAX"), 0x180)
  inspect(flags_text(o), content="CF=0 PF=0 AF=1 ZF=0 SF=1 OF=1 DF=0")
  // add rax, -1 (83 /0 with a sign-extended imm8)
  let o = exec64(b"\x48\x83\xc0\xff", regs=[("RAX", 5)])
  assert_eq(get_word(o, "RAX"), 4)
  inspect(flags_text(o), content="CF=1 PF=0 AF=1 ZF=0 SF=0 OF=0 DF=0")
  // add dword [rbx], 1 (memory destination)
  let o = exec64(b"\x83\x03\x01", regs=[("RBX", DATA)])
  let before = load_mem(exec64(b"\x90"), DATA, 4)
  assert_eq(load_mem(o, DATA, 4), (before + 1) & 0xffffffff)
}

///|
test "legacy adc/sub/sbb/cmp/neg/inc/dec" {
  // adc eax, ebx with CF = 1
  let o = exec32(
    b"\x11\xd8",
    regs=[("EAX", 0xffffffff), ("EBX", 0)],
    flag_bits=1,
  )
  assert_eq(get_word(o, "EAX"), 0)
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=1 SF=0 OF=0 DF=0")
  // sub eax, ebx: 1 - 2 borrows
  let o = exec32(b"\x29\xd8", regs=[("EAX", 1), ("EBX", 2)])
  assert_eq(get_word(o, "EAX"), 0xffffffff)
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=0 SF=1 OF=0 DF=0")
  // sub eax, ebx: 0x80000000 - 1 overflows
  let o = exec32(b"\x29\xd8", regs=[("EAX", 0x80000000), ("EBX", 1)])
  assert_eq(get_word(o, "EAX"), 0x7fffffff)
  inspect(flags_text(o), content="CF=0 PF=1 AF=1 ZF=0 SF=0 OF=1 DF=0")
  // sbb eax, ebx with CF = 1: 5 - 2 - 1
  let o = exec32(b"\x19\xd8", regs=[("EAX", 5), ("EBX", 2)], flag_bits=1)
  assert_eq(get_word(o, "EAX"), 2)
  inspect(flags_text(o), content="CF=0 PF=0 AF=0 ZF=0 SF=0 OF=0 DF=0")
  // sbb eax, ebx with CF = 1 and ebx = 0xffffffff: always borrows
  let o = exec32(
    b"\x19\xd8",
    regs=[("EAX", 5), ("EBX", 0xffffffff)],
    flag_bits=1,
  )
  assert_eq(get_word(o, "EAX"), 5)
  assert_eq(get_flag(o, "CF"), 1)
  // cmp eax, ebx leaves eax
  let o = exec32(b"\x39\xd8", regs=[("EAX", 3), ("EBX", 3)])
  assert_eq(get_word(o, "EAX"), 3)
  inspect(flags_text(o), content="CF=0 PF=1 AF=0 ZF=1 SF=0 OF=0 DF=0")
  // cmp al, 0x80 with al = 0x7f
  let o = exec64(b"\x3c\x80", regs=[("RAX", 0x7f)])
  inspect(flags_text(o), content="CF=1 PF=1 AF=0 ZF=0 SF=1 OF=1 DF=0")
  // neg eax
  let o = exec32(b"\xf7\xd8", regs=[("EAX", 1)])
  assert_eq(get_word(o, "EAX"), 0xffffffff)
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=0 SF=1 OF=0 DF=0")
  let o = exec32(b"\xf7\xd8", regs=[("EAX", 0x80000000)])
  assert_eq(get_word(o, "EAX"), 0x80000000)
  assert_eq(get_flag(o, "OF"), 1)
  let o = exec32(b"\xf7\xd8", regs=[("EAX", 0)])
  assert_eq(get_flag(o, "CF"), 0)
  // inc eax keeps CF; 32-bit mode 40
  let o = exec32(b"\x40", regs=[("EAX", 0x7fffffff)], flag_bits=1)
  assert_eq(get_word(o, "EAX"), 0x80000000)
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=0 SF=1 OF=1 DF=0")
  // dec rcx (48 ff c9)
  let o = exec64(b"\x48\xff\xc9", regs=[("RCX", 1)])
  assert_eq(get_word(o, "RCX"), 0)
  inspect(flags_text(o), content="CF=0 PF=1 AF=0 ZF=1 SF=0 OF=0 DF=0")
}

///|
test "legacy logic: and/or/xor/test/not" {
  // and eax, 0xf0f0 (25 id)
  let o = exec64(b"\x25\xf0\xf0\x00\x00", regs=[("RAX", 0xffffffffffff1234)])
  assert_eq(get_word(o, "RAX"), 0x1030)
  assert_eq(o.undefined.contains("AF"), true)
  inspect(flags_text(o), content="CF=0 PF=1 AF=? ZF=0 SF=0 OF=0 DF=0")
  // or rax, -1 (83 /1 sign-extended)
  let o = exec64(b"\x48\x83\xc8\xff", regs=[("RAX", 0)])
  assert_eq(get_word(o, "RAX"), 0xffffffffffffffff)
  inspect(flags_text(o), content="CF=0 PF=1 AF=? ZF=0 SF=1 OF=0 DF=0")
  // xor eax, eax: the zeroing idiom
  inspect(
    bil_text(lift64(b"\x31\xc0")),
    content=(
      #|RAX:imm64 := pad:64[0:32u]
      #|AF:imm1 := unknown(AF is undefined after xor:imm1)
      #|ZF:imm1 := 1:1u
      #|PF:imm1 := 1:1u
      #|OF:imm1 := 0:1u
      #|CF:imm1 := 0:1u
      #|SF:imm1 := 0:1u
    ),
  )
  // xor ebx, eax
  let o = exec64(b"\x31\xc3", regs=[("RAX", 0xff), ("RBX", 0xf0f)])
  assert_eq(get_word(o, "RBX"), 0xff0)
  // test al, 0x80 (a8 ib)
  let o = exec64(b"\xa8\x80", regs=[("RAX", 0x80)])
  assert_eq(get_word(o, "RAX"), 0x80)
  inspect(flags_text(o), content="CF=0 PF=0 AF=? ZF=0 SF=1 OF=0 DF=0")
  // test rax, rax with rax = 0
  let o = exec64(b"\x48\x85\xc0", regs=[("RAX", 0)])
  assert_eq(get_flag(o, "ZF"), 1)
  // not ecx
  let o = exec64(b"\xf7\xd1", regs=[("RCX", 0xffffffff00000000)])
  assert_eq(get_word(o, "RCX"), 0xffffffff)
}

///|
test "legacy mul/imul/div/idiv" {
  // mul ebx: edx:eax = eax * ebx
  let o = exec32(b"\xf7\xe3", regs=[("EAX", 0x80000000), ("EBX", 4)])
  assert_eq((get_word(o, "EDX"), get_word(o, "EAX")), (2, 0))
  assert_eq((get_flag(o, "CF"), get_flag(o, "OF")), (1, 1))
  // mul bl: ax = al * bl
  let o = exec32(b"\xf6\xe3", regs=[("EAX", 0x12340010), ("EBX", 0x10)])
  assert_eq(get_word(o, "EAX"), 0x12340100)
  // imul rax, rbx, 3 (6b /r ib)
  let o = exec64(b"\x48\x6b\xc3\x03", regs=[("RBX", 0xfffffffffffffffe)])
  assert_eq(get_word(o, "RAX"), 0xfffffffffffffffa)
  assert_eq((get_flag(o, "CF"), get_flag(o, "OF")), (0, 0))
  // imul eax, ebx (0f af) overflowing
  let o = exec64(b"\x0f\xaf\xc3", regs=[("RAX", 0x10000), ("RBX", 0x10000)])
  assert_eq(get_word(o, "RAX"), 0)
  assert_eq((get_flag(o, "CF"), get_flag(o, "OF")), (1, 1))
  // one-operand imul ebx: edx:eax = eax * ebx (signed)
  let o = exec32(b"\xf7\xeb", regs=[("EAX", 0xfffffffe), ("EBX", 3)])
  assert_eq((get_word(o, "EDX"), get_word(o, "EAX")), (0xffffffff, 0xfffffffa))
  // upstream checks the high half against zero, so a negative result that
  // fits in 32 bits still sets CF/OF (Intel: CF = OF = 0)
  assert_eq((get_flag(o, "CF"), get_flag(o, "OF")), (1, 1))
  // div ebx: edx:eax / ebx
  let o = exec32(b"\xf7\xf3", regs=[("EDX", 1), ("EAX", 5), ("EBX", 2)])
  assert_eq((get_word(o, "EAX"), get_word(o, "EDX")), (0x80000002, 1))
  assert_eq(o.undefined.contains("CF"), true)
  // div by zero raises #DE
  let o = exec32(b"\xf7\xf3", regs=[("EDX", 0), ("EAX", 5), ("EBX", 0)])
  assert_eq(o.exn, Some(0))
  // quotient overflow raises #DE
  let o = exec32(b"\xf7\xf3", regs=[("EDX", 2), ("EAX", 0), ("EBX", 2)])
  assert_eq(o.exn, Some(0))
  // div bl: ax / bl -> al = quotient, ah = remainder
  let o = exec32(b"\xf6\xf3", regs=[("EAX", 0x0107), ("EBX", 0x10)])
  assert_eq(get_word(o, "EAX") & 0xffff, 0x0710)
  // idiv ebx: -7 / 2 = -3 rem -1
  let o = exec32(b"\xf7\xfb", regs=[
    ("EDX", 0xffffffff),
    ("EAX", 0xfffffff9),
    ("EBX", 2),
  ])
  assert_eq((get_word(o, "EAX"), get_word(o, "EDX")), (0xfffffffd, 0xffffffff))
}

///|
test "legacy flag instructions" {
  // cld
  let o = exec64(b"\xfc", flag_bits=0b1000000)
  assert_eq(get_flag(o, "DF"), 0)
  // lahf: AH = SF:ZF:0:AF:0:PF:1:CF with bits 5, 3 and 1 undefined upstream
  inspect(
    bil_text(lift32(b"\x9f")),
    content=(
      #|EAX:imm32 := concat(extract[31:16](EAX:imm32), concat(concat(concat(concat(concat(concat(concat(concat(SF:imm1, ZF:imm1), unknown(Undefined RFLAGS bit 5:imm1)), AF:imm1), unknown(Undefined RFLAGS bit 3:imm1)), PF:imm1), unknown(Undefined RFLAGS bit 1:imm1)), CF:imm1), extract[7:0](EAX:imm32)))
    ),
  )
  // sahf: flags from AH
  let o = exec32(b"\x9e", regs=[("EAX", 0xd500)])
  inspect(flags_text(o), content="CF=1 PF=1 AF=1 ZF=1 SF=1 OF=0 DF=0")
  // popcnt eax, ebx (f3 0f b8)
  let o = exec64(b"\xf3\x0f\xb8\xc3", regs=[("RBX", 0xf0f0f0f1)])
  assert_eq(get_word(o, "RAX"), 17)
  assert_eq(get_flag(o, "ZF"), 0)
}
