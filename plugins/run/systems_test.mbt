///|
test "run reports systems with unresolved components" {
  let proj = fixture_project()
  @run.register(@run.Params::new()) |> ignore
  @primus.System::register(
    @primus.System::define_("run-test-broken", components=[
      @primus.System::component("run-test-no-such-component"),
    ]),
  ) catch {
    _ => ()
  }
  try @run.run(@run.Params::new(systems=["user:run-test-broken"]), proj) catch {
    e =>
      inspect(
        @bap_main.error_to_string(e),
        content=(
          #|Invalid system user:run-test-broken: failed to find a component run-test-no-such-component required for system run-test-broken
        ),
      )
  } noraise {
    _ => fail("expected a failure")
  }
}
