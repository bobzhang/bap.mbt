///|
fn tcf_bool(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::bool_t())
}

///|
fn tcf_target(name : String) -> @types.Term[@types.Blk] {
  @types.Blk::create(tid=@types.Tid::for_name(name))
}

///|
fn tcf_cond(x : @types.Var, y : @types.Var) -> @types.Exp {
  BinOp(Eq, Var(x), Var(y))
}

///|
test "trivial condition form hoists complex jump conditions" {
  let x = tcf_bool("x")
  let y = tcf_bool("y")
  let target = tcf_target("target")
  let fallback = tcf_target("fallback")
  let existing = @types.Def::create(y, Int(@types.Word::b1()))
  let complex = tcf_cond(x, y)
  let complex_jmp = @types.Jmp::create_goto(
    @types.Label::direct(target.tid()),
    cond=complex,
  )
  let trivial_jmp = @types.Jmp::create_goto(
    @types.Label::direct(fallback.tid()),
    cond=Var(x),
  )
  let blk = @types.Blk::create(
    defs=[existing],
    jmps=[complex_jmp, trivial_jmp],
    tid=@types.Tid::for_name("entry"),
  )

  let tcf = blk.blk_to_trivial_condition_form()
  assert_true(tcf.tid() == blk.tid())
  assert_true(tcf.defs().length() == 2)
  assert_true(tcf.defs()[0].tid() == existing.tid())
  let hoisted = tcf.defs()[1]
  assert_true(hoisted.rhs() == complex)
  assert_true(hoisted.lhs().is_virtual())
  assert_true(hoisted.lhs().typ() == @types.ValueType::bool_t())
  assert_true(hoisted.lhs().name().has_prefix("c#"))
  assert_true(tcf.jmps().length() == 2)
  assert_true(tcf.jmps()[0].tid() == complex_jmp.tid())
  assert_true(tcf.jmps()[0].cond() == Var(hoisted.lhs()))
  assert_true(tcf.jmps()[0].jmp_has_trivial_condition())
  assert_true(tcf.jmps()[1].tid() == trivial_jmp.tid())
  assert_true(tcf.jmps()[1].cond() == Var(x))
}

///|
test "trivial condition form gives each hoisted condition a distinct variable" {
  let x = tcf_bool("x")
  let y = tcf_bool("y")
  let z = tcf_bool("z")
  let left = tcf_target("left")
  let right = tcf_target("right")
  let first = tcf_cond(x, y)
  let second = tcf_cond(y, z)
  let blk = @types.Blk::create(jmps=[
    @types.Jmp::create_goto(@types.Label::direct(left.tid()), cond=first),
    @types.Jmp::create_goto(@types.Label::direct(right.tid()), cond=second),
  ])

  let tcf = blk.blk_to_trivial_condition_form()
  assert_true(tcf.defs().length() == 2)
  let first_var = tcf.defs()[0].lhs()
  let second_var = tcf.defs()[1].lhs()
  assert_true(first_var.name().has_prefix("c#"))
  assert_true(second_var.name().has_prefix("c#"))
  assert_true(first_var != second_var)
  assert_true(tcf.defs()[0].rhs() == first)
  assert_true(tcf.defs()[1].rhs() == second)
  assert_true(tcf.jmps()[0].cond() == Var(first_var))
  assert_true(tcf.jmps()[1].cond() == Var(second_var))
}

///|
test "trivial condition form maps subroutines and programs" {
  let x = tcf_bool("x")
  let y = tcf_bool("y")
  let target = tcf_target("target")
  let entry = @types.Blk::create(jmps=[
    @types.Jmp::create_goto(
      @types.Label::direct(target.tid()),
      cond=tcf_cond(x, y),
    ),
  ])
  let sub = @types.Sub::create(name="main", blks=[entry, target])
  let program = @types.Program::create(subs=[sub])
  let mapped = program.program_to_trivial_condition_form()
  let mapped_sub = mapped.subs()[0]
  let mapped_entry = mapped_sub.blks()[0]
  assert_true(mapped_entry.defs().length() == 1)
  assert_true(mapped_entry.jmps()[0].jmp_has_trivial_condition())
  assert_true(
    mapped_entry.jmps()[0].cond() == Var(mapped_entry.defs()[0].lhs()),
  )
}
