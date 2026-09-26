// Tests of the T32 decoder on real instruction encodings (hand-assembled
// from the ARM Architecture Reference Manual, ARMv7-A/R, Thumb and
// Thumb-2).

///|
/// The little-endian bytes of the halfwords `hs`.
fn halfwords(hs : Array[Int]) -> Bytes {
  Bytes::makei(hs.length() * 2, i => {
    let h = hs[i / 2]
    (if i % 2 == 0 { h } else { h >> 8 }).to_byte()
  })
}

///|
fn show_insn(insn : @mc.Insn) -> String {
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

///|
/// Decode the instruction made of the halfwords `hs` (outside of an IT
/// block).
fn show_t32(hs : Array[Int]) -> String {
  match @thumb.decode_t32(halfwords(hs)[:], addr=0x1000) {
    Decoded(insn) => {
      assert_eq(insn.size, hs.length() * 2) catch {
        _ => return "wrong size"
      }
      show_insn(insn)
    }
    Invalid(..) => "invalid"
    Truncated => "truncated"
  }
}

///|
/// Decode a sequence of instructions with an IT state.
fn show_seq(hs : Array[Int]) -> String {
  let bytes = halfwords(hs)
  let it = @thumb.ItBlock::new()
  let out = []
  for off = 0; off < bytes.length(); {
    match @thumb.decode_t32(bytes[off:], addr=0x1000UL + off.to_uint64(), it~) {
      Decoded(insn) => {
        out.push(show_insn(insn))
        continue off + insn.size
      }
      Invalid(size~) => {
        out.push("invalid")
        continue off + size
      }
      Truncated => break
    }
  }
  out.join("\n")
}

///|
test "Thumb data processing" {
  inspect(
    show_t32([0x1C48]),
    content="tADDi3 R0, CPSR, R1, 1, 14, Nil | adds r0, r1, #1",
  )
  inspect(
    show_t32([0x1840]),
    content="tADDrr R0, CPSR, R0, R1, 14, Nil | adds r0, r0, r1",
  )
  inspect(
    show_t32([0x1A40]),
    content="tSUBrr R0, CPSR, R0, R1, 14, Nil | subs r0, r0, r1",
  )
  inspect(
    show_t32([0x2005]),
    content="tMOVi8 R0, CPSR, 5, 14, Nil | movs r0, #5",
  )
  inspect(show_t32([0x2805]), content="tCMPi8 R0, 5, 14, Nil | cmp r0, #5")
  inspect(
    show_t32([0x3001]),
    content="tADDi8 R0, CPSR, R0, 1, 14, Nil | adds r0, #1",
  )
  inspect(
    show_t32([0x0088]),
    content="tLSLri R0, CPSR, R1, 2, 14, Nil | lsls r0, r1, #2",
  )
  inspect(
    show_t32([0x0808]),
    content=(
      #|tLSRri R0, CPSR, R1, 0, 14, Nil | lsrs r0, r1, #32
    ),
  )
  inspect(show_t32([0x0008]), content="tMOVSr R0, R1 | movs r0, r1")
  inspect(
    show_t32([0x4008]),
    content="tAND R0, CPSR, R0, R1, 14, Nil | ands r0, r1",
  )
  inspect(
    show_t32([0x4348]),
    content="tMUL R0, CPSR, R1, R0, 14, Nil | muls r0, r1, r0",
  )
  inspect(
    show_t32([0x4248]),
    content="tRSB R0, CPSR, R1, 14, Nil | rsbs r0, r1, #0",
  )
  inspect(show_t32([0x4208]), content="tTST R0, R1, 14, Nil | tst r0, r1")
  inspect(
    show_t32([0x43C8]),
    content="tMVN R0, CPSR, R1, 14, Nil | mvns r0, r1",
  )
  inspect(show_t32([0x4680]), content="tMOVr R8, R0, 14, Nil | mov r8, r0")
  inspect(
    show_t32([0x4440]),
    content="tADDhirr R0, R0, R8, 14, Nil | add r0, r8",
  )
  inspect(show_t32([0x4540]), content="tCMPhir R0, R8, 14, Nil | cmp r0, r8")
  inspect(
    show_t32([0xA802]),
    content="tADDrSPi R0, SP, 2, 14, Nil | add r0, sp, #8",
  )
  inspect(show_t32([0xB082]), content="tSUBspi SP, SP, 2, 14, Nil | sub sp, #8")
  inspect(show_t32([0xB002]), content="tADDspi SP, SP, 2, 14, Nil | add sp, #8")
  inspect(show_t32([0xA002]), content="tADR R0, 2, 14, Nil | adr r0, #8")
  inspect(show_t32([0xB2C8]), content="tUXTB R0, R1, 14, Nil | uxtb r0, r1")
  inspect(show_t32([0xB208]), content="tSXTH R0, R1, 14, Nil | sxth r0, r1")
  inspect(show_t32([0xBA08]), content="tREV R0, R1, 14, Nil | rev r0, r1")
  inspect(show_t32([0xBA48]), content="tREV16 R0, R1, 14, Nil | rev16 r0, r1")
  inspect(show_t32([0xBF00]), content="tHINT 0, 14, Nil | nop")
}

///|
test "Thumb loads, stores and branches" {
  inspect(
    show_t32([0x4802]),
    content="tLDRpci R0, 8, 14, Nil | ldr r0, [pc, #8]",
  )
  inspect(
    show_t32([0x5888]),
    content="tLDRr R0, R1, R2, 14, Nil | ldr r0, [r1, r2]",
  )
  inspect(
    show_t32([0x5688]),
    content="tLDRSB R0, R1, R2, 14, Nil | ldrsb r0, [r1, r2]",
  )
  inspect(
    show_t32([0x6048]),
    content="tSTRi R0, R1, 1, 14, Nil | str r0, [r1, #4]",
  )
  inspect(
    show_t32([0x78C8]),
    content="tLDRBi R0, R1, 3, 14, Nil | ldrb r0, [r1, #3]",
  )
  inspect(
    show_t32([0x8848]),
    content="tLDRHi R0, R1, 1, 14, Nil | ldrh r0, [r1, #2]",
  )
  inspect(
    show_t32([0x9001]),
    content="tSTRspi R0, SP, 1, 14, Nil | str r0, [sp, #4]",
  )
  inspect(show_t32([0xB510]), content="tPUSH 14, Nil, R4, LR | push {r4, lr}")
  inspect(show_t32([0xBD10]), content="tPOP 14, Nil, R4, PC | pop {r4, pc}")
  inspect(
    show_t32([0xC806]),
    content="tLDMIA R0, 14, Nil, R1, R2 | ldm r0!, {r1, r2}",
  )
  inspect(
    show_t32([0xC002]),
    content="tSTMIA_UPD R0, R0, 14, Nil, R1 | stm r0!, {r1}",
  )
  inspect(show_t32([0x4770]), content="tBX LR, 14, Nil | bx lr")
  inspect(show_t32([0x4798]), content="tBLXr 14, Nil, R3 | blx r3")
  inspect(show_t32([0xB110]), content="tCBZ R0, 4 | cbz r0, #4")
  inspect(show_t32([0xB921]), content="tCBNZ R1, 8 | cbnz r1, #8")
  inspect(show_t32([0xD002]), content="tBcc 4, 0, CPSR | beq #4")
  inspect(show_t32([0xE7FE]), content="tB -4, 14, Nil | b #-4")
  inspect(show_t32([0xDF01]), content="tSVC 1, 14, Nil | svc #1")
  // a 32-bit instruction needs four bytes
  assert_true(@thumb.decode_t32(b"\x01\xf1"[:]) is Truncated)
  assert_true(@thumb.decode_t32(b"\x01"[:]) is Truncated)
}

///|
test "Thumb-2 data processing" {
  inspect(
    show_t32([0xF101, 0x0001]),
    content="t2ADDri R0, R1, 1, 14, Nil, Nil | add.w r0, r1, #1",
  )
  // modified immediates are decoded
  inspect(
    show_t32([0xF04F, 0x20FF]),
    content="t2MOVi R0, 4278255360, 14, Nil, Nil | mov.w r0, #4278255360",
  )
  inspect(
    show_t32([0xF44F, 0x5580]),
    content="t2MOVi R5, 4096, 14, Nil, Nil | mov.w r5, #4096",
  )
  inspect(
    show_t32([0xF1B0, 0x0F01]),
    content="t2CMPri R0, 1, 14, Nil | cmp.w r0, #1",
  )
  inspect(
    show_t32([0xF201, 0x1023]),
    content="t2ADDri12 R0, R1, 291, 14, Nil | addw r0, r1, #291",
  )
  inspect(
    show_t32([0xF241, 0x2034]),
    content="t2MOVi16 R0, 4660, 14, Nil | movw r0, #4660",
  )
  inspect(
    show_t32([0xEA4F, 0x0081]),
    content="t2LSLri R0, R1, 2, 14, Nil, Nil | lsl.w r0, r1, #2",
  )
  inspect(
    show_t32([0xEA4F, 0x0001]),
    content="t2MOVr R0, R1, 14, Nil, Nil | mov.w r0, r1",
  )
  inspect(
    show_t32([0xEB01, 0x00C2]),
    content="t2ADDrs R0, R1, R2, 26, 14, Nil, Nil | add.w r0, r1, r2, lsl #3",
  )
  inspect(
    show_t32([0xEA11, 0x0F02]),
    content="t2TSTrr R1, R2, 14, Nil | tst.w r1, r2",
  )
  inspect(
    show_t32([0xFB01, 0xF002]),
    content="t2MUL R0, R1, R2, 14, Nil | mul r0, r1, r2",
  )
  inspect(
    show_t32([0xFB91, 0xF0F2]),
    content="t2SDIV R0, R1, R2, 14, Nil | sdiv r0, r1, r2",
  )
  inspect(
    show_t32([0xFBA2, 0x0103]),
    content="t2UMULL R0, R1, R2, R3, 14, Nil | umull r0, r1, r2, r3",
  )
  inspect(
    show_t32([0xFA5F, 0xF081]),
    content="t2UXTB R0, R1, 0, 14, Nil | uxtb.w r0, r1",
  )
  inspect(
    show_t32([0xFA91, 0xF081]),
    content="t2REV R0, R1, 14, Nil | rev.w r0, r1",
  )
  inspect(
    show_t32([0xFAB1, 0xF081]),
    content=(
      #|t2CLZ R0, R1, 14, Nil | clz r0, r1
    ),
  )
  inspect(
    show_t32([0xF3C1, 0x1007]),
    content="t2UBFX R0, R1, 4, 7, 14, Nil | ubfx r0, r1, #4, #8",
  )
  inspect(
    show_t32([0xFA01, 0xF002]),
    content="t2LSLrr R0, R1, R2, 14, Nil, Nil | lsl.w r0, r1, r2",
  )
}

///|
test "Thumb-2 loads, stores and branches" {
  inspect(
    show_t32([0xF8D1, 0x0004]),
    content="t2LDRi12 R0, R1, 4, 14, Nil | ldr.w r0, [r1, #4]",
  )
  inspect(
    show_t32([0xF851, 0x0C04]),
    content="t2LDRi8 R0, R1, -4, 14, Nil | ldr r0, [r1, #-4]",
  )
  inspect(
    show_t32([0xF851, 0x0B04]),
    content="t2LDR_POST R0, R1, R1, 4, 14, Nil | ldr r0, [r1], #4",
  )
  inspect(
    show_t32([0xF841, 0x0D04]),
    content="t2STR_PRE R1, R0, R1, -4, 14, Nil | str r0, [r1, #-4]!",
  )
  inspect(
    show_t32([0xF851, 0x0022]),
    content="t2LDRs R0, R1, R2, 2, 14, Nil | ldr.w r0, [r1, r2, lsl #2]",
  )
  inspect(
    show_t32([0xF8DF, 0x0008]),
    content="t2LDRpci R0, 8, 14, Nil | ldr.w r0, [pc, #8]",
  )
  inspect(
    show_t32([0xE9D2, 0x0102]),
    content="t2LDRDi8 R0, R1, R2, 8, 14, Nil | ldrd r0, r1, [r2, #8]",
  )
  inspect(
    show_t32([0xE96D, 0x0102]),
    content="t2STRD_PRE SP, R0, R1, SP, -8, 14, Nil | strd r0, r1, [sp, #-8]!",
  )
  inspect(
    show_t32([0xE92D, 0x4030]),
    content="t2STMDB_UPD SP, SP, 14, Nil, R4, R5, LR | push.w {r4, r5, lr}",
  )
  inspect(
    show_t32([0xE8BD, 0x8030]),
    content="t2LDMIA_UPD SP, SP, 14, Nil, R4, R5, PC | pop.w {r4, r5, pc}",
  )
  inspect(
    show_t32([0xE851, 0x0F00]),
    content=(
      #|t2LDREX R0, R1, 0, 14, Nil | ldrex r0, [r1]
    ),
  )
  inspect(
    show_t32([0xE8D0, 0xF001]),
    content="t2TBB R0, R1, 14, Nil | tbb [r0, r1]",
  )
  inspect(show_t32([0xF001, 0xB800]), content="t2B 4096, 14, Nil | b.w #4096")
  inspect(show_t32([0xF000, 0x8004]), content="t2Bcc 8, 0, CPSR | beq.w #8")
  inspect(show_t32([0xF7FF, 0xFFFE]), content="tBL 14, Nil, -4 | bl #-4")
  inspect(show_t32([0xF000, 0xE804]), content="tBLXi 14, Nil, 8 | blx #8")
  inspect(
    show_t32([0xF3BF, 0x8F5B]),
    content=(
      #|t2DMB 11, 14, Nil | dmb ish
    ),
  )
  // coprocessor and VFP instructions are not decoded
  inspect(show_t32([0xEE07, 0x0F15]), content="invalid")
}

///|
test "IT blocks predicate the instructions they cover" {
  // ite eq; moveq r0, #1; movne r0, #2; movs r0, #3
  inspect(
    show_seq([0xBF0C, 0x2001, 0x2002, 0x2003]),
    content=(
      #|t2IT 0, 12 | ite eq
      #|tMOVi8 R0, Nil, 1, 0, CPSR | moveq r0, #1
      #|tMOVi8 R0, Nil, 2, 1, CPSR | movne r0, #2
      #|tMOVi8 R0, CPSR, 3, 14, Nil | movs r0, #3
    ),
  )
  // itt ne: the mask is stored condition-independently
  inspect(
    show_seq([0xBF1C, 0x1840, 0xF101, 0x0001]),
    content=(
      #|t2IT 1, 4 | itt ne
      #|tADDrr R0, Nil, R0, R1, 1, CPSR | addne r0, r0, r1
      #|t2ADDri R0, R1, 1, 1, CPSR, Nil | addne.w r0, r1, #1
    ),
  )
  // itete gt
  inspect(
    show_seq([0xBFCB, 0x2001, 0x2002, 0x2003, 0x2004]),
    content=(
      #|t2IT 12, 11 | itete gt
      #|tMOVi8 R0, Nil, 1, 12, CPSR | movgt r0, #1
      #|tMOVi8 R0, Nil, 2, 13, CPSR | movle r0, #2
      #|tMOVi8 R0, Nil, 3, 12, CPSR | movgt r0, #3
      #|tMOVi8 R0, Nil, 4, 13, CPSR | movle r0, #4
    ),
  )
  // the IT state does not survive a jump to an unrelated address
  let it = @thumb.ItBlock::new()
  let bytes = halfwords([0xBF08, 0x2001])
  guard @thumb.decode_t32(bytes[:2], addr=0x1000, it~) is Decoded(_) else {
    fail("no IT")
  }
  assert_true(it.in_block(0x1002))
  guard @thumb.decode_t32(bytes[2:], addr=0x2000, it~) is Decoded(mov) else {
    fail("no mov")
  }
  // outside of the block: the flag-setting form
  assert_eq(mov.ops[1], @arm.Reg::CPSR.to_mc())
}
