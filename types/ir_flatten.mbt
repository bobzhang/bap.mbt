///|
let flatten_counter : Ref[Int] = Ref(0)

///|
fn flatten_next_id() -> Int {
  flatten_counter.val = flatten_counter.val + 1
  flatten_counter.val
}

///|
fn flatten_fresh_var(typ : ValueType) -> Var {
  Var::new(name="flat_\{flatten_next_id()}", typ~, is_virtual=true)
}

///|
fn Exp::is_flat_value(self : Exp) -> Bool {
  match self {
    Int(_) | Var(_) | Unknown(_) => true
    _ => false
  }
}

///|
fn Term::flatten_insert_def(
  self : Term[Blk],
  def : Term[Def],
  before? : Tid,
) -> Term[Blk] {
  match before {
    Some(tid) => self.insert_def_before(def, before=tid)
    None => self.append_def(def)
  }
}

///|
fn Term::flatten_materialize(
  self : Term[Blk],
  exp : Exp,
  before? : Tid,
) -> (Exp, Term[Blk]) {
  if exp.is_flat_value() {
    (exp, self)
  } else {
    let variable = flatten_fresh_var(exp.type_of())
    let def = Def::create(variable, exp)
    (Var(variable), self.flatten_insert_def(def, before?))
  }
}

///|
fn Term::flatten_exp_into(
  self : Term[Blk],
  exp : Exp,
  before? : Tid,
) -> (Exp, Term[Blk]) {
  match exp {
    Int(_) | Var(_) | Unknown(_) => (exp, self)
    Load(mem~, addr~, endian~, typ~) => {
      let (mem, blk) = self.flatten_exp_into(mem, before?)
      let (addr, blk) = blk.flatten_exp_into(addr, before?)
      blk.flatten_materialize(Load(mem~, addr~, endian~, typ~), before?)
    }
    Store(mem~, addr~, value~, endian~) => {
      let (mem, blk) = self.flatten_exp_into(mem, before?)
      let (addr, blk) = blk.flatten_exp_into(addr, before?)
      let (value, blk) = blk.flatten_exp_into(value, before?)
      blk.flatten_materialize(Store(mem~, addr~, value~, endian~), before?)
    }
    Let(variable, value, body) => {
      let (value, blk) = self.flatten_exp_into(value, before?)
      let (replacement, blk) = match value {
        Var(value_var) => (value_var, blk)
        _ => {
          let value_var = flatten_fresh_var(variable.typ)
          let def = Def::create(value_var, value)
          (value_var, blk.flatten_insert_def(def, before?))
        }
      }
      blk.flatten_exp_into(
        body.substitute_var(variable, Var(replacement)),
        before?,
      )
    }
    Cast(kind~, width~, exp=inner) => {
      let (inner, blk) = self.flatten_exp_into(inner, before?)
      blk.flatten_materialize(Cast(kind~, width~, exp=inner), before?)
    }
    Extract(hi~, lo~, exp~) => {
      let (exp, blk) = self.flatten_exp_into(exp, before?)
      blk.flatten_materialize(Extract(hi~, lo~, exp~), before?)
    }
    Concat(high~, low~) => {
      let (high, blk) = self.flatten_exp_into(high, before?)
      let (low, blk) = blk.flatten_exp_into(low, before?)
      blk.flatten_materialize(Concat(high~, low~), before?)
    }
    UnOp(op, inner) => {
      let (inner, blk) = self.flatten_exp_into(inner, before?)
      blk.flatten_materialize(UnOp(op, inner), before?)
    }
    BinOp(op, lhs, rhs) => {
      let (lhs, blk) = self.flatten_exp_into(lhs, before?)
      let (rhs, blk) = blk.flatten_exp_into(rhs, before?)
      blk.flatten_materialize(BinOp(op, lhs, rhs), before?)
    }
    Ite(cond~, yes~, no~) => {
      let (cond, blk) = self.flatten_exp_into(cond, before?)
      let (yes, blk) = blk.flatten_exp_into(yes, before?)
      let (no, blk) = blk.flatten_exp_into(no, before?)
      blk.flatten_materialize(Ite(cond~, yes~, no~), before?)
    }
  }
}

///|
fn Term::flatten_label_into(
  self : Term[Blk],
  label : Label,
) -> (Label, Term[Blk]) {
  match label {
    Direct(_) => (label, self)
    Indirect(exp) => {
      let (exp, blk) = self.flatten_exp_into(exp)
      (Indirect(exp), blk)
    }
  }
}

///|
fn Term::flatten_call_into(self : Term[Blk], call : Call) -> (Call, Term[Blk]) {
  let (target, blk) = self.flatten_label_into(call.target)
  let (return_label, blk) = match call.return_label {
    Some(label) => {
      let (label, blk) = blk.flatten_label_into(label)
      (Some(label), blk)
    }
    None => (None, blk)
  }
  ({ target, return_label, }, blk)
}

///|
fn Term::flatten_jmp_kind_into(
  self : Term[Blk],
  kind : JmpKind,
) -> (JmpKind, Term[Blk]) {
  match kind {
    JmpCall(call) => {
      let (call, blk) = self.flatten_call_into(call)
      (JmpCall(call), blk)
    }
    Goto(label) => {
      let (label, blk) = self.flatten_label_into(label)
      (Goto(label), blk)
    }
    Ret(label) => {
      let (label, blk) = self.flatten_label_into(label)
      (Ret(label), blk)
    }
    Interrupt(_, _) => (kind, self)
  }
}

///|
fn Term::flatten_jmp_into(self : Term[Blk], jmp : Term[Jmp]) -> Term[Blk] {
  let (cond, blk) = self.flatten_exp_into(jmp.cond())
  let (kind, blk) = blk.flatten_jmp_kind_into(jmp.kind())
  blk.update_jmp(jmp.with_cond(cond).with_kind(kind))
}

///|
pub fn Term::flatten_blk(self : Term[Blk]) -> Term[Blk] {
  let mut blk = self
  for def in self.payload_value.defs {
    let (rhs, next) = blk.flatten_exp_into(def.rhs(), before=def.tid())
    blk = next.update_def(def.with_rhs(rhs))
  }
  for jmp in self.payload_value.jmps {
    blk = blk.flatten_jmp_into(jmp)
  }
  blk
}

///|
pub fn Term::flatten_sub(self : Term[Sub]) -> Term[Sub] {
  self.with_payload({
    ..self.payload_value,
    blks: self.payload_value.blks.map(blk => blk.flatten_blk()),
  })
}

///|
pub fn Term::flatten_program(self : Term[Program]) -> Term[Program] {
  self.with_payload({ subs: self.subs().map(sub => sub.flatten_sub()), })
}
