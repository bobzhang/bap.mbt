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
fn resolve_pass(
  name : String,
  visiting : Array[String],
  visited : Array[String],
  order : Array[ProjectPass],
) -> Result[Unit, String] {
  if visited.contains(name) {
    Ok(())
  } else if visiting.contains(name) {
    Err("cyclic project pass dependency at \{name}")
  } else {
    match find_pass(name) {
      None => Err("unknown project pass \{name}")
      Some(pass) => {
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
pub fn Project::run_passes(
  self : Project,
  names : Array[String],
) -> Result[Project, String] {
  match resolve_passes(names) {
    Ok(order) => {
      let mut project = self
      for pass in order {
        match pass.run(project) {
          Ok(next) => project = next
          Err(reason) => return Err(reason)
        }
      }
      Ok(project)
    }
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
