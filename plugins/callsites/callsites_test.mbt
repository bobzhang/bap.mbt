///|
fn r0() -> @types.Var {
  @types.Var::new(name="R0", typ=Imm(32))
}

///|
fn malloc_program() -> @types.Term[@types.Program] raise {
  let size = @types.Arg::create(
    @types.Var::new(name="malloc_size", typ=Imm(32)),
    @types.Exp::var_exp(r0()),
    intent=In,
  ).with_warn_unused()
  let result = @types.Arg::create(
    @types.Var::new(name="malloc_result", typ=Imm(32)),
    @types.Exp::var_exp(r0()),
    intent=Out,
  )
  let malloc = @types.Sub::create(name="malloc", args=[result, size])
  let ret = @types.Blk::create(tid=@types.Tid::for_name("ret"))
  let call = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(malloc.tid()),
      return_label=@types.Label::direct(ret.tid()),
    ),
    tid=@types.Tid::for_name("call"),
  ).set_attr(@types.Attr::address(@types.Word::of_int(width=32, 0x400)))
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"), jmps=[call])
  let main = @types.Sub::create(name="main", blks=[entry, ret])
  @types.Program::create(subs=[main, malloc])
}

///|
fn describe(blk : @types.Term[@types.Blk]) -> String {
  blk
  .defs()
  .map(def => {
    let origin = match def.origin() {
      Some(tid) => tid.name().unwrap_or("?")
      None => "-"
    }
    "\{def.lhs().name()} := \{def.rhs().to_string()} synthetic=\{def.is_synthetic()} origin=\{origin} address=\{def.get_attr("address").unwrap_or("-")}"
  })
  .join("\n")
}

///|
test "input arguments are defined before the call and outputs after return" {
  let prog = @callsites.fill_calls(malloc_program())
  let main = prog.subs()[0]
  inspect(
    describe(main.blks()[0]),
    content=(
      #|malloc_size := R0:imm32 synthetic=true origin=call address=0x400:32u
    ),
  )
  inspect(
    describe(main.blks()[1]),
    content=(
      #|malloc_result := R0:imm32 synthetic=true origin=call address=0x400:32u
    ),
  )
  // argument attributes are transferred to the definitions
  inspect(main.blks()[0].defs()[0].has_attr("warn-unused"), content="true")
}

///|
test "indirect and unknown callees are skipped" {
  let entry = @types.Blk::create(jmps=[
    @types.Jmp::create_call(
      @types.Call::create(
        target=@types.Label::indirect(@types.Exp::var_exp(r0())),
      ),
    ),
    @types.Jmp::create_call(
      @types.Call::create(target=@types.Label::direct(@types.Tid::fresh())),
    ),
  ])
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="f", blks=[entry]),
  ])
  let result = @callsites.fill_calls(prog)
  inspect(result.subs()[0].blks()[0].defs().length(), content="0")
}

///|
test "intent matching" {
  let arg = (intent : @types.Intent?) => {
    match intent {
      Some(i) => @types.Arg::create(r0(), @types.Exp::var_exp(r0()), intent=i)
      None => @types.Arg::create(r0(), @types.Exp::var_exp(r0()))
    }
  }
  let table = [None, Some(@types.In), Some(@types.Out), Some(@types.Both)].map(i => {
    [
      @callsites.intent_matches(arg(i), In),
      @callsites.intent_matches(arg(i), Out),
    ]
  })
  debug_inspect(
    table,
    content="[[true, true], [true, false], [false, true], [true, true]]",
  )
}

///|
test "pass registration depends on abi" {
  debug_inspect(@callsites.register(), content="Ok(true)")
  debug_inspect(@callsites.register(), content="Ok(false)")
  guard @project.find_pass("callsites") is Some(pass) else {
    fail("callsites is not registered")
  }
  debug_inspect(pass.deps(), content="[\"abi\"]")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    malloc_program(),
  )
  guard project.run_pass("callsites") is Ok(result) else {
    fail("callsites failed")
  }
  inspect(result.pass_has_run("abi"), content="true")
  inspect(result.program().subs()[0].blks()[1].defs().length(), content="1")
}
