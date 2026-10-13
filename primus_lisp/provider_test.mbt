// The `mc` provider of the Lisp semantics and evaluation of the lifted BIL.

///|
fn w(width : Int32, n : Int32) -> @types.Word {
  try! @types.Word::of_int(width~, n)
}

///|
test "lisp semantics provider in a registry" {
  let registry = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry~)
  @primus_lisp.register_semantics_providers(registry~)
  inspect(
    registry.names().join(","),
    content="primus-lisp-riscv,primus-lisp-arm,primus-lisp-powerpc,primus-lisp-x86",
  )
  let target = @core_theory.Target::riscv64()
  let ctx = @mc.Context::create(target)
  let insn = @mc.Insn::create(
    "ADDI",
    [@mc.Op::reg("X1"), @mc.Op::reg("X2"), Imm(-3L)],
    addr=0x1000UL,
    size=4,
    encoding=@mc.default_encoding(target),
  )
  let lifted = registry.lift(ctx, insn)
  // evaluate the lifted code
  let state = @types.BilState::new().set("X2", BilWord(w(64, 10)))
  let state = @types.exec_stmts(lifted.bil(), state~).unwrap()
  inspect(state.get_word("X1").unwrap().to_int(), content="7")
  // an instruction without a Lisp definition is unsupported
  let insn = @mc.Insn::create(
    "NOSUCH",
    [],
    addr=0x1000UL,
    size=4,
    encoding=@mc.default_encoding(target),
  )
  let r = try registry.lift(ctx, insn) catch {
    e => e.is_unsupported()
  } noraise {
    _ => false
  }
  inspect(r, content="true")
}

///|
test "evaluate lifted aarch64 flags" {
  let lifter = @primus_lisp.load_semantics(@core_theory.Target::aarch64(), [
    "semantics/arm",
  ])
  let bil = lifter
    .lift(@knowledge.Name::create("SUBSXri", pkg="llvm-aarch64"), [
      Reg("X0"),
      Reg("X1"),
      Imm(1),
      Imm(0),
    ])
    .unwrap()
  let run = (x1 : Int32) => {
    let state = @types.BilState::new().set("X1", BilWord(w(64, x1)))
    let s = @types.exec_stmts(bil, state~).unwrap()
    let get = (n : String) => s.get_word(n).unwrap().to_string()
    "X0=\{get("X0")} ZF=\{get("ZF")} NF=\{get("NF")} CF=\{get("CF")}"
  }
  inspect(
    run(1),
    content=(
      #|X0=0:64u ZF=1:1u NF=0:1u CF=1:1u
    ),
  )
  inspect(
    run(0),
    content=(
      #|X0=0xFFFFFFFFFFFFFFFF:64u ZF=0:1u NF=1:1u CF=0:1u
    ),
  )
}
