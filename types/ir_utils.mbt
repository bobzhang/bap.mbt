///|
fn add_free_vars(
  vars : Array[Var],
  more : Array[Var],
  killed : Array[Var],
) -> Unit {
  for variable in more {
    if !killed.contains(variable) {
      add_var(vars, variable)
    }
  }
}

///|
pub fn Label::map_exp(self : Label, f : (Exp) -> Exp) -> Label {
  match self {
    Direct(_) => self
    Indirect(exp) => Indirect(f(exp))
  }
}

///|
pub fn Label::free_vars(self : Label) -> Array[Var] {
  match self {
    Direct(_) => []
    Indirect(exp) => exp.free_vars()
  }
}

///|
pub fn Label::substitute_var(
  self : Label,
  variable : Var,
  replacement : Exp,
) -> Label {
  self.map_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Call::map_exp(self : Call, f : (Exp) -> Exp) -> Call {
  {
    target: self.target.map_exp(f),
    return_label: match self.return_label {
      Some(label) => Some(label.map_exp(f))
      None => None
    },
  }
}

///|
pub fn Call::free_vars(self : Call) -> Array[Var] {
  let vars = self.target.free_vars()
  match self.return_label {
    Some(label) => add_vars(vars, label.free_vars())
    None => ()
  }
  vars
}

///|
pub fn Call::substitute_var(
  self : Call,
  variable : Var,
  replacement : Exp,
) -> Call {
  self.map_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn JmpKind::map_exp(self : JmpKind, f : (Exp) -> Exp) -> JmpKind {
  match self {
    JmpCall(call) => JmpCall(call.map_exp(f))
    Goto(label) => Goto(label.map_exp(f))
    Ret(label) => Ret(label.map_exp(f))
    Interrupt(_, _) => self
  }
}

///|
pub fn JmpKind::free_vars(self : JmpKind) -> Array[Var] {
  match self {
    JmpCall(call) => call.free_vars()
    Goto(label) | Ret(label) => label.free_vars()
    Interrupt(_, _) => []
  }
}

///|
pub fn JmpKind::substitute_var(
  self : JmpKind,
  variable : Var,
  replacement : Exp,
) -> JmpKind {
  self.map_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_def_exp(self : Term[Def], f : (Exp) -> Exp) -> Term[Def] {
  self.with_rhs(f(self.rhs()))
}

///|
pub fn Term::def_free_vars(self : Term[Def]) -> Array[Var] {
  self.rhs().free_vars()
}

///|
pub fn Term::substitute_def_var(
  self : Term[Def],
  variable : Var,
  replacement : Exp,
) -> Term[Def] {
  self.map_def_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_phi_exp(self : Term[Phi], f : (Exp) -> Exp) -> Term[Phi] {
  self.with_payload({
    ..self.payload_value,
    values: self.payload_value.values.map(pair => (pair.0, f(pair.1))),
  })
}

///|
pub fn Term::phi_free_vars(self : Term[Phi]) -> Array[Var] {
  let vars = []
  for pair in self.payload_value.values {
    add_vars(vars, pair.1.free_vars())
  }
  vars
}

///|
pub fn Term::substitute_phi_var(
  self : Term[Phi],
  variable : Var,
  replacement : Exp,
) -> Term[Phi] {
  self.map_phi_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_jmp_exp(self : Term[Jmp], f : (Exp) -> Exp) -> Term[Jmp] {
  self.with_payload({ kind: self.kind().map_exp(f), cond: f(self.cond()) })
}

///|
pub fn Term::jmp_free_vars(self : Term[Jmp]) -> Array[Var] {
  let vars = self.cond().free_vars()
  add_vars(vars, self.kind().free_vars())
  vars
}

///|
pub fn Term::substitute_jmp_var(
  self : Term[Jmp],
  variable : Var,
  replacement : Exp,
) -> Term[Jmp] {
  self.map_jmp_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_arg_exp(self : Term[Arg], f : (Exp) -> Exp) -> Term[Arg] {
  self.with_payload({ ..self.payload_value, rhs: f(self.arg_rhs()) })
}

///|
pub fn Term::arg_free_vars(self : Term[Arg]) -> Array[Var] {
  self.arg_rhs().free_vars()
}

///|
pub fn Term::substitute_arg_var(
  self : Term[Arg],
  variable : Var,
  replacement : Exp,
) -> Term[Arg] {
  self.map_arg_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_blk_exp(self : Term[Blk], f : (Exp) -> Exp) -> Term[Blk] {
  self.with_payload({
    phis: self.payload_value.phis.map(term => term.map_phi_exp(f)),
    defs: self.payload_value.defs.map(term => term.map_def_exp(f)),
    jmps: self.payload_value.jmps.map(term => term.map_jmp_exp(f)),
  })
}

///|
pub fn Term::blk_free_vars(self : Term[Blk]) -> Array[Var] {
  let vars = []
  let killed = []
  for phi in self.payload_value.phis {
    add_free_vars(vars, phi.phi_free_vars(), killed)
    add_var(killed, phi.phi_lhs())
  }
  for def in self.payload_value.defs {
    add_free_vars(vars, def.def_free_vars(), killed)
    add_var(killed, def.lhs())
  }
  for jmp in self.payload_value.jmps {
    add_free_vars(vars, jmp.jmp_free_vars(), killed)
  }
  vars
}

///|
pub fn Term::substitute_blk_var(
  self : Term[Blk],
  variable : Var,
  replacement : Exp,
) -> Term[Blk] {
  self.map_blk_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_sub_exp(self : Term[Sub], f : (Exp) -> Exp) -> Term[Sub] {
  self.with_payload({
    ..self.payload_value,
    args: self.payload_value.args.map(term => term.map_arg_exp(f)),
    blks: self.payload_value.blks.map(term => term.map_blk_exp(f)),
  })
}

///|
pub fn Term::sub_free_vars(self : Term[Sub]) -> Array[Var] {
  let vars = []
  for arg in self.payload_value.args {
    add_vars(vars, arg.arg_free_vars())
  }
  for blk in self.payload_value.blks {
    add_vars(vars, blk.blk_free_vars())
  }
  vars
}

///|
pub fn Term::substitute_sub_var(
  self : Term[Sub],
  variable : Var,
  replacement : Exp,
) -> Term[Sub] {
  self.map_sub_exp(exp => exp.substitute_var(variable, replacement))
}

///|
pub fn Term::map_program_exp(
  self : Term[Program],
  f : (Exp) -> Exp,
) -> Term[Program] {
  self.with_payload({
    subs: self.payload_value.subs.map(term => term.map_sub_exp(f)),
  })
}

///|
pub fn Term::program_free_vars(self : Term[Program]) -> Array[Var] {
  let vars = []
  for sub in self.payload_value.subs {
    add_vars(vars, sub.sub_free_vars())
  }
  vars
}

///|
pub fn Term::substitute_program_var(
  self : Term[Program],
  variable : Var,
  replacement : Exp,
) -> Term[Program] {
  self.map_program_exp(exp => exp.substitute_var(variable, replacement))
}
