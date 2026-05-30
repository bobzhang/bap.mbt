///|
fn tid_names(tids : Array[@types.Tid]) -> Array[String] {
  [
    for tid in tids => tid.to_string()
  ]
}

///|
fn block_names(blocks : Array[@types.Term[@types.Blk]]) -> Array[String] {
  [
    for block in blocks => block.name()
  ]
}

///|
test "ir graph helpers resolve local successors from jumps" {
  let typ = @types.ValueType::Imm(32)
  let ptr = @types.Var::new(name="ptr", typ~)
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let dead = @types.Blk::create(tid=@types.Tid::for_name("dead"))
  let entry_jmp = @types.Jmp::create_goto(@types.Label::direct(body.tid()))
  let call = @types.Call::create(
    target=@types.Label::indirect(Var(ptr)),
    return_label=@types.Label::direct(exit.tid()),
  )
  let body_jmp = @types.Jmp::create_call(call)
  let ret_jmp = @types.Jmp::create_ret(@types.Label::direct(entry.tid()))
  let entry = entry.append_jmp(entry_jmp)
  let body = body.append_jmp(body_jmp)
  let exit = exit.append_jmp(ret_jmp)
  assert_true(entry_jmp.succ_tid_of_jmp() == Some(body.tid()))
  assert_true(body_jmp.succ_tid_of_jmp() == Some(exit.tid()))
  assert_true(ret_jmp.succ_tid_of_jmp() is None)
  assert_true(tid_names(entry.blk_successor_tids()) == [body.tid().to_string()])
  let sub = @types.Sub::create(name="main", blks=[entry, body, exit, dead])
  let cfg = sub.sub_cfg()
  assert_true(cfg.node_count() == 4)
  assert_true(cfg.edge_count() == 2)
  assert_true(cfg.has_edge(entry.tid(), body.tid()))
  assert_true(cfg.has_edge(body.tid(), exit.tid()))
  assert_true(!cfg.has_edge(exit.tid(), entry.tid()))
  match cfg.edge(entry.tid(), body.tid()) {
    Some(edge) => assert_true(edge.label == entry_jmp.tid())
    None => fail("expected entry edge")
  }
  assert_true(block_names(sub.sub_successor_blocks(entry)) == ["@body"])
  assert_true(block_names(sub.sub_predecessor_blocks(exit)) == ["@body"])
  assert_true(
    block_names(sub.sub_reverse_postorder()) == ["@entry", "@body", "@exit"],
  )
  assert_true(
    block_names(sub.sub_reachable_blocks()) == ["@entry", "@body", "@exit"],
  )
}

///|
test "ir graph helpers ignore unresolved and external successors" {
  let typ = @types.ValueType::Imm(32)
  let ptr = @types.Var::new(name="ptr", typ~)
  let start = @types.Blk::create(tid=@types.Tid::for_name("start"))
  let handler = @types.Blk::create(tid=@types.Tid::for_name("handler"))
  let interrupt = @types.Jmp::create_int(3, handler.tid())
  let external = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("external")),
  )
  let indirect = @types.Jmp::create_goto(@types.Label::indirect(Var(ptr)))
  let start = start
    .append_jmp(interrupt)
    .append_jmp(external)
    .append_jmp(indirect)
  assert_true(interrupt.succ_tid_of_jmp() == Some(handler.tid()))
  assert_true(external.succ_tid_of_jmp() is Some(_))
  assert_true(indirect.succ_tid_of_jmp() is None)
  let sub = @types.Sub::create(name="trap", blks=[start, handler])
  let cfg = sub.sub_cfg()
  assert_true(cfg.node_count() == 2)
  assert_true(cfg.edge_count() == 1)
  assert_true(cfg.has_edge(start.tid(), handler.tid()))
  assert_true(block_names(sub.sub_successor_blocks(start)) == ["@handler"])
  assert_true(block_names(sub.sub_predecessor_blocks(handler)) == ["@start"])
}
