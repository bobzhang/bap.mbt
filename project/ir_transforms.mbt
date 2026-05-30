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

///|
pub fn ProjectPass::ssa() -> ProjectPass {
  ProjectPass::create(name="ssa", run=project => Ok(project.to_ssa()))
}

///|
pub fn ProjectPass::destroy_ssa() -> ProjectPass {
  ProjectPass::create(name="destroy-ssa", run=project => {
    Ok(project.destroy_ssa())
  })
}

///|
pub fn ProjectPass::flatten() -> ProjectPass {
  ProjectPass::create(name="flatten", run=project => {
    Ok(project.flatten_program())
  })
}

///|
pub fn ProjectPass::trivial_condition_form() -> ProjectPass {
  ProjectPass::create(name="trivial-condition-form", run_once=true, run=project => {
    Ok(project.to_trivial_condition_form())
  })
}

///|
pub fn ProjectPass::stub_resolver(
  link_only? : Array[String],
  no_link? : Array[String],
) -> ProjectPass {
  ProjectPass::create(name="stub-resolver", run=project => {
    Ok(project.resolve_stub_calls(link_only?, no_link?))
  })
}

///|
pub fn register_ir_transform_passes() -> Result[Unit, String] {
  for
    pass in [
      ProjectPass::ssa(),
      ProjectPass::destroy_ssa(),
      ProjectPass::flatten(),
      ProjectPass::trivial_condition_form(),
      ProjectPass::stub_resolver(),
    ] {
    match register_pass_if_absent(pass) {
      Ok(_) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok(())
}
