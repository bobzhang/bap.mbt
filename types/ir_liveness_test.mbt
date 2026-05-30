///|
fn has_var(vars : Array[@types.Var], variable : @types.Var) -> Bool {
  vars.any(item => item == variable)
}

///|
fn assert_has_var(
  vars : Array[@types.Var],
  variable : @types.Var,
) -> Unit raise {
  assert_true(has_var(vars, variable))
}

///|
fn assert_lacks_var(
  vars : Array[@types.Var],
  variable : @types.Var,
) -> Unit raise {
  assert_true(!has_var(vars, variable))
}

///|
fn liveness_for(
  entries : Array[@types.BlockLiveness],
  block : @types.Term[@types.Blk],
) -> @types.BlockLiveness? {
  entries.search_by(item => item.block().same(block)).map(i => entries[i])
}

///|
test "ir liveness accounts for phi edge operands" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let p = @types.Var::new(name="p", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let header = @types.Blk::create(tid=@types.Tid::for_name("header"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let entry = entry
    .append_def(@types.Def::create(x, Int(word8(1))))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(header.tid())))
  let body = body
    .append_def(@types.Def::create(y, Int(word8(2))))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(header.tid())))
  let phi = @types.Phi::of_list(p, [(entry.tid(), Var(x)), (body.tid(), Var(y))])
  let header = header
    .append_phi(phi)
    .append_jmp(
      @types.Jmp::create_goto(@types.Label::direct(body.tid()), cond=Var(p)),
    )
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(exit.tid())))
  let sub = @types.Sub::create(name="live", blks=[entry, header, body, exit])
  assert_has_var(header.blk_defined_vars(), p)
  assert_has_var(phi.phi_edge_free_vars(entry.tid()), x)
  assert_lacks_var(phi.phi_edge_free_vars(entry.tid()), y)
  assert_has_var(header.blk_phi_edge_free_vars(body.tid()), y)
  let liveness = sub.sub_liveness()
  match liveness_for(liveness, entry) {
    Some(info) => {
      assert_has_var(info.live_out(), x)
      assert_lacks_var(info.live_in(), x)
      assert_lacks_var(info.live_in(), p)
    }
    None => fail("expected entry liveness")
  }
  match liveness_for(liveness, body) {
    Some(info) => {
      assert_has_var(info.live_out(), y)
      assert_lacks_var(info.live_in(), y)
      assert_lacks_var(info.live_in(), p)
    }
    None => fail("expected body liveness")
  }
  match liveness_for(liveness, header) {
    Some(info) => {
      assert_has_var(info.live_in(), p)
      assert_lacks_var(info.live_out(), p)
    }
    None => fail("expected header liveness")
  }
}

///|
test "ir liveness reports ordinary block uses" {
  let typ = @types.ValueType::Imm(8)
  let flag = @types.Var::new(name="guard", typ~)
  let start = @types.Blk::create(tid=@types.Tid::for_name("start"))
  let done = @types.Blk::create(tid=@types.Tid::for_name("done"))
  let start = start.append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(done.tid()), cond=Var(flag)),
  )
  let sub = @types.Sub::create(name="guarded", blks=[start, done])
  let liveness = sub.sub_liveness()
  match liveness_for(liveness, start) {
    Some(info) => {
      assert_has_var(info.live_in(), flag)
      assert_lacks_var(info.live_out(), flag)
    }
    None => fail("expected start liveness")
  }
}

///|
test "block value free vars include phi operands and ordinary uses" {
  let typ = @types.ValueType::Imm(8)
  let input = @types.Var::new(name="input", typ~)
  let phi_lhs = @types.Var::new(name="x", typ~).with_index(1)
  let pred = @types.Tid::for_name("pred")
  let done = @types.Tid::for_name("done")
  let phi = @types.Phi::of_list(phi_lhs, [(pred, Var(input))])
  let blk = @types.Blk::create(phis=[phi]).append_jmp(
    @types.Jmp::create_goto(@types.Label::direct(done), cond=Var(phi_lhs)),
  )
  let vars = blk.blk_value_free_vars()
  assert_has_var(vars, input)
  assert_has_var(vars, phi_lhs)
}

///|
test "sub external vars use liveness before SSA and undefined vars after SSA" {
  let typ = @types.ValueType::Imm(8)
  let input = @types.Var::new(name="input", typ~)
  let x = @types.Var::new(name="x", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry")).append_def(
    @types.Def::create(x, Var(input)),
  )
  let sub = @types.Sub::create(name="free", blks=[entry])
  let before = sub.sub_external_vars()
  assert_has_var(before, input)
  assert_lacks_var(before, x)
  let ssa = sub.to_ssa()
  let after = ssa.sub_external_vars()
  assert_has_var(after, input)
  assert_lacks_var(after, x.with_index(1))
}
