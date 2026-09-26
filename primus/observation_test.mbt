///|
let test_stmt : @primus.Statement[Int] = @primus.Statement::provide(
  "test-observation",
  pkg="primus-test",
  inspect=n => Atom("n=\{n}"),
  desc="  A test\n   observation.  ",
)

///|
let test_obs : @primus.Observation[Int] = test_stmt.observation()

///|
test "observers are called newest first and can be cancelled" {
  let log = []
  let computed : Ref[Int] = { val: 0, }
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    // nobody observes yet: `post` does not compute the value
    m.post(test_stmt, () => {
      computed.val += 1
      0
    })
    let a = m.subscribe(test_obs, n => log.push("a\{n}"))
    m.observe(test_obs, n => log.push("b\{n}"))
    let w = m.watch(test_obs.provider(), s => log.push("watch \{s}"))
    m.make(test_stmt, 1)
    m.cancel(a)
    m.post(test_stmt, () => {
      computed.val += 1
      2
    })
    m.cancel(w)
    m.make(test_stmt, 3)
  })
  debug_inspect(
    log,
    content=(
      #|["b1", "a1", "watch n=1", "b2", "watch n=2", "b3"]
    ),
  )
  inspect(computed.val, content="1")
  let p = test_obs.provider()
  inspect(p.name(), content="primus-test:test-observation")
  inspect(
    p.desc(),
    content=(
      #|A test
      #|observation.
    ),
  )
  inspect(p.triggers(), content="4")
  inspect(test_obs.name(), content="primus-test:test-observation")
  inspect(
    @primus.Provider::find("pc-changed").map(p => p.name()).unwrap_or("?"),
    content="pc-changed",
  )
  assert_true(@primus.Observation::list().length() > 50)
}

///|
test "observations nested inside observers" {
  let log = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    m.observe(test_obs, n => {
      log.push("outer \{n}")
      if n > 0 {
        m.make(test_stmt, n - 1)
      }
      log.push("after \{n}")
    })
    m.make(test_stmt, 2)
  })
  debug_inspect(
    log,
    content=(
      #|["outer 2", "outer 1", "outer 0", "after 0", "after 1", "after 2"]
    ),
  )
}

///|
test "term, position and pc observations" {
  let x = reg("x")
  let d = def(x, int64(1)).set_attr(@types.Attr::address(w64(0x10)))
  let b = blk(defs=[d]).set_attr(@types.Attr::address(w64(0x10)))
  let main = sub("main", [b])
  let log = []
  let (_, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      m.observe(@primus.enter_sub, s => {
        log.push("enter-sub \{@types.Sub::name(s)}")
      })
      m.observe(@primus.leave_sub, s => {
        log.push("leave-sub \{@types.Sub::name(s)}")
      })
      m.observe(@primus.enter_blk, _ => log.push("enter-blk"))
      m.observe(@primus.leave_blk, _ => log.push("leave-blk"))
      m.observe(@primus.enter_def, _ => log.push("enter-def"))
      m.observe(@primus.leave_def, _ => log.push("leave-def"))
      m.observe(@primus.enter_pos, p => log.push("pos \{p.level_name()}"))
      m.observe(@primus.pc_change, a => log.push("pc \{word_int(a)}"))
      m.observe(@primus.writing, v => log.push("writing \{v.name()}"))
      m.observe(@primus.written, p => {
        log.push("written \{p.0.name()}=\{value_int(p.1)}")
      })
      m.observe(@primus.const_obs, v => log.push("const \{value_int(v)}"))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      log.push(
        "pc=\{word_int(@primus.Interpreter::pc(m))} pos=\{@primus.Interpreter::pos(m).level_name()}",
      )
    },
  )
  debug_inspect(
    log,
    content=(
      #|[
      #|  "pos sub",
      #|  "enter-sub main",
      #|  "pc 16",
      #|  "pos blk",
      #|  "enter-blk",
      #|  "pos def",
      #|  "enter-def",
      #|  "const 1",
      #|  "writing x",
      #|  "written x=1",
      #|  "leave-def",
      #|  "leave-blk",
      #|  "leave-sub main",
      #|  "pc=16 pos=def",
      #|]
    ),
  )
}

///|
test "binop observations and the clock" {
  let x = reg("x")
  let main = sub("main", [
    blk(defs=[def(x, BinOp(Plus, int64(2), BinOp(Times, int64(3), int64(4))))]),
  ])
  let ops = []
  let clocks = []
  let (_, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      m.observe(@primus.binop, p => {
        let ((op, a, b), r) = p
        ops.push(
          "\{op.to_string()} \{value_int(a)} \{value_int(b)} = \{value_int(r)}",
        )
      })
      m.observe(@primus.clock, t => clocks.push(t))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => clocks.push(@primus.Interpreter::time(m)),
  )
  debug_inspect(
    ops,
    content=(
      #|["* 3 4 = 12", "+ 2 12 = 14"]
    ),
  )
  debug_inspect(clocks, content="[0, 1, 2]")
}

///|
test "exn_raised is observed before the exception propagates" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      m.observe(@primus.exn_raised, e => log.push(@primus.exn_to_string(e)))
    },
    start=m => @primus.Env::get(m, reg("nope")) |> ignore,
  )
  inspect(status_string(status), content="Exn(undefined variable `nope')")
  debug_inspect(
    log,
    content=(
      #|["undefined variable `nope'"]
    ),
  )
}
