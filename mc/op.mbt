// Shared machine-code instruction representation used by the architecture
// lifters. It mirrors the operand model of BAP's `Disassembly_expert.Basic`
// (`Op.Reg`/`Op.Imm`/`Op.Fmm`) so that lifters ported from upstream plugins
// can be driven by any decoder (the built-in Basic decoder, fixtures, or a
// future native backend) without depending on the `project` package.

///|
/// A decoded machine-code operand.
pub(all) enum Op {
  /// Register operand with its backend-specific name (LLVM MC style, e.g.
  /// `R0`, `ZERO_64`, `X1`) and numeric code (`0` when unknown).
  Reg(name~ : String, code~ : Int32)
  /// Integer immediate.
  Imm(Int64)
  /// Floating-point immediate.
  Fmm(Double)
} derive(Eq, Debug)

///|
pub extend Op with Eq::{equal, not_equal}

///|
pub extend Op with Debug::{to_repr}

///|
pub fn Op::reg(name : String, code~ : Int32 = 0) -> Op {
  Reg(name~, code~)
}

///|
pub fn Op::reg_name(self : Op) -> String? {
  match self {
    Reg(name~, ..) => Some(name)
    _ => None
  }
}

///|
pub fn Op::imm_value(self : Op) -> Int64? {
  match self {
    Imm(value) => Some(value)
    _ => None
  }
}

///|
pub fn Op::to_string(self : Op) -> String {
  match self {
    Reg(name~, ..) => name
    Imm(value) => "0x" + value.to_string(radix=16)
    Fmm(value) => value.to_string()
  }
}

///|
pub extend Op with Show::{output}

///|
pub impl Show for Op with fn output(self, logger) {
  logger.write_string(self.to_string())
}
