// Port of BAP `plugins/mips/mips_branch.ml`. All opcodes of this group are
// registered with a delay slot of one instruction, like upstream.
//
// Upstream quirks are preserved: branch targets are `cia + offset` (the
// offset operand is used as decoded, without scaling), BGTZ/BGTZL test
// `rs >= 0`, BEQL has no "likely" nullification, and the compact
// `*ALC` branches do not write the link register.

///|
/// `cpu.jmp (cpu.cia + off)`.
fn Cpu::jmp_rel(self : Cpu, off : Exp) -> Rtl raise @mc.LiftError {
  self.jmp(self.cia + off)
}

///|
/// Return address `cia + 8` (skipping the delay slot).
fn Cpu::return_address(self : Cpu) -> Exp raise @mc.LiftError {
  self.cia + uconst(byte, 8)
}

///|
/// Branch on a comparison of two registers: `op rs, rt, offset`.
fn branch2(
  rs_sign : Sign,
  rt_sign : Sign,
  cmp : (Exp, Exp) -> Exp,
) -> Semantics {
  cpu => {
    let rs = cpu.reg(0, rs_sign)
    let rt = cpu.reg(1, rt_sign)
    let off = cpu.simm(2)
    [when_(cmp(rs, rt), [cpu.jmp_rel(off)])]
  }
}

///|
/// Branch on a comparison of a signed register with zero: `op rs, offset`.
fn branch_zero(cmp : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rs = cpu.sreg(0)
    let off = cpu.simm(1)
    [when_(cmp(rs, zero), [cpu.jmp_rel(off)])]
  }
}

///|
/// BAL rs, offset - Branch and Link, MIPS32 (the upstream operand layout);
/// BAL offset - the Release 6 form decoded by LLVM, which links `RA`.
fn sem_bal(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  if cpu.insn.ops.length() == 1 {
    let off = cpu.simm(0)
    return [cpu.gpr(31).assign(cpu.return_address()), cpu.jmp_rel(off)]
  }
  let rs = cpu.sreg(0)
  let off = cpu.simm(1)
  [rs.assign(cpu.return_address()), cpu.jmp_rel(off)]
}

///|
/// BGEZAL rs, offset - Branch on Greater Than or Equal to Zero and Link.
fn sem_bgezal(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.sreg(0)
  let off = cpu.simm(1)
  [
    when_(rs.ge(zero), [
      cpu.gpr(31).assign(cpu.return_address()),
      cpu.jmp_rel(off),
    ]),
  ]
}

///|
/// BNE ra, rb, offset - Branch on Not Equal (upstream: `lnot (ra = rb)`).
fn sem_bne(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let ra = cpu.ureg(0)
  let rb = cpu.ureg(1)
  let off = cpu.simm(2)
  [when_(lnot(ra.eq(rb)), [cpu.jmp_rel(off)])]
}

///|
/// J target - Jump, MIPS32.
fn sem_j(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let target = cpu.simm(0)
  [cpu.jmp(target)]
}

///|
/// JAL target - Jump and Link, MIPS32.
fn sem_jal(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let target = cpu.simm(0)
  [cpu.gpr(31).assign(cpu.return_address()), cpu.jmp(target)]
}

///|
/// JALR rd, rs - Jump and Link Register, MIPS32.
fn sem_jalr(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  [rd.assign(cpu.return_address()), cpu.jmp(rs)]
}

///|
/// JIALC rt, offset - Jump Indexed and Link, Compact, MIPS32 Release 6.
fn sem_jialc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let off = cpu.simm(1)
  [cpu.gpr(31).assign(cpu.return_address()), cpu.jmp(rt + off)]
}

///|
/// JIC rt, offset - Jump Indexed, Compact, MIPS32 Release 6.
fn sem_jic(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let off = cpu.simm(1)
  [cpu.jmp(rt + off)]
}

///|
/// JR rs - Jump Register, MIPS32.
fn sem_jr(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.sreg(0)
  [cpu.jmp(rs)]
}

///|
/// NAL - No-op and Link, MIPS32 Release 6.
fn sem_nal(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  [cpu.gpr(31).assign(cpu.return_address())]
}

///|
let branch_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("BAL", sem_bal),
  ("BEQ", branch2(Signed, Signed, Exp::eq)),
  ("BEQL", branch2(Signed, Signed, Exp::eq)),
  ("BNE", sem_bne),
  ("BGEZ", branch_zero(Exp::ge)),
  ("BLEZ", branch_zero(Exp::le)),
  ("BGEZAL", sem_bgezal),
  ("BLTZALC", branch_zero(Exp::lt)),
  ("BLEZALC", branch_zero(Exp::le)),
  ("BGEZALC", branch_zero(Exp::ge)),
  ("BGTZALC", branch_zero(Exp::gt)),
  ("BEQZALC", branch_zero(Exp::eq)),
  ("BNEZALC", branch_zero(Exp::neq)),
  ("BLTC", branch2(Signed, Signed, Exp::lt)),
  ("BGEC", branch2(Signed, Signed, Exp::ge)),
  ("BEQC", branch2(Signed, Signed, Exp::eq)),
  ("BNEC", branch2(Signed, Signed, Exp::neq)),
  ("BLTUC", branch2(Unsigned, Unsigned, Exp::lt)),
  ("BGEUC", branch2(Unsigned, Unsigned, Exp::ge)),
  ("BLTZC", branch_zero(Exp::lt)),
  ("BLEZC", branch_zero(Exp::le)),
  ("BGEZC", branch_zero(Exp::ge)),
  ("BGTZC", branch_zero(Exp::gt)),
  ("BEQZC", branch_zero(Exp::eq)),
  ("BNEZC", branch_zero(Exp::neq)),
  ("BGTZ", branch_zero(Exp::ge)),
  ("BGTZL", branch_zero(Exp::ge)),
  ("J", sem_j),
  ("JAL", sem_jal),
  ("JALR", sem_jalr),
  ("JALR.HB", sem_jalr),
  ("JIALC", sem_jialc),
  ("JIC", sem_jic),
  ("JR", sem_jr),
  ("NAL", sem_nal),
  ("JALR64", sem_jalr),
]
