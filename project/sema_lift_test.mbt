///|
/// 0x9000: test rax, rax ; 0x9003: je 0x900a ; 0x9005: add rax, 1 ;
/// 0x9009: ret ; 0x900a: call 0x9100 ; 0x900f: ret
fn sema_lift_disassembly() -> @project.ProjectDisassemblyState raise {
  let bytes = b"\x48\x85\xc0" +
    b"\x74\x05" +
    b"\x48\x83\xc0\x01" +
    b"\xc3" +
    b"\xe8\xf1\x00\x00\x00" +
    b"\xc3"
  lift_ir_disassembly(
    "x86_64",
    bytes,
    start=0x9000UL,
    starts=[0x9000UL, 0x9005UL, 0x900aUL, 0x900fUL],
    edges=[
      @project.ProjectDisassemblyEdge::create(
        source=0x9003UL,
        target=0x900aUL,
        kind=CondEdge,
      ),
      @project.ProjectDisassemblyEdge::create(
        source=0x9003UL,
        target=0x9005UL,
        kind=FallEdge,
      ),
      @project.ProjectDisassemblyEdge::create(
        source=0x900aUL,
        target=0x900fUL,
        kind=FallEdge,
      ),
    ],
  )
}

///|
fn sema_lift_block(
  disassembly : @project.ProjectDisassemblyState,
  addr : UInt64,
) -> @project.ProjectDisassemblyBlock raise {
  for block in disassembly.blocks_with_instructions() {
    if block.addr() == addr {
      return block
    }
  }
  fail("no block at \{addr}")
}

///|
test "ProjectDisassemblyBlock::lift_ir lifts one block with its fall edge" {
  let disassembly = sema_lift_disassembly()
  let cfg = @project.ProjectDisassemblyCfg::of_disassembly(disassembly)
  let entry = sema_lift_block(disassembly, 0x9000UL)
  guard entry.lift_ir(target=@core_theory.Target::x86_64(), cfg~)
    is Ok((blks, errors)) else {
    fail("lifting failed")
  }
  assert_eq(errors, [])
  inspect(
    blks
    .map(blk => blk.jmps().map(jmp => jmp.jmp_to_string()).join("; "))
    .join("\n"),
    content="when ZF:imm1 goto @0x000000000000900a; goto @0x0000000000009005",
  )
}

///|
test "ProjectDisassemblySymtab::lift_ir builds the program of the symbol table" {
  let disassembly = sema_lift_disassembly()
  let cfg = @project.ProjectDisassemblyCfg::of_disassembly(disassembly)
  let blocks = disassembly.blocks_with_instructions()
  let caller = sema_lift_block(disassembly, 0x900aUL)
  let symtab = @project.ProjectDisassemblySymtab::create(functions=[
    @project.ProjectDisassemblyFunction::create(
      name="f",
      entry=sema_lift_block(disassembly, 0x9000UL),
      blocks~,
    ),
  ]).insert_call(caller, "g")
  guard symtab.lift_ir(target=@core_theory.Target::x86_64(), cfg~)
    is Ok((program, errors)) else {
    fail("lifting failed")
  }
  assert_eq(errors, [])
  // the call to 0x9100, an explicit call of `g`, is linked to `g`, which
  // gets a synthetic subroutine; the returns jump to the popped return
  // addresses
  inspect(
    program
    .subs()
    .map(sub => {
      let jmps = sub
        .blks()
        .map(blk => {
          blk.name() +
          blk.jmps().map(jmp => " " + jmp.jmp_to_string()).join(";")
        })
      ([sub.sub_name() + " synthetic=\{sub.is_synthetic()}"] + jmps).join("\n")
    })
    .join("\n"),
    content=(
      #|f synthetic=false
      #|@0x0000000000009000 when ZF:imm1 goto @0x000000000000900a; goto @0x0000000000009005
      #|@0x000000000000900a call @g with return @0x000000000000900f
      #|@0x000000000000900f call *%ret_addr:imm64 with noreturn
      #|@0x0000000000009005 call *%ret_addr:imm64 with noreturn
      #|g synthetic=true
    ),
  )
}
