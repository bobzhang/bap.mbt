///|
test "register is idempotent and orders the providers" {
  let registry = @mc.Registry::new()
  @x86.register(registry~)
  @x86.register(registry~)
  assert_eq(registry.names(), ["x86", "x86-legacy"])
}

///|
test "providers accept the x86 family with x86 encodings" {
  let ctx = (target : @core_theory.Target) => @mc.Context::create(target)
  assert_true(@x86.accepts(ctx(@core_theory.Target::x86_64())))
  assert_true(@x86.accepts(ctx(@core_theory.Target::x86())))
  assert_true(@x86.accepts(ctx(@core_theory.Target::i686())))
  // 16-bit targets and other families are not accepted
  assert_true(!@x86.accepts(ctx(@core_theory.Target::i86())))
  assert_true(!@x86.accepts(ctx(@core_theory.Target::arm())))
  // nor other encodings of x86 targets
  let pcode = @mc.Context::create(
    @core_theory.Target::x86_64(),
    encoding=@core_theory.Language::pcode_x86(),
  )
  assert_true(!@x86.accepts(pcode))
  assert_true(
    @x86.mode_of_context(ctx(@core_theory.Target::i686())) is Some(X86),
  )
}

///|
test "per-opcode lifters override the legacy lifter" {
  let registry = @mc.Registry::new()
  @x86.register(registry~)
  let ctx = @mc.Context::create(@core_theory.Target::x86_64())
  // BTS32ri8 is lifted by the per-opcode provider (the legacy decoder would
  // lift it as a plain BT)
  let insn = mc_insn("x86_64", b"\x0f\xba\xe8\x03")
  let bil = registry.lift(ctx, insn).bil
  assert_true(bil.length() > 6)
  // ADD32rr falls through to the legacy provider
  let insn = mc_insn("x86_64", b"\x01\xd8")
  let lifted = registry.lift(ctx, insn)
  assert_eq(lifted.bil, @x86.lift_legacy(X8664, b"\x01\xd8", addr=0x400000))
  // instructions neither provider models are Unsupported
  let insn = mc_insn("x86_64", b"\xf8")
  let r = try registry.lift(ctx, insn) catch {
    e => e.is_unsupported()
  } noraise {
    _ => false
  }
  assert_true(r)
}

///|
test "opting in from the project lifter" {
  let registry = @mc.Registry::new()
  @x86.register(registry~)
  let insn = basic_decode("x86_64", b"\x0f\xc1\xd8")
  // with the x86 providers
  let ours = match insn.lift(target=@core_theory.Target::x86_64(), registry~) {
    Ok(lifted) => lifted.bil
    Err(e) => fail(e)
  }
  assert_eq(ours, @x86.lift_legacy(X8664, b"\x0f\xc1\xd8", addr=0x400000))
  // an empty registry falls back to the Basic lifter
  let basic = match
    insn.lift(
      target=@core_theory.Target::x86_64(),
      registry=@mc.Registry::new(),
    ) {
    Ok(lifted) => lifted.bil
    Err(e) => fail(e)
  }
  assert_true(basic != ours)
  // clc is not modeled by the ported lifters: Unsupported falls back to
  // the Basic lifter
  let clc = basic_decode("x86_64", b"\xf8")
  assert_true(
    clc.lift(target=@core_theory.Target::x86_64(), registry~) is Ok(_),
  )
}
