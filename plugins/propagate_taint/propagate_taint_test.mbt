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
fn mem_var() -> @types.Var {
  @types.Var::create("mem", Mem(addr_width=64, value_width=8))
}

///|
fn tid(name : String) -> @types.Tid {
  @types.Tid::for_name(name)
}

///|
fn def(
  name : String,
  v : @types.Var,
  e : @types.Exp,
) -> @types.Term[@types.Def] {
  @types.Def::create(v, e, tid=tid(name))
}

///|
fn load64(addr : @types.Exp) -> @types.Exp {
  Load(mem=Var(mem_var()), addr~, endian=LittleEndian, typ=Imm(64))
}

///|
fn store64(addr : @types.Exp, value : @types.Exp) -> @types.Exp {
  Store(mem=Var(mem_var()), addr~, value~, endian=LittleEndian)
}

///|
/// A jump that leaves the subroutine (an indirect return).
fn leave(name : String) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_ret(Indirect(int64(0)), tid=tid(name))
}

///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs~),
  )
}

///|
fn propagate(
  subs : Array[@types.Term[@types.Sub]],
  deterministic? : Bool = true,
) -> @propagate_taint.PropagationResult raise {
  @propagate_taint.run(
    max_steps=100,
    max_loop=10,
    deterministic~,
    reg_policy=Fixed(3),
    mem_policy=Fixed(0),
    project(subs),
    Name("main"),
  )
}

///|
/// The non-empty taint maps of the given terms.
fn report(
  r : @propagate_taint.PropagationResult,
  names : Array[String],
) -> Array[String] {
  let out = []
  for n in names {
    let regs = r.tainted_regs(tid(n))
    let ptrs = r.tainted_ptrs(tid(n))
    let visited = if r.is_visited(tid(n)) { "" } else { " (not visited)" }
    out.push("\{n}: regs=\{regs} ptrs=\{ptrs}\{visited}")
  }
  out
}

///|
test "taints propagate through computations, stores and loads" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let w = reg("w")
  let u = reg("u")
  let p = reg("p")
  let v = reg("v")
  let k = reg("k")
  let q = reg("q")
  let seed = tid("seed")
  let b0 = @types.Blk::create(defs=[
    def("d1", x, BinOp(Plus, Var(y), int64(1))).set_attr(
      @types.Attr::tainted_reg(seed),
    ),
    def("d2", z, BinOp(Times, Var(x), int64(2))),
    def("d3", mem_var(), store64(int64(0x100), Var(z))),
    def("d4", w, load64(int64(0x100))),
    def("d5", u, Var(w)),
    def("d6", p, int64(0x100)),
    def("d7", v, load64(Var(p))),
    def("d8", k, int64(5)),
    def("d9", q, BinOp(Plus, Var(k), int64(1))),
  ])
  let main = @types.Sub::create(name="main", blks=[b0], tid=tid("main"))
  let r = propagate([main])
  debug_inspect(
    report(r, ["d1", "d2", "d3", "d4", "d5", "d7", "d9"]),
    content=(
      #|[
      #|  "d1: regs=((y (@seed))) ptrs=()",
      #|  "d2: regs=((x (@seed))) ptrs=()",
      #|  "d3: regs=((z (@seed))) ptrs=()",
      #|  "d4: regs=() ptrs=()",
      #|  "d5: regs=((w (@seed))) ptrs=()",
      #|  "d7: regs=() ptrs=((p (@seed)))",
      #|  "d9: regs=() ptrs=()",
      #|]
    ),
  )
  debug_inspect(
    r.tainted_terms().map(t => t.to_string()),
    content=(
      #|["@d1", "@d2", "@d3", "@d5", "@d7"]
    ),
  )
}

///|
test "pointer seeds taint the memory pointed by the free variables" {
  let x = reg("x")
  let p = reg("p")
  let y = @types.Var::create("y", Imm(8))
  let b0 = @types.Blk::create(defs=[
    def("s1", x, Var(p)).set_attr(@types.Attr::tainted_ptr(tid("pseed"))),
    def(
      "s2",
      y,
      Load(mem=Var(mem_var()), addr=Var(p), endian=LittleEndian, typ=Imm(8)),
    ),
    def("s3", x, Var(y)),
  ])
  let main = @types.Sub::create(name="main", blks=[b0], tid=tid("main"))
  let r = propagate([main])
  debug_inspect(
    report(r, ["s1", "s2", "s3"]),
    content=(
      #|[
      #|  "s1: regs=() ptrs=((p (@pseed)))",
      #|  "s2: regs=() ptrs=((p (@pseed)))",
      #|  "s3: regs=((y (@pseed))) ptrs=()",
      #|]
    ),
  )
}

///|
/// b0: x := y (seed); if x == 3 goto b1 else goto b2
/// b1: mem[0x100] := x; goto b3
/// b2: p := 0x100; v := mem[p]; a := x; goto b3
/// b3: c := x; return
fn branches() -> Array[@types.Term[@types.Sub]] {
  let x = reg("x")
  let y = reg("y")
  let p = reg("p")
  let v = reg("v")
  let a = reg("a")
  let c = reg("c")
  let b3 = @types.Blk::create(tid=tid("b3"), defs=[def("c1", c, Var(x))], jmps=[
    leave("j3"),
  ])
  let b1 = @types.Blk::create(
    tid=tid("b1"),
    defs=[def("m1", mem_var(), store64(int64(0x100), Var(x)))],
    jmps=[@types.Jmp::create_goto(Direct(b3.tid()), tid=tid("j1"))],
  )
  let b2 = @types.Blk::create(
    tid=tid("b2"),
    defs=[
      def("p1", p, int64(0x100)),
      def("v1", v, load64(Var(p))),
      def("a1", a, Var(x)),
    ],
    jmps=[@types.Jmp::create_goto(Direct(b3.tid()), tid=tid("j2"))],
  )
  let b0 = @types.Blk::create(
    tid=tid("b0"),
    defs=[def("x1", x, Var(y)).set_attr(@types.Attr::tainted_reg(tid("seed")))],
    jmps=[
      @types.Jmp::create_goto(
        Direct(b1.tid()),
        cond=BinOp(Eq, Var(x), int64(3)),
        tid=tid("j0"),
      ),
      @types.Jmp::create_goto(Direct(b2.tid()), tid=tid("j0'")),
    ],
  )
  [@types.Sub::create(name="main", blks=[b0, b1, b2, b3], tid=tid("main"))]
}

///|
test "deterministic mode follows the feasible path only" {
  let r = propagate(branches(), deterministic=true)
  debug_inspect(
    report(r, ["j0", "m1", "v1", "a1", "c1"]),
    content=(
      #|[
      #|  "j0: regs=((x (@seed))) ptrs=()",
      #|  "m1: regs=((x (@seed))) ptrs=()",
      #|  "v1: regs=() ptrs=() (not visited)",
      #|  "a1: regs=() ptrs=() (not visited)",
      #|  "c1: regs=((x (@seed))) ptrs=()",
      #|]
    ),
  )
}

///|
test "backtracking explores untaken branches with the checkpointed taints" {
  let r = propagate(branches(), deterministic=false)
  // in b2 the memory at 0x100 is not tainted: the store happened on the
  // other path, after the checkpoint
  debug_inspect(
    report(r, ["j0", "m1", "v1", "a1", "c1"]),
    content=(
      #|[
      #|  "j0: regs=((x (@seed))) ptrs=()",
      #|  "m1: regs=((x (@seed))) ptrs=()",
      #|  "v1: regs=() ptrs=()",
      #|  "a1: regs=((x (@seed))) ptrs=()",
      #|  "c1: regs=((x (@seed))) ptrs=()",
      #|]
    ),
  )
  let visits = r.visited()
  debug_inspect(
    visits.get(tid("c1")),
    content=(
      #|Some(2)
    ),
  )
}

///|
test "entry points" {
  let r = propagate(branches())
  inspect(r.is_visited(tid("x1")), content="true")
  let prog_subs = branches()
  try
    @propagate_taint.run(
      max_steps=10,
      max_loop=1,
      deterministic=true,
      reg_policy=Random,
      mem_policy=Random,
      project(prog_subs),
      Name("nowhere"),
    )
  catch {
    e =>
      debug_inspect(
        e,
        content=(
          #|EntryPointNotFound
        ),
      )
  } noraise {
    _ => fail("expected EntryPointNotFound")
  }
  let r = @propagate_taint.run(
    max_steps=10,
    max_loop=1,
    deterministic=true,
    reg_policy=Fixed(3),
    mem_policy=Fixed(0),
    project(prog_subs),
    Term(tid("main")),
  )
  inspect(r.is_visited(tid("x1")), content="true")
}

///|
test "concretization policies" {
  debug_inspect(
    ["random", "42", "0x10", "(1 5)", "-3", "(1)", "x"].map(
      @propagate_taint.parse_policy,
    ),
    content=(
      #|[
      #|  Ok(Random),
      #|  Ok(Fixed(42)),
      #|  Ok(Fixed(16)),
      #|  Ok(Interval(1, 5)),
      #|  Ok(Fixed(-3)),
      #|  Err("policy ::= random | <num> | (<num> <num>)"),
      #|  Err("policy ::= random | <num> | (<num> <num>)"),
      #|]
    ),
  )
  inspect(
    @propagate_taint.policy_to_string(Interval(1, 5)),
    content=(
      #|(1 5)
    ),
  )
  let args = @propagate_taint.Args::new()
  inspect(
    "\{args.max_trace} \{args.max_loop} \{args.deterministic} \{@propagate_taint.policy_to_string(args.reg_policy)}",
    content=(
      #|1000000 10 false random
    ),
  )
}

///|
/// main calls f; f contains the seed.
fn callers() -> Array[@types.Term[@types.Sub]] {
  let x = reg("x")
  let y = reg("y")
  let r = reg("r")
  let f = @types.Sub::create(name="f", tid=tid("f"), blks=[
    @types.Blk::create(
      tid=tid("fb"),
      defs=[
        def("f1", x, Var(y)).set_attr(@types.Attr::tainted_reg(tid("seed"))),
        def("f2", r, Var(x)),
      ],
      jmps=[leave("fj")],
    ),
  ])
  let ret = @types.Blk::create(tid=tid("mret"), defs=[def("m2", y, Var(r))], jmps=[
    leave("mj"),
  ])
  let call = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(f.tid()),
      return_label=@types.Label::direct(ret.tid()),
    ),
    tid=tid("call"),
  )
  let entry = @types.Blk::create(tid=tid("mentry"), jmps=[call])
  let main = @types.Sub::create(name="main", tid=tid("main"), blks=[entry, ret])
  let other = @types.Sub::create(name="other", tid=tid("other"), blks=[
    @types.Blk::create(tid=tid("ob"), defs=[def("o1", x, int64(1))]),
  ])
  [main, f, other]
}

///|
fn describe(prog : @types.Term[@types.Program]) -> Array[String] {
  let out = []
  for sub in prog.subs() {
    for blk in sub.blks() {
      for d in blk.defs() {
        out.push(
          "\{d.tid().to_string()}: visited=\{d.is_visited()} regs=\{d.get_attr(@taint.tainted_regs_attr).unwrap_or("-")}",
        )
      }
    }
  }
  out
}

///|
test "the pass analyzes seeded subroutines and their callers" {
  let proj = project(callers())
  let args = @propagate_taint.Args::new(
    reg_policy=Fixed(7),
    mem_policy=Fixed(0),
  )
  let analysis = @propagate_taint.analyze(args, proj)
  inspect(
    analysis.subs,
    content=(
      #|2
    ),
  )
  inspect(
    analysis.coverage_to_string(),
    content=(
      #|[6/6] 100%
    ),
  )
  let proj = @propagate_taint.propagate(args, proj)
  debug_inspect(
    describe(proj.program()),
    content=(
      #|[
      #|  "@m2: visited=true regs=((r (@seed)))",
      #|  "@f1: visited=true regs=((y (@seed)))",
      #|  "@f2: visited=true regs=((x (@seed)))",
      #|  "@o1: visited=false regs=-",
      #|]
    ),
  )
  // only the interesting subroutines (and their callers) are analyzed
  let only_main = @propagate_taint.Args::new(interesting=["main"])
  inspect(
    @propagate_taint.analyze(only_main, project(callers())).subs,
    content=(
      #|0
    ),
  )
  let only_f = @propagate_taint.Args::new(interesting=["f"])
  inspect(
    @propagate_taint.analyze(only_f, project(callers())).subs,
    content=(
      #|2
    ),
  )
  debug_inspect(
    @propagate_taint.register(),
    content=(
      #|Ok(true)
    ),
  )
  debug_inspect(
    @propagate_taint.register(),
    content=(
      #|Ok(false)
    ),
  )
  let marked = project(callers()).run_pass("propagate-taint").unwrap()
  debug_inspect(
    marked.program().subs()[1].blks()[0].defs()[1].get_attr(
      @taint.tainted_regs_attr,
    ),
    content=(
      #|Some("((x (@seed)))")
    ),
  )
}
