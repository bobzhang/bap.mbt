///|
fn fold_unop(op : UnOp, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match eval_unop(op, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn word_is_one(word : Word) -> Bool {
  try word.to_uint64() catch {
    _ => false
  } noraise {
    value => value == 1UL
  }
}

///|
fn fold_binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp? {
  match (lhs, rhs) {
    (Int(left), Int(right)) =>
      match eval_binop(op, left, right) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    (exp, Int(word)) if word.is_zero() =>
      match op {
        Plus | Minus | Or | Xor | LShift | RShift | ARShift => Some(exp)
        _ => None
      }
    (Int(word), exp) if word.is_zero() =>
      match op {
        Plus | Or | Xor => Some(exp)
        _ => None
      }
    (exp, Int(word)) if word_is_one(word) =>
      match op {
        Times => Some(exp)
        _ => None
      }
    (Int(word), exp) if word_is_one(word) =>
      match op {
        Times => Some(exp)
        _ => None
      }
    _ => None
  }
}

///|
fn fold_cast(typ : ValueType, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match cast_word(typ, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn fold_load(
  mem : Exp,
  addr : Exp,
  endian : @bitvec.Endian,
  typ : ValueType,
) -> Exp? {
  match (mem, addr, typ) {
    (
      Store(addr=Int(store_addr), value=Int(value), endian=store_endian, ..),
      Int(load_addr),
      Imm(width),
    ) => {
      let memory = BilMemory::empty(addr_width=store_addr.width())
      match memory.store(store_addr, value, endian=store_endian) {
        Ok(stored) =>
          match stored.load(load_addr, endian~, width~) {
            Ok(word) => Some(Int(word))
            Err(_) => None
          }
        Err(_) => None
      }
    }
    _ => None
  }
}

///|
fn is_constant_exp(exp : Exp) -> Bool {
  match exp {
    Int(_) | Unknown(_) => true
    _ => false
  }
}

///|
pub fn Exp::simplify(self : Exp) -> Exp {
  match self {
    Int(_) | Var(_) | Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) => {
      let simple_mem = mem.simplify()
      let simple_addr = addr.simplify()
      match fold_load(simple_mem, simple_addr, endian, typ) {
        Some(exp) => exp
        None => Load(mem=simple_mem, addr=simple_addr, endian~, typ~)
      }
    }
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.simplify(),
        addr=addr.simplify(),
        value=value.simplify(),
        endian~,
      )
    Let(variable, value, body) => {
      let simple_value = value.simplify()
      let simple_body = body.simplify()
      if is_constant_exp(simple_value) {
        simple_body.substitute_var(variable, simple_value).simplify()
      } else {
        Let(variable, simple_value, simple_body)
      }
    }
    Cast(typ, exp) => {
      let simple = exp.simplify()
      match fold_cast(typ, simple) {
        Some(result) => result
        None => Cast(typ, simple)
      }
    }
    UnOp(op, exp) => {
      let simple = exp.simplify()
      match fold_unop(op, simple) {
        Some(result) => result
        None => UnOp(op, simple)
      }
    }
    BinOp(op, lhs, rhs) => {
      let left = lhs.simplify()
      let right = rhs.simplify()
      match fold_binop(op, left, right) {
        Some(result) => result
        None => BinOp(op, left, right)
      }
    }
    Ite(cond~, yes~, no~) => {
      let simple_cond = cond.simplify()
      let simple_yes = yes.simplify()
      let simple_no = no.simplify()
      match simple_cond {
        Int(word) => if word.is_zero() { simple_no } else { simple_yes }
        _ =>
          if simple_yes == simple_no {
            simple_yes
          } else {
            Ite(cond=simple_cond, yes=simple_yes, no=simple_no)
          }
      }
    }
  }
}

///|
pub fn Stmt::simplify(self : Stmt) -> Stmt {
  match self {
    Move(variable, exp) => Move(variable, exp.simplify())
    Jmp(exp) => Jmp(exp.simplify())
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(cond=cond.simplify(), yes=simplify_stmts(yes), no=simplify_stmts(no))
    While(cond~, body~) =>
      While(cond=cond.simplify(), body=simplify_stmts(body))
  }
}

///|
pub fn Stmt::simplify_to_list(self : Stmt) -> Array[Stmt] {
  match self.simplify() {
    If(cond=Int(word), yes~, no~) => if word.is_zero() { no } else { yes }
    While(cond=Int(word), ..) if word.is_zero() => []
    stmt => [stmt]
  }
}

///|
pub fn simplify_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  let result = []
  for stmt in stmts {
    for simple in stmt.simplify_to_list() {
      result.push(simple)
    }
  }
  result
}

///|
fn remove_live_var(live : Array[Var], variable : Var) -> Array[Var] {
  live.filter(item => item != variable)
}

///|
fn add_stmt_live_vars(live : Array[Var], stmt : Stmt) -> Unit {
  add_vars(live, stmt.free_vars())
}

///|
fn prune_dead_virtuals_loop(
  stmts : Array[Stmt],
  live_out : Array[Var],
) -> (Array[Stmt], Array[Var]) {
  let mut live = live_out.copy()
  let kept = []
  for offset in 0..<stmts.length() {
    let stmt = stmts[stmts.length() - offset - 1]
    match stmt {
      Move(variable, exp) =>
        if variable.is_virtual && !live.any(item => item == variable) {
          ()
        } else {
          live = remove_live_var(live, variable)
          add_vars(live, exp.free_vars())
          kept.push(stmt)
        }
      Jmp(exp) => {
        add_vars(live, exp.free_vars())
        kept.push(stmt)
      }
      Special(_) | CpuExn(_) => kept.push(stmt)
      If(cond~, yes~, no~) => {
        let yes_result = prune_dead_virtuals_loop(yes, live)
        let no_result = prune_dead_virtuals_loop(no, live)
        let next_live = []
        add_vars(next_live, cond.free_vars())
        add_vars(next_live, yes_result.1)
        add_vars(next_live, no_result.1)
        live = next_live
        kept.push(If(cond~, yes=yes_result.0, no=no_result.0))
      }
      While(cond~, body~) => {
        add_vars(live, cond.free_vars())
        for body_stmt in body {
          add_stmt_live_vars(live, body_stmt)
        }
        kept.push(stmt)
      }
    }
  }
  (kept.rev(), live)
}

///|
pub fn prune_dead_virtual_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  prune_dead_virtuals_loop(stmts, []).0
}

///|
pub fn optimize_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  prune_dead_virtual_stmts(simplify_stmts(stmts))
}
