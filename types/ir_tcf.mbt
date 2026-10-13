///|
let tcf_counter : Ref[Int32] = Ref(0)

///|
fn tcf_next_id() -> Int32 {
  tcf_counter.val = tcf_counter.val + 1
  tcf_counter.val
}

///|
fn tcf_fresh_var() -> Var {
  Var::new(name="c#\{tcf_next_id()}", typ=ValueType::bool_t(), is_virtual=true)
}

///|
pub fn Exp::is_trivial_condition(self : Exp) -> Bool {
  match self {
    Int(_) | Var(_) => true
    _ => false
  }
}

///|
pub fn Term::jmp_has_trivial_condition(self : Term[Jmp]) -> Bool {
  self.cond().is_trivial_condition()
}

///|
fn Term::tcf_jmp(self : Term[Jmp], defs : Array[Term[Def]]) -> Term[Jmp] {
  match self.cond() {
    Int(_) | Var(_) => self
    cond => {
      let variable = tcf_fresh_var()
      defs.push(Def::create(variable, cond))
      self.with_cond(Var(variable))
    }
  }
}

///|
pub fn Term::blk_to_trivial_condition_form(self : Term[Blk]) -> Term[Blk] {
  let defs = self.defs()
  let jmps = []
  for jmp in self.jmps() {
    jmps.push(jmp.tcf_jmp(defs))
  }
  self.with_defs(defs).with_jmps(jmps)
}

///|
pub fn Term::sub_to_trivial_condition_form(self : Term[Sub]) -> Term[Sub] {
  self.map_blks(blk => blk.blk_to_trivial_condition_form())
}

///|
pub fn Term::program_to_trivial_condition_form(
  self : Term[Program],
) -> Term[Program] {
  self.with_payload({
    subs: self.subs().map(sub => sub.sub_to_trivial_condition_form()),
  })
}
