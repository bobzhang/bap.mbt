// Port of BAP `plugins/mips/mips_conditional.ml`.

///|
/// SLT rd, rs, rt - Set on Less Than, MIPS32.
fn sem_slt(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let rt = cpu.ureg(2)
  [if_(rs.slt(rt), [rd.assign(one)], [rd.assign(zero)])]
}

///|
/// SLTI rt, rs, imm - Set on Less Than Immediate, MIPS32 (upstream compares
/// unsigned operands).
fn sem_slti(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let im = cpu.uimm(2)
  [if_(rs.lt(im), [rt.assign(one)], [rt.assign(zero)])]
}

///|
/// SLTU rd, rs, rt - Set on Less Than Unsigned, MIPS32.
fn sem_sltu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [if_(rs.lt(rt), [rd.assign(one)], [rd.assign(zero)])]
}

///|
/// SLTIU rt, rs, imm - Set on Less Than Immediate Unsigned, MIPS32.
fn sem_sltiu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let rs = cpu.ureg(1)
  let im = cpu.simm(2)
  [if_(rs.lt(im), [rt.assign(one)], [rt.assign(zero)])]
}

///|
/// SELEQZ rd, rs, rt - Select GPR value or zero, MIPS32 Release 6.
fn sem_seleqz(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [if_(rt.eq(zero), [rd.assign(rs)], [rd.assign(zero)])]
}

///|
/// SELNEZ rd, rs, rt - Select GPR value or zero, MIPS32 Release 6
/// (registered upstream under the name `SELNEQ`).
fn sem_selnez(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [if_(rt.neq(zero), [rd.assign(rs)], [rd.assign(zero)])]
}

///|
let conditional_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("SLT", sem_slt),
  ("SLTi", sem_slti),
  ("SLTu", sem_sltu),
  ("SLTiu", sem_sltiu),
  ("SELEQZ", sem_seleqz),
  ("SELNEQ", sem_selnez),
]
