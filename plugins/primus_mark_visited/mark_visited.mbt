///|
/// # Visited-terms marking (upstream `plugins/primus_mark_visited`)
///
/// Provides the `bap:mark-visited` component (implemented in
/// `@primus_track_visited`) and the `bap:report-visited` component, which
/// reports the progress (the number of visited blocks out of the total)
/// every time a basic block is visited.
pub let component_name : String = "report-visited"

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-mark-visited",
)

///|
/// Initializes the progress reporter in the machine (the
/// `bap:report-visited` component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus_track_visited.progress, p => {
    let (visited, total) = p
    log.report_progress(stage=visited - 1, total~)
  })
}

///|
/// Registers the `bap:mark-visited` and `bap:report-visited` components.
/// Idempotent: returns `false` if `bap:report-visited` was already
/// registered.
pub fn register() -> Bool {
  @primus_track_visited.register() |> ignore
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Reports progress when a new basic block is discovered.",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the components and adds both to the legacy main system, as
/// the upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  register() |> ignore
  @primus_track_visited.init_tracker()
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-mark-visited"

///|
/// Declares the `primus-mark-visited` plugin to `bap_main`. Does nothing if
/// already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "component"],
    doc="Provides the bap:mark-visited and bap:report-visited components.",
    () => @bap_main.Extension::register(_ => enable()),
  )
}
