///|
struct BapSemaFixture {
  entry : @types.Term[@types.Blk]
  b1 : @types.Term[@types.Blk]
  b2 : @types.Term[@types.Blk]
  b3 : @types.Term[@types.Blk]
  b4 : @types.Term[@types.Blk]
  b5 : @types.Term[@types.Blk]
  b6 : @types.Term[@types.Blk]
  exit : @types.Term[@types.Blk]
  i : @types.Var
  j : @types.Var
  k : @types.Var
  sub : @types.Term[@types.Sub]
}

///|
fn bap_word32(value : Int32) -> @types.Word raise @bitvec.BitVecError {
  @types.Word::of_int(width=32, value)
}

///|
fn bap_int32(value : Int32) -> @types.Exp raise @bitvec.BitVecError {
  Int(bap_word32(value))
}

///|
fn bap_bool(value : Bool) -> @types.Exp {
  Int(if value { @types.Word::b1() } else { @types.Word::b0() })
}

///|
fn bap_goto(dst : @types.Term[@types.Blk]) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_goto(@types.Label::direct(dst.tid()))
}

///|
fn bap_cond(
  blk : @types.Term[@types.Blk],
  cond : @types.Exp,
  yes : @types.Term[@types.Blk],
  no : @types.Term[@types.Blk],
) -> @types.Term[@types.Blk] {
  blk
  .append_jmp(@types.Jmp::create_goto(@types.Label::direct(yes.tid()), cond~))
  .append_jmp(bap_goto(no))
}

///|
fn make_bap_sema_fixture() -> BapSemaFixture raise @bitvec.BitVecError {
  let reg32 = @types.ValueType::Imm(32)
  let bool_t = @types.ValueType::Imm(1)
  let i = @types.Var::new(name="i", typ=reg32)
  let j = @types.Var::new(name="j", typ=reg32)
  let k = @types.Var::new(name="k", typ=bool_t)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let b1 = @types.Blk::create(tid=@types.Tid::for_name("b1"))
  let b2 = @types.Blk::create(tid=@types.Tid::for_name("b2"))
  let b3 = @types.Blk::create(tid=@types.Tid::for_name("b3"))
  let b4 = @types.Blk::create(tid=@types.Tid::for_name("b4"))
  let b5 = @types.Blk::create(tid=@types.Tid::for_name("b5"))
  let b6 = @types.Blk::create(tid=@types.Tid::for_name("b6"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let entry = entry.append_jmp(bap_goto(b1))
  let b1 = b1
    .append_def(@types.Def::create(k, bap_bool(false)))
    .append_def(@types.Def::create(i, bap_int32(1)))
    .append_def(@types.Def::create(j, bap_int32(2)))
    .append_jmp(bap_goto(b2))
  let b2 = bap_cond(b2, BinOp(Le, Var(i), Var(j)), b3, b4)
  let b3 = b3
    .append_def(@types.Def::create(j, BinOp(Times, Var(j), bap_int32(2))))
    .append_def(@types.Def::create(k, bap_bool(true)))
    .append_def(@types.Def::create(i, BinOp(Plus, Var(i), bap_int32(1))))
    .append_jmp(bap_goto(b2))
  let b4 = bap_cond(b4, Var(k), b5, b6)
  let call = @types.Call::create(
    target=@types.Label::indirect(Var(j)),
    return_label=@types.Label::direct(exit.tid()),
  )
  let b5 = b5.append_jmp(@types.Jmp::create_call(call))
  let b6 = b6
    .append_def(@types.Def::create(i, BinOp(Plus, Var(i), bap_int32(1))))
    .append_jmp(bap_goto(exit))
  let sub = @types.Sub::create(name="example", blks=[
    entry, b1, b2, b3, b4, b5, b6, exit,
  ])
  { entry, b1, b2, b3, b4, b5, b6, exit, i, j, k, sub, }
}

///|
fn bap_assert_vars_contain(
  actual : Array[@types.Var],
  expected : Array[@types.Var],
) -> Unit raise {
  for variable in expected {
    assert_true(actual.contains(variable))
  }
}

///|
fn bap_liveness_for(
  entries : Array[@types.BlockLiveness],
  block : @types.Term[@types.Blk],
) -> @types.BlockLiveness raise {
  match entries.search_by(info => info.block().tid() == block.tid()) {
    Some(i) => entries[i]
    None => fail("expected block liveness")
  }
}

///|
fn bap_assert_live_contains(
  liveness : Array[@types.BlockLiveness],
  block : @types.Term[@types.Blk],
  expected : Array[@types.Var],
) -> Unit raise {
  let live_in = bap_liveness_for(liveness, block).live_in()
  for variable in expected {
    if !live_in.contains(variable) {
      fail("expected \{variable.to_string()} live at \{block.name()}")
    }
  }
}

///|
fn bap_find_phi(
  sub : @types.Term[@types.Sub],
  variable : @types.Var,
  index : Int32,
) -> @types.Term[@types.Phi] raise {
  match
    sub
    .sub_phis()
    .search_by(phi => {
      phi.phi_lhs().base() == variable && phi.phi_lhs().index() == index
    }) {
    Some(i) => sub.sub_phis()[i]
    None => fail("expected SSA phi node")
  }
}

///|
fn bap_assert_phi_edge(
  sub : @types.Term[@types.Sub],
  variable : @types.Var,
  index : Int32,
  predecessor : @types.Term[@types.Blk],
  predecessor_index : Int32,
) -> Unit raise {
  let phi = bap_find_phi(sub, variable, index)
  assert_true(
    phi.select(predecessor.tid()) ==
    Some(Var(variable.with_index(predecessor_index))),
  )
}

///|
fn bap_assert_cfg_edge(
  cfg : @graphlib.Graph[@types.Tid, @types.Tid],
  src : @types.Term[@types.Blk],
  dst : @types.Term[@types.Blk],
) -> Unit raise {
  if !cfg.has_edge(src.tid(), dst.tid()) {
    fail("expected CFG edge \{src.name()} -> \{dst.name()}")
  }
}

///|
fn bap_insert_cfg(blks : Array[@types.Term[@types.Blk]]) -> @types.IrCfg {
  let mut cfg = @types.IrCfg::create(name="inserted")
  for blk in blks {
    cfg = cfg.insert_node(blk)
  }
  cfg
}

///|
fn bap_assert_ir_cfg_matches(
  expected : @types.IrCfg,
  actual : @types.IrCfg,
) -> Unit raise {
  assert_true(actual.node_count() == expected.node_count())
  assert_true(actual.edge_count() == expected.edge_count())
  assert_true(actual.edges().length() == expected.edges().length())
  for edge in expected.edges() {
    if !actual.has_edge(edge.src(), edge.dst()) {
      fail("expected CFG edge \{edge.src().name()} -> \{edge.dst().name()}")
    }
  }
  for blk in actual.nodes() {
    assert_true(actual.degree(blk) != 0)
  }
}

///|
test "translated BAP sema fixture builds expected CFG edges" {
  let f = make_bap_sema_fixture()
  let cfg = f.sub.sub_cfg()
  inspect(cfg.node_count(), content="8")
  inspect(cfg.edge_count(), content="9")
  bap_assert_cfg_edge(cfg, f.entry, f.b1)
  bap_assert_cfg_edge(cfg, f.b1, f.b2)
  bap_assert_cfg_edge(cfg, f.b2, f.b3)
  bap_assert_cfg_edge(cfg, f.b2, f.b4)
  bap_assert_cfg_edge(cfg, f.b3, f.b2)
  bap_assert_cfg_edge(cfg, f.b4, f.b5)
  bap_assert_cfg_edge(cfg, f.b4, f.b6)
  bap_assert_cfg_edge(cfg, f.b5, f.exit)
  bap_assert_cfg_edge(cfg, f.b6, f.exit)
  for block in [f.entry, f.b1, f.b2, f.b3, f.b4, f.b5, f.b6, f.exit] {
    assert_true(cfg.degree(block.tid()) != 0)
  }
}

///|
test "translated BAP IR CFG insertion order materializes all fixture edges" {
  let f = make_bap_sema_fixture()
  let expected = f.sub.to_cfg()
  let forward = [f.entry, f.b1, f.b2, f.b3, f.b4, f.b5, f.b6, f.exit]
  let reverse = [f.exit, f.b6, f.b5, f.b4, f.b3, f.b2, f.b1, f.entry]
  let mixed = [f.b2, f.b4, f.exit, f.b5, f.b6, f.b3, f.b1, f.entry]
  for order in [forward, reverse, mixed] {
    let actual = bap_insert_cfg(order)
    bap_assert_ir_cfg_matches(expected, actual)
  }
}

///|
test "translated BAP sema fixture reports expected block free vars" {
  let f = make_bap_sema_fixture()
  bap_assert_vars_contain(f.entry.blk_free_vars(), [])
  bap_assert_vars_contain(f.b1.blk_free_vars(), [])
  bap_assert_vars_contain(f.b2.blk_free_vars(), [f.i, f.j])
  bap_assert_vars_contain(f.b3.blk_free_vars(), [f.i])
  bap_assert_vars_contain(f.b4.blk_free_vars(), [f.k])
  bap_assert_vars_contain(f.b5.blk_free_vars(), [f.j])
  bap_assert_vars_contain(f.b6.blk_free_vars(), [f.i])
  bap_assert_vars_contain(f.exit.blk_free_vars(), [])
  bap_assert_vars_contain(f.sub.sub_external_vars(), [])
}

///|
test "translated BAP sema fixture builds expected SSA phi edges" {
  let f = make_bap_sema_fixture()
  let ssa = f.sub.to_ssa()
  bap_assert_phi_edge(ssa, f.i, 2, f.b1, 1)
  bap_assert_phi_edge(ssa, f.i, 2, f.b3, 3)
  bap_assert_phi_edge(ssa, f.j, 2, f.b1, 1)
  bap_assert_phi_edge(ssa, f.j, 2, f.b3, 3)
  bap_assert_phi_edge(ssa, f.k, 2, f.b1, 1)
  bap_assert_phi_edge(ssa, f.k, 2, f.b3, 3)
  bap_assert_phi_edge(ssa, f.i, 5, f.b5, 2)
  bap_assert_phi_edge(ssa, f.i, 5, f.b6, 4)
}

///|
test "translated BAP sema fixture keeps expected SSA liveness" {
  let f = make_bap_sema_fixture()
  let ssa = f.sub.to_ssa()
  let live = ssa.sub_liveness()
  bap_assert_live_contains(live, f.entry, [])
  bap_assert_live_contains(live, f.b1, [])
  bap_assert_live_contains(live, f.b2, [
    f.i.with_index(2),
    f.j.with_index(2),
    f.k.with_index(2),
  ])
  bap_assert_live_contains(live, f.b3, [f.i.with_index(2), f.j.with_index(2)])
  bap_assert_live_contains(live, f.b4, [
    f.i.with_index(2),
    f.j.with_index(2),
    f.k.with_index(2),
  ])
  bap_assert_live_contains(live, f.b5, [f.i.with_index(2), f.j.with_index(2)])
  bap_assert_live_contains(live, f.b6, [f.i.with_index(2)])
  bap_assert_live_contains(live, f.exit, [])
}
