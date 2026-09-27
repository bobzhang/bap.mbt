///|
/// Knowledge base conflicts (`Knowledge.Conflict` / `conflict`).
///
/// Upstream `conflict` is the extensible `exn` type and a diverging
/// knowledge computation evaluates to one of its values. In MoonBit the
/// knowledge computations are direct-style functions that `raise`, so any
/// `Error` plays the role of a conflict; this suberror enumerates the
/// conflicts raised by the knowledge base itself. Users may raise their own
/// `suberror`s from promises and they will propagate through `collect` and
/// `run` exactly like upstream user-defined conflicts.
pub(all) suberror Conflict {
  /// `Empty slot`: raised by `require`/`-->?`/`.![]` when the property is
  /// empty. Rejects the enclosing `with_empty` scope (e.g. a promise).
  Empty(Name)
  /// `Reject`: raised by `reject`, `guard`, `proceed`, `on`, `unless`.
  Reject
  /// `Non_monotonic_update`: `provide` tried to store a value that is not
  /// joinable with the value already stored in the slot.
  NonMonotonicUpdate(slot~ : Name, repr~ : String, error~ : String)
  /// `Not_a_package`, raised by `import`.
  NotAPackage(String)
  /// `Not_a_symbol`, raised by `import`.
  NotASymbol(Name)
  /// `Import (sym, sym')`, raised by a strict `import` that would shadow.
  ImportConflict(Name, Name)
  /// A conflicting join of two knowledge values (`Value.join`), or a
  /// domain join error.
  JoinConflict(String)
  /// A generic failure, e.g., a legacy `Result`-based provider error or a
  /// corrupted serialized knowledge base.
  Failure(String)
} derive(Debug)

///|
pub extend Conflict with Debug::{to_repr}

///|
/// `Conflict.to_string`: a textual representation of any knowledge
/// conflict (including user-defined errors).
pub fn Conflict::to_string(err : Error) -> String {
  match err {
    Empty(slot) => "empty value for property \{slot.show()}"
    Reject => "rejected"
    NonMonotonicUpdate(slot~, repr~, error~) =>
      "Unable to update the slot \{slot.show()} of \{repr},\n\{error}"
    NotAPackage(pkg) => "not a package: \{pkg}"
    NotASymbol(sym) => "not a symbol: \{sym.show()}"
    ImportConflict(sym, other) =>
      "import conflict: \{sym.show()} would shadow \{other.show()}"
    JoinConflict(msg) => msg
    Failure(msg) => msg
    other => "\{other}"
  }
}

///|
/// `reject ()`: rejects the enclosing `with_empty` scope (a promise or a
/// proposal), making it evaluate to the empty value.
pub fn[T] reject() -> T raise Conflict {
  raise Reject
}

///|
/// `guard cnd` (`guard` is a MoonBit keyword): rejects the rest of the computation unless `cnd` holds.
pub fn guard_(cnd : Bool) -> Unit raise Conflict {
  if !cnd {
    raise Reject
  }
}

///|
/// `proceed ~unless:cnd`: rejects the computation if `cnd` holds.
pub fn proceed(unless~ : Bool) -> Unit raise Conflict {
  guard_(!unless)
}

///|
/// `on cnd x`: evaluates `x` if `cnd`, otherwise rejects.
pub fn on(cnd : Bool, yes : () -> Unit raise) -> Unit raise {
  if cnd {
    yes()
  } else {
    raise Reject
  }
}

///|
/// `unless cnd x`: evaluates `x` if `not cnd`, otherwise rejects.
pub fn unless(cnd : Bool, no : () -> Unit raise) -> Unit raise {
  if cnd {
    raise Reject
  } else {
    no()
  }
}

///|
/// `true` iff `err` rejects a `with_empty` scope (`Empty _ | Reject`).
fn is_rejection(err : Error) -> Bool {
  err is (Empty(_) | Reject)
}
