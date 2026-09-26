///|
/// Machine exceptions raised by the Primus core (upstream `Primus.Exn.t`
/// constructors spread across the machine modules).
///
/// Upstream `Primus.Exn.t` is an extensible variant; in MoonBit any
/// `Error` can be raised through a machine (see `Machine::raise_exn`), so
/// other components (e.g. a future Primus Lisp port) define their own
/// `suberror` types and register printers with `exn_add_printer`.
pub(all) suberror PrimusError {
  /// `Interpreter.Halt`: the machine was halted.
  Halt
  /// `Interpreter.Division_by_zero`.
  DivisionByZero
  /// `Interpreter.Segmentation_fault addr`.
  SegmentationFault(@types.Word)
  /// `Interpreter.Cfi_violation callsite`.
  CfiViolation(@types.Word)
  /// `Memory.Pagefault addr`.
  Pagefault(@types.Word)
  /// `Interpreter.Runtime_error msg` (also used for ill-typed programs).
  RuntimeError(String)
  /// `Env.Undefined_var var`.
  UndefinedVar(@types.Var)
  /// `Linker.Unbound_name name`.
  UnboundName(Name)
  /// `Pos.Broken_invariant`: no transition from `level` to `dst`.
  BrokenInvariant(level~ : String, dst~ : String)
  /// Raised when `fork`, `switch` or `kill` is requested while the machine
  /// is in the restricted mode (upstream uses `failwith`).
  Restricted(String)
  /// Raised when switching to a machine that is not alive.
  DeadMachine(Id)
}

///|
let exn_printers : Array[(Error) -> String?] = []

///|
/// Registers a printer for machine exceptions (upstream
/// `Primus.Exn.add_printer`). Printers registered later take precedence.
pub fn exn_add_printer(printer : (Error) -> String?) -> Unit {
  exn_printers.push(printer)
}

///|
fn primus_error_to_string(err : Error) -> String? {
  let s = match err {
    Halt => "Halt"
    DivisionByZero => "Division by zero"
    SegmentationFault(a) => "Segmentation fault at \{a.to_hex()}"
    CfiViolation(a) => "CFI violation at \{a.to_hex()}"
    Pagefault(a) => "Page fault at \{a.to_hex()}"
    RuntimeError(msg) => "Primus interpreter runtime error: \{msg}"
    UndefinedVar(v) => "undefined variable `\{v.name()}'"
    UnboundName(n) => "unbound function \{n.to_string()}"
    BrokenInvariant(level~, dst~) =>
      "Level transition - broken invariant: No transition is defined from the \{level} level to the \{dst} level"
    Restricted(op) => "\{op} in the restricted mode"
    DeadMachine(id) => "machine \{id} is not alive"
    _ => return None
  }
  Some(s)
}

///|
/// Renders a machine exception (upstream `Primus.Exn.to_string`).
pub fn exn_to_string(err : Error) -> String {
  for i = exn_printers.length() - 1; i >= 0; i = i - 1 {
    if exn_printers[i](err) is Some(s) {
      return s
    }
  }
  match primus_error_to_string(err) {
    Some(s) => s
    None => "\{err}"
  }
}

///|
/// The status of a finished machine (upstream `exit_status`).
pub enum ExitStatus {
  Normal
  Exn(Error)
}

///|
pub fn ExitStatus::to_string(self : ExitStatus) -> String {
  match self {
    Normal => "Normal"
    Exn(e) => "Exn(\{exn_to_string(e)})"
  }
}

///|
pub impl Show for ExitStatus with fn output(self, logger) {
  logger.write_string(self.to_string())
}
