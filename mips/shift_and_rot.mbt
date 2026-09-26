// Port of BAP `plugins/mips/mips_shift_and_rot.ml`.
//
// Deliberate deviations from upstream: the word shifts and rotations
// operate on the low word of `rt` and sign-extend the result into MIPS64
// registers (upstream zero-extends, and rotates the high word of `rt`);
// variable shifts use the low 5 (words) or 6 (doublewords) bits of `rs`
// (upstream uses all of `rs`, or the 5 most significant bits for `SRAV`);
// the doubleword rotations are modeled.

///|
/// The shift amount operand 2: the immediate, or the low `bits` bits of
/// the register.
fn shift_amount(bits : Int) -> (Cpu) -> Exp raise @mc.LiftError {
  cpu => {
    match cpu.op(2) {
      Imm(_) => cpu.uimm(2)
      _ => first(cpu.ureg(2), bits)
    }
  }
}

///|
/// Rotate `x` right by `sa` within its width.
fn rotate(x : Exp, sa : Exp) -> Exp raise @mc.LiftError {
  let width = uconst(byte, x.width)
  // `x << (width - sa)` is zero when `sa` is zero
  x.lsr(sa) | x.lsl(width - sa)
}

///|
/// ROTR/ROTRV rd, rt, sa - Rotate Word Right (Variable), MIPS32 Release 2.
fn rotate_word(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rt = cpu.wreg(1, Unsigned)
  let sa = shift_amount(5)(cpu)
  [rd.assign(sword(rotate(rt, sa.cast(word, Unsigned))))]
}

///|
/// DROTR/DROTR32/DROTRV rd, rt, sa - Doubleword Rotate Right, MIPS64.
fn rotate_doubleword(plus32? : Bool = false) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rt = cpu.ureg(1)
    let sa = shift_amount(6)(cpu).cast(doubleword, Unsigned)
    let sa = if plus32 { sa + uconst(doubleword, 32) } else { sa }
    [rd.assign(rotate(rt, sa))]
  }
}

///|
/// Word shifts `rd := low word rt <op> amount`, sign-extended (SLL, SLLV,
/// SRA, SRAV, SRL, SRLV).
fn shift_word(op : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rd = cpu.sreg(0)
    let rt = cpu.wreg(1, Unsigned)
    let sa = shift_amount(5)(cpu)
    [rd.assign(sword(op(rt, sa)))]
  }
}

///|
/// Doubleword shifts `rd := rt <op> (amount [+ 32])` (DSLL, DSLL32,
/// DSLLV, DSRA, DSRA32, DSRAV, DSRL, DSRL32, DSRLV).
fn shift_doubleword(
  op : (Exp, Exp) -> Exp,
  plus32? : Bool = false,
) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rt = cpu.ureg(1)
    let sa = shift_amount(6)(cpu)
    let sa = if plus32 { sa + uconst(byte, 32) } else { sa }
    [rd.assign(op(rt, sa))]
  }
}

///|
let shift_and_rot_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("ROTR", rotate_word),
  ("ROTRV", rotate_word),
  ("DROTR", rotate_doubleword()),
  ("DROTR32", rotate_doubleword(plus32=true)),
  ("DROTRV", rotate_doubleword()),
  ("SLL", shift_word(Exp::lsl)),
  ("SLLV", shift_word(Exp::lsl)),
  ("DSLL", shift_doubleword(Exp::lsl)),
  ("DSLL32", shift_doubleword(Exp::lsl, plus32=true)),
  ("DSLLV", shift_doubleword(Exp::lsl)),
  ("SRA", shift_word(Exp::asr)),
  ("SRAV", shift_word(Exp::asr)),
  ("DSRA", shift_doubleword(Exp::asr)),
  ("DSRA32", shift_doubleword(Exp::asr, plus32=true)),
  ("DSRAV", shift_doubleword(Exp::asr)),
  ("SRL", shift_word(Exp::lsr)),
  ("SRLV", shift_word(Exp::lsr)),
  ("DSRL", shift_doubleword(Exp::lsr)),
  ("DSRL32", shift_doubleword(Exp::lsr, plus32=true)),
  ("DSRLV", shift_doubleword(Exp::lsr)),
]
