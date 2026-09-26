///|
struct ProjectBrancher {
  path_value : String?
  biased_value : Bool
  /// the destinations of the instruction occupying the memory (the
  /// instruction is `None` when the brancher is applied to memory only, see
  /// `ProjectBrancher::resolve`)
  resolve_fn : (@memory.Memory, ProjectDisassemblyInstruction?) -> Array[
    ProjectDisassemblyEdge,
  ]
}

///|
let project_brancher_registry : Map[String, ProjectBrancher] = Map([])

///|
fn project_brancher_applies_to_project(
  brancher : ProjectBrancher,
  project : Project,
) -> Bool {
  match brancher.path() {
    Some(path) => project.filename() == Some(path)
    None => true
  }
}

///|
fn project_brancher_addr_word(addr : UInt64) -> Result[@types.Word, String] {
  try @types.Word::of_uint64(width=64, addr) catch {
    _ => Err("project brancher address conversion failed")
  } noraise {
    word => Ok(word)
  }
}

///|
fn project_brancher_bias_word(bias : Int64) -> Result[@types.Word, String] {
  try @types.Word::of_int64(bias, width=64) catch {
    _ => Err("project brancher bias conversion failed")
  } noraise {
    word => Ok(word)
  }
}

///|
fn project_brancher_word_to_uint64(
  word : @types.Word,
) -> Result[UInt64, String] {
  try word.to_uint64() catch {
    _ => Err("project brancher address conversion failed")
  } noraise {
    addr => Ok(addr)
  }
}

///|
fn project_brancher_translate_addr(
  addr : UInt64,
  bias : Int64,
  to_biased~ : Bool,
) -> Result[UInt64, String] {
  let address = match project_brancher_addr_word(addr) {
    Ok(word) => word
    Err(reason) => return Err(reason)
  }
  let offset = match project_brancher_bias_word(bias) {
    Ok(word) => word
    Err(reason) => return Err(reason)
  }
  let translated = if to_biased {
    try address.add(offset) catch {
      _ => return Err("project brancher address/bias width mismatch")
    } noraise {
      word => word
    }
  } else {
    try address.sub(offset) catch {
      _ => return Err("project brancher address/bias width mismatch")
    } noraise {
      word => word
    }
  }
  project_brancher_word_to_uint64(translated)
}

///|
fn project_brancher_translate_memory(
  memory : @memory.Memory,
  bias : Int64,
) -> Result[@memory.Memory, String] {
  match
    project_brancher_translate_addr(memory.min_addr(), bias, to_biased=false) {
    Ok(start) => Ok(memory.rebase(start))
    Err(reason) => Err(reason)
  }
}

///|
fn project_brancher_translate_edge(
  edge : ProjectDisassemblyEdge,
  bias : Int64,
) -> Result[ProjectDisassemblyEdge, String] {
  let source = match
    project_brancher_translate_addr(edge.source(), bias, to_biased=true) {
    Ok(addr) => addr
    Err(reason) => return Err(reason)
  }
  let target = match edge.target() {
    Some(addr) =>
      match project_brancher_translate_addr(addr, bias, to_biased=true) {
        Ok(value) => Some(value)
        Err(reason) => return Err(reason)
      }
    None => None
  }
  Ok(ProjectDisassemblyEdge::create(source~, target?, kind=edge.kind()))
}

///|
pub fn ProjectBrancher::create(
  resolve : (@memory.Memory) -> Array[ProjectDisassemblyEdge],
) -> ProjectBrancher {
  {
    path_value: None,
    biased_value: false,
    resolve_fn: (mem, _) => resolve(mem),
  }
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
  { ..self, path_value: Some(path), }
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
  { ..self, biased_value: biased, }
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
  (self.resolve_fn)(block, None)
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
  if !project_brancher_applies_to_project(selected, self) {
    return Ok(self)
  }
  let bias = if selected.is_biased() { None } else { self.load_bias() }
  let mut state = self.disassembly()
  for memory in subjects {
    let query_memory = match bias {
      Some(value) =>
        match project_brancher_translate_memory(memory, value) {
          Ok(rebased) => rebased
          Err(reason) => return Err(reason)
        }
      None => memory
    }
    for edge in selected.resolve(query_memory) {
      let stored_edge = match bias {
        Some(value) =>
          match project_brancher_translate_edge(edge, value) {
            Ok(translated) => translated
            Err(reason) => return Err(reason)
          }
        None => edge
      }
      state = state.add_edge(stored_edge)
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
