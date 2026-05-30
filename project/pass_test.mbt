///|
test "project passes register lookup and run" {
  let pass = @project.ProjectPass::create(name="unit-set-loader", run=project => {
    Ok(project.set("loader", "unit"))
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_pass("unit-set-loader") is Some(_))
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.run_pass("unit-set-loader") {
    Ok(next) => assert_true(next.get("loader") == Some("unit"))
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_pass(pass) is Err(_))
}

///|
test "autorun passes update projects" {
  let pass = @project.ProjectPass::create(name="unit-autorun", autorun=true, run=project => {
    Ok(project.set("autorun", "yes"))
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.run_autorun_passes() {
    Ok(next) => assert_true(next.get("autorun") == Some("yes"))
    Err(reason) => fail(reason)
  }
}
