///|
fn call_to(
  target : @types.Tid,
  ret? : @types.Term[@types.Blk],
) -> @types.Term[@types.Jmp] {
  let call = match ret {
    Some(r) =>
      @types.Call::create(target=Direct(target), return_label=Direct(r.tid()))
    None => @types.Call::create(target=Direct(target))
  }
  @types.Jmp::create_call(call)
}

///|
test "calls through the linker bind arguments and return" {
  let rdi = reg("RDI")
  let rax = reg("RAX")
  let res = reg("res")
  let a = reg("double_a")
  let r = reg("double_r")
  let double = sub(
    "double",
    args=[
      @types.Arg::create(a, Var(rdi), intent=In),
      @types.Arg::create(r, Var(rax), intent=Out),
    ],
    [blk(defs=[def(rax, BinOp(Times, Var(a), int64(2)))])],
  )
  let after = blk(defs=[def(res, BinOp(Plus, Var(rax), int64(1)))])
  let entry = blk(defs=[def(rdi, int64(20))], jmps=[
    call_to(double.tid(), ret=after),
  ])
  let calls = []
  let (status, values) = run_main_sub(
    [sub("main", [entry, after]), double],
    [res, r],
    init=m => {
      m.observe(@primus.call, c => {
        calls.push(
          "call \{c.0}(\{c.1.map(value_int).map(x => x.to_string()).join(", ")})",
        )
      })
      m.observe(@primus.call_return, c => {
        calls.push(
          "return \{c.0}(\{c.1.map(value_int).map(x => x.to_string()).join(", ")})",
        )
      })
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(41), Some(40)]
    ),
  )
  debug_inspect(
    calls,
    content=(
      #|[
      #|  "call main()",
      #|  "call double(20)",
      #|  "return double(20, 40)",
      #|  "return main()",
      #|]
    ),
  )
}

///|
test "nested calls use the prompt stack" {
  // main calls f, f calls g twice; every call has its own return block.
  let x = reg("x")
  let g = sub("g", [blk(defs=[def(x, BinOp(Times, Var(x), int64(2)))])])
  let f_done = blk(defs=[def(x, BinOp(Plus, Var(x), int64(1)))])
  let f_mid = blk(jmps=[call_to(g.tid(), ret=f_done)])
  let f = sub("f", [blk(jmps=[call_to(g.tid(), ret=f_mid)]), f_mid, f_done])
  let done = blk(defs=[def(x, BinOp(Plus, Var(x), int64(100)))])
  let main = sub("main", [
    blk(defs=[def(x, int64(5))], jmps=[call_to(f.tid(), ret=done)]),
    done,
  ])
  let (status, values) = run_main_sub([main, f, g], [x])
  inspect(status_string(status), content="Normal")
  // ((5 * 2) * 2 + 1) + 100
  debug_inspect(values, content="[Some(121)]")
}

///|
test "recursion with a shared return block follows the upstream prompt semantics" {
  // Upstream `exec_to_prompt` treats a jump to the destination of the
  // innermost pending call as a return, so when recursive calls share the
  // same return block only the outermost one executes it.
  let n = reg("n")
  let acc = reg("acc")
  let fact_tid = @types.Tid::create()
  let base = blk(defs=[def(acc, int64(1))])
  let after = blk(defs=[
    def(n, BinOp(Plus, Var(n), int64(1))),
    def(acc, BinOp(Times, Var(acc), Var(n))),
  ])
  let rec_ = blk(defs=[def(n, BinOp(Minus, Var(n), int64(1)))], jmps=[
    call_to(fact_tid, ret=after),
  ])
  let entry = blk(jmps=[
    goto(base, cond=BinOp(Eq, Var(n), int64(0))),
    goto(rec_),
  ])
  let fact = @types.Sub::create(name="fact", tid=fact_tid, blks=[
    entry, base, rec_, after,
  ])
  let done = blk()
  let main = sub("main", [
    blk(defs=[def(n, int64(5))], jmps=[call_to(fact_tid, ret=done)]),
    done,
  ])
  let (status, values) = run_main_sub([main, fact], [acc, n])
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(1), Some(1)]")
}

///|
test "host code linked by name, tid and address" {
  let rax = reg("RAX")
  let res = reg("res")
  let ext_tid = @types.Tid::create()
  let after = blk(defs=[def(res, Var(rax))])
  let entry = blk(jmps=[call_to(ext_tid, ret=after)])
  let execs = []
  let (status, values) = run_main_sub([sub("main", [entry, after])], [res], init=m => {
    @primus.Linker::link(
      m,
      name="ext",
      tid=ext_tid,
      addr=w64(0x400),
      Host(m => @primus.Env::set(m, rax, @primus.Value::of_word(m, w64(99)))),
    )
    m.observe(@primus.linker_exec, n => {
      if n is (Symbol(_) | Tid(_)) {
        execs.push(n.to_string())
      }
    })
    assert_true(@primus.Linker::is_linked(m, Symbol("ext")))
    assert_true(@primus.Linker::is_linked(m, Addr(w64(0x400))))
    debug_inspect(
      @primus.Linker::resolve_symbol(m, Addr(w64(0x400))),
      content=(
        #|Some("ext")
      ),
    )
    debug_inspect(
      @primus.Linker::resolve_addr(m, Symbol("ext")).map(word_int),
      content="Some(1024)",
    )
    assert_true(@primus.Linker::resolve_tid(m, Symbol("ext")) == Some(ext_tid))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(99)]")
  inspect(execs.length() >= 2, content="true")
}

///|
test "indirect jumps resolve through the linker addresses" {
  let res = reg("res")
  let target_tid = @types.Tid::create()
  let target = @types.Blk::create(tid=target_tid, defs=[def(res, int64(7))]).set_attr(
    @types.Attr::address(w64(0x500)),
  )
  let entry = blk(jmps=[@types.Jmp::create_goto(Indirect(int64(0x500)))])
  let jumps = []
  let (status, values) = run_main_sub([sub("main", [entry, target])], [res], init=m => {
    m.observe(@primus.jumping, p => jumps.push(value_int(p.1)))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(7)]")
  debug_inspect(jumps, content="[1280]")
}

///|
test "unresolved names raise or call the unresolved handler" {
  let missing = @types.Tid::create()
  let after = blk()
  let main = sub("main", [blk(jmps=[call_to(missing, ret=after)]), after])
  let unresolved = []
  let (status, _) = run_main_sub([main], [], init=m => {
    m.observe(@primus.linker_unresolved, n => unresolved.push(n == Tid(missing)))
  })
  inspect(
    status_string(status).has_prefix("Exn(unbound function"),
    content="true",
  )
  debug_inspect(unresolved, content="[true]")
  let handled : Ref[Int32] = { val: 0, }
  let (status, _) = run_main_sub([main], [], init=m => {
    @primus.Linker::link(
      m,
      name=@primus.unresolved_handler,
      Host(_ => handled.val += 1),
    )
  })
  inspect(status_string(status), content="Normal")
  inspect(handled.val, content="1")
}

///|
test "unlink removes all names of the code" {
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let t = @types.Tid::create()
    @primus.Linker::link(m, name="f", tid=t, Host(_ => ()))
    assert_true(@primus.Linker::is_linked(m, Tid(t)))
    @primus.Linker::unlink(m, Symbol("f"))
    assert_false(@primus.Linker::is_linked(m, Tid(t)))
    assert_false(@primus.Linker::is_linked(m, Symbol("f")))
  })
}

///|
test "synchronous Linker::exec from host code" {
  let x = reg("x")
  let f = sub("f", [blk(defs=[def(x, int64(3))])])
  let seen = []
  let (status, _) = @primus.Machine::run(project([f]), start=m => {
    @primus.Interpreter::link_program(m)
    @primus.Linker::exec(m, Symbol("f"))
    seen.push(value_int(@primus.Env::get(m, x)))
    @primus.Env::set(m, x, @primus.Value::of_word(m, w64(4)))
    @primus.Interpreter::sub(m, f)
    seen.push(value_int(@primus.Env::get(m, x)))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(seen, content="[3, 3]")
}
