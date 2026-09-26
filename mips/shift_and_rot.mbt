// Port of BAP `plugins/mips/mips_shift_and_rot.ml`.

///|
/// ROTR rd, rt, sa / ROTRV rd, rt, rs - Rotate Word Right (Variable),
/// MIPS32 Release 2. `amount` reads the rotate amount operand (index 2).
fn rotate_right(amount : (Cpu) -> Exp raise @mc.LiftError) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rt = cpu.ureg(1)
    let sa = amount(cpu)
    let tm = cpu.uvar(word)
    let tt = cpu.uvar(word)
    [
      // extract the 32-bit word (upstream: `last rt 32`)
      tm.assign(last(rt, 32)),
      tt.assign(tm.lsr(sa)),
      tm.assign(tm.lsl(uconst(byte, 32) - sa)),
      rd.assign(tm | tt),
    ]
  }
}

///|
/// Word shifts `rd := low word rt <op> amount` with a signed destination
/// (SLL, SLLV, SRA, SRL, SRLV).
fn shift_word(
  op : (Exp, Exp) -> Exp,
  amount : (Cpu) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rd = cpu.sreg(0)
    let rt = cpu.ureg(1)
    let sa = amount(cpu)
    [rd.assign(op(low(word, rt), sa))]
  }
}

///|
/// SRAV rd, rt, rs - Shift Word Right Arithmetic Variable, MIPS32
/// (upstream shifts by `last rs 5`, the five most significant bits).
fn sem_srav(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rt = cpu.ureg(1)
  let rs = cpu.ureg(2)
  [rd.assign(low(word, rt).asr(last(rs, 5)))]
}

///|
/// Doubleword shifts `rd := rt <op> (amount [+ 32])` over unsigned
/// registers (DSLL, DSLL32, DSLLV, DSRA, DSRA32, DSRAV, DSRL, DSRL32,
/// DSRLV).
fn shift_doubleword(
  op : (Exp, Exp) -> Exp,
  amount : (Cpu) -> Exp raise @mc.LiftError,
  plus32? : Bool = false,
) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rt = cpu.ureg(1)
    let sa = amount(cpu)
    let sa = if plus32 { sa + uconst(byte, 32) } else { sa }
    [rd.assign(op(rt, sa))]
  }
}

///|
fn shift_imm(cpu : Cpu) -> Exp raise @mc.LiftError {
  cpu.uimm(2)
}

///|
fn shift_reg(cpu : Cpu) -> Exp raise @mc.LiftError {
  cpu.ureg(2)
}

///|
let shift_and_rot_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("ROTR", rotate_right(shift_imm)),
  ("ROTRV", rotate_right(shift_reg)),
  ("SLL", shift_word(Exp::lsl, shift_imm)),
  ("SLLV", shift_word(Exp::lsl, shift_reg)),
  ("DSLL", shift_doubleword(Exp::lsl, shift_imm)),
  ("DSLL32", shift_doubleword(Exp::lsl, shift_imm, plus32=true)),
  ("DSLLV", shift_doubleword(Exp::lsl, shift_reg)),
  ("SRA", shift_word(Exp::asr, shift_imm)),
  ("SRAV", sem_srav),
  ("DSRA", shift_doubleword(Exp::asr, shift_imm)),
  ("DSRA32", shift_doubleword(Exp::asr, shift_imm, plus32=true)),
  ("DSRAV", shift_doubleword(Exp::asr, shift_reg)),
  ("SRL", shift_word(Exp::lsr, shift_imm)),
  ("SRLV", shift_word(Exp::lsr, shift_reg)),
  ("DSRL", shift_doubleword(Exp::lsr, shift_imm)),
  ("DSRL32", shift_doubleword(Exp::lsr, shift_imm, plus32=true)),
  ("DSRLV", shift_doubleword(Exp::lsr, shift_reg)),
]
