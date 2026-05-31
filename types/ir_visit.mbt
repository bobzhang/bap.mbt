///|
pub(all) enum IrVisitEvent {
  EnterTerm(IrTerm)
  LeaveTerm(IrTerm)
  VisitVar(Var)
  VisitExp(Exp)
}

///|
pub fn IrVisitEvent::kind(self : IrVisitEvent) -> String {
  match self {
    EnterTerm(_) => "enter-term"
    LeaveTerm(_) => "leave-term"
    VisitVar(_) => "var"
    VisitExp(_) => "exp"
  }
}

///|
fn[A] fold_exp_visit(exp : Exp, init : A, f : (A, IrVisitEvent) -> A) -> A {
  exp.fold(init, (acc, item) => f(acc, VisitExp(item)))
}

///|
fn[A] fold_var_visit(variable : Var, init : A, f : (A, IrVisitEvent) -> A) -> A {
  f(init, VisitVar(variable))
}

///|
fn[A] fold_arg_visit(
  term : Term[Arg],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  fold_exp_visit(term.arg_rhs(), fold_var_visit(term.arg_lhs(), init, f), f)
}

///|
fn[A] fold_phi_visit(
  term : Term[Phi],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  let mut acc = fold_var_visit(term.phi_lhs(), init, f)
  for pair in term.values() {
    acc = fold_exp_visit(pair.1, acc, f)
  }
  acc
}

///|
fn[A] fold_def_visit(
  term : Term[Def],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  fold_exp_visit(term.rhs(), fold_var_visit(term.lhs(), init, f), f)
}

///|
fn[A] fold_jmp_visit(
  term : Term[Jmp],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  let mut acc = init
  for exp in term.jmp_exps() {
    acc = fold_exp_visit(exp, acc, f)
  }
  acc
}

///|
pub fn[A] IrTerm::fold_visit(
  self : IrTerm,
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  let acc = f(init, EnterTerm(self))
  let acc = match self {
    ProgramTerm(term) => {
      let mut acc = acc
      for sub in term.subs() {
        acc = SubTerm(sub).fold_visit(acc, f)
      }
      acc
    }
    SubTerm(term) => {
      let mut acc = acc
      for arg in term.args() {
        acc = ArgTerm(arg).fold_visit(acc, f)
      }
      for blk in term.blks() {
        acc = BlkTerm(blk).fold_visit(acc, f)
      }
      acc
    }
    BlkTerm(term) => {
      let mut acc = acc
      for phi in term.phis() {
        acc = PhiTerm(phi).fold_visit(acc, f)
      }
      for def in term.defs() {
        acc = DefTerm(def).fold_visit(acc, f)
      }
      for jmp in term.jmps() {
        acc = JmpTerm(jmp).fold_visit(acc, f)
      }
      acc
    }
    ArgTerm(term) => fold_arg_visit(term, acc, f)
    PhiTerm(term) => fold_phi_visit(term, acc, f)
    DefTerm(term) => fold_def_visit(term, acc, f)
    JmpTerm(term) => fold_jmp_visit(term, acc, f)
  }
  f(acc, LeaveTerm(self))
}

///|
pub fn[A] Term::fold_blk_visit(
  self : Term[Blk],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  BlkTerm(self).fold_visit(init, f)
}

///|
pub fn[A] Term::fold_sub_visit(
  self : Term[Sub],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  SubTerm(self).fold_visit(init, f)
}

///|
pub fn[A] Term::fold_program_visit(
  self : Term[Program],
  init : A,
  f : (A, IrVisitEvent) -> A,
) -> A {
  ProgramTerm(self).fold_visit(init, f)
}

///|
pub fn IrTerm::visit_events(self : IrTerm) -> Array[IrVisitEvent] {
  self.fold_visit([], (events, event) => {
    events.push(event)
    events
  })
}

///|
pub fn Term::program_visit_events(self : Term[Program]) -> Array[IrVisitEvent] {
  ProgramTerm(self).visit_events()
}
