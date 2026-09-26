///|
test "op accessors" {
  let r = @mc.Op::reg("R1", code=3)
  assert_eq(r.reg_name(), Some("R1"))
  assert_eq(r.imm_value(), None)
  assert_eq(@mc.Imm(16).imm_value(), Some(16L))
  assert_eq(@mc.Imm(16).to_string(), "0x10")
}

///|
test "insn accessors" {
  let insn = @mc.Insn::create(
    "NOP",
    [],
    addr=0x1000,
    size=4,
    code=42,
    encoding=@core_theory.Language::llvm_mips32(),
    kinds=[MayAffectControlFlow],
    raw=b"\x00\x00\x00\x00",
  )
  assert_eq(insn.next_addr(), 0x1004UL)
  assert_eq(insn.op(0), None)
  assert_eq(insn.name(), "NOP")
  assert_eq(insn.code(), 42)
  assert_eq(insn.size(), 4)
  assert_eq(insn.addr(), 0x1000UL)
  assert_eq(insn.encoding(), @core_theory.Language::llvm_mips32())
  assert_true(insn.has_kind(MayAffectControlFlow))
  assert_true(!insn.has_kind(Call))
  assert_eq(insn.raw().length(), 4)
  let bare = @mc.Insn::create("NOP", [@mc.Op::reg("R0")], addr=0, size=2)
  assert_true(bare.encoding().is_unknown())
  assert_eq(bare.raw().length(), 0)
  assert_eq(bare.ops().length(), 1)
}

///|
test "default encodings" {
  let enc = (t : @core_theory.Target) => @mc.default_encoding(t).to_string()
  assert_eq(enc(@core_theory.Target::mips()), "llvm-mips32")
  assert_eq(enc(@core_theory.Target::mipsel()), "llvm-mips32le")
  assert_eq(enc(@core_theory.Target::mips64()), "llvm-mips64")
  assert_eq(enc(@core_theory.Target::mips64el()), "llvm-mips64le")
  assert_eq(enc(@core_theory.Target::powerpc()), "llvm-powerpc32")
  assert_eq(enc(@core_theory.Target::powerpc64le()), "llvm-powerpc64")
  assert_eq(enc(@core_theory.Target::arm()), "llvm-armv7")
  assert_eq(enc(@core_theory.Target::thumb()), "llvm-thumb")
  assert_eq(enc(@core_theory.Target::aarch64()), "llvm-aarch64")
  assert_eq(enc(@core_theory.Target::systemz()), "llvm-systemz")
  assert_eq(enc(@core_theory.Target::x86_64()), "llvm-x86_64")
  assert_eq(enc(@core_theory.Target::i386()), "llvm-x86")
  assert_true(@mc.default_encoding(@core_theory.Target::unknown()).is_unknown())
  let ctx = @mc.Context::create(
    @core_theory.Target::arm(),
    encoding=@core_theory.Language::llvm_t32(),
  )
  assert_true(ctx.encoded_as(@core_theory.Language::llvm_t32()))
  assert_true(ctx.belongs(@core_theory.Target::arm_family()))
  // an unknown encoding is replaced by the target default
  let ctx = @mc.Context::create(
    @core_theory.Target::arm(),
    encoding=@core_theory.Language::unknown(),
  )
  assert_true(ctx.encoded_as(@core_theory.Language::llvm_a32()))
}

///|
fn nop_provider(name : String, tag : String) -> @mc.Provider {
  @mc.Provider::create(name, accepts=_ => true, lift=(ctx, insn) => {
    if insn.name == "NOP" {
      @mc.Lifted::of_bil([@types.Stmt::special(tag)])
    } else {
      raise @mc.Unsupported(opcode=insn.name, target=ctx.target.to_string())
    }
  })
}

///|
test "registry replaces providers by name" {
  let registry = @mc.Registry::new()
  registry.register(nop_provider("a", "a1"))
  registry.register(nop_provider("b", "b1"))
  registry.register(nop_provider("a", "a2"))
  registry.register(nop_provider("a", "a3"))
  assert_eq(registry.names(), ["a", "b"])
  let ctx = @mc.Context::create(@core_theory.Target::mips())
  let insn = @mc.Insn::create("NOP", [], addr=0, size=4)
  assert_eq(registry.lift(ctx, insn).bil, [@types.Stmt::special("a3")])
  assert_true(registry.find("b") is Some(_))
  assert_true(registry.unregister("a"))
  assert_true(!registry.unregister("a"))
  assert_eq(registry.lift(ctx, insn).bil, [@types.Stmt::special("b1")])
}

///|
test "registry falls through unsupported providers" {
  let registry = @mc.Registry::new()
  let ctx = @mc.Context::create(@core_theory.Target::mips())
  // first provider only models FOO, second only NOP, third rejects the context
  registry.register(
    @mc.Provider::create("foo", accepts=_ => true, lift=(ctx, insn) => {
      if insn.name == "FOO" {
        @mc.Lifted::of_bil([])
      } else {
        raise @mc.Unsupported(opcode=insn.name, target=ctx.target.to_string())
      }
    }),
  )
  registry.register(nop_provider("nop", "nop"))
  registry.register(
    @mc.Provider::create("never", accepts=_ => false, lift=(_, _) => {
      @mc.Lifted::of_bil([@types.Stmt::special("never")])
    }),
  )
  assert_eq(registry.accepting(ctx).map(p => p.name()), ["foo", "nop"])
  // an empty program is a successful result, distinct from Unsupported
  let foo = @mc.Insn::create("FOO", [], addr=0, size=4)
  assert_eq(registry.lift(ctx, foo), @mc.Lifted::of_bil([]))
  let nop = @mc.Insn::create("NOP", [], addr=0, size=4)
  assert_eq(registry.lift(ctx, nop).bil, [@types.Stmt::special("nop")])
  let bar = @mc.Insn::create("BAR", [], addr=0, size=4)
  try registry.lift(ctx, bar) catch {
    err => {
      assert_true(err is Unsupported(opcode="BAR", ..))
      assert_true(err.is_unsupported())
    }
  } noraise {
    _ => fail("expected unsupported instruction")
  }
  // no provider at all
  try @mc.Registry::new().lift(ctx, nop) catch {
    err => assert_true(err is Unsupported(opcode="NOP", ..))
  } noraise {
    _ => fail("expected unsupported instruction")
  }
}

///|
test "registry stops at the first non-unsupported error" {
  let registry = @mc.Registry::new()
  let ctx = @mc.Context::create(@core_theory.Target::mips())
  registry.register(
    @mc.Provider::create("bad", accepts=_ => true, lift=(_, insn) => {
      raise @mc.BadOperands(opcode=insn.name, detail="no operands")
    }),
  )
  registry.register(nop_provider("nop", "nop"))
  let nop = @mc.Insn::create("NOP", [], addr=0, size=4)
  try registry.lift(ctx, nop) catch {
    err =>
      assert_eq(err.message(), "bad operands for instruction: NOP: no operands")
  } noraise {
    _ => fail("expected bad operands")
  }
}

///|
test "registry validates lifted programs" {
  let registry = @mc.Registry::new()
  let ctx = @mc.Context::create(@core_theory.Target::mips())
  let r32 = @types.Var::new(name="R", typ=Imm(32))
  let ill_typed = [
    @types.Stmt::Move(r32, @types.Exp::int(@types.Word::of_int(1, width=8))),
  ]
  registry.register(
    @mc.Provider::create("ill", accepts=_ => true, lift=(_, _) => {
      @mc.Lifted::of_bil(ill_typed)
    }),
  )
  let insn = @mc.Insn::create("MOV", [], addr=0, size=4)
  try registry.lift(ctx, insn) catch {
    err => assert_true(err is IllTyped(opcode="MOV", ..))
  } noraise {
    _ => fail("expected ill-typed program")
  }
  assert_eq(registry.lift(ctx, insn, validate=false).bil, ill_typed)
}

///|
test "lifted results carry delay and destination encoding" {
  let lifted = @mc.Lifted::create(
    [],
    delay=1,
    dest_encoding=@core_theory.Language::llvm_a32(),
  )
  assert_eq(lifted.delay(), 1)
  assert_eq(lifted.dest_encoding(), Some(@core_theory.Language::llvm_a32()))
  assert_eq(@mc.Lifted::of_bil([]).delay(), 0)
  assert_eq(@mc.Lifted::of_bil([]).dest_encoding(), None)
  assert_eq(
    @mc.Unsupported(opcode="X", target="").message(),
    "unsupported instruction: X",
  )
}
