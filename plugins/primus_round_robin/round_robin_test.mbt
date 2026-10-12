///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
/// A subroutine `main` with a chain of `n` blocks named `b0`...
fn chain(n : Int32) -> (@types.Term[@types.Sub], Map[@types.Tid, String]) {
  let tids = Array::makei(n, _ => @types.Tid::create())
  let names = Map([])
  let blks = []
  for i, tid in tids {
    names[tid] = "b\{i}"
    let jmps = if i + 1 < n {
      [@types.Jmp::create_goto(Direct(tids[i + 1]))]
    } else {
      []
    }
    blks.push(@types.Blk::create(tid~, jmps~))
  }
  (@types.Sub::create(name="main", blks~), names)
}

///|
test "the round-robin scheduler switches machines after every block" {
  @primus_round_robin.register() |> ignore
  assert_false(@primus_round_robin.register())
  let (main, names) = chain(3)
  let sys = @primus.System::define_("round-robin-test", components=[
    @primus.System::component(@primus_round_robin.component_name, pkg="bap"),
    @primus.System::component("load-binary", pkg="bap"),
  ])
  let log = []
  let (status, _) = sys.run(
    project([main]),
    init=m => {
      m.observe(@primus.enter_blk, b => {
        log.push("\{m.current()}:\{names.get(b.tid()).unwrap()}")
      })
      m.observe(@primus.system_fini, _ => log.push("\{m.current()}:fini"))
    },
    fini=m => {
      if m.current() == @primus.Id::global() {
        debug_inspect(
          @primus_round_robin.finished(m),
          content="[Id(1), Id(2), Id(3)]",
        )
      }
    },
    start=m => {
      m.fork()
      m.fork()
      @primus.Linker::schedule_exec(m, Symbol("main"))
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "2:b0",
      #|  "3:b0",
      #|  "1:b0",
      #|  "2:b1",
      #|  "0:b0",
      #|  "1:b1",
      #|  "2:b2",
      #|  "3:b1",
      #|  "0:b1",
      #|  "1:b2",
      #|  "2:fini",
      #|  "3:b2",
      #|  "0:b2",
      #|  "1:fini",
      #|  "3:fini",
      #|  "0:fini",
      #|]
    ),
  )
}

///|
test "a single machine is not starved by the round-robin scheduler" {
  let (main, names) = chain(4)
  let sys = @primus.System::define_("round-robin-single", components=[
    @primus.System::component(@primus_round_robin.component_name, pkg="bap"),
    @primus.System::component("load-binary", pkg="bap"),
  ])
  @primus_round_robin.register() |> ignore
  let log = []
  let (status, _) = sys.run(
    project([main]),
    init=m => {
      m.observe(@primus.enter_blk, b => log.push(names.get(b.tid()).unwrap()))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["b0", "b1", "b2", "b3"]
    ),
  )
}
