// Port of `plugins/thumb/thumb_main.ml`: operand decoding and dispatch.
//
// Upstream answers `Insn.empty` (no semantics) for unknown opcodes, operand
// shapes it does not recognise, and exceptions raised while decoding
// operands. The shared `@mc.Lifter` contract reports those cases as errors
// instead: `Unsupported` for opcodes without upstream semantics and
// `BadOperands` for operand shapes (or predicate immediates) upstream
// rejects.

///|
/// Target and encoding names this lifter is registered for.
let thumb_targets : ReadOnlyArray[String] = ["thumb", "thumbv7", "llvm-thumb"]

///|
/// Target names `register` installs the Thumb lifter under.
pub fn target_names() -> Array[String] {
  [..thumb_targets]
}

///|
fn bad(insn : @mc.Insn) -> @mc.LiftError {
  @mc.BadOperands(insn.name)
}

///|
fn reg(name : String) -> @types.Var {
  reg32(name)
}

///|
fn imm(x : Int64) -> Int {
  x.to_int()
}

///|
fn cnd(insn : @mc.Insn, code : Int64) -> Cond raise @mc.LiftError {
  if code >= 0L && code <= 14L && Cond::of_int(code.to_int()) is Some(c) {
    c
  } else {
    raise bad(insn)
  }
}

///|
fn regs(
  insn : @mc.Insn,
  ops : ArrayView[@mc.Op],
) -> Array[@types.Var] raise @mc.LiftError {
  let out = []
  for op in ops {
    match op {
      Reg(name~, ..) => out.push(reg(name))
      _ => raise bad(insn)
    }
  }
  out
}

///|
fn is_pc(r : @types.Var) -> Bool {
  r.name == "PC"
}

///|
/// Low 32 bits of the instruction address.
fn addr32(insn : @mc.Insn) -> Int {
  insn.addr.to_int()
}

///|
fn lift_move(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match (opcode, insn.ops) {
    (TADDi3, [Reg(name=rd, ..), _, Reg(name=rn, ..), Imm(x), Imm(c), _]) =>
      addi3(reg(rd), reg(rn), imm(x), cnd(insn, c))
    (TADDi8, [Reg(name=rd, ..), _, _, Imm(x), Imm(c), _]) =>
      addi8(reg(rd), imm(x), cnd(insn, c))
    (
      TADDrr,
      [Reg(name=rd, ..), _, Reg(name=rn, ..), Reg(name=rm, ..), Imm(c), _],
    ) => addrr(reg(rd), reg(rn), reg(rm), cnd(insn, c))
    (
      TADC,
      [Reg(name=rd, ..), Reg(_), Reg(name=rn, ..), Reg(name=rm, ..), Imm(c), _],
    ) => adcs(reg(rd), reg(rn), reg(rm), cnd(insn, c))
    (TADDrSPi, [Reg(name=rd, ..), _, Imm(x), Imm(c), _]) =>
      addrspi(reg(rd), imm(x) * 4, cnd(insn, c))
    (TADDspi, [_, _, Imm(x), Imm(c), _]) => addspi(imm(x) * 4, cnd(insn, c))
    (TSUBi3, [Reg(name=rd, ..), _, Reg(name=rn, ..), Imm(x), Imm(c), _]) =>
      subi3(reg(rd), reg(rn), imm(x), cnd(insn, c))
    (TSUBi8, [Reg(name=rd, ..), _, _, Imm(x), Imm(c), _]) =>
      subi8(reg(rd), imm(x), cnd(insn, c))
    (
      TSUBrr,
      [Reg(name=rd, ..), _, Reg(name=rn, ..), Reg(name=rm, ..), Imm(c), _],
    ) => subrr(reg(rd), reg(rn), reg(rm), cnd(insn, c))
    (TSUBspi, [_, _, Imm(x), Imm(c), _]) => subspi(imm(x) * 4, cnd(insn, c))
    (TMOVi8, [Reg(name=rd, ..), _, Imm(x), Imm(c), _]) =>
      movi8(reg(rd), x, cnd(insn, c))
    (TMOVSr, [Reg(name=rd, ..), Reg(name=rn, ..)]) => movsr(reg(rd), reg(rn))
    (TASRri, [Reg(name=rd, ..), _, Reg(name=rm, ..), Imm(x), Imm(c), _]) =>
      asri(reg(rd), reg(rm), imm(x), cnd(insn, c))
    (TLSRri, [Reg(name=rd, ..), _, Reg(name=rm, ..), Imm(x), Imm(c), _]) =>
      lsri(reg(rd), reg(rm), imm(x), cnd(insn, c))
    (TLSLri, [Reg(name=rd, ..), _, Reg(name=rm, ..), Imm(x), Imm(c), _]) =>
      lsli(reg(rd), reg(rm), imm(x), cnd(insn, c))
    (TCMPi8, [Reg(name=rn, ..), Imm(x), _, _]) => cmpi8(reg(rn), imm(x))
    (TCMPr, [Reg(name=rn, ..), Reg(name=rm, ..), _, _]) =>
      cmpr(reg(rn), reg(rm))
    (TORR, [Reg(name=rd, ..), _, _, Reg(name=rm, ..), Imm(c), _]) =>
      lorr(reg(rd), reg(rm), cnd(insn, c))
    _ => raise bad(insn)
  }
}

///|
fn lift_mem_multi(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match (opcode, insn.ops[:]) {
    (TSTMIA_UPD, [Reg(name=rd, ..), Imm(c), _, .. ar])
    | (TSTMIA_UPD, [Reg(name=rd, ..), Reg(_), Imm(c), _, .. ar]) =>
      stm(reg(rd), regs(insn, ar), cnd(insn, c))
    (TLDMIA, [Reg(name=rd, ..), Imm(c), _, .. ar]) =>
      ldm(reg(rd), regs(insn, ar), cnd(insn, c))
    (TPUSH, [Imm(c), _, .. ar]) => push(regs(insn, ar), cnd(insn, c))
    (TPOP, [Imm(c), _, .. ar]) => {
      let rs = regs(insn, ar)
      let c = cnd(insn, c)
      if rs.iter().any(is_pc) {
        popret(rs.filter(r => !is_pc(r)), c)
      } else {
        pop(rs, c)
      }
    }
    // upstream has no semantics for tSTMIA and tLDMIA_UPD
    (TSTMIA | TLDMIA_UPD, _) => raise @mc.Unsupported(insn.name)
    _ => raise bad(insn)
  }
}

///|
fn lift_mem(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let pc = addr32(insn) + 4
  match (opcode, insn.ops) {
    (TLDRi | TLDRspi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      ldri(reg(rd), reg(rm), imm(i) * 4, cnd(insn, c))
    (TLDRr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      ldrr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TLDRpci | T2LDRpci, [Reg(name=rd, ..), Imm(i), Imm(c), _]) =>
      ldrpci(reg(rd), pc, imm(i), cnd(insn, c))
    (TLDRBi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      ldrbi(reg(rd), reg(rm), imm(i), cnd(insn, c))
    (TLDRBr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      ldrbr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TLDRSB, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      ldrsb(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TLDRHi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      ldrhi(reg(rd), reg(rm), imm(i) * 2, cnd(insn, c))
    (TLDRHr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      ldrhr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TLDRSH, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      ldrsh(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TSTRspi | TSTRi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      stri(reg(rd), reg(rm), imm(i) * 4, cnd(insn, c))
    (TSTRr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      strr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TSTRBi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      strbi(reg(rd), reg(rm), imm(i), cnd(insn, c))
    (TSTRBr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      strbr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    (TSTRHi, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(i), Imm(c), _]) =>
      strhi(reg(rd), reg(rm), imm(i) * 2, cnd(insn, c))
    (TSTRHr, [Reg(name=rd, ..), Reg(name=rm, ..), Reg(name=rn, ..), Imm(c), _]) =>
      strhr(reg(rd), reg(rm), reg(rn), cnd(insn, c))
    _ => raise bad(insn)
  }
}

///|
fn lift_bits(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match (opcode, insn.ops) {
    (TSXTB, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(c), _]) =>
      sx(8, reg(rd), reg(rm), cnd(insn, c))
    (TSXTH, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(c), _]) =>
      sx(16, reg(rd), reg(rm), cnd(insn, c))
    (TUXTB, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(c), _]) =>
      ux(8, reg(rd), reg(rm), cnd(insn, c))
    (TUXTH, [Reg(name=rd, ..), Reg(name=rm, ..), Imm(c), _]) =>
      ux(16, reg(rd), reg(rm), cnd(insn, c))
    _ => raise bad(insn)
  }
}

///|
fn lift_branch(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let pc = addr32(insn)
  match (opcode, insn.ops) {
    (TB, [Imm(dst), _, _]) => b(pc, imm(dst))
    (TBcc, [Imm(dst), Imm(c), _]) => bcc(pc, cnd(insn, c), imm(dst))
    (TBL, [_, _, Imm(dst), _])
    | (TBLXi, [_, _, Imm(dst)] | [_, _, Imm(dst), _]) => bli(pc, imm(dst))
    // blx pc is unpredictable in all versions of ARM
    (TBLXr, [_, _, Reg(name=dst, ..)]) if is_pc(reg(dst)) => unpredictable()
    (TBLXr, [_, _, Reg(name=dst, ..)]) => blxr(pc, reg(dst))
    (TBX, [Reg(name=dst, ..), _, _]) if is_pc(reg(dst)) => bxi(pc, 0)
    (TBX, [Reg(name=dst, ..), _, _]) => bxr(reg(dst))
    (TCBNZ, [Reg(name=rn, ..), Imm(c)]) => cbnz(pc, reg(rn), imm(c))
    (TCBZ, [Reg(name=rn, ..), Imm(c)]) => cbz(pc, reg(rn), imm(c))
    _ => raise bad(insn)
  }
}

///|
/// Lift a decoded Thumb instruction whose opcode is already known
/// (upstream `Thumb.lift_insn`).
pub fn lift_opcode(
  opcode : Opcode,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match opcode.kind() {
    Mem => lift_mem(opcode, insn)
    MemMulti => lift_mem_multi(opcode, insn)
    Mov => lift_move(opcode, insn)
    Branch => lift_branch(opcode, insn)
    Bit => lift_bits(opcode, insn)
  }
}

///|
/// Lift a decoded Thumb (T32 encoding) instruction to BIL. The opcode is
/// looked up by its LLVM MC name; unknown opcodes raise `Unsupported`.
pub fn lift(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  match Opcode::of_name(insn.name) {
    Some(opcode) => lift_opcode(opcode, insn)
    None => raise @mc.Unsupported(insn.name)
  }
}

///|
/// Register the Thumb lifter with `@mc` for every name in
/// `target_names()`. Idempotent.
pub fn register() -> Unit {
  for target in thumb_targets {
    @mc.register_lifter(target, lift)
  }
}
