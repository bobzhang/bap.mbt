///|
fn r0() -> @types.Var {
  @types.Var::new(name="R0", typ=Imm(32))
}

///|
fn result_var() -> @types.Var {
  @types.Var::new(name="malloc_result", typ=Imm(32))
}

///|
/// `main` calls `malloc` (whose result is `warn_unused`) and returns to `ret`,
/// which optionally uses R0.
fn program(uses_result : Bool) -> @types.Term[@types.Program] {
  let result = @types.Arg::create(
    result_var(),
    @types.Exp::var_exp(r0()),
    intent=Out,
  ).with_warn_unused()
  let malloc = @types.Sub::create(
    name="malloc",
    args=[result],
    tid=@types.Tid::for_name("malloc"),
  )
  let defs = if uses_result {
    [
      @types.Def::create(
        @types.Var::new(name="p", typ=Imm(32)),
        @types.Exp::var_exp(r0()),
        tid=@types.Tid::for_name("use"),
      ),
    ]
  } else {
    []
  }
  let ret = @types.Blk::create(tid=@types.Tid::for_name("ret"), defs~)
  let call = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(malloc.tid()),
      return_label=@types.Label::direct(ret.tid()),
    ),
    tid=@types.Tid::for_name("call"),
  )
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"), jmps=[call])
  @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[entry, ret]),
    malloc,
  ])
}

///|
/// A stand-in for the taint propagation analysis: every tainted definition is
/// visited, and the `use` definition reads the taint of the call.
fn propagate(prog : @types.Term[@types.Program]) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    sub.map_blks(blk => {
      blk.map_defs(def => {
        if def.taints_reg() {
          def.with_visited()
        } else if def.tid().name() == Some("use") {
          @warn_unused.with_tainted_regs(def, [
            (r0(), [@types.Tid::for_name("call")]),
          ])
        } else {
          def
        }
      })
    })
  })
}

///|
fn analyze(uses_result : Bool) -> (@types.Term[@types.Program], String) {
  let prog = program(uses_result)
    |> @callsites.fill_calls
    |> @warn_unused.taint_program
    |> propagate
  let seeds = @warn_unused.collect_seeds(prog)
  let unchecked = @warn_unused.solve(prog, seeds)
  (prog, @warn_unused.render_unchecked(prog, unchecked))
}

///|
test "unused results of warn_unused_result functions are reported" {
  let (prog, report) = analyze(false)
  let tainted = prog.subs()[0].blks()[1].defs()[0]
  debug_inspect(
    tainted.tainted_reg().map(t => t.to_string()),
    content="Some(\"@call\")",
  )
  inspect(
    report,
    content=(
      #|@call: call @malloc with return @ret
      #|
    ),
  )
  let marked = @warn_unused.mark_unchecked(prog, [@types.Tid::for_name("call")])
  inspect(marked.subs()[0].blks()[0].jmps()[0].is_dead(), content="true")
}

///|
test "checked results are not reported" {
  let (_, report) = analyze(true)
  inspect(report, content="")
}

///|
test "tainted register maps round trip" {
  let def = @types.Def::create(r0(), @types.Exp::var_exp(r0()))
  let tagged = @warn_unused.with_tainted_regs(def, [
    (r0(), [@types.Tid::for_name("a"), @types.Tid::for_name("b")]),
  ])
  debug_inspect(
    @warn_unused.tainted_regs(tagged).map(entries => {
      entries.map(e => (e.0, e.1.map(t => t.to_string())))
    }),
    content=(
      #|Some([("R0", ["@a", "@b"])])
    ),
  )
  debug_inspect(@warn_unused.tainted_regs(def), content="None")
}

///|
/// Like `program`, but `malloc` is a PLT-like stub: a single block that
/// leaves through an indirect jump. As in upstream `Microx_conqueror`, the
/// indirect jump pops the return label, so the microexecution of the taint
/// propagation reaches `ret`. (A callee without blocks never evaluates a
/// jump and ends the path, see `blockless_test.mbt`.)
fn program_with_plt_stub(uses_result : Bool) -> @types.Term[@types.Program] {
  let prog = program(uses_result)
  prog.map_subs(sub => {
    if sub.sub_name() != "malloc" {
      return sub
    }
    let body = @types.Blk::create(tid=@types.Tid::for_name("malloc_body"), jmps=[
      @types.Jmp::create_ret(
        Indirect(@types.Exp::var_exp(@types.Var::new(name="LR", typ=Imm(32)))),
        tid=@types.Tid::for_name("malloc_ret"),
      ),
    ])
    @types.Sub::create(
      name=sub.sub_name(),
      args=sub.args(),
      blks=[body],
      tid=sub.tid(),
    )
  })
}

///|
fn project_of(prog : @types.Term[@types.Program]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::unknown()).with_program(prog)
}

///|
test "end to end: the real propagate-taint pass finds unchecked calls" {
  let out = StringBuilder()
  debug_inspect(
    @warn_unused.register(out=s => out.write_string(s)),
    content="Ok(true)",
  )
  debug_inspect(@warn_unused.register(), content="Ok(false)")
  guard @project.find_pass("warn-unused") is Some(pass) else {
    fail("warn-unused is not registered")
  }
  debug_inspect(
    pass.deps(),
    content=(
      #|["warn-unused-taint", "propagate-taint", "warn-unused-print"]
    ),
  )
  // the real taint propagation pass is registered as a dependency
  assert_true(@project.find_pass(@propagate_taint.name) is Some(_))
  // the result of malloc is not used: the call is reported
  guard project_of(program_with_plt_stub(false)).run_pass("warn-unused")
    is Ok(proj) else {
    fail("warn-unused failed")
  }
  inspect(
    out.to_string(),
    content=(
      #|@call: call @malloc with return @ret
      #|
    ),
  )
  let seed_def = proj.program().subs()[0].blks()[1].defs()[0]
  inspect(
    seed_def.is_visited(),
    content=(
      #|true
    ),
  )
  // the result is used: nothing is reported
  out.reset()
  guard project_of(program_with_plt_stub(true)).run_pass("warn-unused")
    is Ok(proj) else {
    fail("warn-unused failed")
  }
  inspect(out.to_string(), content="")
  let use_def = proj.program().subs()[0].blks()[1].defs()
  debug_inspect(
    use_def.map(d => {
      (
        d.tid().name().unwrap_or("<synthetic>"),
        d.get_attr(@warn_unused.tainted_regs_attr),
      )
    }),
    content=(
      #|[
      #|  ("<synthetic>", Some("((R0 (@call)))")),
      #|  ("use", Some("((R0 (@call)))")),
      #|]
    ),
  )
}

///|
test "end to end: unchecked calls are marked dead" {
  ignore(@warn_unused.register())
  let passes = ["warn-unused-taint", "propagate-taint", "warn-unused-mark"]
  let dead = (uses_result : Bool) => {
    match project_of(program_with_plt_stub(uses_result)).run_passes(passes) {
      Ok(proj) => proj.program().subs()[0].blks()[0].jmps()[0].is_dead()
      Err(e) => {
        println(e)
        false
      }
    }
  }
  inspect(dead(false), content="true")
  inspect(dead(true), content="false")
}
