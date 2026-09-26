// Port of `plugins/thumb/thumb_main.ml`: operand decoding and dispatch.
//
// Upstream answers `Insn.empty` (no semantics) for unknown opcodes, operand
// shapes it does not recognise, and exceptions raised while decoding
// operands. This port reports those cases as errors instead: `Unsupported`
// for opcodes without upstream semantics and `BadOperands` for operand
// shapes (or predicate immediates) upstream rejects.

///|
fn bad(insn : @mc.Insn) -> @mc.LiftError {
  @mc.BadOperands(opcode=insn.name, detail="")
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
    (TSTMIA | TLDMIA_UPD, _) =>
      raise @mc.Unsupported(opcode=insn.name, target="thumb")
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
    // LLVM's `tBL` has three operands (the predicate and the target);
    // upstream matches a fourth one
    (TBL, [_, _, Imm(dst)] | [_, _, Imm(dst), _])
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
    None => raise @mc.Unsupported(opcode=insn.name, target="thumb")
  }
}

///|
/// Name of the provider installed by `register`.
pub let provider_name : String = "thumb"

///|
/// Whether the provider applies to `ctx`: 32-bit targets of the ARM family
/// decoded as Thumb (`llvm-thumb`) instructions, as upstream
/// `thumb_main.ml` guards on `Theory.Label.encoding`. Upstream semantics
/// always access memory in little-endian order (`loadw b0`), so big-endian
/// targets are rejected explicitly.
pub fn accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::arm_family()) &&
  ctx.target.bits() == 32 &&
  !(ctx.target.endianness() is BigEndian) &&
  ctx.encoding == @core_theory.Language::llvm_t32()
}

///|
/// The encoding of the destination of a branch when it is statically known
/// and may differ from Thumb (upstream `Thumb_branch.switch_encoding`):
///
/// - `tBX pc` jumps to `pc + 4` (see `dest_encoding`: ARM code, since Thumb
///   instructions are halfword aligned);
/// - `tBLXi` jumps to `pc + 4 + imm`, whose bit 0 selects the encoding
///   (as upstream `blxi`; it is clear for well-formed `blx imm`, i.e. ARM);
/// - `tBL` stays in Thumb.
///
/// Register branches (`tBX rm`, `tBLXr rm`) decide the encoding at run
/// time from bit 0 of the register, so it is not known statically.
pub fn branch_dest_encoding(
  opcode : Opcode,
  insn : @mc.Insn,
) -> @core_theory.Language? {
  let pc = addr32(insn)
  match (opcode, insn.ops) {
    (TBX, [Reg(name~, ..), ..]) if is_pc(reg(name)) =>
      Some(dest_encoding(pc_offset(pc, 0).reinterpret_as_uint().to_uint64()))
    (TBLXi, [_, _, Imm(dst), ..]) =>
      Some(
        dest_encoding(pc_offset(pc, imm(dst)).reinterpret_as_uint().to_uint64()),
      )
    (TBL, _) => Some(@core_theory.Language::llvm_t32())
    _ => None
  }
}

///|
/// Lift in a context. `t2IT` lifts to an empty program. Other opcodes
/// outside the Thumb-1 set (including all Thumb-2 `t2*` opcodes except
/// `t2LDRpci`) raise `Unsupported`, so that a
/// registry falls through to the ARM provider. The result records the
/// destination encoding of interworking branches (see
/// `branch_dest_encoding`).
pub fn lift_in_context(
  ctx : @mc.Context,
  insn : @mc.Insn,
) -> @mc.Lifted raise @mc.LiftError {
  // `t2IT` itself has no effect: the decoder predicates the instructions
  // of the block with its conditions
  if insn.name == "t2IT" {
    return @mc.Lifted::create([])
  }
  guard Opcode::of_name(insn.name) is Some(opcode) else {
    raise @mc.Unsupported(opcode=insn.name, target=ctx.target.to_string())
  }
  let bil = lift_opcode(opcode, insn) catch {
    Unsupported(opcode~, ..) =>
      raise @mc.Unsupported(opcode~, target=ctx.target.to_string())
    err => raise err
  }
  @mc.Lifted::create(bil, dest_encoding?=branch_dest_encoding(opcode, insn))
}

///|
/// The Thumb lifter provider (see `accepts` and `lift_in_context`).
pub fn provider() -> @mc.Provider {
  @mc.Provider::create(provider_name, accepts~, lift=lift_in_context)
}

///|
/// Register the Thumb provider with `registry` (the global `@mc` registry
/// by default). Idempotent: the provider is replaced by name. Register it
/// before the ARM provider so that Thumb-1 opcodes are lifted here and
/// Thumb-2 ones fall through to ARM.
pub fn register(registry? : @mc.Registry = @mc.Registry::global()) -> Unit {
  registry.register(provider())
}
