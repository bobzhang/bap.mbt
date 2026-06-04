///|
fn ir_bool(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::bool_t())
}

///|
fn ir_reg8(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(8))
}

///|
fn ir_word8(value : Int) -> @types.Exp raise @bitvec.BitVecError {
  @types.Exp::int(@types.Word::of_int(width=8, value))
}

///|
fn ir_project(program : @types.Term[@types.Program]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::unknown()).with_program(program)
}

///|
test "project wraps SSA conversion and destruction passes" {
  let x = ir_reg8("x")
  let blk = @types.Blk::create(defs=[
    @types.Def::create(x, ir_word8(1)),
    @types.Def::create(x, ir_word8(2)),
  ])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let project = ir_project(@types.Program::create(subs=[sub]))
  let ssa = project.to_ssa()
  assert_true(ssa.program().subs()[0].is_ssa())
  let restored = ssa.destroy_ssa()
  assert_true(!restored.program().subs()[0].is_ssa())
}

///|
test "project wraps flatten and trivial-condition-form passes" {
  let x = ir_reg8("x")
  let flag = ir_bool("flag")
  let target = @types.Blk::create(tid=@types.Tid::for_name("target"))
  let nested = @types.Exp::binop(
    Plus,
    @types.Exp::binop(Plus, @types.Exp::var_exp(x), ir_word8(1)),
    ir_word8(2),
  )
  let cond = @types.Exp::binop(
    Eq,
    @types.Exp::var_exp(flag),
    @types.Exp::int(@types.Word::b1()),
  )
  let entry = @types.Blk::create(
    defs=[@types.Def::create(x, nested)],
    jmps=[@types.Jmp::create_goto(@types.Label::direct(target.tid()), cond~)],
    tid=@types.Tid::for_name("entry"),
  )
  let project = ir_project(
    @types.Program::create(subs=[
      @types.Sub::create(name="main", blks=[entry, target]),
    ]),
  )
  let flattened = project.flatten_program()
  assert_true(flattened.program().subs()[0].blks()[0].defs().length() > 1)
  let tcf = project.to_trivial_condition_form()
  let tcf_entry = tcf.program().subs()[0].blks()[0]
  assert_true(tcf_entry.defs().length() == 2)
  assert_true(tcf_entry.jmps()[0].jmp_has_trivial_condition())
}

///|
test "project wraps stub call resolution pass" {
  let real = @types.Sub::create(name="real").with_sub_alias("stub")
  let stub = @types.Sub::create(name="stub").with_stub()
  let caller_blk = @types.Blk::create(jmps=[
    @types.Jmp::create_call(
      @types.Call::create(target=@types.Label::direct(stub.tid())),
    ),
  ])
  let caller = @types.Sub::create(name="caller", blks=[caller_blk])
  let project = ir_project(@types.Program::create(subs=[caller, real, stub]))
  let resolved = project.resolve_stub_calls()
  match resolved.program().subs()[0].blks()[0].jmps()[0].kind() {
    JmpCall(call) => assert_true(call.target == Direct(real.tid()))
    _ => fail("expected call jump")
  }
}

///|
test "project maps and marks IR terms with typed predicates" {
  let x = ir_reg8("x")
  let y = ir_reg8("y")
  let def = @types.Def::create(
    x,
    @types.Exp::binop(Plus, @types.Exp::var_exp(y), ir_word8(1)),
  )
  let blk = @types.Blk::create(defs=[def])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let project = ir_project(@types.Program::create(subs=[sub]))
  let marked = project.mark_program_terms(
    term => term.def_lhs_name("x") && term.def_uses_name("y"),
    @types.Attr::mark(value="def"),
  )
  let marked_def = marked.program().program_defs()[0]
  assert_true(@types.DefTerm(marked_def).mark_value() == Some("def"))
  assert_true(!marked.program().program_blks()[0].has_attr("mark"))
  let unmarked = marked.unmark_program_terms("mark")
  assert_true(!unmarked.program().exists_program_term(term => term.has_mark()))
  let class_marked = project.map_program_terms(term => {
    if term.has_class(DefTermClass) {
      term.set_attr(@types.Attr::new(key="class", value=term.class_name()))
    } else {
      term
    }
  })
  assert_true(
    class_marked.program().program_defs()[0].get_attr("class") == Some("def"),
  )
}

///|
test "project term marker can use immediate parent predicates" {
  let x = ir_reg8("x")
  let def = @types.Def::create(x, ir_word8(1))
  let blk = @types.Blk::create(defs=[def])
  let sub = @types.Sub::create(name="main", blks=[blk])
  let project = ir_project(@types.Program::create(subs=[sub]))
  let original = project.program()
  let marked = project.mark_program_terms(
    term => original.program_parent_is(term, def.tid()),
    @types.Attr::new(key="parent", value="def"),
  )
  assert_true(
    marked.program().program_blks()[0].get_attr("parent") == Some("def"),
  )
  assert_true(marked.program().program_defs()[0].get_attr("parent") is None)
}

///|
test "project registers built-in IR transform passes" {
  match @project.register_ir_transform_passes() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_ir_transform_passes() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_pass("ssa") is Some(_))
  assert_true(@project.find_pass("flatten") is Some(_))
  assert_true(@project.find_pass("trivial-condition-form") is Some(_))
  assert_true(@project.find_pass("stub-resolver") is Some(_))

  let x = ir_reg8("x")
  let flag = ir_bool("flag")
  let target = @types.Blk::create(tid=@types.Tid::for_name("target"))
  let entry = @types.Blk::create(
    defs=[
      @types.Def::create(
        x,
        @types.Exp::binop(Plus, @types.Exp::var_exp(x), ir_word8(1)),
      ),
    ],
    jmps=[
      @types.Jmp::create_goto(
        @types.Label::direct(target.tid()),
        cond=@types.Exp::binop(
          Eq,
          @types.Exp::var_exp(flag),
          @types.Exp::int(@types.Word::b1()),
        ),
      ),
    ],
  )
  let project = ir_project(
    @types.Program::create(subs=[
      @types.Sub::create(name="main", blks=[entry, target]),
    ]),
  )
  let transformed = match
    project.run_passes(["flatten", "trivial-condition-form", "ssa"]) {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
  let sub = transformed.program().subs()[0]
  assert_true(sub.is_ssa())
  assert_true(sub.blks()[0].jmps()[0].jmp_has_trivial_condition())
  assert_true(transformed.pass_run_count("flatten") == 1)
  assert_true(transformed.pass_run_count("trivial-condition-form") == 1)
  assert_true(transformed.pass_run_count("ssa") == 1)
}
