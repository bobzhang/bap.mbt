///|
struct ProjectDisassemblyDriver {
  name_value : String
  description_value : String
  priority_value : Int
  run_fn : (Project) -> Result[Project, String]
}

///|
let disassembly_driver_registry : Map[String, ProjectDisassemblyDriver] = {}

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
pub fn register_builtin_disassembly_drivers() -> Result[Unit, String] {
  for
    driver in [
      ProjectDisassemblyDriver::function_symbols(),
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
pub fn Project::disassemble_with_available(
  self : Project,
) -> Result[Project, String] {
  let drivers = disassembly_drivers()
  if drivers.is_empty() {
    Err("no project disassembly drivers are registered")
  } else {
    let mut last_error = ""
    for driver in drivers {
      match driver.run(self) {
        Ok(project) => return Ok(project)
        Err(reason) => last_error = reason
      }
    }
    Err("all project disassembly drivers failed: \{last_error}")
  }
}
