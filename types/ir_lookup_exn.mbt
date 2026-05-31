///|
pub(all) suberror IrTermLookupError {
  MissingIrTerm(String, Tid)
  MissingIrTermIndex(String, Int)
} derive(Eq, Debug)

///|
fn[T] unwrap_ir_term(
  kind : String,
  tid : Tid,
  term : Term[T]?,
) -> Term[T] raise IrTermLookupError {
  match term {
    Some(term) => term
    None => raise MissingIrTerm(kind, tid)
  }
}

///|
fn[T] unwrap_ir_term_index(
  kind : String,
  index : Int,
  term : T?,
) -> T raise IrTermLookupError {
  match term {
    Some(term) => term
    None => raise MissingIrTermIndex(kind, index)
  }
}

///|
pub fn Term::find_sub_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Sub] raise IrTermLookupError {
  unwrap_ir_term("sub", tid, self.find_sub(tid))
}

///|
pub fn Term::nth_sub_exn(
  self : Term[Program],
  index : Int,
) -> Term[Sub] raise IrTermLookupError {
  unwrap_ir_term_index("sub", index, self.nth_sub(index))
}

///|
pub fn Term::find_arg(self : Term[Sub], tid : Tid) -> Term[Arg]? {
  for arg in self.payload_value.args {
    if arg.tid() == tid {
      return Some(arg)
    }
  }
  None
}

///|
pub fn Term::find_arg_exn(
  self : Term[Sub],
  tid : Tid,
) -> Term[Arg] raise IrTermLookupError {
  unwrap_ir_term("arg", tid, self.find_arg(tid))
}

///|
pub fn Term::nth_arg_exn(
  self : Term[Sub],
  index : Int,
) -> Term[Arg] raise IrTermLookupError {
  unwrap_ir_term_index("arg", index, self.nth_arg(index))
}

///|
pub fn Term::find_blk_exn(
  self : Term[Sub],
  tid : Tid,
) -> Term[Blk] raise IrTermLookupError {
  unwrap_ir_term("blk", tid, self.find_blk(tid))
}

///|
pub fn Term::nth_blk_exn(
  self : Term[Sub],
  index : Int,
) -> Term[Blk] raise IrTermLookupError {
  unwrap_ir_term_index("blk", index, self.nth_blk(index))
}

///|
pub fn Term::find_phi_exn(
  self : Term[Blk],
  tid : Tid,
) -> Term[Phi] raise IrTermLookupError {
  unwrap_ir_term("phi", tid, self.find_phi(tid))
}

///|
pub fn Term::nth_phi_exn(
  self : Term[Blk],
  index : Int,
) -> Term[Phi] raise IrTermLookupError {
  unwrap_ir_term_index("phi", index, self.nth_phi(index))
}

///|
pub fn Term::find_def_exn(
  self : Term[Blk],
  tid : Tid,
) -> Term[Def] raise IrTermLookupError {
  unwrap_ir_term("def", tid, self.find_def(tid))
}

///|
pub fn Term::nth_def_exn(
  self : Term[Blk],
  index : Int,
) -> Term[Def] raise IrTermLookupError {
  unwrap_ir_term_index("def", index, self.nth_def(index))
}

///|
pub fn Term::find_jmp_exn(
  self : Term[Blk],
  tid : Tid,
) -> Term[Jmp] raise IrTermLookupError {
  unwrap_ir_term("jmp", tid, self.find_jmp(tid))
}

///|
pub fn Term::nth_jmp_exn(
  self : Term[Blk],
  index : Int,
) -> Term[Jmp] raise IrTermLookupError {
  unwrap_ir_term_index("jmp", index, self.nth_jmp(index))
}

///|
pub fn IrTerm::nth_child_exn(
  self : IrTerm,
  cls : IrTermClass,
  index : Int,
) -> IrTerm raise IrTermLookupError {
  unwrap_ir_term_index(cls.to_string(), index, self.nth_child(cls, index))
}

///|
pub fn IrTerm::find_exn(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm raise IrTermLookupError {
  match self.find(cls, tid) {
    Some(term) => term
    None => raise MissingIrTerm(cls.to_string(), tid)
  }
}

///|
pub fn IrTerm::nth_exn(
  self : IrTerm,
  cls : IrTermClass,
  index : Int,
) -> IrTerm raise IrTermLookupError {
  self.nth_child_exn(cls, index)
}

///|
pub fn Term::program_find_arg(self : Term[Program], tid : Tid) -> Term[Arg]? {
  for sub in self.payload_value.subs {
    match sub.find_arg(tid) {
      Some(arg) => return Some(arg)
      None => ()
    }
  }
  None
}

///|
pub fn Term::program_find_arg_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Arg] raise IrTermLookupError {
  unwrap_ir_term("arg", tid, self.program_find_arg(tid))
}

///|
pub fn Term::program_find_blk_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Blk] raise IrTermLookupError {
  unwrap_ir_term("blk", tid, self.program_find_blk(tid))
}

///|
pub fn Term::program_find_phi_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Phi] raise IrTermLookupError {
  unwrap_ir_term("phi", tid, self.program_find_phi(tid))
}

///|
pub fn Term::program_find_def_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Def] raise IrTermLookupError {
  unwrap_ir_term("def", tid, self.program_find_def(tid))
}

///|
pub fn Term::program_find_jmp_exn(
  self : Term[Program],
  tid : Tid,
) -> Term[Jmp] raise IrTermLookupError {
  unwrap_ir_term("jmp", tid, self.program_find_jmp(tid))
}
