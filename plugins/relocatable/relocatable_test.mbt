///|
fn spec() -> @ogre.Doc raise {
  let ext = @image.Scheme::external_reference()
  let rel = @image.Scheme::relocation()
  @ogre.Doc::empty()
  .put(ext, (0x10L, "puts@GLIBC_2.2.5"))
  .put(ext, (0x20L, "a"))
  .put(ext, (0x20L, "b"))
  .put(ext, (0x50L, "free"))
  .put(rel, (0x10L, 0x2000L))
  .put(rel, (0x30L, 0x1000L))
  .put(rel, (0x40L, 0x1L))
  .put(rel, (0x40L, 0x2L))
}

///|
fn word64(value : Int32) -> @types.Word raise {
  @types.Word::of_int(width=64, value)
}

///|
test "references merge names and relocations" {
  let refs = @relocatable.References::create(
    @core_theory.Target::x86_64(),
    spec(),
  )
  debug_inspect(
    refs.to_array(),
    content=(
      #|[
      #|  (16, Ref(Addr(8192))),
      #|  (32, Bad),
      #|  (48, Ref(Addr(4096))),
      #|  (64, Bad),
      #|  (80, Ref(Name("free"))),
      #|]
    ),
  )
  debug_inspect(refs.lookup(0x50), content="Some(Name(\"free\"))")
  debug_inspect(refs.lookup(0x20), content="None")
  debug_inspect(refs.search(word64(0x30)), content="Some(Addr(4096))")
  inspect(@relocatable.chop_version("puts@GLIBC_2.2.5"), content="puts")
  inspect(@relocatable.chop_version("@odd"), content="@odd")
}

///|
test "references in BIL" {
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8))
  let load = @types.Exp::Load(
    mem=@types.Exp::var_exp(mem),
    addr=@types.Exp::int(word64(0x3000)),
    endian=LittleEndian,
    typ=Imm(64),
  )
  let bil = [
    @types.Stmt::jmp(load),
    @types.Stmt::jmp(@types.Exp::int(word64(0x4000))),
    @types.Stmt::move_stmt(@types.Var::new(name="RAX", typ=Imm(64)), load),
    @types.Stmt::encode(@types.Stmt::call(), "malloc:external"),
    @types.Stmt::encode(@types.Stmt::call(), "intrinsic:trap"),
    @types.Stmt::cpuexn(3),
  ]
  debug_inspect(
    @relocatable.find_references(bil),
    content=(
      #|[Addr(12288), Addr(16384), Addr(12288), Name("malloc")]
    ),
  )
}

///|
test "PLT sizes by target family" {
  debug_inspect(
    [
      @core_theory.Target::x86_64(),
      @core_theory.Target::arm(),
      @core_theory.Target::powerpc(),
      @core_theory.Target::mips(),
      @core_theory.Target::unknown(),
    ].map(@relocatable.plt_size),
    content="[Some(1), Some(4), Some(4), None, None]",
  )
}

///|
test "stubs are resolved through the PLT code" {
  let refs = @relocatable.References::create(
    @core_theory.Target::x86_64(),
    spec(),
  )
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8))
  let lift = (addr : UInt64) => {
    if addr == 0x400 {
      let load = @types.Exp::Load(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::int(@types.Word::of_int(width=64, 0x50)) catch {
          _ => @types.Exp::var_exp(mem)
        },
        endian=LittleEndian,
        typ=Imm(64),
      )
      Some(@relocatable.LiftedInsn::{
        bil: [@types.Stmt::jmp(load)],
        max_addr: 0x405,
      })
    } else {
      None
    }
  }
  let target = @core_theory.Target::x86_64()
  debug_inspect(
    [0x10UL, 0x400UL, 0x500UL].map(addr => {
      @relocatable.resolve_stub(refs, target, addr, lift)
    }),
    content=(
      #|[None, Some("free"), None]
    ),
  )
  let symbolizer = @relocatable.symbolizer(
    refs,
    target,
    is_stub=addr => addr == 0x400 || addr == 0x50,
    lift~,
  )
  debug_inspect(
    [symbolizer.run(0x400), symbolizer.run(0x50), symbolizer.run(0x10)],
    content=(
      #|[Some("free"), Some("free"), None]
    ),
  )
}

///|
test "constant jumps are followed when collecting instructions" {
  let lift = (addr : UInt64) => {
    match addr {
      0x100 => {
        let target = @types.Exp::int(@types.Word::of_int(width=64, 0x200)) catch {
          _ => @types.Exp::unknown("x", Imm(64))
        }
        Some(@relocatable.LiftedInsn::{
          bil: [@types.Stmt::jmp(target)],
          max_addr: 0x101,
        })
      }
      0x200 => Some({ bil: [@types.Stmt::special("second")], max_addr: 0x203, })
      0x204 => Some({ bil: [@types.Stmt::special("third")], max_addr: 0x207, })
      _ => None
    }
  }
  debug_inspect(
    @relocatable.collect_insns(3, 0x100, lift).map(s => s.to_string()),
    content=(
      #|["jmp 0x200:64u", "special second", "special third"]
    ),
  )
  debug_inspect(
    @relocatable.collect_insns(1, 0x100, lift).length(),
    content="1",
  )
}

///|
test "MIPS external references are function starts" {
  let refs = @relocatable.References::create(
    @core_theory.Target::mips(),
    spec(),
  )
  debug_inspect(
    @relocatable.mips_roots(refs, @core_theory.Target::mips()),
    content="[16, 48, 80]",
  )
  debug_inspect(
    @relocatable.mips_roots(refs, @core_theory.Target::x86_64()),
    content="[]",
  )
}

///|
test "the pass renames stub subroutines" {
  let image = @image.Image::create(
    entry=0,
    endian=LittleEndian,
    target=@core_theory.Target::x86_64(),
    spec=spec(),
  )
  let stub = @types.Sub::create(name="sub_50")
    .with_stub()
    .set_attr(@types.Attr::address(word64(0x50)))
  let plain = @types.Sub::create(name="sub_60").set_attr(
    @types.Attr::address(word64(0x60)),
  )
  let project = @project.Project::from_image(
    image,
    target=@core_theory.Target::x86_64(),
  ).with_program(@types.Program::create(subs=[stub, plain]))
  debug_inspect(@relocatable.register(), content="Ok(true)")
  debug_inspect(@relocatable.register(), content="Ok(false)")
  guard project.run_pass("relocatable") is Ok(result) else {
    fail("relocatable failed")
  }
  debug_inspect(
    result.program().subs().map(s => s.sub_name()),
    content=(
      #|["free", "sub_60"]
    ),
  )
  @relocatable.register_sources(image)
  guard @project.find_symbolizer_source("plt-symbolizer") is Some(_) else {
    fail("no symbolizer source")
  }
}
