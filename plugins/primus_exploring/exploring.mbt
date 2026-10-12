///|
/// # The exploring Primus scheduler (upstream `plugins/primus_exploring`)
///
/// The exploring scheduler prioritizes clones that wander into not yet
/// explored or less explored areas: from the set of live machines it
/// chooses those whose next term (their current position) was evaluated
/// the least number of times. The context is switched after each basic
/// block (`leave_blk`), and the scheduler counts how many times each
/// block and subroutine was evaluated (`leave_blk`, `leave_sub`).
///
/// When the queue of planned machines is empty, a new round is planned:
/// every live machine whose position is an unexplored term (or a term
/// explored exactly `level` times, starting with level zero) is queued; a
/// term that is already planned in this round is not planned twice. If
/// nothing was queued, the level is increased.
///
/// Note (faithful to upstream): the position of a machine suspended at
/// `leave_blk` is the last jump term it evaluated, while the counters are
/// keyed by block and subroutine identifiers. Hence machines stopped at a
/// block boundary always look unexplored, and a planning round queues all
/// of them except those that stand at the same jump as a machine queued
/// before (machines are deduplicated by position).
///
/// Deviations from upstream: upstream switches to every machine to learn
/// its position; the port reads the positions of suspended machines with
/// `@primus.Interpreter::pos_of` instead. Upstream also stores the
/// updated scheduler state in the continuation of the switch (i.e., when
/// the switching machine is resumed, overwriting the updates made by
/// other machines in between); the port stores it before switching.
pub let component_name : String = "exploring-scheduler"

///|
priv struct Exploring {
  explored : @immut_hashmap.HashMap[@types.Tid, Int32]
  pending : @list.List[@primus.Id]
}

///|
let state : @primus.State[Exploring] = @primus.State::declare_(
  uuid="5a863fc2-96cf-4a00-b046-b9b38f95aa11",
  name="exploring-scheduler",
  _ => { explored: @immut_hashmap.new(), pending: @list.List([]), },
)

///|
/// How many times the term was explored (evaluated) so far.
pub fn explored(m : @primus.Machine, tid : @types.Tid) -> Int32 {
  m.get_global(state).explored.get(tid).unwrap_or(0)
}

///|
fn position(m : @primus.Machine, id : @primus.Id) -> @types.Tid raise {
  if id == m.current() {
    @primus.Interpreter::pos(m).tid()
  } else {
    @primus.Interpreter::pos_of(m, id).tid()
  }
}

///|
/// Queues `id` if its position is unexplored or explored `level` times
/// (upstream `enqueue`).
fn enqueue(
  m : @primus.Machine,
  level : Int32,
  t : Exploring,
  queued : Array[@primus.Id],
  id : @primus.Id,
) -> Exploring raise {
  let tid = position(m, id)
  let add = (level : Int32) => {
    queued.push(id)
    { ..t, explored: t.explored.add(tid, level), }
  }
  match t.explored.get(tid) {
    None => add(0)
    Some(0) => t
    Some(n) if n == level => add(level)
    Some(_) => t
  }
}

///|
fn remove_planned_explorations(t : Exploring) -> Exploring {
  { ..t, explored: t.explored.filter((_, n) => n != 0), }
}

///|
fn reschedule(m : @primus.Machine, t : Exploring) -> Exploring raise {
  let forks = m.forks()
  for level = 0, t = t {
    let queued = []
    let mut t = t
    for id in forks {
      t = enqueue(m, level, t, queued, id)
    }
    if queued.is_empty() {
      continue level + 1, t
    } else {
      break { ..remove_planned_explorations(t), pending: @list.List(queued), }
    }
  }
}

///|
fn step(m : @primus.Machine) -> Unit raise {
  let t = m.get_global(state)
  let t = match t.pending {
    Empty => reschedule(m, t)
    More(_, ..) => t
  }
  guard t.pending is More(id, tail=pending) else { return }
  m.put_global(state, { ..t, pending, })
  m.switch(id)
}

///|
fn visit(m : @primus.Machine, tid : @types.Tid) -> Unit {
  m.update_global(state, s => {
    ..s,
    explored: s.explored.add(tid, s.explored.get(tid).unwrap_or(0) + 1),
  })
}

///|
/// Initializes the scheduler in the machine (the component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_blk, _ => step(m))
  m.observe(@primus.leave_blk, b => visit(m, b.tid()))
  m.observe(@primus.leave_sub, s => visit(m, s.tid()))
}

///|
let desc : String = "The exploring scheduler will prioritize clones that will wonder into not yet explored or less explored areas. More specifically, from a set of machine clones, it will choose those, that will proceed to a basic block that was visited the least amount of times. The round-robin scheduler will switch the context after each basic block. It will count the number of time the block was evaluated"

///|
/// Registers the `bap:exploring-scheduler` component. Idempotent: returns
/// `false` if the component was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Enables the exploring scheduler (experimental). " + desc,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the scheduler to the legacy main system (upstream
/// `--primus-exploring-scheduler`). Idempotent.
pub fn enable() -> Unit {
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-exploring"

///|
/// Declares the `primus-exploring` plugin to `bap_main` with its
/// `scheduler` flag. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "scheduler"],
    doc="evaluates all Primus machines, prioritizing the least visited\n\n" +
      desc,
    () => {
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
    },
  )
}
