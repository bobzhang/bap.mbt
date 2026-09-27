///|
fn project() -> @project.Project {
  let prog = @types.Program::create(subs=[])
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn system(name : String) -> @primus.System {
  @primus.System::define_(name, components=[
    @primus.System::component(@primus_greedy.component_name, pkg="bap"),
  ])
}

///|
test "the greedy scheduler explores forks depth-first and kills finished machines" {
  @primus_greedy.register() |> ignore
  assert_false(@primus_greedy.register())
  let log = []
  let killed = []
  let (status, _) = system("greedy-test-dfs").run(
    project(),
    init=m => {
      m.observe(@primus.system_fini, _ => log.push("fini \{m.current()}"))
      m.observe(@primus.machine_kill, id => killed.push(id.to_string()))
      m.observe(@primus.machine_switch, p => log.push("switch \{p.0}->\{p.1}"))
    },
    start=m => {
      m.fork(then=m => log.push("run \{m.current()}"))
      m.fork(then=m => log.push("run \{m.current()}"))
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "run 1",
      #|  "run 2",
      #|  "fini 2",
      #|  "switch 2->1",
      #|  "run 1",
      #|  "fini 1",
      #|  "switch 1->0",
      #|  "run 0",
      #|  "run 3",
      #|  "fini 3",
      #|  "switch 3->0",
      #|  "run 0",
      #|  "fini 0",
      #|  "switch 0->0",
      #|]
    ),
  )
  debug_inspect(
    killed,
    content=(
      #|["2", "1", "3"]
    ),
  )
}
