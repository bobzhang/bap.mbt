///|
fn w(width : Int32, value : Int32) -> @types.Word {
  try! @types.Word::of_int(width~, value)
}

///|
fn reg(name : String, width : Int32) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
fn imm_of(value : @types.BilResultValue) -> @types.Word? {
  match value {
    BilResultImm(word) => Some(word)
    _ => None
  }
}

///|
test "plain interpreter evaluates constants and yields bottom for unknowns" {
  let x = reg("x", 32)
  let exp : @types.Exp = BinOp(Plus, Int(w(32, 40)), Int(w(32, 2)))
  assert_eq(imm_of(@microx.eval(exp)), Some(w(32, 42)))
  assert_true(@microx.eval(Var(x)) is BilResultBot)
  assert_true(@microx.eval(Unknown("u", Imm(8))) is BilResultBot)
  // bottom is contagious
  assert_true(@microx.eval(BinOp(Plus, Var(x), Int(w(32, 1)))) is BilResultBot)
  // division by zero follows the bitvector semantics (all ones)
  assert_eq(
    imm_of(@microx.eval(BinOp(Div, Int(w(32, 1)), Int(w(32, 0))))),
    Some(w(32, -1)),
  )
}

///|
test "context bindings, let and fresh result identifiers" {
  let x = reg("x", 8)
  let expi = @microx.Expi::new()
  let ctxt = @microx.ExpContext::new()
  let (ctxt, r) = ctxt.create_word(w(8, 7))
  assert_eq(r.id().to_uint64(), 1UL)
  assert_eq(ctxt.next_id().to_uint64(), 2UL)
  let ctxt = ctxt.update(x, r)
  let (ctxt, r) = expi.eval_exp(ctxt, BinOp(Times, Var(x), Int(w(8, 3))))
  assert_eq(imm_of(r.value()), Some(w(8, 21)))
  // `let` restores the previous binding
  let (ctxt, r) = expi.eval_exp(ctxt, Let(x, Int(w(8, 1)), Var(x)))
  assert_eq(imm_of(r.value()), Some(w(8, 1)))
  assert_eq(imm_of(ctxt.lookup(x).unwrap().value()), Some(w(8, 7)))
  assert_eq(ctxt.bindings().length(), 1)
}

///|
test "memory stores and loads through storages" {
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
  let expi = @microx.Expi::new()
  let ctxt = @microx.ExpContext::new()
  let store : @types.Exp = Store(
    mem=Var(mem),
    addr=Int(w(32, 0x100)),
    value=Int(w(32, 0x11223344)),
    endian=LittleEndian,
  )
  let (ctxt, stored) = expi.eval_exp(ctxt, store)
  assert_true(stored.value() is BilResultMem(_))
  let ctxt = ctxt.update(mem, stored)
  let load : @types.Exp = Load(
    mem=Var(mem),
    addr=Int(w(32, 0x100)),
    endian=LittleEndian,
    typ=Imm(32),
  )
  let (ctxt, loaded) = expi.eval_exp(ctxt, load)
  assert_eq(imm_of(loaded.value()), Some(w(32, 0x11223344)))
  let byte : @types.Exp = Load(
    mem=Var(mem),
    addr=Int(w(32, 0x101)),
    endian=BigEndian,
    typ=Imm(8),
  )
  let (ctxt, loaded) = expi.eval_exp(ctxt, byte)
  assert_eq(imm_of(loaded.value()), Some(w(8, 0x33)))
  // an uninitialized cell is bottom
  let missing : @types.Exp = Load(
    mem=Var(mem),
    addr=Int(w(32, 0x200)),
    endian=LittleEndian,
    typ=Imm(8),
  )
  let (_, loaded) = expi.eval_exp(ctxt, missing)
  assert_true(loaded.value() is BilResultBot)
}

///|
test "concretizer policies" {
  let x = reg("x", 16)
  let fixed = @microx.concretizer(
    reg_policy=Fixed(0x12345),
    mem_policy=Fixed(0x1ff),
  )
  let ctxt = @microx.ExpContext::new()
  let (ctxt, r) = fixed.eval_exp(ctxt, Var(x))
  assert_eq(imm_of(r.value()), Some(w(16, 0x2345)))
  // concretized values are not written back into the context
  assert_true(ctxt.lookup(x) is None)
  let (_, r) = fixed.eval_exp(ctxt, Unknown("u", Imm(4)))
  assert_eq(imm_of(r.value()), Some(w(4, 5)))
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
  let load : @types.Exp = Load(
    mem=Var(mem),
    addr=Int(w(32, 0)),
    endian=LittleEndian,
    typ=Imm(16),
  )
  let (_, r) = fixed.eval_exp(ctxt, load)
  assert_eq(imm_of(r.value()), Some(w(16, 0xffff)))
  // interval policy stays in bounds
  let interval = @microx.concretizer(
    reg_policy=Interval(10L, 20L),
    random_seed=7,
  )
  for _ in 0..<50 {
    let (_, r) = interval.eval_exp(ctxt, Var(x))
    let value = try! imm_of(r.value()).unwrap().to_int()
    assert_true(value >= 10 && value <= 20)
  }
  // seeded concretizers are reproducible
  let a = @microx.concretizer(random_seed=42)
  let b = @microx.concretizer(random_seed=42)
  assert_eq(
    a.eval_exp(ctxt, Var(x)).1.value(),
    b.eval_exp(ctxt, Var(x)).1.value(),
  )
  inspect(
    @microx.Policy::Interval(1L, 2L).to_string(),
    content="(Interval 1 2)",
  )
}

///|
test "concretizer consults the user lookup and memory functions" {
  let x = reg("x", 32)
  let y = reg("y", 32)
  let expi = @microx.concretizer(
    lookup=v => if v.name() == "x" { Some(w(32, 5)) } else { None },
    memory=addr => Some(w(8, try! (addr.to_int() & 0xff))),
    reg_policy=Fixed(1L),
  )
  let ctxt = @microx.ExpContext::new()
  let (_, r) = expi.eval_exp(ctxt, BinOp(Plus, Var(x), Var(y)))
  assert_eq(imm_of(r.value()), Some(w(32, 6)))
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
  let load : @types.Exp = Load(
    mem=Var(mem),
    addr=Int(w(32, 0x10)),
    endian=BigEndian,
    typ=Imm(16),
  )
  let (_, r) = expi.eval_exp(ctxt, load)
  assert_eq(imm_of(r.value()), Some(w(16, 0x1011)))
}

///|
fn tid(name : String) -> @types.Tid {
  @types.Tid::for_name(name)
}

///|
fn ret_jmp() -> @types.Term[@types.Jmp] {
  @types.Jmp::create_ret(Indirect(Var(reg("lr", 32))))
}

///|
/// entry: x := 1; when x = 1 goto A; goto B
/// A: y := 2; return
/// B: z := 3; return
fn diamond() -> @types.Term[@types.Program] {
  let x = reg("x", 32)
  let entry = @types.Blk::create(
    tid=tid("entry"),
    defs=[@types.Def::create(x, Int(w(32, 1)))],
    jmps=[
      @types.Jmp::create_goto(
        Direct(tid("A")),
        cond=BinOp(Eq, Var(x), Int(w(32, 1))),
      ),
      @types.Jmp::create_goto(Direct(tid("B"))),
    ],
  )
  let a = @types.Blk::create(
    tid=tid("A"),
    defs=[@types.Def::create(reg("y", 32), Int(w(32, 2)))],
    jmps=[ret_jmp()],
  )
  let b = @types.Blk::create(
    tid=tid("B"),
    defs=[@types.Def::create(reg("z", 32), Int(w(32, 3)))],
    jmps=[ret_jmp()],
  )
  let main = @types.Sub::create(
    name="main",
    blks=[entry, a, b],
    tid=tid("main"),
  )
  @types.Program::create(subs=[main])
}

///|
test "deterministic conqueror follows the feasible path only" {
  let prog = diamond()
  let ctxt = @microx.Conqueror::new(deterministic=true).run(
    @microx.Context::new(prog),
  )
  assert_true(ctxt.visits(tid("A")) > 0)
  assert_eq(ctxt.visits(tid("B")), 0)
  assert_true(ctxt.lookup(reg("y", 32)) is Some(_))
  assert_true(ctxt.lookup(reg("z", 32)) is None)
  assert_true(ctxt.next() is None)
}

///|
test "conqueror explores untaken branches by backtracking" {
  let prog = diamond()
  let ctxt = @microx.Conqueror::new().run(@microx.Context::new(prog))
  assert_true(ctxt.visits(tid("A")) > 0)
  assert_true(ctxt.visits(tid("B")) > 0)
  // backtracking restores the context of the checkpoint, so only the
  // effects of the last explored path remain
  assert_true(ctxt.lookup(reg("z", 32)) is Some(_))
  assert_true(ctxt.lookup(reg("y", 32)) is None)
  assert_true(ctxt.trace().length() > 0)
  assert_eq(ctxt.checkpoints().get(tid("main")).map(m => m.length()), Some(0))
}

///|
/// L: i := i + 1; when i < 100 goto L; goto E
/// E: return
fn counting_loop() -> @types.Term[@types.Program] {
  let i = reg("i", 32)
  let entry = @types.Blk::create(
    tid=tid("init"),
    defs=[@types.Def::create(i, Int(w(32, 0)))],
    jmps=[@types.Jmp::create_goto(Direct(tid("L")))],
  )
  let body = @types.Blk::create(
    tid=tid("L"),
    defs=[@types.Def::create(i, BinOp(Plus, Var(i), Int(w(32, 1))))],
    jmps=[
      @types.Jmp::create_goto(
        Direct(tid("L")),
        cond=BinOp(Lt, Var(i), Int(w(32, 100))),
      ),
      @types.Jmp::create_goto(Direct(tid("E"))),
    ],
  )
  let exit = @types.Blk::create(tid=tid("E"), jmps=[ret_jmp()])
  let main = @types.Sub::create(
    name="main",
    blks=[entry, body, exit],
    tid=tid("main"),
  )
  @types.Program::create(subs=[main])
}

///|
test "conqueror bounds loop iterations" {
  let ctxt = @microx.Conqueror::new().run(
    @microx.Context::new(counting_loop(), max_loop=3),
  )
  assert_eq(ctxt.visits(tid("L")), 4)
  assert_true(ctxt.visits(tid("E")) > 0)
  // deterministic mode with a step budget
  let ctxt = @microx.Conqueror::new(deterministic=true).run(
    @microx.Context::new(counting_loop(), max_steps=5, max_loop=1000),
  )
  assert_eq(ctxt.visits(tid("E")), 0)
  let i = try! imm_of(ctxt.lookup(reg("i", 32)).unwrap().value())
    .unwrap()
    .to_int()
  assert_eq(i, 5)
}

///|
test "conqueror follows calls and returns" {
  let r = reg("r", 32)
  let callee = @types.Sub::create(name="f", tid=tid("f"), blks=[
    @types.Blk::create(
      tid=tid("f_entry"),
      defs=[@types.Def::create(r, Int(w(32, 9)))],
      jmps=[ret_jmp()],
    ),
  ])
  let call = @types.Call::create(
    target=Direct(tid("f")),
    return_label=Direct(tid("after")),
  )
  let main = @types.Sub::create(name="main", tid=tid("main"), blks=[
    @types.Blk::create(tid=tid("start"), jmps=[@types.Jmp::create_call(call)]),
    @types.Blk::create(
      tid=tid("after"),
      defs=[
        @types.Def::create(reg("s", 32), BinOp(Plus, Var(r), Int(w(32, 1)))),
      ],
      jmps=[ret_jmp()],
    ),
  ])
  let prog = @types.Program::create(subs=[main, callee])
  let ctxt = @microx.Conqueror::new(deterministic=true).run(
    @microx.Context::new(prog),
  )
  assert_eq(imm_of(ctxt.lookup(reg("s", 32)).unwrap().value()), Some(w(32, 10)))
  assert_true(ctxt.visits(tid("f_entry")) > 0)
}

///|
test "context checkpoint primitives" {
  let prog = diamond()
  let main = prog.first_sub().unwrap()
  let ctxt = @microx.Context::new(prog).enter_sub(main)
  let ctxt = ctxt.add_checkpoint(tid("A")).add_checkpoint(tid("B"))
  assert_eq(ctxt.checkpoints().get(tid("main")).map(m => m.length()), Some(2))
  let ctxt = ctxt.visit_term(tid("A"))
  let back = ctxt.backtrack().unwrap()
  assert_eq(back.next(), Some(tid("B")))
  // the visited set of the current context is kept
  assert_eq(back.visits(tid("A")), 1)
  assert_eq(back.checkpoints().get(tid("main")).map(m => m.length()), Some(0))
  assert_true(back.backtrack() is None)
  // returns
  let ctxt = ctxt.store_return(tid("r1")).store_return(tid("r2"))
  assert_eq(ctxt.return_().next(), Some(tid("r2")))
  assert_eq(ctxt.return_().return_().next(), Some(tid("r1")))
  assert_eq(ctxt.return_().return_().return_().next(), None)
  assert_true(ctxt.will_return(tid("elsewhere")))
  assert_true(!ctxt.will_return(tid("A")))
  assert_true(ctxt.step() is Some(_))
  assert_true(@microx.Context::new(prog, max_steps=0).step() is None)
}
