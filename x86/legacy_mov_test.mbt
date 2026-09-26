///|
test "legacy mov: register to register, BIL" {
  // mov rax, rbx
  inspect(
    bil_text(lift64(b"\x48\x89\xd8")),
    content=(
      #|RAX:imm64 := RBX:imm64
    ),
  )
  // mov eax, ebx (zero-extends into RAX)
  inspect(
    bil_text(lift64(b"\x89\xd8")),
    content=(
      #|RAX:imm64 := pad:64[low:32[RBX:imm64]]
    ),
  )
  // mov ah, bl
  inspect(
    bil_text(lift64(b"\x88\xdc")),
    content=(
      #|RAX:imm64 := concat(extract[63:16](RAX:imm64), concat(low:8[low:32[RBX:imm64]], extract[7:0](RAX:imm64)))
    ),
  )
  // mov ax, bx (32-bit mode)
  inspect(
    bil_text(lift32(b"\x66\x89\xd8")),
    content=(
      #|EAX:imm32 := concat(extract[31:16](EAX:imm32), low:16[low:32[EBX:imm32]])
    ),
  )
}

///|
test "legacy mov: execution" {
  let o = exec64(b"\x48\x89\xd8", regs=[("RBX", 0x1122334455667788)])
  assert_eq(get_word(o, "RAX"), 0x1122334455667788)
  let o = exec64(b"\x89\xd8", regs=[
    ("RAX", 0xFFFFFFFFFFFFFFFF),
    ("RBX", 0x1122334455667788),
  ])
  assert_eq(get_word(o, "RAX"), 0x55667788)
  // mov ah, bl
  let o = exec64(b"\x88\xdc", regs=[("RAX", 0x1111111111111111), ("RBX", 0xAB)])
  assert_eq(get_word(o, "RAX"), 0x111111111111AB11)
  // mov sil, bl (REX)
  let o = exec64(b"\x40\x88\xde", regs=[
    ("RSI", 0x1111111111111111),
    ("RBX", 0xAB),
  ])
  assert_eq(get_word(o, "RSI"), 0x11111111111111AB)
  // mov r9w, ax
  let o = exec64(b"\x66\x41\x89\xc1", regs=[
    ("R9", 0x1111111111111111),
    ("RAX", 0xBEEF),
  ])
  assert_eq(get_word(o, "R9"), 0x111111111111BEEF)
  // mov eax, 0x12345678 ; mov rax, imm64 ; mov al, 0x7f
  let o = exec64(b"\xb8\x78\x56\x34\x12", regs=[("RAX", 0xFFFFFFFFFFFFFFFF)])
  assert_eq(get_word(o, "RAX"), 0x12345678)
  let o = exec64(b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11")
  assert_eq(get_word(o, "RAX"), 0x1122334455667788)
  let o = exec64(b"\xb0\x7f", regs=[("RAX", 0x1111111111111111)])
  assert_eq(get_word(o, "RAX"), 0x111111111111117F)
  // mov rax, -1 (c7 with sign-extended imm32)
  let o = exec64(b"\x48\xc7\xc0\xff\xff\xff\xff")
  assert_eq(get_word(o, "RAX"), 0xFFFFFFFFFFFFFFFF)
}

///|
test "legacy mov: memory operands" {
  // mov rax, [rbx + 8]
  let o = exec64(b"\x48\x8b\x43\x08", regs=[("RBX", DATA)])
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 8, 8))
  // mov [rbx + rcx*4 + 0x10], edx
  let o = exec64(b"\x89\x54\x8b\x10", regs=[
    ("RBX", DATA),
    ("RCX", 3),
    ("RDX", 0xCAFEBABE),
  ])
  assert_eq(load_mem(o, DATA + 0x1C, 4), 0xCAFEBABE)
  // mov byte [rbx], 0x5a
  let o = exec64(b"\xc6\x03\x5a", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 1), 0x5A)
  // mov qword [rbx], -2 (sign-extended imm32)
  let o = exec64(b"\x48\xc7\x03\xfe\xff\xff\xff", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 8), 0xFFFFFFFFFFFFFFFE)
  // RIP-relative: mov eax, [rip + 0x10] at 0x10000 - 6
  let o = exec64(b"\x8b\x05\x10\x00\x00\x00", addr=DATA - 6)
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 0x10, 4))
  // RIP-relative with an immediate following:
  // mov dword [rip + 0x10], 0x11223344 at DATA - 10
  let o = exec64(b"\xc7\x05\x10\x00\x00\x00\x44\x33\x22\x11", addr=DATA - 10)
  assert_eq(load_mem(o, DATA + 0x10, 4), 0x11223344)
  // mov eax, [0x10010] (32-bit mode, moffs)
  let o = exec32(b"\xa1\x10\x00\x01\x00")
  assert_eq(get_word(o, "EAX"), load_mem(o, DATA + 0x10, 4))
  // 16-bit addressing: mov ax, [bx + si + 2] (32-bit mode, 67 prefix);
  // the 16-bit address is zero-extended
  inspect(
    bil_text(lift32(b"\x67\x66\x8b\x40\x02")),
    content=(
      #|EAX:imm32 := concat(extract[31:16](EAX:imm32), load(mem:mem32x8, pad:32[((low:16[EBX:imm32] + low:16[ESI:imm32]) + 2:16u)]):imm16)
    ),
  )
}

///|
test "legacy mov: fs segment override" {
  // mov rax, fs:[0x28]
  inspect(
    bil_text(lift64(b"\x64\x48\x8b\x04\x25\x28\x00\x00\x00")),
    content=(
      #|RAX:imm64 := load(mem:mem64x8, (FS_BASE:imm64 + 0x28:64u)):imm64
    ),
  )
  let o = exec64(b"\x64\x48\x8b\x04\x25\x28\x00\x00\x00", regs=[
    ("FS_BASE", DATA),
  ])
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 0x28, 8))
}

///|
test "legacy movzx/movsx/lea/xchg/cmov" {
  // movzx eax, byte [rbx]
  let o = exec64(b"\x0f\xb6\x03", regs=[("RBX", DATA + 5)])
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 5, 1))
  // movsx rax, bl
  let o = exec64(b"\x48\x0f\xbe\xc3", regs=[("RBX", 0x80)])
  assert_eq(get_word(o, "RAX"), 0xFFFFFFFFFFFFFF80)
  // movsxd rax, ebx
  let o = exec64(b"\x48\x63\xc3", regs=[("RBX", 0xFFFFFFFE)])
  assert_eq(get_word(o, "RAX"), 0xFFFFFFFFFFFFFFFE)
  // cdqe (98 with REX.W)
  let o = exec64(b"\x48\x98", regs=[("RAX", 0x80000000)])
  assert_eq(get_word(o, "RAX"), 0xFFFFFFFF80000000)
  // lea rax, [rbx + rcx*8 + 0x10]
  let o = exec64(b"\x48\x8d\x44\xcb\x10", regs=[("RBX", 0x1000), ("RCX", 2)])
  assert_eq(get_word(o, "RAX"), 0x1020)
  // lea eax, [rbx - 1] (truncated to 32 bits)
  let o = exec64(b"\x8d\x43\xff", regs=[("RBX", 0x100000000)])
  assert_eq(get_word(o, "RAX"), 0xFFFFFFFF)
  // xchg rax, rbx
  let o = exec64(b"\x48\x93", regs=[("RAX", 1), ("RBX", 2)])
  assert_eq((get_word(o, "RAX"), get_word(o, "RBX")), (2, 1))
  // cmove eax, ebx: taken and not taken (ZF is bit 3 of flag_bits)
  let o = exec64(
    b"\x0f\x44\xc3",
    regs=[("RAX", 1), ("RBX", 2)],
    flag_bits=0b1000,
  )
  assert_eq(get_word(o, "RAX"), 2)
  let o = exec64(b"\x0f\x44\xc3", regs=[("RAX", 0x100000001), ("RBX", 2)])
  // not taken, but the 32-bit destination is still zero-extended
  assert_eq(get_word(o, "RAX"), 1)
  // bswap eax
  let o = exec64(b"\x0f\xc8", regs=[("RAX", 0x11223344)])
  assert_eq(get_word(o, "RAX"), 0x44332211)
}
