///|
fn ssa_start_var(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::Imm(8))
}

///|
fn ssa_start_render(exp : @types.Exp?) -> String {
  match exp {
    Some(Var(v)) => "\{v.base().name()}.\{v.index()}"
    Some(_) => "<exp>"
    None => "none"
  }
}

///|
test "ssa inserts a phi at an entry block with a back-edge (pseudo start)" {
  let i = ssa_start_var("i")
  let c = ssa_start_var("c")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("ssa.start.entry"))
  let done = @types.Blk::create(tid=@types.Tid::for_name("ssa.start.done"))
  let entry = entry
    .append_def(@types.Def::create(i, BinOp(Plus, Var(i), int8(1))))
    .append_jmp(
      @types.Jmp::create_goto(@types.Label::direct(entry.tid()), cond=Var(c)),
    )
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(done.tid())))
  let sub = @types.Sub::create(name="self_loop", blks=[entry, done]).to_ssa()
  let entry = must_find_blk(sub, entry.tid())
  // Upstream: the entry block has two predecessors in the tid graph (the
  // pseudo start node and itself), so `i` defined in the loop gets a phi at
  // the entry; the pseudo start node does not contribute an operand.
  let phis = entry.phis()
  inspect(phis.length(), content="1")
  let phi = phis[0]
  inspect(phi.phi_lhs().index(), content="1")
  inspect(phi.values().length(), content="1")
  inspect(ssa_start_render(phi.select(entry.tid())), content="i.2")
  let def = entry.defs()[0]
  inspect(def.lhs().index(), content="2")
  assert_true(def.rhs() == BinOp(Plus, Var(i.with_index(1)), int8(1)))
  // The guard is still an upward-exposed use.
  let free = @types.Sub::free_vars(sub)
  assert_true(free.contains(c))
}

///|
test "ssa renames blocks of components disconnected from the first block" {
  let x = ssa_start_var("x")
  let y = ssa_start_var("y")
  let z = ssa_start_var("z")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("ssa.dis.entry"))
  let island = @types.Blk::create(tid=@types.Tid::for_name("ssa.dis.island"))
  let join = @types.Blk::create(tid=@types.Tid::for_name("ssa.dis.join"))
  let entry = entry
    .append_def(@types.Def::create(x, int8(1)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(join.tid())))
  // `island` has no predecessors, so it is a root connected to start.
  let island = island
    .append_def(@types.Def::create(y, Var(x)))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(join.tid())))
  let join = join.append_def(@types.Def::create(z, Var(x)))
  let sub = @types.Sub::create(name="islands", blks=[entry, island, join]).to_ssa()
  let island = must_find_blk(sub, island.tid())
  let join = must_find_blk(sub, join.tid())
  // The island is renamed (its definition gets an index) and reads the
  // undefined, index-0 version of `x`.
  inspect(island.defs()[0].lhs().index(), content="1")
  assert_true(island.defs()[0].rhs() == Var(x))
  // The join merges both roots through a phi with one operand per real
  // predecessor block.
  let phi = must_find_phi_for(join.phis(), x)
  inspect(phi.values().length(), content="2")
  inspect(ssa_start_render(phi.select(entry.tid())), content="x.1")
  inspect(ssa_start_render(phi.select(island.tid())), content="x.0")
  assert_true(join.defs()[0].rhs() == Var(phi.phi_lhs()))
  // `x` is used undefined in the island, hence free in the SSA subroutine.
  let free = @types.Sub::free_vars(sub)
  assert_true(free.contains(x))
  assert_true(!free.contains(y))
}

///|
test "ssa renames a disconnected cycle rooted at its first block" {
  let x = ssa_start_var("x")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("ssa.cyc.entry"))
  let a = @types.Blk::create(tid=@types.Tid::for_name("ssa.cyc.a"))
  let b = @types.Blk::create(tid=@types.Tid::for_name("ssa.cyc.b"))
  let a = a
    .append_def(@types.Def::create(x, BinOp(Plus, Var(x), int8(1))))
    .append_jmp(@types.Jmp::create_goto(@types.Label::direct(b.tid())))
  let b = b.append_jmp(@types.Jmp::create_goto(@types.Label::direct(a.tid())))
  let sub = @types.Sub::create(name="cycle", blks=[entry, a, b]).to_ssa()
  let a = must_find_blk(sub, a.tid())
  // `a` is connected to start (it is the first unreachable block of the
  // cycle), so it has predecessors {start, b} and receives a phi for `x`.
  let phi = must_find_phi_for(a.phis(), x)
  inspect(phi.values().length(), content="1")
  inspect(ssa_start_render(phi.select(b.tid())), content="x.2")
  assert_true(a.defs()[0].rhs() == BinOp(Plus, Var(phi.phi_lhs()), int8(1)))
  inspect(a.defs()[0].lhs().index(), content="2")
}
