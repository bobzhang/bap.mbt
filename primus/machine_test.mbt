///|
let counter_state : @primus.State[Int] = @primus.State::declare_(
  uuid="0f3c6f9e-2b7a-4a55-9d1e-6c2f1a7b8c90",
  name="test-counter",
  _ => 0,
)

///|
test "fork with a continuation runs in the child then in the parent" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      m.observe(@primus.machine_fork, p => log.push("fork \{p.0}->\{p.1}"))
      m.observe(@primus.machine_switch, p => log.push("switch \{p.0}->\{p.1}"))
      m.observe(@primus.machine_kill, id => log.push("kill \{id}"))
    },
    start=m => {
      let pid = m.current()
      m.put_local(counter_state, 10)
      m.fork(then=m => {
        if m.current() == pid {
          log.push("parent sees \{m.get_local(counter_state)}")
        } else {
          m.put_local(counter_state, 20)
          log.push("child sees \{m.get_local(counter_state)}")
        }
      })
      // the fork takes effect at the end of this step
      log.push("still \{m.current()}")
    },
    fini=m => {
      log.push("fini in \{m.current()}")
      // a greedy scheduler: when a fork finishes, resume its parent
      if m.current() != @primus.Id::global() {
        m.kill(m.current())
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "still 0",
      #|  "fork 0->1",
      #|  "child sees 20",
      #|  "fini in 1",
      #|  "kill 1",
      #|  "switch 1->0",
      #|  "parent sees 10",
      #|  "fini in 0",
      #|]
    ),
  )
}

///|
test "forks have isolated local state and shared global state" {
  let x = reg("x")
  let results = []
  let (_, _) = @primus.Machine::run(
    project([]),
    init=m => @primus.Env::set(m, x, @primus.Value::of_word(m, w64(1))),
    start=m => {
      m.put_global(counter_state, 1)
      m.fork(then=m => {
        if m.current() != @primus.Id::global() {
          @primus.Env::set(m, x, @primus.Value::of_word(m, w64(2)))
          @primus.Memory::allocate(m, w64(0x100), 1)
          @primus.Memory::store(m, w64(0x100), w8(0xAB))
          @primus.Linker::link(m, name="child-only", Host(_ => ()))
          m.update_global(counter_state, n => n + 10)
          m.switch(@primus.Id::global())
        } else {
          results.push("parent x=\{value_int(@primus.Env::get(m, x))}")
          results.push(
            "parent mapped=\{@primus.Memory::is_mapped(m, w64(0x100))}",
          )
          results.push("global=\{m.get_global(counter_state)}")
          results.push(
            "parent linked=\{@primus.Linker::is_linked(m, Symbol("child-only"))}",
          )
          let child = @primus.Id(1)
          results.push(
            "child x=\{value_int(@primus.Env::get(m, x))} status=\{m.status(child)}",
          )
        }
      })
    },
    fini=m => {
      if m.current() == @primus.Id::global() {
        // inspect the suspended child through `Other`
        let child = @primus.Id(1)
        if m.status(child) is Live {
          let env_seen = m.get_other(child, counter_state)
          results.push("other counter=\{env_seen}")
        }
      }
    },
  )
  debug_inspect(
    results,
    content=(
      #|[
      #|  "parent x=1",
      #|  "parent mapped=false",
      #|  "global=11",
      #|  "parent linked=false",
      #|  "child x=1 status=Live",
      #|  "other counter=0",
      #|]
    ),
  )
}

///|
test "fork during interpretation explores both branches" {
  // b0: if flag goto b1 else goto b2; the component forks on entering b0
  // and sets the flag in the child only.
  let flag = reg("flag")
  let r = reg("r")
  let b1 = blk(defs=[def(r, int64(1))])
  let b2 = blk(defs=[def(r, int64(2))])
  let b0 = blk(jmps=[goto(b1, cond=BinOp(Eq, Var(flag), int64(1))), goto(b2)])
  let outcomes = []
  let (status, _) = @primus.Machine::run(
    project([sub("main", [b0, b1, b2])]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::set(m, flag, @primus.Value::of_word(m, w64(0)))
      m.observe(@primus.enter_blk, b => {
        if b.tid() == b0.tid() && m.current() == @primus.Id::global() {
          let pid = m.current()
          m.fork(then=m => {
            if m.current() != pid {
              @primus.Env::set(m, flag, @primus.Value::of_word(m, w64(1)))
            }
          })
        }
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      outcomes.push(
        "machine \{m.current()}: r=\{value_int(@primus.Env::get(m, r))}",
      )
      if m.current() != @primus.Id::global() {
        m.kill(m.current())
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    outcomes,
    content=(
      #|["machine 1: r=1", "machine 0: r=2"]
    ),
  )
}

///|
test "switch continuations, forks listing and ancestry" {
  let log = []
  let (_, _) = @primus.Machine::run(
    project([]),
    start=m => {
      m.fork()
      m.schedule(m => {
        // in the child (1): fork again, creating 2
        log.push("in \{m.current()} parent=\{m.parent()}")
        m.fork(then=m => log.push("after fork in \{m.current()}"))
      })
    },
    fini=m => {
      log.push(
        "fini \{m.current()} forks=\{m.forks().map(x => x.to_string()).join(",")} ancestor=\{m.ancestor([@primus.Id(2), @primus.Id(1)])}",
      )
      match m.current().to_int() {
        2 => m.switch(@primus.Id(1), then=_ => log.push("resumed 2"))
        1 => m.switch(@primus.Id(2))
        _ => ()
      }
    },
  )
  debug_inspect(
    log,
    content=(
      #|[
      #|  "in 1 parent=0",
      #|  "after fork in 2",
      #|  "fini 2 forks=0,1,2 ancestor=0",
      #|  "after fork in 1",
      #|  "fini 1 forks=0,1,2 ancestor=0",
      #|  "resumed 2",
      #|]
    ),
  )
}

///|
test "kill another machine runs observers in its context" {
  let log = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    m.put_local(counter_state, 7)
    m.fork(then=m => {
      if m.current() != @primus.Id::global() {
        m.put_local(counter_state, 8)
        m.observe(@primus.machine_kill, id => {
          log.push(
            "killed \{id} in \{m.current()} counter=\{m.get_local(counter_state)}",
          )
          // observers of machine-kill run in the restricted mode
          m.fork() catch {
            e => log.push(@primus.exn_to_string(e))
          }
        })
        m.switch(@primus.Id::global())
      } else {
        m.kill(@primus.Id(1))
        log.push("status \{m.status(@primus.Id(1))}")
        m.kill(@primus.Id::global())
        log.push("global \{m.status(@primus.Id::global())}")
      }
    })
  })
  debug_inspect(
    log,
    content=(
      #|[
      #|  "killed 1 in 1 counter=8",
      #|  "fork in the restricted mode",
      #|  "status Dead",
      #|  "global Current",
      #|]
    ),
  )
}

///|
test "switching to a dead machine fails" {
  let (status, _) = @primus.Machine::run(project([]), start=m => {
    m.switch(@primus.Id(42))
  })
  inspect(status_string(status), content="Exn(machine 42 is not alive)")
}

///|
test "boot runs in the restricted mode" {
  let seen = []
  let (status, _) = @primus.Machine::run(
    project([]),
    boot=m => {
      m.observe(@primus.system_start, s => seen.push("start \{s}"))
      m.observe(@primus.system_stop, s => seen.push("stop \{s}"))
      m.observe(@primus.exn_raised, e => {
        seen.push("raised \{@primus.exn_to_string(e)}")
      })
      // observations are dropped in the restricted mode
      assert_true(m.is_restricted())
      m.fork() catch {
        e => seen.push(@primus.exn_to_string(e))
      }
    },
    start=m => @primus.Interpreter::halt(m),
    system="test-system",
  )
  inspect(status_string(status), content="Exn(Halt)")
  debug_inspect(
    seen,
    content=(
      #|[
      #|  "fork in the restricted mode",
      #|  "start test-system",
      #|  "raised Halt",
      #|  "stop test-system",
      #|]
    ),
  )
}

///|
test "exceptions in boot abort the run" {
  let (status, _) = @primus.Machine::run(project([]), boot=_ => {
    raise @primus.RuntimeError("boom")
  })
  inspect(
    status_string(status),
    content="Exn(Primus interpreter runtime error: boom)",
  )
}

///|
test "exception printers can be extended" {
  @primus.exn_add_printer(e => {
    match e {
      Failure(msg) => Some("custom: \{msg}")
      _ => None
    }
  })
  let (status, _) = @primus.Machine::run(project([]), start=_ => fail("oops"))
  inspect(status_string(status).has_prefix("Exn(custom: "), content="true")
}
