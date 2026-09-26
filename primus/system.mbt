///|
/// Errors of the system layer (systems, components and jobs).
pub(all) suberror SystemError {
  /// No system with this name is registered.
  UnknownSystem(String)
  /// A component required by the system is not registered.
  UnknownComponent(component~ : String, system~ : String)
  /// A system with the same name is already registered.
  DuplicateSystem(String)
  /// A component with the same name is already registered.
  DuplicateComponent(String)
  /// A system description could not be parsed.
  SystemParseError(file~ : String, system~ : String, msg~ : String)
} derive(Debug)

///|
/// A Primus system: a named set of components, possibly depending on other
/// systems (upstream `Primus.System.t`).
pub struct System {
  priv name : @knowledge.Name
  priv desc : String
  priv depends_on : Array[@knowledge.Name]
  priv components : Array[@knowledge.Name]
}

///|
/// Names a component in a system specification (`System.component`).
pub fn System::component(
  name : String,
  pkg? : String = "user",
) -> @knowledge.Name {
  @knowledge.Name::create(name, pkg~)
}

///|
/// Names a system dependency in a system specification
/// (`System.depends_on`).
pub fn System::depends_on(
  name : String,
  pkg? : String = "user",
) -> @knowledge.Name {
  @knowledge.Name::create(name, pkg~)
}

///|
/// Defines a system (`System.define`).
pub fn System::define_(
  desc? : String = "",
  depends_on? : Array[@knowledge.Name] = [],
  components? : Array[@knowledge.Name] = [],
  pkg? : String = "user",
  name : String,
) -> System {
  { name: @knowledge.Name::create(name, pkg~), desc, depends_on, components, }
}

///|
pub fn System::name(self : System) -> @knowledge.Name {
  self.name
}

///|
pub fn System::desc(self : System) -> String {
  self.desc
}

///|
/// The components listed directly in the system.
pub fn System::components(self : System) -> Array[@knowledge.Name] {
  self.components
}

///|
/// The systems this system depends on.
pub fn System::dependencies(self : System) -> Array[@knowledge.Name] {
  self.depends_on
}

///|
/// Adds a component to the system (`System.add_component`).
pub fn System::add_component(
  self : System,
  pkg? : String = "user",
  name : String,
) -> System {
  {
    ..self,
    components: [@knowledge.Name::create(name, pkg~), ..self.components],
  }
}

///|
/// Adds a dependency to the system (`System.add_dependency`).
pub fn System::add_dependency(
  self : System,
  pkg? : String = "user",
  name : String,
) -> System {
  {
    ..self,
    depends_on: [@knowledge.Name::create(name, pkg~), ..self.depends_on],
  }
}

///|
/// Renders the system in the `defsystem` syntax (`System.pp`).
pub fn System::to_string(self : System) -> String {
  let names = (xs : Array[@knowledge.Name]) => xs.map(x => x.show()).join(" ")
  (
    $|(defsystem \{self.name.show()}
    $|  :description "\{self.desc}"
    $|  :depends-on (\{names(self.depends_on)})
    $|  :components (\{names(self.components)}))
  )
}

///|
let systems : Map[String, System] = Map([])

///|
/// Registers a system (`System.Repository.add`).
pub fn System::register(sys : System) -> Unit raise SystemError {
  let key = sys.name.show()
  if systems.contains(key) {
    raise DuplicateSystem(key)
  }
  systems[key] = sys
}

///|
/// Finds a registered system (`System.Repository.find`).
pub fn System::find(name : @knowledge.Name) -> System? {
  systems.get(name.show())
}

///|
/// Finds a registered system by name (`System.Repository.get`); unqualified
/// names are looked up in the `pkg` package.
pub fn System::get(
  name : String,
  pkg? : String = "user",
) -> System raise SystemError {
  let n = @knowledge.Name::read(name, pkg~)
  match systems.get(n.show()) {
    Some(s) => s
    None => raise UnknownSystem(n.show())
  }
}

///|
/// Updates a registered system (`System.Repository.update`).
pub fn System::update(
  name : String,
  pkg? : String = "user",
  f : (System) -> System,
) -> Unit raise SystemError {
  let sys = System::get(name, pkg~)
  systems[sys.name.show()] = f(sys)
}

///|
/// Documentation of all registered systems (`System.Repository.list`).
pub fn System::list() -> Array[Info] {
  systems.values().map(s => Info::create(s.name, desc=s.desc)).collect()
}

///|
/// All components of the system, including those of its (transitive)
/// dependencies, sorted by name.
pub fn System::all_components(
  self : System,
) -> Array[@knowledge.Name] raise SystemError {
  let seen : Map[String, @knowledge.Name] = Map([])
  let visited : Map[String, Unit] = Map([])
  fn go(sys : System) -> Unit raise SystemError {
    if visited.contains(sys.name.show()) {
      return
    }
    visited[sys.name.show()] = ()
    for c in sys.components {
      seen[c.show()] = c
    }
    for d in sys.depends_on {
      match systems.get(d.show()) {
        Some(s) => go(s)
        None => raise UnknownSystem(d.show())
      }
    }
  }

  go(self)
  let out = seen.values().collect()
  out.sort_by((a, b) => a.show().compare(b.show()))
  out
}

// ---------------------------------------------------------------------------
// Components

///|
priv struct ComponentItem {
  init : (Machine) -> Unit raise
  desc : String
  hide : Bool
}

///|
let generic_components : Map[String, ComponentItem] = Map([])

///|
let analysis_components : Map[String, ComponentItem] = Map([])

///|
/// A registry of machine components (upstream `Primus.Components`).
///
/// Upstream distinguishes *generic* components (functors applicable to any
/// machine) from *specialized* analyses (bound to the Knowledge-based
/// machine). In MoonBit there is a single `Machine` type, so both are plain
/// initialization functions `(Machine) -> Unit raise` that typically
/// subscribe to observations; the distinction is kept only for listing and
/// initialization order (analyses first).
#warnings("-struct_never_constructed")
pub struct Components {}

///|
fn add_component(
  table : Map[String, ComponentItem],
  internal : Bool,
  desc : String,
  pkg : String,
  name : String,
  init : (Machine) -> Unit raise,
) -> Unit raise SystemError {
  let key = @knowledge.Name::create(name, pkg~).show()
  if table.contains(key) {
    raise DuplicateComponent(key)
  }
  table[key] = { init, desc, hide: internal, }
}

///|
/// Registers a generic component (`Components.register_generic`).
pub fn Components::register_generic(
  internal? : Bool = false,
  desc? : String = "",
  pkg? : String = "user",
  name : String,
  init : (Machine) -> Unit raise,
) -> Unit raise SystemError {
  add_component(generic_components, internal, desc, pkg, name, init)
}

///|
/// Registers a specialized analysis component (`Components.register`).
pub fn Components::register(
  internal? : Bool = false,
  desc? : String = "",
  pkg? : String = "user",
  name : String,
  init : (Machine) -> Unit raise,
) -> Unit raise SystemError {
  add_component(analysis_components, internal, desc, pkg, name, init)
}

///|
/// Documentation of all visible components (`Components.list`).
pub fn Components::list() -> Array[Info] {
  let out = []
  for k, item in analysis_components {
    if !item.hide {
      out.push(
        Info::create(
          @knowledge.Name::of_string(k),
          desc="[analysis]\n\{item.desc}",
        ),
      )
    }
  }
  for k, item in generic_components {
    if !item.hide {
      out.push(
        Info::create(
          @knowledge.Name::of_string(k),
          desc="[generic]\n\{item.desc}",
        ),
      )
    }
  }
  out
}

///|
let current_system : State[System?] = State::declare_(
  uuid="6b0d3c52-0e5f-4a1e-9a3f-5c1b7f0c2d11",
  name="current-system",
  _ => None,
)

///|
/// The system run by the machine, if it was started with `System::run`.
/// Components (e.g. a Primus Lisp loader) can use it to learn the system
/// name and its components (upstream uses them to refine the Lisp context).
pub fn System::current(m : Machine) -> System? {
  m.get_global(current_system)
}

///|
/// Resolves the initialization functions of all components of the system,
/// analyses first (upstream `init_system`).
fn System::component_inits(
  self : System,
) -> Array[(Machine) -> Unit raise] raise SystemError {
  let comps = self.all_components()
  let inits = []
  let loaded : Map[String, Unit] = Map([])
  for c in comps {
    if analysis_components.get(c.show()) is Some(item) {
      inits.push(item.init)
      loaded[c.show()] = ()
    }
  }
  for c in comps {
    if loaded.contains(c.show()) {
      continue
    }
    match generic_components.get(c.show()) {
      Some(item) => inits.push(item.init)
      None =>
        raise UnknownComponent(component=c.show(), system=self.name.show())
    }
  }
  inits
}

///|
/// Runs the system (`System.run`, `System.Generic(M).run`): the components
/// are initialized during `boot`, then `init` runs followed by the
/// `system_init` observation, `start` is the user code, and `fini` is
/// followed by the `system_fini` observation.
///
/// Raises `SystemError` if the system refers to unknown systems or
/// components; machine exceptions are reported in the exit status.
pub fn System::run(
  self : System,
  proj : @project.Project,
  envp? : Array[String] = [],
  args? : Array[String] = [],
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  start? : (Machine) -> Unit raise = _ => (),
) -> (ExitStatus, @project.Project) raise SystemError {
  let inits = self.component_inits()
  let sys = self
  Machine::run(
    proj,
    system=self.name.show(),
    envp~,
    args~,
    boot=m => {
      m.put_global(current_system, Some(sys))
      for f in inits {
        f(m)
      }
    },
    init=m => {
      init(m)
      m.make(inited_stmt, ())
    },
    fini=m => {
      fini(m)
      m.make(finish_stmt, ())
    },
    start~,
  )
}

// ---------------------------------------------------------------------------
// System description parser

///|
fn parse_names(
  sys : String,
  items : ArrayView[Sexp],
  what : String,
) -> Array[@knowledge.Name] raise SystemError {
  let out = []
  for item in items {
    match item {
      Atom(name) => out.push(@knowledge.Name::read(name, pkg="bap"))
      other =>
        raise SystemParseError(
          file="unknown",
          system=sys,
          msg="expects \{what} ::= <ident>, got \{other}",
        )
    }
  }
  out
}

///|
fn system_of_sexp(s : Sexp) -> System raise SystemError {
  guard s is List([Atom("defsystem"), Atom(name), .. items]) else {
    raise SystemParseError(
      file="unknown",
      system="unknown",
      msg="expected (defsystem <system-designator> <system-definition>) got \{s}",
    )
  }
  let mut sys : System = {
    name: @knowledge.Name::read(name, pkg="bap"),
    desc: "",
    depends_on: [],
    components: [],
  }
  let err = (msg : String) => {
    SystemParseError(file="unknown", system=name, msg~)
  }
  for i = 0; i < items.length(); {
    match items[i:] {
      [Atom(":description"), Atom(desc), ..] => {
        sys = { ..sys, desc, }
        continue i + 2
      }
      [Atom(":description"), ..] => raise err("expected :description <string>")
      [Atom(":components"), List(comps), ..] => {
        sys = {
          ..sys,
          components: [
            ..sys.components,
            ..parse_names(name, comps, "component"),
          ],
        }
        continue i + 2
      }
      [Atom(":components"), ..] =>
        raise err("expects a list of components (add parentheses)")
      [Atom(":depends-on"), List(deps), ..] => {
        sys = {
          ..sys,
          depends_on: [..sys.depends_on, ..parse_names(name, deps, "system")],
        }
        continue i + 2
      }
      [Atom(":depends-on"), ..] =>
        raise err("expects a list of systems (add parentheses)")
      [List(_) as l, ..] => raise err("expects an option name, got list \{l}")
      [other, ..] =>
        raise err(
          "expects option ::= :description | :components | :depends-on, got an unknown option \{other}",
        )
      [] => break
    }
  }
  sys
}

///|
/// Parses system descriptions written in the `defsystem` syntax
/// (upstream `System.from_file`, reading from a string). Unqualified names
/// are placed in the `bap` package, as upstream.
pub fn System::from_string(text : String) -> Array[System] raise SystemError {
  let sexps = Sexp::parse_many(text) catch {
    e =>
      raise SystemParseError(
        file="unknown",
        system="unknown",
        msg=e.to_string(),
      )
  }
  let out = []
  for s in sexps {
    out.push(system_of_sexp(s))
  }
  out
}

///|
/// Reads system descriptions from a file (`System.from_file`).
pub fn System::from_file(path : String) -> Array[System] raise SystemError {
  let bytes = match @native_io.read_file(path) {
    Ok(b) => b
    Err(msg) => raise SystemParseError(file=path, system="unknown", msg~)
  }
  let text = @utf8.decode(bytes) catch {
    _ =>
      raise SystemParseError(file=path, system="unknown", msg="invalid UTF-8")
  }
  System::from_string(text) catch {
    SystemParseError(system~, msg~, ..) =>
      raise SystemParseError(file=path, system~, msg~)
    e => raise e
  }
}

// ---------------------------------------------------------------------------
// Jobs

///|
/// A queued system run (upstream `Primus.Job.t`).
pub struct Job {
  name : String
  desc : String
  envp : Array[String]
  args : Array[String]
  priv init : (Machine) -> Unit raise
  priv fini : (Machine) -> Unit raise
  priv start : (Machine) -> Unit raise
  system : System
}

///|
/// What to do after a job finishes (upstream `Jobs.action`).
pub(all) enum JobAction {
  Stop
  Continue
} derive(Eq, Debug)

///|
/// The result of running the job queue (upstream `Jobs.result`).
pub struct JobsResult {
  project : @project.Project
  failures : Array[(Job, Error)]
  finished : Array[Job]
}

///|
/// The job queue (upstream `Primus.Jobs`).
#warnings("-struct_never_constructed")
pub struct Jobs {}

///|
let job_queue : Array[Job] = []

///|
/// Enqueues a job (`Jobs.enqueue`).
pub fn Jobs::enqueue(
  name? : String = "unnamed",
  desc? : String = "",
  envp? : Array[String] = [],
  args? : Array[String] = [],
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  start? : (Machine) -> Unit raise = _ => (),
  system : System,
) -> Unit {
  job_queue.push({ name, desc, envp, args, init, fini, start, system, })
}

///|
/// The number of pending jobs (`Jobs.pending`).
pub fn Jobs::pending() -> Int {
  job_queue.length()
}

///|
/// Runs all queued jobs in order, threading the project through them
/// (`Jobs.run`). A job fails if its system cannot be started; machine
/// exceptions are reported to `on_success` through the exit status.
pub fn Jobs::run(
  on_failure? : (Job, Error, JobsResult) -> JobAction = (_, _, _) => Continue,
  on_success? : (Job, ExitStatus, JobsResult) -> JobAction = (_, _, _) => {
    Continue
  },
  proj : @project.Project,
) -> JobsResult {
  let mut result : JobsResult = { project: proj, failures: [], finished: [], }
  while !job_queue.is_empty() {
    let job = job_queue.remove(0)
    let action = try
      job.system.run(
        result.project,
        envp=job.envp,
        args=job.args,
        init=job.init,
        fini=job.fini,
        start=job.start,
      )
    catch {
      e => {
        result = {
          ..result,
          finished: [..result.finished, job],
          failures: [..result.failures, (job, e)],
        }
        on_failure(job, e, result)
      }
    } noraise {
      (status, project) => {
        result = { ..result, project, finished: [..result.finished, job], }
        on_success(job, status, result)
      }
    }
    if action is Stop {
      break
    }
  }
  result
}
