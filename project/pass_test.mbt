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

///|
test "run_pass executes dependencies before requested pass" {
  let dep = @project.ProjectPass::create(name="unit-dep-a", run=project => {
    Ok(project.set("trace", "a"))
  })
  let main = @project.ProjectPass::create(
    name="unit-dep-b",
    deps=["unit-dep-a"],
    run=project => Ok(project.set("trace", project.get("trace").unwrap() + "b")),
  )
  match @project.register_pass(dep) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_pass(main) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.run_pass("unit-dep-b") {
    Ok(next) => assert_true(next.get("trace") == Some("ab"))
    Err(reason) => fail(reason)
  }
  match @project.resolve_passes(["unit-dep-b"]) {
    Ok(order) => {
      assert_true(order.length() == 2)
      assert_true(order[0].name() == "unit-dep-a")
      assert_true(order[1].name() == "unit-dep-b")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "autorun dependency roots include non-autorun deps" {
  let dep = @project.ProjectPass::create(name="unit-auto-dep", run=project => {
    Ok(project.set("auto-trace", "d"))
  })
  let main = @project.ProjectPass::create(
    name="unit-auto-main",
    autorun=true,
    deps=["unit-auto-dep"],
    run=project => {
      Ok(project.set("auto-trace", project.get("auto-trace").unwrap() + "m"))
    },
  )
  match @project.register_pass(dep) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_pass(main) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.run_autorun_passes() {
    Ok(next) => assert_true(next.get("auto-trace") == Some("dm"))
    Err(reason) => fail(reason)
  }
}

///|
test "pass resolver reports missing dependencies and cycles" {
  let missing = @project.ProjectPass::create(
    name="unit-missing-main",
    deps=["unit-missing-dep"],
    run=project => Ok(project),
  )
  match @project.register_pass(missing) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.resolve_passes(["unit-missing-main"]) is Err(_))
  let cycle_a = @project.ProjectPass::create(
    name="unit-cycle-a",
    deps=["unit-cycle-b"],
    run=project => Ok(project),
  )
  let cycle_b = @project.ProjectPass::create(
    name="unit-cycle-b",
    deps=["unit-cycle-a"],
    run=project => Ok(project),
  )
  match @project.register_pass(cycle_a) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_pass(cycle_b) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.resolve_passes(["unit-cycle-a"]) is Err(_))
}

///|
test "run_once passes skip after a successful run and record counts" {
  let pass = @project.ProjectPass::create(name="unit-run-once", run_once=true, run=project => {
    let value = match project.get("once-hit") {
      Some(text) => text + "x"
      None => "x"
    }
    Ok(project.set("once-hit", value))
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let first = match project.run_pass("unit-run-once") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(first.get("once-hit") == Some("x"))
  assert_true(first.pass_has_run("unit-run-once"))
  assert_true(first.pass_run_count("unit-run-once") == 1)
  let second = match first.run_pass("unit-run-once") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(second.get("once-hit") == Some("x"))
  assert_true(second.pass_run_count("unit-run-once") == 1)
}

///|
test "regular passes record each successful execution" {
  let pass = @project.ProjectPass::create(name="unit-run-many", run=project => {
    let value = match project.get("many-hit") {
      Some(text) => text + "x"
      None => "x"
    }
    Ok(project.set("many-hit", value))
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let first = match project.run_pass("unit-run-many") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  let second = match first.run_pass("unit-run-many") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(second.get("many-hit") == Some("xx"))
  assert_true(second.pass_run_count("unit-run-many") == 2)
}
