///|
struct ProjectReconstructor {
  run_fn : (Project) -> Result[Project, String]
}

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
fn project_reconstructor_ir_block(
  project : Project,
  block : @memory.Memory,
) -> Result[@types.Term[@types.Blk], String] {
  match project_reconstructor_block_word(project, block) {
    Ok(addr) =>
      Ok(
        @types.Blk::create(tid=@types.Tid::for_addr(addr)).set_attr(
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
  Ok(@types.Sub::create(name~, blks=ir_blocks))
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
    let subroutines : Array[@types.Term[@types.Sub]] = []
    for block in blocks {
      let name = symbolizer.resolve(block.min_addr())
      match project_reconstructor_subroutine(project, name, [block]) {
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
