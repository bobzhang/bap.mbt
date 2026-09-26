///|
fn live_var(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::Imm(8))
}

///|
fn live_names(vars : Array[@types.Var]) -> String {
  let names = vars.map(v => v.name())
  names.sort()
  names.join(",")
}

///|
fn live_goto(dst : @types.Tid) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_goto(@types.Label::direct(dst))
}

///|
test "Live seeds exit with Out/Both argument free vars and keep" {
  let a = live_var("a")
  let t = live_var("t")
  let x = live_var("x")
  let y = live_var("y")
  let z = live_var("z")
  let w = live_var("w")
  let b0 = @types.Blk::create(tid=@types.Tid::for_name("live.b0"))
  let b1 = @types.Blk::create(tid=@types.Tid::for_name("live.b1"))
  let b0 = b0
    .append_def(@types.Def::create(t, Var(a)))
    .append_jmp(live_goto(b1.tid()))
  let b1 = b1.append_def(@types.Def::create(x, Var(t)))
  let blks = [b0, b1]
  // Without arguments nothing is live at the exit.
  let plain = @types.Live::compute(@types.Sub::create(name="plain", blks~))
  inspect(live_names(plain.outs(b1.tid())), content="")
  inspect(live_names(plain.vars()), content="a")
  // Out/Both argument right-hand sides are live at the exit; In arguments
  // are not.
  let args = [
    @types.Arg::create(live_var("r"), Var(x), intent=Out),
    @types.Arg::create(live_var("s"), Var(w), intent=Both),
    @types.Arg::create(live_var("i"), Var(z), intent=In),
  ]
  let sub = @types.Sub::create(name="seeded", args~, blks~)
  let live = @types.Live::compute(sub)
  inspect(live_names(live.outs(b1.tid())), content="w,x")
  inspect(live_names(live.ins(b1.tid())), content="t,w")
  inspect(live_names(live.vars()), content="a,w")
  let exit = @types.tid_graph_exit()
  inspect(live_names(live.solution().get(exit)), content="w,x")
  // `keep` variables are kept alive at the exit as well.
  let kept = sub.sub_live(keep=[y, t])
  inspect(live_names(kept.outs(b1.tid())), content="t,w,x,y")
  inspect(live_names(kept.vars()), content="a,w,y")
  // The legacy wrappers see the same seeding.
  inspect(live_names(sub.sub_external_vars()), content="a,w")
  inspect(live_names(@types.Sub::free_vars(sub)), content="a,w")
  let wrapped = sub.sub_liveness()
  inspect(live_names(wrapped[1].live_out()), content="w,x")
}

///|
test "Live covers disconnected components via the start pseudo node" {
  let a = live_var("a")
  let b = live_var("b")
  let c = live_var("c")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("live.entry")).append_def(
    @types.Def::create(c, Var(a)),
  )
  // `island` is unreachable from `entry` and has no predecessors.
  let island = @types.Blk::create(tid=@types.Tid::for_name("live.island")).append_jmp(
    @types.Jmp::create_goto(@types.Label::indirect(Var(b))),
  )
  // `loop_head`/`loop_body` form a cycle unreachable from `entry`.
  let loop_head = @types.Blk::create(tid=@types.Tid::for_name("live.loop_head"))
  let loop_body = @types.Blk::create(tid=@types.Tid::for_name("live.loop_body"))
  let loop_head = loop_head.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(loop_body.tid()), cond=Var(c)),
  )
  let loop_body = loop_body.append_jmp(live_goto(loop_head.tid()))
  let sub = @types.Sub::create(name="islands", blks=[
    entry, island, loop_head, loop_body,
  ])
  let live = sub.sub_live()
  inspect(live_names(live.vars()), content="a,b,c")
  inspect(live_names(live.ins(island.tid())), content="b")
  inspect(live_names(live.ins(loop_body.tid())), content="c")
  inspect(live_names(live.ins(entry.tid())), content="a")
  inspect(live_names(sub.sub_live_in_vars()), content="a,b,c")
  inspect(live_names(sub.sub_live_in_vars(entry=entry.tid())), content="a")
  // Unknown blocks have empty live sets.
  let unknown = @types.Tid::for_name("live.unknown")
  inspect(live_names(live.ins(unknown)), content="")
  inspect(live_names(live.outs(unknown)), content="")
}

///|
test "Live exposes upstream defs/uses/blks/fold for phi nodes" {
  let x = live_var("x")
  let y = live_var("y")
  let p = live_var("p")
  let q = live_var("q")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("live.phi.entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("live.phi.body"))
  let header = @types.Blk::create(tid=@types.Tid::for_name("live.phi.header"))
  let done = @types.Blk::create(tid=@types.Tid::for_name("live.phi.done"))
  let entry = entry
    .append_def(@types.Def::create(x, Var(q)))
    .append_jmp(live_goto(header.tid()))
  let body = body
    .append_def(@types.Def::create(y, Var(p)))
    .append_jmp(live_goto(header.tid()))
  let phi = @types.Phi::of_list(p, [(entry.tid(), Var(x)), (body.tid(), Var(y))])
  let header = header
    .append_phi(phi)
    .append_jmp(
      @types.Jmp::create_goto(@types.Label::direct(body.tid()), cond=Var(p)),
    )
    .append_jmp(live_goto(done.tid()))
  let sub = @types.Sub::create(name="phis", blks=[entry, body, header, done])
  let live = @types.Live::compute(sub)
  // Phi left-hand sides are defined by the predecessors; operands defined
  // by the predecessor itself are not upward exposed.
  inspect(live_names(live.defs(entry.tid())), content="p,x")
  inspect(live_names(live.uses(entry.tid())), content="q")
  inspect(live_names(live.defs(body.tid())), content="p,y")
  inspect(live_names(live.uses(body.tid())), content="p")
  inspect(live_names(live.defs(header.tid())), content="")
  inspect(live_names(live.uses(header.tid())), content="p")
  inspect(live_names(live.outs(entry.tid())), content="p")
  inspect(live_names(live.ins(header.tid())), content="p")
  inspect(live_names(live.ins(body.tid())), content="p")
  inspect(live_names(live.vars()), content="q")
  assert_true(live.blks(p).length() == 2)
  assert_true(live.blks(p).all(tid => tid == body.tid() || tid == header.tid()))
  inspect(live.blks(q).length(), content="1")
  let count = live.fold(init=0, (n, _, _) => n + 1)
  inspect(count, content="4")
  let solution = @types.Sub::compute_liveness(sub)
  inspect(live_names(solution.get(entry.tid())), content="p")
  inspect(live.to_string().split("\n").to_array().length(), content="5")
}
