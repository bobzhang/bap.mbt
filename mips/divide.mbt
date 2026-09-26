// Port of BAP `plugins/mips/mips_divide.ml`.
//
// Upstream registers the pre-R6 two-operand `DIV`/`DIVU` semantics under
// the LLVM names `SDIV`/`UDIV`; the R6 three-operand `DIV`/`DIVU` lifters
// are defined but not registered, which is mirrored here.

///|
/// DIV rs, rt - Divide Word, MIPS32 (removed in R6); LLVM `SDIV`.
fn sem_div(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.sreg(0)
  let rt = cpu.sreg(1)
  let x = cpu.svar(doubleword)
  [x.assign(zero), cpu.lo().assign(rs.sdiv(rt)), cpu.hi().assign(rs.smod(rt))]
}

///|
/// DIVU rs, rt - Divide Unsigned Word, MIPS32 (removed in R6); LLVM `UDIV`.
fn sem_divu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let rt = cpu.ureg(1)
  let x = cpu.uvar(doubleword)
  [x.assign(zero), cpu.lo().assign(rs / rt), cpu.hi().assign(rs % rt)]
}

///|
/// MOD rd, rs, rt - Modulo Words Signed, MIPS32 R6 (also DMOD).
fn sem_mod(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let rt = cpu.sreg(2)
  [rd.assign(rs.smod(rt))]
}

///|
/// MODU rd, rs, rt - Modulo Words Unsigned, MIPS32 R6 (also DMODU).
fn sem_modu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs % rt)]
}

///|
/// DDIV rd, rs, rt - Divide Doublewords Signed, MIPS64 R6.
fn sem_ddiv(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let rt = cpu.sreg(2)
  [rd.assign(rs.sdiv(rt))]
}

///|
/// DDIVU rd, rs, rt - Divide Doublewords Unsigned, MIPS64 R6.
fn sem_ddivu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs / rt)]
}

///|
let divide_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("SDIV", sem_div),
  ("MOD", sem_mod),
  ("UDIV", sem_divu),
  ("MODu", sem_modu),
  ("DDIV", sem_ddiv),
  ("DMOD", sem_mod),
  ("DDIVu", sem_ddivu),
  ("DMODu", sem_modu),
]
