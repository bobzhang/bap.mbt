///|

///|
pub(all) enum IrTermClass {
  ProgramTermClass
  SubTermClass
  ArgTermClass
  BlkTermClass
  PhiTermClass
  DefTermClass
  JmpTermClass
} derive(Eq, Debug)

///|
pub extend IrTermClass with Eq::{not_equal, equal}

///|
pub extend IrTermClass with Debug::{to_repr}

///|
pub fn program_t() -> IrTermClass {
  ProgramTermClass
}

///|
pub fn sub_t() -> IrTermClass {
  SubTermClass
}

///|
pub fn arg_t() -> IrTermClass {
  ArgTermClass
}

///|
pub fn blk_t() -> IrTermClass {
  BlkTermClass
}

///|
pub fn phi_t() -> IrTermClass {
  PhiTermClass
}

///|
pub fn def_t() -> IrTermClass {
  DefTermClass
}

///|
pub fn jmp_t() -> IrTermClass {
  JmpTermClass
}

///|
pub(all) enum IrTerm {
  ProgramTerm(Term[Program])
  SubTerm(Term[Sub])
  ArgTerm(Term[Arg])
  BlkTerm(Term[Blk])
  PhiTerm(Term[Phi])
  DefTerm(Term[Def])
  JmpTerm(Term[Jmp])
}

///|
pub fn IrTermClass::to_string(self : IrTermClass) -> String {
  match self {
    ProgramTermClass => "program"
    SubTermClass => "sub"
    ArgTermClass => "arg"
    BlkTermClass => "blk"
    PhiTermClass => "phi"
    DefTermClass => "def"
    JmpTermClass => "jmp"
  }
}

///|
pub fn IrTerm::class(self : IrTerm) -> IrTermClass {
  match self {
    ProgramTerm(_) => ProgramTermClass
    SubTerm(_) => SubTermClass
    ArgTerm(_) => ArgTermClass
    BlkTerm(_) => BlkTermClass
    PhiTerm(_) => PhiTermClass
    DefTerm(_) => DefTermClass
    JmpTerm(_) => JmpTermClass
  }
}

///|
pub fn IrTerm::class_name(self : IrTerm) -> String {
  self.class().to_string()
}

///|
pub fn IrTerm::tid(self : IrTerm) -> Tid {
  match self {
    ProgramTerm(term) => term.tid()
    SubTerm(term) => term.tid()
    ArgTerm(term) => term.tid()
    BlkTerm(term) => term.tid()
    PhiTerm(term) => term.tid()
    DefTerm(term) => term.tid()
    JmpTerm(term) => term.tid()
  }
}

///|
pub fn IrTerm::name(self : IrTerm) -> String {
  self.tid().to_string()
}

///|
pub fn IrTerm::clone(self : IrTerm) -> IrTerm {
  match self {
    ProgramTerm(term) => ProgramTerm(term.clone())
    SubTerm(term) => SubTerm(term.clone())
    ArgTerm(term) => ArgTerm(term.clone())
    BlkTerm(term) => BlkTerm(term.clone())
    PhiTerm(term) => PhiTerm(term.clone())
    DefTerm(term) => DefTerm(term.clone())
    JmpTerm(term) => JmpTerm(term.clone())
  }
}

///|
pub fn IrTerm::to_string(self : IrTerm) -> String {
  match self {
    ProgramTerm(term) => term.program_to_string()
    SubTerm(term) => term.sub_to_string()
    ArgTerm(term) => term.arg_to_string()
    BlkTerm(term) => term.blk_to_string()
    PhiTerm(term) => term.phi_to_string()
    DefTerm(term) => term.def_to_string()
    JmpTerm(term) => term.jmp_to_string()
  }
}

///|
pub fn IrTerm::attrs(self : IrTerm) -> Map[String, String] {
  match self {
    ProgramTerm(term) => term.attrs()
    SubTerm(term) => term.attrs()
    ArgTerm(term) => term.attrs()
    BlkTerm(term) => term.attrs()
    PhiTerm(term) => term.attrs()
    DefTerm(term) => term.attrs()
    JmpTerm(term) => term.attrs()
  }
}

///|
pub fn IrTerm::with_attrs(self : IrTerm, attrs : Map[String, String]) -> IrTerm {
  match self {
    ProgramTerm(term) => ProgramTerm(term.with_attrs(attrs))
    SubTerm(term) => SubTerm(term.with_attrs(attrs))
    ArgTerm(term) => ArgTerm(term.with_attrs(attrs))
    BlkTerm(term) => BlkTerm(term.with_attrs(attrs))
    PhiTerm(term) => PhiTerm(term.with_attrs(attrs))
    DefTerm(term) => DefTerm(term.with_attrs(attrs))
    JmpTerm(term) => JmpTerm(term.with_attrs(attrs))
  }
}

///|
pub fn IrTerm::get_attr(self : IrTerm, key : String) -> String? {
  match self {
    ProgramTerm(term) => term.get_attr(key)
    SubTerm(term) => term.get_attr(key)
    ArgTerm(term) => term.get_attr(key)
    BlkTerm(term) => term.get_attr(key)
    PhiTerm(term) => term.get_attr(key)
    DefTerm(term) => term.get_attr(key)
    JmpTerm(term) => term.get_attr(key)
  }
}

///|
pub fn IrTerm::has_attr(self : IrTerm, key : String) -> Bool {
  self.get_attr(key) is Some(_)
}

///|
pub fn IrTerm::set_attr(self : IrTerm, attr : Attr) -> IrTerm {
  match self {
    ProgramTerm(term) => ProgramTerm(term.set_attr(attr))
    SubTerm(term) => SubTerm(term.set_attr(attr))
    ArgTerm(term) => ArgTerm(term.set_attr(attr))
    BlkTerm(term) => BlkTerm(term.set_attr(attr))
    PhiTerm(term) => PhiTerm(term.set_attr(attr))
    DefTerm(term) => DefTerm(term.set_attr(attr))
    JmpTerm(term) => JmpTerm(term.set_attr(attr))
  }
}

///|
pub fn IrTerm::del_attr(self : IrTerm, key : String) -> IrTerm {
  match self {
    ProgramTerm(term) => ProgramTerm(term.del_attr(key))
    SubTerm(term) => SubTerm(term.del_attr(key))
    ArgTerm(term) => ArgTerm(term.del_attr(key))
    BlkTerm(term) => BlkTerm(term.del_attr(key))
    PhiTerm(term) => PhiTerm(term.del_attr(key))
    DefTerm(term) => DefTerm(term.del_attr(key))
    JmpTerm(term) => JmpTerm(term.del_attr(key))
  }
}

///|
pub fn IrTerm::same_tid(self : IrTerm, tid : Tid) -> Bool {
  self.tid() == tid
}

///|
pub fn[A] IrTerm::switch(
  self : IrTerm,
  program~ : (Term[Program]) -> A,
  sub~ : (Term[Sub]) -> A,
  arg~ : (Term[Arg]) -> A,
  blk~ : (Term[Blk]) -> A,
  phi~ : (Term[Phi]) -> A,
  def~ : (Term[Def]) -> A,
  jmp~ : (Term[Jmp]) -> A,
) -> A {
  match self {
    ProgramTerm(term) => program(term)
    SubTerm(term) => sub(term)
    ArgTerm(term) => arg(term)
    BlkTerm(term) => blk(term)
    PhiTerm(term) => phi(term)
    DefTerm(term) => def(term)
    JmpTerm(term) => jmp(term)
  }
}

///|
pub fn[A] IrTerm::proj(
  self : IrTerm,
  program? : (Term[Program]) -> A?,
  sub? : (Term[Sub]) -> A?,
  arg? : (Term[Arg]) -> A?,
  blk? : (Term[Blk]) -> A?,
  phi? : (Term[Phi]) -> A?,
  def? : (Term[Def]) -> A?,
  jmp? : (Term[Jmp]) -> A?,
) -> A? {
  match self {
    ProgramTerm(term) =>
      match program {
        Some(f) => f(term)
        None => None
      }
    SubTerm(term) =>
      match sub {
        Some(f) => f(term)
        None => None
      }
    ArgTerm(term) =>
      match arg {
        Some(f) => f(term)
        None => None
      }
    BlkTerm(term) =>
      match blk {
        Some(f) => f(term)
        None => None
      }
    PhiTerm(term) =>
      match phi {
        Some(f) => f(term)
        None => None
      }
    DefTerm(term) =>
      match def {
        Some(f) => f(term)
        None => None
      }
    JmpTerm(term) =>
      match jmp {
        Some(f) => f(term)
        None => None
      }
  }
}

///|
pub fn[A] IrTerm::cata(
  self : IrTerm,
  init~ : A,
  program? : (Term[Program]) -> A,
  sub? : (Term[Sub]) -> A,
  arg? : (Term[Arg]) -> A,
  blk? : (Term[Blk]) -> A,
  phi? : (Term[Phi]) -> A,
  def? : (Term[Def]) -> A,
  jmp? : (Term[Jmp]) -> A,
) -> A {
  match self {
    ProgramTerm(term) =>
      match program {
        Some(f) => f(term)
        None => init
      }
    SubTerm(term) =>
      match sub {
        Some(f) => f(term)
        None => init
      }
    ArgTerm(term) =>
      match arg {
        Some(f) => f(term)
        None => init
      }
    BlkTerm(term) =>
      match blk {
        Some(f) => f(term)
        None => init
      }
    PhiTerm(term) =>
      match phi {
        Some(f) => f(term)
        None => init
      }
    DefTerm(term) =>
      match def {
        Some(f) => f(term)
        None => init
      }
    JmpTerm(term) =>
      match jmp {
        Some(f) => f(term)
        None => init
      }
  }
}

///|
pub fn IrTerm::map(
  self : IrTerm,
  program? : (Term[Program]) -> Term[Program],
  sub? : (Term[Sub]) -> Term[Sub],
  arg? : (Term[Arg]) -> Term[Arg],
  blk? : (Term[Blk]) -> Term[Blk],
  phi? : (Term[Phi]) -> Term[Phi],
  def? : (Term[Def]) -> Term[Def],
  jmp? : (Term[Jmp]) -> Term[Jmp],
) -> IrTerm {
  match self {
    ProgramTerm(term) =>
      match program {
        Some(f) => ProgramTerm(f(term))
        None => self
      }
    SubTerm(term) =>
      match sub {
        Some(f) => SubTerm(f(term))
        None => self
      }
    ArgTerm(term) =>
      match arg {
        Some(f) => ArgTerm(f(term))
        None => self
      }
    BlkTerm(term) =>
      match blk {
        Some(f) => BlkTerm(f(term))
        None => self
      }
    PhiTerm(term) =>
      match phi {
        Some(f) => PhiTerm(f(term))
        None => self
      }
    DefTerm(term) =>
      match def {
        Some(f) => DefTerm(f(term))
        None => self
      }
    JmpTerm(term) =>
      match jmp {
        Some(f) => JmpTerm(f(term))
        None => self
      }
  }
}

///|
pub fn Term::sub_phis(self : Term[Sub]) -> Array[Term[Phi]] {
  let result = []
  for blk in self.payload_value.blks {
    for phi in blk.phis() {
      result.push(phi)
    }
  }
  result
}

///|
pub fn Term::sub_defs(self : Term[Sub]) -> Array[Term[Def]] {
  let result = []
  for blk in self.payload_value.blks {
    for def in blk.defs() {
      result.push(def)
    }
  }
  result
}

///|
pub fn Term::sub_jmps(self : Term[Sub]) -> Array[Term[Jmp]] {
  let result = []
  for blk in self.payload_value.blks {
    for jmp in blk.jmps() {
      result.push(jmp)
    }
  }
  result
}

///|
pub fn Term::program_args(self : Term[Program]) -> Array[Term[Arg]] {
  let result = []
  for sub in self.payload_value.subs {
    for arg in sub.args() {
      result.push(arg)
    }
  }
  result
}

///|
pub fn Term::program_blks(self : Term[Program]) -> Array[Term[Blk]] {
  let result = []
  for sub in self.payload_value.subs {
    for blk in sub.blks() {
      result.push(blk)
    }
  }
  result
}

///|
pub fn Term::program_phis(self : Term[Program]) -> Array[Term[Phi]] {
  let result = []
  for sub in self.payload_value.subs {
    for phi in sub.sub_phis() {
      result.push(phi)
    }
  }
  result
}

///|
pub fn Term::program_defs(self : Term[Program]) -> Array[Term[Def]] {
  let result = []
  for sub in self.payload_value.subs {
    for def in sub.sub_defs() {
      result.push(def)
    }
  }
  result
}

///|
pub fn Term::program_jmps(self : Term[Program]) -> Array[Term[Jmp]] {
  let result = []
  for sub in self.payload_value.subs {
    for jmp in sub.sub_jmps() {
      result.push(jmp)
    }
  }
  result
}

///|
pub fn Term::blk_terms(
  self : Term[Blk],
  include_self? : Bool = true,
) -> Array[IrTerm] {
  let result = []
  if include_self {
    result.push(BlkTerm(self))
  }
  for phi in self.payload_value.phis {
    result.push(PhiTerm(phi))
  }
  for def in self.payload_value.defs {
    result.push(DefTerm(def))
  }
  for jmp in self.payload_value.jmps {
    result.push(JmpTerm(jmp))
  }
  result
}

///|
pub fn Term::sub_terms(
  self : Term[Sub],
  include_self? : Bool = true,
) -> Array[IrTerm] {
  let result = []
  if include_self {
    result.push(SubTerm(self))
  }
  for arg in self.payload_value.args {
    result.push(ArgTerm(arg))
  }
  for blk in self.payload_value.blks {
    for term in blk.blk_terms() {
      result.push(term)
    }
  }
  result
}

///|
pub fn Term::program_terms(
  self : Term[Program],
  include_self? : Bool = true,
) -> Array[IrTerm] {
  let result = []
  if include_self {
    result.push(ProgramTerm(self))
  }
  for sub in self.payload_value.subs {
    for term in sub.sub_terms() {
      result.push(term)
    }
  }
  result
}

///|
pub fn[A] Term::fold_blk_terms(
  self : Term[Blk],
  init : A,
  f : (A, IrTerm) -> A,
  include_self? : Bool = true,
) -> A {
  let mut acc = init
  for term in self.blk_terms(include_self~) {
    acc = f(acc, term)
  }
  acc
}

///|
pub fn[A] Term::fold_sub_terms(
  self : Term[Sub],
  init : A,
  f : (A, IrTerm) -> A,
  include_self? : Bool = true,
) -> A {
  let mut acc = init
  for term in self.sub_terms(include_self~) {
    acc = f(acc, term)
  }
  acc
}

///|
pub fn[A] Term::fold_program_terms(
  self : Term[Program],
  init : A,
  f : (A, IrTerm) -> A,
  include_self? : Bool = true,
) -> A {
  let mut acc = init
  for term in self.program_terms(include_self~) {
    acc = f(acc, term)
  }
  acc
}

///|
pub fn Term::find_blk_term(
  self : Term[Blk],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> IrTerm? {
  for term in self.blk_terms(include_self~) {
    if f(term) {
      return Some(term)
    }
  }
  None
}

///|
pub fn Term::find_sub_term(
  self : Term[Sub],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> IrTerm? {
  for term in self.sub_terms(include_self~) {
    if f(term) {
      return Some(term)
    }
  }
  None
}

///|
pub fn Term::find_program_term(
  self : Term[Program],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> IrTerm? {
  for term in self.program_terms(include_self~) {
    if f(term) {
      return Some(term)
    }
  }
  None
}

///|
pub fn Term::exists_blk_term(
  self : Term[Blk],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> Bool {
  self.find_blk_term(f, include_self~) is Some(_)
}

///|
pub fn Term::exists_sub_term(
  self : Term[Sub],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> Bool {
  self.find_sub_term(f, include_self~) is Some(_)
}

///|
pub fn Term::exists_program_term(
  self : Term[Program],
  f : (IrTerm) -> Bool,
  include_self? : Bool = true,
) -> Bool {
  self.find_program_term(f, include_self~) is Some(_)
}

///|
fn apply_arg_term(term : Term[Arg], f : (IrTerm) -> IrTerm) -> Term[Arg] {
  match f(ArgTerm(term)) {
    ArgTerm(next) => next
    _ => term
  }
}

///|
fn apply_phi_term(term : Term[Phi], f : (IrTerm) -> IrTerm) -> Term[Phi] {
  match f(PhiTerm(term)) {
    PhiTerm(next) => next
    _ => term
  }
}

///|
fn apply_def_term(term : Term[Def], f : (IrTerm) -> IrTerm) -> Term[Def] {
  match f(DefTerm(term)) {
    DefTerm(next) => next
    _ => term
  }
}

///|
fn apply_jmp_term(term : Term[Jmp], f : (IrTerm) -> IrTerm) -> Term[Jmp] {
  match f(JmpTerm(term)) {
    JmpTerm(next) => next
    _ => term
  }
}

///|
pub fn Term::map_blk_terms(
  self : Term[Blk],
  f : (IrTerm) -> IrTerm,
) -> Term[Blk] {
  let base = match f(BlkTerm(self)) {
    BlkTerm(next) => next
    _ => self
  }
  base
  .with_phis(base.payload_value.phis.map(term => apply_phi_term(term, f)))
  .with_defs(base.payload_value.defs.map(term => apply_def_term(term, f)))
  .with_jmps(base.payload_value.jmps.map(term => apply_jmp_term(term, f)))
}

///|
pub fn Term::map_sub_terms(
  self : Term[Sub],
  f : (IrTerm) -> IrTerm,
) -> Term[Sub] {
  let base = match f(SubTerm(self)) {
    SubTerm(next) => next
    _ => self
  }
  base.with_payload({
    ..base.payload_value,
    args: base.payload_value.args.map(term => apply_arg_term(term, f)),
    blks: base.payload_value.blks.map(blk => blk.map_blk_terms(f)),
  })
}

///|
pub fn Term::map_program_terms(
  self : Term[Program],
  f : (IrTerm) -> IrTerm,
) -> Term[Program] {
  let base = match f(ProgramTerm(self)) {
    ProgramTerm(next) => next
    _ => self
  }
  base.with_payload({
    subs: base.payload_value.subs.map(sub => sub.map_sub_terms(f)),
  })
}

///|
pub fn Term::sub_parent_term(self : Term[Sub], tid : Tid) -> IrTerm? {
  for arg in self.payload_value.args {
    if arg.tid() == tid {
      return Some(SubTerm(self))
    }
  }
  for blk in self.payload_value.blks {
    if blk.tid() == tid {
      return Some(SubTerm(self))
    }
    for phi in blk.payload_value.phis {
      if phi.tid() == tid {
        return Some(BlkTerm(blk))
      }
    }
    for def in blk.payload_value.defs {
      if def.tid() == tid {
        return Some(BlkTerm(blk))
      }
    }
    for jmp in blk.payload_value.jmps {
      if jmp.tid() == tid {
        return Some(BlkTerm(blk))
      }
    }
  }
  None
}

///|
pub fn Term::program_parent_term(self : Term[Program], tid : Tid) -> IrTerm? {
  for sub in self.payload_value.subs {
    if sub.tid() == tid {
      return Some(ProgramTerm(self))
    }
    match sub.sub_parent_term(tid) {
      Some(parent) => return Some(parent)
      None => ()
    }
  }
  None
}

///|
pub fn Term::program_lookup(
  self : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  match cls {
    ProgramTermClass =>
      if self.tid() == tid {
        Some(ProgramTerm(self))
      } else {
        None
      }
    SubTermClass => self.find_sub(tid).map(term => SubTerm(term))
    ArgTermClass => self.program_find_arg(tid).map(term => ArgTerm(term))
    BlkTermClass => self.program_find_blk(tid).map(term => BlkTerm(term))
    PhiTermClass => self.program_find_phi(tid).map(term => PhiTerm(term))
    DefTermClass => self.program_find_def(tid).map(term => DefTerm(term))
    JmpTermClass => self.program_find_jmp(tid).map(term => JmpTerm(term))
  }
}

///|
pub fn Term::lookup(
  self : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  self.program_lookup(cls, tid)
}

///|
pub fn Program::lookup(
  program : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  program.program_lookup(cls, tid)
}

///|
pub fn Term::program_parent(
  self : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  match cls {
    ProgramTermClass => None
    SubTermClass =>
      match self.find_sub(tid) {
        Some(_) => Some(ProgramTerm(self))
        None => None
      }
    ArgTermClass => {
      for sub in self.payload_value.subs {
        for arg in sub.payload_value.args {
          if arg.tid() == tid {
            return Some(SubTerm(sub))
          }
        }
      }
      None
    }
    BlkTermClass => {
      for sub in self.payload_value.subs {
        for blk in sub.payload_value.blks {
          if blk.tid() == tid {
            return Some(SubTerm(sub))
          }
        }
      }
      None
    }
    PhiTermClass => {
      for blk in self.program_blks() {
        for phi in blk.payload_value.phis {
          if phi.tid() == tid {
            return Some(BlkTerm(blk))
          }
        }
      }
      None
    }
    DefTermClass => {
      for blk in self.program_blks() {
        for def in blk.payload_value.defs {
          if def.tid() == tid {
            return Some(BlkTerm(blk))
          }
        }
      }
      None
    }
    JmpTermClass => {
      for blk in self.program_blks() {
        for jmp in blk.payload_value.jmps {
          if jmp.tid() == tid {
            return Some(BlkTerm(blk))
          }
        }
      }
      None
    }
  }
}

///|
pub fn Term::parent(
  self : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  self.program_parent(cls, tid)
}

///|
pub fn Program::parent(
  program : Term[Program],
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  program.program_parent(cls, tid)
}

///|
pub fn Term::find_phi(self : Term[Blk], tid : Tid) -> Term[Phi]? {
  self.payload_value.phis
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.phis[i])
}

///|
pub fn Term::find_jmp(self : Term[Blk], tid : Tid) -> Term[Jmp]? {
  self.payload_value.jmps
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.jmps[i])
}

///|
pub fn Term::program_find_blk(self : Term[Program], tid : Tid) -> Term[Blk]? {
  for blk in self.program_blks() {
    if blk.tid() == tid {
      return Some(blk)
    }
  }
  None
}

///|
pub fn Term::program_find_phi(self : Term[Program], tid : Tid) -> Term[Phi]? {
  for phi in self.program_phis() {
    if phi.tid() == tid {
      return Some(phi)
    }
  }
  None
}

///|
pub fn Term::program_find_def(self : Term[Program], tid : Tid) -> Term[Def]? {
  for def in self.program_defs() {
    if def.tid() == tid {
      return Some(def)
    }
  }
  None
}

///|
pub fn Term::program_find_jmp(self : Term[Program], tid : Tid) -> Term[Jmp]? {
  for jmp in self.program_jmps() {
    if jmp.tid() == tid {
      return Some(jmp)
    }
  }
  None
}
