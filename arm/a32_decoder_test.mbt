// Tests of the A32 decoder on real instruction encodings (hand-assembled
// from the ARM Architecture Reference Manual, ARMv7-A).

///|
/// Render a decoded instruction as `NAME op, op, ... | assembly`, with
/// immediates in decimal.
fn show_a32(word : UInt, addr? : UInt64 = 0) -> String {
  match @arm.decode_a32_word(word, addr~) {
    None => "invalid"
    Some(insn) => {
      let ops = insn.ops
        .iter()
        .map(op => {
          match op {
            Reg(name~, ..) => name
            Imm(v) => v.to_string()
            Fmm(v) => v.to_string()
          }
        })
        .collect()
        .join(", ")
      "\{insn.name} \{ops} | \{insn.assembly}"
    }
  }
}

///|
test "A32 data processing" {
  inspect(
    show_a32(0xE0800001),
    content="ADDrr R0, R0, R1, 14, Nil, Nil | add r0, r0, r1",
  )
  inspect(
    show_a32(0xE2932001),
    content="ADDri R2, R3, 1, 14, Nil, CPSR | adds r2, r3, #1",
  )
  inspect(
    show_a32(0xE24DD008),
    content="SUBri SP, SP, 8, 14, Nil, Nil | sub sp, sp, #8",
  )
  // the modified immediate stays encoded: 0xFF ror 8
  inspect(
    show_a32(0xE3A004FF),
    content=(
      #|MOVi R0, 1279, 14, Nil, Nil | mov r0, #-16777216
    ),
  )
  inspect(
    show_a32(0xE1A00101),
    content=(
      #|MOVsi R0, R1, 18, 14, Nil, Nil | lsl r0, r1, #2
    ),
  )
  inspect(
    show_a32(0xE1A00061),
    content=(
      #|MOVsi R0, R1, 5, 14, Nil, Nil | rrx r0, r1
    ),
  )
  inspect(
    show_a32(0xE1A0F00E),
    content="MOVr PC, LR, 14, Nil, Nil | mov pc, lr",
  )
  inspect(show_a32(0xE3510000), content="CMPri R1, 0, 14, Nil | cmp r1, #0")
  inspect(show_a32(0xE1510002), content="CMPrr R1, R2, 14, Nil | cmp r1, r2")
  inspect(show_a32(0xE1710002), content="CMNzrr R1, R2, 14, Nil | cmn r1, r2")
  inspect(
    show_a32(0xE1310102),
    content="TEQrsi R1, R2, 18, 14, Nil | teq r1, r2, lsl #2",
  )
  // addne r0, r1, r2, asr r3
  inspect(
    show_a32(0x10810352),
    content="ADDrsr R0, R1, R2, R3, 1, 1, CPSR, Nil | addne r0, r1, r2, asr r3",
  )
  inspect(
    show_a32(0xE3010234),
    content="MOVi16 R0, 4660, 14, Nil | movw r0, #4660",
  )
  inspect(
    show_a32(0xE3450678),
    content="MOVTi16 R0, R0, 22136, 14, Nil | movt r0, #22136",
  )
  // `add r0, pc, #8` is ADR; the label is the raw 14-bit field
  inspect(
    show_a32(0xE28F0008),
    content=(
      #|ADDri R0, PC, 8, 14, Nil, Nil | add r0, pc, #8
    ),
  )
  // compares with a non-zero destination field are not decoded
  inspect(
    show_a32(0xE3511000),
    content=(
      #|CMPri R1, 0, 14, Nil | cmp r1, #0
    ),
  )
}

///|
test "A32 loads and stores" {
  inspect(
    show_a32(0xE5910004),
    content="LDRi12 R0, R1, 4, 14, Nil | ldr r0, [r1, #4]",
  )
  // #-0 is INT32_MIN
  inspect(
    show_a32(0xE5110000),
    content=(
      #|LDRi12 R0, R1, 2147483648, 14, Nil | ldr r0, [r1, #-0]
    ),
  )
  inspect(
    show_a32(0xE5210004),
    content=(
      #|STR_PRE_IMM R1, R0, R1, 4294967292, 14, Nil | str r0, [r1, #-4]!
    ),
  )
  inspect(
    show_a32(0xE4910004),
    content="LDR_POST_IMM R0, R1, R1, Nil, 147460, 14, Nil | ldr r0, [r1], #4",
  )
  inspect(
    show_a32(0xE4D10001),
    content="LDRB_POST_IMM R0, R1, R1, Nil, 147457, 14, Nil | ldrb r0, [r1], #1",
  )
  inspect(
    show_a32(0xE7910102),
    content="LDRrs R0, R1, R2, 16386, 14, Nil | ldr r0, [r1, r2, lsl #2]",
  )
  inspect(
    show_a32(0xE7A10002),
    content="STR_PRE_REG R1, R0, R1, R2, 16384, 14, Nil | str r0, [r1, r2]!",
  )
  inspect(
    show_a32(0xE6110002),
    content="LDR_POST_REG R0, R1, R1, R2, 151552, 14, Nil | ldr r0, [r1], -r2",
  )
  inspect(
    show_a32(0xE1D100B2),
    content="LDRH R0, R1, Nil, 2, 14, Nil | ldrh r0, [r1, #2]",
  )
  inspect(
    show_a32(0xE15100D1),
    content="LDRSB R0, R1, Nil, 257, 14, Nil | ldrsb r0, [r1, #-1]",
  )
  inspect(
    show_a32(0xE19100F2),
    content="LDRSH R0, R1, R2, 0, 14, Nil | ldrsh r0, [r1, r2]",
  )
  inspect(
    show_a32(0xE1C200D0),
    content=(
      #|LDRD R0, R1, R2, Nil, 0, 14, Nil | ldrd r0, r1, [r2]
    ),
  )
  inspect(
    show_a32(0xE16D20F8),
    content=(
      #|STRD_PRE SP, R2, R3, SP, Nil, 776, 14, Nil | strd r2, r3, [sp, #-8]!
    ),
  )
  inspect(
    show_a32(0xE0C120F8),
    content=(
      #|STRD_POST R1, R2, R3, R1, Nil, 1032, 14, Nil | strd r2, r3, [r1], #8
    ),
  )
  inspect(
    show_a32(0xE0F100B2),
    content="LDRHTi R0, R1, R1, 258, 14, Nil | ldrht r0, [r1], #2",
  )
  inspect(
    show_a32(0xE0B100B2),
    content="LDRHTr R0, R1, R1, R2, 1, 14, Nil | ldrht r0, [r1], r2",
  )
  inspect(
    show_a32(0xE92D4010),
    content="STMDB_UPD SP, SP, 14, Nil, R4, LR | push {r4, lr}",
  )
  inspect(
    show_a32(0xE8BD8010),
    content="LDMIA_UPD SP, SP, 14, Nil, R4, PC | pop {r4, pc}",
  )
  inspect(
    show_a32(0xE8900006),
    content="LDMIA R0, 14, Nil, R1, R2 | ldm r0, {r1, r2}",
  )
  inspect(
    show_a32(0xE1910F9F),
    content="LDREX R0, R1, 14, Nil | ldrex r0, [r1]",
  )
  inspect(
    show_a32(0xE1812F90),
    content="STREX R2, R0, R1, 14, Nil | strex r2, r0, [r1]",
  )
  inspect(
    show_a32(0xE1B20F9F),
    content="LDREXD R0_R1, R2, 14, Nil | ldrexd r0, r1, [r2]",
  )
  inspect(
    show_a32(0xE1420091),
    content="SWPB R0, R1, R2, 14, Nil | swpb r0, r1, [r2]",
  )
  inspect(show_a32(0xF5D1F004), content="PLDi12 R1, 4 | pld [r1, #4]")
}

///|
test "A32 multiplies, bit manipulation and extensions" {
  inspect(
    show_a32(0xE0000291),
    content="MUL R0, R1, R2, 14, Nil, Nil | mul r0, r1, r2",
  )
  inspect(
    show_a32(0xE0203291),
    content="MLA R0, R1, R2, R3, 14, Nil, Nil | mla r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE0603291),
    content="MLS R0, R1, R2, R3, 14, Nil | mls r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE0810392),
    content="UMULL R0, R1, R2, R3, 14, Nil, Nil | umull r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE0E10392),
    content="SMLAL R0, R1, R2, R3, R0, R1, 14, Nil, Nil | smlal r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE1003281),
    content="SMLABB R0, R1, R2, R3, 14, Nil | smlabb r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE16002A1),
    content="SMULTB R0, R1, R2, 14, Nil | smultb r0, r1, r2",
  )
  inspect(
    show_a32(0xE14100C2),
    content=(
      #|SMLALBT R0, R1, R2, R0, R0, R1, 14, Nil | smlalbt r0, r1, r2, r0
    ),
  )
  inspect(
    show_a32(0xE7003211),
    content="SMLAD R0, R1, R2, R3, 14, Nil | smlad r0, r1, r2, r3",
  )
  inspect(
    show_a32(0xE700F211),
    content="SMUAD R0, R1, R2, 14, Nil | smuad r0, r1, r2",
  )
  inspect(show_a32(0xE6EF0071), content="UXTB R0, R1, 0, 14, Nil | uxtb r0, r1")
  inspect(
    show_a32(0xE6BF0471),
    content="SXTH R0, R1, 1, 14, Nil | sxth r0, r1, ror #8",
  )
  inspect(
    show_a32(0xE6E10072),
    content="UXTAB R0, R1, R2, 0, 14, Nil | uxtab r0, r1, r2",
  )
  inspect(
    show_a32(0xE7E70251),
    content="UBFX R0, R1, 4, 7, 14, Nil | ubfx r0, r1, #4, #8",
  )
  inspect(
    show_a32(0xE7CB0411),
    content=(
      #|BFI R0, R0, R1, 4294963455, 14, Nil | bfi r0, r1, #8, #4
    ),
  )
  inspect(
    show_a32(0xE7CB041F),
    content=(
      #|BFC R0, R0, 4294963455, 14, Nil | bfc r0, #8, #4
    ),
  )
  inspect(show_a32(0xE6BF0F31), content="REV R0, R1, 14, Nil | rev r0, r1")
  inspect(show_a32(0xE6BF0FB1), content="REV16 R0, R1, 14, Nil | rev16 r0, r1")
  inspect(show_a32(0xE6FF0F31), content="RBIT R0, R1, 14, Nil | rbit r0, r1")
  inspect(
    show_a32(0xE6810152),
    content="PKHTB R0, R1, R2, 2, 14, Nil | pkhtb r0, r1, r2, asr #2",
  )
  inspect(show_a32(0xE16F0F11), content="CLZ R0, R1, 14, Nil | clz r0, r1")
}

///|
test "A32 branches, system and hint instructions" {
  inspect(show_a32(0xE12FFF1E), content="BX_RET 14, Nil | bx lr")
  inspect(show_a32(0xE12FFF13), content="BX R3 | bx r3")
  inspect(show_a32(0x112FFF13), content="BX_pred R3, 1, CPSR | bxne r3")
  inspect(show_a32(0xE12FFF33), content="BLX R3 | blx r3")
  inspect(
    show_a32(0xEBFFFFFE),
    content=(
      #|BL -8 | bl #-8
    ),
  )
  inspect(show_a32(0x0B000001), content="BL_pred 4, 0, CPSR | bleq #4")
  inspect(show_a32(0x0A000001), content="Bcc 4, 0, CPSR | beq #4")
  inspect(show_a32(0xEAFFFFFE), content="Bcc -8, 14, Nil | b #-8")
  inspect(show_a32(0xFB000000), content="BLXi 2 | blx #2")
  inspect(show_a32(0xEF000000), content="SVC 0, 14, Nil | svc #0")
  inspect(show_a32(0xE320F000), content="HINT 0, 14, Nil | nop")
  inspect(
    show_a32(0xF57FF05B),
    content=(
      #|DMB 11 | dmb ish
    ),
  )
  inspect(
    show_a32(0xF57FF04F),
    content=(
      #|DSB 15 | dsb sy
    ),
  )
  inspect(show_a32(0xE10F0000), content="MRS R0, 14, Nil | mrs r0, apsr")
  inspect(
    show_a32(0xE128F000),
    content=(
      #|MSR 8, R0, 14, Nil | msr APSR_nzcvq, r0
    ),
  )
  inspect(show_a32(0xF10C0080), content="CPS2p 3, 2 | cpsid i")
  // coprocessor and VFP instructions (the tables of `decode_ext.mbt`)
  inspect(
    show_a32(0xEE070F15),
    content=(
      #|MCR 15, 0, R0, 7, 5, 0, 14, Nil | mcr p15, #0, r0, c7, c5, #0
    ),
  )
  inspect(
    show_a32(0xEE300A01),
    content=(
      #|VADDS S0, S0, S2, 14, Nil | vadd.f32 s0, s0, s2
    ),
  )
  inspect(show_a32(0xFFFFFFFF), content="invalid")
}

///|
test "A32 kinds, raw bytes and the decoder interface" {
  let bytes : Bytes = b"\x01\x00\x80\xe0\x1e\xff\x2f\xe1\x00"
  match @arm.decode_a32(bytes[:], addr=0x1000) {
    Decoded(insn) => {
      assert_eq(insn.name, "ADDrr")
      assert_eq(insn.size, 4)
      assert_eq(insn.addr, 0x1000)
      assert_eq(insn.raw, b"\x01\x00\x80\xe0")
      assert_true(insn.encoding == @core_theory.Language::llvm_a32())
    }
    other => fail("unexpected \{Repr(other)}")
  }
  guard @arm.decode_a32(bytes[4:]) is Decoded(ret) else { fail("no bx lr") }
  debug_inspect(
    ret.kinds,
    content=(
      #|<ReadOnlyArray: [Return, Barrier, Terminator, MayAffectControlFlow]>
    ),
  )
  assert_true(@arm.decode_a32(bytes[8:]) is Truncated)
  assert_true(@arm.decode_a32(b"\x00\x00\x10\xf1"[:]) is Invalid(size=4))
  // big-endian words
  guard @arm.decode_a32(b"\xe0\x80\x00\x01"[:], big_endian=true) is Decoded(add) else {
    fail("no big-endian add")
  }
  assert_eq(add.name, "ADDrr")
  assert_eq(add.raw, b"\xe0\x80\x00\x01")
  // kinds of loads, stores, calls and branches
  let kinds = (w : UInt) => @arm.decode_a32_word(w).unwrap().kinds
  debug_inspect(
    kinds(0xE5910004),
    content=(
      #|<ReadOnlyArray: [MayLoad]>
    ),
  )
  debug_inspect(
    kinds(0xE92D4010),
    content=(
      #|<ReadOnlyArray: [MayStore]>
    ),
  )
  debug_inspect(
    kinds(0xE8BD8010),
    content=(
      #|<ReadOnlyArray: [MayAffectControlFlow, MayLoad]>
    ),
  )
  debug_inspect(
    kinds(0xEBFFFFFE),
    content=(
      #|<ReadOnlyArray: [Call, MayAffectControlFlow]>
    ),
  )
  debug_inspect(
    kinds(0x0A000001),
    content=(
      #|<ReadOnlyArray: [ConditionalBranch, Terminator, MayAffectControlFlow]>
    ),
  )
  // the decoder is selected for ARM targets decoded as A32
  let ctx = @mc.Context::create(
    @core_theory.Target::arm(),
    encoding=@core_theory.Language::llvm_a32(),
  )
  assert_true(@arm.a32_decoder().accepts(ctx))
  let thumb = @mc.Context::create(
    @core_theory.Target::arm(),
    encoding=@core_theory.Language::llvm_t32(),
  )
  assert_true(!@arm.a32_decoder().accepts(thumb))
  @arm.register_decoder()
  @arm.register_decoder()
  assert_eq(
    @mc.decoders().filter(d => d.name() == @arm.a32_decoder_name).length(),
    1,
  )
  assert_true(
    @mc.find_decoder(ctx).map(d => d.name()) == Some(@arm.a32_decoder_name),
  )
}

///|
test "every decoded A32 opcode is known to the lifter or listed" {
  // opcodes the decoder produces that the ARM lifter does not model
  let extra = [
    "ADR", "CLZ", "PKHBT", "SMLABT", "SMLATB", "SMLATT", "SMLAWT", "SMULWB", "SMULWT",
    "SMLALBB", "SMLALTB", "SMLALTT", "SMULBT", "SMULTT", "SMLADX", "SMUADX", "SWP",
    "ISB", "MRSsys", "REVSH", "LDRT_POST_IMM", "STRT_POST_IMM", "LDRHTi", "STRHTi",
    "LDRSBTi", "SXTAB", "UXTAH",
  ]
  let words : Array[UInt] = [
    0xE0800001, 0xE2932001, 0xE1A00101, 0xE3510000, 0xE5910004, 0xE5210004, 0xE4910004,
    0xE7910102, 0xE1D100B2, 0xE16D20F8, 0xE92D4010, 0xE8BD8010, 0xE12FFF1E, 0xEBFFFFFE,
    0x0A000001, 0xE0000291, 0xE0810392, 0xE6EF0071, 0xE7E70251, 0xE7CB0411, 0xEF000000,
    0xE320F000, 0xF57FF05B, 0xE3010234, 0xE3450678, 0xE1910F9F, 0xE1812F90, 0xE10F0000,
    0xE128F000, 0xFB000000, 0xE16F0F11, 0xE28F0008,
  ]
  for w in words {
    let insn = @arm.decode_a32_word(w).unwrap()
    assert_true(
      @arm.Insn::of_name(insn.name) is Some(_) || extra.contains(insn.name),
      msg="\{insn.name}",
    )
  }
}
