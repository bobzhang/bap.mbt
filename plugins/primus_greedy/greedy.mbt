///|
/// # The greedy Primus scheduler (upstream `plugins/primus_greedy`)
///
/// The greedy scheduling strategy continues with the same machine until
/// it reaches a termination state (the machine has nothing left to
/// evaluate). Then another live machine that is not yet halted is chosen:
/// the newest one (the one with the largest identifier), which yields a
/// depth-first traversal of the state tree. The finished machine is
/// killed. When no such machine exists the scheduler switches to the
/// global machine and the whole system terminates, so all paths are
/// explored.
///
/// The scheduler reacts to the `system_fini` observation, which is
/// posted every time a machine finishes when the machine is run as a
/// Primus system (`@primus.System::run`).
pub let component_name : String = "greedy-scheduler"

///|
let desc : String = "The greedy scheduling strategy will continue with the same state, unless the machine reaches a termination state, i.e., when the next value in a context becomes None. In that case another alive state that has a next value that is not None is chosen. If such state doesn't exist, then the Machine finally terminates. Thus this strategy will perform a depth-first traversal of the state tree, and guarantees that all paths are explored. The greedy scheduler will attempt to reschedule every time a basic block is evaluated."

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-greedy",
)

///|
/// The global scheduler state: the set of halted machines.
let state : @primus.State[@sorted_set.SortedSet[@primus.Id]] = @primus.State::declare_(
  uuid="328fd42b-1ffd-44da-8400-8494732dcfa3",
  name="greedy-scheduler-state",
  _ => @sorted_set.new(),
)

///|
/// The identifiers of the machines that have already halted.
pub fn halted(m : @primus.Machine) -> Array[@primus.Id] {
  m.get_global(state).to_array()
}

///|
fn reschedule(m : @primus.Machine) -> Unit raise {
  let halted = m.get_global(state)
  let active = m.forks().filter(id => !halted.contains(id))
  let total = active.length() + halted.length()
  log.report_progress(stage=halted.length() - 1, total~)
  match active.last() {
    None => {
      log.info(message="no more pending machines")
      m.switch(@primus.Id::global())
    }
    Some(cid) => {
      let pid = m.current()
      log.info(message="switch to machine \{cid} from \{pid}")
      log.info(message="killing previous machine \{pid}")
      m.kill(pid)
      m.switch(cid)
    }
  }
}

///|
fn halt(m : @primus.Machine) -> Unit raise {
  let pid = m.current()
  m.update_global(state, s => s.add(pid))
  reschedule(m)
}

///|
/// Initializes the scheduler in the machine (the component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.system_fini, _ => halt(m))
}

///|
/// Registers the `bap:greedy-scheduler` component. Idempotent: returns
/// `false` if the component was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Enables the greedy scheduler. " + desc,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the scheduler to the legacy main system (upstream
/// `--primus-greedy-scheduler`). Idempotent.
pub fn enable() -> Unit {
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-greedy"

///|
/// Declares the `primus-greedy` plugin to `bap_main` with its `scheduler`
/// flag (`--primus-greedy-scheduler`). Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "scheduler"],
    doc="schedules Primus machines in the DFS order",
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
