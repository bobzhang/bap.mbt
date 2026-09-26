// Port of `lib_test/powerpc/powerpc_arith_tests.ml` (neg, sub, mul, div,
// mod). Expected values are computed with host integer arithmetic.

///|
fn low32(x : UInt64) -> UInt64 {
  x & 0xFFFF_FFFFUL
}

///|
/// Low word of `x` as a signed value.
fn slow32(x : UInt64) -> Int64 {
  x.to_int().to_int64()
}

///|
/// `v` (a signed word-sized result) sign-extended to the register width.
fn sext32(a : @powerpc.AddrSize, v : Int64) -> UInt64 {
  trunc(a, v.to_int().to_int64().reinterpret_as_uint64())
}

///|
/// Upstream encoding `XO [31; 1; 2; rb; 0; xo; rc]` of `rt=r1, ra=r2, rb`.
fn xo_word(xo : Int, rb? : Int = 3, rc? : Bool = false) -> UInt {
  enc([(31, 6), (1, 5), (2, 5), (rb, 5), (0, 1), (xo, 9), (rc.to_int(), 1)])
}

///|
/// The upstream encoding of `name r1, r2, r3` and whether its registers are
/// 64-bit (`X`) ones.
fn r123_word(name : String) -> (UInt, Bool) {
  let (base, rc) = match name.strip_suffix("o") {
    Some(base) => (base.to_owned(), true)
    None => (name, false)
  }
  let (xo, wide) = match base {
    "MULLW" => (235, false)
    "DIVW" => (491, false)
    "DIVWU" => (459, false)
    "DIVWE" => (427, false)
    "DIVWEU" => (395, false)
    "MULLD" => (233, true)
    "MULHD" => (73, true)
    "MULHDU" => (9, true)
    "DIVD" => (489, true)
    "DIVDU" => (457, true)
    "DIVDE" => (425, true)
    "DIVDEU" => (393, true)
    // X-form modulo instructions: `X [31; 1; 2; 3; xo; 0]`
    "MODSW" =>
      return (enc([(31, 6), (1, 5), (2, 5), (3, 5), (779, 10), (0, 1)]), false)
    "MODUW" =>
      return (enc([(31, 6), (1, 5), (2, 5), (3, 5), (267, 10), (0, 1)]), false)
    "MODSD" =>
      return (enc([(31, 6), (1, 5), (2, 5), (3, 5), (777, 10), (0, 1)]), true)
    "MODUD" =>
      return (enc([(31, 6), (1, 5), (2, 5), (3, 5), (265, 10), (0, 1)]), true)
    _ => abort("no encoding for \{name}")
  }
  (xo_word(xo, rc~), wide)
}

///|
/// `name r1, r2, r3` decoded from its upstream encoding and evaluated with
/// `r2 = x`, `r3 = y`; the value of `r1`.
fn r123(
  a : @powerpc.AddrSize,
  name : String,
  x : UInt64,
  y : UInt64,
) -> UInt64 raise {
  let (word, wide) = r123_word(name)
  let ops = if wide {
    [reg("X1"), reg("X2"), reg("X3")]
  } else {
    [reg("R1"), reg("R2"), reg("R3")]
  }
  run(a, name, ops, init=[("R2", trunc(a, x)), ("R3", trunc(a, y))], word~).get(
    "R1",
  )
}

///|
test "neg" {
  for a in archs {
    let x = match a {
      R32 => 0x8000_0000UL
      R64 => 0x8000_0000_0000_0000UL
    }
    run(
      a,
      "NEG",
      [reg("R1"), reg("R2")],
      init=[("R2", x)],
      word=xo_word(104, rb=0),
    ).check("R1", x)
    run(
      a,
      "NEGo",
      [reg("R1"), reg("R2")],
      init=[("R2", 5)],
      word=xo_word(104, rb=0, rc=true),
    ).check_cr0(1, 0, 0)
  }
}

///|
test "subf" {
  for a in archs {
    let x = match a {
      R32 => 12345678UL
      R64 => 0xABCD_EF42_1234_5678UL
    }
    let r = run(
      a,
      "SUBF",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", x), ("R2", 0x42)],
      word=xo_word(40),
    )
    r.check("R1", trunc(a, x - 0x42))
    let r = run(
      a,
      "SUBFo",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", 1), ("R2", 2)],
      word=xo_word(40, rc=true),
    )
    r.check("R1", trunc(a, 0UL - 1))
    r.check_cr0(1, 0, 0)
  }
}

///|
test "subfic" {
  for a in archs {
    // subfic r1, r2, 42
    let r = run(
      a,
      "SUBFIC",
      [reg("R1"), reg("R2"), imm(42)],
      init=[("R2", 43)],
      word=enc([(8, 6), (1, 5), (2, 5), (42, 16)]),
    )
    r.check("R1", trunc(a, 42UL - 43))
    r.check("CA", 1)
    r.check("CA32", 1)
  }
}

///|
test "subfc" {
  for a in archs {
    let x = trunc(a, 0xABCD_EF42_1234_5678)
    let r = run(
      a,
      "SUBFC",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", x), ("R2", 0x42)],
      word=xo_word(8),
    )
    r.check("R1", trunc(a, x - 0x42))
    // rb < ra
    r.check("CA", 0)
    r.check("CA32", 0)
    let r = run(
      a,
      "SUBFCo",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", 1), ("R2", 2)],
      word=xo_word(8, rc=true),
    )
    r.check("CA", 1)
    r.check_cr0(1, 0, 0)
  }
}

///|
test "subfe" {
  for a in archs {
    let x = trunc(a, 0xABCD_EF42_1234_5678)
    let y = 0x42UL
    let r = run(
      a,
      "SUBFE",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", x), ("R2", y), ("CA", 1)],
      word=xo_word(136),
    )
    r.check("R1", trunc(a, y.lnot() + x + 1))
    let r = run(
      a,
      "SUBFEo",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R3", 7), ("R2", 7), ("CA", 1)],
      word=xo_word(136, rc=true),
    )
    r.check("R1", 0)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "subfme and subfze" {
  for a in archs {
    let x = trunc(a, 0xABCD_EF42_1234_5678)
    let r = run(
      a,
      "SUBFME",
      [reg("R1"), reg("R2")],
      init=[("R2", x), ("CA", 1)],
      word=xo_word(232, rb=0),
    )
    r.check("R1", trunc(a, x.lnot()))
    r.check("CA", 1)
    r.check("CA32", 1)
    let r = run(
      a,
      "SUBFZE",
      [reg("R1"), reg("R2")],
      init=[("R2", x), ("CA", 1)],
      word=xo_word(200, rb=0),
    )
    r.check("R1", trunc(a, x.lnot() + 1))
    r.check("CA", 1)
    let r = run(
      a,
      "SUBFMEo",
      [reg("R1"), reg("R2")],
      init=[("R2", 0), ("CA", 1)],
      word=xo_word(232, rb=0, rc=true),
    )
    r.check("R1", trunc(a, 0xFFFF_FFFF_FFFF_FFFF))
    r.check_cr0(1, 0, 0)
    let r = run(
      a,
      "SUBFZEo",
      [reg("R1"), reg("R2")],
      init=[("R2", 0), ("CA", 1)],
      word=xo_word(200, rb=0, rc=true),
    )
    r.check("R1", 0)
    r.check_cr0(0, 0, 1)
  }
}

///|
test "mulli" {
  for a in archs {
    let x = trunc(a, 0xABCD_EFAA_BBCD_EDAA)
    let y = 0x1FFFL
    let r = run(
      a,
      "MULLI",
      [reg("R1"), reg("R2"), imm(y)],
      init=[("R2", x)],
      word=enc([(7, 6), (1, 5), (2, 5), (y.to_int(), 16)]),
    )
    r.check("R1", trunc(a, x * y.reinterpret_as_uint64()))
  }
}

///|
test "mulhw" {
  for a in archs {
    let y = 0x4242UL
    let z = 0xFFFF_FFFF_ABCD_EFAAUL
    let r = run(
      a,
      "MULHW",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[
        ("R1", trunc(a, 0xABCD_EFAA_BBCD_EDAA)),
        ("R2", trunc(a, y)),
        ("R3", trunc(a, z)),
      ],
      word=xo_word(75),
    )
    let product = slow32(y) * slow32(z)
    r.check("R1", sext32(a, product >> 32))
    let r = run(
      a,
      "MULHWo",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R2", trunc(a, y)), ("R3", trunc(a, z))],
      word=xo_word(75, rc=true),
    )
    r.check_cr0(1, 0, 0)
  }
}

///|
test "mulhwu" {
  for a in archs {
    let y = 0x4242UL
    let z = 0xABCD_EFAAUL
    let r = run(
      a,
      "MULHWU",
      [reg("R1"), reg("R2"), reg("R3")],
      init=[("R1", trunc(a, 0xABCD_EFAA_BBCD_EDAA)), ("R2", y), ("R3", z)],
      word=xo_word(11),
    )
    r.check("R1", (y * z) >> 32)
  }
}

///|
test "mullw" {
  for a in archs {
    let x = 0xABCD_EFAA_BBCD_EDAAUL
    let y = 0x1234_5678_4242_4242UL
    let expected = trunc(a, low32(x) * low32(y))
    assert_eq(r123(a, "MULLW", x, y), expected)
    assert_eq(r123(a, "MULLWo", x, y), expected)
  }
}

///|
test "divw" {
  for a in archs {
    let x = 0xABCD_EFAA_8888_8888UL
    let y = 0x1234_5678_4444_4444UL
    assert_eq(r123(a, "DIVW", x, y), sext32(a, slow32(x) / slow32(y)))
    assert_eq(r123(a, "DIVWo", x, y), sext32(a, slow32(x) / slow32(y)))
  }
}

///|
test "divwu" {
  for a in archs {
    let x = 0xABCD_EFAA_8888_8888UL
    let y = 0x1234_5678_4444_4444UL
    assert_eq(r123(a, "DIVWU", x, y), low32(x) / low32(y))
    assert_eq(r123(a, "DIVWUo", x, y), low32(x) / low32(y))
  }
}

///|
test "divwe" {
  for a in archs {
    let x = 0xABCD_EFAA_8888_8888UL
    let y = 0x1234_5678_4444_4444UL
    let dividend = (low32(x) << 32).reinterpret_as_int64()
    let expected = sext32(a, dividend / slow32(y))
    assert_eq(r123(a, "DIVWE", x, y), expected)
    assert_eq(r123(a, "DIVWEo", x, y), expected)
  }
}

///|
test "divweu" {
  for a in archs {
    let x = 0xABCD_EFAA_8888_8888UL
    let y = 0x1234_5678_4444_4444UL
    let expected = low32((low32(x) << 32) / low32(y))
    assert_eq(r123(a, "DIVWEU", x, y), expected)
    assert_eq(r123(a, "DIVWEUo", x, y), expected)
  }
}

///|
test "modsw and moduw" {
  for a in archs {
    let x = 0xABCD_EFAB_CDEF_ABCDUL
    let y = 0x1234_5678_9123_4567UL
    assert_eq(r123(a, "MODSW", x, y), sext32(a, slow32(x) % slow32(y)))
    assert_eq(r123(a, "MODUW", x, y), low32(x) % low32(y))
  }
}

///|
let x64 : UInt64 = 0xABCD_EFAB_CDEF_ABCD

///|
let y64 : UInt64 = 0x1234_5678_9123_4567

///|
test "mulld" {
  assert_eq(r123(R64, "MULLD", x64, y64), x64 * y64)
  let r = run(
    R64,
    "MULLDo",
    [reg("X1"), reg("X2"), reg("X3")],
    init=[("R2", x64), ("R3", y64)],
    word=xo_word(233, rc=true),
  )
  r.check("R1", x64 * y64)
}

///|
/// High doubleword of the 128-bit product of `x` and `y`.
fn mul_high(x : UInt64, y : UInt64, signed~ : Bool) -> UInt64 raise {
  let widen = (v : UInt64) => {
    let w = word_of(64, v)
    (if signed { w.signed() } else { w }).extract(hi=127, lo=0)
  }
  widen(x).mul(widen(y)).extract(hi=127, lo=64).to_uint64()
}

///|
test "mulhd and mulhdu" {
  assert_eq(r123(R64, "MULHD", x64, y64), mul_high(x64, y64, signed=true))
  assert_eq(r123(R64, "MULHDo", x64, y64), mul_high(x64, y64, signed=true))
  assert_eq(r123(R64, "MULHDU", x64, y64), mul_high(x64, y64, signed=false))
  assert_eq(r123(R64, "MULHDUo", x64, y64), mul_high(x64, y64, signed=false))
}

///|
test "divd and divdu" {
  let sx = x64.reinterpret_as_int64()
  let sy = y64.reinterpret_as_int64()
  assert_eq(r123(R64, "DIVD", x64, y64), (sx / sy).reinterpret_as_uint64())
  assert_eq(r123(R64, "DIVDo", x64, y64), (sx / sy).reinterpret_as_uint64())
  assert_eq(r123(R64, "DIVDU", x64, y64), x64 / y64)
  assert_eq(r123(R64, "DIVDUo", x64, y64), x64 / y64)
}

///|
/// Low doubleword of `(x << 64) / y` computed on 128-bit words.
fn div_extended(x : UInt64, y : UInt64, signed~ : Bool) -> UInt64 raise {
  let dividend = word_of(64, x).concat(word_of(64, 0))
  let divisor = word_of(64, y).extract(hi=127, lo=0)
  let q = if signed {
    dividend.signed().signed_div(divisor.signed())
  } else {
    dividend.div(divisor)
  }
  q.extract(hi=63, lo=0).to_uint64()
}

///|
test "divde and divdeu" {
  assert_eq(r123(R64, "DIVDE", x64, y64), div_extended(x64, y64, signed=true))
  assert_eq(r123(R64, "DIVDEo", x64, y64), div_extended(x64, y64, signed=true))
  assert_eq(r123(R64, "DIVDEU", x64, y64), div_extended(x64, y64, signed=false))
  assert_eq(
    r123(R64, "DIVDEUo", x64, y64),
    div_extended(x64, y64, signed=false),
  )
}

///|
test "modsd and modud" {
  let sx = x64.reinterpret_as_int64()
  let sy = y64.reinterpret_as_int64()
  assert_eq(r123(R64, "MODSD", x64, y64), (sx % sy).reinterpret_as_uint64())
  assert_eq(r123(R64, "MODUD", x64, y64), x64 % y64)
}
