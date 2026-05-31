///|
let abi_passes : Array[(@project.Project) -> @project.Project] = []

///|
let abi_name_key = "abi-name"

///|
let abi_name_tag_uuid = "ce10e129-4cae-4f49-9b21-8e00d3635067"

///|
pub fn register_pass(pass : (@project.Project) -> @project.Project) -> Unit {
  abi_passes.insert(0, pass)
}

///|
pub fn pass(project : @project.Project) -> @project.Project {
  let mut result = project
  for step in abi_passes {
    result = step(result)
  }
  result
}

///|
pub fn name() -> @project.ProjectStorageTag[String] {
  @project.ProjectStorageTag::string(abi_name_key)
}

///|
pub fn name_uuid() -> String {
  abi_name_tag_uuid
}

///|
pub fn project_pass() -> @project.ProjectPass {
  @project.ProjectPass::create(name="abi", run=project => Ok(pass(project)))
}

///|
pub fn register_project_pass_if_absent() -> Result[Bool, String] {
  @project.register_pass_if_absent(project_pass())
}
