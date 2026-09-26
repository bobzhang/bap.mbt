///|
/// The Basic BIL of an x86 instruction decoded at `start`, one statement
/// per line.
fn basic_bil_x86_lift_text(
  triple : String,
  hex : String,
  start? : UInt64 = 0x401000UL,
) -> String raise {
  let disasm = @project.ProjectDisassemblyBasic::create(triple, backend="llvm").unwrap()
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start~,
    x86_llvm_hex_bytes(hex),
  )
  guard disasm.insn_of_mem(memory) is Ok(result) else { fail("decode") }
  guard result.instruction() is Some(insn) else { fail("invalid \{hex}") }
  match insn.lift_basic_bil() {
    Ok(stmts) =>
      insn.assembly() + "\n" + stmts.map(s => "  " + s.to_string()).join("\n")
    Err(reason) => fail(reason)
  }
}

///|
test "Basic BIL of x86 memory operands in LLVM's MCInst form" {
  let samples = [
    // RIP-relative: the address of the next instruction plus the offset
    ("x86_64", "488d0500010000"),
    ("x86_64", "8b0d10000000"),
    // absolute, FS-relative, EIZ index, 32-bit addresses in 64-bit mode
    ("x86_64", "8b042500100000"),
    ("x86_64", "64488b042528000000"),
    ("x86", "8d742600"),
    ("x86_64", "67458d4110"),
    ("x86_64", "678b01"),
    ("x86", "678b07"),
    ("x86", "a100100000"),
  ]
  let lines = []
  for sample in samples {
    lines.push(basic_bil_x86_lift_text(sample.0, sample.1))
  }
  inspect(
    lines.join("\n"),
    content=(
      #|leaq 256(%rip), %rax
      #|  RAX:imm64 := 0x401107:64u
      #|movl 16(%rip), %ecx
      #|  ECX:imm32 := load(mem:mem64x8, 0x401016:64u):imm32
      #|movl 4096, %eax
      #|  EAX:imm32 := load(mem:mem64x8, 0x1000:64u):imm32
      #|movq %fs:40, %rax
      #|  RAX:imm64 := load(mem:mem64x8, (FS_BASE:imm64 + 0x28:64u)):imm64
      #|leal (%esi,%eiz), %esi
      #|  ESI:imm32 := ESI:imm32
      #|leal 16(%r9d), %r8d
      #|  R8D:imm32 := low:32[pad:64[(R9D:imm32 + 0x10:32u)]]
      #|movl (%ecx), %eax
      #|  EAX:imm32 := load(mem:mem64x8, pad:64[ECX:imm32]):imm32
      #|movl (%bx), %eax
      #|  EAX:imm32 := load(mem:mem32x8, pad:32[BX:imm16]):imm32
      #|movl 4096, %eax
      #|  EAX:imm32 := load(mem:mem32x8, 0x1000:32u):imm32
    ),
  )
}

///|
test "Basic BIL of x86 TEST m,imm, LODS, LOOP, ENTER, POP m and CMPXCHG16B" {
  let samples = [
    ("x86_64", "f6449e087f"),
    ("x86", "f706ffffff7f"),
    ("x86_64", "ac"),
    ("x86", "f3ad"),
    ("x86_64", "e208"),
    ("x86", "e108"),
    ("x86_64", "67e0fe"),
    ("x86_64", "c8100000"),
    ("x86", "c8080001"),
    ("x86_64", "8f06"),
    ("x86", "668f06"),
    ("x86_64", "480fc70e"),
  ]
  let lines = []
  for sample in samples {
    lines.push(basic_bil_x86_lift_text(sample.0, sample.1))
  }
  inspect(
    lines.join("\n"),
    content=(
      #|testb $127, 8(%rsi,%rbx,4)
      #|  %test_a:imm64 := ((RSI:imm64 + (RBX:imm64 * 4:64u)) + 8:64u)
      #|  %test_tmp:imm8 := (load(mem:mem64x8, %test_a:imm64):imm8 & 0x7F:8u)
      #|  CF:imm1 := 0:1u
      #|  OF:imm1 := 0:1u
      #|  AF:imm1 := unknown(AF undefined after TEST:imm1)
      #|  PF:imm1 := (not low:1[let %parity_tmp1:imm8 = ((%test_tmp:imm8 >> 4:8u) ^ %test_tmp:imm8) in let %parity_tmp2:imm8 = ((%parity_tmp1:imm8 >> 2:8u) ^ %parity_tmp1:imm8) in ((%parity_tmp2:imm8 >> 1:8u) ^ %parity_tmp2:imm8)])
      #|  SF:imm1 := high:1[%test_tmp:imm8]
      #|  ZF:imm1 := (0:8u == %test_tmp:imm8)
      #|testl $2147483647, (%esi)
      #|  %test_a:imm32 := ESI:imm32
      #|  %test_tmp:imm32 := (load(mem:mem32x8, %test_a:imm32):imm32 & 0x7FFFFFFF:32u)
      #|  CF:imm1 := 0:1u
      #|  OF:imm1 := 0:1u
      #|  AF:imm1 := unknown(AF undefined after TEST:imm1)
      #|  PF:imm1 := (not low:1[let %parity_tmp1:imm32 = ((%test_tmp:imm32 >> 4:32u) ^ %test_tmp:imm32) in let %parity_tmp2:imm32 = ((%parity_tmp1:imm32 >> 2:32u) ^ %parity_tmp1:imm32) in ((%parity_tmp2:imm32 >> 1:32u) ^ %parity_tmp2:imm32)])
      #|  SF:imm1 := high:1[%test_tmp:imm32]
      #|  ZF:imm1 := (0:32u == %test_tmp:imm32)
      #|lodsb (%rsi), %al
      #|  AL:imm8 := load(mem:mem64x8, RSI:imm64):imm8
      #|  RSI:imm64 := ite((DF:imm1 == 0:1u), (RSI:imm64 + 1:64u), (RSI:imm64 - 1:64u))
      #|rep  lodsl (%esi), %eax
      #|  %rep_continue:imm1 := 1:1u
      #|  while ((ECX:imm32 != 0:32u) & %rep_continue:imm1) do 3 stmts
      #|loop 8
      #|  RCX:imm64 := (RCX:imm64 - 1:64u)
      #|  if (RCX:imm64 != 0:64u) then 2 stmts else 0 stmts
      #|loope 8
      #|  ECX:imm32 := (ECX:imm32 - 1:32u)
      #|  if ((ECX:imm32 != 0:32u) & ZF:imm1) then 2 stmts else 0 stmts
      #|addr32  loopne -2
      #|  ECX:imm32 := (ECX:imm32 - 1:32u)
      #|  if ((ECX:imm32 != 0:32u) & (not ZF:imm1)) then 2 stmts else 0 stmts
      #|enter $16, $0
      #|  RSP:imm64 := (RSP:imm64 - 8:64u)
      #|  mem:mem64x8 := store(mem:mem64x8, RSP:imm64, RBP:imm64)
      #|  %enter_frame:imm64 := RSP:imm64
      #|  RBP:imm64 := %enter_frame:imm64
      #|  RSP:imm64 := (RSP:imm64 - 0x10:64u)
      #|enter $8, $1
      #|  ESP:imm32 := (ESP:imm32 - 4:32u)
      #|  mem:mem32x8 := store(mem:mem32x8, ESP:imm32, EBP:imm32)
      #|  %enter_frame:imm32 := ESP:imm32
      #|  ESP:imm32 := (ESP:imm32 - 4:32u)
      #|  mem:mem32x8 := store(mem:mem32x8, ESP:imm32, %enter_frame:imm32)
      #|  EBP:imm32 := %enter_frame:imm32
      #|  ESP:imm32 := (ESP:imm32 - 8:32u)
      #|popq (%rsi)
      #|  %pop_value:imm64 := load(mem:mem64x8, RSP:imm64):imm64
      #|  RSP:imm64 := (RSP:imm64 + 8:64u)
      #|  mem:mem64x8 := store(mem:mem64x8, RSI:imm64, %pop_value:imm64)
      #|popw (%esi)
      #|  %pop_value:imm16 := load(mem:mem32x8, ESP:imm32):imm16
      #|  ESP:imm32 := (ESP:imm32 + 2:32u)
      #|  mem:mem32x8 := store(mem:mem32x8, ESI:imm32, %pop_value:imm16)
      #|cmpxchg16b (%rsi)
      #|  %cmpxchg16b_a:imm64 := RSI:imm64
      #|  %cmpxchg16b_d:imm128 := load(mem:mem64x8, %cmpxchg16b_a:imm64):imm128
      #|  %cmpxchg16b_eq:imm1 := (concat(RDX:imm64, RAX:imm64) == %cmpxchg16b_d:imm128)
      #|  ZF:imm1 := %cmpxchg16b_eq:imm1
      #|  mem:mem64x8 := store(mem:mem64x8, %cmpxchg16b_a:imm64, ite(%cmpxchg16b_eq:imm1, concat(RCX:imm64, RBX:imm64), %cmpxchg16b_d:imm128))
      #|  if %cmpxchg16b_eq:imm1 then 0 stmts else 2 stmts
    ),
  )
}
