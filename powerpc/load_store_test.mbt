// Ports of `lib_test/powerpc/powerpc_load_tests.ml` and
// `powerpc_store_tests.ml`.

///|
/// `value` truncated to `size` bytes.
fn bytes_of(value : UInt64, size : Int) -> UInt64 {
  if size >= 8 {
    value
  } else {
    value & ((1UL << (size * 8)) - 1)
  }
}

///|
/// The low `size` bytes of `value` in reverse order.
fn byte_reverse(value : UInt64, size : Int) -> UInt64 {
  let mut acc = 0UL
  for i in 0..<size {
    acc = (acc << 8) | ((value >> (8 * i)) & 0xFF)
  }
  acc
}

///|
let all_ones : UInt64 = 0xFFFF_FFFF_FFFF_FFFF

///|
test "lbz, lhz, lwz" {
  for a in archs {
    for case in [("LBZ", 1, 0x42UL), ("LHZ", 2, 0x4242), ("LWZ", 4, 0xAAAA4242)] {
      let (name, size, value) = case
      for d in [20, -16] {
        // lz r9, d(r28)
        let base = 0xABCDEF00UL
        let ea = trunc(a, base + d.to_int64().reinterpret_as_uint64())
        let r = run(
          a,
          name,
          [reg("R9"), imm(d.to_int64()), reg("R28")],
          init=[("R28", base), ("R9", trunc(a, all_ones))],
          mem=[(ea, value, size)],
        )
        r.check("R9", value)
      }
      // lz r9, 20(0)
      let r = run(
        a,
        name,
        [reg("R9"), imm(20), reg("ZERO")],
        init=[("R9", trunc(a, all_ones))],
        mem=[(20, value, size)],
      )
      r.check("R9", value)
    }
  }
}

///|
test "lbzx, lhzx, lwzx" {
  for a in archs {
    for
      case in [
        ("LBZX", 1, 0x42UL),
        ("LHZX", 2, 0x4242),
        ("LWZX", 4, 0xAAAA4242),
      ] {
      let (name, size, value) = case
      // lzx r9, r29, r10
      let r = run(
        a,
        name,
        [reg("R9"), reg("R29"), reg("R10")],
        init=[("R29", 0xABCD0000), ("R10", 0xFF42), ("R9", trunc(a, all_ones))],
        mem=[(0xABCDFF42, value, size)],
      )
      r.check("R9", value)
      // lzx r9, 0, r10
      let r = run(
        a,
        name,
        [reg("R9"), reg("ZERO"), reg("R10")],
        init=[("R10", 0xABCD0000), ("R9", trunc(a, all_ones))],
        mem=[(0xABCD0000, value, size)],
      )
      r.check("R9", value)
    }
  }
}

///|
test "lbzu, lhzu, lwzu" {
  for a in archs {
    for
      case in [
        ("LBZU", 1, 0x42UL),
        ("LHZU", 2, 0x4242),
        ("LWZU", 4, 0xAAAA4242),
      ] {
      let (name, size, value) = case
      for d in [20, -16] {
        // lzu r9, d(r28)
        let base = 0xABCDEF04UL
        let ea = trunc(a, base + d.to_int64().reinterpret_as_uint64())
        let r = run(
          a,
          name,
          [reg("R9"), reg("R28"), imm(d.to_int64()), reg("R28")],
          init=[("R28", base), ("R9", trunc(a, all_ones))],
          mem=[(ea, value, size)],
        )
        r.check("R9", value)
        r.check("R28", ea)
      }
    }
  }
}

///|
test "lbzux, lhzux, lwzux" {
  for a in archs {
    for
      case in [
        ("LBZUX", 1, 0x42UL),
        ("LHZUX", 2, 0x4242),
        ("LWZUX", 4, 0xAAAA4242),
      ] {
      let (name, size, value) = case
      // lzux r9, r29, r10
      let r = run(
        a,
        name,
        [reg("R9"), reg("R29"), reg("R29"), reg("R10")],
        init=[("R29", 0xABCD0000), ("R10", 0xEF42), ("R9", trunc(a, all_ones))],
        mem=[(0xABCDEF42, value, size)],
      )
      r.check("R9", value)
      r.check("R29", 0xABCDEF42)
    }
  }
}

///|
test "lha, lhax, lhau, lhaux" {
  for a in archs {
    let addr = 0x00ABCDEFUL
    // a8 29 00 05  lha r1, 5(r9)
    let r = run(a, "LHA", [reg("R1"), imm(5), reg("R9")], init=[("R9", addr)], mem=[
      (addr + 5, 0xFFAB, 2),
    ])
    r.check("R1", trunc(a, 0xFFFF_FFFF_FFFF_FFAB))
    // 7c 25 4a ae  lhax r1, r5, r9
    let r = run(
      a,
      "LHAX",
      [reg("R1"), reg("R5"), reg("R9")],
      init=[("R5", 5), ("R9", addr)],
      mem=[(addr + 5, 0xFFAB, 2)],
    )
    r.check("R1", trunc(a, 0xFFFF_FFFF_FFFF_FFAB))
    // ac 29 00 05  lhau r1, 5(r9)
    let r = run(
      a,
      "LHAU",
      [reg("R1"), reg("R9"), imm(5), reg("R9")],
      init=[("R9", addr)],
      mem=[(addr + 5, 0xFFAB, 2)],
    )
    r.check("R1", trunc(a, 0xFFFF_FFFF_FFFF_FFAB))
    r.check("R9", addr + 5)
    // 7c 25 4a ee  lhaux r1, r5, r9
    let r = run(
      a,
      "LHAUX",
      [reg("R1"), reg("R5"), reg("R5"), reg("R9")],
      init=[("R5", 5), ("R9", addr)],
      mem=[(addr + 5, 0x0FAB, 2)],
    )
    r.check("R1", 0xFAB)
    r.check("R5", addr + 5)
  }
}

///|
test "lwa, lwax, lwaux" {
  for a in archs {
    let addr = 0x00ABCDEFUL
    // eb eb 01 16  lwa r31, 276(r11)
    let r = run(
      a,
      "LWA",
      [reg("R31"), imm(276), reg("R11")],
      init=[("R11", addr)],
      mem=[(addr + 276, 0xFFACFFAB, 4)],
    )
    r.check("R31", trunc(a, 0xFFFF_FFFF_FFAC_FFAB))
    // 7c 25 4a aa  lwax r1, r5, r9
    let r = run(
      a,
      "LWAX",
      [reg("R1"), reg("R5"), reg("R9")],
      init=[("R5", 5), ("R9", addr)],
      mem=[(addr + 5, 0x0FACFFAB, 4)],
    )
    r.check("R1", 0x0FACFFAB)
    // 7c 25 4a ea  lwaux r1, r5, r9
    let r = run(
      a,
      "LWAUX",
      [reg("R1"), reg("R5"), reg("R5"), reg("R9")],
      init=[("R5", 5), ("R9", addr)],
      mem=[(addr + 5, 0xFFACFFAB, 4)],
    )
    r.check("R1", trunc(a, 0xFFFF_FFFF_FFAC_FFAB))
    r.check("R5", addr + 5)
  }
}

///|
test "ld, ldx, ldu, ldux" {
  let addr = 0x00ABCDEFUL
  let data = 0xFFACBBDD_FFACFFABUL
  // e8 29 00 08  ld r1, 8(r9)
  let r = run(R64, "LD", [reg("X1"), imm(8), reg("X9")], init=[("R9", addr)], mem=[
    (addr + 8, data, 8),
  ])
  r.check("R1", data)
  // 7c 28 48 2a  ldx r1, r8, r9
  let r = run(
    R64,
    "LDX",
    [reg("X1"), reg("X8"), reg("X9")],
    init=[("R9", addr), ("R8", 5)],
    mem=[(addr + 5, data, 8)],
  )
  r.check("R1", data)
  // e8 29 00 09  ldu r1, 8(r9)
  let r = run(
    R64,
    "LDU",
    [reg("X1"), reg("X9"), imm(8), reg("X9")],
    init=[("R9", addr)],
    mem=[(addr + 8, data, 8)],
  )
  r.check("R1", data)
  r.check("R9", addr + 8)
  // 7c 28 48 6a  ldux r1, r8, r9
  let r = run(
    R64,
    "LDUX",
    [reg("X1"), reg("X8"), reg("X8"), reg("X9")],
    init=[("R9", addr), ("R8", 5)],
    mem=[(addr + 5, data, 8)],
  )
  r.check("R1", data)
  r.check("R8", addr + 5)
  // the same with a full 64-bit address
  let big = 0xCDEF4234_CDABCDEFUL
  let r = run(
    R64,
    "LDUX",
    [reg("X1"), reg("X8"), reg("X8"), reg("X9")],
    init=[("R9", big), ("R8", 5)],
    mem=[(big + 5, data, 8)],
  )
  r.check("R1", data)
  r.check("R8", big + 5)
}

///|
test "lhbrx, lwbrx, ldbrx" {
  let data = 0xABCDEFAB_CCDDEEFFUL
  let cases : Array[(@powerpc.AddrSize, String, Int)] = [
    (R32, "LHBRX", 2),
    (R32, "LWBRX", 4),
    (R64, "LHBRX", 2),
    (R64, "LWBRX", 4),
    (R64, "LDBRX", 8),
  ]
  for case in cases {
    let (a, name, size) = case
    let r = run(
      a,
      name,
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R2", 0xABCDEF00), ("R3", 0x42)],
      mem=[(0xABCDEF42, bytes_of(data, size), size)],
    )
    r.check("R1", byte_reverse(data, size))
  }
}

///|
let store_data : UInt64 = 0xFFFFFFFF_ABCDEF42

///|
test "stb, sth, stw" {
  for a in archs {
    for case in [("STB", 1), ("STH", 2), ("STW", 4)] {
      let (name, size) = case
      for d in [16, -16] {
        // st r9, d(r28)
        let base = 0xABCDEF00UL
        let ea = trunc(a, base + d.to_int64().reinterpret_as_uint64())
        let r = run(a, name, [reg("R9"), imm(d.to_int64()), reg("R28")], init=[
          ("R9", trunc(a, store_data)),
          ("R28", base),
        ])
        r.check_mem(a, ea, size, bytes_of(store_data, size))
      }
      // st r9, 16(0)
      let r = run(a, name, [reg("R9"), imm(16), reg("ZERO")], init=[
        ("R9", trunc(a, store_data)),
      ])
      r.check_mem(a, 16, size, bytes_of(store_data, size))
    }
  }
}

///|
test "stbx, sthx, stwx" {
  for a in archs {
    for case in [("STBX", 1), ("STHX", 2), ("STWX", 4)] {
      let (name, size) = case
      // stx r9, r14, r31
      let r = run(a, name, [reg("R9"), reg("R14"), reg("R31")], init=[
        ("R9", trunc(a, store_data)),
        ("R14", 0xABCD0000),
        ("R31", 0xEF42),
      ])
      r.check_mem(a, 0xABCDEF42, size, bytes_of(store_data, size))
      // stx r9, 0, r31
      let r = run(a, name, [reg("R9"), reg("ZERO"), reg("R31")], init=[
        ("R9", trunc(a, store_data)),
        ("R31", 0xABCD0000),
      ])
      r.check_mem(a, 0xABCD0000, size, bytes_of(store_data, size))
    }
  }
}

///|
test "stbu, sthu, stwu" {
  for a in archs {
    for case in [("STBU", 1), ("STHU", 2), ("STWU", 4)] {
      let (name, size) = case
      for d in [16, -16] {
        // stu r4, d(r29)
        let base = 0xABCDEF01UL
        let ea = trunc(a, base + d.to_int64().reinterpret_as_uint64())
        let r = run(
          a,
          name,
          [reg("R29"), reg("R4"), imm(d.to_int64()), reg("R29")],
          init=[("R4", trunc(a, store_data)), ("R29", base)],
        )
        r.check_mem(a, ea, size, bytes_of(store_data, size))
        r.check("R29", ea)
      }
    }
  }
}

///|
test "stbux, sthux, stwux" {
  for a in archs {
    for case in [("STBUX", 1), ("STHUX", 2), ("STWUX", 4)] {
      let (name, size) = case
      // stux r9, r31, r25
      let r = run(a, name, [reg("R31"), reg("R9"), reg("R31"), reg("R25")], init=[
        ("R31", 0xABCD0000),
        ("R25", 0xEF42),
        ("R9", trunc(a, store_data)),
      ])
      r.check_mem(a, 0xABCDEF42, size, bytes_of(store_data, size))
      r.check("R31", 0xABCDEF42)
    }
  }
}

///|
test "std, stdx, stdu, stdux" {
  let data = 0xCCABDD42_ABCDEF42UL
  // f8 29 00 08  std r1, 8(r9)
  let r = run(R64, "STD", [reg("X1"), imm(8), reg("X9")], init=[
    ("R9", 0xABCDEF44),
    ("R1", data),
  ])
  r.check_mem(R64, 0xABCDEF4C, 8, data)
  // 7c 28 49 2a  stdx r1, r8, r9
  let r = run(R64, "STDX", [reg("X1"), reg("X8"), reg("X9")], init=[
    ("R1", data),
    ("R8", 0xABCD0000),
    ("R9", 0xEF42),
  ])
  r.check_mem(R64, 0xABCDEF42, 8, data)
  // f8 29 00 09  stdu r1, 8(r9)
  let r = run(R64, "STDU", [reg("X9"), reg("X1"), imm(8), reg("X9")], init=[
    ("R9", 0xABCDEF42),
    ("R1", data),
  ])
  r.check_mem(R64, 0xABCDEF4A, 8, data)
  r.check("R9", 0xABCDEF4A)
  // 7c 28 49 6a  stdux r1, r8, r9
  let r = run(R64, "STDUX", [reg("X8"), reg("X1"), reg("X8"), reg("X9")], init=[
    ("R1", data),
    ("R8", 0xABCD0000),
    ("R9", 0xEF42),
  ])
  r.check_mem(R64, 0xABCDEF42, 8, data)
  r.check("R8", 0xABCDEF42)
  // with a full 64-bit address
  let x = 0xCABCEF42_ABCD0000UL
  let r = run(R64, "STDUX", [reg("X8"), reg("X1"), reg("X8"), reg("X9")], init=[
    ("R1", data),
    ("R8", x),
    ("R9", 0xEF42),
  ])
  r.check_mem(R64, x + 0xEF42, 8, data)
  r.check("R8", x + 0xEF42)
}

///|
test "sthbrx, stwbrx, stdbrx" {
  let data = 0xCCABDD42_ABCDEF42UL
  let cases : Array[(@powerpc.AddrSize, String, Int)] = [
    (R32, "STHBRX", 2),
    (R32, "STWBRX", 4),
    (R64, "STHBRX", 2),
    (R64, "STWBRX", 4),
    (R64, "STDBRX", 8),
  ]
  for case in cases {
    let (a, name, size) = case
    let r = run(a, name, [reg("R1"), reg("R2"), reg("R3")], init=[
      ("R1", trunc(a, data)),
      ("R2", 0xABCDEF00),
      ("R3", 0x42),
    ])
    r.check_mem(a, 0xABCDEF42, size, byte_reverse(data, size))
  }
}
