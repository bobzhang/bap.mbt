///|
struct ProjectReconstructor {
  run_fn : (Project) -> Result[Project, String]
}

///|
let project_reconstructor_registry : Map[String, ProjectReconstructor] = {}

///|
fn project_reconstructor_find_name(
  names : Array[String],
  name : String,
) -> Int? {
  for i in 0..<names.length() {
    if names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
fn project_reconstructor_block_word(
  project : Project,
  block : @memory.Memory,
) -> Result[@types.Word, String] {
  let code_width = project.target().code_addr_size()
  let width = if code_width <= 0 { 32 } else { code_width }
  try @types.Word::of_uint64(width~, block.min_addr()) catch {
    _ => Err("disassembly block address is not representable by project target")
  } noraise {
    word => Ok(word)
  }
}

///|
fn project_reconstructor_find_block_start(
  blocks : Array[@memory.Memory],
  addr : UInt64,
) -> Int? {
  for i in 0..<blocks.length() {
    if blocks[i].min_addr() == addr {
      return Some(i)
    }
  }
  None
}

///|
fn project_reconstructor_find_block_containing(
  blocks : Array[@memory.Memory],
  addr : UInt64,
) -> Int? {
  for i in 0..<blocks.length() {
    if blocks[i].contains(addr) {
      return Some(i)
    }
  }
  None
}

///|
fn project_reconstructor_edge_target_index(
  blocks : Array[@memory.Memory],
  edge : ProjectDisassemblyEdge,
) -> Int? {
  match edge.target() {
    Some(target) => project_reconstructor_find_block_containing(blocks, target)
    None => None
  }
}

///|
fn project_reconstructor_group_contains(
  group : Array[@memory.Memory],
  block : @memory.Memory,
) -> Bool {
  group.any(item => item.min_addr() == block.min_addr())
}

///|
fn project_reconstructor_has_incoming_edge(
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  block : @memory.Memory,
) -> Bool {
  edges.any(edge => {
    match project_reconstructor_edge_target_index(blocks, edge) {
      Some(target_index) => blocks[target_index].min_addr() == block.min_addr()
      None => false
    }
  })
}

///|
fn project_reconstructor_add_start(
  starts : Array[@memory.Memory],
  block : @memory.Memory,
) -> Unit {
  if !project_reconstructor_group_contains(starts, block) {
    starts.push(block)
  }
}

///|
fn project_reconstructor_reachable_blocks_with_boundaries(
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  start : @memory.Memory,
  boundaries : Array[@memory.Memory],
) -> Array[@memory.Memory] {
  let group : Array[@memory.Memory] = []
  let stack = [start]
  while stack.length() > 0 {
    match stack.pop() {
      Some(block) =>
        if !project_reconstructor_group_contains(group, block) {
          group.push(block)
          for edge in edges {
            if block.contains(edge.source()) {
              match project_reconstructor_edge_target_index(blocks, edge) {
                Some(target_index) => {
                  let target = blocks[target_index]
                  if target.min_addr() == start.min_addr() ||
                    !project_reconstructor_group_contains(boundaries, target) {
                    stack.push(target)
                  }
                }
                None => ()
              }
            }
          }
        }
      None => ()
    }
  }
  group.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  group
}

///|
fn project_reconstructor_reachable_blocks(
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  start : @memory.Memory,
) -> Array[@memory.Memory] {
  project_reconstructor_reachable_blocks_with_boundaries(blocks, edges, start, [])
}

///|
fn project_reconstructor_unassigned_reachable_blocks(
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  assigned : Array[@memory.Memory],
  start : @memory.Memory,
) -> Array[@memory.Memory] {
  let reachable = project_reconstructor_reachable_blocks(blocks, edges, start)
  let group : Array[@memory.Memory] = []
  for block in reachable {
    if !project_reconstructor_group_contains(assigned, block) {
      group.push(block)
      assigned.push(block)
    }
  }
  group
}

///|
fn project_reconstructor_default_groups(
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  roots : Array[UInt64],
) -> Array[Array[@memory.Memory]] {
  let starts : Array[@memory.Memory] = []
  for root in roots {
    match project_reconstructor_find_block_start(blocks, root) {
      Some(index) => project_reconstructor_add_start(starts, blocks[index])
      None => ()
    }
  }
  for block in blocks {
    if !project_reconstructor_has_incoming_edge(blocks, edges, block) {
      project_reconstructor_add_start(starts, block)
    }
  }
  if starts.is_empty() && !blocks.is_empty() {
    starts.push(blocks[0])
  }
  starts.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  let assigned : Array[@memory.Memory] = []
  let groups : Array[Array[@memory.Memory]] = []
  for start in starts {
    let group = project_reconstructor_reachable_blocks_with_boundaries(
      blocks, edges, start, starts,
    )
    if !group.is_empty() {
      groups.push(group)
      for block in group {
        if !project_reconstructor_group_contains(assigned, block) {
          assigned.push(block)
        }
      }
    }
  }
  let remaining = blocks.copy()
  remaining.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  for block in remaining {
    if !project_reconstructor_group_contains(assigned, block) {
      let group = project_reconstructor_unassigned_reachable_blocks(
        blocks, edges, assigned, block,
      )
      if !group.is_empty() {
        groups.push(group)
      }
    }
  }
  groups
}

///|
fn project_reconstructor_edge_jmp(
  edge : ProjectDisassemblyEdge,
  dst : @types.Tid,
) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_goto(@types.Label::direct(dst)).set_attr(
    @types.Attr::new(key="disassembly-edge", value=edge.kind().to_string()),
  )
}

///|
fn project_reconstructor_ir_block(
  project : Project,
  block : @memory.Memory,
) -> Result[@types.Term[@types.Blk], String] {
  match project_reconstructor_block_word(project, block) {
    Ok(addr) =>
      Ok(
        @types.Blk::create(tid=@types.Tid::for_addr(addr, pkg?=project.pkg())).set_attr(
          @types.Attr::address(addr),
        ),
      )
    Err(reason) => Err(reason)
  }
}

///|
fn project_reconstructor_subroutine(
  project : Project,
  name : String,
  blocks : Array[@memory.Memory],
) -> Result[@types.Term[@types.Sub], String] {
  let ir_blocks : Array[@types.Term[@types.Blk]] = []
  for block in blocks {
    match project_reconstructor_ir_block(project, block) {
      Ok(ir_block) => ir_blocks.push(ir_block)
      Err(reason) => return Err(reason)
    }
  }
  for i in 0..<blocks.length() {
    let mut ir_block = ir_blocks[i]
    for edge in project.disassembly().edges_from_block(blocks[i]) {
      match edge.target() {
        Some(target) =>
          match project_reconstructor_find_block_containing(blocks, target) {
            Some(target_index) =>
              ir_block = ir_block.append_jmp(
                project_reconstructor_edge_jmp(
                  edge,
                  ir_blocks[target_index].tid(),
                ),
              )
            None => ()
          }
        None => ()
      }
    }
    ir_blocks[i] = ir_block
  }
  let mut sub = @types.Sub::create(
    name~,
    blks=ir_blocks,
    tid=@types.Tid::for_name(name, pkg?=project.pkg()),
  )
  if !blocks.is_empty() {
    match project_reconstructor_block_word(project, blocks[0]) {
      Ok(addr) => sub = sub.set_attr(@types.Attr::address(addr))
      Err(reason) => return Err(reason)
    }
  }
  match project.image() {
    Some(image) if blocks.any(block => block.contains(image.entry_point())) =>
      Ok(sub.with_entry_point())
    _ => Ok(sub)
  }
}

///|
fn project_reconstructor_apply(
  project : Project,
  subroutines : Array[@types.Term[@types.Sub]],
) -> Project {
  let program = @types.Program::create(subs=subroutines)
  project
  .with_program(program)
  .with_state(project.state().with_subroutines(subroutines))
}

///|
pub fn ProjectReconstructor::create(
  run : (Project) -> Result[Project, String],
) -> ProjectReconstructor {
  { run_fn: run }
}

///|
pub fn ProjectReconstructor::run(
  self : ProjectReconstructor,
  project : Project,
) -> Result[Project, String] {
  (self.run_fn)(project)
}

///|
pub fn ProjectReconstructor::default() -> ProjectReconstructor {
  ProjectReconstructor::create(project => {
    let blocks = project.disassembly().blocks()
    if blocks.is_empty() {
      return Err("project has no disassembly blocks to reconstruct")
    }
    let symbolizer = project.symbolizer()
    let groups = project_reconstructor_default_groups(
      blocks,
      project.disassembly().edges(),
      project.rooter().roots(),
    )
    let subroutines : Array[@types.Term[@types.Sub]] = []
    for group in groups {
      let name = symbolizer.resolve(group[0].min_addr())
      match project_reconstructor_subroutine(project, name, group) {
        Ok(subroutine) => subroutines.push(subroutine)
        Err(reason) => return Err(reason)
      }
    }
    Ok(project_reconstructor_apply(project, subroutines))
  })
}

///|
pub fn ProjectReconstructor::of_blocks(
  blocks : Array[(String, UInt64, UInt64)],
) -> ProjectReconstructor {
  ProjectReconstructor::create(project => {
    let disassembly_blocks = project.disassembly().blocks()
    if disassembly_blocks.is_empty() {
      return Err("project has no disassembly blocks to reconstruct")
    }
    let names : Array[String] = []
    let groups : Array[Array[@memory.Memory]] = []
    for spec in blocks {
      let name = spec.0
      let start = spec.1
      match disassembly_blocks.search_by(block => block.min_addr() == start) {
        Some(block_index) => {
          let block = disassembly_blocks[block_index]
          match project_reconstructor_find_name(names, name) {
            Some(name_index) => groups[name_index].push(block)
            None => {
              names.push(name)
              groups.push([block])
            }
          }
        }
        None => ()
      }
    }
    let subroutines : Array[@types.Term[@types.Sub]] = []
    for i in 0..<names.length() {
      let group = groups[i]
      group.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
      match project_reconstructor_subroutine(project, names[i], group) {
        Ok(subroutine) => subroutines.push(subroutine)
        Err(reason) => return Err(reason)
      }
    }
    if subroutines.is_empty() {
      Err("project block reconstructor matched no disassembly blocks")
    } else {
      Ok(project_reconstructor_apply(project, subroutines))
    }
  })
}

///|
pub fn register_reconstructor(
  name~ : String,
  reconstructor : ProjectReconstructor,
) -> Result[Unit, String] {
  if project_reconstructor_registry.contains(name) {
    Err("project reconstructor \{name} is already registered")
  } else {
    project_reconstructor_registry[name] = reconstructor
    Ok(())
  }
}

///|
pub fn register_reconstructor_if_absent(
  name~ : String,
  reconstructor : ProjectReconstructor,
) -> Result[Bool, String] {
  if project_reconstructor_registry.contains(name) {
    Ok(false)
  } else {
    match register_reconstructor(name~, reconstructor) {
      Ok(_) => Ok(true)
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn register_builtin_reconstructors() -> Result[Unit, String] {
  match
    register_reconstructor_if_absent(
      name="default",
      ProjectReconstructor::default(),
    ) {
    Ok(_) => Ok(())
    Err(reason) => Err(reason)
  }
}

///|
pub fn find_reconstructor(name : String) -> ProjectReconstructor? {
  project_reconstructor_registry.get(name)
}

///|
pub fn reconstructor_names() -> Array[String] {
  let names = []
  project_reconstructor_registry.each((name, _) => names.push(name))
  names.sort_by((left, right) => left.compare(right))
  names
}

///|
pub fn Project::reconstruct(
  self : Project,
  reconstructor? : ProjectReconstructor,
) -> Result[Project, String] {
  let selected = match reconstructor {
    Some(value) => value
    None => ProjectReconstructor::default()
  }
  selected.run(self)
}

///|
pub fn Project::reconstruct_named(
  self : Project,
  reconstructor~ : String,
) -> Result[Project, String] {
  match find_reconstructor(reconstructor) {
    Some(value) => self.reconstruct(reconstructor=value)
    None => Err("unknown project reconstructor \{reconstructor}")
  }
}

///|
pub fn Project::disassemble_and_reconstruct(
  self : Project,
  driver? : String,
  brancher? : ProjectBrancher,
  reconstructor? : ProjectReconstructor,
) -> Result[Project, String] {
  let disassembled = match driver {
    Some(name) =>
      match self.disassemble(driver=name) {
        Ok(project) => project
        Err(reason) => return Err(reason)
      }
    None =>
      match self.disassemble_with_available() {
        Ok(project) => project
        Err(reason) => return Err(reason)
      }
  }
  let branched = match brancher {
    Some(value) =>
      match disassembled.apply_brancher(brancher=value) {
        Ok(project) => project
        Err(reason) => return Err(reason)
      }
    None => disassembled
  }
  branched.reconstruct(reconstructor?)
}

///|
pub fn Project::disassemble_and_reconstruct_named(
  self : Project,
  driver? : String,
  brancher? : String,
  reconstructor? : String,
) -> Result[Project, String] {
  let selected_brancher = match brancher {
    Some(name) =>
      match find_brancher(name) {
        Some(value) => Some(value)
        None => return Err("unknown project brancher \{name}")
      }
    None => None
  }
  let selected_reconstructor = match reconstructor {
    Some(name) =>
      match find_reconstructor(name) {
        Some(value) => Some(value)
        None => return Err("unknown project reconstructor \{name}")
      }
    None => None
  }
  self.disassemble_and_reconstruct(
    driver?,
    brancher?=selected_brancher,
    reconstructor?=selected_reconstructor,
  )
}
