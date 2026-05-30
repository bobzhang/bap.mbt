///|
pub(all) enum VarBinding {
  PhiBinding(Term[Phi])
  DefBinding(Term[Def])
}

///|
fn find_def_index(defs : Array[Term[Def]], tid : Tid) -> Int? {
  defs.search_by(term => term.tid() == tid)
}

///|
fn clamp_def_index(index : Int, length : Int) -> Int {
  if index < 0 {
    0
  } else if index > length {
    length
  } else {
    index
  }
}

///|
fn copy_def_range(
  defs : Array[Term[Def]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Def]] {
  let length = defs.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(defs[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(defs[i])
      }
    }
  }
  out
}

///|
fn Term::with_defs(self : Term[Blk], defs : Array[Term[Def]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, defs, })
}

///|
fn Term::split_def_at(self : Term[Blk], index : Int) -> (Term[Blk], Term[Blk]) {
  let defs = self.payload_value.defs
  let split = clamp_def_index(index, defs.length())
  let next_tid = Tid::fresh()
  let left = self.with_payload({
    phis: self.payload_value.phis.copy(),
    defs: copy_def_range(defs, 0, split, false),
    jmps: [Jmp::create_goto(Label::direct(next_tid))],
  })
  let right = Blk::create(
    defs=copy_def_range(defs, split, defs.length(), false),
    jmps=self.payload_value.jmps.copy(),
    tid=next_tid,
  )
  (left, right)
}

///|
pub fn Term::def_count(self : Term[Blk]) -> Int {
  self.payload_value.defs.length()
}

///|
pub fn Term::nth_def(self : Term[Blk], index : Int) -> Term[Def]? {
  if index >= 0 && index < self.payload_value.defs.length() {
    Some(self.payload_value.defs[index])
  } else {
    None
  }
}

///|
pub fn Term::first_def(self : Term[Blk]) -> Term[Def]? {
  self.nth_def(0)
}

///|
pub fn Term::last_def(self : Term[Blk]) -> Term[Def]? {
  self.nth_def(self.payload_value.defs.length() - 1)
}

///|
pub fn Term::next_def(self : Term[Blk], tid : Tid) -> Term[Def]? {
  match find_def_index(self.payload_value.defs, tid) {
    Some(i) => self.nth_def(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_def(self : Term[Blk], tid : Tid) -> Term[Def]? {
  match find_def_index(self.payload_value.defs, tid) {
    Some(i) => self.nth_def(i - 1)
    None => None
  }
}

///|
pub fn Term::defs_after(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Def]] {
  match find_def_index(self.payload_value.defs, tid) {
    Some(i) =>
      copy_def_range(
        self.payload_value.defs,
        i + 1,
        self.payload_value.defs.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::defs_before(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Def]] {
  match find_def_index(self.payload_value.defs, tid) {
    Some(i) => copy_def_range(self.payload_value.defs, 0, i, rev)
    None => []
  }
}

///|
pub fn Term::insert_def_after(
  self : Term[Blk],
  term : Term[Def],
  after? : Tid,
) -> Term[Blk] {
  let defs = self.payload_value.defs.copy()
  let index = match after {
    Some(tid) =>
      match find_def_index(defs, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(defs.length())
  }
  match index {
    Some(i) => {
      defs.insert(i, term)
      self.with_defs(defs)
    }
    None => self
  }
}

///|
pub fn Term::insert_def_before(
  self : Term[Blk],
  term : Term[Def],
  before? : Tid,
) -> Term[Blk] {
  let defs = self.payload_value.defs.copy()
  let index = match before {
    Some(tid) => find_def_index(defs, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      defs.insert(i, term)
      self.with_defs(defs)
    }
    None => self
  }
}

///|
pub fn Term::update_def(self : Term[Blk], term : Term[Def]) -> Term[Blk] {
  let defs = self.payload_value.defs.copy()
  match find_def_index(defs, term.tid()) {
    Some(i) => {
      defs[i] = term
      self.with_defs(defs)
    }
    None => self
  }
}

///|
pub fn Term::remove_def(self : Term[Blk], tid : Tid) -> Term[Blk] {
  self.with_defs(self.payload_value.defs.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_defs(
  self : Term[Blk],
  f : (Term[Def]) -> Term[Def],
) -> Term[Blk] {
  self.with_defs(self.payload_value.defs.map(f))
}

///|
pub fn Term::filter_defs(
  self : Term[Blk],
  f : (Term[Def]) -> Bool,
) -> Term[Blk] {
  self.with_defs(self.payload_value.defs.filter(f))
}

///|
pub fn Term::filter_map_defs(
  self : Term[Blk],
  f : (Term[Def]) -> Term[Def]?,
) -> Term[Blk] {
  self.with_defs(self.payload_value.defs.filter_map(f))
}

///|
pub fn Term::concat_map_defs(
  self : Term[Blk],
  f : (Term[Def]) -> Array[Term[Def]],
) -> Term[Blk] {
  let defs = []
  for term in self.payload_value.defs {
    for mapped in f(term) {
      defs.push(mapped)
    }
  }
  self.with_defs(defs)
}

///|
pub fn Term::split_before_def(
  self : Term[Blk],
  term : Term[Def],
) -> (Term[Blk], Term[Blk]) {
  match find_def_index(self.payload_value.defs, term.tid()) {
    Some(i) => self.split_def_at(i)
    None => self.split_def_at(self.payload_value.defs.length())
  }
}

///|
pub fn Term::split_after_def(
  self : Term[Blk],
  term : Term[Def],
) -> (Term[Blk], Term[Blk]) {
  match find_def_index(self.payload_value.defs, term.tid()) {
    Some(i) => self.split_def_at(i + 1)
    None => self.split_def_at(self.payload_value.defs.length())
  }
}

///|
pub fn Term::split_top_defs(self : Term[Blk]) -> (Term[Blk], Term[Blk]) {
  self.split_def_at(0)
}

///|
pub fn Term::split_bottom_defs(self : Term[Blk]) -> (Term[Blk], Term[Blk]) {
  self.split_def_at(self.payload_value.defs.length())
}

///|
pub fn Term::find_var(self : Term[Blk], variable : Var) -> VarBinding? {
  let defs = self.payload_value.defs
  for offset in 0..<defs.length() {
    let term = defs[defs.length() - offset - 1]
    if term.lhs() == variable {
      return Some(DefBinding(term))
    }
  }
  for phi in self.payload_value.phis {
    if phi.phi_lhs() == variable {
      return Some(PhiBinding(phi))
    }
  }
  None
}

///|
pub fn Term::uses_var(self : Term[Blk], variable : Var) -> Bool {
  self.blk_free_vars().any(item => item == variable)
}

///|
pub fn Term::def_occurs_after(self : Term[Blk], after : Tid, tid : Tid) -> Bool {
  after == tid || self.defs_after(after).any(term => term.tid() == tid)
}
