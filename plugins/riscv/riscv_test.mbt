///|
fn show_args(args : @c.Args?) -> String {
  guard args is Some({ return_, params, .. }) else { return "rejected" }
  let lines = []
  if return_ is Some((_, e)) {
    lines.push("return: \{e.to_string()}")
  }
  for p in params {
    lines.push("param: \{p.1.to_string()}")
  }
  lines.join("\n")
}

///|
fn proto(args : Array[@c.CType], return_~ : @c.CType = Void) -> @c.Proto {
  { return_, args: args.mapi((i, t) => ("x\{i}", t)), variadic: false, }
}

///|
test "the RISC-V ABI and semantics" {
  let registry = @mc.Registry::new()
  debug_inspect(@riscv.enable(registry~), content="Ok(())")
  debug_inspect(@riscv.enable(registry~), content="Ok(())")
  debug_inspect(
    @riscv.enable(backend="ghidra", registry~),
    content=(
      #|Err("the ghidra backend is not available")
    ),
  )
  guard @c.lookup(@core_theory.Target::riscv64()) is Some(abi) else {
    fail("no ABI")
  }
  let args = (abi.insert_args)(
    @types.Sub::create(name="f"),
    [],
    proto(
      [@c.CType::basic(SInt), @c.CType::basic(Double)],
      return_=@c.CType::basic(SLong),
    ),
  )
  inspect(
    show_args(args),
    content=(
      #|return: X10:imm64
      #|param: X10:imm64
      #|param: F10:imm64
    ),
  )
  // the Lisp semantics lifter
  let target = @core_theory.Target::riscv64()
  let insn = @mc.Insn::create(
    "ADDI",
    [@mc.Op::reg("X1"), @mc.Op::reg("X2"), Imm(3L)],
    addr=0x1000UL,
    size=4,
    encoding=@mc.default_encoding(target),
  )
  let lifted = registry.lift(@mc.Context::create(target), insn)
  inspect(
    lifted.bil().map(s => s.to_string()).join("\n"),
    content="X1:imm64 := (X2:imm64 + 3:64u)",
  )
}
