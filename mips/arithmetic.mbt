// Port of BAP `plugins/mips/mips_arithmetic.ml`.
//
// Deliberate deviations from upstream (for the operands produced by LLVM's
// decoder and the ISA semantics):
// - the 32-bit operations (`ADD`, `ADDIU`, `SUBU`, `LUI`, ...) compute on
//   the low words and sign-extend the result into MIPS64 registers
//   (upstream computes at the full register width);
// - `CLO`/`CLZ` read `rs` and write `rd` (LLVM's `[rd, rs]`; upstream swaps
//   them) and count from the most significant bit (upstream counts from
//   the least significant one);
// - `LSA`/`DLSA` shift by the operand (LLVM's operand is already the
//   encoded amount plus one; upstream adds one again);
// - `SEB`/`SEH` sign-extend the least significant byte/halfword of `rt`
//   into `rd` (upstream takes the most significant one, and swaps the
//   operands);
// - `ALUIPC` computes at the address width;
// - `AUI` and `AUIPC` are modeled (not in upstream).

///|
/// ADD rd, rs, rt - Add Word, MIPS32 (overflow traps are not modeled).
fn sem_add(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.wreg(1, Signed)
  let rt = cpu.wreg(2, Signed)
  [rd.assign(sword(rs + rt))]
}

///|
/// ADDI/ADDIU rt, rs, immediate - Add Immediate (Unsigned) Word, MIPS32.
fn sem_addiu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let rs = cpu.wreg(1, Signed)
  let im = cpu.simm(2)
  [rt.assign(sword(rs + im))]
}

///|
/// DADDI/DADDIU rt, rs, immediate - Doubleword Add Immediate, MIPS64.
fn sem_daddiu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let im = cpu.simm(2)
  [rt.assign(rs + im)]
}

///|
/// ADDIUPC rs, immediate - Add Immediate to PC, MIPS32 Release 6 (LLVM's
/// operand is the scaled offset).
fn sem_addiupc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let im = cpu.simm(1)
  [rs.assign(cpu.cia + im)]
}

///|
/// ADDU rd, rs, rt - Add Unsigned Word, MIPS32.
fn sem_addu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.wreg(1, Unsigned)
  let rt = cpu.wreg(2, Unsigned)
  [rd.assign(sword(rs + rt))]
}

///|
/// DADD/DADDU rd, rs, rt - Doubleword Add, MIPS64.
fn sem_daddu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs + rt)]
}

///|
/// Count the leading bits of the low word of `rs` (the whole `rs` with
/// `doubleword`) equal to `value`, from the most significant one, into `rd`
/// (`CLO`/`CLZ rd, rs`, `DCLO`/`DCLZ rd, rs`).
fn count_leading(value : Exp, doubleword~ : Bool = false) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rs = if doubleword { cpu.ureg(1) } else { cpu.wreg(1, Unsigned) }
    let xv = cpu.uvar(if doubleword { 64 } else { word })
    let cnt = cpu.uvar(byte)
    let counting = cpu.uvar(bit)
    let biti = cpu.uvar(bit)
    [
      xv.assign(rs),
      cnt.assign(zero),
      counting.assign(one),
      Foreach(true, biti, xv, [
        if_(counting & biti.eq(value), [cnt.assign(cnt + one)], [
          counting.assign(zero),
        ]),
      ]),
      rd.assign(cnt),
    ]
  }
}

///|
/// LUi rt, imm - Load Upper Immediate, MIPS32.
fn sem_lui(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let im = cpu.uimm(1)
  [rt.assign(sword(im.lsl(uconst(byte, 16))))]
}

///|
/// AUI rt, rs, imm - Add Upper Immediate, MIPS32 Release 6 (`lui` is `aui`
/// with `rs` zero). Not modeled upstream.
fn sem_aui(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let rs = cpu.wreg(1, Unsigned)
  let im = cpu.uimm(2)
  [rt.assign(sword(rs + im.lsl(uconst(byte, 16))))]
}

///|
/// AUIPC rs, imm - Add Upper Immediate to PC, MIPS32 Release 6. Not
/// modeled upstream.
fn sem_auipc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let im = cpu.uimm(1)
  [rs.assign(cpu.cia + im.lsl(uconst(byte, 16)).signed())]
}

///|
/// ALUIPC rs, imm - Aligned Add Upper Immediate to PC, MIPS32 Release 6.
fn sem_aluipc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let im = cpu.uimm(1)
  let width = cpu.arch.addr_bitwidth()
  let mask = Exp::of_word(make_word(width, -0x10000L))
  [rs.assign((cpu.cia + im.lsl(uconst(byte, 16)).signed()) & mask)]
}

///|
/// LSA rd, rs, rt, sa - Load Scaled Address, MIPS32 Release 6 (LLVM's `sa`
/// operand is the shift amount).
fn sem_lsa(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.wreg(1, Unsigned)
  let rt = cpu.wreg(2, Unsigned)
  let sa = cpu.uimm(3)
  [rd.assign(sword(rs.lsl(sa) + rt))]
}

///|
/// DLSA rd, rs, rt, sa - Doubleword Load Scaled Address, MIPS64 Release 6.
fn sem_dlsa(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  let sa = cpu.uimm(3)
  [rd.assign(rs.lsl(sa) + rt)]
}

///|
/// SEB/SEH rd, rt - Sign-Extend Byte/Halfword, MIPS32 Release 2.
fn sign_extend(width : Int32) -> Semantics {
  cpu => {
    let rd = cpu.sreg(0)
    let rt = cpu.ureg(1)
    [rd.assign(low(width, rt).signed())]
  }
}

///|
/// SUB rd, rs, rt - Subtract Word, MIPS32 (overflow traps are not
/// modeled).
fn sem_sub(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.wreg(1, Signed)
  let rt = cpu.wreg(2, Signed)
  [rd.assign(sword(rs - rt))]
}

///|
/// SUBU rd, rs, rt - Subtract Unsigned Word, MIPS32.
fn sem_subu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.wreg(1, Unsigned)
  let rt = cpu.wreg(2, Unsigned)
  [rd.assign(sword(rs - rt))]
}

///|
/// DSUB/DSUBU rd, rs, rt - Doubleword Subtract, MIPS64.
fn sem_dsubu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs - rt)]
}

///|
let arithmetic_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("ADD", sem_add),
  ("ADDi", sem_addiu),
  ("ADDiu", sem_addiu),
  ("ADDiupc", sem_addiupc),
  ("ADDu", sem_addu),
  ("CLO", count_leading(one)),
  ("CLZ", count_leading(zero)),
  // port: not modeled upstream
  ("DCLO", count_leading(one, doubleword=true)),
  ("DCLZ", count_leading(zero, doubleword=true)),
  ("LSA", sem_lsa),
  ("DLSA", sem_dlsa),
  ("LUi", sem_lui),
  ("AUI", sem_aui),
  ("AUIPC", sem_auipc),
  ("ALUipc", sem_aluipc),
  ("SEB", sign_extend(byte)),
  ("SEH", sign_extend(halfword)),
  ("SUB", sem_sub),
  ("SUBu", sem_subu),
  ("DSUB", sem_dsubu),
  ("DSUBu", sem_dsubu),
  ("DADD", sem_daddu),
  ("DADDu", sem_daddu),
  ("DADDi", sem_daddiu),
  ("DADDiu", sem_daddiu),
]
