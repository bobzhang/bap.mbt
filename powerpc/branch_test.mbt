// Port of `lib_test/powerpc/powerpc_branch_tests.ml`.

///|
fn branch_addr(a : @powerpc.AddrSize) -> UInt64 {
  match a {
    R32 => 0xABCD_42AA
    R64 => 0x0AAA_AAAA_0000_0042
  }
}

///|
/// `offs << 2` in the address width.
fn disp(a : @powerpc.AddrSize, offs : Int) -> UInt64 {
  trunc(a, (offs.to_int64() << 2).reinterpret_as_uint64())
}

///|
test "b, ba, bl, bla" {
  for a in archs {
    let addr = branch_addr(a)
    for offs in [42, -42] {
      for
        case in [
          ("B", false, false),
          ("BA", true, false),
          ("BL", false, true),
          ("BLA", true, true),
        ] {
        let (name, aa, lk) = case
        let word = enc([(18, 6), (offs, 24), (aa.to_int(), 1), (lk.to_int(), 1)])
        let r = run(a, name, [imm(offs.to_int64())], addr~, word~)
        let expected = if aa {
          disp(a, offs)
        } else {
          trunc(a, addr + disp(a, offs))
        }
        r.check_jump(Some(expected))
        if lk {
          r.check("LR", trunc(a, addr + 4))
        } else {
          r.check("LR", 0)
        }
      }
    }
  }
}

///|
/// A BO-field scenario of the upstream tests.
struct BoCase {
  bo : Int
  ctr_before : UInt64
  ctr_after : UInt64?
  cond_reg0 : UInt64
  expect_jump : Bool
}

///|
fn bo_case(
  bo : Int,
  ctr_before? : UInt64 = 0,
  ctr_after? : UInt64,
  cond_reg0? : UInt64 = 0,
  expect_jump? : Bool = false,
) -> BoCase {
  { bo, ctr_before, ctr_after, cond_reg0, expect_jump, }
}

///|
let counter_unchanged : BoCase = bo_case(
  0b00100,
  ctr_before=42,
  cond_reg0=1,
  ctr_after=42,
)

///|
let counter_decremented : BoCase = bo_case(
  0b00000,
  ctr_before=42,
  cond_reg0=1,
  ctr_after=41,
)

///|
let jmp_anyway : BoCase = bo_case(0b10100, expect_jump=true)

///|
/// cond: bo3 = CR0 = 1; ctr: bo1 = 1 and ctr = 0
let cond_ctr_ok_1 : BoCase = bo_case(
  0b01010,
  ctr_before=1,
  cond_reg0=1,
  expect_jump=true,
)

///|
/// cond: bo3 = CR0 = 0; ctr: bo1 = 0 and ctr <> 0
let cond_ctr_ok_2 : BoCase = bo_case(
  0b00000,
  ctr_before=42,
  cond_reg0=0,
  expect_jump=true,
)

///|
/// cond: bo3 = CR0 = 1; ctr: bo1 = 0 and ctr <> 0
let cond_ctr_ok_3 : BoCase = bo_case(
  0b01000,
  ctr_before=42,
  cond_reg0=1,
  expect_jump=true,
)

///|
/// cond: bo3 = CR0 = 0; ctr: bo1 = 1 and ctr = 0
let cond_ctr_ok_4 : BoCase = bo_case(
  0b00010,
  ctr_before=1,
  cond_reg0=0,
  expect_jump=true,
)

///|
/// cond: bo3 = CR0 = 0; ctr: bo1 = 1 and ctr <> 0
let cond_ok_ctr_not_1 : BoCase = bo_case(0b00010, ctr_before=42, cond_reg0=0)

///|
/// cond: bo3 = 1; CR0 = 0; ctr: bo1 = 1 and ctr <> 0
let cond_not_ctr_ok_1 : BoCase = bo_case(0b01010, ctr_before=42, cond_reg0=0)

///|
/// cond: bo3 = CR0 = 0
let cond_ok : BoCase = bo_case(0b00010, cond_reg0=0, expect_jump=true)

///|
/// cond: bo3 = 1; CR0 = 0
let cond_not : BoCase = bo_case(0b01010, cond_reg0=0)

///|
let bc_cases : Array[BoCase] = [
  counter_unchanged, counter_decremented, jmp_anyway, cond_ctr_ok_1, cond_ctr_ok_2,
  cond_ctr_ok_3, cond_ctr_ok_4, cond_ok_ctr_not_1, cond_not_ctr_ok_1,
]

///|
/// `gBC`/`gBCA`/`gBCL`/`gBCLA` with `bi = 0` (`CR0LT`).
test "bc, bca, bcl, bcla" {
  for a in archs {
    let addr = branch_addr(a)
    for
      case in [
        ("gBC", false, false),
        ("gBCA", true, false),
        ("gBCL", false, true),
        ("gBCLA", true, true),
      ] {
      let (name, aa, lk) = case
      for c in bc_cases {
        for offs in [42, -42] {
          let word = enc([
            (16, 6),
            (c.bo, 5),
            (0, 5),
            (offs, 14),
            (aa.to_int(), 1),
            (lk.to_int(), 1),
          ])
          let r = run(
            a,
            name,
            [imm(c.bo.to_int64()), reg("CR0LT"), imm(offs.to_int64())],
            init=[("CR0LT", c.cond_reg0), ("CTR", c.ctr_before)],
            addr~,
            word~,
          )
          if c.expect_jump {
            let expected = if aa {
              disp(a, offs)
            } else {
              trunc(a, addr + disp(a, offs))
            }
            r.check_jump(Some(expected))
          } else {
            r.check_jump(None)
          }
          if c.ctr_after is Some(ctr) {
            r.check("CTR", ctr)
          }
          if lk {
            r.check("LR", trunc(a, addr + 4))
          }
        }
      }
    }
  }
}

///|
/// XL-form conditional branches through `reg` (`LR`, `CTR` or `TAR`) with
/// `bi = 31` (`CR7UN`); `reg` holds the instruction address. The generic
/// (`gBC...`) forms are decoded from their upstream encoding
/// `XL [19; bo; 31; 0; 0; xo; lk]`; the `BCC...` forms are code generation
/// only in LLVM and are never produced by the decoder.
fn bc_to_reg(
  a : @powerpc.AddrSize,
  name : String,
  lk : Bool,
  target : String,
  c : BoCase,
) -> Unit raise {
  let addr = branch_addr(a)
  let xo = match target {
    "LR" => 16
    "CTR" => 528
    _ => 560
  }
  // LLVM has no `bctar` instructions: the `gBCTAR` forms are lifted from
  // hand-made instructions only
  let word = if name.has_prefix("g") && xo != 560 {
    Some(
      enc([
        (19, 6),
        (c.bo, 5),
        (31, 5),
        (0, 3),
        (0, 2),
        (xo, 10),
        (lk.to_int(), 1),
      ]),
    )
  } else {
    None
  }
  let r = run(
    a,
    name,
    [imm(c.bo.to_int64()), reg("CR7UN"), imm(0)],
    init=[("CR7UN", c.cond_reg0), ("CTR", c.ctr_before), (target, addr)],
    addr~,
    word?,
  )
  if c.expect_jump {
    r.check_jump(Some(addr & 0xFFFF_FFFF_FFFF_FFFC))
  } else {
    r.check_jump(None)
  }
  if c.ctr_after is Some(ctr) {
    r.check("CTR", ctr)
  }
  if lk {
    r.check("LR", trunc(a, addr + 4))
  }
}

///|
test "bclr, bclrl" {
  for a in archs {
    for c in bc_cases {
      bc_to_reg(a, "gBCLR", false, "LR", c)
      bc_to_reg(a, "gBCLRL", true, "LR", c)
      bc_to_reg(a, "BCCLR", false, "LR", c)
      bc_to_reg(a, "BCCLRL", true, "LR", c)
    }
  }
}

///|
test "bcctr, bcctrl" {
  for a in archs {
    for c in [jmp_anyway, cond_ok, cond_not] {
      bc_to_reg(a, "gBCCTR", false, "CTR", c)
      bc_to_reg(a, "gBCCTRL", true, "CTR", c)
      bc_to_reg(a, "BCCCTR", false, "CTR", c)
      bc_to_reg(a, "BCCCTRL", true, "CTR", c)
    }
  }
}

///|
test "bctar, bctarl" {
  for a in archs {
    for c in bc_cases {
      bc_to_reg(a, "gBCTAR", false, "TAR", c)
      bc_to_reg(a, "gBCTARL", true, "TAR", c)
    }
  }
}

///|
test "bdnz" {
  for a in archs {
    let addr = branch_addr(a)
    // taken: ctr 42 -> 41
    let word = enc([(16, 6), (0b10000, 5), (0, 5), (42, 14), (0, 2)])
    let r = run(a, "BDNZ", [imm(42)], init=[("CTR", 42)], addr~, word~)
    r.check_jump(Some(trunc(a, addr + (42 << 2))))
    r.check("CTR", 41)
    // not taken: ctr 1 -> 0
    let r = run(a, "BDNZ", [imm(42)], init=[("CTR", 1)], addr~, word~)
    r.check_jump(None)
    r.check("CTR", 0)
  }
}

///|
test "bdz" {
  for a in archs {
    let addr = branch_addr(a)
    let word = enc([(16, 6), (0b10010, 5), (0, 5), (-2, 14), (0, 2)])
    let r = run(a, "BDZ", [imm(-2)], init=[("CTR", 1)], addr~, word~)
    r.check_jump(Some(trunc(a, addr - 8)))
    r.check("CTR", 0)
    let r = run(a, "BDZ", [imm(-2)], init=[("CTR", 42)], addr~, word~)
    r.check_jump(None)
    r.check("CTR", 41)
  }
}

///|
test "bdnzlr" {
  for a in archs {
    let addr = branch_addr(a)
    let word = enc([
      (19, 6),
      (0b10000, 5),
      (0, 5),
      (0, 3),
      (0, 2),
      (16, 10),
      (0, 1),
    ])
    let r = run(a, "BDNZLR", [], init=[("CTR", 42), ("LR", addr)], addr~, word~)
    r.check_jump(Some(addr & 0xFFFF_FFFF_FFFF_FFFC))
    r.check("CTR", 41)
    let r = run(a, "BDNZLR", [], init=[("CTR", 1), ("LR", addr)], addr~, word~)
    r.check_jump(None)
    r.check("CTR", 0)
  }
}

///|
test "blr, blrl, bctr, bctrl" {
  for a in archs {
    let addr = branch_addr(a)
    let target = trunc(a, 0x1234_5678_9ABC_DEF3)
    let aligned = target & 0xFFFF_FFFF_FFFF_FFFC
    run(a, "BLR", [], init=[("LR", target)], addr~, word=0x4e800020).check_jump(
      Some(aligned),
    )
    let r = run(a, "BLRL", [], init=[("LR", target)], addr~, word=0x4e800021)
    r.check_jump(Some(aligned))
    r.check("LR", trunc(a, addr + 4))
    run(a, "BCTR", [], init=[("CTR", target)], addr~, word=0x4e800420).check_jump(
      Some(aligned),
    )
    let r = run(a, "BCTRL", [], init=[("CTR", target)], addr~, word=0x4e800421)
    r.check_jump(Some(aligned))
    r.check("LR", trunc(a, addr + 4))
  }
}

///|
/// `BCC` takes an LLVM predicate (`bi << 5 | bo`) and a CR field register;
/// as upstream, the BO bits come from the low five bits and the condition is
/// the low (`UN`) bit of the field.
test "bcc, bccl, bccla" {
  for a in archs {
    let addr = branch_addr(a)
    let pred_eq = (2 << 5) | 0b01100
    let ops = [imm(pred_eq.to_int64()), reg("CR7"), imm(4)]
    let r = run(a, "BCC", ops, init=[("CR7UN", 1)], addr~)
    r.check_jump(Some(trunc(a, addr + 16)))
    run(a, "BCC", ops, init=[("CR7EQ", 1)], addr~).check_jump(None)
    let r = run(a, "BCCL", ops, init=[("CR7UN", 1)], addr~)
    r.check_jump(Some(trunc(a, addr + 16)))
    r.check("LR", trunc(a, addr + 4))
    let r = run(a, "BCCLA", ops, init=[("CR7UN", 1)], addr~)
    r.check_jump(Some(16))
    r.check("LR", trunc(a, addr + 4))
  }
}
