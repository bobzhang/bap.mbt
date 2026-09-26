// Port of `lib_test/powerpc/powerpc_logical_tests.ml`.

///|
/// `v` as a register-sized value.
fn sv(a : @powerpc.AddrSize, v : Int64) -> UInt64 {
  trunc(a, v.reinterpret_as_uint64())
}

///|
test "andi. and andis." {
  for a in archs {
    // 71 2a 00 1f  andi. r10, r9, 31
    for name in ["ANDIo", "ANDI_rec"] {
      let r = run(
        a,
        name,
        [reg("R10"), reg("R9"), imm(31)],
        init=[("R9", 10)],
        word=0x712a001f,
      )
      r.check("R10", 10)
      r.check_cr0(0, 1, 0)
    }
    // 75 2a 0e 00  andis. r10, r9, 0xe00
    for name in ["ANDISo", "ANDIS_rec"] {
      let r = run(
        a,
        name,
        [reg("R10"), reg("R9"), imm(0x0E00)],
        init=[("R9", 0x0800_0000)],
        word=0x752a0e00,
      )
      r.check("R10", 0x0800_0000)
    }
  }
}

///|
/// `name rA, rS, rB` with rS = `x` and rB = `y`, where `ra`, `rs` and `rb`
/// name the registers.
fn logic3(
  a : @powerpc.AddrSize,
  name : String,
  ra : String,
  rs : String,
  rb : String,
  x : Int64,
  y : Int64,
  word? : UInt,
) -> Run raise {
  run(
    a,
    name,
    [reg(ra), reg(rs), reg(rb)],
    init=[(rb, sv(a, y)), (rs, sv(a, x))],
    word?,
  )
}

///|
test "and, andc" {
  for a in archs {
    // 7f 39 e8 38  and r25, r25, r29
    logic3(a, "AND", "R25", "R25", "R29", 10, 31, word=0x7f39e838).check(
      "R25",
      31 & 10,
    )
    // 7f 39 e8 39  and. r25, r25, r29
    let r = logic3(a, "ANDo", "R25", "R25", "R29", 10, 31, word=0x7f39e839)
    r.check("R25", 10)
    r.check_cr0(0, 1, 0)
    // 7c ea 50 78  andc r10, r7, r10
    logic3(a, "ANDC", "R10", "R7", "R10", 21, 10, word=0x7cea5078).check(
      "R10",
      sv(a, 21L & 10L.lnot()),
    )
    // 7c ea 50 79  andc. r10, r7, r10
    let r = logic3(a, "ANDCo", "R10", "R7", "R10", 42, 42, word=0x7cea5079)
    r.check("R10", 0)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "ori, oris, or, orc" {
  for a in archs {
    // 60 c6 51 c1  ori r6, r6, 20929
    run(
      a,
      "ORI",
      [reg("R6"), reg("R6"), imm(20929)],
      init=[("R6", 62)],
      word=0x60c651c1,
    ).check("R6", 62 | 20929)
    // 65 4a 00 0f  oris r10, r10, 15
    run(
      a,
      "ORIS",
      [reg("R10"), reg("R10"), imm(15)],
      init=[("R10", 61440)],
      word=0x654a000f,
    ).check("R10", 61440 | (15 << 16))
    // 7f 38 c3 78  or r24, r25, r24
    logic3(a, "OR", "R24", "R25", "R24", 10, 24, word=0x7f38c378).check(
      "R24",
      24 | 10,
    )
    let r = logic3(a, "ORo", "R24", "R25", "R24", 10, 24, word=0x7f38c379)
    r.check("R24", 24 | 10)
    r.check_cr0(0, 1, 0)
    // 7c 8a 53 38  orc r10, r4, r10
    logic3(a, "ORC", "R10", "R4", "R10", 42, 10, word=0x7c8a5338).check(
      "R10",
      sv(a, 42L | 10L.lnot()),
    )
    let r = logic3(a, "ORCo", "R10", "R4", "R10", 42, 0, word=0x7c8a5339)
    r.check("R10", sv(a, -1))
    r.check_cr0(1, 0, 0)
  }
}

///|
test "nop" {
  for a in archs {
    inspect(
      @powerpc.lift(a, BigEndian, decode_as(a, 0x60000000, "NOP", [])).length(),
      content="0",
    )
  }
}

///|
test "xori, xoris, xor" {
  for a in archs {
    // 68 63 00 0b  xori r3, r3, 11
    run(
      a,
      "XORI",
      [reg("R3"), reg("R3"), imm(11)],
      init=[("R3", 16)],
      word=0x6863000b,
    ).check("R3", 16 ^ 11)
    // 6d 2a 00 0f  xoris r10, r9, 15
    run(
      a,
      "XORIS",
      [reg("R10"), reg("R9"), imm(15)],
      init=[("R9", 0x1F0000)],
      word=0x6d2a000f,
    ).check("R10", 0x1F0000 ^ (15 << 16))
    // 7c 6a 52 78  xor r10, r3, r10
    logic3(a, "XOR", "R10", "R3", "R10", 42, 15, word=0x7c6a5278).check(
      "R10",
      42 ^ 15,
    )
    let r = logic3(a, "XORo", "R10", "R3", "R10", 42, 42, word=0x7c6a5279)
    r.check("R10", 0)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "nand, nor, eqv" {
  for a in archs {
    // 7c 63 23 b8  nand r3, r3, r4
    logic3(a, "NAND", "R3", "R3", "R4", 42, 15, word=0x7c6323b8).check(
      "R3",
      sv(a, (42L & 15L).lnot()),
    )
    let r = logic3(a, "NANDo", "R3", "R3", "R4", 42, 15, word=0x7c6323b9)
    r.check("R3", sv(a, (42L & 15L).lnot()))
    r.check_cr0(1, 0, 0)
    // 7d 09 48 f8  nor r9, r8, r9
    logic3(a, "NOR", "R9", "R8", "R9", 42, 15, word=0x7d0948f8).check(
      "R9",
      sv(a, (42L | 15L).lnot()),
    )
    let r = logic3(a, "NORo", "R9", "R8", "R9", 42, -15, word=0x7d0948f9)
    r.check("R9", sv(a, (42L | -15L).lnot()))
    r.check_cr0(0, 1, 0)
    // 7d 09 4a 38  eqv r9, r8, r9
    logic3(a, "EQV", "R9", "R8", "R9", 42, 15, word=0x7d094a38).check(
      "R9",
      sv(a, (42L ^ 15L).lnot()),
    )
    let r = logic3(a, "EQVo", "R9", "R8", "R9", -1, 0, word=0x7d094a39)
    r.check("R9", 0)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "extsb, extsh, extsw" {
  for a in archs {
    // 7d 6a 07 74  extsb r10, r11
    run(
      a,
      "EXTSB",
      [reg("R10"), reg("R11")],
      init=[("R11", 0xC0)],
      word=0x7d6a0774,
    ).check("R10", sv(a, -0x40))
    // 7d 25 07 34  extsh r5, r9
    run(
      a,
      "EXTSH",
      [reg("R5"), reg("R9")],
      init=[("R9", 0xC000)],
      word=0x7d250734,
    ).check("R5", sv(a, -0x4000))
    let r = run(
      a,
      "EXTSHo",
      [reg("R5"), reg("R9")],
      init=[("R9", 0xC000)],
      word=0x7d250735,
    )
    r.check("R5", sv(a, -0x4000))
    r.check_cr0(1, 0, 0)
    // 7d 25 07 b4  extsw r5, r9
    run(
      a,
      "EXTSW",
      [reg("X5"), reg("X9")],
      init=[("R9", 0xC0000000)],
      word=0x7d2507b4,
    ).check("R5", sv(a, -0x40000000))
    run(
      a,
      "EXTSWo",
      [reg("X5"), reg("X9")],
      init=[("R9", 0xC0000000)],
      word=0x7d2507b5,
    ).check("R5", sv(a, -0x40000000))
    run(a, "EXTSBo", [reg("R5"), reg("R9")], init=[("R9", 0x7F)]).check_cr0(
      0, 1, 0,
    )
  }
}

///|
test "cntlzw and cnttzw" {
  for a in archs {
    for
      case in [(0x0UL, 32UL), (0x4000000, 5), (0x40000000, 1), (0x80000000, 0)] {
      let (value, zeros) = case
      // 7c 63 00 34  cntlzw r3, r3
      run(
        a,
        "CNTLZW",
        [reg("R3"), reg("R3")],
        init=[("R3", value)],
        word=0x7c630034,
      ).check("R3", zeros)
    }
    for case in [(0x0UL, 32UL), (0x1, 0), (0x2, 1), (0x20, 5)] {
      let (value, zeros) = case
      // 7c 63 04 34  cnttzw r3, r3
      run(
        a,
        "CNTTZW",
        [reg("R3"), reg("R3")],
        init=[("R3", value)],
        word=0x7c630434,
      ).check("R3", zeros)
    }
    let r = run(a, "CNTLZWo", [reg("R3"), reg("R3")], init=[("R3", 0)])
    r.check("R3", 32)
    r.check_cr0(0, 1, 0)
    run(a, "CNTTZWo", [reg("R3"), reg("R3")], init=[("R3", 1)]).check_cr0(
      0, 0, 1,
    )
  }
  // the high word is ignored on 64-bit targets
  run(
    R64,
    "CNTLZW",
    [reg("R3"), reg("R3")],
    init=[("R3", 0xFFFF_0000_0000_0001)],
    word=0x7c630034,
  ).check("R3", 31)
}

///|
test "cntlzd and cnttzd" {
  // 7c 63 00 74  cntlzd r3, r3
  run(
    R64,
    "CNTLZD",
    [reg("X3"), reg("X3")],
    init=[("R3", 0x0000FFFF_00000000)],
    word=0x7c630074,
  ).check("R3", 16)
  run(R64, "CNTLZDo", [reg("X3"), reg("X3")], init=[("R3", 0)]).check("R3", 64)
  // 7c 63 04 75  cnttzd. r3, r3
  run(
    R64,
    "CNTTZDo",
    [reg("X3"), reg("X3")],
    init=[("R3", 0x00000000_FFFF0000)],
    word=0x7c630475,
  ).check("R3", 16)
  run(R64, "CNTTZD", [reg("X3"), reg("X3")], init=[("R3", 0)]).check("R3", 64)
}

///|
test "cmpb" {
  let cases : Array[(UInt64, UInt64, UInt64)] = [
    (0x31_41_AD, 0x34_42_AD, 0x00_00_FF),
    (0x31_42_45, 0x34_42_AD, 0x00_FF_00),
    (0, 0x34_42_AD, 0x0),
    (0x34_42_AD, 0x34_42_AD, 0xFF_FF_FF),
  ]
  for a in archs {
    for case in cases {
      let (x, y, low3) = case
      // 7c 8a 53 f8  cmpb r10, r4, r10: the untouched high bytes are equal
      let head = trunc(a, all_ones) ^ 0xFF_FFFF
      let r = run(
        a,
        "CMPB",
        [reg("R10"), reg("R4"), reg("R10")],
        init=[("R10", x), ("R4", y)],
        word=0x7c8a53f8,
      )
      r.check("R10", head | low3)
    }
  }
}

///|
test "popcntw and popcntd" {
  // 7c 44 02 f4  popcntw r4, r2
  run(
    R32,
    "POPCNTW",
    [reg("R4"), reg("R2")],
    init=[("R2", 0x10000001)],
    word=0x7c4402f4,
  ).check("R4", 2)
  // 4 bits set in the first word, and 2 in the second
  run(
    R64,
    "POPCNTW",
    [reg("R4"), reg("R2")],
    init=[("R2", 0xA0200040_10000001)],
    word=0x7c4402f4,
  ).check("R4", 0x4_0000_0002)
  // 7c 44 03 f4  popcntd r4, r2
  run(
    R64,
    "POPCNTD",
    [reg("X4"), reg("X2")],
    init=[("R2", 0x0F00000F_00000001)],
    word=0x7c4403f4,
  ).check("R4", 9)
}

///|
test "bpermd" {
  // 7c a1 49 f8  bpermd r1, r5, r9
  let r = run(
    R64,
    "BPERMD",
    [reg("X1"), reg("X5"), reg("X9")],
    init=[("R5", 0x05_00_01_44_25_1B_02_04), ("R9", 0xFFABCDEF_0A0B0C0D)],
    word=0x7ca149f8,
  )
  r.check("R1", 0xE3)
}
