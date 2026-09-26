// Port of BAP `plugins/mips/mips_arithmetic.ml`.

///|
/// ADD rd, rs, rt - Add Word, MIPS32.
fn sem_add(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let rt = cpu.sreg(2)
  [rd.assign(rs + rt)]
}

///|
/// ADDI rt, rs, immediate - Add Immediate Word, MIPS32 (removed in R6).
fn sem_addi(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let im = cpu.simm(2)
  [rt.assign(rs + im)]
}

///|
/// ADDIU rt, rs, immediate - Add Immediate Unsigned Word, MIPS32.
/// Also used for DADDIU (MIPS64).
fn sem_addiu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let im = cpu.simm(2)
  [rt.assign(rs + im)]
}

///|
/// ADDIUPC rs, immediate - Add Immediate to PC, MIPS32 Release 6.
fn sem_addiupc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let im = cpu.simm(1)
  [rs.assign(cpu.cia + im)]
}

///|
/// ADDU rd, rs, rt - Add Unsigned Word, MIPS32. Also used for SUBU-like
/// three-register unsigned forms (DADDU).
fn sem_addu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs + rt)]
}

///|
/// CLO rd, rs - Count Leading Ones in Word, MIPS32.
fn sem_clo(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let rd = cpu.ureg(1)
  let xv = cpu.uvar(word)
  let cnt = cpu.uvar(byte)
  let has_no_zeroes = cpu.uvar(bit)
  let biti = cpu.uvar(bit)
  [
    xv.assign(low(word, rs)),
    cnt.assign(zero),
    has_no_zeroes.assign(one),
    foreach(biti, xv, [
      if_(has_no_zeroes & biti.eq(one), [cnt.assign(cnt + one)], [
        has_no_zeroes.assign(zero),
      ]),
    ]),
    rd.assign(cnt),
  ]
}

///|
/// CLZ rd, rs - Count Leading Zeroes in Word, MIPS32.
fn sem_clz(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.ureg(0)
  let rd = cpu.ureg(1)
  let xv = cpu.uvar(word)
  let cnt = cpu.uvar(byte)
  let has_no_ones = cpu.uvar(bit)
  let biti = cpu.uvar(bit)
  [
    xv.assign(low(word, rs)),
    cnt.assign(zero),
    has_no_ones.assign(one),
    foreach(biti, xv, [
      if_(has_no_ones & biti.eq(zero), [cnt.assign(cnt + one)], [
        has_no_ones.assign(zero),
      ]),
    ]),
    rd.assign(cnt),
  ]
}

///|
/// LUi rt, imm - Load Upper Immediate, MIPS32.
fn sem_lui(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let im = cpu.simm(1)
  [rt.assign(im.lsl(uconst(byte, 16)))]
}

///|
/// AUI rt, rs, imm - Add Upper Immediate, MIPS32 Release 6 (`lui` is `aui`
/// with `rs` zero). Not modeled upstream.
fn sem_aui(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let im = cpu.uimm(2)
  let x = cpu.svar(word)
  [x.assign(im.lsl(uconst(byte, 16))), rt.assign(rs + x)]
}

///|
/// ALUIPC rs, imm - Aligned Add Upper Immediate to PC, MIPS32 Release 6.
fn sem_aluipc(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rs = cpu.sreg(0)
  let im = cpu.simm(1)
  let x = cpu.uvar(word)
  let mask = cpu.uvar(word)
  [
    mask.assign(uconst(word, 0xFFFF)),
    x.assign(cpu.cia + im.lsl(uconst(byte, 16))),
    rs.assign(lnot(mask) & x),
  ]
}

///|
/// LSA rd, rs, rt, sa - Load Scaled Address, MIPS32 Release 6 (also DLSA).
fn sem_lsa(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  let sa = cpu.uimm(3)
  [rd.assign(rs.lsl(sa + uconst(byte, 1)) + rt)]
}

///|
/// SEB rd, rt - Sign-Extend Byte, MIPS32 Release 2.
///
/// Mirrors upstream, which (despite the manual) takes the *most*
/// significant byte of the source operand (`last rt 8`).
fn sem_seb(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let rs = cpu.sreg(1)
  [rs.assign(last(rt, 8))]
}

///|
/// SEH rd, rt - Sign-Extend Halfword, MIPS32 Release 2 (upstream uses the
/// most significant halfword, see `sem_seb`).
fn sem_seh(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rt = cpu.ureg(0)
  let rs = cpu.sreg(1)
  [rs.assign(last(rt, 16))]
}

///|
/// SUB rd, rs, rt - Subtract Word, MIPS32 (also DSUB).
fn sem_sub(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rs = cpu.sreg(1)
  let rt = cpu.sreg(2)
  [rd.assign(rs - rt)]
}

///|
/// SUBU rd, rs, rt - Subtract Unsigned Word, MIPS32 (also DSUBU).
fn sem_subu(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(rs - rt)]
}

///|
let arithmetic_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("ADD", sem_add),
  ("ADDi", sem_addi),
  ("ADDiu", sem_addiu),
  ("ADDiupc", sem_addiupc),
  ("ADDu", sem_addu),
  ("CLO", sem_clo),
  ("CLZ", sem_clz),
  ("LSA", sem_lsa),
  ("DLSA", sem_lsa),
  ("LUi", sem_lui),
  ("AUI", sem_aui),
  ("ALUipc", sem_aluipc),
  ("SEB", sem_seb),
  ("SEH", sem_seh),
  ("SUB", sem_sub),
  ("SUBu", sem_subu),
  ("DSUB", sem_sub),
  ("DSUBu", sem_subu),
  ("DADDu", sem_addu),
  ("DADDiu", sem_addiu),
]
