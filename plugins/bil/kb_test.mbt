///|
fn reflect_bir(bil : Array[@types.Stmt]) -> String raise {
  let state = @knowledge.State::new()
  let ct = @bil.bil_theory().join(@bil.ir_theory())
  let eff = ct.reflect_bil(bil)(state)
  show_bir(eff.get(@bil.ir_graph_slot()).reify())
}

///|
test "the bap:bir theory builds the IR of reflected BIL" {
  let x = v("x")
  let c = bool_var("CF")
  let programs : Array[Array[@types.Stmt]] = [
    [Move(x, int(1)), Jmp(Int(w(32, 0x1000)))],
    [
      If(cond=c, yes=[Move(x, int(1))], no=[Move(x, int(2))]),
      Move(x, BinOp(Plus, Var(x), int(1))),
    ],
    [
      Move(x, int(0)),
      While(cond=c, body=[Move(x, BinOp(Plus, Var(x), int(1)))]),
      Move(x, int(5)),
    ],
    [
      Move(x, int(1)),
      @types.Stmt::encode(@types.Stmt::call(), "malloc"),
      Move(x, int(2)),
    ],
  ]
  // the theory builds the same blocks as the shared BIL lowering
  for p in programs {
    assert_eq(reflect_bir(p), show_bir(@bil.lift_bir(p)))
  }
  inspect(
    reflect_bir(programs[3]),
    content=(
      #|%0:
      #|  x:imm32 := 1:32u
      #|  call @malloc with return %1
      #|%1:
      #|  x:imm32 := 2:32u
      #|
    ),
  )
}

///|
test "the bap:jump-dests theory" {
  let state = @knowledge.State::new()
  let ct = @bil.bil_theory().join(@bil.brancher_theory())
  let c = bool_var("CF")
  let eff = ct.reflect_bil([
    If(cond=c, yes=[Jmp(Int(w(32, 0x10)))], no=[]),
    Jmp(Var(v("x"))),
  ])(state)
  let dests = match eff.get(@bil.dests_slot()) {
    None => "none"
    Some(ls) => ls.map(l => @bil.label_tid(l).to_string()).join(" ")
  }
  inspect(
    dests,
    content=(
      #|@0x00000010 %0
    ),
  )
}

///|
test "knowledge base rules lift instructions to semantics and IR" {
  @bil.install_rules(registry=registry())
  @bil.install_rules(registry=registry())
  let names = @core_theory.declared_theories().map(t => t.name.show())
  for n in ["bap:bil", "bap:bil-fp-emu", "bap:bir", "bap:jump-dests"] {
    assert_true(names.contains(n))
  }
  @types.select_passes([])
  let state = @knowledge.State::new()
  let obj = state.create(@core_theory.Program::cls())
  state.provide(
    @core_theory.Label::target_slot(),
    obj,
    @core_theory.Target::x86_64(),
  )
  state.provide(@bil.insn_slot(), obj, Some(insn("JMP")))
  inspect(
    show_bil(state.collect(@bil.code_slot(), obj)),
    content=(
      #|jmp 0x2000:64u
    ),
  )
  let sema = state.collect(@core_theory.Semantics::slot(), obj)
  inspect(
    show_bil(sema.bil()),
    content=(
      #|jmp 0x2000:64u
    ),
  )
  inspect(
    show_bir(sema.get(@bil.bir_slot())),
    content=(
      #|%0:
      #|  goto @0x0000000000002000
      #|
    ),
  )
  // relocations of the unit redirect the jumps (external names are
  // resolved in the knowledge base)
  let unit_ = @core_theory.ProgramUnit::for_file("a.out")
  @bil.provide_relocations(
    state,
    unit_,
    @bil.Relocations::create(exts=[(0x3000, "printf")]),
  )
  let reloc = state.create(@core_theory.Program::cls())
  state.provide(
    @core_theory.Label::target_slot(),
    reloc,
    @core_theory.Target::x86_64(),
  )
  state.provide(@core_theory.Label::unit_slot(), reloc, Some(unit_))
  state.provide(@bil.insn_slot(), reloc, Some(insn("LOADJMP")))
  inspect(
    show_bil(state.collect(@bil.code_slot(), reloc)),
    content=(
      #|R11:imm64 := 0x3000:64u
      #|special @attribute:(bap:call printf)
    ),
  )
  // objects without instructions have no semantics
  let other = state.create(@core_theory.Program::cls())
  assert_true(state.collect(@core_theory.Semantics::slot(), other).is_empty())
}

///|
test "lifted BIL is re-denoted with the desugared BIL theory" {
  let state = @knowledge.State::new()
  let x = v("x")
  let c = bool_var("CF")
  let bil : Array[@types.Stmt] = [
    Special("hint"),
    Move(x, BinOp(Plus, int(1), int(2))),
    If(cond=c, yes=[], no=[]),
    @types.Stmt::encode(@types.Stmt::intrinsic(), "llvm:CPUID"),
    CpuExn(3),
  ]
  inspect(
    show_bil(@bil.optimize(state, bil)),
    content=(
      #|x:imm32 := (1:32u + 2:32u)
      #|special @attribute:(bap:call intrinsic:llvm:CPUID)
      #|cpuexn 3
    ),
  )
}

///|
test "external names are resolved in the knowledge base" {
  let state = @knowledge.State::new()
  let rels = @bil.Relocations::create(exts=[(0x10, "puts")]).resolve_externals(
    state,
  )
  let bil : Array[@types.Stmt] = [Jmp(int(0))]
  inspect(
    show_bil(rels.fixup(bil, addr=0x10, size=1, width=32)),
    content=(
      #|special @attribute:(bap:call puts)
    ),
  )
}
