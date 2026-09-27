// The incremental disassembler in projects (upstream `Project.create`:
// the code regions of the project are scanned with `Disasm.Driver.scan`
// in the knowledge base populated by the rooters, symbolizers and
// branchers of the project).

///|
/// The knowledge base of the project.
pub fn Project::knowledge(self : Project) -> @knowledge.State {
  self.knowledge_value
}

///|
/// The state of the incremental disassembler that disassembled the project
/// (see `ProjectDisassemblyDriver::recursive`), if the disassembly was not
/// changed since.
pub fn Project::disassembly_driver_state(
  self : Project,
) -> ProjectDisassemblyDriverState? {
  self.driver_value
}

///|
/// The project with the state of the incremental disassembler.
pub fn Project::with_disassembly_driver_state(
  self : Project,
  driver : ProjectDisassemblyDriverState,
) -> Project {
  { ..self, driver_value: Some(driver), }
}

///|
/// The program unit of the project (upstream `Theory.Unit`): the unit of
/// the project file, with the project target and the load bias.
pub fn Project::program_unit(self : Project) -> @core_theory.ProgramUnit {
  let bias = match self.load_bias() {
    Some(bias) if bias != 0L =>
      try @types.Word::of_int64(bias, width=64) catch {
        _ => None
      } noraise {
        word => Some(word)
      }
    _ => None
  }
  let path = match self.filename() {
    Some(path) => path
    None => ""
  }
  @core_theory.ProgramUnit::for_file(path, target=self.target(), bias?)
}

///|
/// Evaluates `f` with the knowledge providers of the project (upstream: the
/// providers installed when the project is created): the labels of the
/// project memory belong to the project unit (`Theory.Label.unit`), the
/// rooter of the project (`Project::rooter`) provides the subroutine
/// starts, the symbolizer of the project (`Project::symbolizer`) the names,
/// and `brancher`, when given, the destinations of the instructions.
pub fn[R] Project::with_disasm_providers(
  self : Project,
  brancher? : ProjectBrancher,
  f : () -> R raise?,
) -> R raise? {
  project_disasm_knowledge_init()
  let unit = self.program_unit()
  let relocations = self.relocation_info()
  project_unit_relocations.set(
    self.knowledge(),
    if relocations.is_empty() {
      None
    } else {
      Some((unit, relocations))
    },
  )
  let memory = self.memory()
  let regions = self.disassembly_code_regions()
  let in_project = (addr : UInt64) => {
    memory.lookup(addr).length() > 0 ||
    regions.iter().any(mem => mem.contains(addr))
  }
  let with_brancher = () => {
    match brancher {
      Some(brancher) => brancher.providing(f)
      None => f()
    }
  }
  project_label_unit.promising(
    promise=(kb, label) => {
      match project_label_addr_of(kb, label) {
        Some(addr) if in_project(addr) => Some(unit)
        _ => None
      }
    },
    () => {
      self
      .rooter()
      .providing(() => {
        self.symbolizer().providing(ProjectSymbolizer::agent(), with_brancher)
      })
    },
  )
}

///|
/// The code regions of the project: the executable segments of its image,
/// or all its memory regions when it has no image.
pub fn Project::disassembly_code_regions(
  self : Project,
) -> Array[@memory.Memory] {
  let regions : Array[@memory.Memory] = []
  match self.image() {
    Some(image) =>
      for segment in image.segments() {
        if segment.is_executable() && segment.memory().length() > 0 {
          regions.push(segment.memory())
        }
      }
    None =>
      for entry in self.memory().entries() {
        if entry.0.length() > 0 {
          regions.push(entry.0)
        }
      }
  }
  regions.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  regions
}

///|
/// The disassembly state materialized from the state of the incremental
/// disassembler: the basic blocks reachable from the block starts, their
/// instructions, and the edges between them (from the last instruction of
/// a block: `FallEdge` to the next block, `CondEdge` to the destinations of
/// a conditional jump, `JumpEdge` to the other destinations, including the
/// callees of calls).
fn project_disassembly_of_driver(
  driver : ProjectDisassemblyDriverState,
  kb : @knowledge.State,
) -> ProjectDisassemblyState raise {
  let blocks : Array[@memory.Memory] = []
  let instructions : Array[ProjectDisassemblyInstruction] = []
  let edges : Array[ProjectDisassemblyEdge] = []
  driver.explore(
    kb,
    init=(),
    block=(mem, insns) => {
      blocks.push(mem)
      let mut last : UInt64? = None
      for label in insns.list() {
        match kb.collect(project_insn_slot, label) {
          Some(insn) => {
            instructions.push(insn)
            last = Some(insn.addr())
          }
          None => ()
        }
      }
      (mem, last)
    },
    node=(_, _) => (),
    edge=(src, dst, _) => {
      let (mem, last) = src
      let source = match last {
        Some(addr) => addr
        None => mem.min_addr()
      }
      let target = dst.0.min_addr()
      let kind = if target == mem.max_addr() + 1UL {
        FallEdge
      } else {
        match driver.jump(source) {
          Some(jump) if !jump.is_barrier() && !jump.is_call() => CondEdge
          _ => JumpEdge
        }
      }
      edges.push(ProjectDisassemblyEdge::create(source~, target~, kind~))
    },
  )
  blocks.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  instructions.sort_by((left, right) => left.addr().compare(right.addr()))
  edges.sort_by((left, right) => {
    let order = left.source().compare(right.source())
    if order != 0 {
      order
    } else {
      left.target().compare(right.target())
    }
  })
  ProjectDisassemblyState::create(blocks~, instructions~, edges~)
}

///|
/// Disassembles the code regions of the project with the incremental
/// disassembler (upstream `Project.create`): the regions are scanned in
/// order of their addresses, in the knowledge base of the project with its
/// providers (see `Project::with_disasm_providers`); the project gets the
/// materialized disassembly and the state of the disassembler.
pub fn Project::disassemble_recursive(
  self : Project,
  brancher? : ProjectBrancher,
) -> Result[Project, String] {
  let regions = self.disassembly_code_regions()
  if regions.is_empty() {
    return Err("project has no code to disassemble")
  }
  let kb = self.knowledge()
  let result = try
    self.with_disasm_providers(brancher?, () => {
      let mut driver = match self.disassembly_driver_state() {
        Some(driver) => driver
        None => ProjectDisassemblyDriverState::init()
      }
      for region in regions {
        driver = driver.scan(region, kb)
      }
      (driver, project_disassembly_of_driver(driver, kb))
    })
  catch {
    err => Err("incremental disassembly failed: \{err}")
  } noraise {
    result => Ok(result)
  }
  match result {
    Err(reason) => Err(reason)
    Ok((driver, disassembly)) =>
      if disassembly.blocks().is_empty() {
        Err("the incremental disassembler found no code")
      } else {
        Ok(
          self
          .with_disassembly(disassembly)
          .with_disassembly_driver_state(driver)
          .set("disassembler", "recursive"),
        )
      }
  }
}

///|
/// The incremental recursive-descent disassembler (upstream
/// `Disasm.Driver`, see `Project::disassemble_recursive`).
pub fn ProjectDisassemblyDriver::recursive() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="recursive",
    description="the incremental recursive descent disassembler (upstream Disasm.Driver)",
    priority=-98,
    run=project => project.disassemble_recursive(),
  )
}
