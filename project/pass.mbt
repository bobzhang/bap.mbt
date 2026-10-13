///|
struct ProjectPass {
  name_value : String
  autorun_flag : Bool
  run_once_flag : Bool
  deps_value : Array[String]
  run_fn : (Project) -> Result[Project, String]
  starts_pair : (@future.Stream[Double], @future.Signal[Double])
  successes_pair : (@future.Stream[Double], @future.Signal[Double])
  failures_pair : (@future.Stream[Double], @future.Signal[Double])
  finishes_pair : (@future.Stream[Double], @future.Signal[Double])
}

///|
pub(all) suberror ProjectPassError {
  ProjectPassFailure(String)
} derive(Eq, Debug)

///|
pub extend ProjectPassError with Eq::{not_equal, equal}

///|
pub extend ProjectPassError with Debug::{to_repr}

///|
pub(all) enum ProjectPassRunError {
  ProjectPassUnsatDep(ProjectPass, String)
  ProjectPassRuntimeError(ProjectPass, String)
}

///|
pub(all) enum ProjectPassEventKind {
  PassRegistered
  PassStarted
  PassSucceeded
  PassFailed
  PassFinished
} derive(Eq)

///|
pub extend ProjectPassEventKind with Eq::{not_equal, equal}

///|
struct ProjectPassEvent {
  pass_name_value : String
  kind_value : ProjectPassEventKind
  sequence_value : Int32
}

///|
let pass_registry : Map[String, ProjectPass] = Map([])

///|
let pass_registry_order : Array[String] = []

///|
let pass_event_log : Array[ProjectPassEvent] = []

///|
let pass_event_sequence : Ref[Int32] = Ref(0)

///|
let pass_registration_pair : (
  @future.Stream[ProjectPass],
  @future.Signal[ProjectPass],
) = @future.Stream::create()

///|
fn record_pass_event(
  name : String,
  kind : ProjectPassEventKind,
) -> ProjectPassEvent {
  pass_event_sequence.val += 1
  let event = {
    pass_name_value: name,
    kind_value: kind,
    sequence_value: pass_event_sequence.val,
  }
  pass_event_log.push(event)
  event
}

///|
fn pass_events_of_kind(kind : ProjectPassEventKind) -> Array[ProjectPassEvent] {
  pass_event_log.filter(event => event.kind() == kind)
}

///|
fn pass_events_for(
  name : String,
  kind : ProjectPassEventKind,
) -> Array[ProjectPassEvent] {
  pass_event_log.filter(event => {
    event.pass_name() == name && event.kind() == kind
  })
}

///|
fn project_pass_failure(reason : String) -> ProjectPassError {
  ProjectPassFailure(reason)
}

///|
pub fn ProjectPassRunError::pass(self : ProjectPassRunError) -> ProjectPass {
  match self {
    ProjectPassUnsatDep(pass, _) => pass
    ProjectPassRuntimeError(pass, _) => pass
  }
}

///|
pub fn ProjectPassRunError::dependency(self : ProjectPassRunError) -> String? {
  match self {
    ProjectPassUnsatDep(_, dependency) => Some(dependency)
    ProjectPassRuntimeError(_, _) => None
  }
}

///|
pub fn ProjectPassRunError::reason(self : ProjectPassRunError) -> String {
  match self {
    ProjectPassUnsatDep(_, dependency) => dependency
    ProjectPassRuntimeError(_, reason) => reason
  }
}

///|
pub fn ProjectPassRunError::to_string(self : ProjectPassRunError) -> String {
  match self {
    ProjectPassUnsatDep(pass, dependency) =>
      "unsatisfied dependency \{dependency} for project pass \{pass.name()}"
    ProjectPassRuntimeError(pass, reason) =>
      "runtime error in project pass \{pass.name()}: \{reason}"
  }
}

///|
pub fn ProjectPassEventKind::to_string(self : ProjectPassEventKind) -> String {
  match self {
    PassRegistered => "registered"
    PassStarted => "started"
    PassSucceeded => "succeeded"
    PassFailed => "failed"
    PassFinished => "finished"
  }
}

///|
pub fn ProjectPassEvent::pass_name(self : ProjectPassEvent) -> String {
  self.pass_name_value
}

///|
pub fn ProjectPassEvent::kind(self : ProjectPassEvent) -> ProjectPassEventKind {
  self.kind_value
}

///|
pub fn ProjectPassEvent::sequence(self : ProjectPassEvent) -> Int32 {
  self.sequence_value
}

///|
pub fn pass_events() -> Array[ProjectPassEvent] {
  pass_event_log.copy()
}

///|
pub fn pass_registration_events() -> Array[ProjectPassEvent] {
  pass_events_of_kind(PassRegistered)
}

///|
pub fn pass_registrations() -> @future.Stream[ProjectPass] {
  pass_registration_pair.0
}

///|
pub fn ProjectPass::create(
  name~ : String,
  autorun? : Bool,
  run_once? : Bool,
  deps? : Array[String],
  run~ : (Project) -> Result[Project, String],
) -> ProjectPass {
  let autorun_flag = match autorun {
    Some(flag) => flag
    None => false
  }
  let starts_pair = @future.Stream::create()
  let successes_pair = @future.Stream::create()
  let failures_pair = @future.Stream::create()
  let finishes_pair = @future.Stream::create()
  {
    name_value: name,
    autorun_flag,
    run_once_flag: match run_once {
      Some(flag) => flag
      None => autorun_flag
    },
    deps_value: match deps {
      Some(items) => items.copy()
      None => []
    },
    run_fn: run,
    starts_pair,
    successes_pair,
    failures_pair,
    finishes_pair,
  }
}

///|
pub fn ProjectPass::name(self : ProjectPass) -> String {
  self.name_value
}

///|
pub fn ProjectPass::autorun(self : ProjectPass) -> Bool {
  self.autorun_flag
}

///|
pub fn ProjectPass::run_once(self : ProjectPass) -> Bool {
  self.run_once_flag
}

///|
pub fn ProjectPass::deps(self : ProjectPass) -> Array[String] {
  self.deps_value.copy()
}

///|
fn ProjectPass::run_body(
  self : ProjectPass,
  project : Project,
) -> Result[Project, String] {
  (self.run_fn)(project)
}

///|
fn ProjectPass::record_lifecycle_event(
  self : ProjectPass,
  kind : ProjectPassEventKind,
) -> Unit {
  let event = record_pass_event(self.name(), kind)
  let stamp = event.sequence().to_double()
  match kind {
    PassStarted => self.starts_pair.1.send(stamp)
    PassSucceeded => self.successes_pair.1.send(stamp)
    PassFailed => self.failures_pair.1.send(stamp)
    PassFinished => self.finishes_pair.1.send(stamp)
    PassRegistered => ()
  }
}

///|
pub fn ProjectPass::events(self : ProjectPass) -> Array[ProjectPassEvent] {
  pass_event_log.filter(event => event.pass_name() == self.name())
}

///|
pub fn ProjectPass::start_events(self : ProjectPass) -> Array[ProjectPassEvent] {
  pass_events_for(self.name(), PassStarted)
}

///|
pub fn ProjectPass::success_events(
  self : ProjectPass,
) -> Array[ProjectPassEvent] {
  pass_events_for(self.name(), PassSucceeded)
}

///|
pub fn ProjectPass::failure_events(
  self : ProjectPass,
) -> Array[ProjectPassEvent] {
  pass_events_for(self.name(), PassFailed)
}

///|
pub fn ProjectPass::finish_events(
  self : ProjectPass,
) -> Array[ProjectPassEvent] {
  pass_events_for(self.name(), PassFinished)
}

///|
pub fn ProjectPass::starts(self : ProjectPass) -> @future.Stream[Double] {
  self.starts_pair.0
}

///|
pub fn ProjectPass::successes(self : ProjectPass) -> @future.Stream[Double] {
  self.successes_pair.0
}

///|
pub fn ProjectPass::failures(self : ProjectPass) -> @future.Stream[Double] {
  self.failures_pair.0
}

///|
pub fn ProjectPass::finishes(self : ProjectPass) -> @future.Stream[Double] {
  self.finishes_pair.0
}

///|
fn pass_run_key(name : String) -> String {
  "pass.\{name}.runs"
}

///|
pub fn Project::pass_run_count(self : Project, name : String) -> Int32 {
  match self.get(pass_run_key(name)) {
    Some(value) =>
      try @string.parse_int(value) catch {
        _ => 0
      } noraise {
        count => count
      }
    None => 0
  }
}

///|
pub fn Project::pass_has_run(self : Project, name : String) -> Bool {
  self.pass_run_count(name) > 0
}

///|
fn Project::mark_pass_run(self : Project, name : String) -> Project {
  self.set(pass_run_key(name), (self.pass_run_count(name) + 1).to_string())
}

///|
pub fn register_pass(pass : ProjectPass) -> Result[Unit, String] {
  let name = pass.name()
  if pass_registry.contains(name) {
    Err("project pass \{name} is already registered")
  } else {
    pass_registry[name] = pass
    pass_registry_order.push(name)
    ignore(record_pass_event(name, PassRegistered))
    pass_registration_pair.1.send(pass)
    Ok(())
  }
}

///|
pub fn register_pass_transform(
  name~ : String,
  autorun? : Bool,
  run_once? : Bool,
  deps? : Array[String],
  run~ : (Project) -> Result[Project, String],
) -> Result[Unit, String] {
  register_pass(ProjectPass::create(name~, autorun?, run_once?, deps?, run~))
}

///|
pub fn register_pass_prime(
  name~ : String,
  autorun? : Bool,
  run_once? : Bool,
  deps? : Array[String],
  run~ : (Project) -> Result[Unit, String],
) -> Result[Unit, String] {
  register_pass(
    ProjectPass::create(name~, autorun?, run_once?, deps?, run=project => {
      match run(project) {
        Ok(_) => Ok(project)
        Err(reason) => Err(reason)
      }
    }),
  )
}

///|
pub fn register_pass_if_absent(pass : ProjectPass) -> Result[Bool, String] {
  if pass_registry.contains(pass.name()) {
    Ok(false)
  } else {
    match register_pass(pass) {
      Ok(_) => Ok(true)
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn find_pass(name : String) -> ProjectPass? {
  pass_registry.get(name)
}

///|
pub fn passes() -> Array[ProjectPass] {
  let result = []
  for name in pass_registry_order {
    match pass_registry.get(name) {
      Some(pass) => result.push(pass)
      None => ()
    }
  }
  result
}

///|
fn resolve_pass(
  name : String,
  visiting : Array[String],
  visited : Array[String],
  order : Array[ProjectPass],
) -> Result[Unit, String] {
  match find_pass(name) {
    None => Err("unknown project pass \{name}")
    Some(pass) => resolve_pass_object(pass, visiting, visited, order)
  }
}

///|
fn resolve_pass_object(
  pass : ProjectPass,
  visiting : Array[String],
  visited : Array[String],
  order : Array[ProjectPass],
) -> Result[Unit, String] {
  let name = pass.name()
  if visited.contains(name) {
    Ok(())
  } else if visiting.contains(name) {
    Err("cyclic project pass dependency at \{name}")
  } else {
    visiting.push(name)
    for dep in pass.deps() {
      match resolve_pass(dep, visiting, visited, order) {
        Ok(_) => ()
        Err(reason) => {
          ignore(visiting.pop())
          return Err(reason)
        }
      }
    }
    ignore(visiting.pop())
    visited.push(name)
    order.push(pass)
    Ok(())
  }
}

///|
pub fn resolve_passes(
  names : Array[String],
) -> Result[Array[ProjectPass], String] {
  let visiting = []
  let visited = []
  let order = []
  for name in names {
    match resolve_pass(name, visiting, visited, order) {
      Ok(_) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok(order)
}

///|
fn resolve_pass_for_run(
  owner : ProjectPass,
  name : String,
  visiting : Array[String],
  visited : Array[String],
  order : Array[ProjectPass],
) -> Result[Unit, ProjectPassRunError] {
  match find_pass(name) {
    Some(pass) => resolve_pass_object_for_run(pass, visiting, visited, order)
    None => Err(ProjectPassUnsatDep(owner, name))
  }
}

///|
fn resolve_pass_object_for_run(
  pass : ProjectPass,
  visiting : Array[String],
  visited : Array[String],
  order : Array[ProjectPass],
) -> Result[Unit, ProjectPassRunError] {
  let name = pass.name()
  if visited.contains(name) {
    Ok(())
  } else if visiting.contains(name) {
    Err(
      ProjectPassRuntimeError(pass, "cyclic project pass dependency at \{name}"),
    )
  } else {
    visiting.push(name)
    for dep in pass.deps() {
      match resolve_pass_for_run(pass, dep, visiting, visited, order) {
        Ok(_) => ()
        Err(error) => {
          ignore(visiting.pop())
          return Err(error)
        }
      }
    }
    ignore(visiting.pop())
    visited.push(name)
    order.push(pass)
    Ok(())
  }
}

///|
fn Project::run_resolved_passes_for_run(
  self : Project,
  order : Array[ProjectPass],
) -> Result[Project, ProjectPassRunError] {
  let mut project = self
  for pass in order {
    let name = pass.name()
    if pass.run_once() && project.pass_has_run(name) {
      ()
    } else {
      pass.record_lifecycle_event(PassStarted)
      match pass.run_body(project) {
        Ok(next) => {
          pass.record_lifecycle_event(PassSucceeded)
          pass.record_lifecycle_event(PassFinished)
          project = next.mark_pass_run(name)
        }
        Err(reason) => {
          pass.record_lifecycle_event(PassFailed)
          pass.record_lifecycle_event(PassFinished)
          return Err(ProjectPassRuntimeError(pass, reason))
        }
      }
    }
  }
  Ok(project)
}

///|
fn Project::run_resolved_passes(
  self : Project,
  order : Array[ProjectPass],
) -> Result[Project, String] {
  let mut project = self
  for pass in order {
    let name = pass.name()
    if pass.run_once() && project.pass_has_run(name) {
      ()
    } else {
      pass.record_lifecycle_event(PassStarted)
      match pass.run_body(project) {
        Ok(next) => {
          pass.record_lifecycle_event(PassSucceeded)
          pass.record_lifecycle_event(PassFinished)
          project = next.mark_pass_run(name)
        }
        Err(reason) => {
          pass.record_lifecycle_event(PassFailed)
          pass.record_lifecycle_event(PassFinished)
          return Err(reason)
        }
      }
    }
  }
  Ok(project)
}

///|
pub fn ProjectPass::run(
  self : ProjectPass,
  project : Project,
) -> Result[Project, ProjectPassRunError] {
  let visiting = []
  let visited = []
  let order = []
  match resolve_pass_object_for_run(self, visiting, visited, order) {
    Ok(_) => project.run_resolved_passes_for_run(order)
    Err(error) => Err(error)
  }
}

///|
pub fn ProjectPass::run_exn(
  self : ProjectPass,
  project : Project,
) -> Project raise ProjectPassError {
  match self.run(project) {
    Ok(result) => result
    Err(error) => raise project_pass_failure(error.to_string())
  }
}

///|
pub fn Project::run_passes(
  self : Project,
  names : Array[String],
) -> Result[Project, String] {
  match resolve_passes(names) {
    Ok(order) => self.run_resolved_passes(order)
    Err(reason) => Err(reason)
  }
}

///|
pub fn Project::run_pass(
  self : Project,
  name : String,
) -> Result[Project, String] {
  self.run_passes([name])
}

///|
pub fn Project::run_autorun_passes(self : Project) -> Result[Project, String] {
  let names = []
  for pass in passes() {
    if pass.autorun() {
      names.push(pass.name())
    }
  }
  self.run_passes(names)
}
