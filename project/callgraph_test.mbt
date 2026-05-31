///|
fn project_callgraph_contains_tid(
  tids : Array[@types.Tid],
  tid : @types.Tid,
) -> Bool {
  tids.any(item => item == tid)
}

///|
test "project exposes direct program callgraph" {
  let main_tid = @types.Tid::for_name("project-main")
  let callee_tid = @types.Tid::for_name("project-callee")
  let external_tid = @types.Tid::for_name("project-external")
  let callee = @types.Sub::create(name="callee", tid=callee_tid)
  let direct_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(callee_tid)),
  )
  let external_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(external_tid)),
  )
  let goto = @types.Jmp::create_goto(@types.Label::direct(callee_tid))
  let main = @types.Sub::create(name="main", tid=main_tid, blks=[
    @types.Blk::create(jmps=[direct_call, external_call, goto]),
  ])
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    @types.Program::create(subs=[main, callee]),
  )
  let graph = project.callgraph()
  assert_true(graph.node_count() == 3)
  assert_true(graph.edge_count() == 2)
  match graph.edge(main_tid, callee_tid) {
    Some(edge) => assert_true(edge.label[0].same(direct_call))
    None => fail("expected direct call edge")
  }
  match graph.edge(main_tid, external_tid) {
    Some(edge) => assert_true(edge.label[0].same(external_call))
    None => fail("expected external call edge")
  }
  let callees = project.callees(main)
  assert_true(callees.length() == 2)
  assert_true(project_callgraph_contains_tid(callees, callee_tid))
  assert_true(project_callgraph_contains_tid(callees, external_tid))
  assert_true(project.callers(callee) == [main_tid])
}

///|
test "project exposes resolved indirect program callgraph" {
  let ptr = @types.Var::new(name="dispatch", typ=Imm(32))
  let main_tid = @types.Tid::for_name("project-main-indirect")
  let direct_tid = @types.Tid::for_name("project-direct")
  let fast_tid = @types.Tid::for_name("project-fast")
  let slow_tid = @types.Tid::for_name("project-slow")
  let direct = @types.Sub::create(name="direct", tid=direct_tid)
  let fast = @types.Sub::create(name="fast", tid=fast_tid)
  let slow = @types.Sub::create(name="slow", tid=slow_tid)
  let dispatch_exp : @types.Exp = Var(ptr)
  let indirect_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::indirect(dispatch_exp)),
  )
  let direct_call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(direct_tid)),
  )
  let main = @types.Sub::create(name="main", tid=main_tid, blks=[
    @types.Blk::create(jmps=[indirect_call, direct_call]),
  ])
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    @types.Program::create(subs=[main, direct, fast, slow]),
  )
  let resolver = exp => {
    if exp == dispatch_exp {
      [fast_tid, slow_tid]
    } else {
      []
    }
  }
  let graph = project.resolved_callgraph(resolve_indirect=resolver)
  assert_true(graph.edge_count() == 3)
  match graph.edge(main_tid, fast_tid) {
    Some(edge) => assert_true(edge.label[0].same(indirect_call))
    None => fail("expected resolved fast call edge")
  }
  match graph.edge(main_tid, slow_tid) {
    Some(edge) => assert_true(edge.label[0].same(indirect_call))
    None => fail("expected resolved slow call edge")
  }
  match graph.edge(main_tid, direct_tid) {
    Some(edge) => assert_true(edge.label[0].same(direct_call))
    None => fail("expected direct call edge")
  }
  let callees = project.resolved_callees(main, resolve_indirect=resolver)
  assert_true(callees.length() == 3)
  assert_true(project_callgraph_contains_tid(callees, direct_tid))
  assert_true(project_callgraph_contains_tid(callees, fast_tid))
  assert_true(project_callgraph_contains_tid(callees, slow_tid))
  assert_true(
    project.resolved_callers(fast, resolve_indirect=resolver) == [main_tid],
  )
}
