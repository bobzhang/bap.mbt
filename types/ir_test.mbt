///|
test "terms carry tids and string attributes" {
  let tid = @types.Tid::for_name("entry")
  let term = @types.Program::create(tid~).set_attr(@types.Attr::comment("root"))
  inspect(term.name(), content="@entry")
  assert_true(term.get_attr("comment") == Some("root"))
  assert_true(term.has_attr("comment"))
  let clone = term.clone()
  assert_true(!term.same(clone))
  assert_true(clone.get_attr("comment") == Some("root"))
}

///|
test "program sub and block containers preserve term order" {
  let typ = @types.ValueType::Imm(32)
  let lhs = @types.Var::new(name="x", typ~)
  let def = @types.Def::create(lhs, Int(@types.Word::of_int(width=32, 1)))
  let dst = @types.Tid::for_name("exit")
  let jmp = @types.Jmp::create_goto(@types.Label::direct(dst))
  let blk = @types.Blk::create().append_def(def).append_jmp(jmp)
  let sub = @types.Sub::create(name="main").append_blk(blk)
  let program = @types.Program::create().append_sub(sub)
  assert_true(program.find_sub(sub.tid()) is Some(_))
  assert_true(sub.find_blk(blk.tid()) is Some(_))
  assert_true(blk.find_def(def.tid()) is Some(_))
  assert_true(blk.defines_var(lhs))
  inspect(blk.elts().length().to_string(), content="2")
}

///|
test "program traversal helpers enumerate nested IR terms" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let arg = @types.Arg::create(x, Var(y))
  let pred = @types.Tid::for_name("pred")
  let phi = @types.Phi::of_list(x, [(pred, Var(y))])
  let def = @types.Def::create(y, Int(word8(1)))
  let jmp = @types.Jmp::create_goto(@types.Label::direct(pred))
  let blk = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  let program = @types.Program::create(subs=[sub])
  assert_true(program.program_args().length() == 1)
  assert_true(program.program_blks().length() == 1)
  assert_true(program.program_phis().map(term => term.tid()) == [phi.tid()])
  assert_true(program.program_defs().map(term => term.tid()) == [def.tid()])
  assert_true(program.program_jmps().map(term => term.tid()) == [jmp.tid()])
  assert_true(sub.sub_phis().length() == 1)
  assert_true(sub.sub_defs().length() == 1)
  assert_true(sub.sub_jmps().length() == 1)
  assert_true(blk.find_phi(phi.tid()) is Some(_))
  assert_true(blk.find_jmp(jmp.tid()) is Some(_))
  assert_true(program.program_find_blk(blk.tid()) is Some(_))
  assert_true(program.program_find_phi(phi.tid()) is Some(_))
  assert_true(program.program_find_def(def.tid()) is Some(_))
  assert_true(program.program_find_jmp(jmp.tid()) is Some(_))
}

///|
test "phi nodes jumps calls and args expose BAP-style payloads" {
  let typ = @types.ValueType::Imm(8)
  let lhs = @types.Var::new(name="r0", typ~)
  let left = @types.Tid::for_name("left")
  let right = @types.Tid::for_name("right")
  let one = @types.Int(@types.Word::of_int(width=8, 1))
  let two = @types.Int(@types.Word::of_int(width=8, 2))
  let phi = @types.Phi::of_list(lhs, [(left, one)]).update_phi(right, two)
  assert_true(phi.select(left) == Some(one))
  assert_true(phi.select(right) == Some(two))
  let call = @types.Call::create(target=@types.Label::direct(left)).with_return(
    @types.Label::direct(right),
  )
  let jmp = @types.Jmp::create_call(call)
  inspect(jmp.kind().to_string(), content="call @left")
  let arg = @types.Arg::create(lhs, one).with_intent(Both)
  assert_true(arg.intent() == Some(Both))
}

///|
test "ir definition phi and jump helpers traverse expressions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let one = @types.Int(word8(1))
  let def = @types.Def::create(x, BinOp(Plus, Var(y), one))
  let def_vars = def.def_free_vars()
  assert_true(def_vars.length() == 1)
  assert_true(def_vars.any(item => item == y))
  let def_subst = def.substitute_def_var(y, Int(word8(9)))
  assert_true(def_subst.rhs() == BinOp(Plus, Int(word8(9)), one))
  let folded = @types.Def::create(x, BinOp(Plus, Int(word8(2)), Int(word8(3)))).map_def_exp(exp => {
      exp.simplify()
    },
  )
  assert_true(folded.rhs() == Int(word8(5)))
  let left = @types.Tid::for_name("left")
  let right = @types.Tid::for_name("right")
  let phi = @types.Phi::of_list(x, [
    (left, Var(y)),
    (right, BinOp(Xor, Var(z), one)),
  ])
  let phi_vars = phi.phi_free_vars()
  assert_true(phi_vars.length() == 2)
  assert_true(phi_vars.any(item => item == y))
  assert_true(phi_vars.any(item => item == z))
  let phi_subst = phi.substitute_phi_var(z, Int(word8(7)))
  assert_true(phi_subst.select(right) == Some(BinOp(Xor, Int(word8(7)), one)))
  let jmp = @types.Jmp::create_goto(
    @types.Label::indirect(Var(y)),
    cond=BinOp(Eq, Var(z), Int(word8(0))),
  )
  let jmp_vars = jmp.jmp_free_vars()
  assert_true(jmp_vars.length() == 2)
  assert_true(jmp_vars.any(item => item == y))
  assert_true(jmp_vars.any(item => item == z))
  let jmp_subst = jmp.substitute_jmp_var(y, Int(word8(4)))
  assert_true(jmp_subst.kind() is Goto(Indirect(Int(_))))
}

///|
test "ir block and program helpers respect local definitions" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let left = @types.Tid::for_name("pred")
  let phi = @types.Phi::of_list(x, [(left, Var(z))])
  let def = @types.Def::create(y, Int(word8(1)))
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("done")),
    cond=Var(y),
  )
  let blk = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let blk_vars = blk.blk_free_vars()
  assert_true(blk_vars.is_empty())
  let arg = @types.Arg::create(x, Var(z))
  assert_true(arg.arg_free_vars().any(item => item == z))
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  let program = @types.Program::create().append_sub(sub)
  let program_vars = program.program_free_vars()
  assert_true(program_vars.length() == 1)
  assert_true(program_vars[0] == z)
  let rewritten = program.substitute_program_var(z, Int(word8(7)))
  assert_true(rewritten.program_free_vars().is_empty())
}
