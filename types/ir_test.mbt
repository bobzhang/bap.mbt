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
