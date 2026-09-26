// Calls to external subroutines.
//
// As upstream (`Microx_conqueror.main` over `Biri.t`), a call stores its
// direct return label and jumps to the callee; the callee is evaluated by
// the caller's `eval_fun` loop, *after* the call jump was evaluated. The
// return label is popped only when a jump of the callee leaves it (an
// indirect jump, as in a PLT stub, or a jump out of the subroutine), after
// the checkpoints of the callee are exhausted. A callee without blocks
// never evaluates a jump: `Biri.eval_sub` sets `next` to its (absent) first
// block, the caller's loop stops, and the path ends without reaching the
// return block.

///|
/// start: when c goto call_blk; goto other
/// call_blk: call f with return after
/// after: s := 1; return
/// other: o := 1; return
fn calling(callee : @types.Term[@types.Sub]) -> @types.Term[@types.Program] {
  let c = reg("c", 1)
  let call = @types.Call::create(
    target=Direct(callee.tid()),
    return_label=Direct(tid("after")),
  )
  let main = @types.Sub::create(name="main", tid=tid("main"), blks=[
    @types.Blk::create(
      tid=tid("start"),
      defs=[@types.Def::create(c, Int(w(1, 1)))],
      jmps=[
        @types.Jmp::create_goto(Direct(tid("call_blk")), cond=Var(c)),
        @types.Jmp::create_goto(Direct(tid("other"))),
      ],
    ),
    @types.Blk::create(tid=tid("call_blk"), jmps=[@types.Jmp::create_call(call)]),
    @types.Blk::create(
      tid=tid("after"),
      defs=[@types.Def::create(reg("s", 32), Int(w(32, 1)))],
      jmps=[ret_jmp()],
    ),
    @types.Blk::create(
      tid=tid("other"),
      defs=[@types.Def::create(reg("o", 32), Int(w(32, 1)))],
      jmps=[ret_jmp()],
    ),
  ])
  @types.Program::create(subs=[main, callee])
}

///|
/// An external function without a body.
fn blockless() -> @types.Term[@types.Sub] {
  @types.Sub::create(name="ext", tid=tid("ext"))
}

///|
/// A PLT-like stub: `when d goto s2; jump [lr]` and `s2: jump [lr]`.
fn stub() -> @types.Term[@types.Sub] {
  let d = reg("d", 1)
  @types.Sub::create(name="plt", tid=tid("plt"), blks=[
    @types.Blk::create(
      tid=tid("s1"),
      defs=[@types.Def::create(d, Int(w(1, 0)))],
      jmps=[@types.Jmp::create_goto(Direct(tid("s2")), cond=Var(d)), ret_jmp()],
    ),
    @types.Blk::create(tid=tid("s2"), jmps=[ret_jmp()]),
  ])
}

///|
fn visited(ctxt : @microx.Context, names : Array[String]) -> String {
  names.map(n => "\{n}=\{ctxt.visits(tid(n))}").join(" ")
}

///|
test "a call to a blockless external ends the path" {
  for deterministic in [true, false] {
    let ctxt = @microx.Conqueror::new(deterministic~).run(
      @microx.Context::new(calling(blockless())),
    )
    // the callee is entered, but neither the return block nor (in the
    // non-deterministic mode) the checkpointed branch are reached
    inspect(
      visited(ctxt, ["ext", "after", "other"]),
      content="ext=1 after=0 other=0",
    )
    assert_true(ctxt.next() is None)
  }
}

///|
test "a call to a stub returns through its indirect jump" {
  let ctxt = @microx.Conqueror::new(deterministic=true).run(
    @microx.Context::new(calling(stub())),
  )
  inspect(
    visited(ctxt, ["s1", "s2", "after", "other"]),
    content="s1=1 s2=0 after=1 other=0",
  )
  assert_true(ctxt.lookup(reg("s", 32)) is Some(_))
  // non-deterministic: the checkpoint of the stub (s2) is resumed before
  // returning to the caller, then the caller's checkpoint (other)
  let ctxt = @microx.Conqueror::new().run(@microx.Context::new(calling(stub())))
  inspect(
    visited(ctxt, ["s1", "s2", "after", "other"]),
    content="s1=1 s2=1 after=1 other=1",
  )
  // the final context is the one of the last explored path (other), which
  // branched off before the call
  assert_true(ctxt.lookup(reg("o", 32)) is Some(_))
  assert_true(ctxt.lookup(reg("s", 32)) is None)
}
