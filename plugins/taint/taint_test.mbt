///|
test "strain specifications" {
  debug_inspect(
    @taint.parse_strain("0xBAD"),
    content=(
      #|Ok([Addr(2989)])
    ),
  )
  debug_inspect(
    @taint.parse_strain("(0xBAD malloc_return %0000002a)"),
    content=(
      #|Ok([Addr(2989), Var("malloc_return"), Tid("%0000002a")])
    ),
  )
  debug_inspect(
    @taint.parse_strain("strcpy_dst"),
    content=(
      #|Ok([Var("strcpy_dst")])
    ),
  )
  debug_inspect(
    @taint.parse_strain("0xZZ"),
    content=(
      #|Err("expected 0x<hex-digits> got \"0xZZ\"")
    ),
  )
  debug_inspect(
    @taint.parse_strain("@main"),
    content=(
      #|Err("expected <tid> | <var> | <addr> got \"@main\"")
    ),
  )
  assert_true(@taint.parse_strain("(a (b))") is Err(_))
  assert_true(@taint.parse_strain("a b") is Err(_))
  inspect(
    @taint.strain_to_string([Addr(0xBAD), Var("x"), Tid("%00000001")]),
    content=(
      #|(bad x %00000001)
    ),
  )
  inspect(
    @taint.Strain::Addr(-1).to_string(),
    content=(
      #|ffffffffffffffff
    ),
  )
}

///|
fn def_at(
  name : String,
  addr : Int32,
  lhs : String,
  origin? : @types.Tid,
) -> @types.Term[@types.Def] {
  let d = @types.Def::create(
    @types.Var::create(lhs, Imm(32)),
    Int(try! @types.Word::of_int(width=32, 0)),
    tid=@types.Tid::for_name(name),
  ).set_attr(@types.Attr::address(try! @types.Word::of_int(width=32, addr)))
  match origin {
    Some(o) => d.set_attr(@types.Attr::origin(o))
    None => d
  }
}

///|
fn program() -> @types.Term[@types.Program] {
  let origin = @types.Tid::for_name("call-site")
  @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[
      @types.Blk::create(defs=[
        def_at("d1", 0xBAD, "malloc_return"),
        def_at("d2", 0xBAD, "tmp"),
        def_at("d3", 0x100, "strcpy_dst", origin~),
        def_at("d4", 0x104, "other"),
      ]),
    ]),
  ])
}

///|
fn describe(prog : @types.Term[@types.Program]) -> Array[String] {
  prog.subs()[0].blks()[0]
  .defs()
  .map(d => {
    let reg = d.get_attr(@taint_lib.tainted_reg_attr).unwrap_or("-")
    let ptr = d.get_attr(@taint_lib.tainted_ptr_attr).unwrap_or("-")
    "\{d.tid().to_string()} reg=\{reg} ptr=\{ptr}"
  })
}

///|
test "definitions matching strains are marked with seeds" {
  let regs = [
    @taint.parse_strain("(0xBAD malloc_return)").unwrap(),
    @taint.parse_strain("other").unwrap(),
  ]
  let ptrs = [@taint.parse_strain("strcpy_dst").unwrap()]
  debug_inspect(
    describe(@taint.mark(regs~, ptrs~, program())),
    content=(
      #|[
      #|  "@d1 reg=@d1 ptr=-",
      #|  "@d2 reg=- ptr=-",
      #|  "@d3 reg=- ptr=@call-site",
      #|  "@d4 reg=@d4 ptr=-",
      #|]
    ),
  )
  // an address strain alone matches both definitions of the instruction
  let regs = [@taint.parse_strain("0xbad").unwrap()]
  debug_inspect(
    describe(@taint.mark(regs~, ptrs=[], program())),
    content=(
      #|[
      #|  "@d1 reg=@d1 ptr=-",
      #|  "@d2 reg=@d2 ptr=-",
      #|  "@d3 reg=- ptr=-",
      #|  "@d4 reg=- ptr=-",
      #|]
    ),
  )
}

///|
test "the seeding pass" {
  debug_inspect(@taint.register(), content="Ok(false)")
  let regs = [@taint.parse_strain("malloc_return").unwrap()]
  debug_inspect(
    @taint.register(regs~),
    content=(
      #|Ok(true)
    ),
  )
  debug_inspect(
    @taint.register(regs~),
    content=(
      #|Ok(false)
    ),
  )
  let pass = @taint.pass(regs~, ptrs=[])
  debug_inspect(
    pass.deps(),
    content=(
      #|["callsites"]
    ),
  )
  inspect(pass.autorun(), content="true")
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    program(),
  )
  // the pass depends on the callsites pass
  match pass.run(proj) {
    Ok(_) => fail("expected an unsatisfied dependency")
    Err(e) => inspect(e.to_string().contains("callsites"), content="true")
  }
  ignore(
    @project.register_pass_if_absent(
      @project.ProjectPass::create(name="callsites", run=p => Ok(p)),
    ),
  )
  let proj = proj.run_pass("taint").unwrap()
  debug_inspect(
    describe(proj.program()),
    content=(
      #|[
      #|  "@d1 reg=@d1 ptr=-",
      #|  "@d2 reg=- ptr=-",
      #|  "@d3 reg=- ptr=-",
      #|  "@d4 reg=- ptr=-",
      #|]
    ),
  )
}
