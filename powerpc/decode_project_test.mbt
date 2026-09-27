// The native decoder as a backend of the project's Basic disassembler.

///|
test "the Basic disassembler decodes and lifts PowerPC code" {
  @powerpc.register_decoder()
  let target = @core_theory.Target::powerpc()
  guard @project.ProjectDisassemblyBasic::lookup(
      target,
      @core_theory.Language::llvm_powerpc32(),
    )
    is Ok(dis) else {
    fail("no PowerPC disassembler")
  }
  assert_eq(dis.backend(), @powerpc.decoder_name)
  // stwu r1,-16(r1); mflr r0; <invalid>; addi r3,r3,1; blr; <truncated>
  let memory = @memory.Memory::from_bytes(
    endian=BigEndian,
    start=0x10000UL,
    b"\x94\x21\xff\xf0\x7c\x08\x02\xa6\x00\x00\x00\x00\x38\x63\x00\x01\x4e\x80\x00\x20\x60\x00",
  )
  let insns = dis.run(memory, init=(), return_=_ => [], stopped=(s, _) => {
    s.insns()
  })
  let listed = insns.map(item => {
    let text = match item.1 {
      Some(insn) => {
        let bil = match insn.lift(target~) {
          Ok(lifted) => lifted.bil().map(s => s.to_string()).join("; ")
          Err(reason) => "error: \{reason}"
        }
        "\{insn.name()}:\{insn.encoding()} \{bil}"
      }
      None => "invalid"
    }
    "\{item.0.min_addr().to_string(radix=16)}+\{item.0.length()} \{text}"
  })
  inspect(
    listed.join("\n"),
    content=(
      #|10000+4 STWU:llvm-powerpc32 mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0xFFFFFFF0:32u), R1:imm32); R1:imm32 := (R1:imm32 + 0xFFFFFFF0:32u)
      #|10004+4 MFLR:llvm-powerpc32 R0:imm32 := LR:imm32
      #|10008+4 invalid
      #|1000c+4 ADDI:llvm-powerpc32 R3:imm32 := (R3:imm32 + 1:32u)
      #|10010+4 BLR:llvm-powerpc32 jmp (LR:imm32 & (0xFFFFFFFF:32u << pad:32[2:8u]))
    ),
  )
  // `create` selects the decoder by name or, for the default `llvm`
  // backend, by the target named by the triple
  assert_true(
    @project.ProjectDisassemblyBasic::create(
      "powerpc64",
      backend=@powerpc.decoder_name,
    )
    is Ok(_),
  )
  guard @project.ProjectDisassemblyBasic::create("powerpc") is Ok(dis) else {
    fail("no llvm disassembler for powerpc")
  }
  assert_eq(dis.backend(), @powerpc.decoder_name)
}
