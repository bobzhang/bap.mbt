///|
test "values have fresh identifiers and arithmetic helpers" {
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let a = @primus.Value::of_int(m, width=8, 200)
    let b = @primus.Value::of_int(m, width=8, 100)
    assert_true(a.id() != b.id())
    inspect(value_int(@primus.Value::add(m, a, b)), content="44")
    inspect(value_int(@primus.Value::sub(m, b, a)), content="156")
    inspect(
      value_int(@primus.Value::lshift(m, b, @primus.Value::one(m, 8))),
      content="200",
    )
    inspect(value_int(@primus.Value::extract(m, hi=3, a)), content="8")
    inspect(value_int(@primus.Value::concat(m, a, b)), content="51300")
    inspect(@primus.Value::of_bool(m, true).is_one(), content="true")
    inspect(@primus.Value::zero(m, 32).bitwidth(), content="32")
    inspect(
      @primus.Value::of_string(m, "0x10:32u").to_word().to_hex(),
      content="0x00000010",
    )
    // symbols are interned
    let s1 = @primus.Value::symbol_to_value(m, "malloc")
    let s2 = @primus.Value::symbol_to_value(m, "free")
    let s3 = @primus.Value::symbol_to_value(m, "malloc")
    assert_eq(s1.to_word(), s3.to_word())
    assert_true(s1.to_word() != s2.to_word())
    inspect(@primus.Value::symbol_of_value(m, s2), content="free")
    inspect(s1.bitwidth(), content="63")
  })
}

///|
test "interpreter primitives from host code" {
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let x = @primus.Interpreter::constant(m, w64(5))
    let y = @primus.Interpreter::binop(
      m,
      Plus,
      x,
      @primus.Interpreter::constant(m, w8(1)),
    )
    inspect(value_int(y), content="6")
    inspect(y.bitwidth(), content="64")
    let taken = @primus.Interpreter::branch(m, x, () => "yes", () => "no")
    inspect(taken, content="yes")
    let i = reg("i")
    @primus.Interpreter::set(m, i, @primus.Interpreter::constant(m, w64(3)))
    let stop = @primus.Interpreter::repeat(
      m,
      () => @primus.Interpreter::get(m, i),
      () => {
        @primus.Interpreter::set(
          m,
          i,
          @primus.Interpreter::binop(
            m,
            Minus,
            @primus.Interpreter::get(m, i),
            @primus.Interpreter::constant(m, w64(1)),
          ),
        )
      },
    )
    inspect(stop.is_one(), content="true")
    inspect(value_int(@primus.Interpreter::get(m, i)), content="0")
    // assign through an extract lvalue
    let r = reg("r")
    @primus.Interpreter::set(
      m,
      r,
      @primus.Interpreter::constant(m, w64(0xFF00)),
    )
    @primus.Interpreter::assign(
      m,
      Extract(hi=7, lo=0, exp=Var(r)),
      @primus.Interpreter::constant(m, w8(0x12)),
    )
    inspect(value_int(@primus.Interpreter::get(m, r)), content="65298")
    // loads and stores through memory
    @primus.Memory::allocate(m, w64(0x40), 8)
    let addr = @primus.Interpreter::constant(m, w64(0x40))
    @primus.Interpreter::store(
      m,
      addr,
      @primus.Interpreter::constant(
        m,
        try! @types.Word::of_int(width=32, 0x01020304),
      ),
      LittleEndian,
      R32,
    )
    inspect(
      @primus.Interpreter::load(m, addr, BigEndian, R32).to_word().to_hex(),
      content="0x04030201",
    )
    inspect(
      value_int(@primus.Interpreter::exp(m, BinOp(Times, int64(6), int64(7)))),
      content="42",
    )
  })
}

///|
test "sexp printing and parsing" {
  let s = @primus.Sexp::parse(
    "(defsystem foo :description \"a b\" ; comment\n (x y))",
  )
  inspect(s, content="(defsystem foo :description \"a b\" (x y))")
  let many = @primus.Sexp::parse_many("a (b) \"c d\"")
  inspect(many.length(), content="3")
  let err = try @primus.Sexp::parse("(a b") catch {
    e => e.to_string()
  } noraise {
    _ => "ok"
  }
  inspect(err, content="unexpected end of input")
}

///|
test "systems from defsystem descriptions" {
  let text =
    #|(defsystem test-base
    #|  :description "a base system"
    #|  :components (load-binary))
    #|(defsystem test-child
    #|  :description "a child system"
    #|  :depends-on (test-base)
    #|  :components (test-counter))
  let systems = @primus.System::from_string(text)
  inspect(systems.length(), content="2")
  inspect(systems[1].name().show(), content="bap:test-child")
  for s in systems {
    @primus.System::register(s)
  }
  let comps = systems[1].all_components().map(c => c.show())
  debug_inspect(
    comps,
    content=(
      #|["bap:load-binary", "bap:test-counter"]
    ),
  )
  let err = try @primus.System::from_string("(defsystem bad :oops 1)") catch {
    SystemParseError(msg~, ..) => msg
    _ => "other"
  } noraise {
    _ => "ok"
  }
  inspect(
    err,
    content="expects option ::= :description | :components | :depends-on, got an unknown option :oops",
  )
}

///|
test "running a system initializes its components" {
  let x = reg("x")
  let main = sub("main", [blk(defs=[def(x, int64(3))])])
  let log = []
  @primus.Components::register_generic("test-logger", pkg="bap", m => {
    m.observe(@primus.system_init, _ => log.push("init"))
    m.observe(@primus.system_fini, _ => log.push("fini"))
    m.observe(@primus.enter_sub, s => log.push("enter \{@types.Sub::name(s)}"))
    log.push(
      "booting \{@primus.System::current(m).map(s => s.name().show()).unwrap_or("?")}",
    )
  })
  let sys = @primus.System::define_(
    "test-run",
    pkg="bap",
    depends_on=[@primus.System::depends_on("legacy-main", pkg="bap")],
    components=[@primus.System::component("test-logger", pkg="bap")],
  )
  let (status, _) = sys.run(project([main]), start=m => {
    @primus.Linker::exec(m, Symbol("main"))
    log.push("x=\{value_int(@primus.Env::get(m, x))}")
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["booting bap:test-run", "init", "enter main", "x=3", "fini"]
    ),
  )
  // unknown components are reported before the machine starts
  let broken = @primus.System::define_("broken", components=[
    @primus.System::component("no-such-component"),
  ])
  let err = try broken.run(project([])) catch {
    UnknownComponent(component~, ..) => component
    _ => "other"
  } noraise {
    _ => "ok"
  }
  inspect(
    err,
    content=(
      #|no-such-component
    ),
  )
}

///|
test "legacy main and jobs" {
  let x = reg("x")
  let main = sub("main", [blk(defs=[def(x, int64(9))])])
  let seen = []
  let (status, _) = @primus.Machine::run_main(project([main]), m => {
    @primus.Linker::exec(m, Symbol("main"))
    seen.push(value_int(@primus.Env::get(m, x)))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(seen, content="[9]")
  let sys = @primus.System::get("legacy-main", pkg="bap")
  @primus.Jobs::enqueue(sys, name="first", start=m => {
    @primus.Linker::exec(m, Symbol("main"))
  })
  @primus.Jobs::enqueue(
    @primus.System::define_("missing", components=[
      @primus.System::component("nothing"),
    ]),
    name="second",
  )
  @primus.Jobs::enqueue(sys, name="third", start=m => {
    @primus.Interpreter::halt(m)
  })
  inspect(@primus.Jobs::pending(), content="3")
  let statuses = []
  let result = @primus.Jobs::run(
    project([main]),
    on_success=(job, status, _) => {
      statuses.push("\{job.name}: \{status}")
      Continue
    },
    on_failure=(job, _, _) => {
      statuses.push("\{job.name}: failed")
      Continue
    },
  )
  debug_inspect(
    statuses,
    content=(
      #|["first: Normal", "second: failed", "third: Exn(Halt)"]
    ),
  )
  inspect(result.finished.length(), content="3")
  inspect(result.failures.length(), content="1")
  inspect(@primus.Jobs::pending(), content="0")
}
