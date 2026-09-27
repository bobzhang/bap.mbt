// Port of `Microx_conqueror`: a BIR interpreter (upstream `Biri`) that
// tries to cover as much code as possible by checkpointing untaken
// branches and backtracking to them, with bounded loops and steps.

///|
using @types {type Blk, type Program, type Sub, type Term, type Tid}

///|
/// The execution context of the conqueror (upstream
/// `Microx_conqueror.context`, which extends `Biri.context`).
///
/// The context is persistent: checkpoints are snapshots of contexts.
pub struct Context {
  priv exp : ExpContext
  priv program : Term[Program]
  priv main_sub : Term[Sub]?
  priv trace : @list.List[Tid]
  priv next : Tid?
  priv blk : Term[Blk]?
  priv callstack : @list.List[Term[Sub]]
  priv steps_left : Int
  priv max_loop : Int
  priv vis : @hashmap.HashMap[Tid, Int]
  priv cps : @hashmap.HashMap[Tid, @hashmap.HashMap[Tid, Context]]
  priv rets : @list.List[Tid]
}

///|
/// Creates a context for [program].
///
/// - `max_steps` is the maximum number of steps (jumps) that should be
///   taken in a single path (unbounded by default);
/// - `max_loop` is the maximum number of loop iterations, defaults to
///   `min(10, max_steps / 10)`. Only loops inner to a function are
///   detected;
/// - `main` is the entry subroutine, defaults to the first subroutine.
pub fn Context::new(
  max_steps? : Int = 2147483647,
  max_loop? : Int,
  main? : Term[Sub],
  program : Term[Program],
) -> Context {
  let max_loop = match max_loop {
    Some(n) => n
    None => if max_steps / 10 < 10 { max_steps / 10 } else { 10 }
  }
  {
    exp: ExpContext::new(),
    program,
    main_sub: main,
    trace: @list.empty(),
    next: None,
    blk: None,
    callstack: @list.empty(),
    steps_left: max_steps,
    max_loop,
    vis: @hashmap.HashMap::new(),
    cps: @hashmap.HashMap::new(),
    rets: @list.empty(),
  }
}

///|
/// The program being executed.
pub fn Context::program(self : Context) -> Term[Program] {
  self.program
}

///|
/// The entry subroutine: the one passed to `Context::new`, or the first
/// subroutine of the program.
pub fn Context::main(self : Context) -> Term[Sub]? {
  match self.main_sub {
    Some(sub) => Some(sub)
    None => self.program.first_sub()
  }
}

///|
/// The expression-level state (variable bindings).
pub fn Context::exp_context(self : Context) -> ExpContext {
  self.exp
}

///|
/// Replaces the expression-level state.
pub fn Context::with_exp_context(self : Context, exp : ExpContext) -> Context {
  { ..self, exp, }
}

///|
/// The result bound to a variable, if any.
pub fn Context::lookup(self : Context, variable : @types.Var) -> BilResult? {
  self.exp.lookup(variable)
}

///|
/// The identifiers of all entered terms, most recent first.
pub fn Context::trace(self : Context) -> Array[Tid] {
  self.trace.to_array()
}

///|
/// Records that the term [tid] was entered.
pub fn Context::enter_term(self : Context, tid : Tid) -> Context {
  { ..self, trace: self.trace.prepend(tid), }
}

///|
/// The identifier of the next term to evaluate.
pub fn Context::next(self : Context) -> Tid? {
  self.next
}

///|
/// Sets the next term to evaluate.
pub fn Context::set_next(self : Context, next : Tid?) -> Context {
  { ..self, next, }
}

///|
/// The number of visits of every visited term.
pub fn Context::visited(self : Context) -> Map[Tid, Int] {
  let result : Map[Tid, Int] = Map([])
  for tid, n in self.vis {
    result[tid] = n
  }
  result
}

///|
/// The number of visits of the given term.
pub fn Context::visits(self : Context, tid : Tid) -> Int {
  self.vis.get(tid).unwrap_or(0)
}

///|
/// The pending checkpoints: for each subroutine, the untaken destinations
/// and the contexts that were current when they were recorded.
pub fn Context::checkpoints(self : Context) -> Map[Tid, Map[Tid, Context]] {
  let result : Map[Tid, Map[Tid, Context]] = Map([])
  for sub, points in self.cps {
    let inner : Map[Tid, Context] = Map([])
    for tid, ctxt in points {
      inner[tid] = ctxt
    }
    result[sub] = inner
  }
  result
}

///|
fn tid_compare(x : Tid, y : Tid) -> Int {
  let c = x.id().compare(y.id())
  if c != 0 {
    c
  } else {
    x.to_string().compare(y.to_string())
  }
}

///|
/// Restores the context of the smallest unvisited checkpoint of the current
/// subroutine, keeping the visited terms and remaining checkpoints of
/// [self]. Returns `None` if there are no such checkpoints.
pub fn Context::backtrack(self : Context) -> Context? {
  guard self.callstack is More(sub, ..) else { None }
  let key = sub.tid()
  guard self.cps.get(key) is Some(points) else { None }
  let points = points.filter((p, _) => !self.vis.contains(p))
  let mut best : (Tid, Context)? = None
  for p, old in points {
    match best {
      Some((q, _)) if tid_compare(q, p) <= 0 => ()
      _ => best = Some((p, old))
    }
  }
  guard best is Some((p, old)) else { None }
  let current = { ..self, cps: self.cps.add(key, points.remove(p)), }
  Some(old.merge(current).set_next(Some(p)))
}

///|
/// Records a checkpoint at the destination [p], unless [p] was already
/// visited or there is no current subroutine.
pub fn Context::add_checkpoint(self : Context, p : Tid) -> Context {
  guard self.callstack is More(sub, ..) else { self }
  if self.vis.contains(p) {
    return self
  }
  let key = sub.tid()
  let points = match self.cps.get(key) {
    None => @hashmap.HashMap::singleton(p, self)
    Some(points) => points.add(p, self)
  }
  { ..self, cps: self.cps.add(key, points), }
}

///|
/// Takes the visited terms and checkpoints from [runner].
pub fn Context::merge(self : Context, runner : Context) -> Context {
  { ..self, vis: runner.vis, cps: runner.cps, }
}

///|
/// Pushes a return destination.
pub fn Context::store_return(self : Context, ret : Tid) -> Context {
  { ..self, rets: self.rets.prepend(ret), }
}

///|
/// Pops a return destination and continues there, or stops if there is
/// none.
pub fn Context::return_(self : Context) -> Context {
  match self.rets {
    Empty => self.set_next(None)
    More(r, tail=rs) => { ..self, rets: rs, }.set_next(Some(r))
  }
}

///|
/// The block that is being evaluated.
pub fn Context::blk(self : Context) -> Term[Blk]? {
  self.blk
}

///|
/// Enters a block.
pub fn Context::enter_blk(self : Context, blk : Term[Blk]) -> Context {
  { ..self, blk: Some(blk), }
}

///|
/// Pushes a subroutine on the call stack.
pub fn Context::enter_sub(self : Context, sub : Term[Sub]) -> Context {
  { ..self, callstack: self.callstack.prepend(sub), }
}

///|
/// Pops a subroutine from the call stack.
pub fn Context::leave_sub(self : Context, _sub : Term[Sub]) -> Context {
  match self.callstack {
    More(_, tail~) => { ..self, callstack: tail, }
    Empty => self
  }
}

///|
/// Spends one step, or returns `None` if the step budget is exhausted.
pub fn Context::step(self : Context) -> Context? {
  if self.steps_left > 0 {
    Some({ ..self, steps_left: self.steps_left - 1, })
  } else {
    None
  }
}

///|
/// Increments the visit counter of [tid].
pub fn Context::visit_term(self : Context, tid : Tid) -> Context {
  { ..self, vis: self.vis.add(tid, self.visits(tid) + 1), }
}

///|
/// [ctxt.will_loop(tid)] is true if [tid] is a block of the current
/// subroutine that was visited more than `max_loop` times.
pub fn Context::will_loop(self : Context, tid : Tid) -> Bool {
  match self.callstack {
    Empty => false
    More(sub, ..) =>
      match self.vis.get(tid) {
        None => false
        Some(n) => n > self.max_loop && sub.find_blk(tid) is Some(_)
      }
  }
}

///|
/// [ctxt.will_return(tid)] is true if jumping to [tid] leaves the current
/// subroutine, i.e., [tid] is neither a jump of the current block, nor a
/// block of the current subroutine, nor a subroutine of the program.
pub fn Context::will_return(self : Context, tid : Tid) -> Bool {
  match self.callstack {
    Empty => false
    More(cur, ..) => {
      let fall = match self.blk {
        Some(blk) => blk.find_jmp(tid) is Some(_)
        None => false
      }
      let jump = cur.find_blk(tid) is Some(_)
      let call = self.program.find_sub(tid) is Some(_)
      !(fall || jump || call)
    }
  }
}

///|
/// The BIR interpreter that conquers a program (upstream
/// `Microx_conqueror.main`).
///
/// If `deterministic` is `true` then only the feasible execution path is
/// taken, otherwise the interpreter will execute all linearly independent
/// paths by checkpointing the destinations of every jump of a block and
/// backtracking to unvisited checkpoints when a path returns. Expressions
/// are evaluated with `expi`; pass a `concretizer` to avoid stalling on
/// unknown values.
pub struct Conqueror {
  priv deterministic : Bool
  priv expi : Expi
}

///|
/// Creates a conqueror.
pub fn Conqueror::new(
  deterministic? : Bool = false,
  expi? : Expi = Expi::new(),
) -> Conqueror {
  { deterministic, expi, }
}

///|
priv struct Run {
  conqueror : Conqueror
  mut ctxt : Context
}

///|
fn Run::set_next(self : Run, next : Tid?) -> Unit {
  self.ctxt = self.ctxt.set_next(next)
}

///|
fn Run::eval_exp(self : Run, exp : @types.Exp) -> BilResult {
  let (exp_ctxt, result) = self.conqueror.expi.eval_exp(self.ctxt.exp, exp)
  self.ctxt = self.ctxt.with_exp_context(exp_ctxt)
  result
}

///|
fn Run::update(self : Run, variable : @types.Var, result : BilResult) -> Unit {
  self.ctxt = self.ctxt.with_exp_context(self.ctxt.exp.update(variable, result))
}

///|
fn Run::do_enter_term(self : Run, tid : Tid) -> Unit {
  self.ctxt = self.ctxt.enter_term(tid).visit_term(tid)
}

///|
fn Run::eval(self : Run, term : @types.IrTerm) -> Unit {
  self.do_enter_term(term.tid())
  match term {
    ProgramTerm(_) =>
      match self.ctxt.main() {
        None => ()
        Some(main) => self.eval(SubTerm(main))
      }
    SubTerm(sub) => self.eval_sub(sub)
    ArgTerm(arg) => {
      let result = self.eval_exp(arg.arg_rhs())
      self.update(arg.arg_lhs(), result)
    }
    BlkTerm(blk) => self.eval_blk(blk)
    PhiTerm(phi) => self.eval_phi(phi)
    DefTerm(def) => {
      let result = self.eval_exp(def.rhs())
      self.update(def.lhs(), result)
    }
    JmpTerm(jmp) => self.eval_jmp(jmp)
  }
}

///|
fn Run::eval_args(self : Run, sub : Term[Sub], enter : Bool) -> Unit {
  for arg in sub.args() {
    let selected = match arg.intent() {
      None => true
      Some(In) => enter
      Some(Out) => !enter
      Some(Both) => true
    }
    if selected {
      self.eval(ArgTerm(arg))
    }
  }
}

///|
fn Run::eval_sub(self : Run, sub : Term[Sub]) -> Unit {
  self.ctxt = self.ctxt.enter_sub(sub)
  self.set_next(sub.first_blk().map(blk => blk.tid()))
  self.eval_args(sub, true)
  self.eval_fun(sub)
  self.eval_args(sub, false)
  self.ctxt = self.ctxt.leave_sub(sub)
}

///|
fn Run::eval_fun(self : Run, sub : Term[Sub]) -> Unit {
  while self.ctxt.next is Some(p) {
    match sub.find_blk(p) {
      Some(blk) => self.eval(BlkTerm(blk))
      None =>
        match self.ctxt.program.find_sub(p) {
          Some(callee) => self.eval(SubTerm(callee))
          None => break
        }
    }
  }
}

///|
/// What becomes the next term after the last term of a sequence.
priv enum Fall {
  Keep
  SetTo(Tid?)
}

///|
/// Evaluates a sequence of terms of the same class, see upstream
/// `Biri.eval_terms`: a term is evaluated only if it is the next one, and
/// just before its evaluation the next term is set to its successor.
fn Run::eval_terms(
  self : Run,
  terms : Array[@types.IrTerm],
  fall : Fall,
) -> Unit {
  let set_next = (next : Tid?) => {
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
    match self.ctxt.next {
      Some(tid) if tid == term.tid() => {
        set_next(terms.get(i + 1).map(t => t.tid()))
        self.eval(term)
      }
      _ => ()
    }
  }
}

///|
fn Run::eval_blk(self : Run, blk : Term[Blk]) -> Unit {
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
fn Run::eval_phi(self : Run, phi : Term[@types.Phi]) -> Unit {
  self.do_enter_term(phi.tid())
  let found = self.ctxt.trace.find(tid => phi.select(tid) is Some(_))
  let exp = match found.bind(tid => phi.select(tid)) {
    Some(exp) => exp
    None => phi.select_or_unknown(Tid::create())
  }
  let result = self.eval_exp(exp)
  self.update(phi.phi_lhs(), result)
}

///|
fn Run::break_(self : Run) -> Unit {
  self.set_next(None)
}

///|
fn Run::return_(self : Run) -> Unit {
  self.ctxt = match self.ctxt.backtrack() {
    None => self.ctxt.return_()
    Some(next) => next
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
/// The destination of [jmp]. As upstream, the computation is performed on
/// the current state, so the next term is left pointing to the
/// destination.
fn Run::next_of_jmp(self : Run, jmp : Term[@types.Jmp]) -> Tid? {
  match jmp.kind() {
    Interrupt(_) => None
    Goto(dst) | Ret(dst) => {
      self.eval_label(dst)
      self.ctxt.next
    }
    JmpCall(call) => {
      self.eval_label(call.target())
      self.ctxt.next
    }
  }
}

///|
fn Run::add_checkpoints(self : Run) -> Unit {
  guard !self.conqueror.deterministic && self.ctxt.blk is Some(blk) else {
    return
  }
  for jmp in blk.jmps() {
    self.ctxt = self.ctxt.visit_term(jmp.tid())
    match self.next_of_jmp(jmp) {
      None => ()
      Some(tid) => self.ctxt = self.ctxt.add_checkpoint(tid)
    }
  }
}

///|
fn Run::eval_jmp(self : Run, jmp : Term[@types.Jmp]) -> Unit {
  self.add_checkpoints()
  match self.ctxt.step() {
    None => self.break_()
    Some(ctxt) => {
      self.ctxt = ctxt
      self.biri_eval_jmp(jmp)
      match self.ctxt.next {
        Some(dst) if self.ctxt.will_loop(dst) => self.return_()
        Some(dst) if self.ctxt.will_return(dst) => self.return_()
        Some(_) => ()
        None => self.return_()
      }
    }
  }
}

///|
fn Run::biri_eval_jmp(self : Run, jmp : Term[@types.Jmp]) -> Unit {
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

///|
/// [conqueror.eval(ctxt, term)] evaluates [term] in [ctxt]. Evaluating a
/// program evaluates its main subroutine.
pub fn Conqueror::eval(
  self : Conqueror,
  ctxt : Context,
  term : @types.IrTerm,
) -> Context {
  let run = { conqueror: self, ctxt, }
  run.eval(term)
  run.ctxt
}

///|
/// Evaluates the program of the context, starting from its main
/// subroutine.
pub fn Conqueror::run(self : Conqueror, ctxt : Context) -> Context {
  self.eval(ctxt, ProgramTerm(ctxt.program))
}

///|
/// Evaluates a subroutine.
pub fn Conqueror::eval_sub(
  self : Conqueror,
  ctxt : Context,
  sub : Term[Sub],
) -> Context {
  self.eval(ctxt, SubTerm(sub))
}
