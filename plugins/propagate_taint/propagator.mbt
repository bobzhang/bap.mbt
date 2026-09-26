// Port of `plugins/propagate_taint/propagator.ml`: taint propagation by
// microexecution.
//
// Upstream composes, by OCaml class inheritance, the microx conqueror
// (`Microx.Conqueror.main`, which explores the program), the concretizer
// (`Microx.Concretizer.main`, which invents values for unknown inputs)
// and the legacy taint propagator (`Bap.Std.Taint.propagator`, which
// overrides the expression interpreter to move taints along the data
// flow). The microx port has no open recursion, so this module drives the
// exploration itself, step by step as `Microx_conqueror.main` does, over
// the public microx state (`@microx.Context`: trace, visits, checkpoints,
// backtracking, loop and step bounds) and evaluates expressions with a
// taint-aware interpreter that uses the concretizing `@microx.Expi` for
// variables, memory cells and unknown values.
//
// Checkpoints restore the taint state that was current when they were
// recorded, while the collected results (the taints of the variables
// read by each term) are kept, as upstream `context#merge`.

///|
/// The results of a propagation (upstream `Propagator.Result.t`).
pub struct PropagationResult {
  priv visited : @immut_hashmap.HashMap[@types.Tid, Int]
  priv regs : TermTaints
  priv ptrs : TermTaints
}

///|
/// No visited terms and no taints.
pub fn PropagationResult::empty() -> PropagationResult {
  {
    visited: @immut_hashmap.HashMap::new(),
    regs: @immut_hashmap.HashMap::new(),
    ptrs: @immut_hashmap.HashMap::new(),
  }
}

///|
fn union_taints(x : TermTaints, y : TermTaints) -> TermTaints {
  y.fold(init=x, (acc, tid, map) => {
    match acc.get(tid) {
      None => acc.add(tid, map)
      Some(old) => acc.add(tid, old.union(map))
    }
  })
}

///|
/// The union of two results: visit counts are maximized and taints are
/// merged (upstream `Result.union`).
pub fn PropagationResult::union(
  self : PropagationResult,
  other : PropagationResult,
) -> PropagationResult {
  let visited = other.visited.fold(init=self.visited, (acc, tid, n) => {
    match acc.get(tid) {
      Some(m) if m >= n => acc
      _ => acc.add(tid, n)
    }
  })
  {
    visited,
    regs: union_taints(self.regs, other.regs),
    ptrs: union_taints(self.ptrs, other.ptrs),
  }
}

///|
/// The taints of the values of the variables read by the term (the
/// `tainted-regs` attribute).
pub fn PropagationResult::tainted_regs(
  self : PropagationResult,
  tid : @types.Tid,
) -> @taint.TaintMap {
  self.regs.get(tid).unwrap_or(@taint.TaintMap::empty())
}

///|
/// The taints of the memory pointed by the variables read by the term
/// (the `tainted-ptrs` attribute).
pub fn PropagationResult::tainted_ptrs(
  self : PropagationResult,
  tid : @types.Tid,
) -> @taint.TaintMap {
  self.ptrs.get(tid).unwrap_or(@taint.TaintMap::empty())
}

///|
/// Whether the term reads a tainted variable.
pub fn PropagationResult::is_tainted(
  self : PropagationResult,
  tid : @types.Tid,
) -> Bool {
  self.regs.contains(tid) || self.ptrs.contains(tid)
}

///|
/// Whether the term was evaluated.
pub fn PropagationResult::is_visited(
  self : PropagationResult,
  tid : @types.Tid,
) -> Bool {
  self.visited.contains(tid)
}

///|
/// The number of visits of every visited term.
pub fn PropagationResult::visited(
  self : PropagationResult,
) -> Map[@types.Tid, Int] {
  let out : Map[@types.Tid, Int] = Map([])
  for tid, n in self.visited {
    out[tid] = n
  }
  out
}

///|
/// The identifiers of all terms with taints, sorted.
pub fn PropagationResult::tainted_terms(
  self : PropagationResult,
) -> Array[@types.Tid] {
  let set : TaintSet = self.regs
    .keys()
    .fold(init=@immut_hashset.HashSet::new(), (acc, t) => acc.add(t))
  sorted_taints(self.ptrs.keys().fold(init=set, (acc, t) => acc.add(t)))
}

///|
/// The entry point of a propagation (upstream ``[`Term of tid | `Name of
/// string]``).
pub(all) enum Point {
  Term(@types.Tid)
  Name(String)
}

///|
/// Errors of the propagator.
pub(all) suberror PropagatorError {
  /// the entry point is not a subroutine of the program
  EntryPointNotFound
} derive(Eq, Debug)

///|
pub extend PropagatorError with Eq::{not_equal, equal}

///|
pub extend PropagatorError with Debug::{to_repr}

///|
/// A snapshot of the taint state at a checkpoint.
priv struct Snapshot {
  taint : TaintContext
  subs : @list.List[@types.Term[@types.Sub]]
}

///|
priv struct Run {
  expi : @microx.Expi
  deterministic : Bool
  mut ctxt : @microx.Context
  /// the expression state, while an expression is evaluated
  mut exp : @microx.ExpContext
  mut taint : TaintContext
  /// the taints of variables read by terms (upstream `tvs`)
  mut regs : TermTaints
  /// the taints of memory pointed by variables read by terms (`tms`)
  mut ptrs : TermTaints
  /// the call stack (mirrors the one of the microx context)
  mut subs : @list.List[@types.Term[@types.Sub]]
  /// the most recently entered term (the head of the trace)
  mut term : @types.Tid?
  snapshots : Map[String, Snapshot]
}

///|
fn snapshot_key(sub : @types.Term[@types.Sub], p : @types.Tid) -> String {
  "\{sub.tid().to_string()} \{p.to_string()}"
}

// ---------------------------------------------------------------------------
// The taint-aware expression interpreter (upstream `Taint.propagator`
// over `Microx.Concretizer.main` over `Expi.t`).

///|
fn Run::create(self : Run, value : @types.BilResultValue) -> @types.BilResult {
  let (exp, r) = self.exp.create_value(value)
  self.exp = exp
  r
}

///|
fn Run::word(self : Run, w : @types.Word) -> @types.BilResult {
  self.create(BilResultImm(w))
}

///|
fn Run::bot(self : Run) -> @types.BilResult {
  self.create(BilResultBot)
}

///|
/// Looks up a variable (concretizing unknown values) and records the
/// taints of its value for the current term (upstream `main#lookup`).
fn Run::lookup(self : Run, v : @types.Var) -> @types.BilResult {
  let (exp, r) = self.expi.lookup(self.exp, v)
  self.exp = exp
  match self.term {
    None => ()
    Some(tid) => {
      self.regs = propagate_taints(self.regs, tid, v, self.taint.reg_taints(r))
      match r.value() {
        BilResultImm(a) =>
          self.ptrs = propagate_taints(
            self.ptrs,
            tid,
            v,
            self.taint.ptr_taints(a),
          )
        _ => ()
      }
    }
  }
  r
}

///|
fn Run::bind(self : Run, v : @types.Var, r : @types.BilResult) -> Unit {
  self.exp = self.exp.update(v, r)
}

///|
fn Run::load(
  self : Run,
  storage : @types.BilResultStorage,
  addr : @types.Word,
) -> @types.BilResult {
  let (exp, r) = self.expi.load(self.exp, storage, addr)
  self.exp = exp
  r
}

///|
fn Run::imm(self : Run, exp : @types.Exp) -> @types.Word? {
  match self.eval(exp).value() {
    BilResultImm(w) => Some(w)
    _ => None
  }
}

///|
/// Unknown memories are sparse storages (upstream `main#empty`).
fn Run::mem(self : Run, exp : @types.Exp) -> @types.BilResultStorage? {
  match self.eval(exp).value() {
    BilResultMem(storage) => Some(storage)
    BilResultBot => Some(@types.BilResultStorage::sparse())
    BilResultImm(_) => None
  }
}

///|
fn value_size(mem : @types.Exp) -> Int? {
  match mem.infer_type() {
    Ok(Mem(value_width~, ..)) => Some(value_width)
    _ => None
  }
}

///|
fn is_bit(word : @types.Word, value : Bool) -> Bool {
  word.bitwidth() == 1 && (if value { word.is_one() } else { word.is_zero() })
}

///|
/// Attaches the union of the taints of `args` to `rr` (upstream
/// `propagator#propagate`).
fn Run::propagate(
  self : Run,
  args : Array[@types.BilResult],
  rr : @types.BilResult,
) -> Unit {
  let init : TaintSet = @immut_hashset.HashSet::new()
  let ts = args.fold(init~, (acc, r) => acc.union(self.taint.reg_taints(r)))
  self.taint = self.taint.taint_reg(rr, ts)
}

///|
/// Re-evaluates the operand and propagates its taints to the result
/// (upstream `propagator#eval`).
fn Run::transfer1(
  self : Run,
  e : @types.Exp,
  rr : @types.BilResult,
) -> @types.BilResult {
  let re = self.eval(e)
  self.propagate([re], rr)
  rr
}

///|
/// Re-evaluates both operands and propagates their taints to the result
/// (upstream `propagator#eval2`).
fn Run::transfer2(
  self : Run,
  e1 : @types.Exp,
  e2 : @types.Exp,
  rr : @types.BilResult,
) -> @types.BilResult {
  let r1 = self.eval(e1)
  let r2 = self.eval(e2)
  self.propagate([r1, r2], rr)
  rr
}

///|
fn Run::eval_load(
  self : Run,
  mem : @types.Exp,
  addr : @types.Exp,
  typ : @types.ValueType,
) -> @types.BilResult {
  let r = match (value_size(mem), typ) {
    (Some(vs), Imm(sz)) if vs == sz =>
      match self.mem(mem) {
        None => self.bot()
        Some(storage) =>
          match self.imm(addr) {
            None => self.bot()
            Some(a) => self.load(storage, a)
          }
      }
    _ => self.bot()
  }
  // upstream `propagator#eval_load`
  match self.eval(addr).value() {
    BilResultImm(a) =>
      self.taint = self.taint.taint_reg(r, self.taint.ptr_taints(a))
    _ => ()
  }
  r
}

///|
fn Run::eval_store(
  self : Run,
  mem : @types.Exp,
  addr : @types.Exp,
  value : @types.Exp,
) -> @types.BilResult {
  // upstream `propagator#eval_store` evaluates the stored value first
  let rv = self.eval(value)
  let size = match value.infer_type() {
    Ok(Imm(sz)) => Some(sz)
    _ => None
  }
  let rr = match (value_size(mem), size) {
    (Some(vs), Some(sz)) if vs == sz =>
      match self.mem(mem) {
        None => self.bot()
        Some(storage) =>
          match self.imm(addr) {
            None => self.bot()
            Some(a) =>
              match self.imm(value) {
                None => self.bot()
                Some(w) => self.create(BilResultMem(storage.save(a, w)))
              }
          }
      }
    _ => self.bot()
  }
  match (self.eval(addr).value(), size.bind(@types.Size::of_int_opt)) {
    (BilResultImm(a), Some(s)) =>
      self.taint = self.taint.taint_ptr(a, s, self.taint.reg_taints(rv))
    _ => ()
  }
  rr
}

///|
fn Run::eval(self : Run, exp : @types.Exp) -> @types.BilResult {
  match exp {
    Int(w) => self.word(w)
    Var(v) => self.lookup(v)
    Unknown(_, _) => {
      let (e, r) = self.expi.eval_exp(self.exp, exp)
      self.exp = e
      r
    }
    Load(mem~, addr~, typ~, ..) => self.eval_load(mem, addr, typ)
    Store(mem~, addr~, value~, ..) => self.eval_store(mem, addr, value)
    Let(v, value, body) => {
      let bound = self.eval(value)
      let saved = self.lookup(v)
      self.bind(v, bound)
      let result = self.eval(body)
      self.bind(v, saved)
      result
    }
    Cast(kind~, width~, exp=e) => {
      let r = match self.imm(e) {
        None => self.bot()
        Some(w) =>
          match kind.apply(width, w) {
            Ok(w) => self.word(w)
            Err(_) => self.bot()
          }
      }
      self.transfer1(e, r)
    }
    Extract(hi~, lo~, exp=e) => {
      let r = match self.imm(e) {
        None => self.bot()
        Some(w) =>
          try w.extract(hi~, lo~) catch {
            _ => self.bot()
          } noraise {
            w => self.word(w)
          }
      }
      self.transfer1(e, r)
    }
    Concat(high~, low~) => {
      let h = self.imm(high)
      let l = self.imm(low)
      let r = match (h, l) {
        (Some(h), Some(l)) =>
          try h.concat(l) catch {
            _ => self.bot()
          } noraise {
            w => self.word(w)
          }
        _ => self.bot()
      }
      self.transfer2(high, low, r)
    }
    UnOp(op, e) => {
      let r = match self.imm(e) {
        None => self.bot()
        Some(w) =>
          match op.apply(w) {
            Ok(w) => self.word(w)
            Err(_) => self.bot()
          }
      }
      self.transfer1(e, r)
    }
    BinOp(op, lhs, rhs) => {
      let r = match self.imm(lhs) {
        None => self.bot()
        Some(x) =>
          match self.imm(rhs) {
            None => self.bot()
            Some(y) =>
              match op.apply(x, y) {
                Ok(w) => self.word(w)
                Err(_) => self.bot()
              }
          }
      }
      self.transfer2(lhs, rhs, r)
    }
    Ite(cond~, yes~, no~) =>
      match self.imm(cond) {
        Some(w) if is_bit(w, true) => self.eval(yes)
        Some(w) if is_bit(w, false) => self.eval(no)
        _ => self.bot()
      }
  }
}

///|
/// Evaluates an expression of a term (normalized and simplified, as the
/// microx interpreter does).
fn Run::eval_exp(self : Run, exp : @types.Exp) -> @types.BilResult {
  self.exp = self.ctxt.exp_context()
  let r = self.eval(exp.normalize().simplify())
  self.ctxt = self.ctxt.with_exp_context(self.exp)
  r
}

///|
fn Run::update(self : Run, v : @types.Var, r : @types.BilResult) -> Unit {
  self.ctxt = self.ctxt.with_exp_context(self.ctxt.exp_context().update(v, r))
}

// ---------------------------------------------------------------------------
// Seeds (upstream `main#taint_free_vars` and `taint_result`)

///|
fn is_seeded(def : @types.Term[@types.Def]) -> Bool {
  def.taints_reg() || def.taints_ptr()
}

///|
fn Run::taint_result(
  self : Run,
  def : @types.Term[@types.Def],
  r : @types.BilResult,
) -> Unit {
  match def.tainted_reg() {
    Some(seed) =>
      self.taint = self.taint.taint_reg(
        r,
        @immut_hashset.HashSet::new().add(seed),
      )
    None => ()
  }
  match (def.tainted_ptr(), r.value()) {
    (Some(seed), BilResultImm(a)) =>
      self.taint = self.taint.taint_ptr(
        a,
        @types.Size::of_int_opt(8).unwrap(),
        @immut_hashset.HashSet::new().add(seed),
      )
    _ => ()
  }
}

///|
/// Before a seeded definition is evaluated, every variable it reads is
/// concretized, bound, and its value (or the memory it points to) is
/// tainted by the seed.
fn Run::taint_free_vars(self : Run, def : @types.Term[@types.Def]) -> Unit {
  guard is_seeded(def) else { return }
  let vars = def.def_free_vars()
  vars.sort_by((x, y) => x.compare(y))
  for v in vars {
    self.exp = self.ctxt.exp_context()
    let r = self.lookup(v)
    self.ctxt = self.ctxt.with_exp_context(self.exp)
    self.update(v, r)
    self.taint_result(def, r)
  }
}

// ---------------------------------------------------------------------------
// The exploration (upstream `Microx_conqueror.main` over `Biri`), mirroring
// `@microx.Conqueror`.

///|
fn Run::set_next(self : Run, next : @types.Tid?) -> Unit {
  self.ctxt = self.ctxt.set_next(next)
}

///|
fn Run::do_enter_term(self : Run, tid : @types.Tid) -> Unit {
  self.ctxt = self.ctxt.enter_term(tid).visit_term(tid)
  self.term = Some(tid)
}

///|
fn Run::eval_term(self : Run, term : @types.IrTerm) -> Unit {
  self.do_enter_term(term.tid())
  match term {
    ProgramTerm(_) =>
      match self.ctxt.main() {
        None => ()
        Some(main) => self.eval_term(SubTerm(main))
      }
    SubTerm(sub) => self.eval_sub(sub)
    ArgTerm(arg) => {
      let r = self.eval_exp(arg.arg_rhs())
      self.update(arg.arg_lhs(), r)
    }
    BlkTerm(blk) => self.eval_blk(blk)
    PhiTerm(phi) => self.eval_phi(phi)
    DefTerm(def) => {
      self.taint_free_vars(def)
      let r = self.eval_exp(def.rhs())
      self.update(def.lhs(), r)
    }
    JmpTerm(jmp) => self.eval_jmp(jmp)
  }
}

///|
fn Run::eval_args(
  self : Run,
  sub : @types.Term[@types.Sub],
  enter : Bool,
) -> Unit {
  for arg in sub.args() {
    let selected = match arg.intent() {
      None => true
      Some(In) => enter
      Some(Out) => !enter
      Some(Both) => true
    }
    if selected {
      self.eval_term(ArgTerm(arg))
    }
  }
}

///|
fn Run::eval_sub(self : Run, sub : @types.Term[@types.Sub]) -> Unit {
  self.ctxt = self.ctxt.enter_sub(sub)
  self.subs = self.subs.prepend(sub)
  self.set_next(sub.first_blk().map(blk => blk.tid()))
  self.eval_args(sub, true)
  self.eval_fun(sub)
  self.eval_args(sub, false)
  self.ctxt = self.ctxt.leave_sub(sub)
  self.subs = match self.subs {
    More(_, tail~) => tail
    Empty => @list.empty()
  }
}

///|
fn Run::eval_fun(self : Run, sub : @types.Term[@types.Sub]) -> Unit {
  while self.ctxt.next() is Some(p) {
    match sub.find_blk(p) {
      Some(blk) => self.eval_term(BlkTerm(blk))
      None =>
        match self.ctxt.program().find_sub(p) {
          Some(callee) => self.eval_term(SubTerm(callee))
          None => break
        }
    }
  }
}

///|
priv enum Fall {
  Keep
  SetTo(@types.Tid?)
}

///|
fn Run::eval_terms(
  self : Run,
  terms : Array[@types.IrTerm],
  fall : Fall,
) -> Unit {
  let set_next = (next : @types.Tid?) => {
    match next {
      Some(_) => self.set_next(next)
      None =>
        match fall {
          Keep => ()
          SetTo(tid) => self.set_next(tid)
        }
    }
  }
  set_next(terms.get(0).map(t => t.tid()))
  for i, term in terms {
    match self.ctxt.next() {
      Some(tid) if tid == term.tid() => {
        set_next(terms.get(i + 1).map(t => t.tid()))
        self.eval_term(term)
      }
      _ => ()
    }
  }
}

///|
fn Run::eval_blk(self : Run, blk : @types.Term[@types.Blk]) -> Unit {
  self.ctxt = self.ctxt.enter_blk(blk)
  self.set_next(None)
  let phis = blk.phis().map(t => @types.IrTerm::PhiTerm(t))
  let defs = blk.defs().map(t => @types.IrTerm::DefTerm(t))
  let jmps = blk.jmps().map(t => @types.IrTerm::JmpTerm(t))
  let first_jmp = jmps.get(0).map(t => t.tid())
  let phi_fall = match defs.get(0) {
    Some(def) => SetTo(Some(def.tid()))
    None => SetTo(first_jmp)
  }
  let def_fall = match first_jmp {
    Some(_) => SetTo(first_jmp)
    None => Keep
  }
  self.eval_terms(phis, phi_fall)
  self.eval_terms(defs, def_fall)
  self.eval_terms(jmps, Keep)
}

///|
fn Run::eval_phi(self : Run, phi : @types.Term[@types.Phi]) -> Unit {
  self.do_enter_term(phi.tid())
  let trace = self.ctxt.trace()
  let found = trace.search_by(tid => phi.select(tid) is Some(_))
  let exp = match found.bind(i => phi.select(trace[i])) {
    Some(exp) => exp
    None => phi.select_or_unknown(@types.Tid::create())
  }
  let r = self.eval_exp(exp)
  self.update(phi.phi_lhs(), r)
}

///|
fn Run::break_(self : Run) -> Unit {
  self.set_next(None)
}

///|
fn Run::return_(self : Run) -> Unit {
  let sub = match self.subs {
    More(sub, ..) => Some(sub)
    Empty => None
  }
  match self.ctxt.backtrack() {
    None => self.ctxt = self.ctxt.return_()
    Some(next) => {
      self.ctxt = next
      match (sub, next.next()) {
        (Some(sub), Some(p)) =>
          match self.snapshots.get(snapshot_key(sub, p)) {
            Some(snapshot) => {
              self.taint = snapshot.taint
              self.subs = snapshot.subs
            }
            None => ()
          }
        _ => ()
      }
    }
  }
}

///|
fn Run::eval_label(self : Run, label : @types.Label) -> Unit {
  match label {
    Direct(tid) => self.set_next(Some(tid))
    Indirect(_) => self.break_()
  }
}

///|
fn Run::next_of_jmp(self : Run, jmp : @types.Term[@types.Jmp]) -> @types.Tid? {
  match jmp.kind() {
    Interrupt(_) => None
    Goto(dst) | Ret(dst) => {
      self.eval_label(dst)
      self.ctxt.next()
    }
    JmpCall(call) => {
      self.eval_label(call.target())
      self.ctxt.next()
    }
  }
}

///|
fn Run::add_checkpoints(self : Run) -> Unit {
  guard !self.deterministic && self.ctxt.blk() is Some(blk) else { return }
  for jmp in blk.jmps() {
    self.ctxt = self.ctxt.visit_term(jmp.tid())
    match self.next_of_jmp(jmp) {
      None => ()
      Some(tid) => {
        // record the taint state together with the microx checkpoint
        if self.subs is More(sub, ..) && self.ctxt.visits(tid) == 0 {
          self.snapshots[snapshot_key(sub, tid)] = {
            taint: self.taint,
            subs: self.subs,
          }
        }
        self.ctxt = self.ctxt.add_checkpoint(tid)
      }
    }
  }
}

///|
fn Run::eval_jmp(self : Run, jmp : @types.Term[@types.Jmp]) -> Unit {
  self.add_checkpoints()
  match self.ctxt.step() {
    None => self.break_()
    Some(ctxt) => {
      self.ctxt = ctxt
      self.biri_eval_jmp(jmp)
      match self.ctxt.next() {
        Some(dst) if self.ctxt.will_loop(dst) => self.return_()
        Some(dst) if self.ctxt.will_return(dst) => self.return_()
        Some(_) => ()
        None => self.return_()
      }
    }
  }
}

///|
fn Run::biri_eval_jmp(self : Run, jmp : @types.Term[@types.Jmp]) -> Unit {
  self.do_enter_term(jmp.tid())
  match self.eval_exp(jmp.cond()).value() {
    BilResultImm(r) if is_bit(r, false) => ()
    BilResultImm(r) if is_bit(r, true) =>
      match jmp.kind() {
        Goto(dst) | Ret(dst) => self.eval_label(dst)
        JmpCall(call) =>
          match call.return_label() {
            None | Some(Indirect(_)) => self.break_()
            Some(Direct(ret)) => {
              self.ctxt = self.ctxt.store_return(ret)
              self.eval_label(call.target())
            }
          }
        Interrupt(_, ret) => self.set_next(Some(ret))
      }
    _ => self.break_()
  }
}

// ---------------------------------------------------------------------------
// Entry point

///|
/// The initial value of the stack pointer (upstream `register_lookup`).
fn stack_base(proj : @project.Project) -> @types.Word? {
  let width = proj.target().bits()
  try @types.Word::of_int64(0x40000000L, width~) catch {
    _ => None
  } noraise {
    w => Some(w)
  }
}

///|
/// Concretizes reads of the stack pointer with a fixed base (upstream
/// `register_lookup`).
fn register_lookup(proj : @project.Project) -> (@types.Var) -> @types.Word? {
  let sp = proj.target().reg(@core_theory.Role::stack_pointer())
  let base = stack_base(proj)
  v => {
    match sp {
      Some(sp) if sp.name() == v.name() => base
      _ => None
    }
  }
}

///|
/// Reads static data of the project image (upstream `memory_lookup`).
fn memory_lookup(proj : @project.Project) -> (@types.Word) -> @types.Word? {
  let memory = proj.memory()
  addr => {
    let a = addr.to_uint64() catch { _ => return None }
    match memory.find_addr(a) {
      None => None
      Some((mem, _)) =>
        match mem.get(addr=a) {
          Ok(w) => Some(w)
          Err(_) => None
        }
    }
  }
}

///|
fn find_entry(
  prog : @types.Term[@types.Program],
  point : Point,
) -> @types.Term[@types.Sub] raise PropagatorError {
  match point {
    Term(tid) =>
      match prog.find_sub(tid) {
        Some(sub) => sub
        None => raise EntryPointNotFound
      }
    Name(name) => {
      // upstream: `Tid.from_string ("@" ^ name)`
      let by_tid = match @types.Tid::from_string("@" + name) {
        Ok(tid) => prog.find_sub(tid)
        Err(_) => raise EntryPointNotFound
      }
      match by_tid {
        Some(sub) => sub
        None =>
          match prog.subs().search_by(s => s.sub_name() == name) {
            Some(i) => prog.subs()[i]
            None => raise EntryPointNotFound
          }
      }
    }
  }
}

///|
/// Propagates the taints of the seeds (definitions marked with
/// `tainted-reg`/`tainted-ptr`) through the subroutine at `point` by
/// microexecution (upstream `Propagator.run`).
///
/// - `max_steps` limits the length of a path (in jumps);
/// - `max_loop` limits the number of iterations of a loop;
/// - `deterministic` follows only one path, without backtracking to the
///   untaken branches;
/// - `random_seed`, `reg_policy` and `mem_policy` configure the
///   concretization of unknown registers and memory cells (static data
///   of the project image is read from the image, the stack pointer is
///   set to 0x40000000).
pub fn run(
  max_steps~ : Int,
  max_loop~ : Int,
  deterministic~ : Bool,
  random_seed? : Int,
  reg_policy~ : @microx.Policy,
  mem_policy~ : @microx.Policy,
  proj : @project.Project,
  point : Point,
) -> PropagationResult raise PropagatorError {
  let prog = proj.program()
  let sub = find_entry(prog, point)
  let expi = @microx.concretizer(
    memory=memory_lookup(proj),
    lookup=register_lookup(proj),
    random_seed?,
    reg_policy~,
    mem_policy~,
  )
  let ctxt = @microx.Context::new(max_steps~, max_loop~, prog)
  let run : Run = {
    expi,
    deterministic,
    ctxt,
    exp: ctxt.exp_context(),
    taint: TaintContext::empty(),
    regs: @immut_hashmap.HashMap::new(),
    ptrs: @immut_hashmap.HashMap::new(),
    subs: @list.empty(),
    term: None,
    snapshots: Map([]),
  }
  run.eval_term(SubTerm(sub))
  let visited = run.ctxt
    .visited()
    .iter()
    .fold(init=@immut_hashmap.HashMap::new(), (acc, p) => acc.add(p.0, p.1))
  { visited, regs: run.regs, ptrs: run.ptrs, }
}
