///|
let legacy_components : Ref[Int32] = { val: 0, }

///|
fn init {
  Components::register_generic(
    "load-binary",
    m => Interpreter::link_program(m),
    pkg="bap",
    desc="Links the binary program into the Primus machine. All symbols of the binary program are linked weakly, i.e., if a symbol is already linked, then this component will not override it.",
  ) catch {
    _ => ()
  }
  System::register(
    System::define_(
      "legacy-main",
      pkg="bap",
      components=[System::component("load-binary", pkg="bap")],
      desc="The legacy Primus system that contains all components registered with the Machine.add_component function.",
    ),
  ) catch {
    _ => ()
  }
}

///|
/// Adds a component to the legacy main system (upstream
/// `Primus.Machine.add_component`).
pub fn Machine::add_component(init : (Machine) -> Unit raise) -> Unit {
  legacy_components.val += 1
  let name = "legacy-main-component-\{legacy_components.val}"
  Components::register_generic(
    name,
    init,
    internal=true,
    pkg="bap-internal",
    desc="an anonymous component of the legacy main system",
  ) catch {
    _ => ()
  }
  System::update("legacy-main", pkg="bap", sys => {
    sys.add_component(name, pkg="bap-internal")
  }) catch {
    _ => ()
  }
}

///|
/// Runs the legacy main system with the user code as the start
/// computation (upstream `Primus.Machine.Main(M).run`).
pub fn Machine::run_main(
  envp~ : Array[String] = [],
  args~ : Array[String] = [],
  proj : @project.Project,
  user : (Machine) -> Unit raise,
) -> (ExitStatus, @project.Project) raise SystemError {
  System::get("legacy-main", pkg="bap").run(proj, envp~, args~, start=user)
}
