///|
fn contains_tid(tids : Array[@types.Tid], tid : @types.Tid) -> Bool {
  tids.any(item => item == tid)
}

///|
test "program callgraph groups direct call sites by subroutine tid" {
  let typ = @types.ValueType::Imm(32)
  let ptr = @types.Var::new(name="ptr", typ~)
  let main_tid = @types.Tid::for_name("main")
  let callee_tid = @types.Tid::for_name("callee")
  let external_tid = @types.Tid::for_name("external")
  let callee = @types.Sub::create(name="callee", tid=callee_tid)
  let call_1 = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(callee_tid)),
  )
  let call_2 = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(callee_tid),
      return_label=@types.Label::direct(@types.Tid::for_name("return")),
    ),
  )
  let external_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(external_tid)),
  )
  let indirect_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::indirect(Var(ptr))),
  )
  let goto = @types.Jmp::create_goto(@types.Label::direct(callee_tid))
  let main_blk = @types.Blk::create(jmps=[
    call_1, call_2, external_call, indirect_call, goto,
  ])
  let main = @types.Sub::create(name="main", blks=[main_blk], tid=main_tid)
  assert_true(call_1.direct_call_target() == Some(callee_tid))
  assert_true(call_2.direct_call_target() == Some(callee_tid))
  assert_true(indirect_call.direct_call_target() is None)
  assert_true(goto.direct_call_target() is None)
  assert_true(main.sub_direct_call_tids().length() == 3)
  let program = @types.Program::create(subs=[main, callee])
  let graph = program.program_callgraph()
  assert_true(graph.node_count() == 3)
  assert_true(graph.edge_count() == 2)
  match graph.edge(main_tid, callee_tid) {
    Some(edge) => {
      assert_true(edge.label.length() == 2)
      assert_true(edge.label[0].same(call_1))
      assert_true(edge.label[1].same(call_2))
    }
    None => fail("expected grouped call edge")
  }
  match graph.edge(main_tid, external_tid) {
    Some(edge) => {
      assert_true(edge.label.length() == 1)
      assert_true(edge.label[0].same(external_call))
    }
    None => fail("expected external call edge")
  }
  let callees = program.program_callees(main)
  assert_true(callees.length() == 2)
  assert_true(contains_tid(callees, callee_tid))
  assert_true(contains_tid(callees, external_tid))
  let callers = program.program_callers(callee)
  assert_true(callers.length() == 1)
  assert_true(callers[0] == main_tid)
}

///|
test "call accessors expose target and return labels" {
  let target = @types.Label::direct(@types.Tid::for_name("target"))
  let changed_target = @types.Label::direct(@types.Tid::for_name("changed"))
  let return_label = @types.Label::direct(@types.Tid::for_name("return"))
  let call = @types.Call::create(target~, return_label~)
  assert_true(call.target() == target)
  assert_true(call.return_label() == Some(return_label))
  assert_true(call.return_() == Some(return_label))
  assert_true(call.with_target(changed_target).target() == changed_target)
  assert_true(
    call.with_target(changed_target).return_label() == Some(return_label),
  )
  assert_true(call.with_noreturn().return_label() is None)
  assert_true(call.with_noreturn().return_() is None)
}

///|
test "labels expose BAP-style create and change helpers" {
  let next = @types.Tid::for_name("next")
  let target = @types.Var::new(name="target", typ=@types.ValueType::reg32_t())
  let indirect_value = @types.Int(word32(4))
  match @types.Label::create() {
    Direct(_) => ()
    Indirect(_) => fail("fresh labels should be direct")
  }
  assert_true(
    @types.Label::direct(@types.Tid::for_name("old")).change(direct=_ => next) ==
    @types.Label::direct(next),
  )
  assert_true(
    @types.Label::indirect(Var(target)).change(indirect=_ => indirect_value) ==
    @types.Label::indirect(indirect_value),
  )
  let direct = @types.Label::direct(next)
  assert_true(direct.change(indirect=_ => indirect_value) == direct)
}

///|
test "program callgraph can resolve indirect call targets" {
  let typ = @types.ValueType::Imm(32)
  let dispatch = @types.Var::new(name="dispatch", typ~)
  let main_tid = @types.Tid::for_name("main-indirect")
  let fast_tid = @types.Tid::for_name("fast")
  let slow_tid = @types.Tid::for_name("slow")
  let direct_tid = @types.Tid::for_name("direct")
  let direct = @types.Sub::create(name="direct", tid=direct_tid)
  let fast = @types.Sub::create(name="fast", tid=fast_tid)
  let slow = @types.Sub::create(name="slow", tid=slow_tid)
  let dispatch_exp : @types.Exp = Var(dispatch)
  let indirect_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::indirect(dispatch_exp)),
  )
  let direct_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(direct_tid)),
  )
  let main = @types.Sub::create(
    name="main",
    blks=[@types.Blk::create(jmps=[indirect_call, direct_call])],
    tid=main_tid,
  )
  let resolver = exp => {
    if exp == dispatch_exp {
      [fast_tid, slow_tid]
    } else {
      []
    }
  }
  assert_true(
    indirect_call.resolved_call_targets(resolve_indirect=resolver) ==
    [fast_tid, slow_tid],
  )
  assert_true(
    direct_call.resolved_call_targets(resolve_indirect=resolver) == [direct_tid],
  )
  assert_true(
    main.sub_resolved_call_tids(resolve_indirect=resolver).length() == 3,
  )
  let program = @types.Program::create(subs=[main, direct, fast, slow])
  let graph = program.program_resolved_callgraph(resolve_indirect=resolver)
  assert_true(graph.node_count() == 4)
  assert_true(graph.edge_count() == 3)
  match graph.edge(main_tid, fast_tid) {
    Some(edge) => {
      assert_true(edge.label.length() == 1)
      assert_true(edge.label[0].same(indirect_call))
    }
    None => fail("expected resolved fast edge")
  }
  match graph.edge(main_tid, slow_tid) {
    Some(edge) => assert_true(edge.label[0].same(indirect_call))
    None => fail("expected resolved slow edge")
  }
  match graph.edge(main_tid, direct_tid) {
    Some(edge) => assert_true(edge.label[0].same(direct_call))
    None => fail("expected direct edge")
  }
  let callees = program.program_resolved_callees(
    main,
    resolve_indirect=resolver,
  )
  assert_true(callees.length() == 3)
  assert_true(contains_tid(callees, direct_tid))
  assert_true(contains_tid(callees, fast_tid))
  assert_true(contains_tid(callees, slow_tid))
  assert_true(
    program.program_resolved_callers(fast, resolve_indirect=resolver) ==
    [main_tid],
  )
}
