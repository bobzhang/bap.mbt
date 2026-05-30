///|
fn project_with_value(value : String) -> @project.Project {
  @project.Project::empty(@core_theory.Target::unknown()).set("value", value)
}

///|
fn project_value(project : @project.Project) -> String {
  match project.get("value") {
    Some(value) => value
    None => ""
  }
}

///|
test "project collators fold alternatives against a base project" {
  let collator = @project.ProjectCollator::create(
    name="unit-collator",
    description="collect value differences",
    prepare=project => "base=\{project_value(project)}",
    collate=(version, state, project) => {
      "\{state};v\{version}=\{project_value(project)}"
    },
    summary=state => state,
  )
  assert_true(collator.name() == "unit-collator")
  assert_true(collator.description() == "collect value differences")
  let result = collator.apply([
    project_with_value("old"),
    project_with_value("new-a"),
    project_with_value("new-b"),
  ])
  assert_true(result == Some("base=old;v0=new-a;v1=new-b"))
}

///|
test "project collators ignore empty project sequences" {
  let collator = @project.ProjectCollator::create(
    name="unit-empty-collator",
    prepare=_ => 0,
    collate=(_, state, _) => state + 1,
    summary=state => state,
  )
  assert_true(collator.apply([]) is None)
  assert_true(collator.apply([project_with_value("only")]) == Some(0))
}

///|
test "registered project collators can be discovered and applied" {
  let summary : Ref[String] = Ref("")
  let collator = @project.RegisteredProjectCollator::create(
    name="unit-registered-collator",
    description="collect project values",
    prepare=project => project_value(project),
    collate=(version, state, project) => {
      state + "|\{version}:" + project_value(project)
    },
    summary=state => summary.val = state,
  )
  match @project.register_collator(collator) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_collator(collator) is Err(_))
  match @project.find_collator("unit-registered-collator") {
    Some(found) => {
      assert_true(found.description() == "collect project values")
      found.apply([project_with_value("base"), project_with_value("next")])
      assert_true(summary.val == "base|0:next")
    }
    None => fail("collator was not registered")
  }
  let mut seen = false
  for info in @project.registered_collators() {
    if info.name() == "unit-registered-collator" {
      seen = true
    }
  }
  assert_true(seen)
}
