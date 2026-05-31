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
      assert_true(target.belongs(@core_theory.Target::arm()))
      assert_true(target.matches("thumbv7"))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("thumbv7eb") {
    Ok(target) => {
      assert_true(target.endianness() == BigEndian)
      assert_true(target.belongs(@core_theory.Target::armeb()))
      assert_true(target.matches("thumbeb"))
    }
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("ia-32") {
    Ok(target) => assert_true(target.matches("x86"))
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("x86_64h") {
    Ok(target) => assert_true(target.matches("x86_64"))
    Err(reason) => fail(reason)
  }
  match @core_theory.get_target("ppu") {
    Ok(target) => assert_true(target.matches("powerpc64"))
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
      assert_true(@core_theory.Target::mips().belongs(target))
      assert_true(@core_theory.Target::mipsel().belongs(target))
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
  match @core_theory.Target::get("powerpc-family") {
    Ok(target) => {
      assert_true(@core_theory.Target::powerpc().belongs(target))
      assert_true(@core_theory.Target::powerpcle().belongs(target))
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
  assert_true(linux_elf_matches[0].options().get("cpu") == Some("v2"))
  assert_true(linux_elf_matches[0].options().to_string() == "+cpu=v2")
  let cpu_v2 = @core_theory.Target::filter(
    parent~,
    system=Linux,
    options=@core_theory.TargetOptions::singleton("cpu", "v2"),
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
    Some(vector) =>
      assert_true(amd64.roles_of_var(vector).contains(VectorRegister))
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
      assert_true(origin.bits().length() == 32)
      assert_true(origin.bits().any(v => v.ident() == "CF"))
      assert_true(origin.bits().any(v => v.ident() == "ZF"))
      assert_true(origin.bits().any(v => v.ident() == "OF"))
    }
    None => fail("missing EFLAGS alias origin")
  }
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
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "RFLAGS"))
  assert_true(amd64.vars_with_role(Status).any(v => v.ident() == "IOPL"))
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
    Some(vector) =>
      assert_true(x86.roles_of_var(vector).contains(VectorRegister))
    None => fail("missing XMM0")
  }
  let arm = @core_theory.Target::arm()
  assert_true(arm.find_role(ProgramCounter).map(v => v.ident()) == Some("PC"))
  assert_true(arm.vars_with_role(Argument).any(v => v.ident() == "R0"))
  match arm.find_var("LR") {
    Some(link) => {
      assert_true(arm.roles_of_var(link).contains(LinkRegister))
      assert_true(arm.roles_of_var(link).contains(CallerSaved))
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
  let ppc64 = @core_theory.Target::powerpc64()
  assert_true(ppc64.role_aliases(Argument).contains("r3"))
  assert_true(!ppc64.role_aliases(Argument).contains("rdi"))
  match ppc64.find_var("F31") {
    Some(float) =>
      assert_true(ppc64.roles_of_var(float).contains(FloatingRegister))
    None => fail("missing F31")
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
  match aarch64.find_var("XZR") {
    Some(zero) => {
      assert_true(aarch64.roles_of_var(zero).contains(Constant))
      assert_true(aarch64.roles_of_var(zero).contains(ZeroRegister))
    }
    None => fail("missing XZR")
  }
  match aarch64.origin_of_name("W0") {
    Some(origin) => {
      assert_true(origin.aliased().ident() == "W0")
      assert_true(origin.source().map(v => v.ident()) == Some("X0"))
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
  assert_true(named.name() == Some("main"))
  let addr = @types.Word::of_int(width=64, 0x400000)
  let label = @core_theory.Label::for_addr(addr)
    .with_alias("_start")
    .with_alias("_start")
    .with_alias("entry")
    .with_possible_name(weak, "sub_400000")
    .with_possible_name(strong, "_start")
  assert_true(label.addr() == Some(addr))
  assert_true(label.aliases() == ["_start", "entry"])
  assert_true(label.possible_name() == Some("_start"))
  assert_true(label.possible_name_opinions().entries().length() == 2)
  assert_true(named.target().is_unknown())
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
  let real = @types.Word::of_int(width=64, 0x1234)
  let biased = @types.Word::of_int(width=64, 0x401234)
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
  assert_true(unit.to_real_addr(biased) == Ok(real))
  assert_true(unit.to_biased_addr(real) == Ok(biased))
  assert_true(
    unit.to_real_addr(@types.Word::of_int(width=32, 0x1234)) is Err(_),
  )
  assert_true(unit.target().matches("amd64"))
  assert_true(unit.source().map(item => item.code()) == Some(source.code()))
  assert_true(unit.compiler().map(item => item.name()) == Some("clang"))
  let region = @core_theory.ProgramUnit::for_region(lower=base, upper~, target~)
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
  assert_true(program.units().length() == 1)
  assert_true(program.labels().length() == 1)
  assert_true(program.target().map(item => item.matches("amd64")) == Some(true))
}

///|
test "program source and unit facts expose BAP-style Knowledge slots" {
  let source = @core_theory.Source::create(
    language=C,
    code="int main(void) { return 0; }",
    file="main.c",
  )
  let source_facts = @core_theory.SourceFacts::new()
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
  let label = @core_theory.Label::for_addr(addr)
    .with_unit(unit)
    .with_alias("_main")
    .with_alias("_main")
    .with_alias("main")
    .with_encoding(C)
    .with_possible_name(weak, "sub_401000")
    .with_possible_name(strong, "main")
    .with_subroutine()
  let facts = @core_theory.LabelFacts::new()
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
}
