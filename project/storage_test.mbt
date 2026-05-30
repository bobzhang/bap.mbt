///|
test "typed project storage tags encode and decode values" {
  let loader = @project.ProjectStorageTag::string("loader")
  let trusted = @project.ProjectStorageTag::bool("trusted")
  let weight = @project.ProjectStorageTag::int("weight")
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .set_tag(loader, "raw")
    .set_tag(trusted, true)
    .set_tag(weight, 42)
  match project.get_tag(loader) {
    Ok(value) => assert_true(value == Some("raw"))
    Err(reason) => fail(reason)
  }
  match project.get_tag(trusted) {
    Ok(value) => assert_true(value == Some(true))
    Err(reason) => fail(reason)
  }
  match project.get_tag(weight) {
    Ok(value) => assert_true(value == Some(42))
    Err(reason) => fail(reason)
  }
  assert_true(project.has_tag(loader))
  assert_true(!project.del_tag(loader).has_tag(loader))
}

///|
test "typed project storage reports decode failures" {
  let trusted = @project.ProjectStorageTag::bool("trusted")
  let project = @project.Project::empty(@core_theory.Target::unknown()).set(
    "trusted", "maybe",
  )
  assert_true(project.get_tag(trusted) is Err(_))
}
