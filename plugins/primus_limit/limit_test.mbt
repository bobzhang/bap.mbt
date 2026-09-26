///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn int64(n : Int) -> @types.Exp {
  Int(try! @types.Word::of_int(width=64, n))
}

///|
/// `main` sets `i` to zero and then increments it in an infinite loop.
fn infinite_loop(i : @types.Var) -> (@types.Term[@types.Sub], @types.Tid) {
  let tid = @types.Tid::create()
  let body = @types.Blk::create(
    tid~,
    defs=[@types.Def::create(i, BinOp(Plus, Var(i), int64(1)))],
    jmps=[@types.Jmp::create_goto(Direct(tid))],
  )
  let entry = @types.Blk::create(defs=[@types.Def::create(i, int64(0))], jmps=[
    @types.Jmp::create_goto(Direct(tid)),
  ])
  (@types.Sub::create(name="main", blks=[entry, body]), tid)
}

///|
fn run_loop(
  max_length? : @primus_limit.Bound,
  max_visited? : Int,
) -> (@primus.ExitStatus, Int, Int) {
  let i = @types.Var::create("i", Imm(64))
  let (main, _) = infinite_loop(i)
  let result = Ref(-1)
  let length = Ref(-1)
  let (status, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_limit.install(m, max_length?, max_visited?)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      result.val = (try! @primus.Env::get(m, i).to_word().to_uint64()).to_int()
      length.val = @primus_limit.length(m)
    },
  )
  (status, result.val, length.val)
}

///|
test "bounds are parsed with an optional counter suffix" {
  debug_inspect(
    [
      @primus_limit.Bound::parse("10"),
      @primus_limit.Bound::parse("10b"),
      @primus_limit.Bound::parse("3i"),
      @primus_limit.Bound::parse("4t"),
      @primus_limit.Bound::parse("5e"),
      @primus_limit.Bound::parse("6c"),
    ],
    content=(
      #|[
      #|  { counter: Clk, limit: 10 },
      #|  { counter: Blk, limit: 10 },
      #|  { counter: Insn, limit: 3 },
      #|  { counter: Term, limit: 4 },
      #|  { counter: Exp, limit: 5 },
      #|  { counter: Clk, limit: 6 },
      #|]
    ),
  )
  inspect(@primus_limit.default_bound.to_string(), content="32768")
  inspect(@primus_limit.Bound::parse("4t").to_string(), content="4t")
  let err = try @primus_limit.Bound::parse("lots") catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
  inspect(
    err,
    content=(
      #|Expected a number, got lots
    ),
  )
}

///|
test "the block counter halts an infinite loop" {
  let (status, i, length) = run_loop(
    max_length=@primus_limit.Bound::parse("10b"),
  )
  inspect(status, content="Exn(Halt)")
  // entry + 11 loop iterations are entered, the 12th entry is stopped
  inspect(
    i,
    content=(
      #|10
    ),
  )
  inspect(
    length,
    content=(
      #|11
    ),
  )
}

///|
test "the visits counter halts a loop" {
  let (status, i, _) = run_loop(max_visited=3)
  inspect(status, content="Exn(Halt)")
  inspect(
    i,
    content=(
      #|4
    ),
  )
}

///|
test "the default clock bound halts an infinite loop" {
  let (status, i, length) = run_loop()
  inspect(status, content="Exn(Halt)")
  inspect(
    i,
    content=(
      #|32769
    ),
  )
  inspect(
    length,
    content=(
      #|32769
    ),
  )
}

///|
test "the term counter" {
  let (status, i, length) = run_loop(
    max_length=@primus_limit.Bound::parse("20t"),
  )
  inspect(status, content="Exn(Halt)")
  inspect(
    i,
    content=(
      #|6
    ),
  )
  inspect(
    length,
    content=(
      #|21
    ),
  )
}

///|
test "limits are configured by the plugin parameters" {
  @bap_main.reset()
  @primus_limit.declare_plugin()
  @bap_main.initialize(argv=["bap", "--primus-limit-max-length=7b"])
  let i = @types.Var::create("i", Imm(64))
  let (main, _) = infinite_loop(i)
  let result = Ref(-1)
  let (status, _) = @primus.Machine::run_main(project([main]), m => {
    // the cleanup runs when the halting exception unwinds the stack
    m.push_cleanup(m => {
      result.val = (try! @primus.Env::get(m, i).to_word().to_uint64()).to_int()
    })
    @primus.Linker::schedule_exec(m, Symbol("main"))
  })
  inspect(status, content="Exn(Halt)")
  inspect(
    result.val,
    content=(
      #|7
    ),
  )
  assert_false(@primus_limit.register())
  @bap_main.reset()
}
