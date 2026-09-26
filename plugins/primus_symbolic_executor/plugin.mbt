///|
/// # The Primus symbolic executor (upstream `plugins/primus_symbolic_executor`)
///
/// Tracks a symbolic formula (a Z3 bitvector term) alongside every Primus
/// value computed from a program input, collects the path constraints at
/// branches, and explores the feasible paths by forking machines whose
/// inputs are generated from the models of the constraints.
///
/// The executor consists of four components, all part of the
/// `bap:symbolic-executor` system:
///
/// - `bap:symbolic-computer` (`install_computer`) computes the formulas;
///   generated variables and memory cells are the inputs;
/// - `bap:symbolic-path-constraints` (`install_path_constraints`) records
///   the branch conditions of the path;
/// - `bap:symbolic-path-explorer` (`install_path_explorer`) queues a task
///   for every branch side that the concrete execution did not take and
///   runs the satisfiable ones (see `forker.mbt`);
/// - `bap:symbolic-lisp-primitives` (`install_lisp_primitives`) defines
///   `symbolic-value`, `symbolic-memory`, `symbolic-memory-read`,
///   `symbolic-memory-write`, `symbolic-assume` and `symbolic-assert`.
///
/// The `symbolic-stdio` Lisp library (embedded in `primus_lisp` under
/// `symbolic-executor/`) models `open`/`read`/`fopen`/`fgetc`/... over
/// symbolic files and a symbolic standard input.
///
/// The solver is loaded at run time (see `@z3`); without it the computer
/// component fails with "SMT solver unavailable".
pub let name : String = "primus-symbolic-executor"

///|
/// The names of the components (in the `bap` package).
pub let components : Array[String] = [
  "symbolic-computer", "symbolic-path-explorer", "symbolic-lisp-primitives", "symbolic-path-constraints",
]

///|
/// Registers the executor components. Idempotent: returns `false` if they
/// were already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    "symbolic-computer",
    install_computer,
    pkg="bap",
    desc="Computes a symbolic formula for each Primus value.",
  ) catch {
    _ => return false
  }
  let others : Array[(String, String, (@primus.Machine) -> Unit raise)] = [
    (
      "symbolic-path-explorer",
      "Computes a path constraint for each branch and forks a new machine if the constraint is satisfiable.",
      m => install_path_explorer(m),
    ),
    (
      "symbolic-lisp-primitives",
      "Provides assume and assert primitives.",
      m => install_lisp_primitives(m),
    ),
    (
      "symbolic-path-constraints",
      "tracks the path constraint and records them in the machine's symbolic context",
      m => install_path_constraints(m),
    ),
  ]
  for c in others {
    @primus.Components::register_generic(c.0, c.2, pkg="bap", desc=c.1) catch {
      _ => ()
    }
  }
  true
}

///|
/// Declares the `primus-symbolic-executor` plugin to `bap_main` with its
/// `cutoff-level` and `timeout` parameters
/// (`--primus-symbolic-executor-cutoff-level`,
/// `--primus-symbolic-executor-timeout`). Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "symbolic-executor"],
    doc="provides a Primus symbolic executor",
    () => {
      let cutoff_level = @bap_main.Configuration::parameter(
        @bap_main.Type::int().with_default(1),
        "cutoff-level",
        doc="The number of times the same branch is retried.",
      )
      let timeout = @bap_main.Configuration::parameter(
        @bap_main.Type::int().with_default(16),
        "timeout",
        doc="The number of milliseconds alloted to the SMT solver to find a model",
      )
      @bap_main.Extension::register(ctxt => {
        set_cutoff(ctxt.get(cutoff_level))
        set_timeout(ctxt.get(timeout))
        register() |> ignore
      })
    },
  )
}
