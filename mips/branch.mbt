// Port of BAP `plugins/mips/mips_branch.ml`.
//
// Branch targets are `cia + offset`: LLVM's branch operand is already the
// target relative to the branch (`DecodeBranchTarget`: the word offset
// scaled by four, plus four). The delayed branches and jumps have one
// delay slot (`delayed_branch_semantics`), the Release 6 compact ones none
// (`compact_branch_semantics`).
//
// Deliberate deviations from upstream:
// - signed comparisons with zero and between registers are signed
//   (upstream's comparisons are unsigned), and `BGTZ`/`BGTZL` test `> 0`
//   (upstream: `>= 0`);
// - `J`/`JAL` jump into the 256 MB region of the delay slot address (LLVM's
//   operand is the offset in the region; upstream jumps to it);
// - the branch-and-link forms link unconditionally, the compact ones link
//   `cia + 4`, and `JIC`/`JIALC` sign-extend LLVM's 16-bit offset;
// - `JALR` reads the target before linking (`jalr $ra, $ra`);
// - the compact branches have no delay slot, and the branches missing
//   upstream (`BLTZ`, `BLTZL`, `BGEZL`, `BNEL`, `BLEZL`, `BLTZAL`,
//   `BGEZALL`, `BLTZALL`, `JALX`, `BC`, `BALC`, the hazard-barrier `JR`s)
//   are modeled.
// The "likely" branches do not nullify their delay slot when not taken:
// that needs support from the delay slot handling of the disassembler.

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
/// Return address `cia + 4` of the compact branches.
fn Cpu::compact_return_address(self : Cpu) -> Exp raise @mc.LiftError {
  self.cia + uconst(byte, 4)
}

///|
/// `RA := addr`.
fn Cpu::link(self : Cpu, addr : Exp) -> Rtl raise @mc.LiftError {
  self.gpr(31).assign(addr)
}

///|
/// Branch on a comparison of two registers: `op rs, rt, offset`.
fn branch2(sign : Sign, cmp : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rs = cpu.reg(0, sign)
    let rt = cpu.reg(1, sign)
    let off = cpu.simm(2)
    [when_(cmp(rs, rt), [cpu.jmp_rel(off)])]
  }
}

///|
/// Branch on a signed comparison of a register with zero: `op rs, offset`,
/// linking `link` (if any) unconditionally.
fn branch_zero(
  cmp : (Exp, Exp) -> Exp,
  link? : (Cpu) -> Exp raise @mc.LiftError,
) -> Semantics {
  cpu => {
    let rs = cpu.sreg(0)
    let off = cpu.simm(1)
    let branch = when_(cmp(rs, zero), [cpu.jmp_rel(off)])
    match link {
      None => [branch]
      // the condition reads `rs` before `RA` is written (`rs` may be `RA`)
      Some(link) => {
        let taken = cpu.uvar(bit)
        [
          taken.assign(cmp(rs, zero)),
          cpu.link(link(cpu)),
          when_(taken, [cpu.jmp_rel(off)]),
        ]
      }
    }
  }
}

///|
/// BAL rs, offset - the upstream operand layout (linking `rs`); BAL offset
/// - the Release 6 form decoded by LLVM, which links `RA`.
fn sem_bal(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  if cpu.insn.ops.length() == 1 {
    let off = cpu.simm(0)
    return [cpu.link(cpu.return_address()), cpu.jmp_rel(off)]
  }
  let rs = cpu.sreg(0)
  let off = cpu.simm(1)
  [rs.assign(cpu.return_address()), cpu.jmp_rel(off)]
}

///|
/// BC offset / BALC offset - Branch (and Link), Compact, Release 6.
fn compact_branch(link : Bool) -> Semantics {
  cpu => {
    let off = cpu.simm(0)
    if link {
      [cpu.link(cpu.compact_return_address()), cpu.jmp_rel(off)]
    } else {
      [cpu.jmp_rel(off)]
    }
  }
}

///|
/// J/JAL/JALX target - jump into the 256 MB region of the delay slot.
fn jump_region(link : Bool) -> Semantics {
  cpu => {
    let index = cpu.uimm(0)
    let width = cpu.arch.addr_bitwidth()
    let mask = Exp::of_word(make_word(width, 0x0FFFFFFFL)).unop(Not)
    let target = ((cpu.cia + uconst(byte, 4)) & mask) | index
    if link {
      [cpu.link(cpu.return_address()), cpu.jmp(target)]
    } else {
      [cpu.jmp(target)]
    }
  }
}

///|
/// JALR rd, rs - Jump and Link Register, MIPS32.
fn sem_jalr(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let target = cpu.svar(cpu.arch.addr_bitwidth())
  [target.assign(rs), rd.assign(cpu.return_address()), cpu.jmp(target)]
}

///|
/// JIC/JIALC rt, offset - Jump Indexed (and Link), Compact, Release 6
/// (LLVM's offset is the unsigned 16-bit field).
fn jump_indexed(link : Bool) -> Semantics {
  cpu => {
    let rt = cpu.sreg(0)
    let off = low(halfword, cpu.uimm(1)).signed()
    let target = cpu.svar(cpu.arch.addr_bitwidth())
    let jump = [target.assign(rt + off)]
    if link {
      jump.push(cpu.link(cpu.compact_return_address()))
    }
    jump.push(cpu.jmp(target))
    jump
  }
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
  [cpu.link(cpu.return_address())]
}

///|
/// `(cpu) -> cia + 8`.
fn delayed_link(cpu : Cpu) -> Exp raise @mc.LiftError {
  cpu.return_address()
}

///|
/// `(cpu) -> cia + 4`.
fn compact_link(cpu : Cpu) -> Exp raise @mc.LiftError {
  cpu.compact_return_address()
}

///|
/// The branches and jumps with a delay slot.
let delayed_branch_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("BAL", sem_bal),
  ("BEQ", branch2(Signed, Exp::eq)),
  ("BEQL", branch2(Signed, Exp::eq)),
  ("BNE", branch2(Signed, Exp::neq)),
  ("BNEL", branch2(Signed, Exp::neq)),
  ("BGEZ", branch_zero(Exp::sge)),
  ("BGEZL", branch_zero(Exp::sge)),
  ("BLEZ", branch_zero(Exp::sle)),
  ("BLEZL", branch_zero(Exp::sle)),
  ("BGTZ", branch_zero(Exp::sgt)),
  ("BGTZL", branch_zero(Exp::sgt)),
  ("BLTZ", branch_zero(Exp::slt)),
  ("BLTZL", branch_zero(Exp::slt)),
  ("BGEZAL", branch_zero(Exp::sge, link=delayed_link)),
  ("BGEZALL", branch_zero(Exp::sge, link=delayed_link)),
  ("BLTZAL", branch_zero(Exp::slt, link=delayed_link)),
  ("BLTZALL", branch_zero(Exp::slt, link=delayed_link)),
  ("J", jump_region(false)),
  ("JAL", jump_region(true)),
  ("JALX", jump_region(true)),
  ("JALR", sem_jalr),
  ("JALR.HB", sem_jalr),
  ("JALR64", sem_jalr),
  ("JR", sem_jr),
  ("NAL", sem_nal),
]

///|
/// The Release 6 compact branches and jumps (no delay slot).
let compact_branch_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("BLTZALC", branch_zero(Exp::slt, link=compact_link)),
  ("BLEZALC", branch_zero(Exp::sle, link=compact_link)),
  ("BGEZALC", branch_zero(Exp::sge, link=compact_link)),
  ("BGTZALC", branch_zero(Exp::sgt, link=compact_link)),
  ("BEQZALC", branch_zero(Exp::eq, link=compact_link)),
  ("BNEZALC", branch_zero(Exp::neq, link=compact_link)),
  ("BLTC", branch2(Signed, Exp::slt)),
  ("BGEC", branch2(Signed, Exp::sge)),
  ("BEQC", branch2(Signed, Exp::eq)),
  ("BNEC", branch2(Signed, Exp::neq)),
  ("BLTUC", branch2(Unsigned, Exp::lt)),
  ("BGEUC", branch2(Unsigned, Exp::ge)),
  ("BLTZC", branch_zero(Exp::slt)),
  ("BLEZC", branch_zero(Exp::sle)),
  ("BGEZC", branch_zero(Exp::sge)),
  ("BGTZC", branch_zero(Exp::sgt)),
  ("BEQZC", branch_zero(Exp::eq)),
  ("BNEZC", branch_zero(Exp::neq)),
  ("BC", compact_branch(false)),
  ("BALC", compact_branch(true)),
  ("JIC", jump_indexed(false)),
  ("JIALC", jump_indexed(true)),
]
