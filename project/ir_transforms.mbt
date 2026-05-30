///|
pub fn Project::to_ssa(self : Project) -> Project {
  self.map_program(program => program.program_to_ssa())
}

///|
pub fn Project::destroy_ssa(self : Project) -> Project {
  self.map_program(program => program.destroy_program_ssa())
}

///|
pub fn Project::flatten_program(self : Project) -> Project {
  self.map_program(program => program.flatten_program())
}

///|
pub fn Project::to_trivial_condition_form(self : Project) -> Project {
  self.map_program(program => program.program_to_trivial_condition_form())
}

///|
pub fn Project::resolve_stub_calls(
  self : Project,
  link_only? : Array[String],
  no_link? : Array[String],
) -> Project {
  self.map_program(program => {
    program.program_resolve_stub_calls(link_only?, no_link?)
  })
}
