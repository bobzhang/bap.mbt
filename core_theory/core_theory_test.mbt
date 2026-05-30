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
  let rax = @core_theory.Var::create(word, "RAX")
  let eax = @core_theory.Var::create(@core_theory.Sort::bitv(32), "EAX")
  let family = @core_theory.Target::create(
    name=@knowledge.Name::create("x86", pkg="target"),
    nicknames=["amd64-family"],
    bits=64,
    endianness=LittleEndian,
    vars=[pc, rax, eax],
    alias_origins=[@core_theory.AliasOrigin::subregister(eax, rax, lo=0, hi=31)],
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
  match target.origin_of_name("EAX") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "EAX")
      assert_true(origin.source().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.range() == Some((0, 31)))
    }
    None => fail("missing EAX alias origin")
  }
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
test "target metadata enums parse loader strings" {
  assert_true(
    @core_theory.Endianness::of_string("little-endian") == Some(LittleEndian),
  )
  assert_true(@core_theory.Endianness::of_string("BE") == Some(BigEndian))
  assert_true(@core_theory.System::of_string("macos") == Some(Darwin))
  assert_true(@core_theory.Abi::of_string("system-v") == Some(SysV))
  assert_true(@core_theory.Fabi::of_string("hard-float") == Some(Hard))
  assert_true(@core_theory.Filetype::of_string("mach-o") == Some(MachO))
  assert_true(@core_theory.Filetype::of_string("coff") == Some(PE))
  inspect(@core_theory.Raw.to_string(), content="raw")
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-metadata", pkg="test"),
    system=Linux,
    abi=GNU,
    fabi=Soft,
    filetype=Elf,
  )
  assert_true(target.system().to_string() == "linux")
  assert_true(target.abi().to_string() == "gnu")
  assert_true(target.fabi().to_string() == "soft")
  assert_true(target.filetype().to_string() == "elf")
  let refined = @core_theory.Target::unknown()
    .with_bits(64)
    .with_endianness(BigEndian)
    .with_system(Darwin)
    .with_abi(SysV)
    .with_fabi(Hard)
    .with_filetype(MachO)
  assert_true(refined.bits() == 64)
  assert_true(refined.endianness() == BigEndian)
  assert_true(refined.system() == Darwin)
  assert_true(refined.abi() == SysV)
  assert_true(refined.fabi() == Hard)
  assert_true(refined.filetype() == MachO)
}

///|
test "target role helpers classify common architecture variables" {
  let amd64 = @core_theory.Target::x86_64()
  match amd64.find_var("RSP") {
    Some(sp) => assert_true(amd64.roles_of_var(sp).contains(StackPointer))
    None => fail("missing RSP")
  }
  match amd64.find_var("RIP") {
    Some(pc) => assert_true(amd64.roles_of_var(pc).contains(ProgramCounter))
    None => fail("missing RIP")
  }
  match amd64.find_var("RDI") {
    Some(arg) => assert_true(amd64.roles_of_var(arg).contains(Argument))
    None => fail("missing RDI")
  }
  match amd64.find_var("RAX") {
    Some(result) =>
      assert_true(amd64.roles_of_var(result).contains(ResultRegister))
    None => fail("missing RAX")
  }
  assert_true(amd64.find_role(StackPointer).map(v => v.ident()) == Some("RSP"))
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "ZF"))
  assert_true(amd64.role_aliases(ProgramCounter).contains("rip"))
  let arm = @core_theory.Target::arm()
  assert_true(arm.find_role(ProgramCounter).map(v => v.ident()) == Some("PC"))
  assert_true(arm.vars_with_role(Argument).any(v => v.ident() == "R0"))
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

///|
test "program metadata tracks source compiler and units" {
  let language = @core_theory.Language::of_string("C++")
  assert_true(language == Cxx)
  inspect(language.to_string(), content="cxx")
  let source = @core_theory.Source::create(
    language~,
    code="int main() { return 0; }",
    file="main.cc",
  )
  assert_true(source.language() == Cxx)
  assert_true(source.file() == Some("main.cc"))
  let compiler = @core_theory.Compiler::create(
    "clang",
    version=["17", "0"],
    options=["-O2"],
    specs={ "triple": "x86_64-unknown-linux" },
  )
  assert_true(compiler.version() == ["17", "0"])
  assert_true(compiler.options() == ["-O2"])
  assert_true(compiler.spec("triple") == Some("x86_64-unknown-linux"))
  inspect(compiler.to_string(), content="clang 17.0 -O2")
  let target = @core_theory.Target::x86_64()
  let base = @types.Word::of_int(width=64, 0x400000)
  let upper = @types.Word::of_int(width=64, 0x4000ff)
  let unit = @core_theory.ProgramUnit::for_file(
    "main.o",
    target~,
    bias=base,
    source~,
    compiler~,
  )
  assert_true(unit.path() == Some("main.o"))
  assert_true(unit.name() == "main.o")
  assert_true(unit.bias() == Some(base))
  assert_true(unit.target().matches("amd64"))
  assert_true(unit.source().map(item => item.code()) == Some(source.code()))
  assert_true(unit.compiler().map(item => item.name()) == Some("clang"))
  let region = @core_theory.ProgramUnit::for_region(lower=base, upper~, target~)
  assert_true(region.lower() == Some(base))
  assert_true(region.upper() == Some(upper))
  assert_true(region.name() == "\{base.to_hex()}-\{upper.to_hex()}")
  let label = @core_theory.Label::for_name("main")
    .with_unit(unit)
    .with_encoding(language)
    .with_subroutine()
  assert_true(label.unit().map(item => item.same(unit)) == Some(true))
  assert_true(label.encoding() == Some(Cxx))
  assert_true(label.target().map(item => item.matches("amd64")) == Some(true))
  assert_true(label.is_subroutine())
  let program = @core_theory.Program::create(units=[unit], labels=[label])
  assert_true(program.units().length() == 1)
  assert_true(program.labels().length() == 1)
  assert_true(program.target().map(item => item.matches("amd64")) == Some(true))
}
