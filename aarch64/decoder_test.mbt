// Tests of the A64 decoder on real instruction encodings (hand-assembled
// from the ARM Architecture Reference Manual, ARMv8-A).

///|
fn show(word : UInt32) -> String {
  match @aarch64.decode_a64_word(word, addr=0x1000) {
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
test "A64 arithmetic and logical instructions" {
  inspect(show(0x91001020), content="ADDXri X0, X1, 4, 0 | add x0, x1, #4")
  inspect(show(0xF1000420), content="SUBSXri X0, X1, 1, 0 | subs x0, x1, #1")
  inspect(show(0xF100041F), content="SUBSXri XZR, X0, 1, 0 | cmp x0, #1")
  inspect(show(0x910003FD), content="ADDXri FP, SP, 0, 0 | mov x29, sp")
  inspect(show(0xD10043FF), content="SUBXri SP, SP, 16, 0 | sub sp, sp, #16")
  inspect(
    show(0x8B020C20),
    content="ADDXrs X0, X1, X2, 3 | add x0, x1, x2, lsl #3",
  )
  inspect(show(0x6B020020), content="SUBSWrs W0, W1, W2, 0 | subs w0, w1, w2")
  inspect(
    show(0xCB216BE0),
    content=(
      #|SUBXrx64 X0, SP, X1, 26 | sub x0, sp, x1, lsl #2
    ),
  )
  inspect(
    show(0x9B020C20),
    content="MADDXrrr X0, X1, X2, X3 | madd x0, x1, x2, x3",
  )
  inspect(show(0x9B027C20), content="MADDXrrr X0, X1, X2, XZR | mul x0, x1, x2")
  inspect(
    show(0x1B028C20),
    content="MSUBWrrr W0, W1, W2, W3 | msub w0, w1, w2, w3",
  )
  inspect(show(0x9AC20C20), content="SDIVXr X0, X1, X2 | sdiv x0, x1, x2")
  inspect(show(0x1AC20820), content="UDIVWr W0, W1, W2 | udiv w0, w1, w2")
  inspect(show(0xB0000000), content="ADRP X0, 1 | adrp x0, #4096")
  inspect(show(0x10000020), content="ADR X0, 4 | adr x0, #4")
  inspect(show(0x92401C20), content="ANDXri X0, X1, 4103 | and x0, x1, #0xff")
  inspect(
    show(0x320003E0),
    content=(
      #|ORRWri W0, WZR, 0 | orr w0, wzr, #0x1
    ),
  )
  inspect(show(0xCA020020), content="EORXrs X0, X1, X2, 0 | eor x0, x1, x2")
  inspect(show(0xAA0103E0), content="ORRXrs X0, XZR, X1, 0 | mov x0, x1")
  inspect(
    show(0x2A220820),
    content="ORNWrs W0, W1, W2, 2 | orn w0, w1, w2, lsl #2",
  )
  inspect(show(0xEA020020), content="ANDSXrs X0, X1, X2, 0 | ands x0, x1, x2")
  inspect(show(0xD344FC20), content="UBFMXri X0, X1, 4, 63 | lsr x0, x1, #4")
  inspect(show(0xD37DF020), content="UBFMXri X0, X1, 61, 60 | lsl x0, x1, #3")
  inspect(
    show(0x93407C20),
    content=(
      #|SBFMXri X0, X1, 0, 31 | sxtw x0, w1
    ),
  )
  inspect(
    show(0x33180C20),
    content=(
      #|BFMWri W0, W0, W1, 24, 3 | bfi w0, w1, #8, #4
    ),
  )
  inspect(
    show(0xD2800000),
    content=(
      #|MOVZXi X0, 0, 0 | mov x0, #0
    ),
  )
  inspect(
    show(0x52800020),
    content=(
      #|MOVZWi W0, 1, 0 | mov w0, #1
    ),
  )
  inspect(
    show(0x92800000),
    content=(
      #|MOVNXi X0, 0, 0 | mov x0, #-1
    ),
  )
  inspect(
    show(0xF2A24680),
    content="MOVKXi X0, X0, 4660, 16 | movk x0, #4660, lsl #16",
  )
  inspect(
    show(0x9A820020),
    content="CSELXr X0, X1, X2, 0 | csel x0, x1, x2, eq",
  )
  inspect(
    show(0x1A9F17E0),
    content=(
      #|CSINCWr W0, WZR, WZR, 1 | cset w0, eq
    ),
  )
  inspect(show(0xFA421800), content="CCMPXi X0, 2, 0, 1 | ccmp x0, #2, #0, ne")
  inspect(show(0x3A420024), content="CCMNWr W1, W2, 4, 0 | ccmn w1, w2, #4, eq")
  inspect(show(0x3A00082D), content="SETF8 W1 | setf8 w1")
  inspect(show(0xBA018422), content="RMIF X1, 3, 2 | rmif x1, #3, #2")
  // floating point
  inspect(show(0x1E622820), content="FADDDrr D0, D1, D2 | fadd d0, d1, d2")
}

///|
test "A64 loads and stores" {
  inspect(show(0xF9400420), content="LDRXui X0, X1, 1 | ldr x0, [x1, #8]")
  inspect(show(0xB9000FE0), content="STRWui W0, SP, 3 | str w0, [sp, #12]")
  inspect(
    show(0x39400020),
    content=(
      #|LDRBBui W0, X1, 0 | ldrb w0, [x1]
    ),
  )
  inspect(show(0x39000420), content="STRBBui W0, X1, 1 | strb w0, [x1, #1]")
  inspect(show(0xB9800420), content="LDRSWui X0, X1, 1 | ldrsw x0, [x1, #4]")
  inspect(show(0xF81F83A0), content="STURXi X0, FP, -8 | stur x0, [x29, #-8]")
  inspect(show(0x38001020), content="STURBBi W0, X1, 1 | sturb w0, [x1, #1]")
  inspect(show(0x781FE020), content="STURHHi W0, X1, -2 | sturh w0, [x1, #-2]")
  inspect(
    show(0xF8627820),
    content="LDRXroX X0, X1, X2, 0, 1 | ldr x0, [x1, x2, lsl #3]",
  )
  inspect(
    show(0x38626820),
    content="LDRBBroX W0, X1, X2, 0, 0 | ldrb w0, [x1, x2]",
  )
  inspect(
    show(0xF8226820),
    content="STRXroX X0, X1, X2, 0, 0 | str x0, [x1, x2]",
  )
  inspect(show(0xF8408420), content="LDRXpost X1, X0, X1, 8 | ldr x0, [x1], #8")
  inspect(
    show(0xF81F0FE0),
    content="STRXpre SP, X0, SP, -16 | str x0, [sp, #-16]!",
  )
  inspect(
    show(0xA9BF7BFD),
    content="STPXpre SP, FP, LR, SP, -2 | stp x29, x30, [sp, #-16]!",
  )
  inspect(
    show(0xA8C17BFD),
    content="LDPXpost SP, FP, LR, SP, 2 | ldp x29, x30, [sp], #16",
  )
  inspect(
    show(0xA94107E0),
    content="LDPXi X0, X1, SP, 2 | ldp x0, x1, [sp, #16]",
  )
  inspect(
    show(0xA90007E0),
    content=(
      #|STPXi X0, X1, SP, 0 | stp x0, x1, [sp]
    ),
  )
  inspect(show(0x58000040), content="LDRXl X0, 2 | ldr x0, #8")
  inspect(show(0xC8A07C41), content="CASX X0, X0, X1, X2 | cas x0, x1, [x2]")
  inspect(
    show(0x88E0FC41),
    content="CASALW W0, W0, W1, X2 | casal w0, w1, [x2]",
  )
}

///|
test "A64 branches and system instructions" {
  inspect(show(0x14000002), content="B 2 | b #8")
  inspect(show(0x94000000), content="BL 0 | bl #0")
  inspect(show(0x54000041), content="Bcc 1, 2 | b.ne #8")
  inspect(show(0xB4000040), content="CBZX X0, 2 | cbz x0, #8")
  inspect(show(0x35FFFFE1), content="CBNZW W1, -1 | cbnz w1, #-4")
  inspect(show(0x36180040), content="TBZW W0, 3, 2 | tbz w0, #3, #8")
  inspect(show(0xB7FFFFC1), content="TBNZX X1, 63, -2 | tbnz x1, #63, #-8")
  inspect(show(0xD65F03C0), content="RET LR | ret")
  inspect(show(0xD61F0200), content="BR X16 | br x16")
  inspect(show(0xD63F0100), content="BLR X8 | blr x8")
  inspect(
    show(0xD503201F),
    content=(
      #|NOP  | nop
    ),
  )
  inspect(
    show(0xD5033BBF),
    content=(
      #|DMB 11 | dmb ish
    ),
  )
  inspect(
    show(0xD5033F9F),
    content=(
      #|DSB 15 | dsb sy
    ),
  )
  inspect(
    show(0xD5033FDF),
    content=(
      #|ISB 15 | isb
    ),
  )
  inspect(show(0xD500401F), content="CFINV  | cfinv")
  inspect(show(0xD4000001), content="SVC 0 | svc #0")
  inspect(show(0x00000001), content="UDF 1 | udf #1")
}

///|
test "A64 kinds, raw bytes and the decoder interface" {
  let bytes : Bytes = b"\xc0\x03\x5f\xd6\x00"
  guard @aarch64.decode_a64(bytes[:], addr=0x4000) is Decoded(ret) else {
    fail("no ret")
  }
  assert_eq(ret.name, "RET")
  assert_eq(ret.raw, b"\xc0\x03\x5f\xd6")
  assert_eq(ret.addr, 0x4000)
  assert_true(ret.encoding == @core_theory.Language::llvm_a64())
  debug_inspect(
    ret.kinds.iter().collect(),
    content="[Return, Barrier, Terminator, MayAffectControlFlow]",
  )
  assert_true(@aarch64.decode_a64(bytes[4:]) is Truncated)
  // SVE is not enabled
  assert_true(@aarch64.decode_a64(b"\x00\x00\xa0\x04"[:]) is Invalid(size=4))
  fn kinds(w : UInt32) -> Array[@mc.Kind] {
    @aarch64.decode_a64_word(w).unwrap().kinds.iter().collect()
  }
  debug_inspect(kinds(0x94000000), content="[Call, MayAffectControlFlow]")
  debug_inspect(
    kinds(0x54000041),
    content=(
      #|[ConditionalBranch, Terminator, MayAffectControlFlow]
    ),
  )
  debug_inspect(
    kinds(0x14000002),
    content="[UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]",
  )
  debug_inspect(kinds(0xF9400420), content="[MayLoad]")
  debug_inspect(kinds(0xA9BF7BFD), content="[MayStore]")
  // bit masks of the logical immediates
  debug_inspect(@aarch64.decode_bit_masks(1, 7, 0, 64), content="Some(255)")
  debug_inspect(
    @aarch64.decode_bit_masks(0, 0b111100, 0, 32),
    content="Some(1431655765)",
  )
  debug_inspect(@aarch64.decode_bit_masks(0, 0b111111, 0, 32), content="None")
  // the decoder applies to AArch64 targets
  let ctx = @mc.Context::create(@core_theory.Target::aarch64())
  assert_true(@aarch64.a64_decoder().accepts(ctx))
  assert_true(
    !@aarch64.a64_decoder().accepts(
      @mc.Context::create(@core_theory.Target::arm()),
    ),
  )
  @aarch64.register_decoder()
  @aarch64.register_decoder()
  assert_eq(
    @mc.decoders().filter(d => d.name() == @aarch64.a64_decoder_name).length(),
    1,
  )
}
