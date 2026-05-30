///|
pub fn[A] Exp::fold(self : Exp, init : A, f : (A, Exp) -> A) -> A {
  let acc = f(init, self)
  match self {
    Int(_) | Var(_) | Unknown(_) => acc
    Load(mem~, addr~, ..) => addr.fold(mem.fold(acc, f), f)
    Store(mem~, addr~, value~, ..) =>
      value.fold(addr.fold(mem.fold(acc, f), f), f)
    Let(_, value, body) => body.fold(value.fold(acc, f), f)
    Cast(exp~, ..) | UnOp(_, exp) | Extract(exp~, ..) => exp.fold(acc, f)
    Concat(high~, low~) => low.fold(high.fold(acc, f), f)
    BinOp(_, lhs, rhs) => rhs.fold(lhs.fold(acc, f), f)
    Ite(cond~, yes~, no~) => no.fold(yes.fold(cond.fold(acc, f), f), f)
  }
}

///|
pub fn Exp::find(self : Exp, predicate : (Exp) -> Bool) -> Exp? {
  if predicate(self) {
    Some(self)
  } else {
    match self {
      Int(_) | Var(_) | Unknown(_) => None
      Load(mem~, addr~, ..) =>
        match mem.find(predicate) {
          Some(exp) => Some(exp)
          None => addr.find(predicate)
        }
      Store(mem~, addr~, value~, ..) =>
        match mem.find(predicate) {
          Some(exp) => Some(exp)
          None =>
            match addr.find(predicate) {
              Some(exp) => Some(exp)
              None => value.find(predicate)
            }
        }
      Let(_, value, body) =>
        match value.find(predicate) {
          Some(exp) => Some(exp)
          None => body.find(predicate)
        }
      Cast(exp~, ..) | UnOp(_, exp) | Extract(exp~, ..) => exp.find(predicate)
      Concat(high~, low~) =>
        match high.find(predicate) {
          Some(exp) => Some(exp)
          None => low.find(predicate)
        }
      BinOp(_, lhs, rhs) =>
        match lhs.find(predicate) {
          Some(exp) => Some(exp)
          None => rhs.find(predicate)
        }
      Ite(cond~, yes~, no~) =>
        match cond.find(predicate) {
          Some(exp) => Some(exp)
          None =>
            match yes.find(predicate) {
              Some(exp) => Some(exp)
              None => no.find(predicate)
            }
        }
    }
  }
}

///|
pub fn Exp::exists(self : Exp, predicate : (Exp) -> Bool) -> Bool {
  self.find(predicate) is Some(_)
}

///|
pub fn Exp::map(self : Exp, f : (Exp) -> Exp) -> Exp {
  let mapped = match self {
    Int(_) | Var(_) | Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=mem.map(f), addr=addr.map(f), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=mem.map(f), addr=addr.map(f), value=value.map(f), endian~)
    Let(variable, value, body) => Let(variable, value.map(f), body.map(f))
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=exp.map(f))
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=exp.map(f))
    Concat(high~, low~) => Concat(high=high.map(f), low=low.map(f))
    UnOp(op, exp) => UnOp(op, exp.map(f))
    BinOp(op, lhs, rhs) => BinOp(op, lhs.map(f), rhs.map(f))
    Ite(cond~, yes~, no~) => Ite(cond=cond.map(f), yes=yes.map(f), no=no.map(f))
  }
  f(mapped)
}

///|
pub fn[A] Stmt::fold(self : Stmt, init : A, f : (A, Stmt) -> A) -> A {
  let acc = f(init, self)
  match self {
    If(yes~, no~, ..) => fold(no, fold(yes, acc, f), f)
    While(body~, ..) => fold(body, acc, f)
    Move(_) | Jmp(_) | Special(_) | CpuExn(_) => acc
  }
}

///|
pub fn[A] fold(stmts : Array[Stmt], init : A, f : (A, Stmt) -> A) -> A {
  let mut acc = init
  for stmt in stmts {
    acc = stmt.fold(acc, f)
  }
  acc
}

///|
pub fn[A] Stmt::fold_exps(self : Stmt, init : A, f : (A, Exp) -> A) -> A {
  match self {
    Move(_, rhs) | Jmp(rhs) => rhs.fold(init, f)
    Special(_) | CpuExn(_) => init
    If(cond~, yes~, no~) =>
      fold_exps(no, fold_exps(yes, cond.fold(init, f), f), f)
    While(cond~, body~) => fold_exps(body, cond.fold(init, f), f)
  }
}

///|
pub fn[A] fold_exps(stmts : Array[Stmt], init : A, f : (A, Exp) -> A) -> A {
  let mut acc = init
  for stmt in stmts {
    acc = stmt.fold_exps(acc, f)
  }
  acc
}

///|
pub fn Stmt::find(self : Stmt, predicate : (Stmt) -> Bool) -> Stmt? {
  if predicate(self) {
    Some(self)
  } else {
    match self {
      If(yes~, no~, ..) =>
        match find_stmt(yes, predicate) {
          Some(stmt) => Some(stmt)
          None => find_stmt(no, predicate)
        }
      While(body~, ..) => find_stmt(body, predicate)
      Move(_) | Jmp(_) | Special(_) | CpuExn(_) => None
    }
  }
}

///|
pub fn find_stmt(stmts : Array[Stmt], predicate : (Stmt) -> Bool) -> Stmt? {
  for stmt in stmts {
    match stmt.find(predicate) {
      Some(found) => return Some(found)
      None => ()
    }
  }
  None
}

///|
pub fn Stmt::exists(self : Stmt, predicate : (Stmt) -> Bool) -> Bool {
  self.find(predicate) is Some(_)
}

///|
pub fn exists_stmt(stmts : Array[Stmt], predicate : (Stmt) -> Bool) -> Bool {
  find_stmt(stmts, predicate) is Some(_)
}

///|
pub fn Stmt::find_exp(self : Stmt, predicate : (Exp) -> Bool) -> Exp? {
  match self {
    Move(_, rhs) | Jmp(rhs) => rhs.find(predicate)
    Special(_) | CpuExn(_) => None
    If(cond~, yes~, no~) =>
      match cond.find(predicate) {
        Some(exp) => Some(exp)
        None =>
          match find_exp(yes, predicate) {
            Some(exp) => Some(exp)
            None => find_exp(no, predicate)
          }
      }
    While(cond~, body~) =>
      match cond.find(predicate) {
        Some(exp) => Some(exp)
        None => find_exp(body, predicate)
      }
  }
}

///|
pub fn find_exp(stmts : Array[Stmt], predicate : (Exp) -> Bool) -> Exp? {
  for stmt in stmts {
    match stmt.find_exp(predicate) {
      Some(found) => return Some(found)
      None => ()
    }
  }
  None
}

///|
pub fn Stmt::exists_exp(self : Stmt, predicate : (Exp) -> Bool) -> Bool {
  self.find_exp(predicate) is Some(_)
}

///|
pub fn exists_exp(stmts : Array[Stmt], predicate : (Exp) -> Bool) -> Bool {
  find_exp(stmts, predicate) is Some(_)
}

///|
pub fn Stmt::map_exps(self : Stmt, f : (Exp) -> Exp) -> Stmt {
  match self {
    Move(lhs, rhs) => Move(lhs, rhs.map(f))
    Jmp(exp) => Jmp(exp.map(f))
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(cond=cond.map(f), yes=map_exps(yes, f), no=map_exps(no, f))
    While(cond~, body~) => While(cond=cond.map(f), body=map_exps(body, f))
  }
}

///|
pub fn map_exps(stmts : Array[Stmt], f : (Exp) -> Exp) -> Array[Stmt] {
  [
    for stmt in stmts => stmt.map_exps(f)
  ]
}
