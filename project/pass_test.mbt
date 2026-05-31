///|
fn pass_event_names(events : Array[@project.ProjectPassEvent]) -> Array[String] {
  events.map(event => event.pass_name())
}

///|
fn pass_event_kinds(events : Array[@project.ProjectPassEvent]) -> Array[String] {
  events.map(event => event.kind().to_string())
}

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
test "autorun passes default to run once like BAP" {
  let pass = @project.ProjectPass::create(
    name="unit-autorun-once-default",
    autorun=true,
    run=project => {
      let value = match project.get("auto-once") {
        Some(text) => text + "x"
        None => "x"
      }
      Ok(project.set("auto-once", value))
    },
  )
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(pass.autorun())
  assert_true(pass.run_once())
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let first = match project.run_autorun_passes() {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  let second = match first.run_autorun_passes() {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(second.get("auto-once") == Some("x"))
  assert_true(second.pass_run_count("unit-autorun-once-default") == 1)
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

///|
test "pass registrations are observable lifecycle events" {
  let pass = @project.ProjectPass::create(name="unit-events-registration", run=project => {
    Ok(project)
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let registrations = @project.pass_registrations().filter(event => {
    event.pass_name() == "unit-events-registration"
  })
  assert_true(pass_event_names(registrations) == ["unit-events-registration"])
  assert_true(pass_event_kinds(registrations) == ["registered"])
  assert_true(registrations[0].sequence() > 0)
  assert_true(pass_event_kinds(pass.events()) == ["registered"])
}

///|
test "successful passes record start success and finish events" {
  let pass = @project.ProjectPass::create(name="unit-events-success", run=project => {
    Ok(project.set("events", "ok"))
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let next = match project.run_pass("unit-events-success") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(next.get("events") == Some("ok"))
  assert_true(
    pass_event_kinds(pass.events()) ==
    ["registered", "started", "succeeded", "finished"],
  )
  assert_true(pass_event_names(pass.starts()) == ["unit-events-success"])
  assert_true(pass_event_names(pass.successes()) == ["unit-events-success"])
  assert_true(pass.failures().is_empty())
  assert_true(pass_event_names(pass.finishes()) == ["unit-events-success"])
}

///|
test "failing passes record failure finish and no successful run count" {
  let pass = @project.ProjectPass::create(name="unit-events-failure", run=_ => {
    Err("boom")
  })
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  assert_true(project.run_pass("unit-events-failure") is Err(_))
  assert_true(project.pass_run_count("unit-events-failure") == 0)
  assert_true(
    pass_event_kinds(pass.events()) ==
    ["registered", "started", "failed", "finished"],
  )
  assert_true(pass.successes().is_empty())
  assert_true(pass_event_names(pass.failures()) == ["unit-events-failure"])
  assert_true(pass_event_names(pass.finishes()) == ["unit-events-failure"])
}

///|
test "run_once skipped passes do not emit lifecycle events" {
  let pass = @project.ProjectPass::create(
    name="unit-events-run-once",
    run_once=true,
    run=project => {
      let value = match project.get("events-once") {
        Some(text) => text + "x"
        None => "x"
      }
      Ok(project.set("events-once", value))
    },
  )
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let first = match project.run_pass("unit-events-run-once") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  let second = match first.run_pass("unit-events-run-once") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(second.get("events-once") == Some("x"))
  assert_true(second.pass_run_count("unit-events-run-once") == 1)
  assert_true(
    pass_event_kinds(pass.events()) ==
    ["registered", "started", "succeeded", "finished"],
  )
  assert_true(pass.starts().length() == 1)
  assert_true(pass.successes().length() == 1)
  assert_true(pass.finishes().length() == 1)
}
