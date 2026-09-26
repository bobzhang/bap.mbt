// Ports of `lib_test/powerpc/powerpc_compare_tests.ml`,
// `powerpc_cr_tests.ml` and `powerpc_move_tests.ml`.

///|
enum Order {
  LT
  GT
  EQ
}

///|
/// Check the LT/GT/EQ bits of field `CR7` (bits 28..30).
fn check_cr7(r : Run, expected : Order) -> Unit raise {
  let (lt, gt, eq) : (UInt64, UInt64, UInt64) = match expected {
    LT => (1, 0, 0)
    GT => (0, 1, 0)
    EQ => (0, 0, 1)
  }
  r.check("CR7LT", lt)
  r.check("CR7GT", gt)
  r.check("CR7EQ", eq)
}

///|
/// Compare-immediate forms: `name cr7, r6, value` where `value` is the
/// 16-bit immediate as decoded by LLVM (sign-extended for signed forms).
fn cmpi(
  a : @powerpc.AddrSize,
  name : String,
  signed~ : Bool,
  reg_value : Int64,
  value : Int64,
  expected : Order,
) -> Unit raise {
  let field = value & 0xFFFF
  let decoded = if signed && field >= 0x8000 { field - 0x10000 } else { field }
  // upstream encoding: `opcode; 7 (3 bits); 0; l; 6; value (16 bits)`
  let (opcode, l, r6) = match name {
    "CMPWI" => (11, 0, "R6")
    "CMPLWI" => (10, 0, "R6")
    "CMPDI" => (11, 1, "X6")
    _ => (10, 1, "X6")
  }
  let word = enc([
    (opcode, 6),
    (7, 3),
    (0, 1),
    (l, 1),
    (6, 5),
    (field.to_int(), 16),
  ])
  let r = run(
    a,
    name,
    [reg("CR7"), reg(r6), imm(decoded)],
    init=[("R6", trunc(a, reg_value.reinterpret_as_uint64()))],
    word~,
  )
  check_cr7(r, expected)
}

///|
fn cmp(
  a : @powerpc.AddrSize,
  name : String,
  reg1 : Int64,
  reg2 : Int64,
  expected : Order,
) -> Unit raise {
  // upstream encoding: `31; 7 (3 bits); 0; l; 6; 7; xo (10 bits); 0`
  let (xo, l, r6, r7) = match name {
    "CMPW" => (0, 0, "R6", "R7")
    "CMPLW" => (32, 0, "R6", "R7")
    "CMPD" => (0, 1, "X6", "X7")
    _ => (32, 1, "X6", "X7")
  }
  let word = enc([
    (31, 6),
    (7, 3),
    (0, 1),
    (l, 1),
    (6, 5),
    (7, 5),
    (xo, 10),
    (0, 1),
  ])
  let r = run(
    a,
    name,
    [reg("CR7"), reg(r6), reg(r7)],
    init=[
      ("R6", trunc(a, reg1.reinterpret_as_uint64())),
      ("R7", trunc(a, reg2.reinterpret_as_uint64())),
    ],
    word~,
  )
  check_cr7(r, expected)
}

///|
test "cmpwi and cmpw" {
  let cases : Array[(Int64, Int64, Order)] = [
    (42, 44, LT),
    (44, 42, GT),
    (42, 42, EQ),
    (0x0BCDEFAB_00000042, 0x44, LT),
    (-42, -41, LT),
    (44, -42, GT),
    (-42, -42, EQ),
  ]
  for a in archs {
    for c in cases {
      let (x, y, expected) = c
      cmpi(a, "CMPWI", signed=true, x, y, expected)
      cmp(a, "CMPW", x, y, expected)
    }
  }
}

///|
test "cmplwi and cmplw" {
  let cases : Array[(Int64, Int64, Order)] = [
    (42, 44, LT),
    (44, 42, GT),
    (42, 42, EQ),
    (0x0BCDEFAB_00000042, 0x44, LT),
    (42, 0xFFFFFFFF, LT),
    (-1, 42, GT),
  ]
  for a in archs {
    for c in cases {
      let (x, y, expected) = c
      cmpi(a, "CMPLWI", signed=false, x, y, expected)
      cmp(a, "CMPLW", x, y, expected)
    }
  }
}

///|
test "cmpdi and cmpd" {
  let cases : Array[(Int64, Int64, Order)] = [
    (42, 44, LT),
    (44, 42, GT),
    (42, 42, EQ),
    (0x0BCDEFAB_00000042, 0x44, GT),
    (0xFBCDEFAB_00000042, 0x44, LT),
    (-42, -41, LT),
    (44, -42, GT),
    (-42, -42, EQ),
  ]
  for c in cases {
    let (x, y, expected) = c
    cmpi(R64, "CMPDI", signed=true, x, y, expected)
    cmp(R64, "CMPD", x, y, expected)
  }
}

///|
test "cmpldi and cmpld" {
  let cases : Array[(Int64, Int64, Order)] = [
    (42, 44, LT),
    (44, 42, GT),
    (42, 42, EQ),
    (0x0BCDEFAB_00000042, 0x44, GT),
    (0xFBCDEFAB_00000042, 0x44, GT),
    (42, 0xFFFFFFFF, LT),
    (-1, 42, GT),
  ]
  for c in cases {
    let (x, y, expected) = c
    cmpi(R64, "CMPLDI", signed=false, x, y, expected)
    cmp(R64, "CMPLD", x, y, expected)
  }
}

///|
test "compare copies SO into the field" {
  let r = run(R32, "CMPW", [reg("CR7"), reg("R6"), reg("R7")], init=[("SO", 1)])
  r.check("CR7UN", 1)
}

///|
/// `name 1, 2, 3` on CR bits (`CR0GT`, `CR0EQ`, `CR0UN`).
fn cr_logic(
  a : @powerpc.AddrSize,
  name : String,
  ba : UInt64,
  bb : UInt64,
  expected : UInt64,
) -> Unit raise {
  // upstream encoding: `XL [19; 1; 2; 3; xo; 0]`
  let xo = match name {
    "CRAND" => 257
    "CRNAND" => 225
    "CROR" => 449
    "CRXOR" => 193
    "CRNOR" => 33
    "CREQV" => 289
    "CRANDC" => 129
    _ => 417
  }
  let word = enc([(19, 6), (1, 5), (2, 5), (3, 5), (xo, 10), (0, 1)])
  let r = run(
    a,
    name,
    [reg("CR0GT"), reg("CR0EQ"), reg("CR0UN")],
    init=[("CR0EQ", ba), ("CR0UN", bb)],
    word~,
  )
  r.check("CR0GT", expected)
}

///|
test "cr logical" {
  for a in archs {
    cr_logic(a, "CRAND", 1, 1, 1)
    cr_logic(a, "CRNAND", 1, 1, 0)
    cr_logic(a, "CROR", 1, 0, 1)
    cr_logic(a, "CRXOR", 1, 1, 0)
    cr_logic(a, "CRNOR", 0, 0, 1)
    cr_logic(a, "CREQV", 1, 1, 1)
    cr_logic(a, "CRANDC", 1, 0, 1)
    cr_logic(a, "CRORC", 0, 0, 1)
    // a few more truth-table rows
    cr_logic(a, "CRAND", 1, 0, 0)
    cr_logic(a, "CRNOR", 1, 0, 0)
    cr_logic(a, "CREQV", 1, 0, 0)
    cr_logic(a, "CRANDC", 1, 1, 0)
    cr_logic(a, "CRORC", 0, 1, 0)
  }
}

///|
test "mcrf" {
  for a in archs {
    // mcrf cr1, cr3
    // XL [19; 1; 0; 3; 0; 0; 0; 0]
    let word = enc([
      (19, 6),
      (1, 3),
      (0, 2),
      (3, 3),
      (0, 2),
      (0, 5),
      (0, 10),
      (0, 1),
    ])
    let r = run(
      a,
      "MCRF",
      [reg("CR1"), reg("CR3")],
      init=[("CR3LT", 1), ("CR3GT", 0), ("CR3EQ", 1), ("CR3UN", 0)],
      word~,
    )
    r.check("CR1LT", 1)
    r.check("CR1GT", 0)
    r.check("CR1EQ", 1)
    r.check("CR1UN", 0)
  }
}

///|
/// The SPR operand as decoded by LLVM from the split 10-bit field; the
/// upstream tests encode the field value `n`, which LLVM reports as
/// `n << 5`.
fn spr_operand(n : Int64) -> @mc.Op {
  imm(n << 5)
}

///|
/// Upstream encoding `XFX [31; 1; n; xo; 0]` (the 10-bit SPR field holds
/// `n`).
fn xfx_word(n : Int, xo : Int) -> UInt {
  enc([(31, 6), (1, 5), (n, 10), (xo, 10), (0, 1)])
}

///|
test "mtspr and mfspr" {
  for a in archs {
    let x = trunc(a, 0xABCDEFAB_12345678)
    run(
      a,
      "MTSPR",
      [spr_operand(9), reg("R1")],
      init=[("R1", x)],
      word=xfx_word(9, 467),
    ).check("CTR", x)
    run(
      a,
      "MTSPR",
      [spr_operand(8), reg("R1")],
      init=[("R1", x)],
      word=xfx_word(8, 467),
    ).check("LR", x)
    run(
      a,
      "MFSPR",
      [reg("R1"), spr_operand(8)],
      init=[("LR", x)],
      word=xfx_word(8, 339),
    ).check("R1", x)
    run(
      a,
      "MFSPR",
      [reg("R1"), spr_operand(9)],
      init=[("CTR", x)],
      word=xfx_word(9, 339),
    ).check("R1", x)
    // unknown SPRs only produce a special statement
    let r = run(
      a,
      "MFSPR",
      [reg("R1"), spr_operand(1)],
      init=[("R1", 7)],
      word=xfx_word(1, 339),
    )
    r.check("R1", 7)
  }
}

///|
test "mtcrf" {
  for a in archs {
    let x = trunc(a, 0xABCDEFAB_12345678)
    // XFX [31; 1; 0; mask; 0; 144; 0]
    let word = enc([
      (31, 6),
      (1, 5),
      (0, 1),
      (0b01101001, 8),
      (0, 1),
      (144, 10),
      (0, 1),
    ])
    let r = run(
      a,
      "MTCRF",
      [imm(0b01101001), reg("R1")],
      init=[("R1", x)],
      word~,
    )
    let low = x & 0xFFFF_FFFF
    let model = @powerpc.Model::of_addr_size(a)
    for i in 0..<32 {
      let field = i / 4
      let selected = [1, 2, 4, 7].contains(field)
      let expected = if selected { (low >> (31 - i)) & 1 } else { 0 }
      r.check(model.cri[i].name, expected)
    }
  }
}

///|
test "mfcr" {
  for a in archs {
    let x = 0x12345678UL
    let model = @powerpc.Model::of_addr_size(a)
    let init = []
    for i in 0..<32 {
      init.push((model.cri[i].name, (x >> (31 - i)) & 1))
    }
    // XFX [31; 1; 0; 0; 0; 19; 0]
    let word = enc([(31, 6), (1, 5), (0, 1), (0, 8), (0, 1), (19, 10), (0, 1)])
    run(a, "MFCR", [reg("R1")], init~, word~).check("R1", x)
  }
}

///|
test "mtctr, mtlr, mfctr, mflr" {
  for a in archs {
    let x = trunc(a, 0xABCDEFAB_12345678)
    run(a, "MTCTR", [reg("R0")], init=[("R0", x)], word=0x7c0903a6).check(
      "CTR", x,
    )
    run(a, "MTLR", [reg("R0")], init=[("R0", x)], word=0x7c0803a6).check(
      "LR", x,
    )
    run(a, "MFCTR", [reg("R0")], init=[("CTR", x)], word=0x7c0902a6).check(
      "R0", x,
    )
    run(a, "MFLR", [reg("R0")], init=[("LR", x)], word=0x7c0802a6).check(
      "R0", x,
    )
  }
}
