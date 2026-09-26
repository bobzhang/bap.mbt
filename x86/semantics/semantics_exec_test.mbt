// Execution of lifted BIL over the machine state of full registers
// (`RAX`..`R15` or `EAX`..`EDI`, `YMM0`..): the lifters resolve their
// sub-registers (`@mc.resolve_x86_subregisters`), so a lifter that still
// reads or writes a sub-register variable fails with an unbound or
// unexpected variable.

///|
priv suberror ExecError {
  ExecError(String)
}

///|
/// The machine state during execution.
priv struct Machine {
  values : Map[String, @types.BilValue]
  /// variables whose value is undefined
  undefined : Map[String, Unit]
  mut jump : UInt64?
  mut exn : Int?
  mut fuel : Int
}

///|
/// Evaluate `e`; `None` when the value is undefined (it depends on an
/// `unknown` expression or on an undefined variable).
fn Machine::eval(self : Machine, e : @types.Exp) -> @types.BilValue? raise {
  match e.eval_value(self.values) {
    Ok(v) => Some(v)
    Err(reason) =>
      if reason.has_prefix("unknown expression") ||
        e.free_vars().iter().any(v => self.undefined.contains(v.name)) {
        None
      } else {
        raise ExecError("\{reason} in \{e.to_string()}")
      }
  }
}

///|
fn Machine::eval_word(self : Machine, e : @types.Exp) -> @types.Word? raise {
  match self.eval(e) {
    Some(BilWord(w)) => Some(w)
    Some(BilMem(_)) => raise ExecError("expected a word: \{e.to_string()}")
    None => None
  }
}

///|
fn fits(v : @types.Var, value : @types.BilValue) -> Bool {
  match (v.typ, value) {
    (Imm(w), BilWord(x)) => x.width() == w
    (Mem(..), BilMem(_)) => true
    _ => false
  }
}

///|
/// Execute `stmts`; `false` when execution stopped (jump or exception).
fn Machine::exec(self : Machine, stmts : Array[@types.Stmt]) -> Bool raise {
  for stmt in stmts {
    self.fuel -= 1
    if self.fuel < 0 {
      raise ExecError("fuel exhausted")
    }
    match stmt {
      Move(v, e) =>
        match self.eval(e) {
          Some(value) => {
            if !fits(v, value) {
              raise ExecError("ill-typed assignment \{stmt.to_string()}")
            }
            self.values[v.name] = value
            self.undefined.remove(v.name)
          }
          None => {
            self.values.remove(v.name)
            self.undefined[v.name] = ()
          }
        }
      Jmp(e) =>
        match self.eval_word(e) {
          Some(w) => {
            self.jump = Some(w.to_uint64())
            return false
          }
          None => raise ExecError("jump to an undefined address")
        }
      CpuExn(n) => {
        self.exn = Some(n)
        return false
      }
      Special(_) => ()
      If(cond~, yes~, no~) =>
        match self.eval_word(cond) {
          Some(w) =>
            if !self.exec(if w.is_zero() { no } else { yes }) {
              return false
            }
          None =>
            raise ExecError(
              "branch on an undefined condition \{cond.to_string()}",
            )
        }
      While(cond~, body~) =>
        while true {
          match self.eval_word(cond) {
            Some(w) =>
              if w.is_zero() {
                break
              } else if !self.exec(body) {
                return false
              }
            None => raise ExecError("loop on an undefined condition")
          }
        }
    }
  }
  true
}

///|
fn is_rep(code : Bytes) -> Bool {
  for b in code {
    match b {
      b'\xf2' | b'\xf3' => return true
      b'\x66' | b'\x67' | b'\x2e' | b'\x3e' | b'\x26' | b'\x36' => continue
      b'\x40'..=b'\x4f' => continue
      _ => return false
    }
  }
  false
}

///|
/// Run the lifted semantics of `c` from its initial state; REP string
/// instructions that jump back to themselves are executed again.
fn run_case(c : Case, stmts : Array[@types.Stmt]) -> Machine raise {
  let m : Machine = {
    values: initial_state(c),
    undefined: Map([]),
    jump: None,
    exn: None,
    fuel: 100000,
  }
  for _ in 0..<64 {
    m.jump = None
    m.exec(stmts) |> ignore
    guard m.exn is None && m.jump == Some(CODE) && is_rep(c.code) else { break }
  }
  m
}
