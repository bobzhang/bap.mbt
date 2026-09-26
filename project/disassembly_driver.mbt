///|
struct ProjectDisassemblyDriver {
  name_value : String
  description_value : String
  priority_value : Int
  run_fn : (Project) -> Result[Project, String]
}

///|
let disassembly_driver_registry : Map[String, ProjectDisassemblyDriver] = Map([])

///|
pub fn ProjectDisassemblyDriver::create(
  name~ : String,
  description? : String,
  priority? : Int,
  run~ : (Project) -> Result[Project, String],
) -> ProjectDisassemblyDriver {
  {
    name_value: name,
    description_value: match description {
      Some(text) => text
      None => ""
    },
    priority_value: match priority {
      Some(value) => value
      None => 0
    },
    run_fn: run,
  }
}

///|
pub fn ProjectDisassemblyDriver::name(
  self : ProjectDisassemblyDriver,
) -> String {
  self.name_value
}

///|
pub fn ProjectDisassemblyDriver::description(
  self : ProjectDisassemblyDriver,
) -> String {
  self.description_value
}

///|
pub fn ProjectDisassemblyDriver::priority(
  self : ProjectDisassemblyDriver,
) -> Int {
  self.priority_value
}

///|
pub fn ProjectDisassemblyDriver::run(
  self : ProjectDisassemblyDriver,
  project : Project,
) -> Result[Project, String] {
  (self.run_fn)(project)
}

///|
pub fn register_disassembly_driver(
  driver : ProjectDisassemblyDriver,
) -> Result[Unit, String] {
  let name = driver.name()
  if disassembly_driver_registry.contains(name) {
    Err("project disassembly driver \{name} is already registered")
  } else {
    disassembly_driver_registry[name] = driver
    Ok(())
  }
}

///|
pub fn register_disassembly_driver_if_absent(
  driver : ProjectDisassemblyDriver,
) -> Result[Bool, String] {
  if disassembly_driver_registry.contains(driver.name()) {
    Ok(false)
  } else {
    match register_disassembly_driver(driver) {
      Ok(_) => Ok(true)
      Err(reason) => Err(reason)
    }
  }
}

///|
fn project_raw_byte_assembly(memory : @memory.Memory) -> String {
  ".byte 0x" + memory.hexdump()
}

///|
fn project_raw_byte_bil(memory : @memory.Memory) -> String {
  "unknown 0x" + memory.min_addr().to_string(radix=16)
}

///|
fn project_raw_byte_code(memory : @memory.Memory) -> Int {
  let bytes = memory.to_bytes()
  if bytes.length() == 0 {
    0
  } else {
    bytes[0].to_int()
  }
}

///|
fn project_raw_byte_instruction(
  memory : @memory.Memory,
) -> ProjectDisassemblyInstruction {
  let code = project_raw_byte_code(memory)
  ProjectDisassemblyInstruction::create(
    memory,
    assembly=project_raw_byte_assembly(memory),
    bil=project_raw_byte_bil(memory),
    code~,
    name=".byte",
    encoding="raw",
    operands=[ProjectInstructionOperand::immediate(code.to_int64())],
  )
}

///|
fn project_disassembly_add_raw_byte_instructions(
  state : ProjectDisassemblyState,
  block : @memory.Memory,
) -> Result[ProjectDisassemblyState, String] {
  let mut next = state.add_block(block)
  for offset in 0..<block.length() {
    let addr = block.min_addr() + offset.to_uint64()
    match block.view(from=addr, words=1) {
      Ok(byte_memory) =>
        next = next.add_instruction(project_raw_byte_instruction(byte_memory))
      Err(reason) => return Err(reason)
    }
  }
  Ok(next)
}

///|
pub fn ProjectDisassemblyDriver::memory_blocks() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="memory-blocks",
    description="materialize project memory regions as disassembly blocks",
    priority=-100,
    run=project => {
      let mut state = project.disassembly()
      let mut added = 0
      for entry in project.memory().entries() {
        let block = entry.0
        if block.length() > 0 {
          state = state.add_block(block)
          added = added + 1
        }
      }
      if added == 0 {
        Err("project has no memory blocks to disassemble")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "memory-blocks"))
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::raw_bytes() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="raw-bytes",
    description="materialize project memory regions as byte-granular instructions",
    priority=-95,
    run=project => {
      let mut state = project.disassembly()
      let mut added = 0
      for entry in project.memory().entries() {
        let block = entry.0
        if block.length() > 0 {
          match project_disassembly_add_raw_byte_instructions(state, block) {
            Ok(next) => {
              state = next
              added = added + 1
            }
            Err(reason) => return Err(reason)
          }
        }
      }
      if added == 0 {
        Err("project has no memory blocks to disassemble")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "raw-bytes"))
      }
    },
  )
}

///|
fn project_disassembly_add_linear_sweep_instructions(
  state : ProjectDisassemblyState,
  target : @core_theory.Target,
  block : @memory.Memory,
  backend : String,
) -> Result[ProjectDisassemblyState, String] {
  let mut next = state.add_block(block)
  match ProjectDisassemblyLinearSweep::sweep(target, block, backend~) {
    Ok(items) => {
      for item in items {
        match item.1 {
          Some(instruction) => next = next.add_instruction(instruction)
          None => ()
        }
      }
      Ok(next)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn project_disassembly_add_basic_instructions(
  state : ProjectDisassemblyState,
  disasm : ProjectDisassemblyBasic,
  block : @memory.Memory,
) -> ProjectDisassemblyState {
  let mut next = state.add_block(block)
  let insns = disasm.run(block, init=(), return_=_ => [], stopped=(s, _) => {
    s.insns()
  })
  for item in insns {
    match item.1 {
      Some(instruction) => next = next.add_instruction(instruction)
      None => ()
    }
  }
  next
}

///|
pub fn ProjectDisassemblyDriver::linear_sweep(
  backend? : String = "llvm",
) -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="linear-sweep",
    description="materialize project memory regions with the linear sweep disassembler",
    priority=-96,
    run=project => {
      let mut state = project.disassembly()
      let mut added = 0
      for entry in project.memory().entries() {
        let block = entry.0
        if block.length() > 0 {
          match
            project_disassembly_add_linear_sweep_instructions(
              state,
              project.target(),
              block,
              backend,
            ) {
            Ok(next) => {
              state = next
              added = added + 1
            }
            Err(reason) => return Err(reason)
          }
        }
      }
      if added == 0 {
        Err("project has no memory blocks to disassemble")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "linear-sweep"))
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::basic(
  backend? : String = "llvm",
) -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="basic",
    description="materialize project memory regions with the Basic disassembler",
    priority=-97,
    run=project => {
      let disasm = match
        project_disassembly_basic_for_target(project.target(), backend) {
        Ok(disasm) => disasm
        Err(reason) => return Err(reason)
      }
      let mut state = project.disassembly()
      let mut added = 0
      for entry in project.memory().entries() {
        let block = entry.0
        if block.length() > 0 {
          state = project_disassembly_add_basic_instructions(
            state, disasm, block,
          )
          added = added + 1
        }
      }
      if added == 0 {
        Err("project has no memory blocks to disassemble")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "basic"))
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::function_symbols() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="function-symbols",
    description="materialize function symbol memory as disassembly blocks",
    priority=-50,
    run=project => {
      let image = match project.image() {
        Some(image) => image
        None => return Err("project has no image-backed symbols to disassemble")
      }
      let mut state = project.disassembly()
      let mut added = 0
      for symbol in project.symbols() {
        if symbol.is_function() {
          match image.segment_of_symbol(symbol) {
            Some(segment) if segment.is_executable() =>
              match image.memories_of_symbol(symbol) {
                Some(chunks) =>
                  for chunk in chunks {
                    if chunk.length() > 0 {
                      state = state.add_block(chunk)
                      added = added + 1
                    }
                  }
                None => ()
              }
            _ => ()
          }
        }
      }
      if added == 0 {
        Err("project has no function symbol memory to disassemble")
      } else {
        Ok(
          project
          .with_disassembly(state)
          .set("disassembler", "function-symbols"),
        )
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::image_roots() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="image-roots",
    description="materialize image root addresses as disassembly blocks",
    priority=-25,
    run=project => {
      let image = match project.image() {
        Some(image) => image
        None => return Err("project has no image roots to disassemble")
      }
      let rooter = project.rooter()
      let blocks = match rooter.image_blocks(image, executable_only=true) {
        Ok(blocks) => blocks
        Err(reason) => return Err(reason)
      }
      let mut state = project.disassembly()
      let mut added = 0
      for block in blocks {
        if block.length() > 0 {
          state = state.add_block(block)
          added = added + 1
        }
      }
      if added == 0 {
        Err("project image roots are not mapped")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "image-roots"))
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::project_roots() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="project-roots",
    description="materialize project root addresses from project memory",
    priority=-90,
    run=project => {
      if project.image() is Some(_) {
        return Err("project-root disassembly is for non-image project memory")
      }
      let roots = project.rooter().roots()
      if roots.is_empty() {
        return Err("project has no roots to disassemble")
      }
      let mut state = project.disassembly()
      let mut added = 0
      for root in roots {
        for entry in project.memory().lookup(root) {
          match entry.0.view(from=root) {
            Ok(block) =>
              if block.length() > 0 {
                state = state.add_block(block)
                added = added + 1
              }
            Err(reason) => return Err(reason)
          }
        }
      }
      if added == 0 {
        Err("project roots are not mapped")
      } else {
        Ok(project.with_disassembly(state).set("disassembler", "project-roots"))
      }
    },
  )
}

///|
pub fn ProjectDisassemblyDriver::entry_point() -> ProjectDisassemblyDriver {
  ProjectDisassemblyDriver::create(
    name="entry-point",
    description="materialize image entry point memory as a disassembly block",
    priority=-75,
    run=project => {
      let image = match project.image() {
        Some(image) => image
        None => return Err("project has no image entry point to disassemble")
      }
      let entry = image.entry_point()
      for segment in image.segments() {
        if segment.is_executable() && segment.contains(entry) {
          match segment.memory().view(from=entry) {
            Ok(block) =>
              return Ok(
                project
                .with_disassembly(project.disassembly().add_block(block))
                .set("disassembler", "entry-point"),
              )
            Err(reason) => return Err(reason)
          }
        }
      }
      Err("project entry point is not mapped")
    },
  )
}

///|
pub fn register_builtin_disassembly_drivers() -> Result[Unit, String] {
  for
    driver in [
      ProjectDisassemblyDriver::image_roots(),
      ProjectDisassemblyDriver::function_symbols(),
      ProjectDisassemblyDriver::entry_point(),
      ProjectDisassemblyDriver::project_roots(),
      ProjectDisassemblyDriver::raw_bytes(),
      ProjectDisassemblyDriver::linear_sweep(),
      ProjectDisassemblyDriver::basic(),
      ProjectDisassemblyDriver::memory_blocks(),
    ] {
    match register_disassembly_driver_if_absent(driver) {
      Ok(_) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok(())
}

///|
pub fn find_disassembly_driver(name : String) -> ProjectDisassemblyDriver? {
  disassembly_driver_registry.get(name)
}

///|
pub fn disassembly_drivers() -> Array[ProjectDisassemblyDriver] {
  let result = []
  disassembly_driver_registry.each((_, driver) => result.push(driver))
  result.sort_by((left, right) => right.priority().compare(left.priority()))
  result
}

///|
pub fn disassembly_driver_names() -> Array[String] {
  disassembly_drivers().map(driver => driver.name())
}

///|
pub fn Project::disassemble(
  self : Project,
  driver~ : String,
) -> Result[Project, String] {
  match find_disassembly_driver(driver) {
    Some(value) => value.run(self)
    None => Err("unknown project disassembly driver \{driver}")
  }
}

///|
pub fn Project::disassemble_with_drivers(
  self : Project,
  drivers : Array[ProjectDisassemblyDriver],
) -> Result[Project, String] {
  if drivers.is_empty() {
    Err("no project disassembly drivers are provided")
  } else {
    let failures : Array[String] = []
    for driver in drivers {
      match driver.run(self) {
        Ok(project) => return Ok(project)
        Err(reason) => failures.push("\{driver.name()}: \{reason}")
      }
    }
    Err("all project disassembly drivers failed: \{failures.join("; ")}")
  }
}

///|
pub fn Project::disassemble_with_available(
  self : Project,
) -> Result[Project, String] {
  let drivers = disassembly_drivers()
  if drivers.is_empty() {
    Err("no project disassembly drivers are registered")
  } else {
    self.disassemble_with_drivers(drivers)
  }
}
