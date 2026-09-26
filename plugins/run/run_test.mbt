///|
fn fixture_project() -> @project.Project raise {
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  @project.register_builtin_services() |> ignore
  @disassemble.create_and_process("bin/true", out=_ => ())
}

///|
let entered : Array[String] = []

///|
fn setup() -> Unit {
  if entered.is_empty() {
    @primus.Machine::add_component(m => {
      m.observe(@primus.enter_sub, sub => entered.push(sub.sub_name()))
    })
  }
  entered.clear()
  entered.push("<start>")
}

///|
test "parse entry points" {
  let proj = fixture_project()
  debug_inspect(
    @run.parse_entry_points(proj, ["main", "0x401000", "%00000001"]).map(n => {
      n.to_string()
    }),
    content=(
      #|["main", "0x0000000000401000", "%1"]
    ),
  )
  debug_inspect(
    @run.parse_entry_points(proj, []).map(n => n.to_string()),
    content=(
      #|["@bin/true:main"]
    ),
  )
  debug_inspect(
    @run.parse_entry_points(proj, ["only-queue"]).map(n => n.to_string()),
    content="[]",
  )
  inspect(
    @run.parse_entry_points(proj, ["all-subroutines"]).length(),
    content=(
      #|2
    ),
  )
}

///|
test "run executes the entry points with Primus" {
  setup()
  let proj = fixture_project()
  @run.run(@run.Params::new(entry=["main"]), proj) |> ignore
  debug_inspect(
    entered,
    content=(
      #|["<start>", "main"]
    ),
  )
  setup()
  @run.run(@run.Params::new(entry=["foo", "main"], in_isolation=true), proj)
  |> ignore
  debug_inspect(
    entered,
    content=(
      #|["<start>", "foo", "main"]
    ),
  )
}

///|
test "run reports unknown systems" {
  let proj = fixture_project()
  @run.register(@run.Params::new()) |> ignore
  try @run.run(@run.Params::new(systems=["user:nope"]), proj) catch {
    e =>
      inspect(
        @bap_main.error_to_string(e),
        content=(
          #|Unknown system: user:nope
        ),
      )
  } noraise {
    _ => fail("expected a failure")
  }
}

///|
test "the run pass is declared in bap_main" {
  @bap_main.reset()
  @run.declare_plugin()
  @bap_main.initialize(argv=["bap", "--run-entry-points=main,foo"])
  @bap_main.reset()
  setup()
  let proj = fixture_project()
  match @project.find_pass("run") {
    Some(pass) =>
      match pass.run(proj) {
        Ok(_) => ()
        Err(e) => fail(e.to_string())
      }
    None => fail("the pass is not registered")
  }
  debug_inspect(
    entered,
    content=(
      #|["<start>", "main"]
    ),
  )
}
