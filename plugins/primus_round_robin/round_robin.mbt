///|
/// # The round-robin Primus scheduler (upstream `plugins/primus_round_robin`)
///
/// The round-robin scheduler distributes machine time equally between
/// the competing clones: after each basic block (`leave_blk`) the context
/// is switched to the next machine of a queue. When the queue is empty it
/// is refilled with all live machines that have not yet finished, so the
/// state tree is traversed in an order close to the breadth-first order.
/// When a machine finishes (`system_fini`) it is marked as finished and
/// the next machine is scheduled.
///
/// Deviation from upstream: the upstream `schedule` function continues
/// with another `schedule` after `Machine.switch next` returns, i.e., a
/// machine that is resumed immediately reschedules itself instead of
/// running. This makes the upstream (experimental) scheduler livelock as
/// soon as every machine has been switched away once (with a single
/// machine it spins at the first block). The port implements the
/// documented intent: a resumed machine continues its execution, and
/// machines that have already finished are skipped when dequeued (upstream
/// relied on the rescheduling continuation of finished machines for that).
pub let component_name : String = "round-robin-scheduler"

///|
/// The scheduler state: the queue of machines to run and the set of
/// finished machines.
priv struct RoundRobin {
  pending : @list.List[@primus.Id]
  finished : @sorted_set.SortedSet[@primus.Id]
}

///|
let state : @primus.State[RoundRobin] = @primus.State::declare_(
  uuid="d1b33e16-bf5d-48d5-a174-3901dff3d123",
  name="round-robin-scheduler",
  _ => { pending: @list.List([]), finished: @sorted_set.new(), },
)

///|
/// The machines that have finished so far.
pub fn finished(m : @primus.Machine) -> Array[@primus.Id] {
  m.get_global(state).finished.to_array()
}

///|
fn schedule(m : @primus.Machine, t : RoundRobin) -> Unit raise {
  for t = t {
    match t.pending {
      Empty => {
        let fs = m.forks().filter(id => !t.finished.contains(id))
        if fs.is_empty() {
          return
        }
        continue { ..t, pending: @list.List(fs), }
      }
      More(next, tail=pending) =>
        if m.status(next) is Dead || t.finished.contains(next) {
          continue { pending, finished: t.finished.add(next), }
        } else {
          m.put_global(state, { ..t, pending, })
          m.switch(next)
          return
        }
    }
  }
}

///|
fn step(m : @primus.Machine) -> Unit raise {
  schedule(m, m.get_global(state))
}

///|
fn finish(m : @primus.Machine) -> Unit raise {
  let id = m.current()
  m.update_global(state, t => { ..t, finished: t.finished.add(id), })
  step(m)
}

///|
/// Initializes the scheduler in the machine (the component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_blk, _ => step(m))
  m.observe(@primus.system_fini, _ => finish(m))
}

///|
/// Registers the `bap:round-robin-scheduler` component. Idempotent:
/// returns `false` if the component was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Enables the round-robin scheduler (experimental).",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the scheduler to the legacy main system (upstream
/// `--primus-round-robin-scheduler`). Idempotent.
pub fn enable() -> Unit {
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-round-robin"

///|
let doc : String =
  #|schedules Primus machines in the BFS order
  #|
  #|The round-robin scheduler will try to distribute machine time equally
  #|between competing clones. The state tree will be traversed in an order
  #|that is close to the bread-first search order. The round-robin scheduler
  #|will switch the context after each basic block.

///|
/// Declares the `primus-round-robin` plugin to `bap_main` with its
/// `scheduler` flag. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["primus", "scheduler"], doc~, () => {
    let flag = @bap_main.Configuration::flag(
      "scheduler",
      doc="Enable the scheduler.",
    )
    @bap_main.Extension::register(ctxt => {
      register() |> ignore
      if ctxt.get(flag) {
        enable()
      }
    })
  })
}
