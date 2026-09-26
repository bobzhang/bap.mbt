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
///   linker table, interpreter registers, user states) and a persistent
///   *control stack* of frames. Interpreter frames describe the remaining
///   work of the BIR interpreter (enter a sub, evaluate the next def of a
///   block, return from a call, ...); `Task` frames hold host closures.
/// - the scheduler loop pops frames of the current fork and executes them.
///   Executing one frame is a *step*.
/// - `fork()`, `switch(id)` are requests that take effect at the end of the
///   current step (a safe point): the control stack and the state bag are
///   persistent, so cloning a fork is O(1). When no step is running (for
///   example in `init` code before the scheduler starts) they take effect
///   immediately. `kill(id)` is immediate for other forks and deferred (the
///   upstream "death row") for the current one.
/// - host code that must run "after" a fork or a switch in both/one of the
///   resulting machines is passed as the `then` continuation: it is pushed
///   onto the control stack *before* cloning, so after `fork(then=k)` both
///   the parent and the child run `k` when they are resumed (compare
///   `Machine.current` with the parent id inside `k`), exactly as the
///   upstream `fork () >>= k`.
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
/// | `Machine.catch x h`              | MoonBit `try ... catch`              |
/// | `Machine.Observation.observe`    | `m.observe(obs, f)`                  |
/// | `Machine.Observation.make`       | `m.make(stmt, x)`                    |
/// | `Machine.Observation.post`       | `m.post(stmt, () => x)`              |
/// | `Machine.project`/`put`/`update` | `m.project()`/`set_project`/`update_project` |
/// | `Machine.args` / `envp`          | `m.args()` / `m.envp()`              |
/// | `Machine.lift`                   | not needed (host code is direct)     |
///
/// Synchronous helpers such as `Linker::exec`, `Interpreter::sub` or
/// `Interpreter::exp` run interpreted code to completion in a *nested*
/// scheduler loop; fork/switch requests issued inside a nested run are
/// deferred until the enclosing top-level step completes. Use the
/// `schedule*` functions (`Machine::schedule`, `Linker::schedule_exec`,
/// `Interpreter::schedule_sub`) to run code at the top level, where it can
/// be forked at every step.
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
  priv mut depth : Int
  priv mut last_value : Int64
  priv mut last_barrier : Int
}

///|
/// A fork: its identifier, its local state bag and its control stack.
priv struct Proc {
  id : Int
  mut locals : Bag
  mut stack : Stack
}

///|
priv enum Stack {
  Nil
  Cons(Frame, Stack)
}

///|
priv enum Pending {
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
    current: { id: 0, locals: Bag::empty(), stack: Nil, },
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
    depth: 0,
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
/// Reads the locals state of another (live) machine (`Machine.Other.get`).
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
/// Writes the locals state of another (live) machine (`Machine.Other.put`).
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
// Observations

///|
/// Subscribes to an observation and returns the subscription handle
/// (`Machine.Observation.subscribe`). Observers subscribed later are called
/// earlier, as upstream.
pub fn[T] Machine::subscribe(
  self : Machine,
  obs : Observation[T],
  f : (T) -> Unit raise,
) -> Subscription {
  self.last_sub += 1
  let id = self.last_sub
  let slot = obs.slot
  let run = fn() raise {
    guard slot.val is Some(x) else { return }
    f(x)
  }
  let subs = match self.observers.get(obs.key) {
    Some(xs) => [..xs, (id, run)]
    None => [(id, run)]
  }
  self.observers[obs.key] = subs
  obs.provider.observers += 1
  { key: obs.key, id, watcher: false, }
}

///|
/// Subscribes to an observation (`Machine.Observation.observe`, `>>>`).
pub fn[T] Machine::observe(
  self : Machine,
  obs : Observation[T],
  f : (T) -> Unit raise,
) -> Unit {
  ignore(self.subscribe(obs, f))
}

///|
/// Watches a provider: the observer receives the inspected (S-expression)
/// representation of every observed value (`Machine.Observation.watch`).
/// Watchers are called after the typed observers.
pub fn Machine::watch(
  self : Machine,
  provider : Provider,
  f : (Sexp) -> Unit raise,
) -> Subscription {
  self.last_sub += 1
  let id = self.last_sub
  let subs = match self.watchers.get(provider.key) {
    Some(xs) => [..xs, (id, f)]
    None => [(id, f)]
  }
  self.watchers[provider.key] = subs
  provider.observers += 1
  { key: provider.key, id, watcher: true, }
}

///|
/// Cancels a subscription (`Machine.Observation.cancel`).
pub fn Machine::cancel(self : Machine, sub : Subscription) -> Unit {
  if sub.watcher {
    if self.watchers.get(sub.key) is Some(xs) {
      self.watchers[sub.key] = xs.filter(x => x.0 != sub.id)
    }
  } else if self.observers.get(sub.key) is Some(xs) {
    self.observers[sub.key] = xs.filter(x => x.0 != sub.id)
  }
}

///|
fn[T] Machine::has_observers(self : Machine, obs : Observation[T]) -> Bool {
  (self.observers.get(obs.key) is Some(xs) && !xs.is_empty()) ||
  (self.watchers.get(obs.key) is Some(ws) && !ws.is_empty()) ||
  !obs.provider.listeners.is_empty()
}

///|
fn[T] Machine::notify(
  self : Machine,
  obs : Observation[T],
  x : T,
) -> Unit raise {
  let p = obs.provider
  p.triggers += 1
  let os = self.observers.get(obs.key).unwrap_or([])
  let ws = self.watchers.get(obs.key).unwrap_or([])
  if !ws.is_empty() || !p.listeners.is_empty() {
    let sexp = (obs.inspect)(x)
    for l in p.listeners {
      l(sexp)
    }
    for i = os.length() - 1; i >= 0; i = i - 1 {
      obs.slot.val = Some(x)
      (os[i].1)()
    }
    for i = ws.length() - 1; i >= 0; i = i - 1 {
      (ws[i].1)(sexp)
    }
  } else {
    for i = os.length() - 1; i >= 0; i = i - 1 {
      obs.slot.val = Some(x)
      (os[i].1)()
    }
  }
  obs.slot.val = None
}

///|
/// Posts an observation (`Machine.Observation.make`). Observations are
/// suppressed in the restricted mode.
pub fn[T] Machine::make(
  self : Machine,
  stmt : Statement[T],
  x : T,
) -> Unit raise {
  if !self.restricted {
    self.notify(stmt.obs, x)
  }
}

///|
/// Posts an observation whose value is computed only when somebody
/// observes it (`Machine.Observation.post`).
pub fn[T] Machine::post(
  self : Machine,
  stmt : Statement[T],
  f : () -> T raise,
) -> Unit raise {
  if self.restricted {
    return
  }
  let obs = stmt.obs
  if self.has_observers(obs) {
    self.notify(obs, f())
  } else {
    obs.provider.triggers += 1
  }
}

///|
fn[T] Machine::make_even_if_restricted(
  self : Machine,
  stmt : Statement[T],
  x : T,
) -> Unit raise {
  self.notify(stmt.obs, x)
}

///|
/// Notifies `exn_raised` and raises the exception (`Machine.raise`).
pub fn[T] Machine::raise_exn(self : Machine, exn : Error) -> T raise {
  self.make(exn_raised_stmt, exn)
  raise exn
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
fn Machine::push(self : Machine, frame : Frame) -> Unit {
  self.current.stack = Cons(frame, self.current.stack)
}

///|
/// Pushes a host task onto the control stack of the current machine. The
/// task is executed as a separate step by the scheduler, after the current
/// step; tasks follow the stack discipline (the last scheduled task runs
/// first).
pub fn Machine::schedule(
  self : Machine,
  task : (Machine) -> Unit raise,
) -> Unit {
  self.push(Task(task))
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
  self.pending.push(Fork(then))
  if self.depth == 0 {
    self.apply_pending()
  }
}

///|
/// Switches to the machine `id` (`Machine.switch`). The switch happens at
/// the end of the current step (immediately if no step is running). The
/// optional `then` continuation is pushed onto the control stack of the
/// machine being suspended and runs when it is resumed.
pub fn Machine::switch(
  self : Machine,
  id : Id,
  then? : (Machine) -> Unit raise,
) -> Unit raise {
  if self.restricted {
    raise Restricted("switch")
  }
  self.pending.push(Switch(id, then))
  if self.depth == 0 {
    self.apply_pending()
  }
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
  }
}

///|
fn Machine::do_fork(
  self : Machine,
  then : ((Machine) -> Unit raise)?,
) -> Unit raise {
  if then is Some(k) {
    self.push(Task(k))
  }
  let pid = self.current.id
  self.last_id += 1
  let child = self.last_id
  self.procs[pid] = self.snapshot()
  self.current = {
    id: child,
    locals: self.current.locals,
    stack: self.current.stack,
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
  if then is Some(k) {
    self.push(Task(k))
  }
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
fn Machine::apply_pending(self : Machine) -> Unit raise {
  while !self.pending.is_empty() {
    match self.pending.remove(0) {
      Fork(then) => self.do_fork(then)
      Switch(id, then) => self.do_switch(id, then)
    }
  }
}

// ---------------------------------------------------------------------------
// Scheduler

///|
/// Runs the top-level scheduler loop: executes steps of the current
/// machine until its control stack is empty. Pending fork/switch requests
/// are applied after each step. If a step raises, the fork/switch requests
/// issued during that step are dropped, the control stack of the current
/// machine is discarded (its continuation is aborted, as upstream) and the
/// exception is propagated.
fn Machine::drive(self : Machine) -> Unit raise {
  while self.current.stack is Cons(frame, rest) {
    self.current.stack = rest
    self.depth += 1
    {
      errdefer {
        self.depth -= 1
        self.pending.clear()
        self.current.stack = Nil
      }
      self.exec_frame(frame)
    }
    self.depth -= 1
    if self.depth == 0 {
      self.apply_pending()
    }
  }
}

///|
/// Runs frames pushed by `push` until they are consumed (a nested,
/// synchronous run). Used by synchronous APIs like `Linker::exec`.
fn Machine::run_nested(self : Machine, push : () -> Unit raise) -> Unit raise {
  self.last_barrier += 1
  let marker = self.last_barrier
  self.push(Barrier(marker))
  self.depth += 1
  let unwind = fn() {
    for ;; {
      match self.current.stack {
        Cons(Barrier(k), rest) if k == marker => {
          self.current.stack = rest
          break
        }
        Cons(_, rest) => self.current.stack = rest
        Nil => break
      }
    }
    self.depth -= 1
  }
  errdefer unwind()
  push()
  for ;; {
    match self.current.stack {
      Cons(Barrier(k), rest) if k == marker => {
        self.current.stack = rest
        break
      }
      Cons(frame, rest) => {
        self.current.stack = rest
        self.exec_frame(frame)
      }
      Nil => break
    }
  }
  self.depth -= 1
  if self.depth == 0 {
    self.apply_pending()
  }
}

///|
/// Runs host code as a step (used for `init` and `fini`).
fn Machine::host_step(
  self : Machine,
  f : (Machine) -> Unit raise,
) -> Unit raise {
  self.depth += 1
  {
    errdefer {
      self.depth -= 1
      if self.depth == 0 {
        self.pending.clear()
      }
    }
    f(self)
  }
  self.depth -= 1
  if self.depth == 0 {
    self.apply_pending()
  }
}

///|
/// Runs a machine (upstream `Machine.run`).
///
/// - `boot` is run in the restricted mode (observations are dropped);
/// - `init` is run after the restriction is lifted;
/// - `start` is scheduled as the first task of the global machine, after
///   `system_start` is posted with `system`;
/// - the scheduler runs the current machine to completion; when it
///   finishes (normally or with an exception) `fini` is run; if `fini` (for
///   example a scheduler component observing `system_fini`) switched to
///   another live machine with a non-empty control stack, the scheduler
///   continues with that machine, otherwise `system_stop` is posted in the
///   restricted mode and the result is returned.
///
/// Returns the exit status of the last finished machine and the (possibly
/// updated) project.
pub fn Machine::run(
  proj : @project.Project,
  start? : (Machine) -> Unit raise = _ => (),
  boot? : (Machine) -> Unit raise = _ => (),
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  system? : String = "primus",
  args? : Array[String] = [],
  envp? : Array[String] = [],
) -> (ExitStatus, @project.Project) {
  let m = Machine::new(proj, args~, envp~)
  m.run_with(start~, boot~, init~, fini~, system~)
}

///|
/// Runs an already created machine (see `Machine::run`).
pub fn Machine::run_with(
  self : Machine,
  start? : (Machine) -> Unit raise = _ => (),
  boot? : (Machine) -> Unit raise = _ => (),
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  system? : String = "primus",
) -> (ExitStatus, @project.Project) {
  let m = self
  m.restricted = true
  try {
    m.host_step(boot)
    m.restricted = false
    m.host_step(init)
  } catch {
    e => return (Exn(e), m.proj)
  }
  m.push(
    Task(m => {
      m.make(started_stmt, system)
      start(m)
    }),
  )
  for ;; {
    let status : ExitStatus = try m.drive() catch {
      e => Exn(e)
    } noraise {
      _ => Normal
    }
    let final_status = try m.host_step(fini) catch {
      e => Exn(e)
    } noraise {
      _ => status
    }
    if m.current.stack is Cons(_, _) {
      continue
    }
    m.restricted = true
    m.make_even_if_restricted(stopped_stmt, system) catch {
      e => return (Exn(e), m.proj)
    }
    return (final_status, m.proj)
  }
}

///|
/// Allocates a fresh value identifier (the upstream global `value` state).
fn Machine::fresh_value_id(self : Machine) -> Int64 {
  self.last_value += 1L
  self.last_value
}
