// Port of `plugins/systemz/systemz_lifter.ml` and the lifter-facing part of
// `plugins/systemz/systemz_main.ml`.
//
// Upstream is a tutorial-sized lifter that only models `LR` (load
// register); the port adds the other general-register moves without
// condition codes (`LGR`, `LGFR`, `LLGFR`). Semantics are emitted as BIL instead of Core Theory
// denotations. The rest of `systemz_main` (target, encoding, loader and
// `Arch.t` mapping) is covered by `@core_theory.Target::systemz`/`systemz9`
// and the `llvm-systemz` encoding (`@core_theory.Language::llvm_systemz`)
// the provider accepts.
//
// Upstream answers `Insn.empty` for unknown opcodes and for operands that
// are not registers; this port reports these as `Unsupported` and
// `BadOperands` respectively.

///|
/// Number of SystemZ general-purpose registers (`R0`..`R15`).
let gpr_count : Int32 = 16

///|
/// The 64-bit general-purpose register `R<index>` (upstream
/// `Bap_systemz_target.gpr`), or `None` when `index` is out of range.
pub fn gpr(index : Int32) -> @types.Var? {
  if index >= 0 && index < gpr_count {
    Some(@types.Var::new(name="R\{index}", typ=Imm(64)))
  } else {
    None
  }
}

///|
/// Upstream `regnum`: `Scanf.sscanf s "R%d"`, i.e. an `R` followed by a
/// decimal register number; any trailing suffix (LLVM spells 32-bit
/// halves `R1L`, 64-bit registers `R1D`) is ignored.
pub fn regnum(name : String) -> Int32? {
  guard name is ['R', .. rest] else { None }
  let mut n = 0
  let mut digits = 0
  for c in rest {
    if c >= '0' && c <= '9' && digits < 9 {
      n = n * 10 + (c.to_int() - '0'.to_int())
      digits += 1
    } else {
      break
    }
  }
  if digits == 0 {
    None
  } else {
    Some(n)
  }
}

///|
/// `require_gpr insn pos`: the `pos`th operand must be a register naming a
/// general-purpose register.
fn require_gpr(insn : @mc.Insn, pos : Int32) -> @types.Var raise @mc.LiftError {
  guard insn.op(pos) is Some(Reg(name~, ..)) &&
    regnum(name) is Some(n) &&
    gpr(n) is Some(r) else {
    raise @mc.BadOperands(
      opcode=insn.name,
      detail="operand \{pos} is not a general-purpose register",
    )
  }
  r
}

///|
/// `LR rd, rs`: load the low 32 bits of `rs` into the low half of `rd`,
/// keeping the high half of `rd`.
fn lr(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  let rd = require_gpr(insn, 0)
  let rs = require_gpr(insn, 1)
  [
    Move(
      rd,
      Concat(
        high=Cast(kind=High, width=32, exp=Var(rd)),
        low=Cast(kind=Low, width=32, exp=Var(rs)),
      ),
    ),
  ]
}

///|
/// `LGR rd, rs`: copy the 64-bit `rs` into `rd`.
///
/// port: not modeled upstream.
fn lgr(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  let rd = require_gpr(insn, 0)
  let rs = require_gpr(insn, 1)
  [Move(rd, Var(rs))]
}

///|
/// `LGFR rd, rs` / `LLGFR rd, rs`: load the low 32 bits of `rs` into `rd`,
/// sign- (`kind=Signed`) or zero-extended (`kind=Unsigned`).
///
/// port: not modeled upstream.
fn load_extended(
  insn : @mc.Insn,
  kind : @types.CastKind,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let rd = require_gpr(insn, 0)
  let rs = require_gpr(insn, 1)
  [Move(rd, Cast(kind~, width=64, exp=Cast(kind=Low, width=32, exp=Var(rs))))]
}

///|
/// Lift a decoded SystemZ instruction to BIL.
pub fn lift(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  match insn.name {
    "LR" => lr(insn)
    "LGR" => lgr(insn)
    "LGFR" => load_extended(insn, Signed)
    "LLGFR" => load_extended(insn, Unsigned)
    _ => raise @mc.Unsupported(opcode=insn.name, target="systemz")
  }
}

///|
/// Name of the provider installed by `register`.
pub let provider_name : String = "systemz"

///|
/// Whether the provider applies to `ctx`: SystemZ targets decoded with the
/// `llvm-systemz` encoding.
pub fn accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::systemz()) &&
  (
    ctx.encoding.is_unknown() ||
    ctx.encoding == @core_theory.Language::llvm_systemz()
  )
}

///|
/// Lift in a context: unknown opcodes raise `Unsupported`.
pub fn lift_in_context(
  ctx : @mc.Context,
  insn : @mc.Insn,
) -> @mc.Lifted raise @mc.LiftError {
  let bil = lift(insn) catch {
    Unsupported(opcode~, ..) =>
      raise @mc.Unsupported(opcode~, target=ctx.target.to_string())
    err => raise err
  }
  @mc.Lifted::of_bil(bil)
}

///|
/// The SystemZ lifter provider (see `accepts` and `lift_in_context`).
pub fn provider() -> @mc.Provider {
  @mc.Provider::create(provider_name, accepts~, lift=lift_in_context)
}

///|
/// Register the SystemZ provider with `registry` (the global `@mc`
/// registry by default). Idempotent: the provider is replaced by name.
pub fn register(registry~ : @mc.Registry = @mc.Registry::global()) -> Unit {
  registry.register(provider())
}
