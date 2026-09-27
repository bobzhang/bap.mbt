// End-to-end tests of the symbolic executor. They need the Z3 library
// (native target) and pass trivially without it.

///|
fn w64(n : Int) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn int64(n : Int) -> @types.Exp {
  Int(w64(n))
}

///|
fn goto(
  dst : @types.Term[@types.Blk],
  cond? : @types.Exp,
) -> @types.Term[@types.Jmp] {
  match cond {
    Some(c) => @types.Jmp::create_goto(Direct(dst.tid()), cond=c)
    None => @types.Jmp::create_goto(Direct(dst.tid()))
  }
}

///|
let x : @types.Var = @types.Var::create("x", Imm(64))

///|
let y : @types.Var = @types.Var::create("y", Imm(64))

///|
let r : @types.Var = @types.Var::create("r", Imm(64))

///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn word_of(m : @primus.Machine, v : @types.Var) -> String {
  if @primus.Env::is_set(m, v) {
    (try! @primus.Env::get(m, v).to_word().to_uint64()).to_string()
  } else {
    "unset"
  }
}

///|
fn symbolic_system() -> @primus.System {
  @primus_symbolic_executor.register() |> ignore
  @primus_greedy.register() |> ignore
  @primus_track_visited.register() |> ignore
  let names = @primus_symbolic_executor.components +
    ["greedy-scheduler", "mark-visited"]
  @primus.System::define_(
    "symbolic-test",
    pkg="test",
    components=names.map(n => @primus.System::component(n, pkg="bap")),
  )
}

///|
/// Runs `main` in a symbolic executor system where `x` and `y` are inputs
/// (generated, initially zero) and returns the log of the finished
/// machines.
fn explore(
  subs : Array[@types.Term[@types.Sub]],
  report : (@primus.Machine) -> String,
) -> (Array[String], Array[String]) {
  @primus_symbolic_executor.set_timeout(10000)
  let log = []
  let debug = []
  let (_, _) = try! symbolic_system().run(
    project(subs),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::add(m, x, @primus.Generator::static_value(width=64, 0))
      @primus.Env::add(m, y, @primus.Generator::static_value(width=64, 0))
      m.observe(@primus_symbolic_executor.executor_debug, s => debug.push(s))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => if @primus.Env::is_set(m, r) { log.push(report(m)) },
  )
  (log, debug)
}

///|
test "both sides of an input-dependent branch are explored" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  // if (x == 42) r = 1 else r = 2
  let b1 = @types.Blk::create(defs=[@types.Def::create(r, int64(1))])
  let b2 = @types.Blk::create(defs=[@types.Def::create(r, int64(2))])
  let c = @types.Var::create("c", Imm(1))
  let b0 = @types.Blk::create(
    defs=[@types.Def::create(c, BinOp(Eq, Var(x), int64(42)))],
    jmps=[goto(b1, cond=Var(c)), goto(b2)],
  )
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2])
  let (log, debug) = explore([main], m => {
    "\{m.current()}: x=\{word_of(m, x)} r=\{word_of(m, r)}"
  })
  // the first machine runs with the generated input, the second one with
  // the input generated from the model of `x == 42`
  debug_inspect(
    log,
    content=(
      #|["1: x=0 r=2", "2: x=42 r=1"]
    ),
  )
  debug_inspect(
    debug,
    content=(
      #|[
      #|  "0: starting the master process with pid 0",
      #|  "1: the first fork returns at 1",
      #|  "0: the first fork returns at 0",
      #|  "0: We have some tasks",
      #|  "2: Forked a new machine",
      #|  "2: SAT",
      #|  "2: x = #x000000000000002a",
      #|  "0: Client is finished, master is resumed",
      #|  "0: Worklist is empty, finishing",
      #|]
    ),
  )
}

///|
test "nested branches: models satisfy the constraints of the whole path" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  // if (x + y == 100) { if (x == 7) r = 3 else r = 2 } else r = 1
  let c = @types.Var::create("c", Imm(1))
  let d = @types.Var::create("d", Imm(1))
  let b2 = @types.Blk::create(defs=[@types.Def::create(r, int64(3))])
  let b3 = @types.Blk::create(defs=[@types.Def::create(r, int64(2))])
  let b4 = @types.Blk::create(defs=[@types.Def::create(r, int64(1))])
  let b1 = @types.Blk::create(
    defs=[@types.Def::create(d, BinOp(Eq, Var(x), int64(7)))],
    jmps=[goto(b2, cond=Var(d)), goto(b3)],
  )
  let b0 = @types.Blk::create(
    defs=[
      @types.Def::create(c, BinOp(Eq, BinOp(Plus, Var(x), Var(y)), int64(100))),
    ],
    jmps=[goto(b1, cond=Var(c)), goto(b4)],
  )
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2, b3, b4])
  let (log, _) = explore([main], m => {
    let xv = (try! @primus.Env::get(m, x).to_word().to_uint64()).to_int()
    let yv = (try! @primus.Env::get(m, y).to_word().to_uint64()).to_int()
    let rv = word_of(m, r)
    match rv {
      "3" => "r=3 x=\{xv} y=\{yv}"
      "2" => "r=2 x+y=\{(xv + yv) & 0xffff} x==7:\{xv == 7}"
      _ => "r=\{rv} x=\{xv} y=\{yv}"
    }
  })
  debug_inspect(
    log,
    content=(
      #|["r=1 x=0 y=0", "r=2 x+y=100 x==7:false", "r=3 x=7 y=93"]
    ),
  )
}

///|
test "the executor needs the solver" {
  if @primus_symbolic_executor.is_solver_available() {
    return
  }
  let (status, _) = @primus.Machine::run(project([]), init=m => {
    @primus_symbolic_executor.install_computer(m)
  })
  let msg = match status {
    Normal => "normal"
    Exn(e) => @primus.exn_to_string(e)
  }
  assert_true(msg.contains("SMT solver unavailable"))
}
