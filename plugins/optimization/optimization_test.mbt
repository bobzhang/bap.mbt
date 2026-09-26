///|
fn reg8(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(8))
}

///|
fn tmp8(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(8), is_virtual=true)
}

///|
fn int8(value : Int) -> @types.Exp raise {
  @types.Exp::int(@types.Word::of_int(width=8, value))
}

///|
fn bool_exp(value : Bool) -> @types.Exp {
  @types.Exp::int(@types.Word::of_bool(value))
}

///|
fn vexp(v : @types.Var) -> @types.Exp {
  @types.Exp::var_exp(v)
}

///|
fn render(sub : @types.Term[@types.Sub]) -> String {
  let lines = []
  for blk in sub.blks() {
    lines.push("\{blk.tid().name().unwrap_or("?")}:")
    for def in blk.defs() {
      lines.push("  \{def.lhs().name()} := \{def.rhs().to_string()}")
    }
    for jmp in blk.jmps() {
      lines.push("  jmp when \{jmp.cond().to_string()}")
    }
  }
  lines.join("\n")
}

///|
test "classification by optimization level" {
  let is_flag = (v : @types.Var) => v.name() == "CF"
  let t = tmp8("t")
  let cf = @types.Var::new(name="CF", typ=Imm(1))
  let rax = reg8("RAX")
  debug_inspect(@optimization.classify(is_flag, t), content="Virt")
  debug_inspect(@optimization.classify(is_flag, cf), content="Flag")
  debug_inspect(@optimization.classify(is_flag, rax), content="Phys")
  let allowed = (level : Int) => {
    [t, cf, rax].map(v => {
      @optimization.is_optimization_allowed(is_flag, level, v)
    })
  }
  debug_inspect(allowed(0), content="[false, false, false]")
  debug_inspect(allowed(1), content="[true, false, false]")
  debug_inspect(allowed(2), content="[true, true, false]")
  debug_inspect(allowed(3), content="[true, true, true]")
}

///|
test "level 1 propagates virtual constants and removes dead virtuals" {
  let t = tmp8("t")
  let u = tmp8("u")
  let x = reg8("x")
  let blk = @types.Blk::create(tid=@types.Tid::for_name("entry"), defs=[
    @types.Def::create(t, int8(1)),
    @types.Def::create(x, @types.Exp::binop(Plus, vexp(t), int8(2))),
    @types.Def::create(u, int8(5)),
  ])
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[blk]),
  ])
  let optimized = @optimization.optimize_program(prog, level=1)
  inspect(
    render(optimized.subs()[0]),
    content=(
      #|entry:
      #|  x := 3:8u
    ),
  )
  // level 0 only folds constants and never removes code
  let untouched = @optimization.optimize_program(prog, level=0)
  inspect(untouched.subs()[0].blks()[0].defs().length(), content="3")
}

///|
test "constant false jumps and the blocks behind them are removed" {
  let c = @types.Var::new(name="c", typ=Imm(1), is_virtual=true)
  let dead_blk = @types.Blk::create(tid=@types.Tid::for_name("dead"), defs=[
    @types.Def::create(reg8("y"), int8(7)),
  ])
  let live_blk = @types.Blk::create(tid=@types.Tid::for_name("live"))
  let entry = @types.Blk::create(
    tid=@types.Tid::for_name("entry"),
    defs=[@types.Def::create(c, bool_exp(false))],
    jmps=[
      @types.Jmp::create_goto(
        @types.Label::direct(dead_blk.tid()),
        cond=vexp(c),
      ),
      @types.Jmp::create_goto(@types.Label::direct(live_blk.tid())),
    ],
  )
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[entry, dead_blk, live_blk]),
  ])
  let optimized = @optimization.optimize_program(prog, level=1)
  inspect(
    render(optimized.subs()[0]),
    content=(
      #|entry:
      #|  jmp when 1:1u
      #|live:
    ),
  )
}

///|
test "jumps after an unconditional jump are unreachable" {
  let other = @types.Blk::create(tid=@types.Tid::for_name("other"))
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"), jmps=[
    @types.Jmp::create_goto(
      @types.Label::direct(@types.Tid::for_name("entry")),
      cond=bool_exp(true),
    ),
    @types.Jmp::create_goto(@types.Label::direct(other.tid())),
  ])
  let sub = @types.Sub::create(name="loop", blks=[entry, other])
  let data = @optimization.OptimizationData::create(deads=[], sub).find_unreachable(
    sub,
  )
  debug_inspect(
    data.deads().map(tid => tid.name()),
    content=(
      #|[None, Some("other")]
    ),
  )
}

///|
test "protected physical registers keep their last definition" {
  let rax = reg8("RAX")
  let writer = @types.Sub::create(name="writer", blks=[
    @types.Blk::create(tid=@types.Tid::for_name("w"), defs=[
      @types.Def::create(rax, int8(1)),
      @types.Def::create(rax, int8(2)),
      @types.Def::create(reg8("RBX"), int8(3)),
    ]),
  ])
  let reader = @types.Sub::create(name="reader", blks=[
    @types.Blk::create(tid=@types.Tid::for_name("r"), defs=[
      @types.Def::create(tmp8("t"), vexp(rax)),
    ]),
  ])
  let prog = @types.Program::create(subs=[writer, reader])
  let optimized = @optimization.optimize_program(prog, level=3)
  inspect(
    render(optimized.subs()[0]),
    content=(
      #|w:
      #|  RAX := 2:8u
    ),
  )
  // below level 3 physical registers are never removed
  let level2 = @optimization.optimize_program(prog, level=2)
  inspect(level2.subs()[0].blks()[0].defs().length(), content="3")
}

///|
test "flags are optimized from level 2" {
  let cf = @types.Var::new(name="CF", typ=Imm(1))
  let blk = @types.Blk::create(tid=@types.Tid::for_name("b"), defs=[
    @types.Def::create(cf, bool_exp(true)),
    @types.Def::create(cf, bool_exp(false)),
  ])
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="f", blks=[blk]),
  ])
  let is_flag = (v : @types.Var) => v.base().name() == "CF"
  let at1 = @optimization.optimize_program(prog, level=1, is_flag~)
  inspect(at1.subs()[0].blks()[0].defs().length(), content="2")
  let at2 = @optimization.optimize_program(prog, level=2, is_flag~)
  inspect(at2.subs()[0].blks()[0].defs().length(), content="0")
}

///|
test "target flag predicate uses status and flag roles" {
  let is_flag = @optimization.target_is_flag(@core_theory.Target::unknown())
  inspect(is_flag(reg8("CF")), content="false")
}

///|
test "results are cached by digest" {
  let t = tmp8("t")
  let blk = @types.Blk::create(tid=@types.Tid::for_name("b"), defs=[
    @types.Def::create(t, int8(1)).set_attr(
      @types.Attr::address(@types.Word::of_int(width=32, 0x1000)),
    ),
  ])
  let sub = @types.Sub::create(name="cached", blks=[blk])
  let prog = @types.Program::create(subs=[sub])
  let digest = @optimization.digest_of_sub(sub, 1)
  inspect(
    digest,
    content=(
      #|optimization:0x1000:32u:cached:1
    ),
  )
  let cache = @optimization.OptimizationCache::new()
  let first = @optimization.optimize_program(prog, level=1, cache~)
  inspect(cache.length(), content="1")
  let second = @optimization.optimize_program(prog, level=1, cache~)
  inspect(render(first.subs()[0]) == render(second.subs()[0]), content="true")
  inspect(render(second.subs()[0]), content="b:")
}

///|
test "pass registration follows the level" {
  debug_inspect(@optimization.register(level=0), content="Ok(false)")
  debug_inspect(@optimization.register(level=1), content="Ok(true)")
  debug_inspect(@optimization.register(level=2), content="Ok(false)")
  guard @project.find_pass("optimization") is Some(pass) else {
    fail("pass is not registered")
  }
  inspect(pass.autorun(), content="true")
  let t = tmp8("t")
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[
      @types.Blk::create(tid=@types.Tid::for_name("b"), defs=[
        @types.Def::create(t, int8(1)),
      ]),
    ]),
  ])
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    prog,
  )
  guard project.run_pass("optimization") is Ok(result) else {
    fail("pass failed")
  }
  inspect(render(result.program().subs()[0]), content="b:")
}

///|
test "plugin declaration exposes the level parameter" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @optimization.declare_plugin()
  @optimization.declare_plugin()
  inspect(
    @bap_main.registered_plugins().contains("optimization"),
    content="true",
  )
  @bap_main.initialize(
    argv=["bap", "--optimization-level=2"],
    name="bap",
    env=_ => None,
    out=_ => (),
    err=_ => (),
  )
  inspect(@project.find_pass("optimization") is Some(_), content="true")
  @bap_main.reset()
}
