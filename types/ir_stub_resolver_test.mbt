///|
fn stub_resolver_sub(
  name : String,
  aliases : Array[String],
  is_stub : Bool,
) -> @types.Term[@types.Sub] {
  let mut sub = @types.Sub::create(name~)
  for alias_name in aliases {
    sub = sub.with_sub_alias(alias_name)
  }
  if is_stub {
    sub.with_stub()
  } else {
    sub
  }
}

///|
fn real_sub(name : String, aliases : Array[String]) -> @types.Term[@types.Sub] {
  stub_resolver_sub(name, aliases, false)
}

///|
fn stub_sub(name : String, aliases : Array[String]) -> @types.Term[@types.Sub] {
  stub_resolver_sub(name, aliases, true)
}

///|
fn stub_link_count(links : Map[@types.Tid, @types.Tid]) -> Int32 {
  let count = Ref(0)
  links.each((_, _) => count.val = count.val + 1)
  count.val
}

///|
fn assert_stub_link(
  links : Map[@types.Tid, @types.Tid],
  stub : @types.Term[@types.Sub],
  real : @types.Term[@types.Sub],
) -> Unit raise {
  assert_true(links.get(stub.tid()) == Some(real.tid()))
}

///|
test "stub resolver links direct and reverse aliases" {
  let real = real_sub("a0", [])
  let direct_stub = stub_sub("a1", ["a0"])
  let program = @types.Program::create(subs=[real, direct_stub])
  let links = program.program_stub_links()
  assert_true(stub_link_count(links) == 1)
  assert_stub_link(links, direct_stub, real)
  assert_true(program.program_stub_tids() == [direct_stub.tid()])
  assert_true(direct_stub.has_sub_alias("a0"))
  assert_true(!direct_stub.has_sub_alias("missing"))
  assert_true(direct_stub.without_sub_alias("a0").sub_aliases().is_empty())

  let impl_alias = real_sub("f0", ["f1"])
  let reverse_stub = stub_sub("f1", [])
  let reverse_links = @types.Program::create(subs=[impl_alias, reverse_stub]).program_stub_links()
  assert_true(stub_link_count(reverse_links) == 1)
  assert_stub_link(reverse_links, reverse_stub, impl_alias)
}

///|
test "stub resolver ignores missing all-stub and all-impl components" {
  let missing_real = real_sub("b0", [])
  let missing_stub = stub_sub("b1", [])
  assert_true(
    stub_link_count(
      @types.Program::create(subs=[missing_real, missing_stub]).program_stub_links(),
    ) ==
    0,
  )

  let dangling_real = real_sub("c0", [])
  let dangling_stub = stub_sub("c1", ["c2"])
  assert_true(
    stub_link_count(
      @types.Program::create(subs=[dangling_real, dangling_stub]).program_stub_links(),
    ) ==
    0,
  )

  let stubs_only_a = stub_sub("d0", [])
  let stubs_only_b = stub_sub("d1", ["d0"])
  assert_true(
    stub_link_count(
      @types.Program::create(subs=[stubs_only_a, stubs_only_b]).program_stub_links(),
    ) ==
    0,
  )

  let impl_only_a = real_sub("e0", [])
  let impl_only_b = real_sub("e1", ["e0"])
  assert_true(
    stub_link_count(
      @types.Program::create(subs=[impl_only_a, impl_only_b]).program_stub_links(),
    ) ==
    0,
  )
}

///|
test "stub resolver resolves every stub in an unambiguous component" {
  let real = real_sub("h0", ["h1", "h2"])
  let stub_a = stub_sub("h1", [])
  let stub_b = stub_sub("h2", [])
  let links = @types.Program::create(subs=[real, stub_a, stub_b]).program_stub_links()
  assert_true(stub_link_count(links) == 2)
  assert_stub_link(links, stub_a, real)
  assert_stub_link(links, stub_b, real)

  let real = real_sub("i0", [])
  let alias_stub_a = stub_sub("i1", ["i0"])
  let alias_stub_b = stub_sub("i2", ["i0"])
  let alias_links = @types.Program::create(subs=[
    real, alias_stub_a, alias_stub_b,
  ]).program_stub_links()
  assert_true(stub_link_count(alias_links) == 2)
  assert_stub_link(alias_links, alias_stub_a, real)
  assert_stub_link(alias_links, alias_stub_b, real)

  let many_alias_real = real_sub("g0", ["g1", "g2"])
  let many_alias_stub = stub_sub("g1", [])
  let many_alias_links = @types.Program::create(subs=[
    many_alias_real, many_alias_stub,
  ]).program_stub_links()
  assert_true(stub_link_count(many_alias_links) == 1)
  assert_stub_link(many_alias_links, many_alias_stub, many_alias_real)

  let cross_real = real_sub("j0", ["j1"])
  let cross_stub = stub_sub("j1", ["j0"])
  let cross_links = @types.Program::create(subs=[cross_real, cross_stub]).program_stub_links()
  assert_true(stub_link_count(cross_links) == 1)
  assert_stub_link(cross_links, cross_stub, cross_real)

  let real_k0 = real_sub("k0", [])
  let real_k1 = real_sub("k1", [])
  let real_k2 = real_sub("k2", [])
  let stub_k3 = stub_sub("k3", ["k0"])
  let stub_k4 = stub_sub("k4", ["k1"])
  let stub_k5 = stub_sub("k5", ["k2"])
  let many_pair_links = @types.Program::create(subs=[
    real_k0, real_k1, real_k2, stub_k3, stub_k4, stub_k5,
  ]).program_stub_links()
  assert_true(stub_link_count(many_pair_links) == 3)
  assert_stub_link(many_pair_links, stub_k3, real_k0)
  assert_stub_link(many_pair_links, stub_k4, real_k1)
  assert_stub_link(many_pair_links, stub_k5, real_k2)
}

///|
test "stub resolver rejects components with multiple implementations" {
  let stub_m0 = stub_sub("m0", ["m2", "m3", "m4"])
  let real_m1 = real_sub("m1", ["m0"])
  let stub_m5 = stub_sub("m5", ["m6", "m7", "m8"])
  let real_m6 = real_sub("m6", ["m5", "m9"])
  let real_m9 = real_sub("m9", ["m10"])
  let stub_m10 = stub_sub("m10", [])
  let links = @types.Program::create(subs=[
    stub_m0, real_m1, stub_m5, real_m6, real_m9, stub_m10,
  ]).program_stub_links()
  assert_true(stub_link_count(links) == 1)
  assert_stub_link(links, stub_m0, real_m1)
  assert_true(links.get(stub_m5.tid()) is None)
  assert_true(links.get(stub_m10.tid()) is None)

  let stub_n0 = stub_sub("n0", ["n1", "n2", "n3"])
  let real_n1 = real_sub("n1", [])
  let real_n4 = real_sub("n4", ["n5"])
  let stub_n5 = stub_sub("n5", [])
  let real_n6 = real_sub("n6", [])
  let stub_n7 = stub_sub("n7", ["n6"])
  let real_n8 = real_sub("n8", ["n1", "n5"])
  let n_links = @types.Program::create(subs=[
    stub_n0, real_n1, real_n4, stub_n5, real_n6, stub_n7, real_n8,
  ]).program_stub_links()
  assert_true(stub_link_count(n_links) == 1)
  assert_stub_link(n_links, stub_n7, real_n6)
  assert_true(n_links.get(stub_n0.tid()) is None)
  assert_true(n_links.get(stub_n5.tid()) is None)
}

///|
test "stub resolver resolves disconnected complex intersections" {
  let stub_p0 = stub_sub("p0", ["p1", "p2", "p3"])
  let stub_p4 = stub_sub("p4", ["p5", "p6", "p7"])
  let real_p5 = real_sub("p5", [])
  let stub_p6 = stub_sub("p6", ["p8", "p9", "p10", "p4"])
  let real_p11 = real_sub("p11", ["p12", "p13", "p1"])
  let links = @types.Program::create(subs=[
    stub_p0, stub_p4, real_p5, stub_p6, real_p11,
  ]).program_stub_links()
  assert_true(stub_link_count(links) == 3)
  assert_stub_link(links, stub_p0, real_p11)
  assert_stub_link(links, stub_p4, real_p5)
  assert_stub_link(links, stub_p6, real_p5)
}

///|
test "stub resolver redirects direct call targets" {
  let real = real_sub("k0", [])
  let stub = stub_sub("k3", ["k0"])
  let next = @types.Blk::create(tid=@types.Tid::for_name("next"))
  let call = @types.Jmp::create_call(
    @types.Call::create(
      target=@types.Label::direct(stub.tid()),
      return_label=@types.Label::direct(next.tid()),
    ),
  )
  let main_blk = @types.Blk::create(jmps=[call])
  let main = @types.Sub::create(name="main", blks=[main_blk])
  let program = @types.Program::create(subs=[main, real, stub])
  let resolved = program.program_resolve_stub_calls()
  match resolved.find_sub(main.tid()) {
    Some(resolved_main) =>
      match resolved_main.blks()[0].jmps()[0].kind() {
        JmpCall(call) => {
          assert_true(call.target == Direct(real.tid()))
          assert_true(call.return_label == Some(Direct(next.tid())))
        }
        _ => fail("expected call")
      }
    None => fail("expected main subroutine")
  }
}

///|
test "stub resolver honors link-only and no-link filters" {
  let real_a = real_sub("filter-a", [])
  let real_b = real_sub("filter-b", [])
  let stub_a = stub_sub("stub-a", ["filter-a"])
  let stub_b = stub_sub("stub-b", ["filter-b"])
  let program = @types.Program::create(subs=[real_a, real_b, stub_a, stub_b])

  let only_a = program.program_stub_links(link_only=["filter-a"])
  assert_true(stub_link_count(only_a) == 1)
  assert_stub_link(only_a, stub_a, real_a)
  assert_true(only_a.get(stub_b.tid()) is None)

  let skip_a = program.program_stub_links(no_link=["filter-a"])
  assert_true(stub_link_count(skip_a) == 1)
  assert_true(skip_a.get(stub_a.tid()) is None)
  assert_stub_link(skip_a, stub_b, real_b)

  let call_a = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(stub_a.tid())),
  )
  let call_b = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(stub_b.tid())),
  )
  let blk = @types.Blk::create(jmps=[call_a, call_b])
  let main = @types.Sub::create(name="filter-main", blks=[blk])
  let call_program = @types.Program::create(subs=[
    main, real_a, real_b, stub_a, stub_b,
  ])
  let resolved = call_program.program_resolve_stub_calls(link_only=["filter-a"])
  match resolved.find_sub(main.tid()) {
    Some(resolved_main) => {
      let jmps = resolved_main.blks()[0].jmps()
      match (jmps[0].kind(), jmps[1].kind()) {
        (JmpCall(first), JmpCall(second)) => {
          assert_true(first.target == Direct(real_a.tid()))
          assert_true(second.target == Direct(stub_b.tid()))
        }
        _ => fail("expected direct calls")
      }
    }
    None => fail("expected main subroutine")
  }
}
