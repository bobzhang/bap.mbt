///|
fn must_find_blk(
  sub : @types.Term[@types.Sub],
  tid : @types.Tid,
) -> @types.Term[@types.Blk] raise {
  match sub.find_blk(tid) {
    Some(blk) => blk
    None => fail("expected block")
  }
}

///|
fn must_find_phi_for(
  phis : Array[@types.Term[@types.Phi]],
  variable : @types.Var,
) -> @types.Term[@types.Phi] raise {
  match phis.search_by(phi => phi.phi_lhs().base() == variable) {
    Some(i) => phis[i]
    None => fail("expected phi")
  }
}

///|
fn int8(value : Int) -> @types.Exp raise @bitvec.BitVecError {
  Int(@types.Word::of_int(width=8, value))
}

///|
test "ssa renames straight-line definitions and uses" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let blk = @types.Blk::create(tid=@types.Tid::for_name("entry"))
    .append_def(@types.Def::create(x, int8(1)))
    .append_def(@types.Def::create(y, Var(x)))
  let sub = @types.Sub::create(name="linear", blks=[blk]).to_ssa()
  assert_true(sub.is_ssa())
  let renamed = must_find_blk(sub, blk.tid())
  let defs = renamed.defs()
  assert_true(defs.length() == 2)
  let x1 = defs[0].lhs()
  let y1 = defs[1].lhs()
  assert_true(x1.base() == x)
  assert_true(x1.index() == 1)
  assert_true(y1.base() == y)
  assert_true(y1.index() == 1)
  assert_true(defs[1].rhs() == Var(x1))
  assert_true(renamed.phis().is_empty())
}

///|
test "ssa inserts phi nodes at diamond joins" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let join = @types.Blk::create(tid=@types.Tid::for_name("join"))
  let entry = entry
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(left.tid())))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(right.tid())))
  let left = left
    .append_def(@types.Def::create(x, int8(1)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(join.tid())))
  let right = right
    .append_def(@types.Def::create(x, int8(2)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(join.tid())))
  let join = join.append_def(@types.Def::create(y, Var(x)))
  let sub = @types.Sub::create(name="diamond", blks=[entry, left, right, join]).to_ssa()
  assert_true(sub.is_ssa())
  let left = must_find_blk(sub, left.tid())
  let right = must_find_blk(sub, right.tid())
  let join = must_find_blk(sub, join.tid())
  let left_x = left.defs()[0].lhs()
  let right_x = right.defs()[0].lhs()
  let phis = join.phis()
  assert_true(phis.length() == 1)
  let phi = phis[0]
  let phi_x = phi.phi_lhs()
  assert_true(left_x.base() == x)
  assert_true(right_x.base() == x)
  assert_true(phi_x.base() == x)
  assert_true(left_x.index() > 0)
  assert_true(right_x.index() > 0)
  assert_true(phi_x.index() > 0)
  assert_true(left_x != right_x)
  assert_true(phi.select(left.tid()) == Some(Var(left_x)))
  assert_true(phi.select(right.tid()) == Some(Var(right_x)))
  let join_defs = join.defs()
  assert_true(join_defs.length() == 1)
  assert_true(join_defs[0].lhs().base() == y)
  assert_true(join_defs[0].rhs() == Var(phi_x))
}

///|
test "ssa inserts loop-carried phi nodes" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let header = @types.Blk::create(tid=@types.Tid::for_name("header"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let entry = entry
    .append_def(@types.Def::create(x, int8(0)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(header.tid())))
  let header = header
    .append_def(@types.Def::create(y, Var(x)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(body.tid())))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(exit.tid())))
  let body = body
    .append_def(@types.Def::create(y, BinOp(Plus, Var(y), int8(1))))
    .append_def(@types.Def::create(x, Var(y)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(header.tid())))
  let sub = @types.Sub::create(name="loop", blks=[entry, header, body, exit]).to_ssa()
  let entry = must_find_blk(sub, entry.tid())
  let header = must_find_blk(sub, header.tid())
  let body = must_find_blk(sub, body.tid())
  let entry_x = entry.defs()[0].lhs()
  let header_y = header.defs()[0].lhs()
  let body_x = body.defs()[1].lhs()
  let phis = header.phis()
  assert_true(phis.length() >= 1)
  let phi = must_find_phi_for(phis, x)
  let phi_x = phi.phi_lhs()
  assert_true(phi_x.base() == x)
  assert_true(header.defs()[0].rhs() == Var(phi_x))
  assert_true(body.defs()[0].rhs() == BinOp(Plus, Var(header_y), int8(1)))
  assert_true(phi.select(entry.tid()) == Some(Var(entry_x)))
  assert_true(phi.select(body.tid()) == Some(Var(body_x)))
}
