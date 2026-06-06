///|
fn pass_event_names(events : Array[@project.ProjectPassEvent]) -> Array[String] {
  events.map(event => event.pass_name())
}

///|
fn pass_event_kinds(events : Array[@project.ProjectPassEvent]) -> Array[String] {
  events.map(event => event.kind().to_string())
}

///|
fn pass_names(passes : Array[@project.ProjectPass]) -> Array[String] {
  passes.map(pass => pass.name())
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
test "project passes preserve registration order" {
  let z = @project.ProjectPass::create(name="unit-order-z", run=project => {
    Ok(project)
  })
  let a = @project.ProjectPass::create(name="unit-order-a", run=project => {
    Ok(project)
  })
  let m = @project.ProjectPass::create(name="unit-order-m", run=project => {
    Ok(project)
  })
  for pass in [z, a, m] {
    match @project.register_pass(pass) {
      Ok(_) => ()
      Err(reason) => fail(reason)
    }
  }
  let names = pass_names(@project.passes()).filter(name => {
    name.has_prefix("unit-order-")
  })
  assert_true(names == ["unit-order-z", "unit-order-a", "unit-order-m"])
}

///|
test "autorun passes follow registration order" {
  let first = @project.ProjectPass::create(
    name="unit-autorun-order-z",
    autorun=true,
    run=project => {
      let value = match project.get("autorun-order") {
        Some(text) => text
        None => ""
      }
      Ok(project.set("autorun-order", value + "z"))
    },
  )
  let second = @project.ProjectPass::create(
    name="unit-autorun-order-a",
    autorun=true,
    run=project => {
      let value = match project.get("autorun-order") {
        Some(text) => text
        None => ""
      }
      Ok(project.set("autorun-order", value + "a"))
    },
  )
  match @project.register_pass(first) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_pass(second) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let next = match project.run_autorun_passes() {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(next.get("autorun-order") == Some("za"))
}

///|
test "register_pass_prime registers side-effect-only passes" {
  let hits = Ref(0)
  match
    @project.register_pass_prime(name="unit-pass-prime", run=project => {
      if project.get("kept") == Some("yes") {
        hits.val += 1
        Ok(())
      } else {
        Err("expected original project")
      }
    }) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let project = @project.Project::empty(@core_theory.Target::unknown()).set(
    "kept", "yes",
  )
  let next = match project.run_pass("unit-pass-prime") {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(hits.val == 1)
  assert_true(next.get("kept") == Some("yes"))
  assert_true(next.pass_run_count("unit-pass-prime") == 1)
}

///|
test "register_pass_transform registers project-updating passes" {
  match
    @project.register_pass_transform(
      name="unit-pass-transform-dep",
      run_once=true,
      run=project => Ok(project.set("transform-dep", "yes")),
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @project.register_pass_transform(
      name="unit-pass-transform-main",
      autorun=true,
      deps=["unit-pass-transform-dep"],
      run=project => {
        if project.get("transform-dep") == Some("yes") {
          Ok(project.set("transform-main", "yes"))
        } else {
          Err("dependency did not run")
        }
      },
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let pass = match @project.find_pass("unit-pass-transform-main") {
    Some(pass) => pass
    None => fail("expected transform pass registration")
  }
  assert_true(pass.autorun())
  assert_true(pass.run_once())
  assert_true(pass.deps() == ["unit-pass-transform-dep"])
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let next = match project.run_autorun_passes() {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  assert_true(next.get("transform-dep") == Some("yes"))
  assert_true(next.get("transform-main") == Some("yes"))
  assert_true(next.pass_run_count("unit-pass-transform-dep") == 1)
  assert_true(next.pass_run_count("unit-pass-transform-main") == 1)
  assert_true(
    @project.register_pass_transform(name="unit-pass-transform-main", run=project => {
      Ok(project)
    })
    is Err(_),
  )
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
test "project pass run executes pass object with dependencies" {
  let dep = @project.ProjectPass::create(name="unit-object-dep", run=project => {
    Ok(project.set("object-trace", "d"))
  })
  match @project.register_pass(dep) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let pass = @project.ProjectPass::create(
    name="unit-object-main",
    deps=["unit-object-dep"],
    run=project => {
      Ok(
        project.set("object-trace", project.get("object-trace").unwrap() + "m"),
      )
    },
  )
  assert_true(@project.find_pass("unit-object-main") is None)
  let project = @project.Project::empty(@core_theory.Target::unknown())
  let next = match pass.run(project) {
    Ok(next) => next
    Err(error) => fail(error.to_string())
  }
  assert_true(next.get("object-trace") == Some("dm"))
  assert_true(next.pass_run_count("unit-object-dep") == 1)
  assert_true(next.pass_run_count("unit-object-main") == 1)
  assert_true(
    pass_event_kinds(dep.events()) ==
    ["registered", "started", "succeeded", "finished"],
  )
  assert_true(
    pass_event_kinds(pass.events()) == ["started", "succeeded", "finished"],
  )
}

///|
test "project pass run reports structured errors" {
  let missing = @project.ProjectPass::create(
    name="unit-structured-missing",
    deps=["unit-structured-absent"],
    run=project => Ok(project),
  )
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match missing.run(project) {
    Err(error) => {
      assert_true(error.pass().name() == "unit-structured-missing")
      assert_true(error.dependency() == Some("unit-structured-absent"))
      assert_true(error.reason() == "unit-structured-absent")
      assert_true(error.to_string().contains("unsatisfied dependency"))
    }
    Ok(_) => fail("expected missing dependency error")
  }
  let failing = @project.ProjectPass::create(name="unit-structured-runtime", run=_ => {
    Err("structured boom")
  })
  match failing.run(project) {
    Err(error) => {
      assert_true(error.pass().name() == "unit-structured-runtime")
      assert_true(error.dependency() is None)
      assert_true(error.reason() == "structured boom")
      assert_true(error.to_string().contains("runtime error"))
    }
    Ok(_) => fail("expected runtime error")
  }
}

///|
test "project pass run_exn mirrors checked execution" {
  let pass = @project.ProjectPass::create(name="unit-run-exn-success", run=project => {
    Ok(project.set("run-exn", "ok"))
  })
  let project = @project.Project::empty(@core_theory.Target::unknown())
  try {
    let next = pass.run_exn(project)
    assert_true(next.get("run-exn") == Some("ok"))
    assert_true(next.pass_run_count("unit-run-exn-success") == 1)
  } catch {
    @project.ProjectPassFailure(reason) => fail(reason)
    _ => fail("unexpected project pass exception")
  }
  let failing = @project.ProjectPass::create(name="unit-run-exn-failure", run=_ => {
    Err("run-exn boom")
  })
  try {
    let _ = failing.run_exn(project)
    fail("unexpected run_exn success")
  } catch {
    @project.ProjectPassFailure(reason) => {
      assert_true(reason.contains("unit-run-exn-failure"))
      assert_true(reason.contains("run-exn boom"))
    }
    _ => fail("unexpected project pass exception")
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
  let registrations = @project.pass_registration_events().filter(event => {
    event.pass_name() == "unit-events-registration"
  })
  assert_true(pass_event_names(registrations) == ["unit-events-registration"])
  assert_true(pass_event_kinds(registrations) == ["registered"])
  assert_true(registrations[0].sequence() > 0)
  assert_true(pass_event_kinds(pass.events()) == ["registered"])
}

///|
test "pass registrations stream registered pass objects" {
  let names = []
  let stream = @project.pass_registrations()
  let id = stream.subscribe(pass => names.push(pass.name()))
  let pass = @project.ProjectPass::create(
    name="unit-events-registration-stream",
    run=project => Ok(project),
  )
  match @project.register_pass(pass) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  stream.unsubscribe(id)
  assert_true(names == ["unit-events-registration-stream"])
}

///|
test "successful passes record start success and finish events" {
  let pass = @project.ProjectPass::create(name="unit-events-success", run=project => {
    Ok(project.set("events", "ok"))
  })
  let starts = []
  let successes = []
  let failures = []
  let finishes = []
  let start_id = pass.starts().subscribe(time => starts.push(time))
  let success_id = pass.successes().subscribe(time => successes.push(time))
  let failure_id = pass.failures().subscribe(time => failures.push(time))
  let finish_id = pass.finishes().subscribe(time => finishes.push(time))
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
  pass.starts().unsubscribe(start_id)
  pass.successes().unsubscribe(success_id)
  pass.failures().unsubscribe(failure_id)
  pass.finishes().unsubscribe(finish_id)
  assert_true(pass_event_names(pass.start_events()) == ["unit-events-success"])
  assert_true(
    pass_event_names(pass.success_events()) == ["unit-events-success"],
  )
  assert_true(pass.failure_events().is_empty())
  assert_true(pass_event_names(pass.finish_events()) == ["unit-events-success"])
  assert_true(starts.length() == 1)
  assert_true(successes.length() == 1)
  assert_true(failures.is_empty())
  assert_true(finishes.length() == 1)
  assert_true(starts[0] < successes[0])
  assert_true(successes[0] < finishes[0])
}

///|
test "failing passes record failure finish and no successful run count" {
  let pass = @project.ProjectPass::create(name="unit-events-failure", run=_ => {
    Err("boom")
  })
  let starts = []
  let successes = []
  let failures = []
  let finishes = []
  let start_id = pass.starts().subscribe(time => starts.push(time))
  let success_id = pass.successes().subscribe(time => successes.push(time))
  let failure_id = pass.failures().subscribe(time => failures.push(time))
  let finish_id = pass.finishes().subscribe(time => finishes.push(time))
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
  pass.starts().unsubscribe(start_id)
  pass.successes().unsubscribe(success_id)
  pass.failures().unsubscribe(failure_id)
  pass.finishes().unsubscribe(finish_id)
  assert_true(pass.success_events().is_empty())
  assert_true(
    pass_event_names(pass.failure_events()) == ["unit-events-failure"],
  )
  assert_true(pass_event_names(pass.finish_events()) == ["unit-events-failure"])
  assert_true(starts.length() == 1)
  assert_true(successes.is_empty())
  assert_true(failures.length() == 1)
  assert_true(finishes.length() == 1)
  assert_true(starts[0] < failures[0])
  assert_true(failures[0] < finishes[0])
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
  assert_true(pass.start_events().length() == 1)
  assert_true(pass.success_events().length() == 1)
  assert_true(pass.finish_events().length() == 1)
}
