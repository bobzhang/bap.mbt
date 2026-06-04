///|
fn empty_project() -> @project.Project {
  @project.Project::empty(@core_theory.Target::unknown())
}

///|
fn string_tag_or_empty(
  project : @project.Project,
  tag : @project.ProjectStorageTag[String],
) -> String {
  match project.get_tag(tag) {
    Ok(Some(value)) => value
    _ => ""
  }
}

///|
fn expect_string_tag(
  project : @project.Project,
  tag : @project.ProjectStorageTag[String],
) -> String raise {
  match project.get_tag(tag) {
    Ok(Some(value)) => value
    Ok(None) => ""
    Err(reason) => fail(reason)
  }
}

///|
test "abi name tag preserves BAP metadata key and uuid" {
  let tag = @abi.name()
  assert_eq(tag.name(), "abi-name")
  assert_eq(@abi.name_uuid(), "ce10e129-4cae-4f49-9b21-8e00d3635067")
  let project = empty_project().set_tag(tag, "sysv")
  assert_eq(expect_string_tag(project, tag), "sysv")
}

///|
test "abi dispatcher applies newest registered passes first" {
  let tag = @project.ProjectStorageTag::string("abi-test-order")
  @abi.register_pass(project => {
    let current = string_tag_or_empty(project, tag)
    project.set_tag(tag, current + "a")
  })
  @abi.register_pass(project => {
    let current = string_tag_or_empty(project, tag)
    project.set_tag(tag, current + "b")
  })
  let project = @abi.pass(empty_project())
  assert_eq(expect_string_tag(project, tag), "ba")
}

///|
test "abi dispatcher can be installed as a project pass" {
  let tag = @project.ProjectStorageTag::string("abi-project-pass")
  @abi.register_pass(project => project.set_tag(tag, "ran"))
  assert_true(@abi.project_pass().autorun())
  match @abi.register_project_pass_if_absent() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match empty_project().run_pass("abi") {
    Ok(project) => assert_eq(expect_string_tag(project, tag), "ran")
    Err(reason) => fail(reason)
  }
  match @project.find_pass("abi") {
    Some(pass) => assert_true(pass.autorun())
    None => fail("missing abi pass")
  }
  let autorun_tag = @project.ProjectStorageTag::string("abi-autorun-pass")
  @abi.register_pass(project => project.set_tag(autorun_tag, "autorun"))
  match empty_project().run_autorun_passes() {
    Ok(project) => assert_eq(expect_string_tag(project, autorun_tag), "autorun")
    Err(reason) => fail(reason)
  }
}
