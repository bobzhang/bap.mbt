///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
/// A subroutine `main` with a chain of `n` blocks named `b0`...
fn chain(n : Int) -> (@types.Term[@types.Sub], Map[@types.Tid, String]) {
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
/// Resumes another live machine when a machine finishes.
fn resume_other(m : @primus.Machine) -> Unit raise {
  let others = m.forks().filter(id => id != m.current())
  if others.last() is Some(id) {
    m.kill(m.current())
    m.switch(id)
  }
}

///|
fn run_wandering(seed : Int) -> Array[String] raise {
  let (main, names) = chain(5)
  let log = []
  let (status, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_wandering.install(m, seed~)
      m.observe(@primus.enter_blk, b => {
        log.push("\{m.current()}:\{names.get(b.tid()).unwrap()}")
      })
    },
    start=m => {
      m.fork()
      @primus.Linker::schedule_exec(m, Symbol("main"))
    },
    fini=resume_other,
  )
  assert_true(status is Normal)
  log
}

///|
test "the wandering scheduler interleaves machines pseudo-randomly" {
  let log = run_wandering(0)
  debug_inspect(
    log,
    content=(
      #|[
      #|  "1:b0",
      #|  "0:b0",
      #|  "1:b1",
      #|  "1:b2",
      #|  "0:b1",
      #|  "0:b2",
      #|  "1:b3",
      #|  "0:b3",
      #|  "0:b4",
      #|  "1:b4",
      #|]
    ),
  )
  // deterministic for a given seed
  assert_eq(run_wandering(0), log)
  // every machine runs its path to completion
  assert_eq(log.filter(x => x.has_suffix(":b4")).length(), 2)
  assert_eq(log.length(), 10)
}

///|
test "the wandering scheduler registers its component once" {
  assert_true(@primus_wandering.register(seed=7))
  assert_false(@primus_wandering.register())
}
