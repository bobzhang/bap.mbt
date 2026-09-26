// The `run` pass (upstream `Run_main`): populates and runs the Primus job
// queue.

///|
/// The name of the plugin and of its pass.
pub let name : String = "run"

///|
/// A bad parameter of the pass (upstream `Invalid_argument`).
pub(all) suberror RunError {
  InvalidArgument(String)
}

///|
pub fn RunError::to_string(self : RunError) -> String {
  match self {
    InvalidArgument(msg) => msg
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
fn register_error_printer() -> Unit {
  if !printer_registered.val {
    printer_registered.val = true
    @bap_main.register_error_printer(e => {
      match e {
        InvalidArgument(msg) => Some(msg)
        _ => None
      }
    })
  }
}

///|
let reporter : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section=name,
)

///|
/// The parameters of the pass (the `--run-*` options).
pub(all) struct Params {
  /// The process argument vector (`--run-argv`).
  argv : Array[String]
  /// The process environment (`--run-env`).
  envp : Array[String]
  /// The entry points or one of the `all-subroutines`,
  /// `marked-subroutines`, `only-queue` keywords (`--run-entry-points`).
  entry : Array[String]
  /// Run each entry point as a separate job (`--run-in-isolation`).
  in_isolation : Bool
  /// Run entry points that were already visited (`--run-with-repetitions`).
  with_repetitions : Bool
  /// The Primus systems to run (`--run-systems`).
  systems : Array[String]
  /// Run until all subroutines and blocks are visited
  /// (`--run-until-visited-all`).
  until_visited : Bool
} derive(Debug)

///|
pub extend Params with Debug::{to_repr}

///|
pub fn Params::new(
  argv? : Array[String] = [],
  envp? : Array[String] = [],
  entry? : Array[String] = [],
  in_isolation? : Bool = false,
  with_repetitions? : Bool = false,
  systems? : Array[String] = ["bap:legacy-main"],
  until_visited? : Bool = false,
) -> Params {
  { argv, envp, entry, in_isolation, with_repetitions, systems, until_visited, }
}

///|
/// Parses an entry point (upstream `name_of_entry`): a tid starting with
/// `%`, an address starting with `0`, or a symbol name.
pub fn name_of_entry(width : Int, entry : String) -> @primus.Name raise {
  if entry == "" {
    raise InvalidArgument("An entry point should be a non-empty string")
  }
  if entry.has_prefix("%") {
    match @types.Tid::from_string(entry) {
      Ok(tid) => Tid(tid)
      Err(msg) => raise InvalidArgument(msg)
    }
  } else if entry.has_prefix("0") {
    Addr(@types.Word::of_int64(parse_int64(entry), width~))
  } else {
    Symbol(entry)
  }
}

///|
/// Parses an integer literal like OCaml's `Int64.of_string`: decimal or
/// hexadecimal, octal, and binary with the `0x`, `0o`, and `0b` prefixes.
fn parse_int64(s : String) -> Int64 raise {
  let (digits, radix) = if s.has_prefix("0x") || s.has_prefix("0X") {
    (s[2:].to_owned(), 16)
  } else if s.has_prefix("0o") {
    (s[2:].to_owned(), 8)
  } else if s.has_prefix("0b") {
    (s[2:].to_owned(), 2)
  } else {
    (s, 10)
  }
  if digits == "" {
    raise InvalidArgument("Int64.of_string: \{s}")
  }
  let mut v = 0UL
  for c in digits {
    let d = match c {
      '0'..='9' => c.to_int() - '0'.to_int()
      'a'..='f' => c.to_int() - 'a'.to_int() + 10
      'A'..='F' => c.to_int() - 'A'.to_int() + 10
      '_' => continue
      _ => raise InvalidArgument("Int64.of_string: \{s}")
    }
    if d >= radix {
      raise InvalidArgument("Int64.of_string: \{s}")
    }
    v = v * radix.to_uint64() + d.to_uint64()
  }
  v.reinterpret_as_int64()
}

///|
/// The subroutines marked as entry points (upstream `entry_points`).
pub fn entry_points(prog : @types.Term[@types.Program]) -> Array[@types.Tid] {
  prog.subs().filter(sub => sub.is_entry_point()).map(sub => sub.tid())
}

///|
/// All subroutines in the topological order of the callgraph, the entry
/// points first (upstream `all_subroutines`). With `marked`, only the
/// subroutines that have the `mark` attribute.
pub fn all_subroutines(
  prog : @types.Term[@types.Program],
  marked? : Bool = false,
) -> Array[@primus.Name] {
  let entries = entry_points(prog)
  let unmarked : Array[@types.Tid] = []
  if marked {
    for sub in prog.subs() {
      if !@types.IrTerm::SubTerm(sub).has_mark() {
        unmarked.push(sub.tid())
      }
    }
  }
  let result : Array[@primus.Name] = []
  for t in entries {
    if !unmarked.contains(t) {
      result.push(Tid(t))
    }
  }
  let order = prog.program_callgraph().reverse_postorder_traverse()
  for t in order {
    if !entries.contains(t) && !unmarked.contains(t) {
      result.push(Tid(t))
    }
  }
  // subroutines that are not in the callgraph
  for sub in prog.subs() {
    let t = sub.tid()
    if !entries.contains(t) && !unmarked.contains(t) && !order.contains(t) {
      result.push(Tid(t))
    }
  }
  result
}

///|
/// The entry points to run (upstream `parse_entry_points`).
pub fn parse_entry_points(
  proj : @project.Project,
  entries : Array[String],
) -> Array[@primus.Name] raise {
  if entries is ["only-queue"] {
    return []
  }
  let prog = proj.program()
  let parsed = match entries {
    ["all-subroutines"] => all_subroutines(prog)
    ["marked-subroutines"] => all_subroutines(prog, marked=true)
    [] => entry_points(prog).map(t => @primus.Name::Tid(t))
    xs => {
      let width = proj.target().code_addr_size()
      xs.map(x => name_of_entry(width, x))
    }
  }
  match (entries, parsed) {
    (["marked-subroutines"], []) => []
    (_, []) => [Symbol("_start")]
    (_, xs) => xs
  }
}

///|
/// The subroutines entered by the machines (upstream `visited`).
let visited : @primus.State[Array[@types.Tid]] = @primus.State::declare_(
  uuid="c6028425-a8c7-48cf-b6d9-57a44ed9a08a",
  name="visited-subroutines",
  clone=xs => xs.copy(),
  _ => [],
)

///|
/// The component that records the visited subroutines (upstream
/// `Visited`).
fn record_visited(m : @primus.Machine) -> Unit {
  m.observe(@primus.enter_sub, sub => {
    let tids = m.get_global(visited)
    if !tids.contains(sub.tid()) {
      m.put_global(visited, [..tids, sub.tid()])
    }
  })
}

///|
fn is_visited_in_machine(m : @primus.Machine, x : @primus.Name) -> Bool {
  match x {
    Tid(tid) => m.get_global(visited).contains(tid)
    _ => false
  }
}

///|
/// Executes the entry point, reporting (and swallowing) the machine
/// exceptions, and then halts the machine (upstream `exec` followed by
/// `Eval.halt`).
fn exec_and_halt(m : @primus.Machine, x : @primus.Name) -> Unit {
  reporter.info(
    message="Fork \{m.current()}: starting from the \{x} entry point",
  )
  // frames run in the reverse order of their scheduling
  m.schedule(m => @primus.Interpreter::halt(m))
  m.push_handler((_, exn) => {
    reporter.info(message="execution from \{x} terminated with: \{exn}")
  })
  @primus.Linker::schedule_exec(m, x)
}

///|
/// The start of the job that runs all entries in one system, each in its
/// own fork (upstream `run`).
fn run_entries(
  need_repeat : Bool,
  entries : Array[@primus.Name],
) -> (@primus.Machine) -> Unit raise {
  fn loop_(m : @primus.Machine, stage : Int) -> Unit raise {
    match entries.get(stage) {
      None => {
        reporter.info(message="all toplevel machines done, halting")
        @primus.Interpreter::halt(m)
      }
      Some(x) => {
        let pid = m.current()
        m.fork(then=m => {
          if m.current() == pid {
            loop_(m, stage + 1)
          } else if is_visited_in_machine(m, x) && !need_repeat {
            @primus.Interpreter::halt(m)
          } else {
            exec_and_halt(m, x)
          }
        })
      }
    }
  }

  m => loop_(m, 0)
}

///|
fn enqueue_super_job(
  need_repeat : Bool,
  params : Params,
  sys : @primus.System,
  xs : Array[@primus.Name],
) -> Unit {
  @primus.Jobs::enqueue(
    sys,
    envp=params.envp,
    args=params.argv,
    name="multi-task",
    desc="runs all entries in one system",
    start=run_entries(need_repeat, xs),
  )
}

///|
/// Whether the first block of the subroutine is visited (upstream
/// `is_visited` on the project).
fn is_visited_in_project(proj : @project.Project, x : @primus.Name) -> Bool {
  match x {
    Addr(_) | Symbol(_) => false
    Tid(t) =>
      match proj.program().subs().search_by(s => s.tid() == t) {
        None => true
        Some(i) =>
          match proj.program().subs()[i].blks() {
            [] => true
            [blk, ..] => blk.is_visited()
          }
      }
  }
}

///|
fn enqueue_separate_jobs(
  need_repeat : Bool,
  params : Params,
  sys : @primus.System,
  xs : Array[@primus.Name],
) -> Unit {
  for p in xs {
    @primus.Jobs::enqueue(
      sys,
      args=params.argv,
      envp=params.envp,
      name=p.to_string(),
      start=m => {
        if need_repeat || !is_visited_in_project(m.project(), p) {
          m.push_handler((_, exn) => {
            reporter.info(message="execution from \{p} terminated with: \{exn}")
          })
          @primus.Linker::schedule_exec(m, p)
        }
      },
    )
  }
}

///|
fn on_success(
  job : @primus.Job,
  status : @primus.ExitStatus,
  _result : @primus.JobsResult,
) -> @primus.JobAction {
  match status {
    Normal | Exn(@primus.Halt) =>
      reporter.info(message="The job `\{job.name}' finished successfully")
    Exn(e) =>
      reporter.error(
        message="The job `\{job.name}' finished abnormally with an exception:\n\{e}",
      )
  }
  Continue
}

///|
fn on_failure(
  job : @primus.Job,
  conflict : Error,
  _result : @primus.JobsResult,
) -> @primus.JobAction {
  reporter.error(
    message="The job `\{job.name}' failed: \{@bap_main.error_to_string(conflict)}",
  )
  Continue
}

///|
fn find_first_unvisited_sub(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Sub]? {
  prog
  .subs()
  .iter()
  .find_first(sub => {
    match sub.blks() {
      [] => false
      [blk, ..] => !blk.is_visited()
    }
  })
}

///|
fn find_first_unvisited_blk(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Blk]? {
  for sub in prog.subs() {
    for blk in sub.blks() {
      if !blk.is_visited() {
        return Some(blk)
      }
    }
  }
  None
}

///|
/// The Primus systems with the given names.
fn find_systems(names : Array[String]) -> Array[@primus.System] raise {
  let out = []
  for sys in names {
    match @primus.System::find(@knowledge.Name::read(sys)) {
      None => raise InvalidArgument("Unknown system: \{sys}")
      Some(s) => {
        // a system with unresolved components can not be started: report
        // it instead of silently failing every job
        s.validate() catch {
          e => raise InvalidArgument("Invalid system \{sys}: \{e}")
        }
        out.push(s)
      }
    }
  }
  out
}

///|
/// Runs the Primus jobs over the project (the body of the `run` pass,
/// upstream `main`).
pub fn run(params : Params, proj : @project.Project) -> @project.Project raise {
  let enqueue = if params.in_isolation {
    enqueue_separate_jobs
  } else {
    enqueue_super_job
  }
  let inputs = parse_entry_points(proj, params.entry)
  let systems = find_systems(params.systems)
  for sys in systems {
    enqueue(params.with_repetitions, params, sys, inputs)
  }
  reporter.report_progress(total=@primus.Jobs::pending())
  let enqueue_term = (tid : @types.Tid) => {
    let p = @primus.Name::Tid(tid)
    for sys in systems {
      @primus.Jobs::enqueue(
        sys,
        args=params.argv,
        envp=params.envp,
        name=p.to_string(),
        start=m => @primus.Linker::schedule_exec(m, p),
      )
    }
  }
  for proj = proj {
    let result = @primus.Jobs::run(on_failure~, on_success~, proj)
    let proj = result.project
    if !params.until_visited {
      break proj
    }
    let prog = proj.program()
    match find_first_unvisited_sub(prog) {
      Some(sub) => {
        enqueue_term(sub.tid())
        continue proj
      }
      None =>
        match find_first_unvisited_blk(prog) {
          Some(blk) => {
            enqueue_term(blk.tid())
            continue proj
          }
          None => break proj
        }
    }
  }
}

///|
/// The dependencies of the pass.
pub let deps : Array[String] = ["trivial-condition-form"]

///|
let visited_registered : Ref[Bool] = Ref(false)

///|
let current_params : Ref[Params] = Ref(Params::new())

///|
/// Registers the `run` pass with the parameters and the `run:records-visited`
/// component (upstream `Config.declare_extension`). Returns `false` if the
/// pass is already registered.
pub fn register(params : Params) -> Result[Bool, String] {
  register_error_printer()
  if !visited_registered.val {
    visited_registered.val = true
    @primus.Machine::add_component(m => record_visited(m))
    @primus.Components::register_generic(
      "records-visited",
      m => record_visited(m),
      internal=true,
      pkg="run",
    ) catch {
      _ => ()
    }
  }
  // the pass reads the parameters of the latest registration
  current_params.val = params
  @project.register_pass_if_absent(
    @project.ProjectPass::create(name~, deps~, run=proj => {
      try run(current_params.val, proj) catch {
        e => Err(@bap_main.error_to_string(e))
      } noraise {
        proj => Ok(proj)
      }
    }),
  )
}
