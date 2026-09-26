// Calls to external subroutines follow the microx conqueror (and upstream
// `Microx_conqueror`): a callee without blocks ends the path, a stub whose
// body leaves through an indirect jump returns to the caller's return
// block, after its own checkpoints are explored.

///|
/// start: x := y (seed); when x = 3 goto call_blk; goto other
/// call_blk: call callee with return after
/// after: a := x; return
/// other: o := x; return
fn calling(callee : @types.Term[@types.Sub]) -> Array[@types.Term[@types.Sub]] {
  let x = reg("x")
  let call = @types.Call::create(
    target=Direct(callee.tid()),
    return_label=Direct(tid("after")),
  )
  let main = @types.Sub::create(name="main", tid=tid("main"), blks=[
    @types.Blk::create(
      tid=tid("start"),
      defs=[
        def("x1", x, Var(reg("y"))).set_attr(
          @types.Attr::tainted_reg(tid("seed")),
        ),
      ],
      jmps=[
        @types.Jmp::create_goto(
          Direct(tid("call_blk")),
          cond=BinOp(Eq, Var(x), int64(3)),
        ),
        @types.Jmp::create_goto(Direct(tid("other"))),
      ],
    ),
    @types.Blk::create(tid=tid("call_blk"), jmps=[
      @types.Jmp::create_call(call, tid=tid("call")),
    ]),
    @types.Blk::create(tid=tid("after"), defs=[def("a1", reg("a"), Var(x))], jmps=[
      leave("after_ret"),
    ]),
    @types.Blk::create(tid=tid("other"), defs=[def("o1", reg("o"), Var(x))], jmps=[
      leave("other_ret"),
    ]),
  ])
  [main, callee]
}

///|
/// A PLT-like stub: `when d goto s2; jump [0]` and `s2: jump [0]`.
fn plt_stub() -> @types.Term[@types.Sub] {
  let d = @types.Var::create("d", Imm(1))
  @types.Sub::create(name="plt", tid=tid("plt"), blks=[
    @types.Blk::create(
      tid=tid("s1"),
      defs=[def("d1", d, Int(try! @types.Word::of_int(width=1, 0)))],
      jmps=[
        @types.Jmp::create_goto(Direct(tid("s2")), cond=Var(d)),
        leave("s1_ret"),
      ],
    ),
    @types.Blk::create(tid=tid("s2"), jmps=[leave("s2_ret")]),
  ])
}

///|
test "a call to a blockless external ends the path" {
  let ext = @types.Sub::create(name="ext", tid=tid("ext"))
  for deterministic in [true, false] {
    let r = propagate(calling(ext), deterministic~)
    debug_inspect(
      report(r, ["x1", "a1", "o1"]),
      content=(
        #|[
        #|  "x1: regs=((y (@seed))) ptrs=()",
        #|  "a1: regs=() ptrs=() (not visited)",
        #|  "o1: regs=() ptrs=() (not visited)",
        #|]
      ),
    )
  }
}

///|
test "a call to a stub returns to the caller" {
  let r = propagate(calling(plt_stub()), deterministic=true)
  debug_inspect(
    report(r, ["a1", "o1"]),
    content=(
      #|[
      #|  "a1: regs=((x (@seed))) ptrs=()",
      #|  "o1: regs=() ptrs=() (not visited)",
      #|]
    ),
  )
  // non-deterministic: the stub's checkpoint, the return block and the
  // caller's checkpoint are all explored
  let r = propagate(calling(plt_stub()), deterministic=false)
  debug_inspect(
    report(r, ["s2_ret", "a1", "o1"]),
    content=(
      #|[
      #|  "s2_ret: regs=() ptrs=()",
      #|  "a1: regs=((x (@seed))) ptrs=()",
      #|  "o1: regs=((x (@seed))) ptrs=()",
      #|]
    ),
  )
}
