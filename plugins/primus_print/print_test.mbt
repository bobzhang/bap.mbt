///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs~),
  )
}

///|
let event_a : (@primus.Observation[Int32], @primus.Statement[Int32]) = @primus.Observation::provide(
  "print-a",
  pkg="test",
  inspect=x => Atom(x.to_string()),
)

///|
let event_b : (@primus.Observation[Int32], @primus.Statement[Int32]) = @primus.Observation::provide(
  "print-b",
  pkg="test",
  inspect=x => Atom(x.to_string()),
)

///|
test "monitors are selected by provider names" {
  let names = (xs : Array[String]) => {
    @primus_print.parse_monitors(xs).map(p => p.name())
  }
  debug_inspect(
    names(["enter-blk", "+leave-blk", "-enter-blk"]),
    content=(
      #|["leave-blk"]
    ),
  )
  debug_inspect(
    names(["test:print-a", "test:print-b"]),
    content=(
      #|["test:print-b", "test:print-a"]
    ),
  )
  let all = @primus.Observation::list_providers().length()
  assert_eq(names(["all", "-enter-blk"]).length(), all - 1)
  let err = try @primus_print.parse_monitors(["no-such-event"]) catch {
    e => e.to_string()
  } noraise {
    _ => "ok"
  }
  inspect(
    err,
    content=(
      #|An unknown observation provider `no-such-event'
    ),
  )
}

///|
test "observations and rules are printed" {
  let out = []
  @primus_print.monitor(@primus_print.parse_monitors(["test:print-a"]), s => {
    out.push(s)
  })
  let rule = match
    @bare.Rule::of_string("(((test:print-a ?x) (test:print-b ?x)) ((both ?x)))") {
    Ok(r) => r
    Err(e) => fail(e.to_string())
  }
  @primus_print.process_rule(rule, s => out.push(s))
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    m.make(event_a.1, 1)
    m.make(event_b.1, 2)
    m.make(event_a.1, 2)
    m.make(event_b.1, 2)
  })
  debug_inspect(
    out,
    content=(
      #|[
      #|  "(test:print-a 1)\n",
      #|  "(test:print-a 2)\n",
      #|  "(both 2)\n",
      #|  "(both 2)\n",
      #|]
    ),
  )
}

///|
test "the traceback is printed when the system stops" {
  let r = @types.Var::create("r", Imm(64))
  let b1 = @types.Blk::create(defs=[
    @types.Def::create(r, Int(try! @types.Word::of_int(width=64, 1))),
  ])
  let b0 = @types.Blk::create(jmps=[@types.Jmp::create_goto(Direct(b1.tid()))])
  let main = @types.Sub::create(name="main", tid=@types.Tid::for_name("main"), blks=[
    b0, b1,
  ])
  let out = []
  let (status, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_print.install(m, traceback=16, out=s => out.push(s))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  inspect(status, content="Normal")
  // positions are printed from the most recent one; terms are rendered
  // without their identifiers to keep the snapshot stable
  let kinds = out.map(s => {
    if s.has_suffix(": <main>\n") {
      "sub main"
    } else if s.has_suffix(":\n") {
      "blk"
    } else if s.contains(":=") {
      "def"
    } else if s.contains("goto") {
      "jmp"
    } else {
      s
    }
  })
  debug_inspect(
    kinds,
    content=(
      #|["def", "blk", "jmp", "blk", "sub main"]
    ),
  )
}
