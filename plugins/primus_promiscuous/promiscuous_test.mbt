///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn int64(n : Int32) -> @types.Exp {
  Int(try! @types.Word::of_int(width=64, n))
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
let r : @types.Var = @types.Var::create("r", Imm(64))

///|
let c : @types.Var = @types.Var::create("c", Imm(1))

///|
fn resume_other(m : @primus.Machine) -> Unit raise {
  let others = m.forks().filter(id => id != m.current())
  if others.last() is Some(id) {
    m.kill(m.current())
    m.switch(id)
  }
}

///|
/// Runs `main` with the path explorer and returns, for every finished
/// machine, its identifier, exit status, the value of `r` and its
/// conflicts.
fn explore(
  subs : Array[@types.Term[@types.Sub]],
  init~ : (@primus.Machine) -> Unit raise = _ => (),
) -> Array[String] {
  let log = []
  let status = Ref("normal")
  let (_, _) = @primus.Machine::run(
    project(subs),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Env::set(
        m,
        x,
        @primus.Value::of_word(m, try! @types.Word::of_int(width=64, 0)),
      )
      @primus_promiscuous.install(m)
      m.observe(@primus.exn_raised, e => {
        let s = @primus.exn_to_string(e)
        status.val = if s.has_prefix("unbound function") {
          "unbound function"
        } else {
          s
        }
      })
      init(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      let rv = if @primus.Env::is_set(m, r) {
        (try! @primus.Env::get(m, r).to_word().to_uint64()).to_string()
      } else {
        "unset"
      }
      let cs = @primus_promiscuous.conflicts(m).map(a => {
        "\{a.variable.name()}=\{a.res}"
      })
      log.push(
        "\{m.current()}: r=\{rv} status=\{status.val} conflicts=\{cs.join(" ")}",
      )
      status.val = "normal"
      resume_other(m)
    },
  )
  log
}

///|
test "assumptions of a block in the trivial condition form" {
  let b1 = @types.Blk::create()
  let d = @types.Var::create("d", Imm(1))
  let j1 = goto(b1, cond=Var(c))
  let j2 = goto(b1, cond=Var(d))
  let j3 = goto(b1)
  let blk = @types.Blk::create(jmps=[j1, j2, j3])
  let render = (xs : Array[Array[@primus_promiscuous.Assn]]) => {
    xs.map(assns => {
      assns.map(a => {
        let who = if a.jmp == j1.tid() { "j1" } else { "j2" }
        "\{who}:\{a.variable.name()}=\{a.res}"
      })
    })
  }
  // reverse jump order: the fallthrough, the second, the first jump
  debug_inspect(
    render(@primus_promiscuous.assumptions(blk)),
    content=(
      #|[
      #|  ["j2:d=false", "j1:c=false"],
      #|  ["j2:d=true", "j1:c=false"],
      #|  ["j1:c=true"],
      #|]
    ),
  )
  let bad = @types.Blk::create(jmps=[goto(b1, cond=BinOp(Eq, Var(x), int64(0)))])
  let err = try @primus_promiscuous.assumptions(bad) catch {
    e => @primus.exn_to_string(e)
  } noraise {
    _ => "no error"
  }
  inspect(
    err,
    content=(
      #|Primus interpreter runtime error: Not in TCF
    ),
  )
}

///|
test "both edges of a conditional branch are explored" {
  let b1 = @types.Blk::create(defs=[@types.Def::create(r, int64(1))])
  let b2 = @types.Blk::create(defs=[@types.Def::create(r, int64(2))])
  let b0 = @types.Blk::create(
    defs=[@types.Def::create(c, BinOp(Eq, Var(x), int64(0)))],
    jmps=[goto(b1, cond=Var(c)), goto(b2)],
  )
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2])
  debug_inspect(
    explore([main]),
    content=(
      #|[
      #|  "0: r=1 status=normal conflicts=",
      #|  "1: r=2 status=normal conflicts=c=false",
      #|]
    ),
  )
}

///|
test "visited blocks do not fork again" {
  // a loop that runs three times: only the first visit of the loop header
  // forks
  let i = @types.Var::create("i", Imm(64))
  let exit = @types.Blk::create(defs=[@types.Def::create(r, Var(i))])
  let head_tid = @types.Tid::create()
  let head = @types.Blk::create(
    tid=head_tid,
    defs=[
      @types.Def::create(i, BinOp(Plus, Var(i), int64(1))),
      @types.Def::create(c, BinOp(Lt, Var(i), int64(3))),
    ],
    jmps=[@types.Jmp::create_goto(Direct(head_tid), cond=Var(c)), goto(exit)],
  )
  let entry = @types.Blk::create(defs=[@types.Def::create(i, int64(0))], jmps=[
    @types.Jmp::create_goto(Direct(head_tid)),
  ])
  let main = @types.Sub::create(name="main", blks=[entry, head, exit])
  debug_inspect(
    explore([main]),
    content=(
      #|[
      #|  "0: r=3 status=normal conflicts=",
      #|  "1: r=1 status=normal conflicts=c=false",
      #|]
    ),
  )
}

///|
test "blocks marked as visited in the project do not fork" {
  let b1 = @types.Blk::create(defs=[@types.Def::create(r, int64(1))])
  let b2 = @types.Blk::create(defs=[@types.Def::create(r, int64(2))])
  let b0 = @types.Blk::create(
    defs=[@types.Def::create(c, BinOp(Eq, Var(x), int64(0)))],
    jmps=[goto(b1, cond=Var(c)), goto(b2)],
  ).set_attr(@types.Attr::visited())
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2])
  debug_inspect(
    explore([main]),
    content=(
      #|["0: r=1 status=normal conflicts="]
    ),
  )
}

///|
test "the code after an unresolved call is explored" {
  let after = @types.Blk::create(defs=[@types.Def::create(r, int64(5))])
  let b0 = @types.Blk::create(jmps=[
    @types.Jmp::create_call(
      @types.Call::create(
        target=Direct(@types.Tid::create()),
        return_label=Direct(after.tid()),
      ),
    ),
  ])
  let main = @types.Sub::create(name="main", blks=[b0, after])
  debug_inspect(
    explore([main]),
    content=(
      #|[
      #|  "0: r=unset status=unbound function conflicts=",
      #|  "1: r=5 status=Halt conflicts=",
      #|]
    ),
  )
}

///|
test "the division by zero handler component" {
  let b0 = @types.Blk::create(defs=[
    @types.Def::create(r, BinOp(Div, int64(1), Var(x))),
  ])
  let main = @types.Sub::create(name="main", blks=[b0])
  debug_inspect(
    explore([main]),
    content=(
      #|["0: r=unset status=Division by zero conflicts="]
    ),
  )
  debug_inspect(
    explore([main], init=m => {
      @primus_promiscuous.install_division_by_zero_handler(m)
    }),
    content=(
      #|["0: r=0 status=normal conflicts="]
    ),
  )
}

///|
test "components are registered once and the legacy mode extends legacy-main" {
  assert_true(@primus_promiscuous.register())
  assert_false(@primus_promiscuous.register())
  @primus_promiscuous.enable_legacy_promiscuous_mode()
  let comps = @primus.System::get("legacy-main", pkg="bap").components()
  inspect(
    comps.map(c => c.show()).filter(c => !c.contains("internal")).join(" "),
    content=(
      #|bap:limit bap:division-by-zero-handler bap:promiscuous-path-explorer bap:arg-randomizer bap:mem-randomizer bap:var-randomizer bap:load-binary
    ),
  )
}
