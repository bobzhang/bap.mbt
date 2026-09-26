///|
fn w64(n : Int) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn int64(n : Int) -> @types.Exp {
  Int(w64(n))
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn store64(addr : Int, value : @types.Exp) -> @types.Exp {
  Store(
    mem=Var(@types.Var::create("mem", Mem(addr_width=64, value_width=8))),
    addr=int64(addr),
    value~,
    endian=LittleEndian,
  )
}

///|
/// Runs `main` with 32 bytes of memory at 0x1000, the input register `x`
/// set to an arbitrary (non-constant) value, and the `constant-tracker`
/// component installed by `install`.
fn run_main(
  defs : Array[@types.Term[@types.Def]],
  install? : (@primus.Machine) -> Unit raise = m => {
    @constant_tracker.tracker_component(m)
  },
  init? : (@primus.Machine) -> Unit raise = _ => (),
  fini? : (@primus.Machine) -> Unit raise = _ => (),
) -> String {
  let main = @types.Sub::create(name="main", blks=[@types.Blk::create(defs~)])
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
  let (status, _) = @primus.Machine::run(
    proj,
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Memory::allocate(m, w64(0x1000), 32)
      @primus.Env::set(m, reg("x"), @primus.Value::of_word(m, w64(42)))
      install(m)
      init(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini~,
  )
  status.to_string()
}

///|
fn program() -> Array[@types.Term[@types.Def]] {
  let x = reg("x")
  [
    @types.Def::create(reg("a"), int64(5)),
    @types.Def::create(reg("b"), BinOp(Plus, Var(reg("a")), int64(1))),
    @types.Def::create(reg("c"), BinOp(Plus, Var(x), Var(reg("a")))),
    @types.Def::create(
      @types.Var::create("d", Imm(8)),
      Cast(kind=Low, width=8, exp=Var(reg("b"))),
    ),
    @types.Def::create(
      @types.Var::create("e", Imm(128)),
      Concat(high=Var(reg("a")), low=Var(reg("b"))),
    ),
    @types.Def::create(
      @types.Var::create("f", Imm(32)),
      Extract(hi=31, lo=0, exp=Var(reg("c"))),
    ),
    @types.Def::create(reg("g"), UnOp(Neg, Var(reg("b")))),
    @types.Def::create(
      @types.Var::create("mem", Mem(addr_width=64, value_width=8)),
      store64(0x1000, Var(reg("b"))),
    ),
    @types.Def::create(
      @types.Var::create("mem", Mem(addr_width=64, value_width=8)),
      store64(0x1008, Var(x)),
    ),
  ]
}

///|
test "the tracker component follows the interpreter" {
  let log = []
  let status = run_main(program(), fini=m => {
    for name in ["x", "a", "b", "c", "d", "e", "f", "g"] {
      let v = @primus.Env::all(m).filter(v => v.name() == name)[0]
      log.push(
        "\{name}: \{@constant_tracker.is_static_constant(m, @primus.Env::get(m, v))}",
      )
    }
    let ptr = (a : Int) => @primus.Value::of_word(m, w64(a))
    let call = (name, args) => {
      let r = @constant_tracker.call_primitive(m, name, args)
      r.is_one()
    }
    let env = (name : String) => {
      let v = @primus.Env::all(m).filter(v => v.name() == name)[0]
      @primus.Env::get(m, v)
    }
    log.push(
      "all-static-constant a b d: \{call("all-static-constant", [env("a"), env("b"), env("d")])}",
    )
    log.push(
      "all-static-constant a c: \{call("all-static-constant", [env("a"), env("c")])}",
    )
    log.push("all-static-constant (): \{call("all-static-constant", [])}")
    log.push(
      "points-to-static-data 0x1000 8: \{call("points-to-static-data", [ptr(0x1000), ptr(8)])}",
    )
    log.push(
      "points-to-static-data 0x1000 9: \{call("points-to-static-data", [ptr(0x1000), ptr(9)])}",
    )
    log.push(
      "points-to-static-data 0x5000 0: \{call("points-to-static-data", [ptr(0x5000), ptr(0)])}",
    )
    try call("points-to-static-data", [ptr(0x5000), ptr(1)]) catch {
      e => log.push("unmapped: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("unmapped memory was readable")
    }
    try call("points-to-static-data", [ptr(0x1000)]) catch {
      e => log.push("arity: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("no arity error")
    }
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "x: false",
      #|  "a: true",
      #|  "b: true",
      #|  "c: false",
      #|  "d: true",
      #|  "e: true",
      #|  "f: false",
      #|  "g: true",
      #|  "all-static-constant a b d: true",
      #|  "all-static-constant a c: false",
      #|  "all-static-constant (): true",
      #|  "points-to-static-data 0x1000 8: true",
      #|  "points-to-static-data 0x1000 9: false",
      #|  "points-to-static-data 0x5000 0: true",
      #|  "unmapped: Page fault at 0x0000000000005000",
      #|  "arity: Primus interpreter runtime error: points-to-static-data: expected 2 argument(s), got 1",
      #|]
    ),
  )
}

///|
test "without the tracker nothing is a static constant" {
  let log = []
  let status = run_main(program(), install=_ => (), fini=m => {
    let a = @primus.Env::get(m, reg("a"))
    log.push("a: \{@constant_tracker.is_static_constant(m, a)}")
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["a: false"]
    ),
  )
}

///|
test "forks track static constants independently" {
  let x = reg("x")
  let d0 = @types.Def::create(reg("a"), int64(5))
  let log = []
  let status = run_main(
    [d0, @types.Def::create(reg("y"), BinOp(Plus, Var(x), Var(reg("a"))))],
    init=m => {
      m.observe(@primus.leave_def, d => {
        if d.tid() == d0.tid() && m.current() == @primus.Id::global() {
          let pid = m.current()
          m.fork(then=m => {
            if m.current() != pid {
              // the child assumes that the input is a constant
              @constant_tracker.declare_static_constant(
                m,
                @primus.Env::get(m, x),
              )
            }
          })
        }
      })
    },
    fini=m => {
      let y = @primus.Env::get(m, reg("y"))
      log.push(
        "machine \{m.current()}: y is constant = \{@constant_tracker.is_static_constant(m, y)}",
      )
      if m.current() != @primus.Id::global() {
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "machine 1: y is constant = true",
      #|  "machine 0: y is constant = false",
      #|]
    ),
  )
}

///|
test "the registered component works in a Primus system" {
  @constant_tracker.register_components()
  @constant_tracker.register_components()
  let names = @primus.Components::list()
    .map(i => i.name().to_string())
    .filter(n => n.has_prefix("bap:constant"))
  debug_inspect(
    names,
    content=(
      #|["bap:constant-tracker-primitives", "bap:constant-tracker"]
    ),
  )
  let sys = @primus.System::define_("constant-tracker-test", pkg="test", components=[
    @primus.System::component("load-binary", pkg="bap"),
    @primus.System::component("constant-tracker", pkg="bap"),
  ])
  let main = @types.Sub::create(name="main", blks=[
    @types.Blk::create(defs=[
      @types.Def::create(reg("a"), int64(5)),
      @types.Def::create(reg("b"), BinOp(Times, Var(reg("a")), int64(3))),
    ]),
  ])
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
  let log = []
  let (status, _) = sys.run(
    proj,
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      let b = @primus.Env::get(m, reg("b"))
      log.push("b: \{@constant_tracker.is_static_constant(m, b)}")
    },
  )
  inspect(status.to_string(), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["b: true"]
    ),
  )
  debug_inspect(
    @constant_tracker.primitives().map(p => p.name),
    content=(
      #|["all-static-constant", "points-to-static-data"]
    ),
  )
  let names = []
  @constant_tracker.install_primitives(p => names.push(p.name))
  inspect(names.length(), content="2")
}
