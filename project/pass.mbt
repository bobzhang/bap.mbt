///|
struct ProjectPass {
  name_value : String
  autorun_flag : Bool
  deps_value : Array[String]
  run_fn : (Project) -> Result[Project, String]
}

///|
let pass_registry : Map[String, ProjectPass] = {}

///|
pub fn ProjectPass::create(
  name~ : String,
  autorun? : Bool,
  deps? : Array[String],
  run~ : (Project) -> Result[Project, String],
) -> ProjectPass {
  {
    name_value: name,
    autorun_flag: match autorun {
      Some(flag) => flag
      None => false
    },
    deps_value: match deps {
      Some(items) => items.copy()
      None => []
    },
    run_fn: run,
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
pub fn ProjectPass::deps(self : ProjectPass) -> Array[String] {
  self.deps_value.copy()
}

///|
pub fn ProjectPass::run(
  self : ProjectPass,
  project : Project,
) -> Result[Project, String] {
  (self.run_fn)(project)
}

///|
pub fn register_pass(pass : ProjectPass) -> Result[Unit, String] {
  let name = pass.name()
  if pass_registry.contains(name) {
    Err("project pass \{name} is already registered")
  } else {
    pass_registry[name] = pass
    Ok(())
  }
}

///|
pub fn find_pass(name : String) -> ProjectPass? {
  pass_registry.get(name)
}

///|
pub fn passes() -> Array[ProjectPass] {
  let result = []
  pass_registry.each((_, pass) => result.push(pass))
  result
}

///|
pub fn Project::run_pass(
  self : Project,
  name : String,
) -> Result[Project, String] {
  match find_pass(name) {
    Some(pass) => pass.run(self)
    None => Err("unknown project pass \{name}")
  }
}

///|
pub fn Project::run_autorun_passes(self : Project) -> Result[Project, String] {
  let mut project = self
  for pass in passes() {
    if pass.autorun() {
      match pass.run(project) {
        Ok(next) => project = next
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(project)
}
