// Port of BAP `plugins/mips/mips_multiply.ml`.

///|
/// MUL/MUH/MULU/MUHU rd, rs, rt: `rd := part word (rs * rt)`.
fn mul_word(
  sign : Sign,
  part : (Int, Exp) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rd = cpu.reg(0, sign)
    let rs = cpu.reg(1, sign)
    let rt = cpu.reg(2, sign)
    [rd.assign(part(word, rs * rt))]
  }
}

///|
/// DMUL/DMUH/DMULU/DMUHU rd, rs, rt: via a 128-bit temporary.
fn mul_doubleword(
  sign : Sign,
  part : (Int, Exp) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rd = cpu.reg(0, sign)
    let rs = cpu.reg(1, sign)
    let rt = cpu.reg(2, sign)
    let tmp = cpu.tmp(sign, quadword)
    [tmp.assign(rs * rt), rd.assign(part(doubleword, tmp))]
  }
}

///|
/// MULT/MULTU rs, rt: `HI:LO := rs * rt` via a 64-bit temporary.
fn mult(sign : Sign) -> Semantics {
  cpu => {
    let rs = cpu.reg(0, sign)
    let rt = cpu.reg(1, sign)
    let x = cpu.tmp(sign, doubleword)
    [
      x.assign(rs * rt),
      cpu.hi().assign(high(word, x)),
      cpu.lo().assign(low(word, x)),
    ]
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
]
