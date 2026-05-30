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
