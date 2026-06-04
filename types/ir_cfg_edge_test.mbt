///|
fn test_bool_var(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::bool_t())
}

///|
fn test_var_exp(variable : @types.Var) -> @types.Exp {
  Var(variable)
}

///|
fn test_not_exp(exp : @types.Exp) -> @types.Exp {
  UnOp(Not, exp)
}

///|
fn test_and_exp(lhs : @types.Exp, rhs : @types.Exp) -> @types.Exp {
  BinOp(And, lhs, rhs)
}

///|
fn test_true_exp() -> @types.Exp {
  Int(@types.Word::b1())
}

///|
fn edge_tids(edges : Array[@types.IrCfgEdge]) -> Array[@types.Tid] {
  edges.map(edge => edge.tid())
}

///|
fn edge_positions(edges : Array[@types.IrCfgEdge]) -> Array[Int] {
  edges.map(edge => edge.position())
}

///|
fn jmp_tids(jmps : Array[@types.Term[@types.Jmp]]) -> Array[@types.Tid] {
  jmps.map(jmp => jmp.tid())
}

///|
test "BAP IR CFG edges preserve jump positions and endpoint blocks" {
  let p = test_bool_var("p")
  let q = test_bool_var("q")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let fall = @types.Blk::create(tid=@types.Tid::for_name("fall"))
  let left_jmp = @types.Jmp::create_goto(
    @types.Label::direct(left.tid()),
    cond=test_var_exp(p),
  )
  let right_jmp = @types.Jmp::create_goto(
    @types.Label::direct(right.tid()),
    cond=test_var_exp(q),
  )
  let fall_jmp = @types.Jmp::create_goto(@types.Label::direct(fall.tid()))
  let entry = entry
    .append_jmp(left_jmp)
    .append_jmp(right_jmp)
    .append_jmp(fall_jmp)
  let sub = @types.Sub::create(blks=[entry, left, right, fall])
  let out_edges = sub.sub_out_edges(entry)
  assert_true(out_edges.length() == 3)
  assert_true(out_edges[0].position() == 0)
  assert_true(out_edges[1].position() == 1)
  assert_true(out_edges[2].position() == 2)
  assert_true(out_edges[0].src().tid() == entry.tid())
  assert_true(out_edges[1].dst().tid() == right.tid())
  assert_true(
    edge_tids(out_edges) == [left_jmp.tid(), right_jmp.tid(), fall_jmp.tid()],
  )
  assert_true(edge_tids(sub.sub_in_edges(right)) == [right_jmp.tid()])
  match sub.sub_edge(entry, fall) {
    Some(edge) => assert_true(edge.tid() == fall_jmp.tid())
    None => fail("expected edge to fall")
  }
}

///|
test "BAP IR CFG edge condition excludes earlier jump conditions" {
  let p = test_bool_var("p")
  let q = test_bool_var("q")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let fall = @types.Blk::create(tid=@types.Tid::for_name("fall"))
  let left_jmp = @types.Jmp::create_goto(
    @types.Label::direct(left.tid()),
    cond=test_var_exp(p),
  )
  let right_jmp = @types.Jmp::create_goto(
    @types.Label::direct(right.tid()),
    cond=test_var_exp(q),
  )
  let fall_jmp = @types.Jmp::create_goto(@types.Label::direct(fall.tid()))
  let entry = entry
    .append_jmp(left_jmp)
    .append_jmp(right_jmp)
    .append_jmp(fall_jmp)
  let sub = @types.Sub::create(blks=[entry, left, right, fall])
  let right_edge = sub.sub_edge(entry, right).unwrap()
  assert_true(jmp_tids(right_edge.jmps_before(sub)) == [left_jmp.tid()])
  assert_true(jmp_tids(right_edge.jmps_after(sub)) == [fall_jmp.tid()])
  let expected_right = test_and_exp(
    test_var_exp(q),
    test_not_exp(test_var_exp(p)),
  ).simplify()
  assert_true(right_edge.cond(sub) == expected_right)
  let fall_edge = sub.sub_edge(entry, fall).unwrap()
  assert_true(
    jmp_tids(fall_edge.jmps_before(sub)) == [left_jmp.tid(), right_jmp.tid()],
  )
  assert_true(fall_edge.jmps_after(sub).is_empty())
  let expected_fall = test_and_exp(
    test_and_exp(test_true_exp(), test_not_exp(test_var_exp(p))),
    test_not_exp(test_var_exp(q)),
  ).simplify()
  assert_true(fall_edge.cond(sub) == expected_fall)
}

///|
test "BAP IR CFG edge side queries filter local edges and preserve positions" {
  let ptr = test_bool_var("ptr")
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let left = @types.Blk::create(tid=@types.Tid::for_name("left"))
  let right = @types.Blk::create(tid=@types.Tid::for_name("right"))
  let fall = @types.Blk::create(tid=@types.Tid::for_name("fall"))
  let left_jmp = @types.Jmp::create_goto(@types.Label::direct(left.tid()))
  let indirect_jmp = @types.Jmp::create_goto(
    @types.Label::indirect(test_var_exp(ptr)),
  )
  let right_jmp = @types.Jmp::create_goto(@types.Label::direct(right.tid()))
  let external_jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("external")),
  )
  let fall_jmp = @types.Jmp::create_goto(@types.Label::direct(fall.tid()))
  let entry = entry
    .append_jmp(left_jmp)
    .append_jmp(indirect_jmp)
    .append_jmp(right_jmp)
    .append_jmp(external_jmp)
    .append_jmp(fall_jmp)
  let sub = @types.Sub::create(blks=[entry, left, right, fall])
  let right_edge = sub.sub_edge(entry, right).unwrap()
  assert_true(
    jmp_tids(right_edge.jmps_before(sub)) ==
    [left_jmp.tid(), indirect_jmp.tid()],
  )
  assert_true(
    jmp_tids(right_edge.jmps_after(sub)) == [external_jmp.tid(), fall_jmp.tid()],
  )
  assert_true(edge_tids(right_edge.edges_before(sub)) == [left_jmp.tid()])
  assert_true(edge_positions(right_edge.edges_before(sub)) == [0])
  assert_true(edge_tids(right_edge.edges_after(sub)) == [fall_jmp.tid()])
  assert_true(edge_positions(right_edge.edges_after(sub)) == [4])
  let fall_edge = sub.sub_edge(entry, fall).unwrap()
  assert_true(
    edge_tids(fall_edge.edges_before(sub)) == [left_jmp.tid(), right_jmp.tid()],
  )
  assert_true(edge_positions(fall_edge.edges_before(sub)) == [0, 2])
  assert_true(fall_edge.edges_after(sub).is_empty())
}
