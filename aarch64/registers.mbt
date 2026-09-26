// AArch64 registers as `@mc` operands, named as the LLVM AArch64
// disassembler names them (`MCRegisterInfo::getName`): `X0`..`X28`, `FP`
// (`X29`), `LR` (`X30`), `SP`, `XZR`, `W0`..`W30`, `WSP`, `WZR`.
//
// Register codes are port-local: `W<n>` is `n + 1`, `WSP` 32, `WZR` 33,
// `X<n>` (with `FP` and `LR`) is `n + 34`, `SP` 65 and `XZR` 66.

///|
/// The LLVM name of the 64-bit (`sf`) or 32-bit register `n`; register 31
/// is the stack pointer when `sp` is set and the zero register otherwise.
pub fn reg_name(sf : Bool, n : Int, sp? : Bool = false) -> String {
  match (sf, n) {
    (true, 29) => "FP"
    (true, 30) => "LR"
    (true, 31) => if sp { "SP" } else { "XZR" }
    (false, 31) => if sp { "WSP" } else { "WZR" }
    (true, n) => "X\{n}"
    (false, n) => "W\{n}"
  }
}

///|
/// The port-local code of a register (see the file header).
fn reg_code(sf : Bool, n : Int, sp : Bool) -> Int {
  match (sf, n) {
    (true, 31) => if sp { 65 } else { 66 }
    (false, 31) => if sp { 32 } else { 33 }
    (true, n) => n + 34
    (false, n) => n + 1
  }
}

///|
/// The register `n` as an `@mc` operand (see `reg_name`).
pub fn mc_reg(sf : Bool, n : Int, sp? : Bool = false) -> @mc.Op {
  Reg(name=reg_name(sf, n, sp~), code=reg_code(sf, n, sp))
}

///|
/// The 64-bit register `n` as an `@mc` operand.
pub fn mc_x(n : Int, sp? : Bool = false) -> @mc.Op {
  mc_reg(true, n, sp~)
}

///|
/// The 32-bit register `n` as an `@mc` operand.
pub fn mc_w(n : Int, sp? : Bool = false) -> @mc.Op {
  mc_reg(false, n, sp~)
}

///|
/// The assembly name of a register (`x0`, `x29`, `sp`, `wzr`, ...).
pub fn reg_asm(sf : Bool, n : Int, sp? : Bool = false) -> String {
  match (sf, n) {
    (true, 31) => if sp { "sp" } else { "xzr" }
    (false, 31) => if sp { "wsp" } else { "wzr" }
    (true, n) => "x\{n}"
    (false, n) => "w\{n}"
  }
}

///|
/// The assembly name of a condition code.
pub fn cond_asm(cond : Int) -> String {
  [
    "eq", "ne", "hs", "lo", "mi", "pl", "vs", "vc", "hi", "ls", "ge", "lt", "gt",
    "le", "al", "nv",
  ][cond & 15]
}
