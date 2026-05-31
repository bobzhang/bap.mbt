///|
pub(all) enum VarBinding {
  PhiBinding(Term[Phi])
  DefBinding(Term[Def])
}

///|
fn find_sub_index(subs : Array[Term[Sub]], tid : Tid) -> Int? {
  subs.search_by(term => term.tid() == tid)
}

///|
fn find_arg_index(args : Array[Term[Arg]], tid : Tid) -> Int? {
  args.search_by(term => term.tid() == tid)
}

///|
fn find_def_index(defs : Array[Term[Def]], tid : Tid) -> Int? {
  defs.search_by(term => term.tid() == tid)
}

///|
fn find_phi_index(phis : Array[Term[Phi]], tid : Tid) -> Int? {
  phis.search_by(term => term.tid() == tid)
}

///|
fn find_jmp_index(jmps : Array[Term[Jmp]], tid : Tid) -> Int? {
  jmps.search_by(term => term.tid() == tid)
}

///|
fn find_blk_index(blks : Array[Term[Blk]], tid : Tid) -> Int? {
  blks.search_by(term => term.tid() == tid)
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
fn copy_sub_range(
  subs : Array[Term[Sub]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Sub]] {
  let length = subs.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(subs[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(subs[i])
      }
    }
  }
  out
}

///|
fn copy_arg_range(
  args : Array[Term[Arg]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Arg]] {
  let length = args.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(args[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(args[i])
      }
    }
  }
  out
}

///|
fn copy_blk_range(
  blks : Array[Term[Blk]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Blk]] {
  let length = blks.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(blks[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(blks[i])
      }
    }
  }
  out
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
fn copy_phi_range(
  phis : Array[Term[Phi]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Phi]] {
  let length = phis.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(phis[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(phis[i])
      }
    }
  }
  out
}

///|
fn copy_jmp_range(
  jmps : Array[Term[Jmp]],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[Term[Jmp]] {
  let length = jmps.length()
  let from = clamp_def_index(start, length)
  let until = clamp_def_index(stop, length)
  let out = []
  if from < until {
    if rev {
      for offset in 0..<(until - from) {
        out.push(jmps[until - offset - 1])
      }
    } else {
      for i in from..<until {
        out.push(jmps[i])
      }
    }
  }
  out
}

///|
fn Term::with_subs(
  self : Term[Program],
  subs : Array[Term[Sub]],
) -> Term[Program] {
  self.with_payload({ subs, })
}

///|
fn Term::with_args(self : Term[Sub], args : Array[Term[Arg]]) -> Term[Sub] {
  self.with_payload({ ..self.payload_value, args, })
}

///|
fn Term::with_defs(self : Term[Blk], defs : Array[Term[Def]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, defs, })
}

///|
fn Term::with_phis(self : Term[Blk], phis : Array[Term[Phi]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, phis, })
}

///|
fn Term::with_jmps(self : Term[Blk], jmps : Array[Term[Jmp]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, jmps, })
}

///|
fn Term::with_blks(self : Term[Sub], blks : Array[Term[Blk]]) -> Term[Sub] {
  self.with_payload({ ..self.payload_value, blks, })
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
pub fn Term::sub_count(self : Term[Program]) -> Int {
  self.payload_value.subs.length()
}

///|
pub fn Term::nth_sub(self : Term[Program], index : Int) -> Term[Sub]? {
  if index >= 0 && index < self.payload_value.subs.length() {
    Some(self.payload_value.subs[index])
  } else {
    None
  }
}

///|
pub fn Term::first_sub(self : Term[Program]) -> Term[Sub]? {
  self.nth_sub(0)
}

///|
pub fn Term::last_sub(self : Term[Program]) -> Term[Sub]? {
  self.nth_sub(self.payload_value.subs.length() - 1)
}

///|
pub fn Term::next_sub(self : Term[Program], tid : Tid) -> Term[Sub]? {
  match find_sub_index(self.payload_value.subs, tid) {
    Some(i) => self.nth_sub(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_sub(self : Term[Program], tid : Tid) -> Term[Sub]? {
  match find_sub_index(self.payload_value.subs, tid) {
    Some(i) => self.nth_sub(i - 1)
    None => None
  }
}

///|
pub fn Term::subs_after(
  self : Term[Program],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Sub]] {
  match find_sub_index(self.payload_value.subs, tid) {
    Some(i) =>
      copy_sub_range(
        self.payload_value.subs,
        i + 1,
        self.payload_value.subs.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::subs_before(
  self : Term[Program],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Sub]] {
  match find_sub_index(self.payload_value.subs, tid) {
    Some(i) => copy_sub_range(self.payload_value.subs, 0, i, rev)
    None => []
  }
}

///|
pub fn Term::insert_sub_after(
  self : Term[Program],
  term : Term[Sub],
  after? : Tid,
) -> Term[Program] {
  let subs = self.payload_value.subs.copy()
  let index = match after {
    Some(tid) =>
      match find_sub_index(subs, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(subs.length())
  }
  match index {
    Some(i) => {
      subs.insert(i, term)
      self.with_subs(subs)
    }
    None => self
  }
}

///|
pub fn Term::insert_sub_before(
  self : Term[Program],
  term : Term[Sub],
  before? : Tid,
) -> Term[Program] {
  let subs = self.payload_value.subs.copy()
  let index = match before {
    Some(tid) => find_sub_index(subs, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      subs.insert(i, term)
      self.with_subs(subs)
    }
    None => self
  }
}

///|
pub fn Term::update_sub(
  self : Term[Program],
  term : Term[Sub],
) -> Term[Program] {
  let subs = self.payload_value.subs.copy()
  match find_sub_index(subs, term.tid()) {
    Some(i) => {
      subs[i] = term
      self.with_subs(subs)
    }
    None => self
  }
}

///|
pub fn Term::remove_sub(self : Term[Program], tid : Tid) -> Term[Program] {
  self.with_subs(self.payload_value.subs.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_subs(
  self : Term[Program],
  f : (Term[Sub]) -> Term[Sub],
) -> Term[Program] {
  self.with_subs(self.payload_value.subs.map(f))
}

///|
pub fn Term::filter_subs(
  self : Term[Program],
  f : (Term[Sub]) -> Bool,
) -> Term[Program] {
  self.with_subs(self.payload_value.subs.filter(f))
}

///|
pub fn Term::filter_map_subs(
  self : Term[Program],
  f : (Term[Sub]) -> Term[Sub]?,
) -> Term[Program] {
  self.with_subs(self.payload_value.subs.filter_map(f))
}

///|
pub fn Term::concat_map_subs(
  self : Term[Program],
  f : (Term[Sub]) -> Array[Term[Sub]],
) -> Term[Program] {
  let subs = []
  for term in self.payload_value.subs {
    for mapped in f(term) {
      subs.push(mapped)
    }
  }
  self.with_subs(subs)
}

///|
pub fn Term::arg_count(self : Term[Sub]) -> Int {
  self.payload_value.args.length()
}

///|
pub fn Term::nth_arg(self : Term[Sub], index : Int) -> Term[Arg]? {
  if index >= 0 && index < self.payload_value.args.length() {
    Some(self.payload_value.args[index])
  } else {
    None
  }
}

///|
pub fn Term::first_arg(self : Term[Sub]) -> Term[Arg]? {
  self.nth_arg(0)
}

///|
pub fn Term::last_arg(self : Term[Sub]) -> Term[Arg]? {
  self.nth_arg(self.payload_value.args.length() - 1)
}

///|
pub fn Term::next_arg(self : Term[Sub], tid : Tid) -> Term[Arg]? {
  match find_arg_index(self.payload_value.args, tid) {
    Some(i) => self.nth_arg(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_arg(self : Term[Sub], tid : Tid) -> Term[Arg]? {
  match find_arg_index(self.payload_value.args, tid) {
    Some(i) => self.nth_arg(i - 1)
    None => None
  }
}

///|
pub fn Term::args_after(
  self : Term[Sub],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Arg]] {
  match find_arg_index(self.payload_value.args, tid) {
    Some(i) =>
      copy_arg_range(
        self.payload_value.args,
        i + 1,
        self.payload_value.args.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::args_before(
  self : Term[Sub],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Arg]] {
  match find_arg_index(self.payload_value.args, tid) {
    Some(i) => copy_arg_range(self.payload_value.args, 0, i, rev)
    None => []
  }
}

///|
pub fn Term::insert_arg_after(
  self : Term[Sub],
  term : Term[Arg],
  after? : Tid,
) -> Term[Sub] {
  let args = self.payload_value.args.copy()
  let index = match after {
    Some(tid) =>
      match find_arg_index(args, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(args.length())
  }
  match index {
    Some(i) => {
      args.insert(i, term)
      self.with_args(args)
    }
    None => self
  }
}

///|
pub fn Term::insert_arg_before(
  self : Term[Sub],
  term : Term[Arg],
  before? : Tid,
) -> Term[Sub] {
  let args = self.payload_value.args.copy()
  let index = match before {
    Some(tid) => find_arg_index(args, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      args.insert(i, term)
      self.with_args(args)
    }
    None => self
  }
}

///|
pub fn Term::update_arg(self : Term[Sub], term : Term[Arg]) -> Term[Sub] {
  let args = self.payload_value.args.copy()
  match find_arg_index(args, term.tid()) {
    Some(i) => {
      args[i] = term
      self.with_args(args)
    }
    None => self
  }
}

///|
pub fn Term::remove_arg(self : Term[Sub], tid : Tid) -> Term[Sub] {
  self.with_args(self.payload_value.args.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_args(
  self : Term[Sub],
  f : (Term[Arg]) -> Term[Arg],
) -> Term[Sub] {
  self.with_args(self.payload_value.args.map(f))
}

///|
pub fn Term::filter_args(
  self : Term[Sub],
  f : (Term[Arg]) -> Bool,
) -> Term[Sub] {
  self.with_args(self.payload_value.args.filter(f))
}

///|
pub fn Term::filter_map_args(
  self : Term[Sub],
  f : (Term[Arg]) -> Term[Arg]?,
) -> Term[Sub] {
  self.with_args(self.payload_value.args.filter_map(f))
}

///|
pub fn Term::concat_map_args(
  self : Term[Sub],
  f : (Term[Arg]) -> Array[Term[Arg]],
) -> Term[Sub] {
  let args = []
  for term in self.payload_value.args {
    for mapped in f(term) {
      args.push(mapped)
    }
  }
  self.with_args(args)
}

///|
pub fn Term::blk_count(self : Term[Sub]) -> Int {
  self.payload_value.blks.length()
}

///|
pub fn Term::nth_blk(self : Term[Sub], index : Int) -> Term[Blk]? {
  if index >= 0 && index < self.payload_value.blks.length() {
    Some(self.payload_value.blks[index])
  } else {
    None
  }
}

///|
pub fn Term::first_blk(self : Term[Sub]) -> Term[Blk]? {
  self.nth_blk(0)
}

///|
pub fn Term::last_blk(self : Term[Sub]) -> Term[Blk]? {
  self.nth_blk(self.payload_value.blks.length() - 1)
}

///|
pub fn Term::next_blk(self : Term[Sub], tid : Tid) -> Term[Blk]? {
  match find_blk_index(self.payload_value.blks, tid) {
    Some(i) => self.nth_blk(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_blk(self : Term[Sub], tid : Tid) -> Term[Blk]? {
  match find_blk_index(self.payload_value.blks, tid) {
    Some(i) => self.nth_blk(i - 1)
    None => None
  }
}

///|
pub fn Term::blks_after(
  self : Term[Sub],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Blk]] {
  match find_blk_index(self.payload_value.blks, tid) {
    Some(i) =>
      copy_blk_range(
        self.payload_value.blks,
        i + 1,
        self.payload_value.blks.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::blks_before(
  self : Term[Sub],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Blk]] {
  match find_blk_index(self.payload_value.blks, tid) {
    Some(i) => copy_blk_range(self.payload_value.blks, 0, i, rev)
    None => []
  }
}

///|
pub fn Term::insert_blk_after(
  self : Term[Sub],
  term : Term[Blk],
  after? : Tid,
) -> Term[Sub] {
  let blks = self.payload_value.blks.copy()
  let index = match after {
    Some(tid) =>
      match find_blk_index(blks, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(blks.length())
  }
  match index {
    Some(i) => {
      blks.insert(i, term)
      self.with_blks(blks)
    }
    None => self
  }
}

///|
pub fn Term::insert_blk_before(
  self : Term[Sub],
  term : Term[Blk],
  before? : Tid,
) -> Term[Sub] {
  let blks = self.payload_value.blks.copy()
  let index = match before {
    Some(tid) => find_blk_index(blks, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      blks.insert(i, term)
      self.with_blks(blks)
    }
    None => self
  }
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
pub fn Term::phi_count(self : Term[Blk]) -> Int {
  self.payload_value.phis.length()
}

///|
pub fn Term::nth_phi(self : Term[Blk], index : Int) -> Term[Phi]? {
  if index >= 0 && index < self.payload_value.phis.length() {
    Some(self.payload_value.phis[index])
  } else {
    None
  }
}

///|
pub fn Term::first_phi(self : Term[Blk]) -> Term[Phi]? {
  self.nth_phi(0)
}

///|
pub fn Term::last_phi(self : Term[Blk]) -> Term[Phi]? {
  self.nth_phi(self.payload_value.phis.length() - 1)
}

///|
pub fn Term::next_phi(self : Term[Blk], tid : Tid) -> Term[Phi]? {
  match find_phi_index(self.payload_value.phis, tid) {
    Some(i) => self.nth_phi(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_phi(self : Term[Blk], tid : Tid) -> Term[Phi]? {
  match find_phi_index(self.payload_value.phis, tid) {
    Some(i) => self.nth_phi(i - 1)
    None => None
  }
}

///|
pub fn Term::jmp_count(self : Term[Blk]) -> Int {
  self.payload_value.jmps.length()
}

///|
pub fn Term::nth_jmp(self : Term[Blk], index : Int) -> Term[Jmp]? {
  if index >= 0 && index < self.payload_value.jmps.length() {
    Some(self.payload_value.jmps[index])
  } else {
    None
  }
}

///|
pub fn Term::first_jmp(self : Term[Blk]) -> Term[Jmp]? {
  self.nth_jmp(0)
}

///|
pub fn Term::last_jmp(self : Term[Blk]) -> Term[Jmp]? {
  self.nth_jmp(self.payload_value.jmps.length() - 1)
}

///|
pub fn Term::next_jmp(self : Term[Blk], tid : Tid) -> Term[Jmp]? {
  match find_jmp_index(self.payload_value.jmps, tid) {
    Some(i) => self.nth_jmp(i + 1)
    None => None
  }
}

///|
pub fn Term::prev_jmp(self : Term[Blk], tid : Tid) -> Term[Jmp]? {
  match find_jmp_index(self.payload_value.jmps, tid) {
    Some(i) => self.nth_jmp(i - 1)
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
pub fn Term::phis_after(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Phi]] {
  match find_phi_index(self.payload_value.phis, tid) {
    Some(i) =>
      copy_phi_range(
        self.payload_value.phis,
        i + 1,
        self.payload_value.phis.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::phis_before(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Phi]] {
  match find_phi_index(self.payload_value.phis, tid) {
    Some(i) => copy_phi_range(self.payload_value.phis, 0, i, rev)
    None => []
  }
}

///|
pub fn Term::jmps_after(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Jmp]] {
  match find_jmp_index(self.payload_value.jmps, tid) {
    Some(i) =>
      copy_jmp_range(
        self.payload_value.jmps,
        i + 1,
        self.payload_value.jmps.length(),
        rev,
      )
    None => []
  }
}

///|
pub fn Term::jmps_before(
  self : Term[Blk],
  tid : Tid,
  rev? : Bool = false,
) -> Array[Term[Jmp]] {
  match find_jmp_index(self.payload_value.jmps, tid) {
    Some(i) => copy_jmp_range(self.payload_value.jmps, 0, i, rev)
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
pub fn Term::insert_phi_after(
  self : Term[Blk],
  term : Term[Phi],
  after? : Tid,
) -> Term[Blk] {
  let phis = self.payload_value.phis.copy()
  let index = match after {
    Some(tid) =>
      match find_phi_index(phis, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(phis.length())
  }
  match index {
    Some(i) => {
      phis.insert(i, term)
      self.with_phis(phis)
    }
    None => self
  }
}

///|
pub fn Term::insert_phi_before(
  self : Term[Blk],
  term : Term[Phi],
  before? : Tid,
) -> Term[Blk] {
  let phis = self.payload_value.phis.copy()
  let index = match before {
    Some(tid) => find_phi_index(phis, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      phis.insert(i, term)
      self.with_phis(phis)
    }
    None => self
  }
}

///|
pub fn Term::insert_jmp_after(
  self : Term[Blk],
  term : Term[Jmp],
  after? : Tid,
) -> Term[Blk] {
  let jmps = self.payload_value.jmps.copy()
  let index = match after {
    Some(tid) =>
      match find_jmp_index(jmps, tid) {
        Some(i) => Some(i + 1)
        None => None
      }
    None => Some(jmps.length())
  }
  match index {
    Some(i) => {
      jmps.insert(i, term)
      self.with_jmps(jmps)
    }
    None => self
  }
}

///|
pub fn Term::insert_jmp_before(
  self : Term[Blk],
  term : Term[Jmp],
  before? : Tid,
) -> Term[Blk] {
  let jmps = self.payload_value.jmps.copy()
  let index = match before {
    Some(tid) => find_jmp_index(jmps, tid)
    None => Some(0)
  }
  match index {
    Some(i) => {
      jmps.insert(i, term)
      self.with_jmps(jmps)
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
pub fn Term::update_phi_term(self : Term[Blk], term : Term[Phi]) -> Term[Blk] {
  let phis = self.payload_value.phis.copy()
  match find_phi_index(phis, term.tid()) {
    Some(i) => {
      phis[i] = term
      self.with_phis(phis)
    }
    None => self
  }
}

///|
pub fn Term::remove_phi_term(self : Term[Blk], tid : Tid) -> Term[Blk] {
  self.with_phis(self.payload_value.phis.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_phis(
  self : Term[Blk],
  f : (Term[Phi]) -> Term[Phi],
) -> Term[Blk] {
  self.with_phis(self.payload_value.phis.map(f))
}

///|
pub fn Term::update_jmp(self : Term[Blk], term : Term[Jmp]) -> Term[Blk] {
  let jmps = self.payload_value.jmps.copy()
  match find_jmp_index(jmps, term.tid()) {
    Some(i) => {
      jmps[i] = term
      self.with_jmps(jmps)
    }
    None => self
  }
}

///|
pub fn Term::remove_jmp(self : Term[Blk], tid : Tid) -> Term[Blk] {
  self.with_jmps(self.payload_value.jmps.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_jmps(
  self : Term[Blk],
  f : (Term[Jmp]) -> Term[Jmp],
) -> Term[Blk] {
  self.with_jmps(self.payload_value.jmps.map(f))
}

///|
pub fn Term::map_blk_elts(
  self : Term[Blk],
  phi? : (Term[Phi]) -> Term[Phi],
  def? : (Term[Def]) -> Term[Def],
  jmp? : (Term[Jmp]) -> Term[Jmp],
) -> Term[Blk] {
  self.with_payload({
    phis: match phi {
      Some(f) => self.payload_value.phis.map(f)
      None => self.payload_value.phis.copy()
    },
    defs: match def {
      Some(f) => self.payload_value.defs.map(f)
      None => self.payload_value.defs.copy()
    },
    jmps: match jmp {
      Some(f) => self.payload_value.jmps.map(f)
      None => self.payload_value.jmps.copy()
    },
  })
}

///|
pub fn Term::update_blk(self : Term[Sub], blk : Term[Blk]) -> Term[Sub] {
  let blks = self.payload_value.blks.copy()
  match find_blk_index(blks, blk.tid()) {
    Some(i) => {
      blks[i] = blk
      self.with_blks(blks)
    }
    None => self
  }
}

///|
pub fn Term::remove_blk(self : Term[Sub], tid : Tid) -> Term[Sub] {
  self.with_blks(self.payload_value.blks.filter(term => term.tid() != tid))
}

///|
pub fn Term::map_blks(
  self : Term[Sub],
  f : (Term[Blk]) -> Term[Blk],
) -> Term[Sub] {
  self.with_blks(self.payload_value.blks.map(f))
}

///|
pub fn Term::filter_blks(
  self : Term[Sub],
  f : (Term[Blk]) -> Bool,
) -> Term[Sub] {
  self.with_blks(self.payload_value.blks.filter(f))
}

///|
pub fn Term::filter_map_blks(
  self : Term[Sub],
  f : (Term[Blk]) -> Term[Blk]?,
) -> Term[Sub] {
  self.with_blks(self.payload_value.blks.filter_map(f))
}

///|
pub fn Term::concat_map_blks(
  self : Term[Sub],
  f : (Term[Blk]) -> Array[Term[Blk]],
) -> Term[Sub] {
  let blks = []
  for term in self.payload_value.blks {
    for mapped in f(term) {
      blks.push(mapped)
    }
  }
  self.with_blks(blks)
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
pub fn Term::split_defs_while(
  self : Term[Blk],
  f : (Term[Def]) -> Bool,
) -> (Term[Blk], Term[Blk]) {
  match self.payload_value.defs.search_by(term => !f(term)) {
    Some(i) => self.split_def_at(i)
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
