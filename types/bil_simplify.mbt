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
