///|
struct ProjectBrancher {
  path_value : String?
  biased_value : Bool
  resolve_fn : (@memory.Memory) -> Array[ProjectDisassemblyEdge]
}

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
    known_edges.filter(edge => edge.source() == block.min_addr())
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
pub fn Project::apply_brancher(
  self : Project,
  brancher? : ProjectBrancher,
) -> Result[Project, String] {
  let blocks = self.disassembly().blocks()
  if blocks.is_empty() {
    return Err("project has no disassembly blocks to branch")
  }
  let selected = match brancher {
    Some(value) => value
    None => ProjectBrancher::empty()
  }
  let mut state = self.disassembly()
  for block in blocks {
    for edge in selected.resolve(block) {
      state = state.add_edge(edge)
    }
  }
  Ok(self.with_disassembly(state))
}
