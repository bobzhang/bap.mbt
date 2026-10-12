// Ports of `lib_test/powerpc/powerpc_rotate_tests.ml` and
// `powerpc_shift_tests.ml`.

///|
fn rotl64(x : UInt64, sh : Int32) -> UInt64 {
  if sh == 0 {
    x
  } else {
    (x << sh) | (x >> (64 - sh))
  }
}

///|
/// Upstream `circ_shift32`: rotate the low word (replicated into both
/// halves on 64-bit targets).
fn circ_shift32(a : @powerpc.AddrSize, x : UInt64, sh : Int32) -> UInt64 {
  if sh == 0 {
    x
  } else {
    let w = x & 0xFFFF_FFFF
    trunc(a, rotl64((w << 32) | w, sh))
  }
}

///|
/// `MASK(start, stop)` (bits numbered from the most significant one),
/// wrapping around when `start > stop`: ones in `0..stop` and `start..63`
/// (upstream's `mask64` leaves out bits `start` and `stop`).
fn mask64(start : Int32, stop : Int32) -> UInt64 {
  let mut m = 0UL
  for i in 0..<64 {
    let set = if start <= stop {
      i >= start && i <= stop
    } else {
      i <= stop || i >= start
    }
    if set {
      m = m | (1UL << (63 - i))
    }
  }
  m
}

///|
fn mask32(a : @powerpc.AddrSize, start : Int32, stop : Int32) -> UInt64 {
  trunc(a, mask64(start + 32, stop + 32))
}

///|
let word_rotate_cases : Array[(Int32, Int32, Int32)] = [
  (3, 5, 10),
  (3, 10, 5),
  (3, 0, 5),
  (3, 5, 0),
  (3, 0, 0),
  (0, 3, 5),
]

///|
/// Upstream `M [opcode; 9; 10; sh; mb; me; rc]` (`rlw* r10, r9, ...`).
fn m_word(
  opcode : Int32,
  sh : Int32,
  mb : Int32,
  me : Int32,
  rc~ : Bool = false,
) -> UInt32 {
  enc([
    (opcode, 6),
    (9, 5),
    (10, 5),
    (sh, 5),
    (mb, 5),
    (me, 5),
    (rc.to_int(), 1),
  ])
}

///|
/// The split 6-bit mask field of the MD and MDS forms (upstream `swap_msb`).
fn swap_msb(n : Int32) -> Int32 {
  ((n & 31) << 1) | (n >> 5)
}

///|
/// Upstream `MD [30; 9; 10; sh0_4; swap_msb n; xo; sh5; rc]`.
fn md_word(xo : Int32, sh : Int32, n : Int32, rc~ : Bool = false) -> UInt32 {
  enc([
    (30, 6),
    (9, 5),
    (10, 5),
    (sh & 31, 5),
    (swap_msb(n), 6),
    (xo, 3),
    (sh >> 5, 1),
    (rc.to_int(), 1),
  ])
}

///|
/// Upstream `MDS [30; 9; 10; 11; swap_msb n; xo; rc]`.
fn mds_word(xo : Int32, n : Int32, rc~ : Bool = false) -> UInt32 {
  enc([
    (30, 6),
    (9, 5),
    (10, 5),
    (11, 5),
    (swap_msb(n), 6),
    (xo, 4),
    (rc.to_int(), 1),
  ])
}

///|
/// Upstream `X [31; 9; 10; rb; xo; rc]`.
fn shift_word(xo : Int32, rb~ : Int32 = 11, rc~ : Bool = false) -> UInt32 {
  enc([(31, 6), (9, 5), (10, 5), (rb, 5), (xo, 10), (rc.to_int(), 1)])
}

///|
/// Upstream `XS [31; 9; 10; sh0_4; 413; sh5; rc]`.
fn sradi_word(sh : Int32, rc~ : Bool = false) -> UInt32 {
  enc([
    (31, 6),
    (9, 5),
    (10, 5),
    (sh & 31, 5),
    (413, 9),
    (sh >> 5, 1),
    (rc.to_int(), 1),
  ])
}

///|
test "rlwinm, rlwnm, rlwimi" {
  for a in archs {
    let x = 0xAABBCCDDUL
    let y = trunc(a, 0xAABBCCDD_FFEEAA42)
    for case in word_rotate_cases {
      let (sh, from, to) = case
      let mask = mask32(a, from, to)
      let rotated = circ_shift32(a, x, sh)
      // 55 2a ...  rlwinm r10, r9, sh, from, to
      let r = run(
        a,
        "RLWINM",
        [
          reg("R10"),
          reg("R9"),
          imm(sh.to_int64()),
          imm(from.to_int64()),
          imm(to.to_int64()),
        ],
        init=[("R9", x)],
        word=m_word(21, sh, from, to),
      )
      r.check("R10", rotated & mask)
      // 5d 2a 19 ..  rlwnm r10, r9, r3, from, to
      let r = run(
        a,
        "RLWNM",
        [
          reg("R10"),
          reg("R9"),
          reg("R3"),
          imm(from.to_int64()),
          imm(to.to_int64()),
        ],
        init=[("R9", x), ("R3", sh.to_uint64())],
        word=m_word(23, 3, from, to),
      )
      r.check("R10", rotated & mask)
      // 51 2a ...  rlwimi r10, r9, sh, from, to
      let r = run(
        a,
        "RLWIMI",
        [
          reg("R10"),
          reg("R10"),
          reg("R9"),
          imm(sh.to_int64()),
          imm(from.to_int64()),
          imm(to.to_int64()),
        ],
        init=[("R9", x), ("R10", y)],
        word=m_word(20, sh, from, to),
      )
      r.check("R10", (rotated & mask) | (y & mask.lnot()))
    }
  }
}

///|
test "rlwinm. and friends set CR0" {
  let ops = [reg("R10"), reg("R9"), imm(0), imm(0), imm(31)]
  let word = m_word(21, 0, 0, 31, rc=true)
  run(R32, "RLWINMo", ops, init=[("R9", 0x8000_0000)], word~).check_cr0(1, 0, 0)
  run(R32, "RLWINM_rec", ops, init=[("R9", 0)], word~).check_cr0(0, 0, 1)
  let ops = [reg("R10"), reg("R9"), reg("R3"), imm(0), imm(31)]
  run(R32, "RLWNMo", ops, init=[("R9", 1)], word=m_word(23, 3, 0, 31, rc=true)).check_cr0(
    0, 1, 0,
  )
  let ops = [reg("R10"), reg("R10"), reg("R9"), imm(0), imm(0), imm(31)]
  run(R32, "RLWIMIo", ops, init=[("R9", 1)], word=m_word(20, 0, 0, 31, rc=true)).check_cr0(
    0, 1, 0,
  )
}

///|
let x_rot : UInt64 = 0xAABBCCDD_4242FFAA

///|
let dword_rotate_cases : Array[(Int32, Int32)] = [
  (4, 25),
  (4, 55),
  (4, 0),
  (0, 25),
  (0, 0),
]

///|
test "rldicl, rldicr, rldic" {
  for case in dword_rotate_cases {
    let (sh, n) = case
    let rotated = rotl64(x_rot, sh)
    let ops = [reg("X10"), reg("X9"), imm(sh.to_int64()), imm(n.to_int64())]
    run(R64, "RLDICL", ops, init=[("R9", x_rot)], word=md_word(0, sh, n)).check(
      "R10",
      rotated & mask64(n, 63),
    )
    run(R64, "RLDICR", ops, init=[("R9", x_rot)], word=md_word(1, sh, n)).check(
      "R10",
      rotated & mask64(0, n),
    )
    run(R64, "RLDIC", ops, init=[("R9", x_rot)], word=md_word(2, sh, n)).check(
      "R10",
      rotated & mask64(n, 63 - sh),
    )
  }
}

///|
test "rldcl, rldcr" {
  for case in dword_rotate_cases {
    let (sh, n) = case
    let rotated = rotl64(x_rot, sh)
    let ops = [reg("X10"), reg("X9"), reg("R11"), imm(n.to_int64())]
    let init = [("R9", x_rot), ("R11", sh.to_uint64())]
    run(R64, "RLDCL", ops, init~, word=mds_word(8, n)).check(
      "R10",
      rotated & mask64(n, 63),
    )
    run(R64, "RLDCR", ops, init~, word=mds_word(9, n)).check(
      "R10",
      rotated & mask64(0, n),
    )
  }
}

///|
test "rldimi" {
  let y = 0xFFABCDEF_FFEEAA42UL
  for case in dword_rotate_cases {
    let (sh, n) = case
    let rotated = rotl64(x_rot, sh)
    let mask = mask64(n, 63 - sh)
    let ops = [
      reg("X10"),
      reg("X10"),
      reg("X9"),
      imm(sh.to_int64()),
      imm(n.to_int64()),
    ]
    run(
      R64,
      "RLDIMI",
      ops,
      init=[("R9", x_rot), ("R10", y)],
      word=md_word(3, sh, n),
    ).check("R10", (rotated & mask) | (y & mask.lnot()))
  }
}

///|
test "rld* record forms set CR0" {
  let ops = [reg("X10"), reg("X9"), imm(0), imm(0)]
  for case in [("RLDICLo", 0), ("RLDICRo", 1), ("RLDICo", 2), ("RLDICL_rec", 0)] {
    let (name, xo) = case
    run(
      R64,
      name,
      ops,
      init=[("R9", 0x8000_0000_0000_0000)],
      word=md_word(xo, 0, 0, rc=true),
    ).check_cr0(1, 0, 0)
  }
  let ops = [reg("X10"), reg("X9"), reg("R11"), imm(0)]
  for case in [("RLDCLo", 8), ("RLDCRo", 9)] {
    let (name, xo) = case
    run(R64, name, ops, init=[("R9", 0)], word=mds_word(xo, 0, rc=true)).check_cr0(
      0, 0, 1,
    )
  }
  let ops = [reg("X10"), reg("X10"), reg("X9"), imm(0), imm(0)]
  run(R64, "RLDIMIo", ops, init=[("R9", 5)], word=md_word(3, 0, 0, rc=true)).check_cr0(
    0, 1, 0,
  )
}

///|
test "slw and srw" {
  for a in archs {
    let x = trunc(a, 0xFFEEAA42_AABBCCDD)
    for sh in [4, 0, 42] {
      let init = [("R9", x), ("R11", sh.to_uint64())]
      let ops = [reg("R10"), reg("R9"), reg("R11")]
      let (left, right) = if sh >= 32 {
        (0UL, 0UL)
      } else {
        ((x << sh) & 0xFFFF_FFFF, (x & 0xFFFF_FFFF) >> sh)
      }
      run(a, "SLW", ops, init~, word=shift_word(24)).check("R10", left)
      run(a, "SRW", ops, init~, word=shift_word(536)).check("R10", right)
    }
  }
}

///|
/// Arithmetic shift of the low word of `x`, sign-extended to the register
/// width.
fn sra32(a : @powerpc.AddrSize, x : UInt64, sh : Int32) -> UInt64 {
  let w = x.to_int()
  let shifted = if sh >= 32 { if w < 0 { -1 } else { 0 } } else { w >> sh }
  trunc(a, shifted.to_int64().reinterpret_as_uint64())
}

///|
test "srawi" {
  let cases : Array[(Int32, UInt64, UInt64)] = [
    (4, 0xFFFFFFFF_0ABBCCDD, 0),
    (4, 0xFFFFFFFF_0ABBCCD0, 0),
    (4, 0x00000000_8ABBCCD0, 0),
    (4, 0x00000000_8ABBCCDD, 1),
  ]
  for a in archs {
    for case in cases {
      let (sh, x, ca) = case
      let x = trunc(a, x)
      let r = run(
        a,
        "SRAWI",
        [reg("R10"), reg("R9"), imm(sh.to_int64())],
        init=[("R9", x)],
        word=shift_word(824, rb=sh),
      )
      r.check("R10", sra32(a, x, sh))
      r.check("CA", ca)
      r.check("CA32", ca)
    }
  }
}

///|
test "sraw" {
  let cases : Array[(Int32, UInt64, UInt64)] = [
    (4, 0xFFFFFFFF_0ABBCCDD, 0),
    (32, 0xFFFFFFFF_0ABBCCDD, 0),
    (4, 0xFFFFFFFF_8ABBCCD0, 0),
    (42, 0x00000000_80000000, 1),
    (4, 0xFFFFFFFF_8ABBCCDA, 1),
  ]
  for a in archs {
    for case in cases {
      let (sh, x, ca) = case
      let x = trunc(a, x)
      let r = run(
        a,
        "SRAW",
        [reg("R10"), reg("R9"), reg("R11")],
        init=[("R9", x), ("R11", sh.to_uint64())],
        word=shift_word(792),
      )
      r.check("R10", sra32(a, x, sh))
      r.check("CA", ca)
      r.check("CA32", ca)
    }
  }
}

///|
test "sraw. and srawi. set CR0" {
  let r = run(
    R32,
    "SRAWo",
    [reg("R10"), reg("R9"), reg("R11")],
    init=[("R9", 0x8000_0000), ("R11", 4)],
    word=shift_word(792, rc=true),
  )
  r.check_cr0(1, 0, 0)
  let r = run(
    R32,
    "SRAWIo",
    [reg("R10"), reg("R9"), imm(4)],
    init=[("R9", 0x10)],
    word=shift_word(824, rb=4, rc=true),
  )
  r.check("R10", 1)
  r.check_cr0(0, 1, 0)
}

// The doubleword shift tests are disabled upstream; these follow the lifter
// semantics.

///|
test "sld and srd" {
  let x = 0xABCDEF42_0ABBCCDDUL
  for sh in [0, 4, 42] {
    let init = [("R9", x), ("R11", sh.to_uint64())]
    let ops = [reg("X10"), reg("X9"), reg("R11")]
    run(R64, "SLD", ops, init~, word=shift_word(27)).check("R10", x << sh)
    run(R64, "SRD", ops, init~, word=shift_word(539)).check("R10", x >> sh)
    run(R64, "SLDo", ops, init~, word=shift_word(27, rc=true)).check(
      "R10",
      x << sh,
    )
    run(R64, "SRDo", ops, init~, word=shift_word(539, rc=true)).check(
      "R10",
      x >> sh,
    )
  }
}

///|
/// 64-bit arithmetic shift with the carry flag of `srad`/`sradi`.
fn sra64(x : UInt64, sh : Int32) -> (UInt64, UInt64) {
  let s = x.reinterpret_as_int64()
  let shifted = if sh >= 64 { if s < 0 { -1L } else { 0L } } else { s >> sh }
  let lost = if sh >= 64 { x } else { x & ((1UL << sh) - 1) }
  let ca : UInt64 = if s < 0 && lost != 0 { 1 } else { 0 }
  (shifted.reinterpret_as_uint64(), ca)
}

///|
test "sradi and srad" {
  let cases : Array[(Int32, UInt64)] = [
    (4, 0x8ABCDE42_AABBCCD0),
    (4, 0x8ABCDE42_AABBCCDD),
    (42, 0x8ABCDE42_AABBCCDD),
    (4, 0x0ABCDE42_AABBCCDD),
    (42, 0x0ABCDE42_AABBCCDD),
  ]
  for case in cases {
    let (sh, x) = case
    let (expected, ca) = sra64(x, sh)
    let r = run(
      R64,
      "SRADI",
      [reg("X10"), reg("X9"), imm(sh.to_int64())],
      init=[("R9", x)],
      word=sradi_word(sh),
    )
    r.check("R10", expected)
    r.check("CA", ca)
    r.check("CA32", ca)
    let r = run(
      R64,
      "SRAD",
      [reg("X10"), reg("X9"), reg("R11")],
      init=[("R9", x), ("R11", sh.to_uint64())],
      word=shift_word(794),
    )
    r.check("R10", expected)
    r.check("CA", ca)
    r.check("CA32", ca)
  }
  // shifting by 64 or more fills with the sign bit
  let (expected, ca) = sra64(0x80000000_00000000, 64)
  let r = run(
    R64,
    "SRAD",
    [reg("X10"), reg("X9"), reg("R11")],
    init=[("R9", 0x80000000_00000000), ("R11", 64)],
    word=shift_word(794),
  )
  r.check("R10", expected)
  r.check("CA", ca)
  run(
    R64,
    "SRADo",
    [reg("X10"), reg("X9"), reg("R11")],
    init=[("R9", 0x80000000_00000000), ("R11", 1)],
    word=shift_word(794, rc=true),
  ).check_cr0(1, 0, 0)
  run(
    R64,
    "SRADIo",
    [reg("X10"), reg("X9"), imm(1)],
    init=[("R9", 4)],
    word=sradi_word(1, rc=true),
  ).check_cr0(0, 1, 0)
}
