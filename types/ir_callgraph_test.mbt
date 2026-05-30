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
  let return_label = @types.Label::direct(@types.Tid::for_name("return"))
  let call = @types.Call::create(target~, return_label~)
  assert_true(call.target() == target)
  assert_true(call.return_label() == Some(return_label))
  assert_true(call.with_noreturn().return_label() is None)
}
