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
test "terms expose common BAP-style attributes and flags" {
  let origin = @types.Tid::for_name("source")
  let def = @types.Def::create(
      @types.Var::new(name="x", typ=Imm(8)),
      Int(@types.Word::of_int(width=8, 1)),
    )
    .set_attr(@types.Attr::filename("unit.bin"))
    .set_attr(@types.Attr::format("hex"))
    .set_attr(@types.Attr::origin(origin))
    .set_attr(@types.Attr::synthetic())
    .with_flag("custom-flag")
  assert_true(def.get_attr("filename") == Some("unit.bin"))
  assert_true(def.get_attr("format") == Some("hex"))
  assert_true(def.get_attr("origin") == Some(origin.to_string()))
  assert_true(def.has_flag("synthetic"))
  assert_true(def.has_flag("custom-flag"))
  assert_true(!def.without_flag("custom-flag").has_flag("custom-flag"))
}

///|
test "subroutines expose BAP-style semantic flags" {
  let sub = @types.Sub::create(name="main")
    .with_extern()
    .with_leaf()
    .with_malloc()
    .with_const()
    .with_noreturn()
    .with_nothrow()
    .with_returns_twice()
    .with_entry_point()
    .with_intrinsic()
    .with_pure()
  assert_true(sub.is_extern())
  assert_true(sub.is_leaf())
  assert_true(sub.is_malloc())
  assert_true(sub.is_const())
  assert_true(sub.is_noreturn())
  assert_true(sub.is_nothrow())
  assert_true(sub.returns_twice())
  assert_true(sub.is_entry_point())
  assert_true(sub.is_intrinsic())
  assert_true(sub.is_pure())
  assert_true(sub.get_attr("extern") == Some("true"))
  assert_true(sub.get_attr("returns-twice") == Some("true"))
  assert_true(sub.get_attr("entry-point") == Some("true"))
  assert_true(!sub.without_extern().is_extern())
  assert_true(!sub.without_leaf().is_leaf())
  assert_true(!sub.without_malloc().is_malloc())
  assert_true(!sub.without_const().is_const())
  assert_true(!sub.without_noreturn().is_noreturn())
  assert_true(!sub.without_nothrow().is_nothrow())
  assert_true(!sub.without_returns_twice().returns_twice())
  assert_true(!sub.without_entry_point().is_entry_point())
  assert_true(!sub.without_intrinsic().is_intrinsic())
  assert_true(!sub.without_pure().is_pure())
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
test "ir term views visit every nested term and report parents" {
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

  assert_true(
    program.program_terms().map(term => term.class_name()) ==
    ["program", "sub", "arg", "blk", "phi", "def", "jmp"],
  )
  assert_true(
    program.program_terms(include_self=false).map(term => term.class_name()) ==
    ["sub", "arg", "blk", "phi", "def", "jmp"],
  )
  let names = program.fold_program_terms([], (acc, term) => {
    acc.push("\{term.class_name()}:\{term.name()}")
    acc
  })
  assert_true(names.length() == 7)
  assert_true(program.exists_program_term(term => term.same_tid(def.tid())))
  assert_true(
    program.find_program_term(term => term.class_name() == "def")
    is Some(DefTerm(_)),
  )
  match program.program_parent_term(sub.tid()) {
    Some(parent) => assert_true(parent.class_name() == "program")
    None => fail("expected sub parent")
  }
  match program.program_parent_term(arg.tid()) {
    Some(parent) => assert_true(parent.class_name() == "sub")
    None => fail("expected arg parent")
  }
  match program.program_parent_term(def.tid()) {
    Some(parent) => assert_true(parent.class_name() == "blk")
    None => fail("expected def parent")
  }
  assert_true(program.program_parent_term(program.tid()) is None)
}

///|
test "ir term mapping rewrites nested term attributes" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let def = @types.Def::create(x, Int(word8(1)))
  let blk = @types.Blk::create(defs=[def])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let program = @types.Program::create(subs=[sub])

  let marked = program.map_program_terms(term => {
    term.set_attr(@types.Attr::new(key="visited", value=term.class_name()))
  })
  for term in marked.program_terms() {
    assert_true(term.get_attr("visited") == Some(term.class_name()))
  }
  let unmarked = marked.map_program_terms(term => term.del_attr("visited"))
  assert_true(!unmarked.exists_program_term(term => term.has_attr("visited")))
  let ignored = program.map_program_terms(term => {
    match term {
      DefTerm(_) => ProgramTerm(program)
      _ => term
    }
  })
  assert_true(ignored.program_defs()[0].tid() == def.tid())
}

///|
test "ir term query helpers match classes attributes vars and children" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let arg = @types.Arg::create(z, Var(y))
  let phi = @types.Phi::of_list(x, [(arg.tid(), Var(z))])
  let def = @types.Def::create(x, BinOp(Plus, Var(y), Int(word8(1)))).set_attr(
    @types.Attr::new(key="color", value="red"),
  )
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("done")),
    cond=Var(x),
  )
  let blk = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  let program = @types.Program::create(subs=[sub])
  let program_term = @types.ProgramTerm(program)
  let sub_term = @types.SubTerm(sub)
  let block_term = @types.BlkTerm(blk)
  let def_term = @types.DefTerm(def)
  assert_true(program_term.children().map(term => term.tid()) == [sub.tid()])
  assert_true(
    sub_term.children().map(term => term.class_name()) == ["arg", "blk"],
  )
  assert_true(
    block_term.children().map(term => term.class_name()) ==
    ["phi", "def", "jmp"],
  )
  assert_true(def_term.has_class(DefTermClass))
  assert_true(def_term.has_tid(def.tid()))
  assert_true(def_term.has_tid_text(def.tid().to_string()))
  assert_true(def_term.has_name(def.name()))
  assert_true(def_term.has_attr_value("color", "red"))
  assert_true(!def_term.has_attr_value("color", "blue"))
  assert_true(def_term.def_lhs_name("x"))
  assert_true(def_term.def_uses_name("y"))
  assert_true(!def_term.def_uses_name("z"))
  assert_true(def_term.defines_var(x))
  assert_true(def_term.defines_var_name("x"))
  assert_true(def_term.uses_var(y))
  assert_true(def_term.uses_var_name("y"))
  assert_true(!def_term.uses_var_name("x"))
  assert_true(sub_term.defines_var_name("z"))
  assert_true(block_term.defines_var_name("x"))
  assert_true(block_term.has_child_tid(def.tid()))
  assert_true(!block_term.has_child_tid(sub.tid()))
}

///|
test "ir term address query helpers mirror BAP term-addr" {
  let addr32 = @types.Word::of_int64(42L, width=32)
  let addr64 = @types.Word::of_int64(42L, width=64)
  let blk = @types.Blk::create().set_attr(@types.Attr::address(addr32))
  let block_term = @types.BlkTerm(blk)
  assert_true(block_term.has_address(addr32))
  assert_true(!block_term.has_address(addr64))
  assert_true(block_term.has_address_text("42"))
  assert_true(block_term.has_address_text("0x2a"))
  assert_true(block_term.has_address_text("0x2A:32u"))
  assert_true(!block_term.has_address_text("43"))
  assert_true(!block_term.has_address_text("0x2a:64u"))

  let plain = @types.BlkTerm(
    @types.Blk::create().set_attr(@types.Attr::new(key="address", value="0x2a")),
  )
  assert_true(plain.has_address(addr32))
  assert_true(!plain.has_address(@types.Word::of_int64(43L, width=32)))

  let invalid = @types.BlkTerm(
    @types.Blk::create().set_attr(
      @types.Attr::new(key="address", value="not-an-address"),
    ),
  )
  assert_true(!invalid.has_address(addr32))
  assert_true(
    !@types.SubTerm(@types.Sub::create(name="main")).has_address(addr32),
  )
}

///|
test "ir term query helpers test immediate parent relationships" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let def = @types.Def::create(x, Int(word8(1)))
  let blk = @types.Blk::create(defs=[def])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let program = @types.Program::create(subs=[sub])
  assert_true(program.program_parent_is(ProgramTerm(program), sub.tid()))
  assert_true(program.program_parent_is(SubTerm(sub), blk.tid()))
  assert_true(program.program_parent_is(BlkTerm(blk), def.tid()))
  assert_true(!program.program_parent_is(SubTerm(sub), def.tid()))
  assert_true(sub.sub_parent_is(SubTerm(sub), blk.tid()))
  assert_true(sub.sub_parent_is(BlkTerm(blk), def.tid()))
  assert_true(!sub.sub_parent_is(SubTerm(sub), def.tid()))
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
test "ir terms render BAP-style strings" {
  let typ = @types.ValueType::Imm(8)
  let lhs = @types.Var::new(name="r0", typ~)
  let flag = @types.Var::new(name="flag", typ=@types.ValueType::bool_t())
  let target = @types.Var::new(name="target", typ=@types.ValueType::reg32_t())
  let left = @types.Tid::for_name("left")
  let right = @types.Tid::for_name("right")
  let one = @types.Int(@types.Word::of_int(width=8, 1))
  let two = @types.Int(@types.Word::of_int(width=8, 2))
  let def = @types.Def::create(lhs, one)
  let phi = @types.Phi::of_list(lhs, [(left, one), (right, two)])
  let goto = @types.Jmp::create_goto(
    @types.Label::indirect(Var(target)),
    cond=Var(flag),
  )
  let call = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(left),
      return_label=@types.Label::direct(right),
    ),
  )
  let noreturn = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(left)),
  )
  let ret = @types.Jmp::create_ret(@types.Label::direct(right))
  let interrupt = @types.Jmp::create_int(13, right)
  let arg = @types.Arg::create(lhs, one, intent=Both)

  inspect(arg.arg_to_string(), content="r0 :: in out imm8 = 1:8u")
  inspect(def.def_to_string(), content="r0:imm8 := 1:8u")
  inspect(
    phi.phi_to_string(),
    content="r0:imm8 <- phi([1:8u, @left], [2:8u, @right])",
  )
  inspect(goto.jmp_to_string(), content="when flag:imm1 goto *target:imm32")
  inspect(call.jmp_to_string(), content="call @left with return @right")
  inspect(noreturn.jmp_to_string(), content="call @left with noreturn")
  inspect(ret.jmp_to_string(), content="return @right")
  inspect(interrupt.jmp_to_string(), content="interrupt 0xD return @right")
  inspect(@types.DefTerm(def).to_string(), content="r0:imm8 := 1:8u")

  let blk = @types.Blk::create(
    phis=[phi],
    defs=[def],
    jmps=[goto],
    tid=@types.Tid::for_name("entry"),
  )
  inspect(
    blk.blk_to_string(),
    content="@entry\nr0:imm8 <- phi([1:8u, @left], [2:8u, @right])\nr0:imm8 := 1:8u\nwhen flag:imm1 goto *target:imm32",
  )
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  assert_true(sub.sub_to_string().contains("sub main(r0)"))
  assert_true(sub.sub_to_string().contains(arg.arg_to_string()))
  assert_true(sub.sub_to_string().contains(blk.blk_to_string()))
  let program = @types.Program::create(subs=[sub])
  assert_true(program.program_to_string().contains("program\nsub main(r0)"))
  assert_true(@types.ProgramTerm(program).to_string().contains("sub main(r0)"))
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
