///|
let doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Populates and run the Primus Jobs queue. Creates new job for each
  #|specified system and runs the queued jobs (including those that were
  #|already added to the queue by other analyses). After the job queue is
  #|emptied, commits the obtained knowledge and passes the resulting project
  #|data structure downstream.
  #|

///|
/// Declares the `run` plugin (the `run` pass and the `--run-*` options)
/// in the `bap_main` framework. Does nothing if it is already registered.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["pass", "primus", "emulator", "microexecution"],
    doc="emulates the program using Primus",
    () => {
      @bap_main.Extension::documentation(doc)
      let strings = @bap_main.Type::list(@bap_main.Type::string())
      let argv = @bap_main.Configuration::parameter(
        doc="Process argument vector",
        strings,
        "argv",
      )
      let envp = @bap_main.Configuration::parameter(
        doc="Program environemt as a comma separated list of VAR=VAL pairs",
        strings,
        "env",
      )
      let entry = @bap_main.Configuration::parameter(
        doc="Can be a list of $(i,entry points) or one of the following keywords: $(b,all-subroutines), $(b,marked-subroutines), $(b,only-queue). An $(i,entry point) is either a string denoting a function name, a tid starting with the $(b,%) (percent) symbol, or an address in a hexadecimal format prefixed with $(b,0x). When the option is specified, the Primus Machine will start the execution from the specified entry point(s). Otherwise the execution will be started from all program terms that are marked with the [entry_point] attribute. If neither the argument nor there any entry points in the program, then a function called $(b,_start) is called.",
        strings,
        "entry-points",
      )
      let in_isolation = @bap_main.Configuration::flag(
        doc="Run each entry point as new system. Each entry point is enqueued as a job and run in a separate systems.",
        "in-isolation",
      )
      let with_repetitions = @bap_main.Configuration::flag(
        doc="Run all subroutines in a row, even those that were visited during the run of other ones.",
        "with-repetitions",
      )
      let systems = @bap_main.Configuration::parameters(
        doc="Runs the specified Primus systems. If several systems are specified then runs all entry points for each specified system.",
        strings,
        "systems",
      )
      let until_visited = @bap_main.Configuration::flag(
        doc="Runs Primus until all subroutines and blocks are visited.",
        "until-visited-all",
      )
      @bap_main.Extension::register(
        doc="emulates the program using Primus",
        provides=["pass", "primus", "emulator", "microexecution"],
        ctxt => {
          let systems = ctxt.get(systems).fold(init=[], (a, b) => a + b)
          let params = Params::new(
            argv=ctxt.get(argv),
            envp=ctxt.get(envp),
            entry=ctxt.get(entry),
            in_isolation=ctxt.get(in_isolation),
            with_repetitions=ctxt.get(with_repetitions),
            systems=if systems.is_empty() {
              ["bap:legacy-main"]
            } else {
              systems
            },
            until_visited=ctxt.get(until_visited),
          )
          match register(params) {
            Ok(_) => ()
            Err(msg) => fail(msg)
          }
        },
      )
    },
  )
}
