///|
fn type_unify(
  expected : ValueType,
  got : ValueType,
) -> Result[ValueType, TypeError] {
  if expected == got {
    Ok(expected)
  } else {
    Err(TypeError::bad_type(expected~, got~))
  }
}

///|
fn checked_imm(typ : ValueType) -> Result[Int, TypeError] {
  match typ {
    Imm(width) => Ok(width)
    Mem(_) => Err(TypeError::bad_imm())
  }
}

///|
fn checked_mem(typ : ValueType) -> Result[(Int, Int), TypeError] {
  match typ {
    Mem(addr_width~, value_width~) => Ok((addr_width, value_width))
    Imm(_) => Err(TypeError::bad_mem())
  }
}

///|
fn checked_load(
  mem : Exp,
  addr : Exp,
  typ : ValueType,
) -> Result[ValueType, TypeError] {
  match (mem.infer_type(), addr.infer_type()) {
    (Ok(mem_typ), Ok(addr_typ)) =>
      match (checked_mem(mem_typ), checked_imm(addr_typ)) {
        (Ok((addr_width, _)), Ok(got_addr_width)) =>
          if addr_width == got_addr_width {
            match typ {
              Imm(_) => Ok(typ)
              Mem(_) => Err(TypeError::bad_imm())
            }
          } else {
            Err(
              TypeError::bad_type(
                expected=Imm(addr_width),
                got=Imm(got_addr_width),
              ),
            )
          }
        (Err(err), _) | (_, Err(err)) => Err(err)
      }
    (Err(err), _) | (_, Err(err)) => Err(err)
  }
}

///|
fn checked_store(
  mem : Exp,
  addr : Exp,
  value : Exp,
) -> Result[ValueType, TypeError] {
  match (mem.infer_type(), addr.infer_type(), value.infer_type()) {
    (Ok(mem_typ), Ok(addr_typ), Ok(value_typ)) =>
      match
        (checked_mem(mem_typ), checked_imm(addr_typ), checked_imm(value_typ)) {
        (Ok((addr_width, _)), Ok(got_addr_width), Ok(value_width)) =>
          if addr_width != got_addr_width {
            Err(
              TypeError::bad_type(
                expected=Imm(addr_width),
                got=Imm(got_addr_width),
              ),
            )
          } else if Size::of_int_opt(value_width) == None {
            Err(TypeError::bad_cast())
          } else {
            Ok(mem_typ)
          }
        (Err(err), _, _) | (_, Err(err), _) | (_, _, Err(err)) => Err(err)
      }
    (Err(err), _, _) | (_, Err(err), _) | (_, _, Err(err)) => Err(err)
  }
}

///|
fn checked_binop(
  op : BinOp,
  lhs : Exp,
  rhs : Exp,
) -> Result[ValueType, TypeError] {
  match (lhs.infer_type(), rhs.infer_type()) {
    (Ok(lhs_typ), Ok(rhs_typ)) =>
      match op {
        LShift | RShift | ARShift =>
          match (checked_imm(lhs_typ), checked_imm(rhs_typ)) {
            (Ok(_), Ok(_)) => Ok(lhs_typ)
            (Err(err), _) | (_, Err(err)) => Err(err)
          }
        _ =>
          match type_unify(lhs_typ, rhs_typ) {
            Ok(Mem(_)) => Err(TypeError::bad_imm())
            Ok(Imm(_)) =>
              match op {
                Eq | Neq | Lt | Le | SignedLt | SignedLe => Ok(Imm(1))
                _ => Ok(lhs_typ)
              }
            Err(err) => Err(err)
          }
      }
    (Err(err), _) | (_, Err(err)) => Err(err)
  }
}

///|
fn checked_ite(cond : Exp, yes : Exp, no : Exp) -> Result[ValueType, TypeError] {
  match cond.infer_type() {
    Ok(cond_typ) =>
      match checked_imm(cond_typ) {
        Ok(1) =>
          match (yes.infer_type(), no.infer_type()) {
            (Ok(yes_typ), Ok(no_typ)) => type_unify(yes_typ, no_typ)
            (Err(err), _) | (_, Err(err)) => Err(err)
          }
        Ok(width) => Err(TypeError::bad_type(expected=Imm(1), got=Imm(width)))
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///|
fn checked_extract(
  hi : Int,
  lo : Int,
  exp : Exp,
) -> Result[ValueType, TypeError] {
  match exp.infer_type() {
    Ok(Imm(_)) =>
      if lo < 0 || hi < lo {
        Err(TypeError::bad_cast())
      } else {
        Ok(Imm(hi - lo + 1))
      }
    Ok(Mem(_)) => Err(TypeError::bad_imm())
    Err(err) => Err(err)
  }
}

///|
fn checked_cast(
  kind : CastKind,
  width : Int,
  exp : Exp,
) -> Result[ValueType, TypeError] {
  if width <= 0 {
    Err(TypeError::bad_cast())
  } else {
    match exp.infer_type() {
      Ok(Imm(exp_width)) =>
        match kind {
          Unsigned | Signed => Ok(Imm(width))
          High | Low =>
            if exp_width >= width {
              Ok(Imm(width))
            } else {
              Err(TypeError::bad_cast())
            }
        }
      Ok(Mem(_)) => Err(TypeError::bad_imm())
      Err(err) => Err(err)
    }
  }
}

///|
fn checked_concat(high : Exp, low : Exp) -> Result[ValueType, TypeError] {
  match (high.infer_type(), low.infer_type()) {
    (Ok(Imm(high_width)), Ok(Imm(low_width))) => Ok(Imm(high_width + low_width))
    (Ok(Mem(_)), _) | (_, Ok(Mem(_))) => Err(TypeError::bad_imm())
    (Err(err), _) | (_, Err(err)) => Err(err)
  }
}

///|
pub fn Exp::infer_type(self : Exp) -> Result[ValueType, TypeError] {
  match self {
    Int(word) => Ok(Imm(word.width()))
    Var(variable) => Ok(variable.typ)
    Unknown(_, typ) => Ok(typ)
    Load(mem~, addr~, typ~, ..) => checked_load(mem, addr, typ)
    Store(mem~, addr~, value~, ..) => checked_store(mem, addr, value)
    Let(variable, value, body) =>
      match value.infer_type() {
        Ok(value_typ) =>
          match type_unify(variable.typ, value_typ) {
            Ok(_) => body.infer_type()
            Err(err) => Err(err)
          }
        Err(err) => Err(err)
      }
    Cast(kind~, width~, exp~) => checked_cast(kind, width, exp)
    Extract(hi~, lo~, exp~) => checked_extract(hi, lo, exp)
    Concat(high~, low~) => checked_concat(high, low)
    UnOp(_, exp) =>
      match exp.infer_type() {
        Ok(exp_typ) =>
          match checked_imm(exp_typ) {
            Ok(_) => Ok(exp_typ)
            Err(err) => Err(err)
          }
        Err(err) => Err(err)
      }
    BinOp(op, lhs, rhs) => checked_binop(op, lhs, rhs)
    Ite(cond~, yes~, no~) => checked_ite(cond, yes, no)
  }
}

///|
#alias(infer_exn)
pub fn Exp::infer_type_exn(self : Exp) -> ValueType raise TypeInferenceError {
  match self.infer_type() {
    Ok(typ) => typ
    Err(err) => raise InvalidExpType(err)
  }
}

///|
fn checked_condition(cond : Exp) -> Result[Unit, TypeError] {
  match cond.infer_type() {
    Ok(Imm(1)) => Ok(())
    Ok(Imm(width)) => Err(TypeError::bad_type(expected=Imm(1), got=Imm(width)))
    Ok(Mem(_)) => Err(TypeError::bad_imm())
    Err(err) => Err(err)
  }
}

///|
pub fn check_stmt_types(stmts : Array[Stmt]) -> Result[Unit, TypeError] {
  for stmt in stmts {
    match stmt.check_type() {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }
  Ok(())
}

///|
pub fn Stmt::check_type(self : Stmt) -> Result[Unit, TypeError] {
  match self {
    Move(variable, exp) =>
      match exp.infer_type() {
        Ok(typ) =>
          if variable.typ == typ {
            Ok(())
          } else {
            Err(TypeError::bad_type(expected=variable.typ, got=typ))
          }
        Err(err) => Err(err)
      }
    Jmp(exp) =>
      match exp.infer_type() {
        Ok(Imm(_)) => Ok(())
        Ok(Mem(_)) => Err(TypeError::bad_imm())
        Err(err) => Err(err)
      }
    Special(_) | CpuExn(_) => Ok(())
    If(cond~, yes~, no~) =>
      match checked_condition(cond) {
        Ok(_) =>
          match check_stmt_types(yes) {
            Ok(_) => check_stmt_types(no)
            Err(err) => Err(err)
          }
        Err(err) => Err(err)
      }
    While(cond~, body~) =>
      match checked_condition(cond) {
        Ok(_) => check_stmt_types(body)
        Err(err) => Err(err)
      }
  }
}
