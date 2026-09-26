// The A32 and T32 decoders registered as `@mc` decoders drive the project
// Basic disassembler (`ProjectDisassemblyBasic::lookup`), and the decoded
// instructions lift with the ARM and Thumb lifters.

///|
/// Disassemble `bytes` at `start` with the Basic disassembler of
/// `encoding` for `target`, and render each instruction as `name` followed
/// by its lifted BIL (or `invalid`).
fn disassemble_and_lift(
  target : @core_theory.Target,
  encoding : @core_theory.Language,
  bytes : Bytes,
  start : UInt64,
) -> String raise {
  @arm.register_decoder()
  @thumb.register_decoder()
  guard @project.ProjectDisassemblyBasic::lookup(target, encoding) is Ok(dis) else {
    fail("no disassembler for \{encoding.to_string()}")
  }
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  let insns = dis.run(memory, init=(), return_=_ => [], stopped=(s, _) => {
    s.insns()
  })
  let lines = [dis.backend()]
  for item in insns {
    match item.1 {
      None => lines.push("invalid")
      Some(insn) => {
        let bil = match insn.lift(target~) {
          Ok(lifted) => lifted.bil().map(s => s.to_string()).join("; ")
          Err(reason) => "error: \{reason}"
        }
        lines.push("\{insn.name()}: \{bil}")
      }
    }
  }
  lines.join("\n")
}

///|
test "A32 code is decoded and lifted through the Basic disassembler" {
  inspect(
    disassemble_and_lift(
      @core_theory.Target::arm(),
      @core_theory.Language::llvm_a32(),
      b"\x01\x00\x80\xe0\x04\x00\x91\xe5\xff\xff\xff\xff\x1e\xff\x2f\xe1",
      0x8000,
    ),
    content=(
      #|arm-a32
      #|ADDrr: %v2:imm32 := R0:imm32; %v3:imm32 := R1:imm32; R0:imm32 := (R0:imm32 + R1:imm32)
      #|LDRi12: R0:imm32 := load(mem:mem32x8, (R1:imm32 + 4:32u)):imm32
      #|invalid
      #|BX_RET: jmp LR:imm32
    ),
  )
}

///|
test "Thumb code with an IT block is decoded and lifted through the Basic disassembler" {
  inspect(
    disassemble_and_lift(
      @core_theory.Target::thumb(),
      @core_theory.Language::llvm_t32(),
      b"\x88\x42\x0c\xbf\x01\x20\x02\x20\x01\xf1\x01\x00\x70\x47",
      0x8000,
    ),
    content=(
      #|arm-t32
      #|tCMPr: %t:imm32 := (R0:imm32 - R1:imm32); NF:imm1 := extract[31:31](%t:imm32); ZF:imm1 := (%t:imm32 == 0:32u); CF:imm1 := (not (R0:imm32 < R1:imm32)); VF:imm1 := extract[31:31](((R0:imm32 ^ R1:imm32) & (R0:imm32 ^ %t:imm32)))
      #|t2IT: 
      #|tMOVi8: R0:imm32 := ite(ZF:imm1, 1:32u, R0:imm32)
      #|tMOVi8: R0:imm32 := ite((not ZF:imm1), 2:32u, R0:imm32)
      #|t2ADDri: %v2:imm32 := R1:imm32; %v3:imm32 := 1:32u; R0:imm32 := (R1:imm32 + 1:32u)
      #|tBX: jmp (LR:imm32 & 0xFFFFFFFE:32u)
    ),
  )
}
