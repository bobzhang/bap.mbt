// End-to-end tests: decode A32 machine code, lift it with the ARM lifter
// and evaluate the BIL.

///|
/// Decode the little-endian A32 words at `addr` and lift them in the ARM
/// context.
fn decode_lift(
  words : Array[UInt32],
  addr : UInt64,
) -> Array[Array[@types.Stmt]] raise {
  let ctx = @mc.Context::create(
    @core_theory.Target::arm(),
    encoding=@core_theory.Language::llvm_a32(),
  )
  let result = []
  for k, w in words {
    let bytes = Bytes::makei(4, i => (w >> (8 * i)).to_byte())
    guard @arm.decode_a32(bytes[:], addr=addr + (4 * k).to_uint64())
      is Decoded(insn) else {
      fail("cannot decode \{w}")
    }
    result.push(@arm.lift_in_context(ctx, insn).bil)
  }
  result
}

///|
test "decode, lift and run an A32 sequence" {
  let program = decode_lift(
    [
      0xE3A00005, // mov r0, #5
       0xE3A01007, // mov r1, #7
       0xE0802001, // add r2, r0, r1
       0xE252300C, // subs r3, r2, #12
       0x03A04001, // moveq r4, #1
       0x13A04002, // movne r4, #2
       0xE3A05A01, // mov r5, #0x1000
       0xE5852004, // str r2, [r5, #4]
       0xE5B56004, // ldr r6, [r5, #4]!
       0xE1A07102, // mov r7, r2, lsl #2
       0xE7E78251, // ubfx r8, r1, #4, #8
       0xE0090291, // mul r9, r1, r2
       0xE92D0003, // push {r0, r1}
       0xE8BD0C00, // pop {r10, r11}
    ],
    0x2000,
  )
  let mut s = state([("SP", 0x1010)], bytes=Bytes::make(32, b'\x00'))
  for stmts in program {
    s = exec(stmts, s)
  }
  debug_inspect(
    [
      reg_value(s, "R2"),
      reg_value(s, "R3"),
      reg_value(s, "R4"),
      reg_value(s, "R5"),
      reg_value(s, "R6"),
      reg_value(s, "R7"),
      reg_value(s, "R8"),
      reg_value(s, "R9"),
      reg_value(s, "R10"),
      reg_value(s, "R11"),
      reg_value(s, "SP"),
    ],
    content="[12, 0, 1, 4100, 12, 48, 0, 84, 5, 7, 4112]",
  )
  assert_eq(nzcv(s), "-ZC-")
  assert_eq(mem_word(s, 0x1004), 12)
  assert_eq(mem_word(s, 0x1008), 5)
}

///|
test "decoded A32 branches jump to their targets" {
  let init = state(
    [("LR", 0x3000), ("R3", 0x4000), ("SP", 0x1000)],
    flags=[("ZF", true)],
    bytes=b"\x00\x50\x00\x00",
  )
  let targets = decode_lift(
    [
      0x0A000001, // beq #4
       0xEBFFFFFE, // bl #-8
       0xE12FFF1E, // bx lr
       0xE12FFF13, // bx r3
       0xE8BD8000, // pop {pc}
    ],
    0x2000,
  ).map(stmts => jump_target(stmts, init))
  debug_inspect(
    targets,
    content="[Some(8204), Some(8196), Some(12288), Some(16384), Some(20480)]",
  )
}
