///|
fn w64(n : Int) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn project(defs : Array[@types.Term[@types.Def]]) -> @project.Project {
  let main = @types.Sub::create(name="main", blks=[@types.Blk::create(defs~)])
  let prog = @types.Program::create(subs=[main])
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
/// Runs `f` in the start computation of a machine with 16 bytes of
/// memory mapped at 0x1000.
fn with_machine(f : (@primus.Machine) -> Unit raise) -> String {
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => @primus.Memory::allocate(m, w64(0x1000), 16),
    start=f,
  )
  status.to_string()
}

///|
fn show(v : @primus.Value) -> String {
  if v.bitwidth() == 1 {
    "bit \{v.is_one()}"
  } else {
    v.to_word().to_hex()
  }
}

///|
test "the primitive table" {
  debug_inspect(
    @primus_taint.primitives().map(p => "\{p.name} \{p.types}"),
    content=(
      #|[
      #|  "taint-introduce-directly (a b) -> c",
      #|  "taint-introduce-indirectly (a int int) -> c",
      #|  "taint-get-direct (a b) -> c",
      #|  "taint-get-indirect (a b) -> c",
      #|  "taint-sanitize-direct (a b) -> c",
      #|  "taint-sanitize-indirect (a b) -> c",
      #|  "taint-policy-select (a b) -> bool",
      #|  "taint-policy-set-default (a) -> bool",
      #|  "taint-kind (a) -> b",
      #|]
    ),
  )
  assert_true(@primus_taint.find_primitive("taint-kind") is Some(_))
  assert_true(@primus_taint.find_primitive("taint-unknown") is None)
  let names = []
  @primus_taint.install_primitives(p => names.push(p.name))
  assert_eq(names.length(), 9)
}

///|
test "taint primitives operate on the tracker" {
  let log = []
  let status = with_machine(m => {
    let call = (name, args) => @primus_taint.call_primitive(m, name, args)
    let untrusted = @primus.Value::symbol_to_value(m, "untrusted")
    let secret = @primus.Value::symbol_to_value(m, "secret")
    let x = @primus.Value::of_word(m, w64(42))
    let t = call("taint-introduce-directly", [untrusted, x])
    log.push("introduced \{t.to_word().to_hex()}")
    let got = call("taint-get-direct", [untrusted, x])
    log.push("get-direct untrusted: \{got == t}")
    log.push(
      "get-direct secret: \{show(call("taint-get-direct", [secret, x]))}",
    )
    log.push(
      "kind: \{@primus.Value::symbol_of_value(m, call("taint-kind", [t]))}",
    )
    let p = @primus.Value::of_word(m, w64(0x1000))
    let n = @primus.Value::of_word(m, w64(4))
    let t2 = call("taint-introduce-indirectly", [secret, p, n])
    let q = @primus.Value::of_word(m, w64(0x1003))
    log.push(
      "get-indirect at 0x1003: \{call("taint-get-indirect", [secret, q]) == t2}",
    )
    log.push(
      "get-indirect at 0x1004: \{show(call("taint-get-indirect", [secret, @primus.Value::of_word(m, w64(0x1004))]))}",
    )
    let r = call("taint-sanitize-indirect", [secret, q])
    log.push("sanitize returns its argument: \{r == q}")
    log.push("after sanitize: \{show(call("taint-get-indirect", [secret, p]))}")
    ignore(call("taint-sanitize-direct", [untrusted, x]))
    log.push(
      "after direct sanitize: \{show(call("taint-get-direct", [untrusted, x]))}",
    )
    let exact = @primus.Value::symbol_to_value(m, "propagate-exactly")
    let by_comp = @primus.Value::symbol_to_value(m, "propagate-by-computation")
    log.push(
      "policy-select: \{show(call("taint-policy-select", [secret, exact]))}",
    )
    ignore(call("taint-policy-set-default", [by_comp]))
    let selected = @taint.Policy::selected(
      m,
      @taint.Policy::of_value(exact),
      @taint.Kind::of_value(secret),
    )
    let default = @taint.Policy::default(m).map(p => p.name(m))
    log.push("selected: \{selected}, default: \{default.unwrap_or("-")}")
    try call("taint-kind", []) catch {
      e => log.push("arity: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("no arity error")
    }
    try call("taint-nothing", []) catch {
      e => log.push("unknown: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("no unbound error")
    }
    try call("taint-kind", [x]) catch {
      e => log.push("bad object: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("no bad object error")
    }
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 0x0000000000000001",
      #|  "get-direct untrusted: true",
      #|  "get-direct secret: bit false",
      #|  "kind: untrusted",
      #|  "get-indirect at 0x1003: true",
      #|  "get-indirect at 0x1004: bit false",
      #|  "sanitize returns its argument: true",
      #|  "after sanitize: bit false",
      #|  "after direct sanitize: bit false",
      #|  "policy-select: bit false",
      #|  "selected: true, default: propagate-by-computation",
      #|  "arity: Primus interpreter runtime error: taint-kind: expected 1 argument(s), got 0",
      #|  "unknown: unbound function taint-nothing",
      #|  "bad object: bad taint object: 0x2A:64u#1",
      #|]
    ),
  )
}

///|
test "the taint-finalize signal" {
  let x = reg("x")
  let dx = @types.Def::create(x, Int(w64(5))).set_attr(
    @types.Attr::address(w64(0x10)),
  )
  let d2 = @types.Def::create(x, Int(w64(0))).set_attr(
    @types.Attr::address(w64(0x14)),
  )
  let d3 = @types.Def::create(x, Int(w64(1))).set_attr(
    @types.Attr::address(w64(0x18)),
  )
  let log = []
  let (status, _) = @primus.Machine::run(
    project([dx, d2, d3]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @taint.Gc::conservative(m)
      @primus_taint.install_signals(m, (name, args) => {
        log.push("(\{name} \{args.map(a => a.to_word().to_hex()).join(" ")})")
      })
      m.observe(@primus.leave_def, d => {
        if d.tid() == dx.tid() {
          let k = @primus.Value::symbol_to_value(m, "k")
          ignore(
            @primus_taint.call_primitive(m, "taint-introduce-directly", [
              k,
              @primus.Env::get(m, x),
            ]),
          )
        }
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  inspect(status.to_string(), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["(taint-finalize 0x0000000000000001 0x0)"]
    ),
  )
}

///|
test "components are registered once and work in a system" {
  let first = @primus_taint.register()
  let again = @primus_taint.register()
  inspect(
    "\{first} \{again}",
    content=(
      #|6 0
    ),
  )
  let names = @primus.Components::list()
    .map(i => i.name().to_string())
    .filter(n => {
      n.has_prefix("bap:") &&
      (n.contains("taint") || n.contains("garbage") || n.contains("policy"))
    })
  names.sort()
  debug_inspect(
    names,
    content=(
      #|[
      #|  "bap:propagate-taint-exact",
      #|  "bap:select-default-taint-policy",
      #|  "bap:conservative-garbage-collector",
      #|  "bap:propagate-taint-by-computation",
      #|  "bap:select-propagate-taint-exact-policy",
      #|  "bap:select-propagate-by-computation-policy",
      #|]
    ),
  )
  // a system made of the registered components
  let x = reg("x")
  let y = reg("y")
  let dx = @types.Def::create(x, Int(w64(5)))
  let dy = @types.Def::create(y, BinOp(Plus, Var(x), Int(w64(1))))
  let sys = @primus.System::define_("taint-test", pkg="test", components=[
    @primus.System::component("load-binary", pkg="bap"),
    @primus.System::component("propagate-taint-by-computation", pkg="bap"),
    @primus.System::component("select-default-taint-policy", pkg="bap"),
  ])
  let log = []
  let (status, _) = sys.run(
    project([dx, dy]),
    init=m => {
      m.observe(@primus.leave_def, d => {
        if d.tid() == dx.tid() {
          let k = @taint.Kind::create(m, "k")
          ignore(@taint.Tracker::new_direct(m, @primus.Env::get(m, x), k))
        }
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      let v = @primus.Env::get(m, y)
      log.push(
        "y: \{@taint.Tracker::lookup(m, v, Direct).to_array().map(o => o.to_string()).join(",")}",
      )
    },
  )
  inspect(status.to_string(), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["y: 1"]
    ),
  )
  inspect(@primus_taint.enable(), content="true")
  inspect(@primus_taint.enable(), content="false")
}
