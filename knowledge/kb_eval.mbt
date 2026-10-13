///|
/// Global promise/observer identifiers (`pids`).
let pids : Ref[Int32] = { val: 0, }

///|
fn next_pid() -> Int32 {
  pids.val = pids.val + 1
  pids.val
}

///|
/// The empty value of the slot domain, or `Empty slot` for domains
/// without a bottom element.
fn[K, P] Slot::bottom(self : Slot[K, P]) -> P raise Conflict {
  match self.domain_value.empty() {
    Some(empty) => empty
    None => raise Empty(self.name)
  }
}

///|
fn[K, P] Slot::check_owner(
  self : Slot[K, P],
  object : Object[K],
) -> Unit raise Conflict {
  if object.class_name() != self.owner {
    raise Failure(
      "slot \{self.name.show()} does not belong to class \{object.class_name().show()}",
    )
  }
}

///|
/// The value currently stored in the slot (`current`), without running
/// any promises. `None` if nothing is stored and the domain has no bottom.
fn[K, P] State::current_opt(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> P? {
  let stored = match self.info(slot.owner, object.id()) {
    Some(info) => info.data.find(slot.core.key)
    None => None
  }
  match stored {
    Some(_) => stored
    None => slot.domain_value.empty()
  }
}

///|
/// `current p x`: the value currently stored in the slot, without running
/// any promises. Raises `Empty` if nothing is stored and the domain has no
/// bottom element.
pub fn[K, P] State::current(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> P raise Conflict {
  match self.current_opt(slot, object) {
    Some(value) => value
    None => raise Empty(slot.name)
  }
}

///|
/// `commit`: joins `value` into the stored value of the slot or diverges
/// with `NonMonotonicUpdate`.
fn[K, P] State::commit(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
  value : P,
) -> Unit raise Conflict {
  let objects = self.class_objects(slot.owner)
  let info = match objects.vals.get(object.id()) {
    Some(info) => info
    None => noinfo
  }
  match info.data.commit(slot.core.key, slot.core.ops, value) {
    Ok(data) =>
      self.set_class_objects(slot.owner, {
        ..objects,
        vals: objects.vals.add(object.id(), { ..info, data, }),
      })
    Err(error) =>
      raise NonMonotonicUpdate(slot=slot.name, repr=self.repr(object), error~)
  }
}

///|
/// `Knowledge.provide p x v`: joins `v` into the property `p` of `x` and
/// notifies the observers of `p`. Providing an empty value or providing
/// to the null object is a no-op. Diverges with `NonMonotonicUpdate` if
/// `v` conflicts with the stored value.
pub fn[K, P] State::provide(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
  value : P,
) -> Unit raise {
  if object.is_null() || slot.domain_value.is_empty(value) {
    return
  }
  slot.check_owner(object)
  self.commit(slot, object, value)
  // snapshot the observers: an observer may register or retract others
  let watchers = [ for _, run in slot.core.watchers => run ]
  for run in watchers {
    run(self, object.id(), object.class_name(), value)
  }
}

///|
/// `Knowledge.with_empty ~missing f`: evaluates `f` and, if it is rejected
/// (by `reject`, `guard`, `require`, ... i.e. raises `Empty` or `Reject`),
/// rolls the knowledge base back and evaluates to `missing`. Other
/// conflicts propagate.
pub fn[R] State::with_empty(
  self : State,
  missing~ : R,
  f : () -> R raise,
) -> R raise {
  let snapshot = self.env
  f() catch {
    err =>
      if is_rejection(err) {
        self.env = snapshot
        missing
      } else {
        raise err
      }
  }
}

///|
/// Runs a promise body under `with_empty`, yielding `None` on rejection.
fn[R] State::rejectable(self : State, f : () -> R raise) -> R? raise {
  self.with_empty(missing=None, () => Some(f()))
}

///|
priv enum SlotStatus {
  Sleep
  Awoke
  Ready
}

///|
fn[K, P] State::status(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> SlotStatus {
  match self.info(slot.owner, object.id()) {
    None => Sleep
    Some(info) =>
      match info.comp.get(slot.core.key.uid) {
        Some(Working(_, _)) => Awoke
        Some(Done) => Ready
        None =>
          match info.data.find(slot.core.key) {
            Some(value) if !slot.domain_value.is_empty(value) => Ready
            _ => Sleep
          }
      }
  }
}

///|
fn[K, P] State::update_work(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
  f : (Work?) -> Work,
) -> Unit {
  let uid = slot.core.key.uid
  self.update_info(slot.owner, object.id(), info => {
    ..info,
    comp: info.comp.add(uid, f(info.comp.get(uid))),
  })
}

///|
fn[K, P] State::working(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
  f : (@sorted_set.SortedSet[Int32], @sorted_set.SortedSet[Int32]) -> Work,
) -> Unit {
  self.update_work(slot, object, work => {
    match work {
      Some(Working(waiting, current)) => f(waiting, current)
      _ => f(@sorted_set.SortedSet::new(), @sorted_set.SortedSet::new())
    }
  })
}

///|
/// `dequeue_waiting`: the promises that must be re-run, clearing the queue.
fn[K, P] State::dequeue_waiting(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> Array[(Int32, (State, Int32, Name) -> Unit raise)] {
  let waiting = match self.info(slot.owner, object.id()) {
    Some({ comp, .. }) =>
      match comp.get(slot.core.key.uid) {
        Some(Working(waiting, _)) => waiting
        _ => @sorted_set.SortedSet::new()
      }
    None => @sorted_set.SortedSet::new()
  }
  self.working(slot, object, (_, _) => {
    Working(@sorted_set.SortedSet::new(), @sorted_set.SortedSet::new())
  })
  // upstream folds the pid tree into a list, i.e., the waiting promises
  // are re-run newest first
  let result = []
  for pid in waiting.rev_iter() {
    match slot.core.promises.get(pid) {
      Some(run) => result.push((pid, run))
      None => ()
    }
  }
  result
}

///|
/// `collect_inner`: runs the promises and iterates until the least fixed
/// point is reached, i.e., until no promise that observed an intermediate
/// approximation of the slot (through a re-entrant `collect`) needs to be
/// re-run, or the re-run did not add any information.
fn[K, P] State::collect_inner(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
  promises : Array[(Int32, (State, Int32, Name) -> Unit raise)],
) -> Unit raise {
  let was = self.current_opt(slot, object)
  for promise in promises {
    let (pid, run) = promise
    self.working(slot, object, (waiting, current) => {
      Working(waiting, current.add(pid))
    })
    run(self, object.id(), object.class_name())
    self.working(slot, object, (waiting, current) => {
      Working(waiting, current.remove(pid))
    })
  }
  let waiting = self.dequeue_waiting(slot, object)
  if waiting.is_empty() {
    return
  }
  let now = self.current_opt(slot, object)
  let changed = match (now, was) {
    (Some(now), Some(was)) =>
      match slot.domain_value.order(now, was) {
        Equal | Less => false
        Greater | Incomparable => true
      }
    (Some(_), None) => true
    (None, _) => false
  }
  if changed {
    self.collect_inner(slot, object, waiting)
  }
}

///|
/// `Knowledge.collect p x`: the value of the property `p` of `x`.
///
/// If the property was never computed for `x` (and no value was provided),
/// all promises of `p` are run and their results are joined into the
/// property. Promises may collect other properties, including `p` itself
/// (directly or through other properties): a re-entrant request for a
/// property that is being computed returns its current approximation and
/// re-schedules the requesting promises, so that the promises are
/// iterated until the least fixed point is reached. Once computed, the
/// property is never recomputed (later provides still refine it).
///
/// The null object always has the empty value. Raises `Empty` if nothing
/// is known and the slot domain has no bottom element.
pub fn[K, P] State::collect(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> P raise {
  if object.is_null() {
    return slot.bottom()
  }
  slot.check_owner(object)
  match self.status(slot, object) {
    Ready => ()
    Awoke =>
      // enqueue_promises: the running promises observed an intermediate
      // value and have to be re-run
      self.working(slot, object, (waiting, current) => {
        Working(waiting.union(current), current)
      })
    Sleep => {
      self.update_work(slot, object, _ => {
        Working(@sorted_set.SortedSet::new(), @sorted_set.SortedSet::new())
      })
      let promises = [ for pid, run in slot.core.promises => (pid, run) ]
      self.collect_inner(slot, object, promises)
      self.update_work(slot, object, _ => Done)
    }
  }
  self.current(slot, object)
}

///|
/// `Knowledge.require p x`: collects `p` and rejects with `Empty` if the
/// value is empty (so a promise that requires an unknown property
/// evaluates to the empty value).
pub fn[K, P] State::require(
  self : State,
  slot : Slot[K, P],
  object : Object[K],
) -> P raise {
  let value = self.collect(slot, object)
  if slot.domain_value.is_empty(value) {
    raise Empty(slot.name)
  }
  value
}

///|
/// `x -->? p`: collects an optional property and rejects if it is `None`.
pub fn[K, P] State::require_some(
  self : State,
  slot : Slot[K, P?],
  object : Object[K],
) -> P raise {
  match self.collect(slot, object) {
    Some(value) => value
    None => raise Empty(slot.name)
  }
}

///|
/// `Knowledge.resolve p x`: collects the opinions of `p` and computes the
/// consensus.
pub fn[K, P] State::resolve(
  self : State,
  slot : Slot[K, Opinions[P]],
  object : Object[K],
) -> P raise {
  self.collect(slot, object).choice()
}

///|
/// `Knowledge.suggest agent p x v`: provides `v` as the opinion of `agent`.
pub fn[K, P] State::suggest(
  self : State,
  agent : Agent,
  slot : Slot[K, Opinions[P]],
  object : Object[K],
  value : P,
) -> Unit raise {
  let opinions = self.current(slot, object)
  self.provide(slot, object, opinions.add(agent, value))
}

///|
/// Wraps a promise body (`wrap`): rejection yields no information.
fn[K, P] Slot::promise_action(
  self : Slot[K, P],
  get : (State, Object[K]) -> P raise,
) -> (State, Int32, Name) -> Unit raise {
  (state, id, class_name) => {
    let object : Object[K] = { id, class_name, _phantom: None, }
    match state.rejectable(() => get(state, object)) {
      Some(value) =>
        if !self.domain_value.is_empty(value) {
          state.provide(self, object, value)
        }
      None => ()
    }
  }
}

///|
fn[K, P] Slot::proposal_action(
  self : Slot[K, Opinions[P]],
  agent : Agent,
  get : (State, Object[K]) -> P raise,
) -> (State, Int32, Name) -> Unit raise {
  (state, id, class_name) => {
    let object : Object[K] = { id, class_name, _phantom: None, }
    match state.rejectable(() => get(state, object)) {
      Some(value) => state.suggest(agent, self, object, value)
      None => ()
    }
  }
}

///|
/// `Knowledge.promise p f`: promises to compute the property `p` with `f`.
///
/// `f` is run (inside `with_empty`) when `p` is collected for an object
/// whose property was not computed yet; its non-empty result is provided
/// to `p`. `f` may refer to `p` directly or indirectly, in which case the
/// least fixed point of all involved promises is computed. Promises are
/// run in registration order and are never run on the null object.
/// Returns the promise id.
pub fn[K, P] Slot::promise(
  self : Slot[K, P],
  f : (State, Object[K]) -> P raise,
) -> Int32 {
  let pid = next_pid()
  self.core.promises[pid] = self.promise_action(f)
  pid
}

///|
/// Retracts a promise or proposal registered on the slot.
pub fn[K, P] Slot::retract(self : Slot[K, P], pid : Int32) -> Unit {
  self.core.promises.remove(pid)
}

///|
/// Removes an observer registered on the slot.
pub fn[K, P] Slot::unobserve(self : Slot[K, P], pid : Int32) -> Unit {
  self.core.watchers.remove(pid)
}

///|
/// `Knowledge.promising p ~promise scope`: evaluates `scope` with the
/// promise active and retracts the promise afterwards.
pub fn[K, P, R] Slot::promising(
  self : Slot[K, P],
  promise~ : (State, Object[K]) -> P raise,
  scope : () -> R raise?,
) -> R raise? {
  let pid = self.promise(promise)
  errdefer self.retract(pid)
  let result = scope()
  self.retract(pid)
  result
}

///|
/// `Knowledge.propose agent p f`: promises an opinion of `agent`.
pub fn[K, P] Slot::propose(
  self : Slot[K, Opinions[P]],
  agent : Agent,
  f : (State, Object[K]) -> P raise,
) -> Int32 {
  let pid = next_pid()
  self.core.promises[pid] = self.proposal_action(agent, f)
  pid
}

///|
/// `Knowledge.proposing agent p ~propose scope`: a scope-limited proposal.
pub fn[K, P, R] Slot::proposing(
  self : Slot[K, Opinions[P]],
  agent : Agent,
  propose~ : (State, Object[K]) -> P raise,
  scope : () -> R raise?,
) -> R raise? {
  let pid = self.propose(agent, propose)
  errdefer self.retract(pid)
  let result = scope()
  self.retract(pid)
  result
}

///|
/// `Knowledge.observe p push`: calls `push x v` whenever a non-empty value
/// `v` is provided to the property `p` of `x` (forward chaining). Returns
/// the observer id.
pub fn[K, P] Slot::observe(
  self : Slot[K, P],
  push : (State, Object[K], P) -> Unit raise,
) -> Int32 {
  let pid = next_pid()
  self.core.watchers[pid] = (state, id, class_name, value) => {
    push(state, { id, class_name, _phantom: None, }, value)
  }
  pid
}

///|
/// `Knowledge.observing p ~observe scope`: observes `p` during `scope`.
pub fn[K, P, R] Slot::observing(
  self : Slot[K, P],
  observe~ : (State, Object[K], P) -> Unit raise,
  scope : () -> R raise?,
) -> R raise? {
  let pid = self.observe(observe)
  errdefer self.unobserve(pid)
  let result = scope()
  self.unobserve(pid)
  result
}
