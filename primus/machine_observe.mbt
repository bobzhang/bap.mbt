// Observations of a machine: subscriptions, synchronous notification and
// resumable (boundary) dispatch.

///|
/// Subscribes to an observation and returns the subscription handle
/// (`Machine.Observation.subscribe`). Observers subscribed later are called
/// earlier, as upstream. The observer runs synchronously, in the middle of
/// the step that posted the observation.
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
    slot.val = None
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
/// Subscribes a *resumable* observer: instead of running in the middle of
/// the step that posted the observation, the handler is scheduled as a
/// task that runs as its own step right after that step (before the
/// step's successors). The handler may therefore push frames, make
/// resumable calls (`Machine::call`) and fork or switch at any point of its
/// execution, e.g. a Primus Lisp signal handler evaluated as frames.
/// Exceptions raised by the handler go through the handler frames
/// (`Machine::push_handler`) like any other step. Cancel it with
/// `Machine::cancel`.
pub fn[T] Machine::subscribe_resumable(
  self : Machine,
  obs : Observation[T],
  f : (Machine, T) -> Unit raise,
) -> Subscription {
  self.subscribe(obs, x => self.schedule(m => f(m, x)))
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
/// Appends one closure per observer, watcher and listener of the event to
/// `out` (in delivery order). The value is captured, so the closures can be
/// run later (resumable dispatch).
fn[T] Machine::collect_observers(
  self : Machine,
  obs : Observation[T],
  x : T,
  out : Array[() -> Unit raise],
) -> Unit {
  let p = obs.provider
  p.triggers += 1
  let os = self.observers.get(obs.key).unwrap_or([])
  let ws = self.watchers.get(obs.key).unwrap_or([])
  let sexp : Ref[Sexp?] = { val: None, }
  let inspect = () => {
    match sexp.val {
      Some(s) => s
      None => {
        let s = (obs.inspect)(x)
        sexp.val = Some(s)
        s
      }
    }
  }
  for l in p.listeners {
    out.push(() => l(inspect()))
  }
  let slot = obs.slot
  for i = os.length() - 1; i >= 0; i = i - 1 {
    let run = os[i].1
    out.push(() => {
      slot.val = Some(x)
      run()
    })
  }
  for i = ws.length() - 1; i >= 0; i = i - 1 {
    let w = ws[i].1
    out.push(() => w(inspect()))
  }
}

///|
fn[T] Machine::notify(
  self : Machine,
  obs : Observation[T],
  x : T,
) -> Unit raise {
  if !self.has_observers(obs) {
    obs.provider.triggers += 1
    return
  }
  let items = []
  self.collect_observers(obs, x, items)
  for f in items {
    f()
  }
}

///|
/// Whether a resumable dispatch may suspend here: only in a top-level step
/// (not inside a nested synchronous run).
fn Machine::can_suspend(self : Machine) -> Bool {
  self.depth == 1 && self.nested == 0
}

///|
/// Runs the observer closures starting at `from`. If an observer requests
/// a fork or a switch in a top-level step, the remaining closures are saved
/// in a `Dispatch` frame that runs when the machine is resumed (in both
/// machines after a fork), and the dispatch stops.
fn Machine::dispatch(
  self : Machine,
  items : Array[() -> Unit raise],
  from : Int,
) -> Unit raise {
  let mark = self.deferred.length()
  for i in from..<items.length() {
    let pending = self.pending.length()
    items[i]()
    if self.can_suspend() &&
      self.pending.length() > pending &&
      i + 1 < items.length() {
      self.deferred.insert(mark, Dispatch(items, i + 1))
      return
    }
  }
}

///|
/// A group of term-boundary observations (e.g. `leave-blk`, `leave-term`,
/// `leave-pos`) posted together and dispatched resumably.
priv struct Boundary {
  machine : Machine
  items : Array[() -> Unit raise]
}

///|
fn Machine::boundary(self : Machine) -> Boundary {
  { machine: self, items: [], }
}

///|
fn[T] Boundary::add(self : Boundary, stmt : Statement[T], x : T) -> Unit {
  let m = self.machine
  if m.restricted {
    return
  }
  if m.has_observers(stmt.obs) {
    m.collect_observers(stmt.obs, x, self.items)
  } else {
    stmt.obs.provider.triggers += 1
  }
}

///|
fn Boundary::dispatch(self : Boundary) -> Unit raise {
  if !self.items.is_empty() {
    self.machine.dispatch(self.items, 0)
  }
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
