///|
fn add_var(vars : Array[Var], variable : Var) -> Unit {
  if !vars.any(item => item == variable) {
    vars.push(variable)
  }
}

///|
fn add_vars(vars : Array[Var], more : Array[Var]) -> Unit {
  for variable in more {
    add_var(vars, variable)
  }
}

///|
pub fn Exp::free_vars(self : Exp) -> Array[Var] {
  let vars = []
  match self {
    Int(_) | Unknown(_) => ()
    Var(variable) => add_var(vars, variable)
    Load(mem~, addr~, ..) => {
      add_vars(vars, mem.free_vars())
      add_vars(vars, addr.free_vars())
    }
    Store(mem~, addr~, value~, ..) => {
      add_vars(vars, mem.free_vars())
      add_vars(vars, addr.free_vars())
      add_vars(vars, value.free_vars())
    }
    Let(variable, value, body) => {
      add_vars(vars, value.free_vars())
      for item in body.free_vars() {
        if item != variable {
          add_var(vars, item)
        }
      }
    }
    Cast(_, exp) | UnOp(_, exp) => add_vars(vars, exp.free_vars())
    BinOp(_, lhs, rhs) => {
      add_vars(vars, lhs.free_vars())
      add_vars(vars, rhs.free_vars())
    }
    Ite(cond~, yes~, no~) => {
      add_vars(vars, cond.free_vars())
      add_vars(vars, yes.free_vars())
      add_vars(vars, no.free_vars())
    }
  }
  vars
}

///|
pub fn Exp::substitute(self : Exp, target : Exp, replacement : Exp) -> Exp {
  if self == target {
    replacement
  } else {
    match self {
      Int(_) | Var(_) | Unknown(_) => self
      Load(mem~, addr~, endian~, typ~) =>
        Load(
          mem=mem.substitute(target, replacement),
          addr=addr.substitute(target, replacement),
          endian~,
          typ~,
        )
      Store(mem~, addr~, value~, endian~) =>
        Store(
          mem=mem.substitute(target, replacement),
          addr=addr.substitute(target, replacement),
          value=value.substitute(target, replacement),
          endian~,
        )
      Let(variable, value, body) =>
        Let(
          variable,
          value.substitute(target, replacement),
          body.substitute(target, replacement),
        )
      Cast(typ, exp) => Cast(typ, exp.substitute(target, replacement))
      UnOp(op, exp) => UnOp(op, exp.substitute(target, replacement))
      BinOp(op, lhs, rhs) =>
        BinOp(
          op,
          lhs.substitute(target, replacement),
          rhs.substitute(target, replacement),
        )
      Ite(cond~, yes~, no~) =>
        Ite(
          cond=cond.substitute(target, replacement),
          yes=yes.substitute(target, replacement),
          no=no.substitute(target, replacement),
        )
    }
  }
}

///|
pub fn Exp::substitute_var(
  self : Exp,
  variable : Var,
  replacement : Exp,
) -> Exp {
  match self {
    Var(current) if current == variable => replacement
    Let(bound, value, body) => {
      let new_value = value.substitute_var(variable, replacement)
      if bound == variable {
        Let(bound, new_value, body)
      } else {
        Let(bound, new_value, body.substitute_var(variable, replacement))
      }
    }
    _ => self.substitute(Var(variable), replacement)
  }
}

///|
fn result_word(value : Word) -> Result[Word, String] {
  Ok(value)
}

///|
fn word_error() -> Result[Word, String] {
  Err("bitvector operation failed")
}

///|
fn eval_unop(op : UnOp, value : Word) -> Result[Word, String] {
  match op {
    Not => result_word(value.lnot())
    Neg => result_word(value.neg())
  }
}

///|
fn shift_amount(value : Word) -> Result[Int, String] {
  try value.to_uint64() catch {
    _ => Err("shift amount is too wide")
  } noraise {
    amount => Ok(amount.to_int())
  }
}

///|
fn cast_word(typ : ValueType, value : Word) -> Result[Word, String] {
  match typ {
    Imm(width) =>
      if width == value.width() {
        Ok(value)
      } else if width < value.width() {
        try value.truncate(width~) catch {
          _ => word_error()
        } noraise {
          word => Ok(word)
        }
      } else {
        try value.widen(width~) catch {
          _ => word_error()
        } noraise {
          word => Ok(word)
        }
      }
    Mem(_) => Err("can't cast scalar word to memory type")
  }
}

///|
fn eval_cmp(
  lhs : Word,
  rhs : Word,
  compare : (Word, Word) -> Int raise @bitvec.BitVecError,
  accept : (Int) -> Bool,
) -> Result[Word, String] {
  try compare(lhs, rhs) catch {
    _ => word_error()
  } noraise {
    ordering => Ok(Word::of_bool(accept(ordering)))
  }
}

///|
fn eval_binop(op : BinOp, lhs : Word, rhs : Word) -> Result[Word, String] {
  match op {
    Plus =>
      try lhs.add(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Minus =>
      try lhs.sub(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Times =>
      try lhs.mul(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Div =>
      try lhs.div(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    SignedDiv =>
      try lhs.signed_div(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Mod =>
      try lhs.rem(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    SignedMod =>
      try lhs.signed_rem(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    And =>
      try lhs.bit_and(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Or =>
      try lhs.bit_or(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    Xor =>
      try lhs.bit_xor(rhs) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    LShift =>
      match shift_amount(rhs) {
        Ok(amount) => Ok(lhs.lshift(amount))
        Err(reason) => Err(reason)
      }
    RShift =>
      match shift_amount(rhs) {
        Ok(amount) => Ok(lhs.rshift(amount))
        Err(reason) => Err(reason)
      }
    ARShift =>
      match shift_amount(rhs) {
        Ok(amount) => Ok(lhs.arshift(amount))
        Err(reason) => Err(reason)
      }
    Eq => Ok(Word::of_bool(lhs == rhs))
    Neq => Ok(Word::of_bool(lhs != rhs))
    Lt => eval_cmp(lhs, rhs, Word::compare_unsigned, value => value < 0)
    Le => eval_cmp(lhs, rhs, Word::compare_unsigned, value => value <= 0)
    SignedLt => eval_cmp(lhs, rhs, Word::compare_signed, value => value < 0)
    SignedLe => eval_cmp(lhs, rhs, Word::compare_signed, value => value <= 0)
  }
}

///|
fn widen_apply_operand(value : Word, width : Int) -> Result[Word, String] {
  if value.width() == width {
    Ok(value)
  } else if value.width() < width {
    try value.widen(width~) catch {
      _ => word_error()
    } noraise {
      word => Ok(word)
    }
  } else {
    try value.truncate(width~) catch {
      _ => word_error()
    } noraise {
      word => Ok(word)
    }
  }
}

///|
fn align_apply_operands(lhs : Word, rhs : Word) -> Result[(Word, Word), String] {
  let width = Int::max(lhs.width(), rhs.width())
  match (widen_apply_operand(lhs, width), widen_apply_operand(rhs, width)) {
    (Ok(left), Ok(right)) => Ok((left, right))
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
pub fn UnOp::apply(self : UnOp, value : Word) -> Result[Word, String] {
  eval_unop(self, value)
}

///|
pub fn BinOp::apply(
  self : BinOp,
  lhs : Word,
  rhs : Word,
) -> Result[Word, String] {
  match self {
    LShift | RShift | ARShift => eval_binop(self, lhs, rhs)
    _ =>
      match align_apply_operands(lhs, rhs) {
        Ok((left, right)) => eval_binop(self, left, right)
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn Exp::eval(self : Exp, env : Map[String, Word]) -> Result[Word, String] {
  let values : Map[String, BilValue] = Map([])
  env.each((name, word) => values[name] = BilWord(word))
  match self.eval_value(values) {
    Ok(BilWord(word)) => Ok(word)
    Ok(BilMem(_)) => Err("expression evaluated to memory")
    Err(reason) => Err(reason)
  }
}

///|
pub fn Stmt::free_vars(self : Stmt) -> Array[Var] {
  let vars = []
  match self {
    Move(_, rhs) => add_vars(vars, rhs.free_vars())
    Jmp(exp) => add_vars(vars, exp.free_vars())
    Special(_) | CpuExn(_) => ()
    If(cond~, yes~, no~) => {
      add_vars(vars, cond.free_vars())
      for stmt in yes {
        add_vars(vars, stmt.free_vars())
      }
      for stmt in no {
        add_vars(vars, stmt.free_vars())
      }
    }
    While(cond~, body~) => {
      add_vars(vars, cond.free_vars())
      for stmt in body {
        add_vars(vars, stmt.free_vars())
      }
    }
  }
  vars
}

///|
pub fn Stmt::substitute_var(
  self : Stmt,
  variable : Var,
  replacement : Exp,
) -> Stmt {
  match self {
    Move(lhs, rhs) => Move(lhs, rhs.substitute_var(variable, replacement))
    Jmp(exp) => Jmp(exp.substitute_var(variable, replacement))
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(
        cond=cond.substitute_var(variable, replacement),
        yes=yes.map(stmt => stmt.substitute_var(variable, replacement)),
        no=no.map(stmt => stmt.substitute_var(variable, replacement)),
      )
    While(cond~, body~) =>
      While(
        cond=cond.substitute_var(variable, replacement),
        body=body.map(stmt => stmt.substitute_var(variable, replacement)),
      )
  }
}
