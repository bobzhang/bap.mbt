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
  let attrs = { "phase": "imported" }
  let replaced = term.with_attrs(attrs)
  attrs["phase"] = "mutated"
  assert_true(replaced.get_attr("comment") is None)
  assert_true(replaced.get_attr("phase") == Some("imported"))
  assert_true(replaced.tid() == term.tid())
}

///|
test "tids parse BAP-style textual identifiers" {
  let created = @types.Tid::create()
  assert_true(created.name() is None)
  assert_true(created.ivec() is None)
  match @types.Tid::from_string("@entry") {
    Ok(tid) => {
      assert_true(tid.name() == Some("entry"))
      inspect(tid.to_string(), content="@entry")
    }
    Err(reason) => fail(reason)
  }
  match @types.Tid::from_string("plain") {
    Ok(tid) => {
      assert_true(tid.name() == Some("plain"))
      inspect(tid.to_string(), content="@plain")
    }
    Err(reason) => fail(reason)
  }
  match @types.Tid::from_string("@interrupt:#13") {
    Ok(tid) => {
      assert_true(tid.ivec() == Some(13))
      inspect(tid.to_string(), content="@interrupt:#13")
    }
    Err(reason) => fail(reason)
  }
  match @types.Tid::from_string("%42") {
    Ok(tid) => {
      assert_true(tid.id() == 42)
      assert_true(tid.name() is None)
      assert_true(tid.ivec() is None)
      inspect(tid.to_string(), content="%42")
    }
    Err(reason) => fail(reason)
  }
  assert_true(@types.Tid::from_string("%") is Err(_))
  assert_true(@types.Tid::from_string("@interrupt:#") is Err(_))
  try @types.Tid::from_string_exn("%bad") catch {
    InvalidTid(text) => assert_true(text == "%bad")
  } noraise {
    _ => fail("expected invalid tid")
  }
}

///|
test "BAP-style IR builders collect construction inputs" {
  let typ = @types.ValueType::Imm(32)
  let arg = @types.Arg::create(
    @types.Var::new(name="argc", typ~),
    Int(@types.Word::of_int(width=32, 1)),
  )
  let first_blk = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let second_blk = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let sub_tid = @types.Tid::for_name("main")
  let sub_builder = @types.SubBuilder::create(
    tid=sub_tid,
    name="main",
    args=1,
    blks=2,
  )
  sub_builder.add_arg(arg)
  sub_builder.add_blk(first_blk)
  let first_sub = sub_builder.result()
  sub_builder.add_blk(second_blk)
  let second_sub = sub_builder.result()
  assert_true(first_sub.tid() == sub_tid)
  assert_true(first_sub.sub_name() == "main")
  assert_true(first_sub.args().length() == 1)
  assert_true(first_sub.blks().map(blk => blk.tid()) == [first_blk.tid()])
  assert_true(
    second_sub.blks().map(blk => blk.tid()) ==
    [first_blk.tid(), second_blk.tid()],
  )

  let program_tid = @types.Tid::for_name("program")
  let program_builder = @types.ProgramBuilder::create(tid=program_tid, subs=2)
  program_builder.add_sub(first_sub)
  let first_program = program_builder.result()
  program_builder.add_sub(second_sub)
  let second_program = program_builder.result()
  assert_true(first_program.tid() == program_tid)
  assert_true(first_program.subs().map(sub => sub.tid()) == [sub_tid])
  assert_true(second_program.subs().map(sub => sub.tid()) == [sub_tid, sub_tid])
}

///|
test "terms expose common BAP-style attributes and flags" {
  let origin = @types.Tid::for_name("source")
  let cond : @types.Exp = Var(@types.Var::new(name="ok", typ=Imm(1)))
  let def = @types.Def::create(
      @types.Var::new(name="x", typ=Imm(8)),
      Int(@types.Word::of_int(width=8, 1)),
    )
    .set_attr(@types.Attr::filename("unit.bin"))
    .set_attr(@types.Attr::format("hex"))
    .set_attr(@types.Attr::origin(origin))
    .set_attr(@types.Attr::synthetic())
    .set_attr(@types.Attr::precondition(cond))
    .set_attr(@types.Attr::invariant(cond))
    .set_attr(@types.Attr::postcondition(cond))
    .with_flag("custom-flag")
  assert_true(def.get_attr("filename") == Some("unit.bin"))
  assert_true(def.get_attr("format") == Some("hex"))
  assert_true(def.get_attr("origin") == Some(origin.to_string()))
  assert_true(def.has_flag("synthetic"))
  assert_true(def.get_attr("precondition") == Some(cond.to_string()))
  assert_true(def.get_attr("invariant") == Some(cond.to_string()))
  assert_true(def.get_attr("postcondition") == Some(cond.to_string()))
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
test "ir term class dispatch helpers mirror BAP switch proj and cata" {
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

  let switched = program
    .program_terms()
    .map(term => {
      term.switch(
        program=_ => "program",
        sub=_ => "sub",
        arg=_ => "arg",
        blk=_ => "blk",
        phi=_ => "phi",
        def=_ => "def",
        jmp=_ => "jmp",
      )
    })
  assert_true(switched == ["program", "sub", "arg", "blk", "phi", "def", "jmp"])

  let projected_def : String? = @types.DefTerm(def).proj(def=term => {
    Some(term.name())
  })
  let projected_wrong : String? = @types.DefTerm(def).proj(blk=term => {
    Some(term.name())
  })
  let projected_none : String? = @types.DefTerm(def).proj(def=_ => None)
  assert_true(projected_def == Some(def.name()))
  assert_true(projected_wrong is None)
  assert_true(projected_none is None)

  assert_true(
    @types.ArgTerm(arg).cata(init="missing", arg=term => term.name()) ==
    arg.name(),
  )
  assert_true(
    @types.ArgTerm(arg).cata(init="missing", def=term => term.name()) ==
    "missing",
  )
}

///|
test "ir term map applies class-specific handlers with identity defaults" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let def = @types.Def::create(x, Int(word8(1)))
  let blk = @types.Blk::create(defs=[def])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let program = @types.Program::create(subs=[sub])
  let mark = @types.Attr::new(key="mark", value="mapped")

  let mapped = program.map_program_terms(term => {
    term.map(
      program=term => term.set_attr(mark),
      blk=term => term.set_attr(mark),
      def=term => term.set_attr(mark),
    )
  })
  assert_true(mapped.get_attr("mark") == Some("mapped"))
  assert_true(mapped.subs()[0].get_attr("mark") is None)
  assert_true(mapped.subs()[0].blks()[0].get_attr("mark") == Some("mapped"))
  assert_true(mapped.program_defs()[0].get_attr("mark") == Some("mapped"))

  let unchanged = @types.DefTerm(def).map(blk=term => term.set_attr(mark))
  assert_true(unchanged.same_term(DefTerm(def)))
  assert_true(unchanged.get_attr("mark") is None)
}

///|
test "IR term lookup exn helpers report missing tids" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let arg = @types.Arg::create(x, Var(x))
  let phi = @types.Phi::create(x, @types.Tid::for_name("entry"), Var(x))
  let def = @types.Def::create(x, Int(word8(1)))
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("exit")),
  )
  let blk = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  let program = @types.Program::create(subs=[sub])
  assert_true(program.find_sub_exn(sub.tid()).same(sub))
  assert_true(sub.find_arg(arg.tid()).map(term => term.same(arg)) == Some(true))
  assert_true(sub.find_arg_exn(arg.tid()).same(arg))
  assert_true(sub.find_blk_exn(blk.tid()).same(blk))
  assert_true(blk.find_phi_exn(phi.tid()).same(phi))
  assert_true(blk.find_def_exn(def.tid()).same(def))
  assert_true(blk.find_jmp_exn(jmp.tid()).same(jmp))
  assert_true(
    program.program_find_arg(arg.tid()).map(term => term.same(arg)) ==
    Some(true),
  )
  assert_true(program.program_find_arg_exn(arg.tid()).same(arg))
  assert_true(program.program_find_blk_exn(blk.tid()).same(blk))
  assert_true(program.program_find_phi_exn(phi.tid()).same(phi))
  assert_true(program.program_find_def_exn(def.tid()).same(def))
  assert_true(program.program_find_jmp_exn(jmp.tid()).same(jmp))
  let missing = @types.Tid::for_name("missing")
  try program.program_find_def_exn(missing) catch {
    MissingIrTerm(kind, tid) => {
      assert_true(kind == "def")
      assert_true(tid == missing)
    }
  } noraise {
    _ => fail("expected MissingIrTerm")
  }
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
test "program class-filtered lookup and parent helpers mirror BAP Ir_program" {
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
    program.program_lookup(ProgramTermClass, program.tid())
    is Some(ProgramTerm(_)),
  )
  assert_true(
    program.program_lookup(SubTermClass, sub.tid()) is Some(SubTerm(_)),
  )
  assert_true(
    program.program_lookup(ArgTermClass, arg.tid()) is Some(ArgTerm(_)),
  )
  assert_true(
    program.program_lookup(BlkTermClass, blk.tid()) is Some(BlkTerm(_)),
  )
  assert_true(
    program.program_lookup(PhiTermClass, phi.tid()) is Some(PhiTerm(_)),
  )
  assert_true(
    program.program_lookup(DefTermClass, def.tid()) is Some(DefTerm(_)),
  )
  assert_true(
    program.program_lookup(JmpTermClass, jmp.tid()) is Some(JmpTerm(_)),
  )
  assert_true(program.program_lookup(BlkTermClass, def.tid()) is None)

  assert_true(
    program.program_parent(SubTermClass, sub.tid()) is Some(ProgramTerm(_)),
  )
  assert_true(
    program.program_parent(ArgTermClass, arg.tid()) is Some(SubTerm(_)),
  )
  assert_true(
    program.program_parent(BlkTermClass, blk.tid()) is Some(SubTerm(_)),
  )
  assert_true(
    program.program_parent(PhiTermClass, phi.tid()) is Some(BlkTerm(_)),
  )
  assert_true(
    program.program_parent(DefTermClass, def.tid()) is Some(BlkTerm(_)),
  )
  assert_true(
    program.program_parent(JmpTermClass, jmp.tid()) is Some(BlkTerm(_)),
  )
  assert_true(program.program_parent(ProgramTermClass, program.tid()) is None)
  assert_true(program.program_parent(BlkTermClass, def.tid()) is None)
}

///|
fn ir_visit_event_tag(event : @types.IrVisitEvent) -> String {
  match event {
    EnterTerm(term) => "enter:\{term.class_name()}"
    LeaveTerm(term) => "leave:\{term.class_name()}"
    VisitVar(variable) => "var:\{variable.name()}"
    VisitExp(exp) => "exp:\{traverse_exp_tag(exp)}"
  }
}

///|
test "ir visitor events include terms variables and expressions in BAP order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let arg = @types.Arg::create(x, Var(y))
  let pred = @types.Tid::for_name("pred")
  let phi = @types.Phi::of_list(x, [(pred, Var(y))])
  let def = @types.Def::create(y, BinOp(Plus, Var(y), Int(word8(1))))
  let jmp = @types.Jmp::create_goto(@types.Label::direct(pred), cond=Var(x))
  let blk = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let sub = @types.Sub::create(name="main", args=[arg], blks=[blk])
  let program = @types.Program::create(subs=[sub])

  let tags = program.fold_program_visit([], (acc, event) => {
    acc.push(ir_visit_event_tag(event))
    acc
  })
  assert_true(
    tags ==
    [
      "enter:program", "enter:sub", "enter:arg", "var:x", "exp:var", "leave:arg",
      "enter:blk", "enter:phi", "var:x", "exp:var", "leave:phi", "enter:def", "var:y",
      "exp:binop", "exp:var", "exp:int", "leave:def", "enter:jmp", "exp:var", "leave:jmp",
      "leave:blk", "leave:sub", "leave:program",
    ],
  )
  assert_true(program.program_visit_events().map(ir_visit_event_tag) == tags)
  let root_term : @types.IrTerm = ProgramTerm(program)
  assert_true(root_term.visit_events().map(ir_visit_event_tag) == tags)
  assert_true(
    sub.fold_sub_visit(0, (count, _) => count + 1) == tags.length() - 2,
  )
  assert_true(blk.fold_blk_visit(0, (count, _) => count + 1) == 15)
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
test "ir term mapping visits containers before children" {
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

  let visits : Array[String] = []
  let mapped = program.map_program_terms(term => {
    visits.push(term.class_name())
    match term {
      ProgramTerm(program) =>
        ProgramTerm(program.set_attr(@types.Attr::new(key="order", value="0")))
      SubTerm(sub) =>
        SubTerm(sub.set_attr(@types.Attr::new(key="order", value="1")))
      BlkTerm(blk) =>
        BlkTerm(blk.set_attr(@types.Attr::new(key="order", value="3")))
      _ => term
    }
  })
  assert_true(visits == ["program", "sub", "arg", "blk", "phi", "def", "jmp"])
  assert_true(mapped.get_attr("order") == Some("0"))
  assert_true(mapped.subs()[0].get_attr("order") == Some("1"))
  assert_true(mapped.subs()[0].blks()[0].get_attr("order") == Some("3"))
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
test "ir term direct-child helpers filter find update remove and change" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_y = @types.Def::create(y, Int(word8(1)))
  let def_z = @types.Def::create(z, Var(y))
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("done")),
  )
  let blk = @types.Blk::create(defs=[def_y, def_z], jmps=[jmp])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let program = @types.Program::create(subs=[sub])
  let program_term : @types.IrTerm = ProgramTerm(program)
  let block_term : @types.IrTerm = BlkTerm(blk)

  assert_true(
    program_term.children_of_class(SubTermClass).map(term => term.tid()) ==
    [sub.tid()],
  )
  assert_true(
    program_term.find_child(SubTermClass, sub.tid()) is Some(SubTerm(_)),
  )
  assert_true(program_term.find_child(DefTermClass, def_y.tid()) is None)
  assert_true(
    block_term.children_of_class(DefTermClass).map(term => term.tid()) ==
    [def_y.tid(), def_z.tid()],
  )
  assert_true(
    block_term.children_of_class(DefTermClass, rev=true).map(term => term.tid()) ==
    [def_z.tid(), def_y.tid()],
  )

  let mark = @types.Attr::new(key="edited", value="yes")
  let updated = block_term.update_child(DefTerm(def_y.set_attr(mark)))
  match updated.find_child(DefTermClass, def_y.tid()) {
    Some(DefTerm(term)) => assert_true(term.get_attr("edited") == Some("yes"))
    _ => fail("expected updated def child")
  }
  let removed = updated.remove_child(DefTermClass, def_z.tid())
  assert_true(removed.children_of_class(DefTermClass).length() == 1)

  let def_tail = @types.Def::create(x, Var(z), tid=@types.Tid::for_name("tail"))
  let saw_missing = Ref(false)
  let appended = removed.change_child(DefTermClass, def_tail.tid(), current => {
    saw_missing.val = current is None
    Some(DefTerm(def_tail))
  })
  assert_true(saw_missing.val)
  assert_true(
    appended.children_of_class(DefTermClass).map(term => term.tid()) ==
    [def_y.tid(), def_tail.tid()],
  )

  let unchanged = appended.change_child(DefTermClass, def_y.tid(), _ => {
    Some(JmpTerm(jmp))
  })
  assert_true(
    unchanged.children_of_class(DefTermClass).map(term => term.tid()) ==
    [def_y.tid(), def_tail.tid()],
  )
}

///|
test "ir term direct-child navigation mirrors BAP Term sequence helpers" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let a = @types.Def::create(x, Int(word8(1)), tid=@types.Tid::for_name("a"))
  let b = @types.Def::create(x, Int(word8(2)), tid=@types.Tid::for_name("b"))
  let c = @types.Def::create(x, Int(word8(3)), tid=@types.Tid::for_name("c"))
  let jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("done")),
  )
  let blk = @types.Blk::create(defs=[a, b, c], jmps=[jmp])
  let block_term : @types.IrTerm = BlkTerm(blk)

  assert_true(block_term.child_count(DefTermClass) == 3)
  assert_true(block_term.child_count(PhiTermClass) == 0)
  assert_true(block_term.nth_child(DefTermClass, -1) is None)
  assert_true(block_term.nth_child(DefTermClass, 0) is Some(DefTerm(_)))
  assert_true(block_term.nth_child(DefTermClass, 3) is None)
  assert_true(
    block_term.first_child(DefTermClass).map(term => term.tid()) ==
    Some(a.tid()),
  )
  assert_true(
    block_term.last_child(DefTermClass).map(term => term.tid()) == Some(c.tid()),
  )
  assert_true(
    block_term.next_child(DefTermClass, a.tid()).map(term => term.tid()) ==
    Some(b.tid()),
  )
  assert_true(block_term.next_child(DefTermClass, c.tid()) is None)
  assert_true(
    block_term.prev_child(DefTermClass, c.tid()).map(term => term.tid()) ==
    Some(b.tid()),
  )
  assert_true(block_term.prev_child(DefTermClass, a.tid()) is None)
  assert_true(
    block_term.children_after(DefTermClass, a.tid()).map(term => term.tid()) ==
    [b.tid(), c.tid()],
  )
  assert_true(
    block_term
    .children_after(DefTermClass, a.tid(), rev=true)
    .map(term => term.tid()) ==
    [c.tid(), b.tid()],
  )
  assert_true(
    block_term.children_before(DefTermClass, c.tid()).map(term => term.tid()) ==
    [a.tid(), b.tid()],
  )
  assert_true(
    block_term
    .children_before(DefTermClass, c.tid(), rev=true)
    .map(term => term.tid()) ==
    [b.tid(), a.tid()],
  )
  assert_true(block_term.children_after(DefTermClass, jmp.tid()).is_empty())
  assert_true(block_term.children_before(DefTermClass, jmp.tid()).is_empty())
}

///|
test "ir term direct-child insertion mirrors BAP append and prepend" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let a = @types.Def::create(x, Int(word8(1)), tid=@types.Tid::for_name("a"))
  let b = @types.Def::create(x, Int(word8(2)), tid=@types.Tid::for_name("b"))
  let c = @types.Def::create(x, Int(word8(3)), tid=@types.Tid::for_name("c"))
  let head = @types.Def::create(
    x,
    Int(word8(0)),
    tid=@types.Tid::for_name("head"),
  )
  let left = @types.Def::create(
    x,
    Int(word8(9)),
    tid=@types.Tid::for_name("left"),
  )
  let block_term : @types.IrTerm = BlkTerm(@types.Blk::create(defs=[a]))

  let appended = block_term.append_child(DefTerm(c))
  assert_true(
    appended.children_of_class(DefTermClass).map(term => term.tid()) ==
    [a.tid(), c.tid()],
  )
  let inserted = appended.append_child(DefTerm(b), after=a.tid())
  assert_true(
    inserted.children_of_class(DefTermClass).map(term => term.tid()) ==
    [a.tid(), b.tid(), c.tid()],
  )
  let missing_anchor = inserted.append_child(
    DefTerm(head),
    after=@types.Tid::for_name("missing"),
  )
  assert_true(
    missing_anchor.children_of_class(DefTermClass).map(term => term.tid()) ==
    [a.tid(), b.tid(), c.tid()],
  )

  let prepended = inserted.prepend_child(DefTerm(head))
  assert_true(
    prepended.children_of_class(DefTermClass).map(term => term.tid()) ==
    [head.tid(), a.tid(), b.tid(), c.tid()],
  )
  let before_b = inserted.prepend_child(DefTerm(left), before=b.tid())
  assert_true(
    before_b.children_of_class(DefTermClass).map(term => term.tid()) ==
    [a.tid(), left.tid(), b.tid(), c.tid()],
  )

  let wrong_child = inserted.append_child(
    SubTerm(@types.Sub::create(name="not-a-block-child")),
  )
  assert_true(
    wrong_child.children_of_class(DefTermClass).map(term => term.tid()) ==
    [a.tid(), b.tid(), c.tid()],
  )
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
  let ptr = @types.Var::new(name="ptr", typ=@types.ValueType::reg32_t())
  let ptr_exp : @types.Exp = Var(ptr)
  let phi = @types.Phi::of_list(lhs, [(left, one)]).update_phi(right, two)
  let single = @types.Phi::create(
    lhs,
    left,
    one,
    tid=@types.Tid::for_name("phi-term"),
  )
  assert_true(single.select(left) == Some(one))
  assert_true(single.tid().name() == Some("phi-term"))
  assert_true(phi.select(left) == Some(one))
  assert_true(phi.select(right) == Some(two))
  assert_true(single.select_or_unknown(left) == one)
  assert_true(
    single.select_or_unknown(right) == Unknown("unresolved-tid @right", typ),
  )
  let call = @types.Call::create(target=@types.Label::direct(left)).with_return(
    @types.Label::direct(right),
  )
  let jmp = @types.Jmp::create_call(call)
  inspect(jmp.kind().to_string(), content="call @left")
  assert_true(
    @types.Jmp::resolve(@types.Jmp::resolved(left)) == ResolvedTarget(left),
  )
  assert_true(
    @types.Jmp::resolve(@types.Jmp::indirect(ptr_exp)) ==
    IndirectTarget(ptr_exp),
  )
  let goto = @types.Jmp::create_goto(@types.Label::direct(left))
  assert_true(goto.dst() == Some(@types.Jmp::resolved(left)))
  assert_true(goto.alt() is None)
  assert_true(
    goto.with_dst(Some(@types.Jmp::indirect(ptr_exp))).kind() ==
    Goto(Indirect(ptr_exp)),
  )
  assert_true(
    goto.with_alt(Some(@types.Jmp::resolved(right))).kind() ==
    JmpCall(
      @types.Call::create(
        target=@types.Label::direct(right),
        return_label=@types.Label::direct(left),
      ),
    ),
  )
  assert_true(
    goto.with_alt(Some(@types.Jmp::resolved(@types.Tid::for_ivec(7)))).kind() ==
    Interrupt(7, left),
  )
  let ret = @types.Jmp::create_ret(@types.Label::direct(right))
  assert_true(ret.dst() is None)
  assert_true(ret.alt() == Some(@types.Jmp::resolved(right)))
  let interrupt = @types.Jmp::create_int(13, right)
  assert_true(interrupt.dst() == Some(@types.Jmp::resolved(right)))
  match interrupt.alt() {
    Some(ResolvedDst(tid)) => {
      assert_true(tid.ivec() == Some(13))
      inspect(tid.to_string(), content="@interrupt:#13")
    }
    _ => fail("expected interrupt vector destination")
  }
  let arg = @types.Arg::create(lhs, one).with_intent(Both)
  assert_true(arg.intent() == Some(Both))
  let tagged_arg = arg
    .set_attr(@types.Arg::warn_unused())
    .set_attr(@types.Arg::alloc_size())
    .set_attr(@types.Arg::format("printf"))
    .set_attr(@types.Arg::restricted())
    .set_attr(@types.Arg::nonnull())
  assert_true(tagged_arg.has_attr("warn-unused"))
  assert_true(tagged_arg.has_attr("alloc-size"))
  assert_true(tagged_arg.get_attr("format") == Some("printf"))
  assert_true(tagged_arg.has_attr("restricted"))
  assert_true(tagged_arg.has_attr("nonnull"))
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
  let jmp_exps = jmp.jmp_exps()
  assert_true(jmp_exps.length() == 2)
  assert_true(jmp_exps[0] == Var(y))
  assert_true(jmp_exps[1] == BinOp(Eq, Var(z), Int(word8(0))))
  let jmp_vars = jmp.jmp_free_vars()
  assert_true(jmp_vars.length() == 2)
  assert_true(jmp_vars.any(item => item == y))
  assert_true(jmp_vars.any(item => item == z))
  let jmp_subst = jmp.substitute_jmp_var(y, Int(word8(4)))
  assert_true(jmp_subst.kind() is Goto(Indirect(Int(_))))
  let call_return : @types.Exp = Var(x)
  let call_jmp = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::indirect(Var(y)),
      return_label=@types.Label::indirect(call_return),
    ),
    cond=Var(z),
  )
  let call_exps = call_jmp.jmp_exps()
  assert_true(call_exps.length() == 3)
  assert_true(call_exps[0] == call_return)
  assert_true(call_exps[1] == Var(y))
  assert_true(call_exps[2] == Var(z))
  let block = @types.Blk::create(phis=[phi], defs=[def], jmps=[jmp])
  let eight = @types.Int(word8(8))
  let mapped = block.map_blk_exp(_ => eight, skip_jmp=true)
  assert_true(mapped.phis()[0].select(left) == Some(eight))
  assert_true(mapped.defs()[0].rhs() == eight)
  assert_true(mapped.jmps()[0].cond() == jmp.cond())
  let phi_skipped = block.map_blk_exp(_ => eight, skip_phi=true)
  assert_true(phi_skipped.phis()[0].select(left) == phi.select(left))
  assert_true(phi_skipped.defs()[0].rhs() == eight)
  let lhs_mapped = block.map_blk_lhs(
    variable => variable.with_index(3),
    skip_phi=true,
  )
  assert_true(lhs_mapped.phis()[0].phi_lhs() == x)
  assert_true(lhs_mapped.defs()[0].lhs() == x.with_index(3))
  let def_skipped = block.map_blk_lhs(
    variable => variable.with_index(4),
    skip_def=true,
  )
  assert_true(def_skipped.phis()[0].phi_lhs() == x.with_index(4))
  assert_true(def_skipped.defs()[0].lhs() == x)
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
