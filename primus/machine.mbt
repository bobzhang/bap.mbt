///|
/// # Primus machine
///
/// Upstream Primus is a monad transformer (`Machine.S`) whose computations
/// are continuations: `fork ()` captures the current continuation and runs
/// it twice (once in the child, later once more in the parent), `switch id`
/// stores the current continuation and resumes another one.
///
/// MoonBit has neither higher-kinded types nor multi-shot continuations, so
/// the port uses an imperative design in which the *continuation is data*:
///
/// - `Machine` is the whole world: the project, the table of forks, the
///   global state bag, the observers and the scheduler.
/// - every fork (`Id`) owns a persistent local state bag (env, memory,
///   linker table, interpreter registers, user states), a *result
///   register* and a persistent *control stack* of frames. Interpreter
///   frames describe the remaining work of the BIR interpreter; host frames
///   (tasks, continuations, exception handlers, cleanups, observer
///   dispatch) are closures. See `scheduler.mbt` for the frame protocol and
///   the resumable call API (`Machine::call`) that lets host code such as
///   a Lisp evaluator be written as frames.
/// - the scheduler loop pops frames of the current fork and executes them.
///   Executing one frame is a *step*. The interpreter steps are: entering a
///   term (subroutine, block, phi, def, jump), evaluating its body and
///   leaving it, performing the taken jump of a block, returning from a
///   subroutine and continuing after a call returns. Every `enter-*` and
///   `leave-*` observation (including `enter-pos`/`leave-pos`) is posted at
///   the end of a step, so it is an exact suspension point.
/// - `fork()` and `switch(id)` are requests that take effect at the end of
///   the current step (a safe point); when no step is running they take
///   effect immediately. The control stack and the state bag are
///   persistent, so cloning a fork is O(1) (states with a `clone` policy
///   are copied, see `State`). `kill(id)` is immediate for other forks and
///   deferred (the upstream "death row") for the current one.
/// - when an observer of a term-boundary observation requests a fork or a
///   switch, the remaining observers of that event are saved in a dispatch
///   frame and run when the machine is resumed (in both machines after a
///   fork), exactly like the upstream continuation of the observation.
/// - host code that follows a `fork()`/`switch()` call *in the same
///   callback* still runs once, in the machine that issued the request.
///   Code that must run "after" the fork or the switch is passed as the
///   `then` continuation (or pushed as frames): it is pushed onto the
///   control stack *before* cloning, so after `fork(then=k)` both the
///   parent and the child run `k` when they are resumed (compare
///   `Machine::current` with the parent id inside `k`), exactly as the
///   upstream `fork () >>= k`. Requests issued after a transferring
///   request by the same machine are re-issued when that machine resumes.
///
/// Mapping of the upstream API (`Machine.S`) to MoonBit:
///
/// | upstream                         | MoonBit                              |
/// |----------------------------------|--------------------------------------|
/// | `Machine.run user ~boot ~init`   | `Machine::run(proj, start=..., ...)` |
/// | `Machine.current ()`             | `m.current()`                        |
/// | `Machine.global`                 | `Id::global()`                       |
/// | `Machine.fork () >>= k`          | `m.fork(then=k)`                     |
/// | `Machine.switch id >>= k`        | `m.switch(id, then=k)`               |
/// | `Machine.kill id`                | `m.kill(id)`                         |
/// | `Machine.forks ()`               | `m.forks()`                          |
/// | `Machine.status id`              | `m.status(id)`                       |
/// | `Machine.parent ()` / `ancestor` | `m.parent()` / `m.ancestor(ids)`     |
/// | `Machine.Local.get s`            | `m.get_local(s)` (also `put`/`update`)|
/// | `Machine.Global.get s`           | `m.get_global(s)`                    |
/// | `Machine.Other.get id s`         | `m.get_other(id, s)`                 |
/// | `Machine.raise exn`              | `m.raise_exn(exn)`                   |
/// | `Machine.catch x h`              | `try ... catch`, or `m.push_handler` |
/// | `Machine.Observation.observe`    | `m.observe(obs, f)`                  |
/// | `Machine.Observation.make`       | `m.make(stmt, x)`                    |
/// | `Machine.Observation.post`       | `m.post(stmt, () => x)`              |
/// | `Machine.project`/`put`/`update` | `m.project()`/`set_project`/`update_project` |
/// | `Machine.args` / `envp`          | `m.args()` / `m.envp()`              |
/// | `Machine.lift`                   | not needed (host code is direct)     |
/// | `x >>= k` (in host code)         | `m.call(..., then=k)`, `m.schedule`  |
///
/// Synchronous helpers such as `Linker::exec`, `Interpreter::sub` or
/// `Interpreter::exp` run interpreted code to completion in a *nested*
/// scheduler loop; fork/switch requests issued inside a nested run are
/// deferred until the enclosing top-level step completes. Code that must
/// be forkable at every step uses the frame API instead (`Machine::call`,
/// `Machine::schedule`, `Linker::schedule_exec`,
/// `Interpreter::schedule_sub`).
pub struct Machine {
  priv mut proj : @project.Project
  priv args : Array[String]
  priv envp : Array[String]
  priv mut current : Proc
  priv procs : Map[Int, Proc]
  priv parents : Map[Int, Int]
  priv mut global : Bag
  priv mut last_id : Int
  priv observers : Map[Int, Array[(Int, () -> Unit raise)]]
  priv watchers : Map[Int, Array[(Int, (Sexp) -> Unit raise)]]
  priv mut last_sub : Int
  priv mut restricted : Bool
  priv deathrow : Array[Int]
  priv pending : Array[Pending]
  priv mut applying : Bool
  priv mut depth : Int
  priv mut nested : Int
  priv deferred : Array[Frame]
  priv mut last_value : Int64
  priv mut last_barrier : Int
}

///|
/// A fork: its identifier, its local state bag, its result register, the
/// arguments of the innermost call and its control stack.
priv struct Proc {
  id : Int
  mut locals : Bag
  mut stack : Stack
  mut result : Value?
  mut call_args : Array[Value]
}

///|
/// A fork or switch request together with the machine that issued it.
priv struct Pending {
  issuer : Int
  op : PendingOp
}

///|
priv enum PendingOp {
  Fork(((Machine) -> Unit raise)?)
  Switch(Id, ((Machine) -> Unit raise)?)
}

///|
/// The status of a machine (upstream ``[`Current | `Live | `Dead]``).
pub(all) enum ForkStatus {
  Current
  Live
  Dead
} derive(Eq, Debug)

///|
pub impl Show for ForkStatus with fn output(self, logger) {
  logger.write_string(
    match self {
      Current => "Current"
      Live => "Live"
      Dead => "Dead"
    },
  )
}

///|
/// Creates a fresh machine world for the project. The machine starts in
/// the restricted mode (as upstream `init_state`); `Machine::run` lifts the
/// restriction after `boot`.
pub fn Machine::new(
  proj : @project.Project,
  args? : Array[String] = [],
  envp? : Array[String] = [],
) -> Machine {
  {
    proj,
    args,
    envp,
    current: {
      id: 0,
      locals: Bag::empty(),
      stack: Nil,
      result: None,
      call_args: [],
    },
    procs: {},
    parents: {},
    global: Bag::empty(),
    last_id: 0,
    observers: {},
    watchers: {},
    last_sub: 0,
    restricted: true,
    deathrow: [],
    pending: [],
    applying: false,
    depth: 0,
    nested: 0,
    deferred: [],
    last_value: 0L,
    last_barrier: 0,
  }
}

// ---------------------------------------------------------------------------
// Project access

///|
pub fn Machine::project(self : Machine) -> @project.Project {
  self.proj
}

///|
pub fn Machine::set_project(self : Machine, proj : @project.Project) -> Unit {
  self.proj = proj
}

///|
pub fn Machine::update_project(
  self : Machine,
  f : (@project.Project) -> @project.Project,
) -> Unit {
  self.proj = f(self.proj)
}

///|
pub fn Machine::program(self : Machine) -> @types.Term[@types.Program] {
  self.proj.program()
}

///|
/// The target of the project (upstream `Machine.arch`).
pub fn Machine::target(self : Machine) -> @core_theory.Target {
  self.proj.target()
}

///|
pub fn Machine::args(self : Machine) -> Array[String] {
  self.args
}

///|
pub fn Machine::envp(self : Machine) -> Array[String] {
  self.envp
}

///|
/// Whether the machine is in the restricted mode (observations are
/// suppressed and fork/switch/kill are forbidden).
pub fn Machine::is_restricted(self : Machine) -> Bool {
  self.restricted
}

// ---------------------------------------------------------------------------
// States

///|
pub fn[T] Machine::get_local(self : Machine, state : State[T]) -> T {
  match self.current.locals.find(state) {
    Some(x) => x
    None => (state.init)(self.proj)
  }
}

///|
pub fn[T] Machine::put_local(self : Machine, state : State[T], x : T) -> Unit {
  self.current.locals = self.current.locals.set(state, x)
}

///|
pub fn[T] Machine::update_local(
  self : Machine,
  state : State[T],
  f : (T) -> T,
) -> Unit {
  self.put_local(state, f(self.get_local(state)))
}

///|
pub fn[T] Machine::get_global(self : Machine, state : State[T]) -> T {
  match self.global.find(state) {
    Some(x) => x
    None => (state.init)(self.proj)
  }
}

///|
pub fn[T] Machine::put_global(self : Machine, state : State[T], x : T) -> Unit {
  self.global = self.global.set(state, x)
}

///|
pub fn[T] Machine::update_global(
  self : Machine,
  state : State[T],
  f : (T) -> T,
) -> Unit {
  self.put_global(state, f(self.get_global(state)))
}

///|
fn Machine::find_proc(self : Machine, id : Id) -> Proc? {
  if id.0 == self.current.id {
    Some(self.current)
  } else {
    self.procs.get(id.0)
  }
}

///|
/// Reads the local state of another (live) machine (`Machine.Other.get`).
/// Schedulers use it to inspect suspended forks, e.g. their position with
/// `Interpreter::pos_of`.
pub fn[T] Machine::get_other(
  self : Machine,
  id : Id,
  state : State[T],
) -> T raise {
  guard self.find_proc(id) is Some(p) else { raise DeadMachine(id) }
  match p.locals.find(state) {
    Some(x) => x
    None => (state.init)(self.proj)
  }
}

///|
/// Writes the local state of another (live) machine (`Machine.Other.put`).
pub fn[T] Machine::put_other(
  self : Machine,
  id : Id,
  state : State[T],
  x : T,
) -> Unit raise {
  guard self.find_proc(id) is Some(p) else { raise DeadMachine(id) }
  p.locals = p.locals.set(state, x)
}

///|
pub fn[T] Machine::update_other(
  self : Machine,
  id : Id,
  state : State[T],
  f : (T) -> T,
) -> Unit raise {
  self.put_other(id, state, f(self.get_other(id, state)))
}

// ---------------------------------------------------------------------------
// Forks

///|
/// The identifier of the current machine (`Machine.current`).
pub fn Machine::current(self : Machine) -> Id {
  Id(self.current.id)
}

///|
/// All live machines, starting with the global one (`Machine.forks`).
pub fn Machine::forks(self : Machine) -> Array[Id] {
  let ids = [self.current.id]
  for id, _ in self.procs {
    ids.push(id)
  }
  ids.sort()
  let out = [Id::global()]
  for id in ids {
    if id != 0 {
      out.push(Id(id))
    }
  }
  out
}

///|
/// The status of a machine (`Machine.status`).
pub fn Machine::status(self : Machine, id : Id) -> ForkStatus {
  if id.0 == self.current.id {
    Current
  } else if self.procs.contains(id.0) {
    Live
  } else {
    Dead
  }
}

///|
fn Machine::is_alive(self : Machine, id : Int) -> Bool {
  id == self.current.id || self.procs.contains(id)
}

///|
fn Machine::live_parent(self : Machine, id : Int) -> Int {
  for i = id {
    match self.parents.get(i) {
      None => break 0
      Some(p) => if self.is_alive(p) { break p } else { continue p }
    }
  }
}

///|
/// The closest common live ancestor of the machines (`Machine.ancestor`).
pub fn Machine::ancestor(self : Machine, ids : Array[Id]) -> Id {
  let mut xs = ids.map(x => x.0)
  for _ in 0..<(self.last_id + 2) {
    let ps = xs.map(x => self.live_parent(x))
    match ps {
      [] => return Id::global()
      [p, ..] if ps.iter().all(q => q == p) => return Id(p)
      _ => xs = ps
    }
  }
  Id::global()
}

///|
/// The closest live ancestor of the current machine (`Machine.parent`).
pub fn Machine::parent(self : Machine) -> Id {
  self.ancestor([self.current()])
}

///|
fn Machine::request(self : Machine, op : PendingOp) -> Unit raise {
  self.pending.push({ issuer: self.current.id, op, })
  if self.depth == 0 {
    self.apply_pending()
  }
}

///|
/// Forks the current machine (`Machine.fork`).
///
/// The fork happens at the end of the current step (immediately if no step
/// is running). After the fork the child becomes the current machine and
/// the parent is suspended with an identical control stack and state. The
/// optional `then` continuation is pushed onto the control stack before
/// cloning, so it runs first in the child and, when the parent is resumed,
/// in the parent too.
pub fn Machine::fork(
  self : Machine,
  then? : (Machine) -> Unit raise,
) -> Unit raise {
  if self.restricted {
    raise Restricted("fork")
  }
  self.request(Fork(then))
}

///|
/// Switches to the machine `id` (`Machine.switch`). The switch happens at
/// the end of the current step (immediately if no step is running). The
/// optional `then` continuation is pushed onto the control stack of the
/// machine being suspended and runs when it is resumed. Switching to a
/// machine that is not alive raises `DeadMachine` in the issuing machine.
pub fn Machine::switch(
  self : Machine,
  id : Id,
  then? : (Machine) -> Unit raise,
) -> Unit raise {
  if self.restricted {
    raise Restricted("switch")
  }
  self.request(Switch(id, then))
}

///|
fn Machine::with_context(
  self : Machine,
  id : Int,
  f : () -> Unit raise,
) -> Unit raise {
  if id == self.current.id {
    f()
  } else {
    guard self.procs.get(id) is Some(p) else { raise DeadMachine(Id(id)) }
    let saved = self.current
    self.current = p
    defer {
      self.current = saved
    }
    f()
  }
}

///|
fn Machine::notify_killed(self : Machine, id : Id) -> Unit raise {
  self.restricted = true
  defer {
    self.restricted = false
  }
  self.make_even_if_restricted(killed_stmt, id)
}

///|
/// Kills the machine `id` (`Machine.kill`). Killing the global machine is
/// a no-op. Killing the current machine sentences it to death: it keeps
/// running until the next fork or switch, after which it is removed.
/// `machine_kill` observers are run in the context of the killed machine
/// and in the restricted mode.
pub fn Machine::kill(self : Machine, id : Id) -> Unit raise {
  if self.restricted {
    raise Restricted("kill")
  }
  if id.0 == 0 {
    return
  }
  if id.0 == self.current.id {
    self.notify_killed(id)
    self.deathrow.push(id.0)
  } else if self.procs.contains(id.0) {
    self.with_context(id.0, () => self.notify_killed(id))
    self.procs.remove(id.0)
  }
}

///|
fn Machine::execute_sentenced(self : Machine) -> Unit {
  for id in self.deathrow {
    if id != self.current.id {
      self.procs.remove(id)
    }
  }
  self.deathrow.clear()
}

///|
fn Machine::snapshot(self : Machine) -> Proc {
  {
    id: self.current.id,
    locals: self.current.locals,
    stack: self.current.stack,
    result: self.current.result,
    call_args: self.current.call_args,
  }
}

///|
/// Pushes the continuation of the issuer of a transferring request: the
/// requests it issued after this one (re-issued when it is resumed) and
/// the `then` continuation of the request itself (on top).
fn Machine::push_continuation(
  self : Machine,
  issuer : Int,
  then : ((Machine) -> Unit raise)?,
) -> Unit {
  let rest = []
  let keep = []
  for r in self.pending {
    if r.issuer == issuer {
      rest.push(r.op)
    } else {
      keep.push(r)
    }
  }
  if !rest.is_empty() {
    self.pending.clear()
    self.pending.append(keep)
    self.push(Task(m => reissue(m, rest)))
  }
  if then is Some(k) {
    self.push(Task(k))
  }
}

///|
fn reissue(m : Machine, ops : Array[PendingOp]) -> Unit raise {
  for op in ops {
    match op {
      Fork(then) => m.fork(then?)
      Switch(id, then) => m.switch(id, then?)
    }
  }
}

///|
fn Machine::do_fork(
  self : Machine,
  then : ((Machine) -> Unit raise)?,
) -> Unit raise {
  let pid = self.current.id
  self.push_continuation(pid, then)
  self.last_id += 1
  let child = self.last_id
  self.procs[pid] = self.snapshot()
  self.current = {
    ..self.snapshot(),
    id: child,
    locals: self.current.locals.fork(),
  }
  self.parents[child] = pid
  self.execute_sentenced()
  self.make(forked_stmt, (Id(pid), Id(child)))
}

///|
fn Machine::do_switch(
  self : Machine,
  id : Id,
  then : ((Machine) -> Unit raise)?,
) -> Unit raise {
  let pid = self.current.id
  if id.0 != pid && !self.procs.contains(id.0) {
    raise DeadMachine(id)
  }
  self.push_continuation(pid, then)
  if id.0 != pid {
    let next = self.procs.get(id.0).unwrap()
    self.procs[pid] = self.snapshot()
    self.procs.remove(id.0)
    self.current = next
  }
  self.execute_sentenced()
  self.make(switched_stmt, (Id(pid), id))
}

///|
/// Applies the pending requests in order. Each request is applied on
/// behalf of the machine that issued it: requests of a suspended issuer
/// are re-issued when it resumes, requests of dead machines are dropped.
/// The function is not reentrant: requests issued by `machine_fork` and
/// `machine_switch` observers are appended and handled by the same loop.
fn Machine::apply_pending(self : Machine) -> Unit raise {
  if self.applying {
    return
  }
  self.applying = true
  defer {
    self.applying = false
  }
  while !self.pending.is_empty() {
    let req = self.pending.remove(0)
    if req.issuer == self.current.id {
      match req.op {
        Fork(then) => self.do_fork(then)
        Switch(id, then) => self.do_switch(id, then)
      }
    } else if self.procs.get(req.issuer) is Some(p) {
      p.stack = Cons(Task(m => reissue(m, [req.op])), p.stack)
    }
  }
}

///|
/// Allocates a fresh value identifier (the upstream global `value` state).
fn Machine::fresh_value_id(self : Machine) -> Int64 {
  self.last_value += 1L
  self.last_value
}
