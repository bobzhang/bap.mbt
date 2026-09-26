// Port of `lib_test/powerpc/powerpc_add_tests.ml`.

///|
test "addi" {
  for a in archs {
    // 38 21 00 10  addi r1, r1, 16
    run(
      a,
      "ADDI",
      [reg("R1"), reg("R1"), imm(16)],
      init=[("R1", 26)],
      word=0x38210010,
    ).check("R1", 42)
    // 38 20 00 10  addi r1, 0, 16 is decoded as li r1, 16
    run(a, "LI", [reg("R1"), imm(16)], word=0x38200010).check("R1", 16)
    run(a, "ADDI", [reg("R1"), reg("ZERO"), imm(16)]).check("R1", 16)
    // the 64-bit `ZERO8` denotes zero as well
    run(a, "ADDI", [reg("R1"), reg("ZERO8"), imm(16)]).check("R1", 16)
    // la is an alias of addi
    run(a, "LA", [reg("R1"), reg("R1"), imm(-6)], init=[("R1", 48)]).check(
      "R1", 42,
    )
  }
}

///|
test "addis" {
  for a in archs {
    // 3f de 00 02  addis r30, r30, 2
    run(
      a,
      "ADDIS",
      [reg("R30"), reg("R30"), imm(2)],
      init=[("R30", 42)],
      word=0x3fde0002,
    ).check("R30", 42 + (2 << 16))
    // 3f c0 00 02  addis r30, 0, 2 is decoded as lis r30, 2
    run(a, "LIS", [reg("R30"), imm(2)], word=0x3fc00002).check("R30", 2 << 16)
    run(a, "ADDIS", [reg("R30"), reg("ZERO"), imm(2)]).check("R30", 2 << 16)
    // 3d 6b f0 00  addis r11, r11, -4096
    run(
      a,
      "ADDIS",
      [reg("R11"), reg("R11"), imm(-4096)],
      init=[("R11", 1)],
      word=0x3d6bf000,
    ).check("R11", trunc(a, 0xFFFF_FFFF_F000_0001))
  }
}

///|
test "li and lis" {
  for a in archs {
    run(a, "LI", [reg("R3"), imm(42)]).check("R3", 42)
    run(a, "LIS", [reg("R3"), imm(2)]).check("R3", 0x20000)
    // negative immediates are sign-extended on 64-bit targets, as with
    // `addi`/`addis` (upstream zero-extends them)
    run(a, "LIS", [reg("R3"), imm(-1)], word=0x3c60ffff).check(
      "R3",
      trunc(a, 0xFFFF_FFFF_FFFF_0000),
    )
    run(a, "LI", [reg("R3"), imm(-2)], word=0x3860fffe).check(
      "R3",
      trunc(a, 0xFFFF_FFFF_FFFF_FFFE),
    )
  }
}

///|
test "add" {
  for a in archs {
    // 7d 62 5a 14  add r11, r2, r11
    run(
      a,
      "ADD4",
      [reg("R11"), reg("R2"), reg("R11")],
      init=[("R2", 34), ("R11", 8)],
      word=0x7d625a14,
    ).check("R11", 42)
  }
}

///|
test "addic" {
  for a in archs {
    // 30 21 00 10  addic r1, r1, 16
    let r = run(
      a,
      "ADDIC",
      [reg("R1"), reg("R1"), imm(16)],
      init=[("R1", 0xFFFF_FFF0)],
      word=0x30210010,
    )
    match a {
      R32 => {
        r.check("R1", 0)
        r.check("CA", 1)
      }
      R64 => {
        r.check("R1", 0x1_0000_0000)
        r.check("CA", 0)
      }
    }
    r.check("CA32", 1)
  }
}

///|
test "addc" {
  for a in archs {
    // 7d 62 58 14  addc r11, r2, r11
    let r = run(
      a,
      "ADDC",
      [reg("R11"), reg("R2"), reg("R11")],
      init=[("R2", 0xFFFF_FFF0), ("R11", 16)],
      word=0x7d625814,
    )
    match a {
      R32 => {
        r.check("R11", 0)
        r.check("CA", 1)
      }
      R64 => {
        r.check("R11", 0x1_0000_0000)
        r.check("CA", 0)
      }
    }
    r.check("CA32", 1)
  }
}

///|
test "adde" {
  for a in archs {
    // 7c 21 81 14  adde r1, r1, r16
    let r = run(
      a,
      "ADDE",
      [reg("R1"), reg("R1"), reg("R16")],
      init=[("R1", 0xFFFF_FFF0), ("R16", 15), ("CA", 1)],
      word=0x7c218114,
    )
    match a {
      R32 => {
        r.check("R1", 0)
        r.check("CA", 1)
      }
      R64 => {
        r.check("R1", 0x1_0000_0000)
        r.check("CA", 0)
      }
    }
    r.check("CA32", 1)
  }
}

///|
test "addme" {
  for a in archs {
    // 7c 22 01 d4  addme r1, r2
    let r = run(
      a,
      "ADDME",
      [reg("R1"), reg("R2")],
      init=[("R2", 0xFFFF_FFFF), ("CA", 1)],
      word=0x7c2201d4,
    )
    r.check("R1", 0xFFFF_FFFF)
    // `ra + CA - 1` carries unless `ra + CA` is zero
    r.check("CA32", 1)
    r.check("CA", 1)
  }
}

///|
test "addze" {
  for a in archs {
    // 7c 22 01 94  addze r1, r2
    let r = run(
      a,
      "ADDZE",
      [reg("R1"), reg("R2")],
      init=[("R2", trunc(a, 0xFFFF_FFFF_FFFF_FFFF)), ("CA", 1)],
      word=0x7c220194,
    )
    r.check("R1", 0)
    r.check("CA32", 1)
    r.check("CA", 1)
  }
}

///|
test "add." {
  for a in archs {
    // 7d 62 5a 15  add. r11, r2, r11 (both LLVM spellings)
    for name in ["ADD4o", "ADD4_rec"] {
      let r = run(
        a,
        name,
        [reg("R11"), reg("R2"), reg("R11")],
        init=[("R2", 34), ("R11", 8)],
        word=0x7d625a15,
      )
      r.check("R11", 42)
      r.check_cr0(0, 1, 0)
    }
  }
}

///|
test "addic." {
  for a in archs {
    // 34 21 00 10  addic. r1, r1, 16
    let r = run(
      a,
      "ADDICo",
      [reg("R1"), reg("R1"), imm(16)],
      init=[("R1", trunc(a, 0xFFFF_FFFF_FFFF_FFF0))],
      word=0x34210010,
    )
    r.check("R1", 0)
    r.check("CA32", 1)
    r.check("CA", 1)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "addc." {
  for a in archs {
    // 7d 62 58 15  addc. r11, r2, r11
    let (x, y) = match a {
      R32 => (0x0FFF_FFF0UL, 0xF000_000FUL)
      R64 => (0x0FFF_FFFF_FFFF_FFF0UL, 0xF000_0000_0000_000FUL)
    }
    let r = run(
      a,
      "ADDCo",
      [reg("R11"), reg("R2"), reg("R11")],
      init=[("R2", x), ("R11", y)],
      word=0x7d625815,
    )
    r.check("R11", trunc(a, 0xFFFF_FFFF_FFFF_FFFF))
    r.check("CA32", 0)
    r.check("CA", 0)
    r.check_cr0(1, 0, 0)
  }
}

///|
test "adde." {
  for a in archs {
    // 7c 21 81 15  adde. r1, r1, r16
    let r = run(
      a,
      "ADDEo",
      [reg("R1"), reg("R1"), reg("R16")],
      init=[("R1", 0x0FFF_FFF0), ("R16", 0xF000_000E), ("CA", 1)],
      word=0x7c218115,
    )
    r.check("R1", 0xFFFF_FFFF)
    r.check("CA32", 0)
    r.check("CA", 0)
    match a {
      R32 => r.check_cr0(1, 0, 0)
      R64 => r.check_cr0(0, 1, 0)
    }
  }
}

///|
test "addme." {
  for a in archs {
    // 7c 22 01 d5  addme. r1, r2
    let r = run(
      a,
      "ADDMEo",
      [reg("R1"), reg("R2")],
      init=[("R2", 1), ("CA", 0)],
      word=0x7c2201d5,
    )
    r.check("R1", 0)
    r.check("CA32", 1)
    r.check("CA", 1)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "addze." {
  for a in archs {
    // 7c 22 01 95  addze. r1, r2
    let r = run(
      a,
      "ADDZEo",
      [reg("R1"), reg("R2")],
      init=[("R2", trunc(a, 0xFFFF_FFFF_FFFF_FFFF)), ("CA", 1)],
      word=0x7c220195,
    )
    r.check("R1", 0)
    r.check("CA32", 1)
    r.check("CA", 1)
  }
}

///|
test "add renders as BIL" {
  let bil = @powerpc.lift32(
    @mc.Insn::create(
      "ADD4",
      [reg("R11"), reg("R2"), reg("R11")],
      addr=0,
      size=4,
    ),
  )
  inspect(
    bil.map(s => s.to_string()).join("\n"),
    content=(
      #|R11:imm32 := (R2:imm32 + R11:imm32)
    ),
  )
}
