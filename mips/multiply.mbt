// Port of BAP `plugins/mips/mips_multiply.ml`, with the `HI`/`LO` moves.
//
// Deliberate deviations from upstream: products are computed at twice the
// operand width, so that the high halves (`MUH`, `MULT`'s `HI`, `DMUH`,
// ...) are the true high halves (upstream multiplies at the operand width
// and takes the high half of that); the 32-bit multiplies use the low
// words and sign-extend their results into MIPS64 registers; `MFHI`,
// `MFLO`, `MTHI`, `MTLO`, `MADD[U]`, `MSUB[U]` and `DMULT[U]` are modeled
// (not in upstream).

///|
/// The product of `x` and `y` extended with the signedness `sign` to twice
/// their width.
fn wide_product(sign : Sign, x : Exp, y : Exp) -> Exp {
  let width = x.width * 2
  x.cast(width, sign) * y.cast(width, sign)
}

///|
/// MUL/MUH/MULU/MUHU rd, rs, rt: `rd := part (rs * rt)` over the low words.
fn mul_word(
  sign : Sign,
  part : (Int, Exp) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rd = cpu.sreg(0)
    let rs = cpu.wreg(1, sign)
    let rt = cpu.wreg(2, sign)
    [rd.assign(sword(part(word, wide_product(sign, rs, rt))))]
  }
}

///|
/// DMUL/DMUH/DMULU/DMUHU rd, rs, rt: via a 128-bit product.
fn mul_doubleword(
  sign : Sign,
  part : (Int, Exp) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rd = cpu.reg(0, sign)
    let rs = cpu.reg(1, sign)
    let rt = cpu.reg(2, sign)
    let tmp = cpu.tmp(sign, quadword)
    [tmp.assign(wide_product(sign, rs, rt)), rd.assign(part(doubleword, tmp))]
  }
}

///|
/// MULT/MULTU rs, rt: `HI:LO := rs * rt` over the low words, each half
/// sign-extended.
fn mult(sign : Sign) -> Semantics {
  cpu => {
    let rs = cpu.wreg(0, sign)
    let rt = cpu.wreg(1, sign)
    let x = cpu.tmp(sign, doubleword)
    [
      x.assign(wide_product(sign, rs, rt)),
      cpu.hi().assign(sword(high(word, x))),
      cpu.lo().assign(sword(low(word, x))),
    ]
  }
}

///|
/// DMULT/DMULTU rs, rt: `HI:LO := rs * rt` over doublewords.
fn dmult(sign : Sign) -> Semantics {
  cpu => {
    let rs = cpu.reg(0, sign)
    let rt = cpu.reg(1, sign)
    let x = cpu.tmp(sign, quadword)
    [
      x.assign(wide_product(sign, rs, rt)),
      cpu.hi().assign(high(doubleword, x)),
      cpu.lo().assign(low(doubleword, x)),
    ]
  }
}

///|
/// MADD/MADDU/MSUB/MSUBU rs, rt: `HI:LO := HI:LO +/- rs * rt` over the low
/// words.
fn mult_accumulate(sign : Sign, subtract : Bool) -> Semantics {
  cpu => {
    let rs = cpu.wreg(0, sign)
    let rt = cpu.wreg(1, sign)
    let acc = cpu.uvar(doubleword)
    let product = wide_product(sign, rs, rt)
    let sum = if subtract { acc - product } else { acc + product }
    [
      acc.assign(low(word, cpu.hi()).concat(low(word, cpu.lo()))),
      acc.assign(sum),
      cpu.hi().assign(sword(high(word, acc))),
      cpu.lo().assign(sword(low(word, acc))),
    ]
  }
}

///|
/// MFHI/MFLO rd.
fn move_from(from_hi : Bool) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    [rd.assign(if from_hi { cpu.hi() } else { cpu.lo() })]
  }
}

///|
/// MTHI/MTLO rs.
fn move_to(to_hi : Bool) -> Semantics {
  cpu => {
    let rs = cpu.ureg(0)
    [(if to_hi { cpu.hi() } else { cpu.lo() }).assign(rs)]
  }
}

///|
let multiply_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("MUL", mul_word(Signed, low)),
  ("MUH", mul_word(Signed, high)),
  ("MULu", mul_word(Unsigned, low)),
  ("MUHu", mul_word(Unsigned, high)),
  ("DMUL", mul_doubleword(Signed, low)),
  ("DMUH", mul_doubleword(Signed, high)),
  ("DMULu", mul_doubleword(Unsigned, low)),
  ("DMUHu", mul_doubleword(Unsigned, high)),
  ("MULT", mult(Signed)),
  ("MULTu", mult(Unsigned)),
  ("DMULT", dmult(Signed)),
  ("DMULTu", dmult(Unsigned)),
  ("MADD", mult_accumulate(Signed, false)),
  ("MADDU", mult_accumulate(Unsigned, false)),
  ("MSUB", mult_accumulate(Signed, true)),
  ("MSUBU", mult_accumulate(Unsigned, true)),
  ("MFHI", move_from(true)),
  ("MFLO", move_from(false)),
  ("MTHI", move_to(true)),
  ("MTLO", move_to(false)),
]
