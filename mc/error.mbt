///|
/// Lifter failure, mirroring BAP's `Error.t` results from lifters.
pub(all) suberror LiftError {
  /// The lifter (provider) does not model the opcode in this context.
  /// This is different from a successful empty program: a registry tries
  /// the next provider, and a caller may fall back to another lifter.
  Unsupported(opcode~ : String, target~ : String)
  /// The opcode is modeled but its operands are malformed.
  BadOperands(opcode~ : String, detail~ : String)
  /// The produced BIL is not well typed.
  IllTyped(opcode~ : String, detail~ : String)
  /// Any other lifting failure.
  Failure(String)
} derive(Debug)

///|
pub extend LiftError with Debug::{to_repr}

///|
/// A human-readable description of the error.
pub fn LiftError::message(self : LiftError) -> String {
  match self {
    Unsupported(opcode~, target~) =>
      if target == "" {
        "unsupported instruction: \{opcode}"
      } else {
        "unsupported instruction: \{opcode} (target \{target})"
      }
    BadOperands(opcode~, detail~) =>
      if detail == "" {
        "bad operands for instruction: \{opcode}"
      } else {
        "bad operands for instruction: \{opcode}: \{detail}"
      }
    IllTyped(opcode~, detail~) =>
      "ill-typed semantics for instruction: \{opcode}: \{detail}"
    Failure(msg) => msg
  }
}

///|
/// Whether the error is `Unsupported`.
pub fn LiftError::is_unsupported(self : LiftError) -> Bool {
  self is Unsupported(..)
}
