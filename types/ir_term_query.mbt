///|
pub fn IrTerm::same_term(self : IrTerm, other : IrTerm) -> Bool {
  self.class() == other.class() && self.tid() == other.tid()
}

///|
pub fn IrTerm::has_class(self : IrTerm, cls : IrTermClass) -> Bool {
  self.class() == cls
}

///|
pub fn IrTerm::has_name(self : IrTerm, name : String) -> Bool {
  self.name() == name
}

///|
pub fn IrTerm::has_tid(self : IrTerm, tid : Tid) -> Bool {
  self.tid() == tid
}

///|
pub fn IrTerm::has_tid_text(self : IrTerm, text : String) -> Bool {
  self.tid().to_string() == text
}

///|
pub fn IrTerm::has_attr_value(
  self : IrTerm,
  key : String,
  value : String,
) -> Bool {
  self.get_attr(key) == Some(value)
}

///|
pub fn IrTerm::children(self : IrTerm) -> Array[IrTerm] {
  match self {
    ProgramTerm(term) => [ for sub in term.subs() => SubTerm(sub) ]
    SubTerm(term) => {
      let result = []
      for arg in term.args() {
        result.push(ArgTerm(arg))
      }
      for blk in term.blks() {
        result.push(BlkTerm(blk))
      }
      result
    }
    BlkTerm(term) => {
      let result = []
      for phi in term.phis() {
        result.push(PhiTerm(phi))
      }
      for def in term.defs() {
        result.push(DefTerm(def))
      }
      for jmp in term.jmps() {
        result.push(JmpTerm(jmp))
      }
      result
    }
    ArgTerm(_) | PhiTerm(_) | DefTerm(_) | JmpTerm(_) => []
  }
}

///|
pub fn IrTerm::has_child_tid(self : IrTerm, tid : Tid) -> Bool {
  self.children().any(child => child.tid() == tid)
}

///|
pub fn IrTerm::free_vars(self : IrTerm) -> Array[Var] {
  match self {
    ProgramTerm(term) => term.program_free_vars()
    SubTerm(term) => term.sub_free_vars()
    ArgTerm(term) => term.arg_free_vars()
    BlkTerm(term) => term.blk_free_vars()
    PhiTerm(term) => term.phi_free_vars()
    DefTerm(term) => term.def_free_vars()
    JmpTerm(term) => term.jmp_free_vars()
  }
}

///|
pub fn IrTerm::uses_var(self : IrTerm, variable : Var) -> Bool {
  self.free_vars().any(item => item == variable)
}

///|
pub fn IrTerm::uses_var_name(self : IrTerm, name : String) -> Bool {
  self.free_vars().any(item => item.name() == name)
}

///|
pub fn IrTerm::defined_vars(self : IrTerm) -> Array[Var] {
  let vars = []
  match self {
    ProgramTerm(term) =>
      for sub in term.subs() {
        add_vars(vars, SubTerm(sub).defined_vars())
      }
    SubTerm(term) => {
      for arg in term.args() {
        add_var(vars, arg.arg_lhs())
      }
      for blk in term.blks() {
        add_vars(vars, BlkTerm(blk).defined_vars())
      }
    }
    ArgTerm(term) => add_var(vars, term.arg_lhs())
    BlkTerm(term) => add_vars(vars, term.blk_defined_vars())
    PhiTerm(term) => add_var(vars, term.phi_lhs())
    DefTerm(term) => add_var(vars, term.lhs())
    JmpTerm(_) => ()
  }
  vars
}

///|
pub fn IrTerm::defines_var(self : IrTerm, variable : Var) -> Bool {
  self.defined_vars().any(item => item == variable)
}

///|
pub fn IrTerm::defines_var_name(self : IrTerm, name : String) -> Bool {
  self.defined_vars().any(item => item.name() == name)
}

///|
pub fn IrTerm::def_lhs_name(self : IrTerm, name : String) -> Bool {
  match self {
    DefTerm(term) => term.lhs().name() == name
    _ => false
  }
}

///|
pub fn IrTerm::def_uses_name(self : IrTerm, name : String) -> Bool {
  match self {
    DefTerm(term) => term.def_free_vars().any(item => item.name() == name)
    _ => false
  }
}

///|
pub fn Term::sub_parent_is(
  self : Term[Sub],
  parent : IrTerm,
  child : Tid,
) -> Bool {
  match self.sub_parent_term(child) {
    Some(actual) => actual.same_term(parent)
    None => false
  }
}

///|
pub fn Term::program_parent_is(
  self : Term[Program],
  parent : IrTerm,
  child : Tid,
) -> Bool {
  match self.program_parent_term(child) {
    Some(actual) => actual.same_term(parent)
    None => false
  }
}
