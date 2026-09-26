// Port of `plugins/systemz/systemz_lifter.ml` and the lifter-facing part of
// `plugins/systemz/systemz_main.ml`.
//
// Upstream is a tutorial-sized lifter that only models `LR` (load
// register). Semantics are emitted as BIL instead of Core Theory
// denotations. The rest of `systemz_main` (target, encoding, loader and
// `Arch.t` mapping) is covered by `@core_theory.Target::systemz`/`systemz9`
// and the `llvm-systemz` encoding name used for registration here.
//
// Upstream answers `Insn.empty` for unknown opcodes and for operands that
// are not registers; the shared `@mc.Lifter` contract reports these as
// `Unsupported` and `BadOperands` respectively.

///|
/// Number of SystemZ general-purpose registers (`R0`..`R15`).
let gpr_count : Int = 16

///|
/// Target and encoding names this lifter is registered for.
let systemz_targets : ReadOnlyArray[String] = [
  "systemz", "systemz9", "llvm-systemz",
]

///|
/// Target names `register` installs the SystemZ lifter under.
pub fn target_names() -> Array[String] {
  [..systemz_targets]
}

///|
/// The 64-bit general-purpose register `R<index>` (upstream
/// `Bap_systemz_target.gpr`), or `None` when `index` is out of range.
pub fn gpr(index : Int) -> @types.Var? {
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
pub fn regnum(name : String) -> Int? {
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
fn require_gpr(insn : @mc.Insn, pos : Int) -> @types.Var raise @mc.LiftError {
  guard insn.op(pos) is Some(Reg(name~, ..)) &&
    regnum(name) is Some(n) &&
    gpr(n) is Some(r) else {
    raise @mc.BadOperands(insn.name)
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
/// Lift a decoded SystemZ instruction to BIL.
pub fn lift(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  match insn.name {
    "LR" => lr(insn)
    _ => raise @mc.Unsupported(insn.name)
  }
}

///|
/// Register the SystemZ lifter with `@mc` for every name in
/// `target_names()`. Idempotent.
pub fn register() -> Unit {
  for target in systemz_targets {
    @mc.register_lifter(target, lift)
  }
}
