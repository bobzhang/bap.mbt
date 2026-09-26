///|
fn reloc_word(x : UInt64) -> @types.Exp {
  @types.Exp::int(try! @types.Word::of_uint64(width=64, x))
}

///|
fn reloc_bil(bil : Array[@types.Stmt]) -> String {
  bil.map(s => s.to_string()).join("; ")
}

///|
test "relocation fixups redirect the jumps of relocated instructions" {
  let rels = @project.ProjectRelocations::create(
    rels=[(0x7UL, 0x0UL)],
    exts=[(0x18UL, "ext@GLIBC_2.2.5")],
    stubs=[(0x100UL, 0x10)],
  )
  // a call through a placeholder: the Basic hint keeps classifying the
  // jump, which goes to the relocation target
  let call = [
    @types.Stmt::encode(@types.Stmt::call(), "0xb"),
    @types.Stmt::jmp(reloc_word(0xb)),
  ]
  inspect(
    reloc_bil(rels.fixup(call, addr=0x6, size=5, width=64)),
    content=(
      #|special @attribute:(bap:call 0x0); jmp 0:64u
    ),
  )
  // a call of an external symbol: the jump (with its hint) becomes a call
  // of the symbol, without its version
  inspect(
    reloc_bil(rels.fixup(call, addr=0x17, size=5, width=64)),
    content=(
      #|special @attribute:(bap:call ext)
    ),
  )
  // a direct jump to a referenced address is not a reference
  let stub = [@types.Stmt::jmp(reloc_word(0x18))]
  let rels = @project.ProjectRelocations::create(exts=[(0x18UL, "ext")], stubs=[
    (0x100UL, 0x10),
  ])
  inspect(
    reloc_bil(rels.fixup(stub, addr=0x104, size=6, width=64)),
    content=(
      #|jmp 0x18:64u
    ),
  )
  // a jump through a loaded constant address that is referenced, in a
  // stub, calls the external symbol
  let load = [
    @types.Stmt::jmp(
      @types.Exp::load(
        mem=@types.Exp::var_exp(
          @types.Var::create("mem", @types.ValueType::mem(Addr64, R8)),
        ),
        addr=reloc_word(0x18),
        LittleEndian,
        R64,
      ),
    ),
  ]
  inspect(
    reloc_bil(rels.fixup(load, addr=0x104, size=6, width=64)),
    content=(
      #|special @attribute:(bap:call ext:external)
    ),
  )
  // code that is not affected by relocations is kept
  inspect(
    reloc_bil(rels.fixup(call, addr=0x30, size=5, width=64)),
    content=(
      #|special @attribute:(bap:call 0xb); jmp 0xB:64u
    ),
  )
  // conditional jumps are redirected in place
  let rels = @project.ProjectRelocations::create(rels=[(0x2UL, 0x40UL)])
  let cond = [
    @types.Stmt::if_(
      @types.Exp::var_exp(@types.Var::create("ZF", Imm(1))),
      [@types.Stmt::jmp(reloc_word(0x0))],
      [],
    ),
  ]
  guard rels.fixup(cond, addr=0x0, size=4, width=64)
    is [If(yes=[Jmp(Int(dst))], no=[], ..)] else {
    fail("expected a conditional jump")
  }
  assert_eq(dst.to_uint64(), 0x40UL)
}
