///|
fn int64(n : Int32) -> @types.Exp {
  Int(try! @types.Word::of_int(width=64, n))
}

///|
let x : @types.Var = @types.Var::create("x", Imm(64))

///|
let r : @types.Var = @types.Var::create("r", Imm(64))

///|
/// `main` branches on `x == 0` to `b1` (taken) or `b2`; `stub` is a
/// subroutine that is never called directly.
fn program() -> @types.Term[@types.Program] {
  let b1 = @types.Blk::create(defs=[@types.Def::create(r, int64(1))])
  let b2 = @types.Blk::create(defs=[@types.Def::create(r, int64(2))])
  let b0 = @types.Blk::create(jmps=[
    @types.Jmp::create_goto(Direct(b1.tid()), cond=BinOp(Eq, Var(x), int64(0))),
    @types.Jmp::create_goto(Direct(b2.tid())),
  ])
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2])
  let stub = @types.Sub::create(name="stub", blks=[
    @types.Blk::create(defs=[@types.Def::create(r, int64(3))]),
  ])
  @types.Program::create(subs=[main, stub])
}

///|
fn describe(prog : @types.Term[@types.Program]) -> Array[String] {
  let out = []
  for sub in prog.subs() {
    for i, blk in sub.blks() {
      let mark = (visited : Bool, dead : Bool) => {
        match (visited, dead) {
          (true, false) => "visited"
          (false, true) => "dead"
          (false, false) => "-"
          (true, true) => "visited+dead"
        }
      }
      let defs = blk
        .defs()
        .map(d => mark(d.is_visited(), d.is_dead()))
        .join(",")
      out.push(
        "\{@types.Sub::name(sub)}.b\{i}: \{mark(blk.is_visited(), blk.is_dead())} [\{defs}]",
      )
    }
  }
  out
}

///|
fn run(
  prog : @types.Term[@types.Program],
  start~ : (@primus.Machine) -> Unit raise = _ => (),
) -> (@types.Term[@types.Program], Array[(Int32, Int32)]) raise {
  let progress = []
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    prog,
  )
  let (status, proj) = @primus.Machine::run(
    proj,
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::set(
        m,
        x,
        @primus.Value::of_word(m, try! @types.Word::of_int(width=64, 0)),
      )
      @primus_track_visited.install(m)
      m.observe(@primus_track_visited.progress, p => progress.push(p))
    },
    start=m => {
      start(m)
      @primus.Linker::schedule_exec(m, Symbol("main"))
    },
  )
  assert_true(status is Normal)
  (proj.program(), progress)
}

///|
test "visited blocks are marked as visited and the others as dead" {
  let (prog, progress) = run(program())
  debug_inspect(
    describe(prog),
    content=(
      #|[
      #|  "main.b0: visited []",
      #|  "main.b1: visited [visited]",
      #|  "main.b2: dead [dead]",
      #|  "stub.b0: dead [dead]",
      #|]
    ),
  )
  debug_inspect(
    progress,
    content=(
      #|[(1, 4), (2, 4)]
    ),
  )
  // a second run keeps the marks and starts with the visited blocks
  let (prog2, progress2) = run(prog)
  assert_eq(describe(prog2), describe(prog))
  debug_inspect(
    progress2,
    content=(
      #|[(2, 4), (2, 4)]
    ),
  )
}

///|
test "calls of stubs mark the whole stubbed subroutine as visited" {
  let (prog, _) = run(program(), start=m => {
    m.make(@primus.lisp_call_entered, ("stub", []))
  })
  debug_inspect(
    describe(prog),
    content=(
      #|[
      #|  "main.b0: visited []",
      #|  "main.b1: visited [visited]",
      #|  "main.b2: dead [dead]",
      #|  "stub.b0: visited [visited]",
      #|]
    ),
  )
}

///|
test "the online interface to the visited set" {
  let prog = program()
  let main = prog.subs()[0]
  let b2 = main.blks()[2].tid()
  let log = []
  let (_, _) = @primus.Machine::run(
    @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog),
    start=m => {
      log.push(@primus_track_visited.mem(m, b2))
      @primus_track_visited.add(m, b2)
      log.push(@primus_track_visited.mem(m, b2))
      log.push(@primus_track_visited.all(m).length() == 1)
      @primus_track_visited.del(m, b2)
      log.push(@primus_track_visited.mem(m, b2))
      log.push(@primus_track_visited.total(m) == 4)
    },
  )
  debug_inspect(
    log,
    content=(
      #|[false, true, true, false, true]
    ),
  )
  assert_true(@primus_track_visited.register())
  assert_false(@primus_track_visited.register())
}
