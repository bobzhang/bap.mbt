// Tests of the resumable (frame-based) execution model: calls with results,
// forks inside callees, suspension at observations, handlers and cleanups.

///|
fn val64(m : @primus.Machine, n : Int32) -> @primus.Value {
  @primus.Value::of_word(m, w64(n))
}

///|
fn opt_int(v : @primus.Value?) -> String {
  match v {
    Some(x) => value_int(x).to_string()
    None => "none"
  }
}

///|
/// kill the finished fork and resume the global machine (a greedy
/// scheduler)
fn resume_global(m : @primus.Machine) -> Unit raise {
  if m.current() != @primus.Id::global() &&
    m.status(@primus.Id::global()) is Live {
    m.kill(m.current())
    m.switch(@primus.Id::global())
  }
}

///|
test "resumable calls pass arguments and results" {
  let rdi = reg("RDI")
  let rax = reg("RAX")
  let a = reg("inc_a")
  let r = reg("inc_r")
  let inc = sub(
    "inc",
    args=[
      @types.Arg::create(a, Var(rdi), intent=In),
      @types.Arg::create(r, Var(rax), intent=Out),
    ],
    [blk(defs=[def(rax, BinOp(Plus, Var(a), int64(1)))])],
  )
  let log = []
  let (status, _) = @primus.Machine::run(
    project([inc]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Linker::link(
        m,
        name="twice",
        Host(m => {
          let x = m.call_args()[0]
          m.set_result(Some(val64(m, value_int(x).to_int() * 2)))
        }),
      )
    },
    start=m => {
      m.call(Symbol("twice"), args=[val64(m, 20)], then=(m, r) => {
        log.push("twice=\{opt_int(r)}")
        m.call(Symbol("inc"), args=[r.unwrap()], then=(m, r) => {
          log.push("inc=\{opt_int(r)}")
          // synchronous variant of the same protocol
          let s = @primus.Linker::call(m, Symbol("inc"), args=[val64(m, 1)])
          log.push("sync inc=\{opt_int(s)}")
        })
      })
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["twice=40", "inc=41", "sync inc=2"]
    ),
  )
}

///|
test "host code written as frames returns through the result register" {
  // a tiny "evaluator": (+ 1 (f 2)) where f is linked host code that
  // itself continues with frames before returning
  let log = []
  let (_, _) = @primus.Machine::run(
    project([]),
    init=m => {
      @primus.Linker::link(
        m,
        name="f",
        Host(m => {
          let x = m.call_args()[0]
          m.schedule(m => {
            log.push("f body")
            m.set_result(Some(val64(m, value_int(x).to_int() * 10)))
          })
        }),
      )
    },
    start=m => {
      m.call(Symbol("f"), args=[val64(m, 2)], then=(_, r) => {
        log.push("result \{value_int(r.unwrap()) + 1}")
      })
    },
  )
  debug_inspect(
    log,
    content=(
      #|["f body", "result 21"]
    ),
  )
}

///|
test "a fork inside a resumable callee continues the caller in both machines" {
  let flag = reg("flag")
  let ret = reg("ret")
  let out = reg("f_out")
  let body = blk(defs=[def(ret, BinOp(Plus, Var(flag), int64(10)))])
  let f = sub("f", args=[@types.Arg::create(out, Var(ret), intent=Out)], [body])
  let log = []
  let (status, _) = @primus.Machine::run(
    project([f]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::set(m, flag, val64(m, 0))
      m.observe(@primus.enter_blk, b => {
        if b.tid() == body.tid() && m.current() == @primus.Id::global() {
          m.fork(then=m => {
            if m.current() != @primus.Id::global() {
              @primus.Env::set(m, flag, val64(m, 1))
            }
          })
        }
      })
    },
    start=m => {
      m.call(Symbol("f"), then=(m, r) => {
        log.push("\{m.current()}: \{opt_int(r)}")
      })
    },
    fini=resume_global,
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["1: 11", "0: 10"]
    ),
  )
}

///|
test "an infinite callee yields to a round-robin scheduler" {
  let i = reg("i")
  let loop_tid = @types.Tid::create()
  let body = blk(tid=loop_tid, defs=[def(i, BinOp(Plus, Var(i), int64(1)))], jmps=[
    @types.Jmp::create_goto(Direct(loop_tid)),
  ])
  let spin = sub("spin", [body])
  let log = []
  let (status, _) = @primus.Machine::run(
    project([spin]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::set(m, i, val64(m, 0))
      m.observe(@primus.leave_blk, _ => {
        log.push("\{m.current()}:\{value_int(@primus.Env::get(m, i))}")
        if log.length() >= 6 {
          @primus.Interpreter::halt(m)
        }
        let other = if m.current() == @primus.Id::global() {
          @primus.Id(1)
        } else {
          @primus.Id::global()
        }
        m.switch(other)
      })
    },
    start=m => m.fork(then=m => m.call(Symbol("spin"), then=(_, _) => ())),
  )
  inspect(status_string(status), content="Exn(Halt)")
  debug_inspect(
    log,
    content=(
      #|["1:1", "0:1", "1:2", "0:2", "1:3", "0:3"]
    ),
  )
}

///|
test "handlers and cleanups are frames that survive forks" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project([]),
    start=m => {
      m.push_handler((m, e) => {
        log.push("handled \{m.current()}: \{@primus.exn_to_string(e)}")
      })
      m.push_cleanup(m => log.push("cleanup \{m.current()}"))
      m.schedule(m => {
        m.fork(then=m => raise @primus.RuntimeError("boom \{m.current()}"))
      })
    },
    fini=resume_global,
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "cleanup 1",
      #|  "handled 1: Primus interpreter runtime error: boom 1",
      #|  "cleanup 0",
      #|  "handled 0: Primus interpreter runtime error: boom 0",
      #|]
    ),
  )
  let log = []
  let (status, _) = @primus.Machine::run(project([]), start=m => {
    m.push_cleanup(_ => log.push("cleanup"))
    m.schedule(_ => log.push("body"))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["body", "cleanup"]
    ),
  )
}

///|
test "a leave-blk switch suspends before the jump and the remaining observers" {
  let b1 = blk()
  let ext_tid = @types.Tid::create()
  let b0 = blk(jmps=[
    @types.Jmp::create_call(
      @types.Call::create(target=Direct(ext_tid), return_label=Direct(b1.tid())),
    ),
  ])
  let main = sub("main", [b0, b1])
  let log = []
  let switched : Ref[Bool] = { val: false, }
  let (status, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Linker::link(
        m,
        name="ext",
        tid=ext_tid,
        Host(m => log.push("ext in \{m.current()}")),
      )
      // subscribed first, called last
      m.observe(@primus.leave_blk, b => {
        if b.tid() == b0.tid() {
          log.push("A in \{m.current()}")
        }
      })
      m.observe(@primus.leave_blk, b => {
        if b.tid() == b0.tid() && !switched.val {
          switched.val = true
          log.push("B switch")
          m.switch(@primus.Id::global(), then=_ => log.push("resumed"))
        }
      })
    },
    start=m => {
      m.fork(then=m => {
        if m.current() != @primus.Id::global() {
          @primus.Linker::schedule_exec(m, Symbol("main"))
        }
      })
    },
    fini=m => {
      log.push("fini \{m.current()}")
      if m.current() == @primus.Id::global() && m.status(@primus.Id(1)) is Live {
        log.push(
          "child at \{@primus.Interpreter::pos_of(m, @primus.Id(1)).level_name()}",
        )
        m.switch(@primus.Id(1))
      }
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "B switch",
      #|  "fini 0",
      #|  "child at jmp",
      #|  "resumed",
      #|  "A in 1",
      #|  "ext in 1",
      #|  "fini 1",
      #|]
    ),
  )
}

///|
test "requests are applied on behalf of the machine that issued them" {
  let log = []
  let forks = []
  let (_, _) = @primus.Machine::run(
    project([]),
    init=m => m.observe(@primus.machine_fork, p => forks.push("\{p.0}->\{p.1}")),
    start=m => {
      m.fork(then=m => {
        match m.current().to_int() {
          1 => m.switch(@primus.Id::global(), then=_ => log.push("1 resumed"))
          _ =>
            m.fork(then=m => {
              match m.current().to_int() {
                2 =>
                  m.switch(@primus.Id::global(), then=_ => log.push("2 resumed"))
                _ => {
                  log.push("0 issues")
                  m.switch(@primus.Id(1))
                  m.switch(@primus.Id(2))
                  log.push("0 after")
                }
              }
            })
        }
      })
    },
    fini=resume_global,
  )
  debug_inspect(
    log,
    content=(
      #|["0 issues", "0 after", "1 resumed", "2 resumed"]
    ),
  )
  debug_inspect(
    forks,
    content=(
      #|["0->1", "0->2"]
    ),
  )
}

///|
test "fork observers that fork are serialized" {
  let forks = []
  let (_, _) = @primus.Machine::run(
    project([]),
    init=m => {
      m.observe(@primus.machine_fork, p => {
        forks.push("\{p.0}->\{p.1} current=\{m.current()}")
        if forks.length() < 3 {
          m.fork()
        }
      })
    },
    start=m => m.fork(),
  )
  debug_inspect(
    forks,
    content=(
      #|["0->1 current=1", "1->2 current=2", "2->3 current=3"]
    ),
  )
}

///|
test "exceptions: dead switch targets, handlers and nested runs" {
  let log = []
  let (status, _) = @primus.Machine::run(project([]), start=m => {
    m.push_handler((_, e) => log.push("handled \{@primus.exn_to_string(e)}"))
    m.schedule(m => m.switch(@primus.Id(99)))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["handled machine 99 is not alive"]
    ),
  )
  let log = []
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      @primus.Linker::link(
        m,
        name="bad",
        Host(m => {
          m.schedule(_ => log.push("never"))
          raise @primus.RuntimeError("bad")
        }),
      )
      @primus.Linker::link(
        m,
        name="inner",
        Host(m => {
          m.push_handler((_, _) => log.push("inner handled"))
          m.schedule(_ => raise @primus.RuntimeError("x"))
        }),
      )
      @primus.Linker::link(m, name="good", Host(_ => log.push("good")))
    },
    start=m => {
      m.schedule(_ => log.push("outer frame"))
      let depth = m.stack_depth()
      @primus.Linker::exec(m, Symbol("bad")) catch {
        e => log.push("caught \{@primus.exn_to_string(e)}")
      }
      log.push("same depth \{m.stack_depth() == depth}")
      @primus.Linker::exec(m, Symbol("inner"))
      @primus.Linker::exec(m, Symbol("good"))
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "caught Primus interpreter runtime error: bad",
      #|  "same depth true",
      #|  "inner handled",
      #|  "good",
      #|  "outer frame",
      #|]
    ),
  )
}

///|
let array_state : @primus.State[Array[Int32]] = @primus.State::declare_(
  uuid="7c1d7c2e-5f4b-4b8e-9a61-2f3e4d5c6b7a",
  name="test-array-state",
  clone=a => a.copy(),
  _ => [],
)

///|
test "states with a clone policy are isolated after a fork" {
  let log = []
  let (_, _) = @primus.Machine::run(
    project([]),
    start=m => {
      m.put_local(array_state, [1])
      m.fork(then=m => {
        m.get_local(array_state).push(m.current().to_int() + 10)
        log.push(
          "\{m.current()}: \{m.get_local(array_state).length()} last=\{m.get_local(array_state)[1]}",
        )
      })
    },
    fini=resume_global,
  )
  debug_inspect(
    log,
    content=(
      #|["1: 2 last=11", "0: 2 last=10"]
    ),
  )
  let map = @primus.PersistentMap::empty().add(1, "a").add(2, "b")
  let map2 = map.remove(1)
  debug_inspect(
    (map.length(), map2.length(), map.get(1), map2.get(2)),
    content=(
      #|(2, 1, Some("a"), Some("b"))
    ),
  )
}

///|
test "a trap handler subroutine does not corrupt the caller position" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let w = reg("w")
  let handler = sub(@primus.division_by_zero_handler, [
    blk(defs=[def(y, int64(7))]),
  ])
  let b1_tid = @types.Tid::create()
  let b0 = blk(
    defs=[def(x, BinOp(Div, int64(1), int64(0))), def(z, int64(5))],
    jmps=[@types.Jmp::create_goto(Direct(b1_tid))],
  )
  let phi = @types.Phi::of_list(w, [
    (b0.tid(), int64(1)),
    (handler.payload().blks[0].tid(), int64(2)),
  ])
  let b1 = @types.Blk::create(tid=b1_tid, phis=[phi])
  let parents = []
  let (status, values) = run_main_sub(
    [sub("main", [b0, b1]), handler],
    [y, z, w],
    init=m => {
      m.observe(@primus.enter_pos, p => {
        match p {
          Blk(l) => parents.push(@types.Sub::name(l.up.me))
          _ => ()
        }
      })
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(7), Some(5), Some(1)]
    ),
  )
  debug_inspect(
    parents,
    content=(
      #|["main", "__primus_division_by_zero_handler", "main"]
    ),
  )
}

///|
test "memory region boundaries and permissions" {
  let log = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    // a one-cell allocation is initialized
    @primus.Memory::allocate(m, w64(0x10), 1, init=_ => w8(0x42))
    log.push("one cell: \{word_int(@primus.Memory::load(m, w64(0x10)))}")
    // the upper bound is inclusive
    @primus.Memory::add_region(m, lower=w64(0x20), upper=w64(0x22), init=a => {
      w8(word_int(a).to_int())
    })
    log.push("upper: \{word_int(@primus.Memory::load(m, w64(0x22)))}")
    log.push("past upper: \{@primus.Memory::is_mapped(m, w64(0x23))}")
    // a region wrapping around the end of the address space
    @primus.Memory::add_region(
      m,
      lower=try! @types.Word::of_int64(-16L, width=64),
      upper=w64(0x4),
      generator=@primus.Generator::static_value(1),
    )
    log.push(
      "wrapped: \{@primus.Memory::is_mapped(m, w64(0x3))} \{@primus.Memory::is_mapped(m, try! @types.Word::of_int64(-1L, width=64))} \{@primus.Memory::is_mapped(m, w64(0x100))}",
    )
    // cached cells of read-only regions stay read-only
    @primus.Memory::allocate(
      m,
      w64(0x200),
      2,
      read_only=true,
      init=_ => w8(1),
      generator=@primus.Generator::static_value(2),
    )
    ignore(@primus.Memory::load(m, w64(0x201)))
    for a in [0x200, 0x201] {
      @primus.Memory::store(m, w64(a), w8(9)) catch {
        e => log.push(@primus.exn_to_string(e))
      }
    }
    log.push("writable: \{@primus.Memory::is_writable(m, w64(0x200))}")
    @primus.Memory::store_never_fail(m, w64(0x900), w8(3))
    log.push(
      "never-fail cell writable: \{@primus.Memory::is_writable(m, w64(0x900))}",
    )
  })
  debug_inspect(
    log,
    content=(
      #|[
      #|  "one cell: 66",
      #|  "upper: 34",
      #|  "past upper: false",
      #|  "wrapped: true true false",
      #|  "Page fault at 0x0000000000000200",
      #|  "Page fault at 0x0000000000000201",
      #|  "writable: false",
      #|  "never-fail cell writable: true",
      #|]
    ),
  )
}

///|
test "call payloads are copies and resumable observers can fork" {
  let a = reg("g_a")
  let rdi = reg("RDI")
  let g = sub("g", args=[@types.Arg::create(a, Var(rdi), intent=In)], [blk()])
  let main = sub("main", [
    blk(defs=[def(rdi, int64(3))], jmps=[
      @types.Jmp::create_call(@types.Call::create(target=Direct(g.tid()))),
    ]),
  ])
  let log = []
  let (status, _) = @primus.Machine::run(
    project([main, g]),
    init=m => {
      @primus.Interpreter::link_program(m)
      m.observe(@primus.call, c => if c.0 == "g" { c.1.push(val64(m, 99)) })
      m.observe(@primus.call_return, c => {
        if c.0 == "g" {
          log.push("\{m.current()} return g: \{c.1.length()} args")
        }
      })
      ignore(
        m.subscribe_resumable(@primus.enter_sub, (m, s) => {
          if @types.Sub::name(s) == "g" && m.current() == @primus.Id::global() {
            log.push("resumable handler")
            m.fork()
          }
        }),
      )
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=resume_global,
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["resumable handler", "1 return g: 1 args", "0 return g: 1 args"]
    ),
  )
}

///|
test "shift amounts are clamped by magnitude" {
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let one128 = @primus.Value::of_word(
      m,
      try! @types.Word::of_int(width=128, 1),
    )
    let x = @primus.Value::of_int(m, width=8, 3)
    inspect(value_int(@primus.Value::lshift(m, x, one128)), content="6")
    let huge = @primus.Value::lshift(
      m,
      one128,
      @primus.Value::of_int(m, width=8, 100),
    )
    inspect(value_int(@primus.Value::lshift(m, x, huge)), content="0")
  })
}

///|
/// The global machine forks `n` children one after another; each child
/// writes its id to every cell.
fn spawn(
  m : @primus.Machine,
  n : Int32,
  cells : Int32,
  seen : Array[Bool],
) -> Unit raise {
  if n == 0 {
    return
  }
  m.fork(then=m => {
    if m.current() != @primus.Id::global() {
      let id = m.current().to_int()
      for c in 0..<cells {
        @primus.Memory::store(m, w64(c), w8(id))
      }
      seen.push(
        word_int(@primus.Memory::load(m, w64(cells - 1))).to_int() == id,
      )
    } else {
      spawn(m, n - 1, cells, seen)
    }
  })
}

///|
test "fork-heavy memory writes and loader initialization" {
  let forks = 64
  let cells = 256
  let seen = []
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      // loader-style initialization of a large region
      @primus.Memory::add_region(
        m,
        lower=w64(0x10000),
        upper=w64(0x10000 + 16383),
        init=a => w8(word_int(a).to_int() & 0xFF),
      )
      @primus.Memory::allocate(m, w64(0), cells)
    },
    start=m => spawn(m, forks, cells, seen),
    fini=resume_global,
  )
  inspect(status_string(status), content="Normal")
  inspect(seen.length(), content="64")
  assert_true(seen.iter().all(x => x))
}

///|
test "requests issued after a fork run in both machines (upstream program order)" {
  let forks = []
  let (_, _) = @primus.Machine::run(
    project([]),
    init=m => m.observe(@primus.machine_fork, p => forks.push("\{p.0}->\{p.1}")),
    start=m => {
      m.fork()
      m.fork()
    },
    fini=resume_global,
  )
  debug_inspect(
    forks,
    content=(
      #|["0->1", "1->2", "0->3"]
    ),
  )
}
