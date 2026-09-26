// Execution of lifted BIL over the canonical machine state.

///|
/// Sub-register variables of the lifters (the Basic lifter models `EAX`,
/// `AL`, `XMM0`, ... as separate variables): name -> (full register, lo,
/// hi). Writes of 32-bit registers in 64-bit mode zero-extend into the
/// full register (Intel SDM 3.4.1.1), other writes merge.
fn alias_table(mode : Int) -> Map[String, (String, Int, Int)] {
  let table : Map[String, (String, Int, Int)] = Map([])
  let names : Array[(String, String, String, String)] = [
    ("EAX", "AX", "AL", "AH"),
    ("ECX", "CX", "CL", "CH"),
    ("EDX", "DX", "DL", "DH"),
    ("EBX", "BX", "BL", "BH"),
    ("ESP", "SP", "SPL", ""),
    ("EBP", "BP", "BPL", ""),
    ("ESI", "SI", "SIL", ""),
    ("EDI", "DI", "DIL", ""),
  ]
  for i, base in gpr_names(mode) {
    let (d, w, b, h) = if i < 8 {
      names[i]
    } else {
      ("R\{i}D", "R\{i}W", "R\{i}B", "")
    }
    if mode == 64 {
      table[d] = (base, 0, 31)
      if i >= 8 {
        table["R\{i}L"] = (base, 0, 7)
      }
    }
    table[w] = (base, 0, 15)
    if mode == 64 || i < 4 {
      table[b] = (base, 0, 7)
    }
    if h != "" {
      table[h] = (base, 8, 15)
    }
  }
  for i in 0..<nregs(mode) {
    table["XMM\{i}"] = ("YMM\{i}", 0, 127)
  }
  table
}

///|
fn var_width(v : @types.Var) -> Int {
  match v.typ {
    Imm(w) => w
    Mem(..) => 0
  }
}

///|
fn full_width(mode : Int, base : String) -> Int {
  if base.has_prefix("YMM") {
    256
  } else {
    mode
  }
}

///|
fn full_var(mode : Int, base : String) -> @types.Var {
  @types.Var::create(base, Imm(full_width(mode, base)))
}

///|
fn norm_exp(
  mode : Int,
  table : Map[String, (String, Int, Int)],
  e : @types.Exp,
) -> @types.Exp {
  let n = x => norm_exp(mode, table, x)
  match e {
    Var(v) =>
      match table.get(v.name) {
        Some((base, lo, hi)) if var_width(v) == hi - lo + 1 =>
          Extract(hi~, lo~, exp=Var(full_var(mode, base)))
        _ => e
      }
    Int(_) | Unknown(_) => e
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=n(mem), addr=n(addr), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=n(mem), addr=n(addr), value=n(value), endian~)
    Let(v, x, y) => Let(v, n(x), n(y))
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=n(exp))
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=n(exp))
    Concat(high~, low~) => Concat(high=n(high), low=n(low))
    UnOp(op, x) => UnOp(op, n(x))
    BinOp(op, x, y) => BinOp(op, n(x), n(y))
    Ite(cond~, yes~, no~) => Ite(cond=n(cond), yes=n(yes), no=n(no))
  }
}

///|
/// Rewrite sub-register reads and writes onto the full registers.
fn normalize(
  mode : Int,
  table : Map[String, (String, Int, Int)],
  stmts : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let n = x => norm_exp(mode, table, x)
  stmts.map(s => {
    match s {
      Move(v, e) =>
        match table.get(v.name) {
          Some((base, lo, hi)) if var_width(v) == hi - lo + 1 => {
            let bv = full_var(mode, base)
            let width = full_width(mode, base)
            let e = n(e)
            if mode == 64 && lo == 0 && hi == 31 && width == 64 {
              Move(bv, Cast(kind=Unsigned, width=64, exp=e))
            } else {
              let mut value = e
              if lo > 0 {
                value = Concat(
                  high=value,
                  low=Extract(hi=lo - 1, lo=0, exp=Var(bv)),
                )
              }
              if hi < width - 1 {
                value = Concat(
                  high=Extract(hi=width - 1, lo=hi + 1, exp=Var(bv)),
                  low=value,
                )
              }
              Move(bv, value)
            }
          }
          _ => Move(v, n(e))
        }
      Jmp(e) => Jmp(n(e))
      If(cond~, yes~, no~) =>
        If(
          cond=n(cond),
          yes=normalize(mode, table, yes),
          no=normalize(mode, table, no),
        )
      While(cond~, body~) =>
        While(cond=n(cond), body=normalize(mode, table, body))
      s => s
    }
  })
}

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
  let table = alias_table(c.mode)
  let stmts = normalize(c.mode, table, stmts)
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
