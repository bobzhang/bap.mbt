///|
pub(all) suberror ProjectDisasmError {
  ProjectDisasmFailure(String)
} derive(Eq, Debug)

///|
struct ProjectDisasm {
  project_value : Project
  errors_value : Array[ProjectDisassemblyRecError]
}

///|
fn project_disasm_state_of_cfg(
  cfg : ProjectDisassemblyCfg,
) -> ProjectDisassemblyState {
  let blocks : Array[@memory.Memory] = []
  let instructions : Array[ProjectDisassemblyInstruction] = []
  for node in cfg.nodes() {
    blocks.push(node.memory())
    for instruction in node.instructions() {
      instructions.push(instruction)
    }
  }
  ProjectDisassemblyState::create(
    blocks~,
    instructions~,
    edges=cfg.to_disassembly_edges(),
  )
}

///|
fn project_disasm_from_project_result(
  project : Result[Project, String],
  backend : String?,
  brancher : ProjectBrancher?,
) -> Result[ProjectDisasm, String] {
  match project {
    Ok(value) => ProjectDisasm::of_project(value, backend?, brancher?)
    Err(reason) => Err(reason)
  }
}

///|
fn project_disasm_merge_state(
  left : ProjectDisassemblyState,
  right : ProjectDisassemblyState,
) -> ProjectDisassemblyState {
  let blocks = left.blocks()
  for block in right.blocks() {
    blocks.push(block)
  }
  let instructions = left.instructions()
  for instruction in right.instructions() {
    instructions.push(instruction)
  }
  let edges = left.edges()
  for edge in right.edges() {
    edges.push(edge)
  }
  ProjectDisassemblyState::create(blocks~, instructions~, edges~)
}

///|
fn project_disasm_symbols_of_roots(
  roots : Array[UInt64],
) -> Array[@image.Symbol] {
  let symbols : Array[@image.Symbol] = []
  for root in roots {
    symbols.push(
      @image.Symbol::create(
        name="sub_" + root.to_string(radix=16),
        addr=root,
        is_function=true,
      ),
    )
  }
  symbols
}

///|
fn project_disasm_failure(reason : String) -> ProjectDisasmError {
  ProjectDisasmFailure(reason)
}

///|
pub fn ProjectDisasm::create(cfg : ProjectDisassemblyCfg) -> ProjectDisasm {
  ProjectDisasm::from_project(
    Project::empty(@core_theory.Target::unknown()).with_disassembly(
      project_disasm_state_of_cfg(cfg),
    ),
  )
}

///|
pub fn ProjectDisasm::from_project(
  project : Project,
  errors? : Array[ProjectDisassemblyRecError],
) -> ProjectDisasm {
  {
    project_value: project,
    errors_value: match errors {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn Project::disasm(self : Project) -> ProjectDisasm {
  ProjectDisasm::from_project(self)
}

///|
pub fn Library::disasm(self : Library) -> ProjectDisasm {
  ProjectDisasm::from_project(
    Project::create(
      target=self.target(),
      filename?=self.unit().path(),
      program=self.program(),
      memory=self.memory(),
      symbols=self.symbols(),
      state=self.state(),
    ),
  )
}

///|
pub fn ProjectDisasm::project(self : ProjectDisasm) -> Project {
  self.project_value
}

///|
pub fn ProjectDisasm::disassembly(
  self : ProjectDisasm,
) -> ProjectDisassemblyState {
  self.project_value.disassembly()
}

///|
pub fn ProjectDisasm::cfg(self : ProjectDisasm) -> ProjectDisassemblyCfg {
  self.disassembly().cfg()
}

///|
pub fn ProjectDisasm::errors(
  self : ProjectDisasm,
) -> Array[ProjectDisassemblyRecError] {
  self.errors_value.copy()
}

///|
pub fn ProjectDisasm::has_errors(self : ProjectDisasm) -> Bool {
  !self.errors_value.is_empty()
}

///|
pub fn ProjectDisasm::insns(
  self : ProjectDisasm,
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction)] {
  let result : Array[(@memory.Memory, ProjectDisassemblyInstruction)] = []
  for block in self.disassembly().blocks_with_instructions() {
    for pair in block.insns() {
      result.push(pair)
    }
  }
  result
}

///|
pub fn ProjectDisasm::merge(
  self : ProjectDisasm,
  other : ProjectDisasm,
) -> ProjectDisasm {
  let errors = self.errors_value.copy()
  for error in other.errors_value {
    errors.push(error)
  }
  ProjectDisasm::from_project(
    self.project_value.with_disassembly(
      project_disasm_merge_state(self.disassembly(), other.disassembly()),
    ),
    errors~,
  )
}

///|
pub fn ProjectDisasm::of_project(
  project : Project,
  backend? : String,
  brancher? : ProjectBrancher,
) -> Result[ProjectDisasm, String] {
  match register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match ProjectDisassemblyRec::run(project, driver?=backend, brancher?) {
    Ok(result) =>
      Ok(ProjectDisasm::from_project(result.project(), errors=result.errors()))
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectDisasm::of_mem(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
) -> Result[ProjectDisasm, String] {
  let roots = match rooter {
    Some(value) => value.roots()
    None => [memory.min_addr()]
  }
  let rooted = Project::empty(target)
    .with_memory(@memory.MemMap::empty().add(memory, "mem"))
    .with_symbols(project_disasm_symbols_of_roots(roots))
  ProjectDisasm::of_project(rooted, backend?, brancher?)
}

///|
pub fn ProjectDisasm::of_image(
  image : @image.Image,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
) -> Result[ProjectDisasm, String] {
  let project = Project::from_image(image)
  let rooted = match rooter {
    Some(value) =>
      project.with_symbols(project_disasm_symbols_of_roots(value.roots()))
    None => project
  }
  ProjectDisasm::of_project(rooted, backend?, brancher?)
}

///|
pub fn ProjectDisasm::of_file(
  path : String,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
  loader? : String,
) -> Result[ProjectDisasm, String] {
  match register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  let project = match loader {
    Some(name) => Project::load_file(path, loader=name)
    None => Project::file(filename=path)
  }
  let with_roots = match project {
    Ok(value) =>
      match rooter {
        Some(selected) =>
          Ok(
            value.with_symbols(
              project_disasm_symbols_of_roots(selected.roots()),
            ),
          )
        None => Ok(value)
      }
    Err(reason) => Err(reason)
  }
  project_disasm_from_project_result(with_roots, backend, brancher)
}

///|
pub fn ProjectDisasm::of_project_exn(
  project : Project,
  backend? : String,
  brancher? : ProjectBrancher,
) -> ProjectDisasm raise ProjectDisasmError {
  match ProjectDisasm::of_project(project, backend?, brancher?) {
    Ok(result) => result
    Err(reason) => raise project_disasm_failure(reason)
  }
}

///|
pub fn ProjectDisasm::of_mem_exn(
  target : @core_theory.Target,
  memory : @memory.Memory,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
) -> ProjectDisasm raise ProjectDisasmError {
  match ProjectDisasm::of_mem(target, memory, backend?, brancher?, rooter?) {
    Ok(result) => result
    Err(reason) => raise project_disasm_failure(reason)
  }
}

///|
pub fn ProjectDisasm::of_image_exn(
  image : @image.Image,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
) -> ProjectDisasm raise ProjectDisasmError {
  match ProjectDisasm::of_image(image, backend?, brancher?, rooter?) {
    Ok(result) => result
    Err(reason) => raise project_disasm_failure(reason)
  }
}

///|
pub fn ProjectDisasm::of_file_exn(
  path : String,
  backend? : String,
  brancher? : ProjectBrancher,
  rooter? : ProjectRooter,
  loader? : String,
) -> ProjectDisasm raise ProjectDisasmError {
  match ProjectDisasm::of_file(path, backend?, brancher?, rooter?, loader?) {
    Ok(result) => result
    Err(reason) => raise project_disasm_failure(reason)
  }
}
