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
  Reg(name~ : String, code~ : Int)
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
pub fn Op::reg(name : String, code? : Int = 0) -> Op {
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

///|
/// A decoded instruction: opcode name (LLVM MC style, e.g. `ADDiu`,
/// `ADD4`, `MOVi`), textual assembly, operands, address and size in bytes.
pub(all) struct Insn {
  name : String
  assembly : String
  ops : Array[Op]
  addr : UInt64
  size : Int
} derive(Eq, Debug)

///|
pub extend Insn with Eq::{equal, not_equal}

///|
pub extend Insn with Debug::{to_repr}

///|
pub fn Insn::create(
  name : String,
  ops : Array[Op],
  addr? : UInt64 = 0,
  size? : Int = 4,
  assembly? : String = "",
) -> Insn {
  { name, assembly, ops, addr, size, }
}

///|
pub fn Insn::op(self : Insn, index : Int) -> Op? {
  self.ops.get(index)
}

///|
/// Address of the instruction following this one.
pub fn Insn::next_addr(self : Insn) -> UInt64 {
  self.addr + self.size.to_uint64()
}

///|
/// Lifter failure, mirroring BAP's `Error.t` results from lifters.
pub(all) suberror LiftError {
  /// The opcode is not modeled by the lifter.
  Unsupported(String)
  /// The opcode is known but its operands are malformed.
  BadOperands(String)
  /// Any other lifting failure.
  Failure(String)
} derive(Debug)

///|
pub extend LiftError with Debug::{to_repr}

///|
pub fn LiftError::message(self : LiftError) -> String {
  match self {
    Unsupported(name) => "unsupported instruction: " + name
    BadOperands(name) => "bad operands for instruction: " + name
    Failure(msg) => msg
  }
}

///|
/// A lifter translates one decoded instruction into BIL.
pub type Lifter = (Insn) -> Array[@types.Stmt] raise LiftError

///|
let lifters : Map[String, Lifter] = Map([])

///|
/// Register a lifter for a target family name (e.g. `mips`, `mips64`,
/// `powerpc`, `arm`, `thumb`). Later registrations replace earlier ones,
/// so built-in registration is idempotent.
pub fn register_lifter(target : String, lifter : Lifter) -> Unit {
  lifters[target] = lifter
}

///|
pub fn find_lifter(target : String) -> Lifter? {
  lifters.get(target)
}

///|
/// Registered target family names in sorted order.
pub fn lifter_targets() -> Array[String] {
  let names = lifters.keys().collect()
  names.sort()
  names
}

///|
/// Lift an instruction with the lifter registered for `target`.
pub fn lift(target : String, insn : Insn) -> Array[@types.Stmt] raise LiftError {
  match lifters.get(target) {
    Some(lifter) => lifter(insn)
    None => raise Failure("no lifter registered for target " + target)
  }
}
