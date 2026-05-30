///|
fn def_lhs_names(defs : Array[@types.Term[@types.Def]]) -> Array[String] {
  [
    for term in defs => term.lhs().name
  ]
}

///|
fn assert_def_lhs_names(
  block : @types.Term[@types.Blk],
  expected : Array[String],
) -> Unit raise {
  assert_true(def_lhs_names(block.defs()) == expected)
}

///|
test "block definition sequence helpers follow BAP term order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  assert_true(block.def_count() == 3)
  assert_true(block.first_def().map(term => term.lhs()) == Some(x))
  assert_true(block.last_def().map(term => term.lhs()) == Some(z))
  assert_true(block.nth_def(1).map(term => term.lhs()) == Some(y))
  assert_true(block.nth_def(-1) is None)
  assert_true(block.nth_def(3) is None)
  assert_true(block.next_def(def_x.tid()).map(term => term.lhs()) == Some(y))
  assert_true(block.prev_def(def_z.tid()).map(term => term.lhs()) == Some(y))
  assert_true(block.prev_def(def_x.tid()) is None)
}

///|
test "block before and after definition slices support reverse order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  assert_true(def_lhs_names(block.defs_after(def_x.tid())) == ["y", "z"])
  assert_true(
    def_lhs_names(block.defs_after(def_x.tid(), rev=true)) == ["z", "y"],
  )
  assert_true(def_lhs_names(block.defs_before(def_z.tid())) == ["x", "y"])
  assert_true(
    def_lhs_names(block.defs_before(def_z.tid(), rev=true)) == ["y", "x"],
  )
  assert_true(block.defs_after(@types.Tid::for_name("missing")).is_empty())
  assert_true(block.def_occurs_after(def_x.tid(), def_z.tid()))
  assert_true(block.def_occurs_after(def_y.tid(), def_y.tid()))
  assert_true(!block.def_occurs_after(def_z.tid(), def_x.tid()))
}

///|
test "block definition editing helpers insert update remove and map" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let o = @types.Var::new(name="o", typ~)
  let s = @types.Var::new(name="s", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let def_o = @types.Def::create(o, Int(word8(4)))
  let def_s = @types.Def::create(s, Int(word8(5)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  let inserted = block
    .insert_def_after(def_o, after=def_x.tid())
    .insert_def_before(def_s)
  assert_def_lhs_names(inserted, ["s", "x", "o", "y", "z"])
  let unchanged = inserted.insert_def_after(
    @types.Def::create(o, Int(word8(6))),
    after=@types.Tid::for_name("absent"),
  )
  assert_def_lhs_names(unchanged, ["s", "x", "o", "y", "z"])
  let renamed_y = def_y.with_lhs(s)
  assert_def_lhs_names(block.update_def(renamed_y), ["x", "s", "z"])
  assert_def_lhs_names(inserted.remove_def(def_o.tid()), ["s", "x", "y", "z"])
  assert_def_lhs_names(
    block.map_defs(term => if term.lhs() == y { term.with_lhs(s) } else { term }),
    ["x", "s", "z"],
  )
  assert_def_lhs_names(block.filter_defs(term => term.lhs() != y), ["x", "z"])
  assert_def_lhs_names(
    block.filter_map_defs(term => {
      if term.lhs() == y {
        None
      } else {
        Some(term)
      }
    }),
    ["x", "z"],
  )
  assert_def_lhs_names(
    block.concat_map_defs(term => {
      if term.lhs() == y {
        [term, term]
      } else {
        [term]
      }
    }),
    ["x", "y", "y", "z"],
  )
}

///|
test "block phi jump and sub update helpers map terms" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let pred = @types.Tid::for_name("pred")
  let dst = @types.Tid::for_name("dst")
  let phi = @types.Phi::of_list(x, [(pred, Var(y))])
  let jmp = @types.Jmp::create_goto(@types.Label::direct(dst), cond=Var(x))
  let block = @types.Blk::create(phis=[phi], jmps=[jmp])
  let updated_phi = phi.with_phi_lhs(y)
  let updated_block = block.update_phi_term(updated_phi)
  assert_true(updated_block.phis()[0].phi_lhs() == y)
  assert_true(
    block.map_phis(term => term.with_phi_lhs(y)).phis()[0].phi_lhs() == y,
  )
  assert_true(block.remove_phi_term(phi.tid()).phis().is_empty())
  let updated_jmp = jmp.with_cond(Var(y))
  assert_true(block.update_jmp(updated_jmp).jmps()[0].cond() == Var(y))
  assert_true(
    block.map_jmps(term => term.with_cond(Var(y))).jmps()[0].cond() == Var(y),
  )
  assert_true(block.remove_jmp(jmp.tid()).jmps().is_empty())
  let sub = @types.Sub::create(name="main", blks=[block])
  let rewritten = block.append_def(@types.Def::create(y, Var(x)))
  assert_true(
    sub.update_blk(rewritten).find_blk(block.tid()).map(blk => blk.def_count()) ==
    Some(1),
  )
  assert_true(
    sub.map_blks(blk => blk.append_def(@types.Def::create(y, Var(x)))).blks()[0].def_count() ==
    1,
  )
}

///|
test "block definition split helpers preserve control transfer shape" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let exit = @types.Tid::for_name("exit")
  let jmp = @types.Jmp::create_goto(@types.Label::direct(exit))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z], jmps=[jmp])
  let before = block.split_before_def(def_y)
  assert_def_lhs_names(before.0, ["x"])
  assert_def_lhs_names(before.1, ["y", "z"])
  match before.0.jmps()[0].kind() {
    Goto(Direct(tid)) => assert_true(tid == before.1.tid())
    _ => fail("split block must jump to the second block")
  }
  assert_true(before.1.jmps()[0].same(jmp))
  let after = block.split_after_def(def_y)
  assert_def_lhs_names(after.0, ["x", "y"])
  assert_def_lhs_names(after.1, ["z"])
  let top = block.split_top_defs()
  assert_def_lhs_names(top.0, [])
  assert_def_lhs_names(top.1, ["x", "y", "z"])
  let bottom = block.split_bottom_defs()
  assert_def_lhs_names(bottom.0, ["x", "y", "z"])
  assert_def_lhs_names(bottom.1, [])
}

///|
test "block variable lookup prefers latest definitions then phi bindings" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let pred = @types.Tid::for_name("pred")
  let phi = @types.Phi::of_list(x, [(pred, Var(z))])
  let def_y1 = @types.Def::create(y, Int(word8(1)))
  let def_y2 = @types.Def::create(y, BinOp(Plus, Var(x), Int(word8(2))))
  let block = @types.Blk::create(phis=[phi], defs=[def_y1, def_y2])
  match block.find_var(y) {
    Some(DefBinding(term)) => assert_true(term.same(def_y2))
    _ => fail("expected latest def binding")
  }
  match block.find_var(x) {
    Some(PhiBinding(term)) => assert_true(term.same(phi))
    _ => fail("expected phi binding")
  }
  assert_true(block.uses_var(x))
  assert_true(!block.uses_var(y))
  assert_true(block.find_var(z) is None)
}
