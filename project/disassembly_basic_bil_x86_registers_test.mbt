// The Basic lifter writes the full x86 registers, like upstream's x86
// lifter: 32-bit writes zero-extend in 64-bit mode, 8/16-bit writes merge,
// sub-register reads extract.

///|
fn x86_register_lift(triple : String, bytes : Bytes) -> String raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create(triple, backend="llvm") {
    Ok(d) => d
    Err(r) => fail(r)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000,
    bytes,
  )
  let insn = match disasm.insn_of_mem(memory) {
    Ok(result) => result.instruction().unwrap()
    Err(r) => fail(r)
  }
  match insn.lift_basic_bil() {
    Ok(bil) => "\{insn.encoding()}: " + bil.map(s => s.to_string()).join("; ")
    Err(r) => fail(r)
  }
}

///|
test "Basic lifter writes full x86-64 registers" {
  // mov eax, ebx: zero-extends into RAX
  inspect(
    x86_register_lift("x86_64", b"\x89\xd8"),
    content="llvm-x86_64: RAX:imm64 := pad:64[low:32[RBX:imm64]]",
  )
  // mov eax, 1
  inspect(
    x86_register_lift("x86_64", b"\xb8\x01\x00\x00\x00"),
    content="llvm-x86_64: RAX:imm64 := 1:64u",
  )
  // mov ax, bx: merges
  inspect(
    x86_register_lift("x86_64", b"\x66\x89\xd8"),
    content="llvm-x86_64: RAX:imm64 := concat(high:48[RAX:imm64], low:16[RBX:imm64])",
  )
  // mov ah, bl
  inspect(
    x86_register_lift("x86_64", b"\x88\xdc"),
    content="llvm-x86_64: RAX:imm64 := concat(high:48[RAX:imm64], concat(low:8[RBX:imm64], low:8[RAX:imm64]))",
  )
  // mov rax, rbx
  inspect(
    x86_register_lift("x86_64", b"\x48\x89\xd8"),
    content="llvm-x86_64: RAX:imm64 := RBX:imm64",
  )
}

///|
test "Basic lifter writes full x86 registers" {
  // mov eax, ebx: EAX is the full register
  inspect(
    x86_register_lift("x86", b"\x89\xd8"),
    content="llvm-x86: EAX:imm32 := EBX:imm32",
  )
  // mov al, bl: merges
  inspect(
    x86_register_lift("x86", b"\x88\xd8"),
    content="llvm-x86: EAX:imm32 := concat(high:24[EAX:imm32], low:8[EBX:imm32])",
  )
}
