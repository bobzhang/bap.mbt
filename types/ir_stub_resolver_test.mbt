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
fn stub_link_count(links : Map[@types.Tid, @types.Tid]) -> Int {
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
