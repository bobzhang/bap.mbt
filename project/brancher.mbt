///|
struct ProjectBrancher {
  path_value : String?
  biased_value : Bool
  resolve_fn : (@memory.Memory) -> Array[ProjectDisassemblyEdge]
}

///|
let project_brancher_registry : Map[String, ProjectBrancher] = {}

///|
pub fn ProjectBrancher::create(
  resolve : (@memory.Memory) -> Array[ProjectDisassemblyEdge],
) -> ProjectBrancher {
  { path_value: None, biased_value: false, resolve_fn: resolve }
}

///|
pub fn ProjectBrancher::empty() -> ProjectBrancher {
  ProjectBrancher::create(_ => [])
}

///|
pub fn ProjectBrancher::of_edges(
  edges : Array[ProjectDisassemblyEdge],
) -> ProjectBrancher {
  let known_edges = edges.copy()
  ProjectBrancher::create(block => {
    known_edges.filter(edge => block.contains(edge.source()))
  })
}

///|
pub fn ProjectBrancher::set_path(
  self : ProjectBrancher,
  path : String,
) -> ProjectBrancher {
  { ..self, path_value: Some(path) }
}

///|
pub fn ProjectBrancher::path(self : ProjectBrancher) -> String? {
  self.path_value
}

///|
pub fn ProjectBrancher::with_biased(
  self : ProjectBrancher,
  biased : Bool,
) -> ProjectBrancher {
  { ..self, biased_value: biased }
}

///|
pub fn ProjectBrancher::is_biased(self : ProjectBrancher) -> Bool {
  self.biased_value
}

///|
pub fn ProjectBrancher::resolve(
  self : ProjectBrancher,
  block : @memory.Memory,
) -> Array[ProjectDisassemblyEdge] {
  (self.resolve_fn)(block)
}

///|
pub fn register_brancher(
  name~ : String,
  brancher : ProjectBrancher,
) -> Result[Unit, String] {
  if project_brancher_registry.contains(name) {
    Err("project brancher \{name} is already registered")
  } else {
    project_brancher_registry[name] = brancher
    Ok(())
  }
}

///|
pub fn register_brancher_if_absent(
  name~ : String,
  brancher : ProjectBrancher,
) -> Result[Bool, String] {
  if project_brancher_registry.contains(name) {
    Ok(false)
  } else {
    match register_brancher(name~, brancher) {
      Ok(_) => Ok(true)
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn register_builtin_branchers() -> Result[Unit, String] {
  match register_brancher_if_absent(name="empty", ProjectBrancher::empty()) {
    Ok(_) => Ok(())
    Err(reason) => Err(reason)
  }
}

///|
pub fn find_brancher(name : String) -> ProjectBrancher? {
  project_brancher_registry.get(name)
}

///|
pub fn brancher_names() -> Array[String] {
  let names = []
  project_brancher_registry.each((name, _) => names.push(name))
  names.sort_by((left, right) => left.compare(right))
  names
}

///|
pub fn Project::apply_brancher(
  self : Project,
  brancher? : ProjectBrancher,
) -> Result[Project, String] {
  let blocks = self.disassembly().blocks()
  if blocks.is_empty() {
    return Err("project has no disassembly blocks to branch")
  }
  let instructions = self.disassembly().instructions()
  let subjects = if instructions.is_empty() {
    blocks
  } else {
    instructions.map(instruction => instruction.memory())
  }
  let selected = match brancher {
    Some(value) => value
    None => ProjectBrancher::empty()
  }
  let mut state = self.disassembly()
  for memory in subjects {
    for edge in selected.resolve(memory) {
      state = state.add_edge(edge)
    }
  }
  Ok(self.with_disassembly(state))
}

///|
pub fn Project::apply_brancher_named(
  self : Project,
  brancher~ : String,
) -> Result[Project, String] {
  match find_brancher(brancher) {
    Some(value) => self.apply_brancher(brancher=value)
    None => Err("unknown project brancher \{brancher}")
  }
}
