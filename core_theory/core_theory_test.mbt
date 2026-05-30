///|
test "sorts model symbolic applications" {
  let word = @core_theory.Sort::bitv(32)
  inspect(word.to_string(), content="core:bitv<32>")
  assert_true(word.name() == Some(@knowledge.Name::create("bitv", pkg="core")))
  assert_true(word.tail() == [IntSort(32)])
  let mem = @core_theory.Sort::mem(@core_theory.Sort::bitv(64), word)
  inspect(mem.to_string(), content="core:mem<core:bitv<64>><core:bitv<32>>")
}

///|
test "variables preserve sorts versions and mutability flags" {
  let sort = @core_theory.Sort::bitv(64)
  let reg = @core_theory.Var::create(sort, "RAX", is_mutable=true)
  inspect(reg.name(), content="RAX")
  assert_true(reg.is_mutable())
  assert_true(!reg.is_virtual())
  let versioned = reg.versioned(2)
  inspect(versioned.name(), content="RAX#2")
  assert_true(versioned.sort().same(sort))
  assert_true(@core_theory.Var::fresh(sort).is_virtual())
}

///|
test "effect sorts form the expected lattice" {
  assert_true(@core_theory.EffectData.union(EffectCtrl) == EffectBoth)
  assert_true(@core_theory.EffectData.order(EffectBoth) == Less)
  assert_true(@core_theory.EffectData.order(EffectCtrl) == Incomparable)
  inspect(@core_theory.Effect::jump().to_string(), content="jump")
}

///|
test "targets inherit defaults and match ancestry" {
  let word = @core_theory.Sort::bitv(64)
  let pc = @core_theory.Var::create(word, "PC")
  let family = @core_theory.Target::create(
    name=@knowledge.Name::create("x86", pkg="target"),
    nicknames=["amd64-family"],
    bits=64,
    endianness=LittleEndian,
    vars=[pc],
  )
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("x86-64", pkg="target"),
    parent=family,
    nicknames=["amd64"],
  )
  assert_true(target.belongs(family))
  assert_true(target.order(family) == Less)
  assert_true(target.bits() == 64)
  assert_true(target.endianness() == LittleEndian)
  assert_true(target.matches("amd64"))
  assert_true(target.matches("X86"))
  assert_true(target.find_var("PC") is Some(_))
}

///|
test "target registry resolves common and custom declarations" {
  match @core_theory.get_target("AMD64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.code_addr_size() == 64)
      assert_true(target.belongs(@core_theory.Target::x86()))
      assert_true(target.find_var("RIP") is Some(_))
      assert_true(target.matching("x86") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("riscv64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.find_var("PC") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-target-registry", pkg="test"),
    nicknames=["unit-target-alias"],
    bits=16,
  )
  match @core_theory.register_target(target) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.find_target("unit-target-alias").map(t => t.bits()) == Some(16),
  )
  assert_true(@core_theory.register_target(target) is Err(_))
  assert_true(
    @core_theory.declared_targets().any(t => t.matches("unit-target-alias")),
  )
}

///|
test "labels carry symbolic entry points" {
  let named = @core_theory.Label::for_name("main")
  assert_true(named.is_valid())
  assert_true(named.name() == Some("main"))
  let addr = @types.Word::of_int(width=64, 0x400000)
  let label = @core_theory.Label::for_addr(addr).with_alias("_start")
  assert_true(label.addr() == Some(addr))
  assert_true(label.aliases() == ["_start"])
  assert_true(!@core_theory.Label::null().is_valid())
}
