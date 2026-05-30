///|
test "typed project storage tags encode and decode values" {
  let loader = @project.ProjectStorageTag::string("loader")
  let trusted = @project.ProjectStorageTag::bool("trusted")
  let weight = @project.ProjectStorageTag::int("weight")
  let args = @project.ProjectStorageTag::string_array("args")
  let counts = @project.ProjectStorageTag::int_array("counts")
  let flags = @project.ProjectStorageTag::bool_array("flags")
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .set_tag(loader, "raw")
    .set_tag(trusted, true)
    .set_tag(weight, 42)
    .set_tag(args, ["--input=a:b", "", "wide"])
    .set_tag(counts, [1, -2, 42])
    .set_tag(flags, [true, false, true])
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
  match project.get_tag(args) {
    Ok(value) => assert_true(value == Some(["--input=a:b", "", "wide"]))
    Err(reason) => fail(reason)
  }
  match project.get_tag(counts) {
    Ok(value) => assert_true(value == Some([1, -2, 42]))
    Err(reason) => fail(reason)
  }
  match project.get_tag(flags) {
    Ok(value) => assert_true(value == Some([true, false, true]))
    Err(reason) => fail(reason)
  }
  assert_true(project.has_tag(loader))
  assert_true(!project.del_tag(loader).has_tag(loader))
}

///|
test "typed project storage reports decode failures" {
  let trusted = @project.ProjectStorageTag::bool("trusted")
  let args = @project.ProjectStorageTag::string_array("args")
  let counts = @project.ProjectStorageTag::int_array("counts")
  let flags = @project.ProjectStorageTag::bool_array("flags")
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .set("trusted", "maybe")
    .set("args", "4:abc")
    .set("counts", "2:ok")
    .set("flags", "5:maybe")
  assert_true(project.get_tag(trusted) is Err(_))
  assert_true(project.get_tag(args) is Err(_))
  assert_true(project.get_tag(counts) is Err(_))
  assert_true(project.get_tag(flags) is Err(_))
}
