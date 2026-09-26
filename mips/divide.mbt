// Port of BAP `plugins/mips/mips_divide.ml`.
//
// LLVM names the pre-R6 two-operand `DIV`/`DIVU` (`HI`/`LO` results)
// `SDIV`/`UDIV`, and the MIPS64 ones `DSDIV`/`DUDIV`; the Release 6
// three-operand forms are `DIV`/`DIVU`/`MOD`/`MODU` and their `D` variants.
//
// Deliberate deviations from upstream: the 32-bit divisions divide the low
// words and sign-extend their results into MIPS64 registers; the R6
// `DIV`/`DIVU` (defined but not registered upstream) and the pre-R6
// `DSDIV`/`DUDIV` are registered.

///|
/// DIV rs, rt - Divide Word, MIPS32 (removed in R6); LLVM `SDIV`.
fn sem_div(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.wreg(0, Signed)
  let rt = cpu.wreg(1, Signed)
  [cpu.lo().assign(sword(rs.sdiv(rt))), cpu.hi().assign(sword(rs.smod(rt)))]
}

///|
/// DIVU rs, rt - Divide Unsigned Word, MIPS32 (removed in R6); LLVM `UDIV`.
fn sem_divu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.wreg(0, Unsigned)
  let rt = cpu.wreg(1, Unsigned)
  [cpu.lo().assign(sword(rs / rt)), cpu.hi().assign(sword(rs % rt))]
}

///|
/// DDIV rs, rt - Doubleword Divide, MIPS64 (removed in R6); LLVM `DSDIV`.
fn sem_dsdiv(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.sreg(0)
  let rt = cpu.sreg(1)
  [cpu.lo().assign(rs.sdiv(rt)), cpu.hi().assign(rs.smod(rt))]
}

///|
/// DDIVU rs, rt - Doubleword Divide Unsigned, MIPS64 (removed in R6); LLVM
/// `DUDIV`.
fn sem_dudiv(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let rt = cpu.ureg(1)
  [cpu.lo().assign(rs / rt), cpu.hi().assign(rs % rt)]
}

///|
/// Release 6 `op rd, rs, rt` over the low words (`DIV`, `DIVU`, `MOD`,
/// `MODU`), with the result sign-extended.
fn word_op(sign : Sign, op : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rd = cpu.sreg(0)
    let rs = cpu.wreg(1, sign)
    let rt = cpu.wreg(2, sign)
    [rd.assign(sword(op(rs, rt)))]
  }
}

///|
/// Release 6 `op rd, rs, rt` over doublewords (`DDIV`, `DDIVU`, `DMOD`,
/// `DMODU`).
fn doubleword_op(sign : Sign, op : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rd = cpu.reg(0, sign)
    let rs = cpu.reg(1, sign)
    let rt = cpu.reg(2, sign)
    [rd.assign(op(rs, rt))]
  }
}

///|
let divide_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("SDIV", sem_div),
  ("UDIV", sem_divu),
  ("DSDIV", sem_dsdiv),
  ("DUDIV", sem_dudiv),
  ("DIV", word_op(Signed, Exp::sdiv)),
  ("DIVU", word_op(Unsigned, (x, y) => x / y)),
  ("MOD", word_op(Signed, Exp::smod)),
  ("MODu", word_op(Unsigned, (x, y) => x % y)),
  ("DDIV", doubleword_op(Signed, Exp::sdiv)),
  ("DDIVu", doubleword_op(Unsigned, (x, y) => x / y)),
  ("DMOD", doubleword_op(Signed, Exp::smod)),
  ("DMODu", doubleword_op(Unsigned, (x, y) => x % y)),
]
