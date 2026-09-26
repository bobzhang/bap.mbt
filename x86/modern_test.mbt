// The per-opcode lifters over LLVM MC opcodes (upstream x86_btx, x86_mov,
// x86_mov_offset, x86_cmpxchg, x86_cdq and x86_endbr). Instructions are
// decoded with the project's Basic decoder, which produces LLVM-style
// opcode names and operands, or built directly.

///|
fn modern64(
  bytes : Bytes,
  addr? : UInt64 = 0x400000,
) -> Array[@types.Stmt] raise {
  @x86.lift_modern(X8664, mc_insn("x86_64", bytes, addr~))
}

///|
fn modern32(
  bytes : Bytes,
  addr? : UInt64 = 0x8048000,
) -> Array[@types.Stmt] raise {
  @x86.lift_modern(X86, mc_insn("x86", bytes, addr~))
}

///|
fn mexec64(
  bytes : Bytes,
  regs? : Array[(String, UInt64)] = [],
  flag_bits? : Int = 0,
) -> Outcome raise {
  run(modern64(bytes), machine(X8664, regs~, flag_bits~))
}

///|
fn mexec32(
  bytes : Bytes,
  regs? : Array[(String, UInt64)] = [],
  flag_bits? : Int = 0,
) -> Outcome raise {
  run(modern32(bytes), machine(X86, regs~, flag_bits~))
}

///|
fn reg_op(name : String) -> @mc.Op {
  @mc.Op::reg(name)
}

///|
test "modern mov" {
  inspect(
    ops_text(mc_insn("x86_64", b"\x89\xd8")),
    content="MOV32rr [EAX, EBX]",
  )
  inspect(
    bil_text(modern64(b"\x89\xd8")),
    content="RAX:imm64 := pad:64[low:32[RBX:imm64]]",
  )
  inspect(
    bil_text(modern64(b"\x88\xdc")),
    content=(
      #|RAX:imm64 := concat(concat(high:48[RAX:imm64], low:8[RBX:imm64]), low:8[RAX:imm64])
    ),
  )
  inspect(
    bil_text(modern32(b"\x66\x89\xd8")),
    content=(
      #|EAX:imm32 := concat(high:16[EAX:imm32], low:16[EBX:imm32])
    ),
  )
  let o = mexec64(b"\x88\xdc", regs=[("RAX", 0x1111111111111111), ("RBX", 0xab)])
  assert_eq(get_word(o, "RAX"), 0x111111111111ab11)
  let o = mexec64(b"\x48\x89\xd8", regs=[("RBX", 0x1122334455667788)])
  assert_eq(get_word(o, "RAX"), 0x1122334455667788)
  // mov eax, [rbx + rcx*4 + 8]
  let o = mexec64(b"\x8b\x44\x8b\x08", regs=[("RBX", DATA), ("RCX", 2)])
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 16, 4))
  // mov [rbx], ax
  let o = mexec64(b"\x66\x89\x03", regs=[("RBX", DATA), ("RAX", 0xbeef)])
  assert_eq(load_mem(o, DATA, 2), 0xbeef)
  // mov dword [rbx + 4], 7
  let o = mexec64(b"\xc7\x43\x04\x07\x00\x00\x00", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA + 4, 4), 7)
  // mov r8d, 0xffffffff
  let insn = @mc.Insn::create(
    "MOV32ri",
    [reg_op("R8D"), Imm(-1)],
    addr=0,
    size=6,
  )
  let o = run(
    @x86.lift_modern(X8664, insn),
    machine(X8664, regs=[("R8", 0xffffffff00000000)]),
  )
  assert_eq(get_word(o, "R8"), 0xffffffff)
  // movabs rax, imm64
  let o = mexec64(b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11")
  assert_eq(get_word(o, "RAX"), 0x1122334455667788)
  // 32-bit mode: mov ecx, [esp + 4]
  let o = mexec32(b"\x8b\x4c\x24\x04", regs=[("ESP", STACK)])
  assert_eq(get_word(o, "ECX"), load_mem(o, STACK + 4, 4))
  // RIP-relative memory: the base is the next instruction address
  let insn = @mc.Insn::create(
    "MOV32rm",
    [
      reg_op("EAX"),
      reg_op("RIP"),
      Imm(1),
      reg_op("Nil"),
      Imm(0x10),
      reg_op("Nil"),
    ],
    addr=DATA - 6,
    size=6,
  )
  let o = run(@x86.lift_modern(X8664, insn), machine(X8664))
  assert_eq(get_word(o, "RAX"), load_mem(o, DATA + 0x10, 4))
  // fs segment: mov rax, fs:[0x28]
  let insn = @mc.Insn::create(
    "MOV64rm",
    [
      reg_op("RAX"),
      reg_op("Nil"),
      Imm(1),
      reg_op("Nil"),
      Imm(0x28),
      reg_op("FS"),
    ],
    addr=0,
    size=9,
  )
  inspect(
    bil_text(@x86.lift_modern(X8664, insn)),
    content="RAX:imm64 := load(mem:mem64x8, (FS_BASE:imm64 + 0x28:64u)):imm64",
  )
}

///|
test "modern mov segments and moffs" {
  // mov ax, ds
  let insn = @mc.Insn::create(
    "MOV16rs",
    [reg_op("AX"), reg_op("DS")],
    addr=0,
    size=3,
  )
  inspect(
    bil_text(@x86.lift_modern(X86, insn)),
    content=(
      #|EAX:imm32 := concat(high:16[EAX:imm32], DS:imm16)
    ),
  )
  // mov eax, ds (32-bit mode zero-extends)
  let insn = @mc.Insn::create(
    "MOV32rs",
    [reg_op("EAX"), reg_op("DS")],
    addr=0,
    size=2,
  )
  inspect(
    bil_text(@x86.lift_modern(X86, insn)),
    content="EAX:imm32 := pad:32[DS:imm16]",
  )
  // mov ds, eax
  let insn = @mc.Insn::create(
    "MOV32sr",
    [reg_op("DS"), reg_op("EAX")],
    addr=0,
    size=2,
  )
  inspect(
    bil_text(@x86.lift_modern(X86, insn)),
    content="DS:imm16 := low:16[EAX:imm32]",
  )
  // mov al, moffs (MOV8ao32 in 32-bit mode, Mem_to_reg)
  let insn = @mc.Insn::create(
    "MOV8ao32",
    [Imm(DATA.reinterpret_as_int64()), reg_op("Nil")],
    addr=0,
    size=5,
  )
  let o = run(@x86.lift_modern(X86, insn), machine(X86))
  assert_eq(get_word(o, "EAX") & 0xff, load_mem(o, DATA, 1))
  // mov moffs, rax (MOV64o64a in 64-bit mode, Reg_to_mem)
  let insn = @mc.Insn::create(
    "MOV64o64a",
    [Imm(DATA.reinterpret_as_int64()), reg_op("Nil")],
    addr=0,
    size=10,
  )
  let o = run(@x86.lift_modern(X8664, insn), machine(X8664, regs=[("RAX", 42)]))
  assert_eq(load_mem(o, DATA, 8), 42)
  // the 64-bit opcodes are not registered for IA32
  assert_eq(@x86.is_modern_opcode(X86, "MOV64rr"), false)
  assert_eq(@x86.is_modern_opcode(X8664, "MOV64rr"), true)
  assert_eq(@x86.is_modern_opcode(X86, "MOV32ao32"), true)
  assert_eq(@x86.is_modern_opcode(X8664, "MOV32ao32"), false)
}

///|
test "modern btx" {
  inspect(
    ops_text(mc_insn("x86_64", b"\x0f\xab\xd8")),
    content=(
      #|BTS32rr [EAX, EAX, EBX]
    ),
  )
  inspect(
    bil_text(modern64(b"\x0f\xab\xd8")),
    content=(
      #|%o_1:imm5 := low:5[RBX:imm64]
      #|%d_2:imm32 := low:32[RAX:imm64]
      #|CF:imm1 := low:1[(%d_2:imm32 >> %o_1:imm5)]
      #|OF:imm1 := unknown(bts:imm1)
      #|SF:imm1 := unknown(bts:imm1)
      #|AF:imm1 := unknown(bts:imm1)
      #|PF:imm1 := unknown(bts:imm1)
      #|RAX:imm64 := pad:64[(%d_2:imm32 | (1:32u << %o_1:imm5))]
    ),
  )
  // bt eax, ebx with ebx = 36: the offset is taken modulo 32
  let o = mexec64(b"\x0f\xa3\xd8", regs=[("RAX", 0x10), ("RBX", 36)])
  assert_eq(get_flag(o, "CF"), 1)
  // btr rax, 3
  let o = mexec64(b"\x48\x0f\xba\xf0\x03", regs=[("RAX", 0xff)])
  assert_eq(get_word(o, "RAX"), 0xf7)
  assert_eq(get_flag(o, "CF"), 1)
  // btc eax, 35 (masked to 3)
  let o = mexec32(b"\x0f\xba\xf8\x23", regs=[("EAX", 0)])
  assert_eq(get_word(o, "EAX"), 8)
  // bts dword [rbx], 5
  let before = load_mem(exec64(b"\x90"), DATA, 4)
  let o = mexec64(b"\x0f\xba\x2b\x05", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 4), before | 0x20)
  assert_eq(get_flag(o, "CF").to_uint64(), (before >> 5) & 1)
  // bt dword [rbx], eax with a bit offset beyond the first dword
  let o = mexec64(b"\x0f\xa3\x03", regs=[("RBX", DATA), ("RAX", 37)])
  let second = load_mem(o, DATA + 4, 4)
  assert_eq(get_flag(o, "CF").to_uint64(), (second >> 5) & 1)
  // lock bts dword [rbx], eax is wrapped into the lock intrinsics
  let insn = @mc.Insn::create(
    "BTS32mr",
    [reg_op("RBX"), Imm(1), reg_op("Nil"), Imm(0), reg_op("Nil"), reg_op("EAX")],
    addr=0,
    size=4,
    raw=b"\xf0\x0f\xab\x03",
  )
  let bil = @x86.lift_modern(X8664, insn)
  inspect(
    bil[0].to_string(),
    content="special @attribute:(bap:intrinsic x86:lock)",
  )
  inspect(
    bil[bil.length() - 1].to_string(),
    content="special @attribute:(bap:intrinsic x86:unlock)",
  )
  let o = run(bil, machine(X8664, regs=[("RBX", DATA), ("RAX", 1)]))
  assert_eq(load_mem(o, DATA, 4) & 2, 2)
}

///|
test "modern cmpxchg" {
  inspect(
    ops_text(mc_insn("x86_64", b"\x0f\xb1\xd8")),
    content=(
      #|CMPXCHG32rr [EAX, EBX]
    ),
  )
  // cmpxchg ecx, ebx: equal
  let o = mexec32(b"\x0f\xb1\xd9", regs=[("EAX", 5), ("ECX", 5), ("EBX", 9)])
  assert_eq((get_word(o, "ECX"), get_word(o, "EAX")), (9, 5))
  assert_eq(get_flag(o, "ZF"), 1)
  // not equal: the accumulator is loaded
  let o = mexec32(b"\x0f\xb1\xd9", regs=[("EAX", 4), ("ECX", 5), ("EBX", 9)])
  assert_eq((get_word(o, "ECX"), get_word(o, "EAX")), (5, 5))
  assert_eq((get_flag(o, "ZF"), get_flag(o, "CF")), (0, 1))
  // lock cmpxchg [rbx], ecx (LLVM name CMPXCHG32rm)
  let insn = @mc.Insn::create(
    "CMPXCHG32rm",
    [reg_op("RBX"), Imm(1), reg_op("Nil"), Imm(0), reg_op("Nil"), reg_op("ECX")],
    addr=0,
    size=4,
    raw=b"\xf0\x0f\xb1\x0b",
  )
  let init = machine(X8664, regs=[("RBX", DATA), ("RCX", 77)])
  let old = load_mem(run([], init), DATA, 4)
  let init = machine(X8664, regs=[("RBX", DATA), ("RCX", 77), ("RAX", old)])
  let o = run(@x86.lift_modern(X8664, insn), init)
  assert_eq(load_mem(o, DATA, 4), 77)
  assert_eq(get_flag(o, "ZF"), 1)
}

///|
test "modern cdq family and endbr" {
  let o = mexec32(b"\x99", regs=[("EAX", 0x80000000), ("EDX", 0)])
  assert_eq(get_word(o, "EDX"), 0xffffffff)
  let o = mexec64(b"\x48\x99", regs=[("RAX", 1), ("RDX", 5)])
  assert_eq(get_word(o, "RDX"), 0)
  let o = mexec64(b"\x48\x98", regs=[("RAX", 0xffffffff)])
  assert_eq(get_word(o, "RAX"), 0xffffffffffffffff)
  let o = mexec64(b"\x98", regs=[("RAX", 0x8000)])
  assert_eq(get_word(o, "RAX"), 0xffff8000)
  let o = mexec32(b"\x66\x98", regs=[("EAX", 0x12340080)])
  assert_eq(get_word(o, "EAX"), 0x1234ff80)
  let o = mexec32(b"\x66\x99", regs=[("EAX", 0x8000), ("EDX", 0x12345678)])
  assert_eq(get_word(o, "EDX"), 0x1234ffff)
  // endbr64 is a nop unless CET is enabled
  let insn = mc_insn("x86_64", b"\xf3\x0f\x1e\xfa")
  assert_eq(bil_text(@x86.lift_modern(X8664, insn)), "")
  inspect(
    bil_text(@x86.lift_modern(X8664, insn, cet_enabled=true)),
    content="special @attribute:(bap:intrinsic endbr)",
  )
}

///|
test "modern errors" {
  // opcodes without a per-opcode lifter
  let insn = mc_insn("x86_64", b"\x01\xd8")
  let r = try @x86.lift_modern(X8664, insn) catch {
    e => e.message()
  } noraise {
    _ => "lifted"
  }
  inspect(r, content="unsupported instruction: ADD32rr (target x86_64)")
  // malformed operands
  let insn = @mc.Insn::create("MOV32rr", [reg_op("EAX")], addr=0, size=2)
  let r = try @x86.lift_modern(X8664, insn) catch {
    e => e.message()
  } noraise {
    _ => "lifted"
  }
  inspect(r, content="bad operands for instruction: MOV32rr: invalid operands")
  // registers that do not exist in the mode
  let insn = @mc.Insn::create(
    "MOV32rr",
    [reg_op("R8D"), reg_op("EAX")],
    addr=0,
    size=3,
  )
  let r = try @x86.lift_modern(X86, insn) catch {
    e => e.message()
  } noraise {
    _ => "lifted"
  }
  inspect(r, content="MOV32rr: invalid register R8D")
}
