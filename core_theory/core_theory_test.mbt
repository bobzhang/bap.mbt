///|
fn register_core_test_agent(
  name : String,
  reliability : @knowledge.AgentReliability,
) -> @knowledge.Agent raise {
  match @knowledge.Agent::register(name, pkg="core-test", reliability~) {
    Ok(agent) => agent
    Err(reason) => fail(reason)
  }
}

///|
fn documented_core_properties(class_name : String) -> Array[String] {
  let classes = @knowledge.Documentation::classes()
  match classes.search_by(entry => entry.0.name().show() == class_name) {
    Some(index) => classes[index].1.map(property => property.name().show())
    None => []
  }
}

///|
fn documented_name_count(names : Array[String], name : String) -> Int {
  let mut count = 0
  for item in names {
    if item == name {
      count = count + 1
    }
  }
  count
}

///|
fn[T : Eq] assert_persistent_round_trip(
  codec : @knowledge.Persistent[T]?,
  value : T,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      assert_true(persistent.decode(persistent.encode(value)) == Ok(value))
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_optional_source_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.Source?]?,
  value : @core_theory.Source?,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) =>
          match (decoded, value) {
            (None, None) => ()
            (Some(left), Some(right)) => assert_true(left.equal(right))
            _ => fail("unexpected decoded source for \{label}")
          }
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_optional_compiler_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.Compiler?]?,
  value : @core_theory.Compiler?,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) =>
          match (decoded, value) {
            (None, None) => ()
            (Some(left), Some(right)) => assert_true(left.equal(right))
            _ => fail("unexpected decoded compiler for \{label}")
          }
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_optional_unit_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.ProgramUnit?]?,
  value : @core_theory.ProgramUnit?,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) =>
          match (decoded, value) {
            (None, None) => ()
            (Some(left), Some(right)) => assert_true(left.same(right))
            _ => fail("unexpected decoded unit for \{label}")
          }
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_value_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.Value]?,
  value : @core_theory.Value,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) => assert_true(decoded.equal(value))
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_semantics_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.Semantics]?,
  value : @core_theory.Semantics,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) => assert_true(decoded.equal(value))
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
fn assert_var_persistent_round_trip(
  codec : @knowledge.Persistent[@core_theory.Var]?,
  value : @core_theory.Var,
  label : String,
) -> Unit raise {
  match codec {
    Some(persistent) =>
      match persistent.decode(persistent.encode(value)) {
        Ok(decoded) => assert_true(decoded.equal(value))
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for \{label}")
  }
}

///|
test "sorts model symbolic applications" {
  assert_true(
    @core_theory.Sort::top().name() ==
    Some(@knowledge.Name::create("Top", pkg="core")),
  )
  let word = @core_theory.Sort::bitv(32)
  inspect(word.to_string(), content="core:bitv<32>")
  assert_true(word.name() == Some(@knowledge.Name::create("bitv", pkg="core")))
  assert_true(word.value() is None)
  assert_true(@core_theory.Sort::int(32).value() == Some(32))
  assert_true(word.refine_bitv() == Some(word))
  assert_true(word.bitv_size() == Some(32))
  assert_true(word.refine_bool() is None)
  assert_true(word.tail() == [@core_theory.Sort::int(32)])
  assert_true(word.hd() == Some(@core_theory.Sort::int(32)))
  assert_true(word.tl() == Some(word.head()))
  assert_true(@core_theory.Sort::bool().hd() is None)
  assert_true(@core_theory.Sort::bool().tl() is None)
  let mem = @core_theory.Sort::mem(@core_theory.Sort::bitv(64), word)
  inspect(mem.to_string(), content="core:mem<core:bitv<64>><core:bitv<32>>")
  assert_true(
    mem.refine(@knowledge.Name::create("mem", pkg="core")) == Some(mem),
  )
  assert_true(mem.mem_keys() == Some(@core_theory.Sort::bitv(64)))
  assert_true(mem.mem_values() == Some(word))
  assert_true(mem.hd() == Some(@core_theory.Sort::bitv(64)))
  match mem.tl() {
    Some(rest) => {
      inspect(rest.to_string(), content="core:mem<core:bitv<32>>")
      assert_true(rest.hd() == Some(word))
    }
    None => fail("expected memory sort tail")
  }
  assert_true(@core_theory.Sort::float(80).float_width() == Some(80))
  assert_true(
    @core_theory.Sort::float(80).float_bits() ==
    Some(@core_theory.Sort::bitv(80)),
  )
  let ieee754 = @core_theory.Sort::app(
    @core_theory.Sort::app(
      @core_theory.Sort::app(
        @core_theory.Sort::sym(@knowledge.Name::create("IEEE754", pkg="core")),
        @core_theory.Sort::int(2),
      ),
      @core_theory.Sort::int(11),
    ),
    @core_theory.Sort::int(52),
  )
  let float_format = @core_theory.Sort::float_format(
    ieee754,
    @core_theory.Sort::bitv(64),
  )
  inspect(
    float_format.to_string(),
    content="core:bitv<core:IEEE754<2><11><52>><64>",
  )
  assert_true(float_format.float_format_exp() == Some(ieee754))
  assert_true(
    float_format.float_format_bits() == Some(@core_theory.Sort::bitv(64)),
  )
  let float64 = @core_theory.Sort::float_with_format(float_format)
  assert_true(float64.refine_float() == Some(float64))
  assert_true(float64.float_format_of() == Some(float_format))
  assert_true(float64.float_bits() == Some(@core_theory.Sort::bitv(64)))
  assert_true(float64.float_width() == Some(64))
  assert_true(
    @core_theory.Sort::rmode().refine_rmode() ==
    Some(@core_theory.Sort::rmode()),
  )
  assert_persistent_round_trip(
    Some(@core_theory.Sort::persistent()),
    mem,
    "sort",
  )
}

///|
test "IEEE754 parameters define floating point sorts" {
  let binary64 = @core_theory.Ieee754Parameters::binary64()
  assert_true(binary64.base == 2)
  assert_true(binary64.bias == 1023)
  assert_true(binary64.k == 64)
  assert_true(binary64.p == 53)
  assert_true(binary64.w == 11)
  assert_true(binary64.t == 52)
  assert_true(@core_theory.Ieee754Parameters::binary(64) == Some(binary64))
  assert_true(@core_theory.Ieee754Parameters::binary(0) is None)
  assert_true(@core_theory.Ieee754Parameters::binary(24) is None)
  let decimal64 = @core_theory.Ieee754Parameters::decimal64()
  assert_true(decimal64.base == 10)
  assert_true(decimal64.k == 64)
  assert_true(decimal64.p == 16)
  assert_true(decimal64.w == 13)
  assert_true(decimal64.t == 50)
  assert_true(@core_theory.Ieee754Parameters::decimal(64) == Some(decimal64))
  assert_true(@core_theory.Ieee754Parameters::decimal(16) is None)
  let float64 = @core_theory.Sort::ieee754(binary64)
  inspect(
    float64.to_string(),
    content="core:float<core:bitv<core:IEEE754<2><11><52>><64>>",
  )
  assert_true(float64.ieee754_spec() == Some(binary64))
  assert_true(float64.ieee754_exps() == Some(@core_theory.Sort::bitv(11)))
  assert_true(float64.ieee754_sigs() == Some(@core_theory.Sort::bitv(53)))
  assert_true(float64.ieee754_bits() == Some(@core_theory.Sort::bitv(64)))
  assert_true(float64.float_width() == Some(64))
  assert_true(@core_theory.Sort::float(64).ieee754_spec() is None)
}

///|
test "variables preserve sorts versions and mutability flags" {
  let sort = @core_theory.Sort::bitv(64)
  let reg = @core_theory.Var::create(sort, "RAX")
  inspect(reg.name(), content="RAX")
  assert_true(reg.is_mutable())
  assert_true(!reg.is_virtual())
  assert_true(reg.equal(@core_theory.Var::create(sort, "RAX")))
  assert_true(
    !@core_theory.Var::create(sort, "tmp", is_mutable=false).is_mutable(),
  )
  inspect(@core_theory.Var::create(sort, "").name(), content="_")
  inspect(@core_theory.Var::create(sort, "0tmp").name(), content="_0tmp")
  inspect(@core_theory.Var::create(sort, "R.0").name(), content="R\\.0")
  inspect(@core_theory.Var::create(sort, "R 0").name(), content="R\\ 0")
  match @core_theory.Var::of_ident(sort, "RAX.3") {
    Ok(parsed) => {
      inspect(parsed.ident(), content="RAX")
      assert_true(parsed.version() == 3)
      assert_true(parsed.is_mutable())
      assert_true(!parsed.is_virtual())
      inspect(parsed.name(), content="RAX.3")
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Var::of_ident(sort, "R\\.0") {
    Ok(parsed) => {
      inspect(parsed.ident(), content="R\\.0")
      assert_true(parsed.version() == 0)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Var::of_ident(sort, "#7.2") {
    Ok(parsed) => {
      inspect(parsed.ident(), content="#7")
      assert_true(parsed.version() == 2)
      assert_true(parsed.is_virtual())
      assert_true(parsed.is_mutable())
      inspect(parsed.name(), content="#7.2")
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Var::of_ident(sort, "$4") {
    Ok(parsed) => {
      inspect(parsed.ident(), content="$4")
      assert_true(parsed.version() == 0)
      assert_true(parsed.is_virtual())
      assert_true(!parsed.is_mutable())
    }
    Err(reason) => fail(reason)
  }
  assert_true(@core_theory.Var::of_ident(sort, "") is Err(_))
  assert_true(@core_theory.Var::of_ident(sort, "#x") is Err(_))
  assert_true(@core_theory.Var::of_ident(sort, "R.") is Err(_))
  let versioned = reg.versioned(2)
  inspect(versioned.name(), content="RAX.2")
  assert_true(versioned.sort().same(sort))
  assert_true(reg.compare(versioned) < 0)
  assert_true(reg.forget().sort().same(sort))
  let fresh = @core_theory.Var::fresh(sort)
  assert_true(fresh.is_virtual())
  assert_true(fresh.is_mutable())
  assert_true(fresh.name().has_prefix("#"))
  @core_theory.Var::reset_temporary_counter()
  inspect(@core_theory.Var::fresh(sort).name(), content="#1")
  assert_var_persistent_round_trip(
    Some(@core_theory.Var::persistent()),
    versioned,
    "var",
  )
}

///|
test "effect sorts form the expected lattice" {
  assert_true(@core_theory.EffectSort::bot() == EffectBot)
  assert_true(@core_theory.EffectSort::top() == EffectTop)
  assert_true(@core_theory.EffectSort::data() == EffectData)
  assert_true(@core_theory.EffectSort::ctrl() == EffectCtrl)
  assert_true(@core_theory.EffectSort::rreg() == EffectData)
  assert_true(@core_theory.EffectSort::wreg() == EffectData)
  assert_true(@core_theory.EffectSort::rmem() == EffectData)
  assert_true(@core_theory.EffectSort::wmem() == EffectData)
  assert_true(@core_theory.EffectSort::barr() == EffectData)
  assert_true(@core_theory.EffectSort::fall() == EffectCtrl)
  assert_true(@core_theory.EffectSort::jump() == EffectCtrl)
  assert_true(@core_theory.EffectSort::cjmp() == EffectCtrl)
  assert_true(@core_theory.EffectData.both(EffectCtrl) == EffectBoth)
  assert_true(@core_theory.EffectSort::union_all([]) == EffectBot)
  assert_true(
    @core_theory.EffectSort::union_all([EffectData, EffectCtrl]) == EffectBoth,
  )
  assert_true(
    @core_theory.EffectSort::join([EffectData], [EffectCtrl]) == EffectBoth,
  )
  assert_true(@core_theory.EffectData.union(EffectCtrl) == EffectBoth)
  assert_true(@core_theory.EffectData.order(EffectBoth) == Less)
  assert_true(@core_theory.EffectData.order(EffectCtrl) == Incomparable)
  assert_persistent_round_trip(
    Some(@core_theory.EffectSort::persistent()),
    EffectBoth,
    "effect sort",
  )
  assert_true(@core_theory.Effect::jump().equal(@core_theory.Effect::jump()))
  match
    @core_theory.Effect::persistent().decode(
      @core_theory.Effect::persistent().encode(@core_theory.Effect::jump()),
    ) {
    Ok(decoded) => assert_true(decoded.equal(@core_theory.Effect::jump()))
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.Effect::jump().compare(@core_theory.Effect::fall()) != 0,
  )
  inspect(@core_theory.Effect::jump().to_string(), content="jump")
  assert_true(@core_theory.Effect::barr().sort() == EffectData)
  inspect(@core_theory.Effect::cjmp().to_string(), content="cjmp")
  assert_true(@core_theory.Effect::cjump().equal(@core_theory.Effect::cjmp()))
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
  assert_true(target.equal(target))
  assert_true(!target.equal(family))
  assert_true(target.compare(target) == 0)
  assert_true(target.compare(family) != 0)
  inspect(target.to_string(), content="target:x86-64")
  assert_true(target.hash() == target.name().hash())
  assert_true(
    target.hash() ==
    @core_theory.Target::create(
      name=@knowledge.Name::create("x86-64", pkg="target"),
    ).hash(),
  )
  let domain = @core_theory.Target::domain()
  assert_true(domain.is_empty(@core_theory.Target::unknown()))
  assert_true(domain.order(@core_theory.Target::unknown(), target) == Less)
  match domain.join(@core_theory.Target::unknown(), target) {
    Ok(joined) => assert_true(joined.equal(target))
    Err(reason) => fail(reason)
  }
  assert_true(domain.join(target, @core_theory.Target::arm()) is Err(_))
  assert_true(target.belongs(family))
  assert_true(target.order(family) == Less)
  assert_true(target.bits() == 64)
  assert_true(target.endianness() == LittleEndian)
  assert_true(target.parent().equal(family))
  match target.parents().get(0) {
    Some(parent) => assert_true(parent.equal(family))
    None => fail("missing target parent")
  }
  match target.parents().get(target.parents().length() - 1) {
    Some(parent) => assert_true(parent.is_unknown())
    None => fail("missing unknown parent sentinel")
  }
  assert_true(@core_theory.Target::unknown().parent().is_unknown())
  let data_mem = @core_theory.Var::create(
    @core_theory.Sort::mem(
      @core_theory.Sort::bitv(32),
      @core_theory.Sort::bitv(16),
    ),
    "data-memory",
    is_mutable=true,
  )
  let code_mem = @core_theory.Var::create(
    @core_theory.Sort::mem(
      @core_theory.Sort::bitv(48),
      @core_theory.Sort::bitv(8),
    ),
    "code-memory",
    is_mutable=true,
  )
  let memory_target = @core_theory.Target::create(
    name=@knowledge.Name::create("x86-memory", pkg="target"),
    parent=family,
    bits=64,
    data=data_mem,
    code=code_mem,
    data_alignment=16,
    code_alignment=32,
  )
  assert_true(memory_target.data().same(data_mem))
  assert_true(memory_target.code().same(code_mem))
  assert_true(memory_target.data_addr_size() == 32)
  assert_true(memory_target.code_addr_size() == 48)
  assert_true(memory_target.data_alignment() == 16)
  assert_true(memory_target.code_alignment() == 32)
  assert_true(
    memory_target.find_var("data-memory").map(v => v.same(data_mem)) ==
    Some(true),
  )
  assert_true(
    memory_target.find_var("code-memory").map(v => v.same(code_mem)) ==
    Some(true),
  )
  let little = @core_theory.Endianness::of_string("le").unwrap()
  let big = @core_theory.Endianness::of_string("be").unwrap()
  assert_true(@core_theory.Endianness::le() == LittleEndian)
  assert_true(@core_theory.Endianness::eb() == BigEndian)
  assert_true(@core_theory.Endianness::bi() == BiEndian)
  assert_true(little.equal(little))
  assert_true(little.compare(big) < 0)
  let unknown_system = @core_theory.System::of_string("unknown").unwrap()
  let linux = @core_theory.System::of_string("linux").unwrap()
  assert_true(@core_theory.System::unknown().is_unknown())
  assert_true(@core_theory.System::linux() == Linux)
  assert_true(@core_theory.System::hpux() == HPUX)
  assert_true(@core_theory.System::netbsd() == NetBSD)
  assert_true(@core_theory.System::darwin() == Darwin)
  assert_true(@core_theory.System::solaris() == Solaris)
  assert_true(@core_theory.System::aix() == AIX)
  assert_true(@core_theory.System::irix() == IRIX)
  assert_true(@core_theory.System::vxworks() == VxWorks)
  assert_true(@core_theory.System::freebsd() == FreeBSD)
  assert_true(@core_theory.System::tru64() == Tru64)
  assert_true(@core_theory.System::modesto() == Modesto)
  assert_true(@core_theory.System::openbsd() == OpenBSD)
  assert_true(@core_theory.System::windows() == Windows)
  assert_true(@core_theory.System::msdos() == MSDOS)
  assert_true(@core_theory.System::uefi() == UEFI)
  assert_true(@core_theory.System::none() == NoSystem)
  assert_true(unknown_system.is_unknown())
  assert_true(!linux.is_unknown())
  assert_true(linux.equal(@core_theory.System::of_string("linux").unwrap()))
  assert_true(unknown_system.compare(linux) < 0)
  assert_true(@core_theory.Abi::unknown().is_unknown())
  assert_true(@core_theory.Abi::gnu() == GNU)
  assert_true(@core_theory.Abi::sysv() == SysV)
  assert_true(@core_theory.Abi::eabi() == EABI)
  assert_true(@core_theory.Abi::gnueabi() == GNUEABI)
  assert_true(@core_theory.Abi::cdecl() == CDecl)
  assert_true(@core_theory.Abi::pascal() == Pascal)
  assert_true(@core_theory.Abi::fortran() == FortranAbi)
  assert_true(@core_theory.Abi::stdcall() == StdCall)
  assert_true(@core_theory.Abi::fastcall() == FastCall)
  assert_true(@core_theory.Abi::thiscall() == ThisCall)
  assert_true(@core_theory.Abi::vectorcall() == VectorCall)
  assert_true(@core_theory.Abi::watcom() == Watcom)
  assert_true(@core_theory.Abi::ms() == MSVC)
  assert_true(@core_theory.Abi::msvc() == MSVC)
  assert_true(@core_theory.Abi::smc() == SMC)
  assert_true(@core_theory.Abi::hvc() == HVC)
  assert_true(!@core_theory.Abi::of_string("gnu").unwrap().is_unknown())
  assert_true(
    @core_theory.Abi::of_string("sysv")
    .unwrap()
    .compare(@core_theory.Abi::of_string("gnu").unwrap()) <
    0,
  )
  assert_true(@core_theory.Fabi::unknown().is_unknown())
  assert_true(@core_theory.Fabi::hard() == Hard)
  assert_true(@core_theory.Fabi::soft() == Soft)
  assert_true(!@core_theory.Fabi::of_string("hard").unwrap().is_unknown())
  assert_true(
    @core_theory.Fabi::of_string("soft")
    .unwrap()
    .compare(@core_theory.Fabi::of_string("hard").unwrap()) <
    0,
  )
  assert_true(@core_theory.Filetype::unknown().is_unknown())
  assert_true(@core_theory.Filetype::elf() == Elf)
  assert_true(@core_theory.Filetype::coff() == COFF)
  assert_true(@core_theory.Filetype::macho() == MachO)
  assert_true(@core_theory.Filetype::aout() == AOut)
  assert_true(@core_theory.Filetype::pe() == PE)
  assert_true(@core_theory.Filetype::raw() == Raw)
  assert_true(!@core_theory.Filetype::of_string("elf").unwrap().is_unknown())
  assert_true(
    @core_theory.Filetype::of_string("elf")
    .unwrap()
    .compare(@core_theory.Filetype::of_string("raw").unwrap()) <
    0,
  )
  assert_true(target.matches("amd64"))
  assert_true(target.matches("X86"))
  assert_true(target.find_var("PC") is Some(_))
  match target.origin_of_name("EAX") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "EAX")
      assert_true(origin.reg().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.source().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.range() == Some((0, 31)))
      assert_true(origin.lo() == Some(0))
      assert_true(origin.hi() == Some(31))
      assert_true(!origin.is_alias())
    }
    None => fail("missing EAX alias origin")
  }
  let direct_alias = @core_theory.AliasOrigin::register(pc, rax)
  assert_true(direct_alias.reg().map(v => v.ident()) == Some("RAX"))
  assert_true(direct_alias.is_alias())
  assert_true(direct_alias.lo() is None)
  assert_true(direct_alias.hi() is None)
}

///|
test "target registry resolves common and custom declarations" {
  match @core_theory.get_target("AMD64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.code_addr_size() == 64)
      assert_true(target.data_alignment() == 8)
      assert_true(target.code_alignment() == 8)
      assert_true(target.data().same(target.code()))
      assert_true(target.data().ident() == "mem")
      assert_true(target.data().is_mutable())
      inspect(
        target.data().sort().to_string(),
        content="core:mem<core:bitv<64>><core:bitv<8>>",
      )
      let raw = @bitvec.of_uint64(width=128, 0x1234)
      assert_true(target.code_addr(raw).to_string() == "0x1234:64u")
      assert_true(target.data_addr(raw).to_string() == "0x1234:64u")
      assert_true(target.data_word(raw).to_string() == "0x1234:64u")
      assert_true(target.belongs(@core_theory.Target::x86()))
      assert_true(target.find_var("RIP") is Some(_))
      assert_true(target.matching("x86") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::read("AMD64") {
    Ok(target) => assert_true(target.bits() == 64)
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("riscv64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.find_var("PC") is Some(_))
      assert_true(target.find_var("a0") is Some(_))
      assert_true(target.belongs(@core_theory.Target::riscv()))
      assert_true(!target.belongs(@core_theory.Target::riscv32()))
      assert_true(target.matches("riscv"))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("riscv") {
    Ok(target) => {
      assert_true(target.bits() == 0)
      assert_true(target.endianness() == LittleEndian)
      assert_true(@core_theory.Target::riscv32().belongs(target))
      assert_true(@core_theory.Target::riscv64().belongs(target))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("thumb") {
    Ok(target) => {
      assert_true(target.bits() == 32)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.code_alignment() == 16)
      assert_true(target.belongs(@core_theory.Target::arm()))
      assert_true(target.matches("thumbv7"))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("thumbv7eb") {
    Ok(target) => {
      assert_true(target.endianness() == BigEndian)
      assert_true(target.code_alignment() == 16)
      assert_true(target.belongs(@core_theory.Target::armeb()))
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::arm()))
      assert_true(target.matches("thumbeb"))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("arm-family") {
    Ok(target) => {
      assert_true(@core_theory.Target::arm().belongs(target))
      assert_true(@core_theory.Target::armeb().belongs(target))
      assert_true(@core_theory.Target::aarch64().belongs(target))
      assert_true(@core_theory.Target::aarch64_be().belongs(target))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv4") {
    Ok(target) => {
      assert_true(target.matches("armv4+le"))
      assert_true(target.bits() == 32)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.code_alignment() == 32)
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::arm()))
      assert_true(target.find_var("R0") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv4eb") {
    Ok(target) => {
      assert_true(target.matches("armv4+be"))
      assert_true(target.bits() == 32)
      assert_true(target.endianness() == BigEndian)
      assert_true(target.code_alignment() == 32)
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::armeb()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv7-a+fp") {
    Ok(target) => {
      assert_true(target.matches("armv7-a+fp+le"))
      assert_true(target.code_alignment() == 16)
      assert_true(@core_theory.Target::arm().belongs(target))
      assert_true(target.find_var("SP") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv8-m+aarch32+le") {
    Ok(target) => {
      assert_true(target.matches("armv8-m+aarch32"))
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.code_alignment() == 16)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv7+bi") {
    Ok(target) => {
      assert_true(target.matches("armv7"))
      assert_true(target.bits() == 32)
      assert_true(target.endianness() == BiEndian)
      assert_true(target.code_alignment() == 16)
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::arm()))
      assert_true(!target.belongs(@core_theory.Target::armeb()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("armv8-a+bi") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == BiEndian)
      assert_true(target.code_alignment() == 32)
      assert_true(target.find_var("X0") is Some(_))
      assert_true(target.find_var("XZR") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("ia-32") {
    Ok(target) => assert_true(target.matches("x86"))
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("8086") {
    Ok(target) => {
      assert_true(target.matches("i86"))
      assert_true(target.bits() == 16)
      assert_true(target.find_var("AX") is Some(_))
      assert_true(target.find_var("EAX") is None)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("80186") {
    Ok(target) => {
      assert_true(target.matches("i186"))
      assert_true(target.belongs(@core_theory.Target::i86()))
      assert_true(target.bits() == 16)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("80286") {
    Ok(target) => {
      assert_true(target.matches("i286"))
      assert_true(target.belongs(@core_theory.Target::i186()))
      assert_true(target.bits() == 16)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("i286-msdos-cdecl") {
    Ok(target) => {
      assert_true(target.bits() == 16)
      assert_true(target.system() == MSDOS)
      assert_true(target.abi() == CDecl)
      assert_true(target.filetype() == UnknownFiletype)
      assert_true(target.belongs(@core_theory.Target::i286()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("i286-msdos-pascal") {
    Ok(target) => {
      assert_true(target.system() == MSDOS)
      assert_true(target.abi() == Pascal)
      assert_true(target.belongs(@core_theory.Target::i286()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("80386") {
    Ok(target) => {
      assert_true(target.matches("i386"))
      assert_true(target.bits() == 32)
      assert_true(target.find_var("EAX") is Some(_))
      assert_true(target.find_var("ST0") is None)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("80486") {
    Ok(target) => {
      assert_true(target.matches("i486"))
      assert_true(target.find_var("ST0") is Some(_))
      assert_true(target.find_var("MM0") is None)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("p5") {
    Ok(target) => {
      assert_true(target.matches("i586"))
      assert_true(target.find_var("MM0") is Some(_))
      assert_true(target.find_var("XMM0") is None)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("p6") {
    Ok(target) => {
      assert_true(target.matches("i686"))
      assert_true(target.find_var("XMM0") is Some(_))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("x86_64h") {
    Ok(target) => {
      assert_true(target.matches("x86_64"))
      assert_true(target.belongs(@core_theory.Target::i686()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("ppu") {
    Ok(target) => assert_true(target.matches("powerpc64"))
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("ppc32eb") {
    Ok(target) => {
      assert_true(target.matches("powerpc"))
      assert_true(target.matches("powerpc32eb"))
      assert_true(target.endianness() == BigEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("mips64el") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.belongs(@core_theory.Target::mips_family()))
      assert_true(!target.belongs(@core_theory.Target::mips()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("mips-family") {
    Ok(target) => {
      assert_true(target.bits() == 0)
      assert_true(@core_theory.Target::mipsbi().belongs(target))
      assert_true(@core_theory.Target::mips().belongs(target))
      assert_true(@core_theory.Target::mipsel().belongs(target))
      assert_true(@core_theory.Target::mips64bi().belongs(target))
      assert_true(@core_theory.Target::mips64().belongs(target))
      assert_true(@core_theory.Target::mips64el().belongs(target))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("sparc64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == BigEndian)
      assert_true(target.matches("sparcv9"))
      assert_true(target.belongs(@core_theory.Target::sparc()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("s390x") {
    Ok(target) => {
      assert_true(target.matches("systemz"))
      assert_true(target.matches("systemz9"))
      assert_true(target.belongs(@core_theory.Target::systemz()))
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == BigEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("systemz9") {
    Ok(target) => {
      assert_true(target.matches("s390x"))
      assert_true(target.belongs(@core_theory.Target::systemz()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("nvptx64") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.belongs(@core_theory.Target::nvptx()))
    }
    Err(reason) => fail(reason)
  }
  assert_true(@core_theory.get_target("hexagon") is Ok(_))
  assert_true(@core_theory.get_target("r600") is Ok(_))
  assert_true(@core_theory.get_target("xcore") is Ok(_))
  match @core_theory.Target::get("x86_64-windows-ms-coff") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.system() == Windows)
      assert_true(target.abi() == MSVC)
      assert_true(target.filetype() == COFF)
      assert_true(target.belongs(@core_theory.Target::x86_64()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("arm64_be") {
    Ok(target) => {
      assert_true(target.matches("aarch64_be"))
      assert_true(target.endianness() == BigEndian)
      assert_true(target.code_alignment() == 32)
    }
    Err(reason) => fail(reason)
  }
  match
    @core_theory.Target::select(
      parent=@core_theory.Target::x86_64(),
      system=Windows,
      abi=MSVC,
      filetype=COFF,
      unique=true,
    ) {
    Ok(target) => {
      assert_true(target.matches("x86_64-windows-ms-coff"))
      assert_true(target.filetype().to_string() == "coff")
    }
    Err(reason) => fail(reason)
  }
  assert_true(@core_theory.Target::lookup("x86-linux-gnu-elf") is Some(_))
  assert_true(
    @core_theory.Target::filter(
      parent=@core_theory.Target::x86(),
      system=FreeBSD,
      abi=CDecl,
      filetype=Elf,
    ).any(target => target.matches("x86-freebsd-cdecl-elf")),
  )
  match @core_theory.Target::get("arm-linux-gnueabihard-elf") {
    Ok(target) => {
      assert_true(target.system() == Linux)
      assert_true(target.abi() == GNUEABI)
      assert_true(target.fabi() == Hard)
      assert_true(target.filetype() == Elf)
      assert_true(target.belongs(@core_theory.Target::arm()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("thumb-linux-gnueabihard-elf") {
    Ok(target) => {
      assert_true(target.system() == Linux)
      assert_true(target.abi() == GNUEABI)
      assert_true(target.fabi() == Hard)
      assert_true(target.filetype() == Elf)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.belongs(@core_theory.Target::thumb()))
      assert_true(target.belongs(@core_theory.Target::arm()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("thumbeb-linux-gnu-elf") {
    Ok(target) => {
      assert_true(target.system() == Linux)
      assert_true(target.abi() == GNU)
      assert_true(target.filetype() == Elf)
      assert_true(target.endianness() == BigEndian)
      assert_true(target.belongs(@core_theory.Target::thumbeb()))
      assert_true(target.belongs(@core_theory.Target::armeb()))
    }
    Err(reason) => fail(reason)
  }
  assert_true(@core_theory.Target::lookup("thumb-none-eabihard") is Some(_))
  match @core_theory.Target::lookup("armv7-a+fp") {
    Some(target) => {
      assert_true(target.matches("armv7-a+fp+le"))
      assert_true(@core_theory.Target::arm().belongs(target))
      assert_true(target.find_var("D31") is Some(_))
    }
    None => fail("missing ARMv7-A+FP target alias")
  }
  match @core_theory.Target::lookup("armv7-a+fp+le") {
    Some(target) => {
      assert_true(target.matches("armv7-a+fp"))
      assert_true(@core_theory.Target::arm().belongs(target))
    }
    None => fail("missing ARMv7-A+FP little-endian target alias")
  }
  match @core_theory.Target::lookup("armv7-a+fp+be") {
    Some(target) => {
      assert_true(target.matches("armv7-a+fp"))
      assert_true(@core_theory.Target::armeb().belongs(target))
      assert_true(target.endianness() == BigEndian)
    }
    None => fail("missing ARMv7-A+FP big-endian target alias")
  }
  match @core_theory.Target::lookup("armv7-m") {
    Some(target) => {
      assert_true(target.matches("armv7-m+le"))
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::arm()))
    }
    None => fail("missing ARMv7-M target alias")
  }
  match @core_theory.Target::lookup("armv7-m+be") {
    Some(target) => {
      assert_true(target.matches("armv7-m"))
      assert_true(target.belongs(@core_theory.Target::arm_family()))
      assert_true(!target.belongs(@core_theory.Target::armeb()))
      assert_true(target.endianness() == BigEndian)
    }
    None => fail("missing ARMv7-M big-endian target alias")
  }
  match @core_theory.Target::lookup("armv8.6-a") {
    Some(target) => {
      assert_true(target.matches("armv8.6-a+le"))
      assert_true(target.bits() == 64)
      assert_true(target.code_alignment() == 32)
      assert_true(@core_theory.Target::aarch64().belongs(target))
    }
    None => fail("missing ARMv8.6-A target alias")
  }
  match @core_theory.Target::lookup("armv8.1-a+le") {
    Some(target) => {
      assert_true(target.matches("armv8.1-a"))
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.find_var("XZR") is Some(_))
    }
    None => fail("missing ARMv8.1-A little-endian target alias")
  }
  match @core_theory.Target::lookup("armv8.1-a+be") {
    Some(target) => {
      assert_true(target.matches("armv8.1-a"))
      assert_true(target.endianness() == BigEndian)
      assert_true(@core_theory.Target::aarch64_be().belongs(target))
    }
    None => fail("missing ARMv8.1-A big-endian target alias")
  }
  match
    @core_theory.Target::select(
      parent=@core_theory.Target::thumb(),
      system=Linux,
      abi=GNUEABI,
      fabi=Hard,
      filetype=Elf,
      unique=true,
    ) {
    Ok(target) => assert_true(target.matches("thumb-linux-gnueabihard-elf"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("aarch64-windows-eabi-coff") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.system() == Windows)
      assert_true(target.abi() == EABI)
      assert_true(target.filetype() == COFF)
      assert_true(target.belongs(@core_theory.Target::aarch64()))
    }
    Err(reason) => fail(reason)
  }
  match
    @core_theory.Target::select(
      parent=@core_theory.Target::aarch64(),
      system=UEFI,
      abi=SMC,
      filetype=COFF,
      unique=true,
    ) {
    Ok(target) => assert_true(target.matches("aarch64-uefi-smc-coff"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips64el-linux-gnu-elf") {
    Ok(target) => {
      assert_true(target.bits() == 64)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.system() == Linux)
      assert_true(target.abi() == GNU)
      assert_true(target.filetype() == Elf)
      assert_true(target.belongs(@core_theory.Target::mips64el()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mipsbe") {
    Ok(target) => assert_true(target.matches("mips"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips32bi") {
    Ok(target) => {
      assert_true(target.matches("mipsbi"))
      assert_true(target.endianness() == BiEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips32le") {
    Ok(target) => assert_true(target.matches("mipsel"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips64bi") {
    Ok(target) => {
      assert_true(target.matches("mips64bi"))
      assert_true(target.endianness() == BiEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips64be") {
    Ok(target) => assert_true(target.matches("mips64"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("mips64le") {
    Ok(target) => assert_true(target.matches("mips64el"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("misp64le") {
    Ok(target) => assert_true(target.matches("mips64el"))
    Err(reason) => fail(reason)
  }
  match
    @core_theory.Target::select(
      parent=@core_theory.Target::mips64el(),
      system=Linux,
      abi=GNU,
      filetype=Elf,
      unique=true,
    ) {
    Ok(target) => assert_true(target.matches("mips64el-linux-gnu-elf"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("ppc32le") {
    Ok(target) => {
      assert_true(target.matches("powerpcle"))
      assert_true(target.bits() == 32)
      assert_true(target.endianness() == LittleEndian)
      assert_true(target.belongs(@core_theory.Target::powerpc_family()))
      assert_true(!target.belongs(@core_theory.Target::powerpc()))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("power") {
    Ok(target) => assert_true(target.matches("powerpc"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("powerpc32+le") {
    Ok(target) => assert_true(target.matches("powerpcle"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("powerpc32+bi") {
    Ok(target) => {
      assert_true(target.matches("powerpcbi"))
      assert_true(target.endianness() == BiEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("power64be") {
    Ok(target) => assert_true(target.matches("powerpc64"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("powerpc64+bi") {
    Ok(target) => {
      assert_true(target.matches("powerpc64bi"))
      assert_true(target.endianness() == BiEndian)
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("power64le") {
    Ok(target) => assert_true(target.matches("powerpc64le"))
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("powerpc-family") {
    Ok(target) => {
      assert_true(@core_theory.Target::powerpcbi().belongs(target))
      assert_true(@core_theory.Target::powerpc().belongs(target))
      assert_true(@core_theory.Target::powerpcle().belongs(target))
      assert_true(@core_theory.Target::powerpc64bi().belongs(target))
      assert_true(@core_theory.Target::powerpc64().belongs(target))
      assert_true(@core_theory.Target::powerpc64le().belongs(target))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::get("powerpcle-vxworks-gnu-macho") {
    Ok(target) => {
      assert_true(target.system() == VxWorks)
      assert_true(target.abi() == GNU)
      assert_true(target.filetype() == MachO)
      assert_true(target.belongs(@core_theory.Target::powerpcle()))
    }
    Err(reason) => fail(reason)
  }
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-target-registry", pkg="test"),
    nicknames=["unit-target-alias"],
    bits=16,
  )
  match @core_theory.Target::register(target) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.Target::lookup("unit-target-alias").map(t => t.bits()) ==
    Some(16),
  )
  match @core_theory.Target::get("unit-target-alias") {
    Ok(target) => assert_true(target.bits() == 16)
    Err(reason) => fail(reason)
  }
  let packaged_a = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-packaged-target", pkg="test-a"),
    bits=8,
  )
  let packaged_b = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-packaged-target", pkg="test-b"),
    bits=32,
  )
  match @core_theory.Target::register(packaged_a) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::register(packaged_b) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.Target::lookup("unit-packaged-target", pkg="test-a").map(t => {
      t.bits()
    }) ==
    Some(8),
  )
  assert_true(
    @core_theory.Target::lookup("test-b:unit-packaged-target").map(t => t.bits()) ==
    Some(32),
  )
  assert_true(
    @core_theory.Target::lookup("test-b:UNIT-PACKAGED-TARGET").map(t => t.bits()) ==
    Some(32),
  )
  match @core_theory.Target::get("unit-packaged-target", pkg="test-b") {
    Ok(target) => assert_true(target.bits() == 32)
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.Target::lookup("unit-packaged-target", pkg="missing") is None,
  )
  assert_true(
    @core_theory.Target::lookup("missing:unit-packaged-target") is None,
  )
  assert_true(
    @core_theory.find_target("unit-target-alias").map(t => t.bits()) == Some(16),
  )
  assert_true(@core_theory.Target::register(target) is Err(_))
  assert_true(
    @core_theory.Target::declared().any(t => t.matches("unit-target-alias")),
  )
  assert_true(
    @core_theory.Target::families().any(group => {
      group.any(t => t.matches("unit-target-alias"))
    }),
  )
}

///|
test "target selection filters BAP-style metadata constraints" {
  let parent = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-select-root", pkg="test"),
    bits=32,
  )
  let linux_elf = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-select-linux-elf", pkg="test"),
    parent~,
    system=Linux,
    abi=GNU,
    filetype=Elf,
    options=@core_theory.TargetOptions::singleton("cpu", "v2"),
  )
  let linux_macho = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-select-linux-macho", pkg="test"),
    parent~,
    system=Linux,
    abi=GNU,
    filetype=MachO,
    options=@core_theory.TargetOptions::singleton("cpu", "v1"),
  )
  let darwin = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-select-darwin", pkg="test"),
    parent~,
    system=Darwin,
    abi=SysV,
    filetype=MachO,
  )
  for target in [parent, linux_elf, linux_macho, darwin] {
    match @core_theory.register_target(target) {
      Ok(_) => ()
      Err(reason) => fail(reason)
    }
  }

  let all = @core_theory.Target::filter(parent~)
  assert_true(all.length() == 4)
  let family = @core_theory.Target::family(parent)
  assert_true(family.length() == 4)
  assert_true(family[0].name().unqualified() == "unit-select-root")
  let linux = @core_theory.Target::filter(parent~, system=Linux)
  assert_true(linux.length() == 2)
  assert_true(linux.all(target => target.system() == Linux))
  let linux_elf_matches = @core_theory.Target::filter(
    parent~,
    system=Linux,
    abi=GNU,
    filetype=Elf,
  )
  assert_true(linux_elf_matches.length() == 1)
  assert_true(
    linux_elf_matches[0].name().unqualified() == "unit-select-linux-elf",
  )
  let cpu_v2_options = @core_theory.TargetOptions::of_map({ "cpu": "v2" })
  assert_true(linux_elf_matches[0].options().get("cpu") == Some("v2"))
  assert_true(linux_elf_matches[0].options().equal(cpu_v2_options))
  assert_true(linux_elf_matches[0].options().compare(cpu_v2_options) == 0)
  assert_true(
    linux_elf_matches[0]
    .options()
    .compare(@core_theory.TargetOptions::singleton("cpu", "v1")) !=
    0,
  )
  assert_true(linux_elf_matches[0].options().to_string() == "+cpu=v2")
  let cpu_v2 = @core_theory.Target::filter(
    parent~,
    system=Linux,
    options=cpu_v2_options,
  )
  assert_true(cpu_v2.length() == 1)
  assert_true(cpu_v2[0].name().unqualified() == "unit-select-linux-elf")
  assert_true(
    @core_theory.Target::filter(
      parent~,
      system=Linux,
      abi=GNU,
      filetype=Elf,
      options=@core_theory.TargetOptions::singleton("cpu", "v2"),
      strict=true,
    ).length() ==
    1,
  )
  match @core_theory.Target::select(parent~, system=Linux, abi=GNU) {
    Ok(target) => assert_true(target.system() == Linux)
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::select(parent~, system=Windows) {
    Ok(target) => assert_true(target.equal(parent))
    Err(reason) => fail(reason)
  }
  assert_true(
    @core_theory.Target::select(parent~, system=Linux, abi=GNU, unique=true)
    is Err(_),
  )
  assert_true(
    @core_theory.Target::select(parent~, system=Windows, strict=true) is Err(_),
  )
  let strict_unknown = @core_theory.Target::filter(parent~, strict=true)
  assert_true(strict_unknown.length() == 1)
  assert_true(strict_unknown[0].name().unqualified() == "unit-select-root")
  assert_true(
    @core_theory.Target::filter().any(target => target.matches("x86_64")),
  )
  let partitions = @core_theory.Target::partition([
    @core_theory.Target::x86_64(),
    darwin,
    parent,
    linux_elf,
    @core_theory.Target::x86(),
  ])
  assert_true(partitions.length() == 2)
  match
    partitions.search_by(group => {
      group[0].name().unqualified() == "unit-select-root"
    }) {
    Some(index) => assert_true(partitions[index].length() == 3)
    None => fail("missing unit-select-root partition")
  }
  match partitions.search_by(group => group[0].matches("x86")) {
    Some(index) => {
      assert_true(partitions[index][0].matches("x86"))
      assert_true(partitions[index][1].matches("x86_64"))
    }
    None => fail("missing x86 partition")
  }
}

///|
test "target variant registration generates BAP-style names" {
  let parent = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-variant-root", pkg="test"),
    bits=64,
  )
  match @core_theory.register_target(parent) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let tuned = @core_theory.TargetOptions::singleton("cpu", "tiny")
  match
    @core_theory.Target::register_variants(
      parent,
      systems=[Linux, Darwin],
      abis=[GNU],
      filetypes=[Elf],
      options=[@core_theory.TargetOptions::empty(), tuned],
    ) {
    Ok(variants) => {
      assert_true(variants.length() == 4)
      assert_true(
        variants.any(target => {
          target.name().unqualified() == "unit-variant-root-linux-gnu-elf"
        }),
      )
      assert_true(
        variants.any(target => {
          target.name().unqualified() ==
          "unit-variant-root-linux-gnu-elf+cpu=tiny"
        }),
      )
      let tuned_matches = @core_theory.Target::filter(
        parent~,
        system=Linux,
        options=tuned,
      )
      assert_true(tuned_matches.length() == 1)
      assert_true(tuned_matches[0].options().get("cpu") == Some("tiny"))
    }
    Err(reason) => fail(reason)
  }
  match
    @core_theory.Target::register_variants(
      parent,
      systems=[Linux],
      abis=[GNU],
      filetypes=[Elf],
      pkg="test-variant-override",
    ) {
    Ok(variants) => {
      assert_true(variants.length() == 1)
      let variant = variants[0]
      assert_true(variant.name().pkg() == "test-variant-override")
      assert_true(
        @core_theory.Target::lookup(
          "unit-variant-root-linux-gnu-elf",
          pkg="test-variant-override",
        ).map(target => target.name().pkg()) ==
        Some("test-variant-override"),
      )
      assert_true(
        @core_theory.Target::lookup(
          "unit-variant-root-linux-gnu-elf",
          pkg="test",
        ).map(target => target.name().pkg()) ==
        Some("test"),
      )
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.Target::register_variants(parent) {
    Ok(empty) => assert_true(empty.is_empty())
    Err(reason) => fail(reason)
  }
}

///|
test "target metadata enums parse loader strings" {
  assert_true(
    @core_theory.Endianness::of_string("little-endian") == Some(LittleEndian),
  )
  assert_true(@core_theory.Endianness::of_string("BE") == Some(BigEndian))
  assert_true(@core_theory.System::of_string("hp-ux") == Some(HPUX))
  assert_true(@core_theory.System::of_string("net-bsd") == Some(NetBSD))
  assert_true(@core_theory.System::of_string("macos") == Some(Darwin))
  assert_true(@core_theory.System::of_string("sunos") == Some(Solaris))
  assert_true(@core_theory.System::of_string("aix") == Some(AIX))
  assert_true(@core_theory.System::of_string("irix") == Some(IRIX))
  assert_true(@core_theory.System::of_string("freebsd") == Some(FreeBSD))
  assert_true(@core_theory.System::of_string("tru-64") == Some(Tru64))
  assert_true(@core_theory.System::of_string("modesto") == Some(Modesto))
  assert_true(@core_theory.System::of_string("vx-works") == Some(VxWorks))
  assert_true(@core_theory.System::of_string("bare-metal") == Some(NoSystem))
  assert_true(@core_theory.Abi::of_string("system-v") == Some(SysV))
  assert_true(@core_theory.Abi::of_string("gnu-eabi") == Some(GNUEABI))
  assert_true(@core_theory.Abi::of_string("pascal") == Some(Pascal))
  assert_true(@core_theory.Abi::of_string("fortran") == Some(FortranAbi))
  assert_true(@core_theory.Abi::of_string("std-call") == Some(StdCall))
  assert_true(@core_theory.Abi::of_string("this-call") == Some(ThisCall))
  assert_true(@core_theory.Abi::of_string("vector-call") == Some(VectorCall))
  assert_true(
    @core_theory.Abi::of_string("msvc").map(a => a.to_string()) == Some("ms"),
  )
  assert_true(@core_theory.Abi::of_string("smc") == Some(SMC))
  assert_true(@core_theory.Abi::of_string("hvc") == Some(HVC))
  assert_true(@core_theory.Fabi::of_string("hard-float") == Some(Hard))
  assert_true(@core_theory.Filetype::of_string("mach-o") == Some(MachO))
  assert_true(@core_theory.Filetype::of_string("coff") == Some(COFF))
  assert_true(@core_theory.Filetype::of_string("pe-coff") == Some(PE))
  assert_true(@core_theory.Filetype::of_string("a.out") == Some(AOut))
  inspect(@core_theory.Raw.to_string(), content="raw")
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("unit-metadata", pkg="test"),
    system=FreeBSD,
    abi=CDecl,
    fabi=Soft,
    filetype=AOut,
  )
  assert_true(target.system().to_string() == "freebsd")
  assert_true(target.abi().to_string() == "cdecl")
  assert_true(target.fabi().to_string() == "soft")
  assert_true(target.filetype().to_string() == "aout")
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
  let stack_pointer = @core_theory.Role::of_string("stack-pointer").unwrap()
  let argument = @core_theory.Role::of_string("function-argument").unwrap()
  let result = @core_theory.Role::of_string("function-return").unwrap()
  let alias_role = @core_theory.Role::of_string("alias").unwrap()
  let zero_flag = @core_theory.Role::of_string("zero-flag").unwrap()
  let thumb_role = @core_theory.Role::of_string("thumb").unwrap()
  assert_true(stack_pointer.to_string() == "stack-pointer")
  assert_true(alias_role.to_string() == "alias")
  assert_true(zero_flag.to_string() == "zero-flag")
  assert_true(thumb_role.to_string() == "thumb")
  assert_true(@core_theory.Role::general() == General)
  assert_true(@core_theory.Role::special() == SpecialRegister)
  assert_true(@core_theory.Role::alias_register() == AliasRegister)
  assert_true(@core_theory.Role::pseudo() == PseudoRegister)
  assert_true(@core_theory.Role::integer() == IntegerRegister)
  assert_true(@core_theory.Role::floating() == FloatingRegister)
  assert_true(@core_theory.Role::vector() == VectorRegister)
  assert_true(@core_theory.Role::stack_pointer() == StackPointer)
  assert_true(@core_theory.Role::frame_pointer() == FramePointer)
  assert_true(@core_theory.Role::link() == LinkRegister)
  assert_true(@core_theory.Role::thread() == ThreadPointer)
  assert_true(@core_theory.Role::privileged() == PrivilegedRegister)
  assert_true(@core_theory.Role::constant() == Constant)
  assert_true(@core_theory.Role::zero() == ZeroRegister)
  assert_true(@core_theory.Role::one() == OneRegister)
  assert_true(@core_theory.Role::status() == Status)
  assert_true(@core_theory.Role::control() == ControlRegister)
  assert_true(@core_theory.Role::system() == SystemRegister)
  assert_true(@core_theory.Role::hardware() == HardwareRegister)
  assert_true(@core_theory.Role::reserved() == Reserved)
  assert_true(@core_theory.Role::zero_flag() == ZeroFlag)
  assert_true(@core_theory.Role::sign_flag() == SignFlag)
  assert_true(@core_theory.Role::carry_flag() == CarryFlag)
  assert_true(@core_theory.Role::overflow_flag() == OverflowFlag)
  assert_true(@core_theory.Role::parity_flag() == ParityFlag)
  assert_true(@core_theory.Role::function_argument() == Argument)
  assert_true(@core_theory.Role::function_return() == ResultRegister)
  assert_true(@core_theory.Role::caller_saved() == CallerSaved)
  assert_true(@core_theory.Role::callee_saved() == CalleeSaved)
  assert_true(@core_theory.Role::thumb() == ThumbMode)
  assert_true(
    @core_theory.Role::of_string("function-argument") == Some(Argument),
  )
  assert_true(@core_theory.Role::of_string("sign-flag") == Some(SignFlag))
  assert_true(@core_theory.Role::of_string("thumb-mode") == Some(ThumbMode))
  assert_true(argument.equal(argument))
  assert_true(argument.compare(result) < 0)
  match amd64.find_var("RSP") {
    Some(sp) => assert_true(amd64.roles_of_var(sp).contains(StackPointer))
    None => fail("missing RSP")
  }
  match amd64.find_var("RIP") {
    Some(pc) => {
      assert_true(amd64.roles_of_var(pc).contains(ProgramCounter))
      assert_true(amd64.roles_of_var(pc).contains(PseudoRegister))
    }
    None => fail("missing RIP")
  }
  match amd64.find_var("RDI") {
    Some(arg) => assert_true(amd64.roles_of_var(arg).contains(Argument))
    None => fail("missing RDI")
  }
  match amd64.find_var("RAX") {
    Some(result) => {
      assert_true(amd64.roles_of_var(result).contains(IntegerRegister))
      assert_true(amd64.roles_of_var(result).contains(ResultRegister))
    }
    None => fail("missing RAX")
  }
  match amd64.find_var("EAX") {
    Some(alias_var) => {
      assert_true(amd64.roles_of_var(alias_var).contains(IntegerRegister))
      assert_true(amd64.roles_of_var(alias_var).contains(ResultRegister))
      assert_true(amd64.roles_of_var(alias_var).contains(AliasRegister))
      assert_true(
        amd64.unalias(alias_var).map(o => o.range()) == Some(Some((0, 31))),
      )
    }
    None => fail("missing EAX")
  }
  match amd64.origin_of_name("EAX") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "EAX")
      assert_true(origin.source().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.range() == Some((0, 31)))
    }
    None => fail("missing EAX alias origin")
  }
  match amd64.origin_of_name("AL") {
    Some(origin) => {
      assert_true(origin.source().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.range() == Some((0, 7)))
    }
    None => fail("missing AL alias origin")
  }
  match amd64.origin_of_name("AH") {
    Some(origin) => {
      assert_true(origin.source().map(v => v.ident()) == Some("RAX"))
      assert_true(origin.range() == Some((8, 15)))
    }
    None => fail("missing AH alias origin")
  }
  match amd64.origin_of_name("R9D") {
    Some(origin) => {
      assert_true(origin.source().map(v => v.ident()) == Some("R9"))
      assert_true(origin.range() == Some((0, 31)))
    }
    None => fail("missing R9D alias origin")
  }
  match amd64.find_var("YMM7") {
    Some(vector) => {
      assert_true(amd64.roles_of_var(vector).contains(VectorRegister))
      assert_true(amd64.roles_of_var(vector).contains(FloatingRegister))
    }
    None => fail("missing YMM7")
  }
  match amd64.origin_of_name("XMM7") {
    Some(origin) => {
      assert_true(origin.source().map(v => v.ident()) == Some("YMM7"))
      assert_true(origin.range() == Some((0, 127)))
    }
    None => fail("missing XMM7 alias origin")
  }
  match amd64.origin_of_name("EFLAGS") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "EFLAGS")
      assert_true(!origin.is_alias())
      assert_true(origin.reg() is None)
      assert_true(origin.lo() is None)
      assert_true(origin.hi() is None)
      assert_true(origin.bits().length() == 32)
      assert_true(origin.bits().any(v => v.ident() == "CF"))
      assert_true(origin.bits().any(v => v.ident() == "ZF"))
      assert_true(origin.bits().any(v => v.ident() == "OF"))
    }
    None => fail("missing EFLAGS alias origin")
  }
  assert_true(
    amd64
    .alias_origins()
    .any(origin => {
      origin.aliased().ident() == "EFLAGS" &&
      origin.source().map(v => v.ident()) == Some("RFLAGS") &&
      origin.range() == Some((0, 31))
    }),
  )
  match amd64.origin_of_name("IOPL") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "IOPL")
      assert_true(origin.bits().length() == 2)
      assert_true(origin.bits()[0].ident() == "IOPLH")
      assert_true(origin.bits()[1].ident() == "IOPLL")
    }
    None => fail("missing IOPL alias origin")
  }
  assert_true(amd64.find_role(StackPointer).map(v => v.ident()) == Some("RSP"))
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "ZF"))
  assert_true(amd64.vars_with_role(SpecialRegister).any(v => v.ident() == "ZF"))
  assert_true(amd64.vars_with_role(ZeroFlag).any(v => v.ident() == "ZF"))
  assert_true(amd64.vars_with_role(CarryFlag).any(v => v.ident() == "CF"))
  assert_true(amd64.vars_with_role(OverflowFlag).any(v => v.ident() == "OF"))
  assert_true(amd64.vars_with_role(ParityFlag).any(v => v.ident() == "PF"))
  assert_true(amd64.vars_with_role(AliasRegister).any(v => v.ident() == "EAX"))
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "RFLAGS"))
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "IOPL"))
  match amd64.find_var("ZF") {
    Some(flag) => assert_true(amd64.has_roles([Status, ZeroFlag], flag))
    None => fail("missing ZF")
  }
  assert_true(amd64.regs(roles=[Status, ZeroFlag]).any(v => v.ident() == "ZF"))
  assert_true(
    !amd64.regs(roles=[Status], exclude=[ZeroFlag]).any(v => v.ident() == "ZF"),
  )
  assert_true(amd64.reg(StackPointer).map(v => v.ident()) == Some("RSP"))
  assert_true(
    amd64.reg(ProgramCounter, unique=true).map(v => v.ident()) == Some("RIP"),
  )
  assert_true(amd64.reg(ResultRegister, unique=true) is None)
  assert_true(amd64.role_aliases(ProgramCounter).contains("rip"))
  assert_true(!amd64.role_aliases(ProgramCounter).contains("pc"))
  let x86 = @core_theory.Target::x86()
  match x86.origin_of_name("AX") {
    Some(origin) => {
      assert_true(origin.source().map(v => v.ident()) == Some("EAX"))
      assert_true(origin.range() == Some((0, 15)))
    }
    None => fail("missing AX alias origin")
  }
  match x86.origin_of_name("IOPL") {
    Some(origin) => {
      assert_true(origin.bits().length() == 2)
      assert_true(origin.bits()[0].ident() == "IOPLH")
      assert_true(origin.bits()[1].ident() == "IOPLL")
    }
    None => fail("missing x86 IOPL alias origin")
  }
  match x86.find_var("ST0") {
    Some(float) =>
      assert_true(x86.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing ST0")
  }
  match x86.find_var("XMM0") {
    Some(vector) => {
      assert_true(x86.roles_of_var(vector).contains(VectorRegister))
      assert_true(x86.roles_of_var(vector).contains(FloatingRegister))
    }
    None => fail("missing XMM0")
  }
  let arm = @core_theory.Target::arm()
  assert_true(arm.find_role(ProgramCounter).map(v => v.ident()) == Some("PC"))
  assert_true(arm.vars_with_role(Argument).any(v => v.ident() == "R0"))
  assert_true(arm.role_aliases(ThumbMode).contains("r7"))
  assert_true(arm.role_aliases(ThumbMode).contains("lr"))
  match arm.find_var("R0") {
    Some(reg) => assert_true(arm.roles_of_var(reg).contains(ThumbMode))
    None => fail("missing R0")
  }
  match arm.find_var("R8") {
    Some(reg) => assert_true(!arm.roles_of_var(reg).contains(ThumbMode))
    None => fail("missing R8")
  }
  match arm.find_var("LR") {
    Some(link) => {
      assert_true(arm.roles_of_var(link).contains(LinkRegister))
      assert_true(arm.roles_of_var(link).contains(CallerSaved))
      assert_true(arm.roles_of_var(link).contains(ThumbMode))
    }
    None => fail("missing LR")
  }
  match arm.find_var("R4") {
    Some(saved) => {
      assert_true(arm.roles_of_var(saved).contains(IntegerRegister))
      assert_true(arm.roles_of_var(saved).contains(CalleeSaved))
    }
    None => fail("missing R4")
  }
  match arm.find_var("NF") {
    Some(flag) => assert_true(arm.roles_of_var(flag).contains(Status))
    None => fail("missing NF")
  }
  match arm.find_var("D31") {
    Some(float) => {
      assert_true(arm.roles_of_var(float).contains(FloatingRegister))
      assert_true(!arm.roles_of_var(float).contains(IntegerRegister))
      assert_true(float.sort().same(@core_theory.Sort::bitv(64)))
    }
    None => fail("missing ARM D31")
  }
  match arm.origin_of_name("SP") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "SP")
      assert_true(origin.source().map(v => v.ident()) == Some("R13"))
    }
    None => fail("missing ARM SP alias origin")
  }
  match arm.origin_of_name("CPSR") {
    Some(origin) => {
      assert_true(origin.source() is None)
      assert_true(
        origin.bits().map(v => v.ident()) == ["NF", "ZF", "CF", "VF", "QF"],
      )
    }
    None => fail("missing CPSR alias origin")
  }
  match @core_theory.Target::thumb().origin_of_name("LR") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "LR")
      assert_true(origin.source().map(v => v.ident()) == Some("R14"))
    }
    None => fail("missing Thumb LR alias origin")
  }
  let riscv = @core_theory.Target::riscv64()
  assert_true(riscv.role_aliases(ResultRegister).contains("x10"))
  assert_true(riscv.role_aliases(ResultRegister).contains("a0"))
  assert_true(riscv.role_aliases(Argument).contains("a7"))
  assert_true(!riscv.role_aliases(ResultRegister).contains("rax"))
  match riscv.find_var("F31") {
    Some(float) =>
      assert_true(riscv.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing F31")
  }
  match riscv.find_var("X2") {
    Some(sp) => {
      assert_true(riscv.roles_of_var(sp).contains(IntegerRegister))
      assert_true(riscv.roles_of_var(sp).contains(StackPointer))
    }
    None => fail("missing X2")
  }
  match riscv.find_var("X1") {
    Some(ra) => {
      assert_true(riscv.roles_of_var(ra).contains(LinkRegister))
      assert_true(riscv.roles_of_var(ra).contains(CallerSaved))
    }
    None => fail("missing X1")
  }
  match riscv.find_var("X3") {
    Some(tp) => assert_true(riscv.roles_of_var(tp).contains(ThreadPointer))
    None => fail("missing X3")
  }
  match riscv.find_var("X8") {
    Some(saved) => assert_true(riscv.roles_of_var(saved).contains(CalleeSaved))
    None => fail("missing X8")
  }
  match riscv.find_var("X0") {
    Some(zero) => {
      assert_true(riscv.roles_of_var(zero).contains(Constant))
      assert_true(riscv.roles_of_var(zero).contains(ZeroRegister))
      assert_true(!riscv.roles_of_var(zero).contains(ResultRegister))
    }
    None => fail("missing X0")
  }
  match riscv.find_var("sp") {
    Some(sp) => assert_true(riscv.roles_of_var(sp).contains(StackPointer))
    None => fail("missing sp alias")
  }
  match riscv.find_var("X10") {
    Some(arg) => {
      assert_true(riscv.roles_of_var(arg).contains(Argument))
      assert_true(riscv.roles_of_var(arg).contains(ResultRegister))
    }
    None => fail("missing X10")
  }
  match riscv.find_var("a0") {
    Some(arg) => {
      assert_true(riscv.roles_of_var(arg).contains(Argument))
      assert_true(riscv.roles_of_var(arg).contains(ResultRegister))
    }
    None => fail("missing a0 alias")
  }
  match riscv.origin_of_name("A0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "A0")
      assert_true(origin.source().map(v => v.ident()) == Some("X10"))
    }
    None => fail("missing A0 alias origin")
  }
  match riscv.origin_of_name("sp") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "SP")
      assert_true(origin.source().map(v => v.ident()) == Some("X2"))
    }
    None => fail("missing sp alias origin")
  }
  let mips64 = @core_theory.Target::mips64()
  match mips64.find_var("F31") {
    Some(float) =>
      assert_true(mips64.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing F31")
  }
  match mips64.find_var("ZERO") {
    Some(zero) => {
      assert_true(mips64.roles_of_var(zero).contains(IntegerRegister))
      assert_true(mips64.roles_of_var(zero).contains(Constant))
      assert_true(mips64.roles_of_var(zero).contains(ZeroRegister))
    }
    None => fail("missing ZERO")
  }
  match mips64.find_var("R31") {
    Some(link) => assert_true(mips64.roles_of_var(link).contains(LinkRegister))
    None => fail("missing R31")
  }
  match mips64.find_var("R26") {
    Some(reserved) =>
      assert_true(mips64.roles_of_var(reserved).contains(Reserved))
    None => fail("missing R26")
  }
  match mips64.find_var("F0") {
    Some(result) =>
      assert_true(mips64.roles_of_var(result).contains(ResultRegister))
    None => fail("missing F0")
  }
  match mips64.find_var("F1") {
    Some(arg) => assert_true(mips64.roles_of_var(arg).contains(Argument))
    None => fail("missing F1")
  }
  match mips64.origin_of_name("V0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "V0")
      assert_true(origin.source().map(v => v.ident()) == Some("R2"))
    }
    None => fail("missing V0 alias origin")
  }
  let sparcv9 = @core_theory.Target::sparcv9()
  match sparcv9.find_var("SP") {
    Some(sp) => {
      assert_true(sparcv9.roles_of_var(sp).contains(StackPointer))
      match sparcv9.origin_of_name("sp") {
        Some(origin) => {
          assert_true(origin.aliased().ident() == "SP")
          assert_true(origin.source().map(v => v.ident()) == Some("O6"))
        }
        None => fail("missing SPARC SP alias origin")
      }
    }
    None => fail("missing SPARC SP")
  }
  match sparcv9.find_var("FP") {
    Some(fp) => {
      assert_true(sparcv9.roles_of_var(fp).contains(FramePointer))
      match sparcv9.origin_of_name("fp") {
        Some(origin) => {
          assert_true(origin.aliased().ident() == "FP")
          assert_true(origin.source().map(v => v.ident()) == Some("I6"))
        }
        None => fail("missing SPARC FP alias origin")
      }
    }
    None => fail("missing SPARC FP")
  }
  match sparcv9.find_var("O6") {
    Some(sp) => assert_true(sparcv9.roles_of_var(sp).contains(StackPointer))
    None => fail("missing SPARC O6")
  }
  match sparcv9.find_var("I6") {
    Some(fp) => assert_true(sparcv9.roles_of_var(fp).contains(FramePointer))
    None => fail("missing SPARC I6")
  }
  match sparcv9.find_var("O7") {
    Some(link) => {
      assert_true(sparcv9.roles_of_var(link).contains(LinkRegister))
      assert_true(sparcv9.roles_of_var(link).contains(CallerSaved))
    }
    None => fail("missing SPARC O7")
  }
  match sparcv9.find_var("I7") {
    Some(link) => {
      assert_true(sparcv9.roles_of_var(link).contains(LinkRegister))
      assert_true(sparcv9.roles_of_var(link).contains(CalleeSaved))
    }
    None => fail("missing SPARC I7")
  }
  match sparcv9.find_var("L0") {
    Some(saved) =>
      assert_true(sparcv9.roles_of_var(saved).contains(CalleeSaved))
    None => fail("missing SPARC L0")
  }
  match sparcv9.find_var("O0") {
    Some(result) => {
      assert_true(sparcv9.roles_of_var(result).contains(Argument))
      assert_true(sparcv9.roles_of_var(result).contains(ResultRegister))
      assert_true(sparcv9.roles_of_var(result).contains(CallerSaved))
    }
    None => fail("missing SPARC O0")
  }
  match sparcv9.find_var("F31") {
    Some(float) => {
      assert_true(sparcv9.roles_of_var(float).contains(FloatingRegister))
      assert_true(!sparcv9.roles_of_var(float).contains(IntegerRegister))
      assert_true(float.sort().same(@core_theory.Sort::bitv(32)))
    }
    None => fail("missing SPARC F31")
  }
  let sparc = @core_theory.Target::sparc()
  match sparc.find_var("F0") {
    Some(float) =>
      assert_true(sparc.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing SPARC F0")
  }
  let ppc64 = @core_theory.Target::powerpc64()
  assert_true(ppc64.role_aliases(Argument).contains("r3"))
  assert_true(!ppc64.role_aliases(Argument).contains("rdi"))
  match ppc64.find_var("F31") {
    Some(float) =>
      assert_true(ppc64.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing F31")
  }
  match ppc64.find_var("FL") {
    Some(flag) => {
      assert_true(ppc64.roles_of_var(flag).contains(Status))
      assert_true(ppc64.roles_of_var(flag).contains(FloatingRegister))
    }
    None => fail("missing FL")
  }
  match ppc64.find_var("V31") {
    Some(vector) =>
      assert_true(ppc64.roles_of_var(vector).contains(VectorRegister))
    None => fail("missing V31")
  }
  match ppc64.find_var("LR") {
    Some(link) => assert_true(ppc64.roles_of_var(link).contains(LinkRegister))
    None => fail("missing LR")
  }
  match ppc64.find_var("ZERO") {
    Some(zero) => {
      assert_true(ppc64.roles_of_var(zero).contains(Constant))
      assert_true(ppc64.roles_of_var(zero).contains(ZeroRegister))
    }
    None => fail("missing ZERO")
  }
  match ppc64.find_var("R2") {
    Some(reserved) =>
      assert_true(ppc64.roles_of_var(reserved).contains(Reserved))
    None => fail("missing R2")
  }
  match ppc64.find_var("R14") {
    Some(saved) => assert_true(ppc64.roles_of_var(saved).contains(CalleeSaved))
    None => fail("missing R14")
  }
  match ppc64.find_var("CR0EQ") {
    Some(flag) => assert_true(ppc64.roles_of_var(flag).contains(Status))
    None => fail("missing CR0EQ")
  }
  match ppc64.find_var("R1") {
    Some(sp) => assert_true(ppc64.roles_of_var(sp).contains(StackPointer))
    None => fail("missing R1")
  }
  match ppc64.origin_of_name("SP") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "SP")
      assert_true(origin.source().map(v => v.ident()) == Some("R1"))
    }
    None => fail("missing PowerPC64 SP alias origin")
  }
  assert_true(ppc64.origin_of_name("ZERO") is None)
  match @core_theory.Target::powerpc().origin_of_name("sp") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "SP")
      assert_true(origin.source().map(v => v.ident()) == Some("R1"))
    }
    None => fail("missing PowerPC SP alias origin")
  }
  match ppc64.find_var("F1") {
    Some(arg) => assert_true(ppc64.roles_of_var(arg).contains(Argument))
    None => fail("missing F1")
  }
  match ppc64.find_var("F0") {
    Some(result) =>
      assert_true(ppc64.roles_of_var(result).contains(ResultRegister))
    None => fail("missing F0")
  }
  let aarch64 = @core_theory.Target::aarch64()
  match aarch64.find_var("R0") {
    Some(reg) => {
      assert_true(aarch64.roles_of_var(reg).contains(IntegerRegister))
      assert_true(aarch64.roles_of_var(reg).contains(Argument))
      assert_true(aarch64.roles_of_var(reg).contains(ResultRegister))
    }
    None => fail("missing R0")
  }
  match aarch64.find_var("X2") {
    Some(reg) => {
      assert_true(aarch64.roles_of_var(reg).contains(IntegerRegister))
      assert_true(!aarch64.roles_of_var(reg).contains(StackPointer))
    }
    None => fail("missing X2")
  }
  match aarch64.find_var("X30") {
    Some(link) => assert_true(aarch64.roles_of_var(link).contains(LinkRegister))
    None => fail("missing X30")
  }
  match aarch64.find_var("V0") {
    Some(vector) => {
      assert_true(aarch64.roles_of_var(vector).contains(VectorRegister))
      assert_true(aarch64.roles_of_var(vector).contains(Argument))
      assert_true(aarch64.roles_of_var(vector).contains(ResultRegister))
    }
    None => fail("missing V0")
  }
  match aarch64.find_var("D0") {
    Some(float) =>
      assert_true(aarch64.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing D0")
  }
  match aarch64.find_var("NF") {
    Some(flag) => assert_true(aarch64.roles_of_var(flag).contains(Status))
    None => fail("missing AArch64 NF")
  }
  match aarch64.find_var("XZR") {
    Some(zero) => {
      assert_true(aarch64.roles_of_var(zero).contains(Constant))
      assert_true(aarch64.roles_of_var(zero).contains(ZeroRegister))
    }
    None => fail("missing XZR")
  }
  match aarch64.origin_of_name("X0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "X0")
      assert_true(origin.source().map(v => v.ident()) == Some("R0"))
    }
    None => fail("missing X0 alias origin")
  }
  assert_true(aarch64.origin_of_name("R0") is None)
  match aarch64.origin_of_name("W0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "W0")
      assert_true(origin.source().map(v => v.ident()) == Some("R0"))
      assert_true(origin.range() == Some((0, 31)))
    }
    None => fail("missing W0 alias origin")
  }
  match aarch64.origin_of_name("D0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "D0")
      assert_true(origin.source().map(v => v.ident()) == Some("V0"))
      assert_true(origin.range() == Some((0, 63)))
    }
    None => fail("missing D0 alias origin")
  }
  match aarch64.origin_of_name("NZCV") {
    Some(origin) => {
      assert_true(origin.source() is None)
      assert_true(origin.bits().map(v => v.ident()) == ["NF", "ZF", "CF", "VF"])
    }
    None => fail("missing NZCV alias origin")
  }
  match aarch64.origin_of_name("FP") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "FP")
      assert_true(origin.source().map(v => v.ident()) == Some("X29"))
    }
    None => fail("missing FP alias origin")
  }
  match aarch64.origin_of_name("LR") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "LR")
      assert_true(origin.source().map(v => v.ident()) == Some("X30"))
    }
    None => fail("missing LR alias origin")
  }
  match aarch64.origin_of_name("WSP") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "WSP")
      assert_true(origin.source().map(v => v.ident()) == Some("SP"))
      assert_true(origin.range() == Some((0, 31)))
    }
    None => fail("missing WSP alias origin")
  }
  let systemz = @core_theory.Target::systemz()
  match systemz.find_var("R15") {
    Some(sp) => {
      assert_true(systemz.roles_of_var(sp).contains(IntegerRegister))
      assert_true(systemz.roles_of_var(sp).contains(StackPointer))
    }
    None => fail("missing R15")
  }
  match systemz.find_var("F15") {
    Some(float) =>
      assert_true(systemz.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing F15")
  }
  match systemz.find_var("R14") {
    Some(link) => assert_true(systemz.roles_of_var(link).contains(LinkRegister))
    None => fail("missing R14")
  }
  match @core_theory.Target::systemz9().origin_of_name("sp") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "SP")
      assert_true(origin.source().map(v => v.ident()) == Some("R15"))
    }
    None => fail("missing systemz SP alias origin")
  }
}

///|
test "labels carry symbolic entry points" {
  let weak = register_core_test_agent("possible-name-weak", Unreliable)
  let strong = register_core_test_agent("possible-name-strong", Reliable)
  let named = @core_theory.Label::for_name("main")
  assert_true(named.is_valid())
  assert_true(named.same(named))
  assert_true(named.compare(named) == 0)
  assert_true(named.name() == Some("main"))
  assert_true(named.same(@core_theory.Label::for_name("main")))
  assert_true(!named.same(@core_theory.Label::for_name("main", pkg="alt")))
  let addr = @types.Word::of_int(width=64, 0x400000)
  let label = @core_theory.Label::for_addr(addr)
    .with_alias("_start")
    .with_alias("_start")
    .with_alias("entry")
    .with_possible_name(weak, "sub_400000")
    .with_possible_name(strong, "_start")
  assert_true(!named.same(label))
  assert_true(named.compare(label) != 0)
  assert_true(label.same(@core_theory.Label::for_addr(addr)))
  assert_true(!label.same(@core_theory.Label::for_addr(addr, pkg="alt")))
  assert_true(label.addr() == Some(addr))
  assert_true(label.aliases() == ["_start", "entry"])
  assert_true(label.possible_name() == Some("_start"))
  assert_true(label.possible_name_opinions().entries().length() == 2)
  let ivec = @core_theory.Label::for_ivec(0x80, pkg="irq")
  assert_true(ivec.same(@core_theory.Label::for_ivec(0x80, pkg="irq")))
  assert_true(!ivec.same(@core_theory.Label::for_ivec(0x80)))
  assert_true(named.target().is_unknown())
  assert_true(!@core_theory.Label::null().is_valid())
}

///|
test "program metadata tracks source compiler and units" {
  let language = @core_theory.Language::of_string("C++")
  assert_true(language == Cxx)
  assert_true(language.equal(Cxx))
  assert_true(@core_theory.Language::unknown().is_unknown())
  assert_true(@core_theory.Language::of_string("unknown").is_unknown())
  assert_true(!language.is_unknown())
  assert_true(@core_theory.Language::c().compare(language) < 0)
  assert_true(language.compare(Cxx) == 0)
  let rust = @core_theory.Language::of_string("rust")
  let zig = @core_theory.Language::of_string("zig")
  assert_true(rust.compare(zig) != 0)
  inspect(language.to_string(), content="cxx")
  assert_true(@core_theory.Language::llvm_a32().to_string() == "llvm-armv7")
  assert_true(@core_theory.Language::llvm_t32().to_string() == "llvm-thumb")
  assert_true(@core_theory.Language::llvm_a64().to_string() == "llvm-aarch64")
  assert_true(@core_theory.Language::llvm_x86().to_string() == "llvm-x86")
  assert_true(@core_theory.Language::llvm_x86_64().to_string() == "llvm-x86_64")
  assert_true(@core_theory.Language::llvm_mips32().to_string() == "llvm-mips32")
  assert_true(
    @core_theory.Language::llvm_mips32le().to_string() == "llvm-mips32le",
  )
  assert_true(@core_theory.Language::llvm_mips64().to_string() == "llvm-mips64")
  assert_true(
    @core_theory.Language::llvm_mips64le().to_string() == "llvm-mips64le",
  )
  assert_true(
    @core_theory.Language::llvm_powerpc32().to_string() == "llvm-powerpc32",
  )
  assert_true(
    @core_theory.Language::llvm_powerpc64().to_string() == "llvm-powerpc64",
  )
  assert_true(
    @core_theory.Language::llvm_riscv32().to_string() == "llvm-riscv32",
  )
  assert_true(
    @core_theory.Language::llvm_riscv64().to_string() == "llvm-riscv64",
  )
  assert_true(
    @core_theory.Language::llvm_systemz().to_string() == "llvm-systemz",
  )
  assert_true(@core_theory.Language::pcode_x86().to_string() == "pcode-x86")
  assert_true(@core_theory.Language::pcode_arm().to_string() == "pcode-arm")
  assert_true(@core_theory.Language::pcode_mips().to_string() == "pcode-mips")
  assert_true(
    @core_theory.Language::pcode_powerpc().to_string() == "pcode-powerpc",
  )
  let source = @core_theory.Source::create(
    language~,
    code="int main() { return 0; }",
    file="main.cc",
  )
  let same_source = @core_theory.Source::create(
    language~,
    code="int main() { return 0; }",
    file="main.cc",
  )
  let newer_source = source.with_code("long main() { return 0; }")
  assert_true(source.language() == Cxx)
  assert_true(source.file() == Some("main.cc"))
  assert_true(source.equal(same_source))
  assert_true(source.compare(same_source) == 0)
  assert_true(!source.equal(newer_source))
  assert_true(source.compare(newer_source) != 0)
  let source_codec = @core_theory.Source::persistent()
  match source_codec.decode(source_codec.encode(source)) {
    Ok(decoded) => assert_true(decoded.equal(source))
    Err(reason) => fail(reason)
  }
  let compiler = @core_theory.Compiler::create(
    "clang",
    version=["17", "0"],
    options=["-O2"],
    specs={ "triple": "x86_64-unknown-linux", "arch": "x86-64" },
  )
  assert_true(compiler.version() == ["17", "0"])
  assert_true(compiler.options() == ["-O2"])
  assert_true(compiler.spec("triple") == Some("x86_64-unknown-linux"))
  assert_true(compiler.spec("arch") == Some("x86-64"))
  let same_compiler = @core_theory.Compiler::create(
    "clang",
    version=["17", "0"],
    options=["-O2"],
    specs={ "arch": "x86-64", "triple": "x86_64-unknown-linux" },
  )
  let optimized_compiler = @core_theory.Compiler::create(
    "clang",
    version=["17", "0"],
    options=["-O3"],
    specs={ "arch": "x86-64", "triple": "x86_64-unknown-linux" },
  )
  assert_true(compiler.equal(same_compiler))
  assert_true(compiler.compare(same_compiler) == 0)
  assert_true(compiler.compare(optimized_compiler) < 0)
  let compiler_codec = @core_theory.Compiler::persistent()
  match compiler_codec.decode(compiler_codec.encode(compiler)) {
    Ok(decoded) => assert_true(decoded.equal(compiler))
    Err(reason) => fail(reason)
  }
  inspect(
    compiler.to_string(),
    content="((name clang) (version (17 0)) (options (-O2)) (specs ((arch x86-64) (triple x86_64-unknown-linux))))",
  )
  let quoted_compiler = @core_theory.Compiler::create(
    "clang driver",
    options=["-DMSG=hello world", "\"quoted\""],
    specs={ "target triple": "x86_64 linux" },
  )
  inspect(
    quoted_compiler.to_string(),
    content="((name \"clang driver\") (version ()) (options (\"-DMSG=hello world\" \"\\\"quoted\\\"\")) (specs ((\"target triple\" \"x86_64 linux\"))))",
  )
  let target = @core_theory.Target::x86_64()
  let base = @types.Word::of_int(width=64, 0x400000)
  let upper = @types.Word::of_int(width=64, 0x4000ff)
  let real = @types.Word::of_int(width=64, 0x1234)
  let biased = @types.Word::of_int(width=64, 0x401234)
  let unit = @core_theory.ProgramUnit::for_file(
    "main.o",
    target~,
    bias=base,
    source~,
    compiler~,
  )
  let unit_codec = @core_theory.ProgramUnit::persistent()
  match unit_codec.decode(unit_codec.encode(unit)) {
    Ok(decoded) => assert_true(decoded.same(unit))
    Err(reason) => fail(reason)
  }
  assert_true(unit.path() == Some("main.o"))
  assert_true(unit.same(unit))
  assert_true(unit.compare(unit) == 0)
  assert_true(unit.same(@core_theory.ProgramUnit::for_file("main.o")))
  assert_true(!unit.same(@core_theory.ProgramUnit::for_file("other.o")))
  assert_true(unit.name() == "main.o")
  assert_true(unit.bias() == Some(base))
  assert_true(unit.to_real_addr(biased) == Ok(real))
  assert_true(unit.to_biased_addr(real) == Ok(biased))
  assert_true(
    unit.to_real_addr(@types.Word::of_int(width=32, 0x1234)) is Err(_),
  )
  assert_true(unit.target().matches("amd64"))
  assert_true(unit.source().map(item => item.code()) == Some(source.code()))
  assert_true(unit.compiler().map(item => item.name()) == Some("clang"))
  let region = @core_theory.ProgramUnit::for_region(lower=base, upper~, target~)
  match unit_codec.decode(unit_codec.encode(region)) {
    Ok(decoded) => assert_true(decoded.same(region))
    Err(reason) => fail(reason)
  }
  assert_true(!unit.same(region))
  assert_true(
    region.same(@core_theory.ProgramUnit::for_region(lower=base, upper~)),
  )
  assert_true(
    !region.same(
      @core_theory.ProgramUnit::for_region(lower=base, upper~, pkg="alt"),
    ),
  )
  assert_true(unit.compare(region) != 0)
  assert_true(region.lower() == Some(base))
  assert_true(region.upper() == Some(upper))
  assert_true(region.name() == "\{base.to_hex()}-\{upper.to_hex()}")
  assert_true(region.to_real_addr(base) == Ok(base))
  assert_true(region.to_biased_addr(base) == Ok(base))
  let label = @core_theory.Label::for_name("main")
    .with_unit(unit)
    .with_encoding(language)
    .with_subroutine()
  assert_true(label.unit().map(item => item.same(unit)) == Some(true))
  assert_true(label.encoding() == Some(Cxx))
  assert_true(label.target().matches("amd64"))
  assert_true(label.is_subroutine())
  let program = @core_theory.Program::create(units=[unit], labels=[label])
  let same_program = @core_theory.Program::create(
    units=[unit],
    labels=[label],
    target~,
  )
  let region_program = @core_theory.Program::create(units=[region], labels=[
    label,
  ])
  assert_true(program.equal(same_program))
  assert_true(program.compare(same_program) == 0)
  assert_true(!program.equal(region_program))
  assert_true(program.compare(region_program) != 0)
  assert_true(program.units().length() == 1)
  assert_true(program.labels().length() == 1)
  assert_true(program.target().map(item => item.matches("amd64")) == Some(true))
}

///|
test "program semantics stores values and instruction bytes" {
  assert_true(
    @core_theory.Semantics::empty()
    .value()
    .sort()
    .same(@core_theory.Sort::top()),
  )
  let value = @core_theory.Value::empty(@core_theory.Sort::bool()).with_fact(
    "kind", "lifted",
  )
  let same_value = @core_theory.Value::empty(@core_theory.Sort::bool()).with_fact(
    "kind", "lifted",
  )
  match value.resort(sort => sort.refine_bool()) {
    Some(refined) => {
      assert_true(refined.sort().same(@core_theory.Sort::bool()))
      assert_true(refined.fact("kind") == Some("lifted"))
    }
    None => fail("expected bool value refinement")
  }
  assert_true(value.resort(sort => sort.refine_bitv()) is None)
  assert_true(
    value.match_can(
      sort => sort.refine_bool(),
      refined => refined.fact("kind"),
      () => None,
    ) ==
    Some("lifted"),
  )
  assert_true(
    value.match_can(sort => sort.refine_bitv(), _ => Some("unexpected"), () => {
      None
    })
    is None,
  )
  let byte_value = @core_theory.Value::empty(@core_theory.Sort::bitv(8))
  assert_true(
    value.match_both(
      sort => sort.refine_bool(),
      byte_value,
      sort => sort.refine_bitv(),
      (left, right) => {
        left.sort().same(@core_theory.Sort::bool()) &&
        right.sort().bitv_size() == Some(8)
      },
      () => false,
    ),
  )
  assert_true(
    value.match_both(
      sort => sort.refine_bitv(),
      byte_value,
      sort => sort.refine_bitv(),
      (_, _) => true,
      () => false,
    ) ==
    false,
  )
  assert_true(value.equal(same_value))
  assert_true(value.compare(same_value) == 0)
  assert_true(!value.equal(value.with_fact("extra", "true")))
  let forgotten_value = value.forget()
  assert_true(forgotten_value.sort().same(@core_theory.Sort::bool()))
  assert_true(forgotten_value.fact("kind") == Some("lifted"))
  let semantics = @core_theory.Semantics::empty()
    .with_value(value)
    .with_code(b"\x90\xc3")
  let same_semantics = @core_theory.Semantics::empty()
    .with_value(same_value)
    .with_code(b"\x90\xc3")
  assert_value_persistent_round_trip(
    Some(@core_theory.Value::persistent()),
    value,
    "semantics value",
  )
  assert_semantics_persistent_round_trip(
    Some(@core_theory.Semantics::persistent()),
    semantics,
    "semantics",
  )
  assert_true(semantics.equal(same_semantics))
  assert_true(semantics.compare(same_semantics) == 0)
  assert_true(semantics.compare(semantics.with_code(b"\x90\xc4")) != 0)
  assert_true(semantics.value().fact("kind") == Some("lifted"))
  assert_true(semantics.code() == Some(b"\x90\xc3"))
  assert_true(semantics.code_hex() == Some("90c3"))
  let facts = @core_theory.SemanticsFacts::new()
  assert_value_persistent_round_trip(
    facts.value().slot().persistent(),
    value,
    "semantics fact value",
  )
  assert_persistent_round_trip(
    facts.code().slot().persistent(),
    Some(b"\x90\xc3"),
    "semantics instruction code",
  )
  assert_persistent_round_trip(
    facts.code().slot().persistent(),
    (None : Bytes?),
    "empty semantics instruction code",
  )
  match facts.for_semantics(semantics) {
    Ok(object) => {
      assert_true(facts.value().has(object))
      assert_true(facts.collect_value(object).fact("kind") == Some("lifted"))
      assert_true(facts.collect_code(object) == Some(b"\x90\xc3"))
      assert_true(facts.collect_semantics(object).code_hex() == Some("90c3"))
      assert_true(
        facts.provide_semantics(
          object,
          @core_theory.Semantics::empty().with_code(b"\x90\x90"),
        )
        is Err(_),
      )
    }
    Err(reason) => fail(reason)
  }
  let empty = facts.create()
  assert_true(!facts.code().has(empty))
  assert_true(facts.collect_semantics(empty).code() is None)
}

///|
test "program source and unit facts expose BAP-style Knowledge slots" {
  let source = @core_theory.Source::create(
    language=C,
    code="int main(void) { return 0; }",
    file="main.c",
  )
  let source_facts = @core_theory.SourceFacts::new()
  assert_persistent_round_trip(
    source_facts.language().slot().persistent(),
    C,
    "source language",
  )
  assert_persistent_round_trip(
    source_facts.code().slot().persistent(),
    "int main(void) { return 0; }",
    "source code",
  )
  assert_persistent_round_trip(
    source_facts.file().slot().persistent(),
    Some("main.c"),
    "source path",
  )
  assert_persistent_round_trip(
    source_facts.file().slot().persistent(),
    (None : String?),
    "empty source path",
  )
  match source_facts.for_source(source) {
    Ok(source_object) => {
      assert_true(source_facts.language().collect(source_object) == Some(C))
      assert_true(
        source_facts.code().require(source_object) ==
        Ok("int main(void) { return 0; }"),
      )
      assert_true(
        source_facts.file().collect(source_object) == Some(Some("main.c")),
      )
      let collected = source_facts.collect_source(source_object)
      assert_true(collected.language() == C)
      assert_true(collected.file() == Some("main.c"))
    }
    Err(reason) => fail(reason)
  }

  let compiler = @core_theory.Compiler::create(
    "clang",
    version=["18"],
    options=["-g"],
    specs={ "triple": "x86_64-linux-gnu" },
  )
  let base = @types.Word::of_int(width=64, 0x400000)
  let unit = @core_theory.ProgramUnit::for_file(
    "main.o",
    target=@core_theory.Target::x86_64(),
    bias=base,
    source~,
    compiler~,
  )
  let unit_facts = @core_theory.ProgramUnitFacts::new()
  assert_persistent_round_trip(
    unit_facts.path().slot().persistent(),
    Some("main.o"),
    "unit path",
  )
  assert_persistent_round_trip(
    unit_facts.bias().slot().persistent(),
    Some(base),
    "unit bias",
  )
  assert_persistent_round_trip(
    unit_facts.bias().slot().persistent(),
    (None : @types.Word?),
    "empty unit bias",
  )
  match unit_facts.target().slot().persistent() {
    Some(persistent) =>
      match
        persistent.decode(persistent.encode(@core_theory.Target::x86_64())) {
        Ok(decoded) => assert_true(decoded.matches("amd64"))
        Err(reason) => fail(reason)
      }
    None => fail("missing persistent codec for unit target")
  }
  assert_optional_source_persistent_round_trip(
    unit_facts.source().slot().persistent(),
    Some(source),
    "unit source",
  )
  assert_optional_source_persistent_round_trip(
    unit_facts.source().slot().persistent(),
    None,
    "empty unit source",
  )
  assert_optional_compiler_persistent_round_trip(
    unit_facts.compiler().slot().persistent(),
    Some(compiler),
    "unit compiler",
  )
  assert_optional_compiler_persistent_round_trip(
    unit_facts.compiler().slot().persistent(),
    None,
    "empty unit compiler",
  )
  let observed_paths : Ref[Int] = Ref(0)
  unit_facts
  .path()
  .observe((_, path) => {
    if path == Some("main.o") {
      observed_paths.val = observed_paths.val + 1
    }
    Ok(())
  })
  match unit_facts.for_unit(unit) {
    Ok(unit_object) => {
      assert_true(observed_paths.val == 1)
      assert_true(unit_facts.collect_path(unit_object) == Some("main.o"))
      assert_true(unit_facts.collect_bias(unit_object) == Some(base))
      assert_true(unit_facts.collect_target(unit_object).matches("amd64"))
      assert_true(
        unit_facts.collect_source(unit_object).map(item => item.file()) ==
        Some(Some("main.c")),
      )
      assert_true(
        unit_facts.collect_compiler(unit_object).map(item => item.name()) ==
        Some("clang"),
      )
      assert_true(
        unit_facts.provide_unit(
          unit_object,
          @core_theory.ProgramUnit::for_file("other.o"),
        )
        is Err(_),
      )
    }
    Err(reason) => fail(reason)
  }

  let unknown_object = unit_facts.create()
  assert_true(unit_facts.collect_target(unknown_object).is_unknown())
}

///|
test "program label facts expose BAP-style Knowledge slots" {
  let weak = register_core_test_agent("label-fact-weak", Unreliable)
  let strong = register_core_test_agent("label-fact-strong", Reliable)
  let source = @core_theory.Source::create(language=C, file="main.c")
  let unit = @core_theory.ProgramUnit::for_file(
    "main.o",
    target=@core_theory.Target::x86_64(),
    source~,
  )
  let addr = @types.Word::of_int(width=64, 0x401000)
  let label_semantics = @core_theory.Semantics::empty().with_code(b"\x55\xc3")
  let label = @core_theory.Label::for_addr(addr)
    .with_unit(unit)
    .with_alias("_main")
    .with_alias("_main")
    .with_alias("main")
    .with_encoding(C)
    .with_possible_name(weak, "sub_401000")
    .with_possible_name(strong, "main")
    .with_semantics(label_semantics)
    .with_subroutine()
  let facts = @core_theory.LabelFacts::new()
  assert_persistent_round_trip(
    facts.addr().slot().persistent(),
    Some(addr),
    "label addr",
  )
  assert_persistent_round_trip(
    facts.name().slot().persistent(),
    (None : String?),
    "label name",
  )
  assert_persistent_round_trip(
    facts.ivec().slot().persistent(),
    Some(0x80),
    "label ivec",
  )
  assert_persistent_round_trip(
    facts.encoding().slot().persistent(),
    C,
    "label encoding",
  )
  assert_persistent_round_trip(
    facts.aliases().slot().persistent(),
    ["_main", "main"],
    "label aliases",
  )
  assert_semantics_persistent_round_trip(
    facts.semantics().slot().persistent(),
    label_semantics,
    "label semantics",
  )
  assert_optional_unit_persistent_round_trip(
    facts.unit().slot().persistent(),
    Some(unit),
    "label unit",
  )
  assert_optional_unit_persistent_round_trip(
    facts.unit().slot().persistent(),
    None,
    "empty label unit",
  )
  assert_persistent_round_trip(
    facts.is_valid().slot().persistent(),
    Some(true),
    "label validity",
  )
  assert_persistent_round_trip(
    facts.is_subroutine().slot().persistent(),
    (None : Bool?),
    "empty label subroutine flag",
  )
  let alias_notifications : Ref[Int] = Ref(0)
  facts
  .aliases()
  .observe((_, aliases) => {
    if aliases.contains("main") {
      alias_notifications.val = alias_notifications.val + 1
    }
    Ok(())
  })
  match facts.for_label(label) {
    Ok(object) => {
      assert_true(alias_notifications.val == 1)
      assert_true(facts.collect_addr(object) == Some(addr))
      assert_true(facts.collect_name(object) is None)
      assert_true(facts.collect_possible_name(object) == Some("main"))
      assert_true(facts.collect_encoding(object) == Some(C))
      assert_true(
        facts.collect_semantics(object).map(s => s.code_hex()) ==
        Some(Some("55c3")),
      )
      assert_true(facts.collect_aliases(object) == ["_main", "main"])
      assert_true(
        facts.collect_unit(object).map(item => item.same(unit)) == Some(true),
      )
      assert_true(facts.collect_target(object).matches("amd64"))
      assert_true(facts.collect_is_valid(object) == Some(true))
      assert_true(facts.collect_is_subroutine(object) == Some(true))
      assert_true(
        facts.provide_label(
          object,
          @core_theory.Label::for_addr(@types.Word::of_int(width=64, 0x402000))
          .with_unit(unit)
          .with_subroutine(),
        )
        is Err(_),
      )
    }
    Err(reason) => fail(reason)
  }

  let empty = facts.create()
  assert_true(facts.collect_target(empty).is_unknown())
  assert_true(facts.collect_encoding(empty) is None)
  assert_true(facts.collect_semantics(empty) is None)
}

///|
test "core theory fact slots register public Knowledge documentation" {
  ignore(@core_theory.SourceFacts::new())
  ignore(@core_theory.ProgramUnitFacts::new())
  ignore(@core_theory.LabelFacts::new())
  ignore(@core_theory.SemanticsFacts::new())
  ignore(@core_theory.LabelFacts::new())

  let source_properties = documented_core_properties("core:unit-source")
  assert_true(source_properties.contains("core:source-language"))
  assert_true(source_properties.contains("core:source-code"))
  assert_true(source_properties.contains("core:source-path"))

  let unit_properties = documented_core_properties("core:unit")
  assert_true(unit_properties.contains("core:unit-path"))
  assert_true(unit_properties.contains("core:unit-bias"))
  assert_true(unit_properties.contains("core:unit-target"))
  assert_true(unit_properties.contains("core:unit-source"))
  assert_true(unit_properties.contains("core:unit-compiler"))

  let label_properties = documented_core_properties("core:program")
  assert_true(label_properties.contains("core:label-addr"))
  assert_true(label_properties.contains("core:label-name"))
  assert_true(label_properties.contains("core:possible-name"))
  assert_true(label_properties.contains("core:label-ivec"))
  assert_true(label_properties.contains("core:encoding"))
  assert_true(label_properties.contains("core:semantics"))
  assert_true(label_properties.contains("core:label-aliases"))
  assert_true(label_properties.contains("core:label-unit"))
  assert_true(label_properties.contains("core:is-valid"))
  assert_true(label_properties.contains("core:is-subroutine"))
  assert_true(documented_name_count(label_properties, "core:label-addr") == 1)

  let semantics_properties = documented_core_properties("core:semantics")
  assert_true(semantics_properties.contains("core:value"))
  assert_true(semantics_properties.contains("core:insn-code"))
}
