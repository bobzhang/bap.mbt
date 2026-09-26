///|
fn block(
  start : UInt64,
  bytes : Bytes,
) -> @project.ProjectDisassemblyBlock raise {
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  match
    @project.ProjectDisassemblyBlock::create(memory, [
      @project.ProjectDisassemblyInstruction::create(memory, assembly="nop"),
    ]) {
    Ok(block) => block
    Err(reason) => fail(reason)
  }
}

///|
test "functions are dumped block by block in reverse postorder" {
  let entry = block(0x8000UL, b"\x01\x02")
  let body = block(0x8010UL, b"\x03\x04\x05\x06")
  let tail = block(0x8020UL, b"\x07")
  let helper = block(0x9000UL, b"\x08")
  let main = @project.ProjectDisassemblyFunction::create(name="main", entry~, blocks=[
    entry, body, tail,
  ])
  let odd = @project.ProjectDisassemblyFunction::create(
    name="odd name",
    entry=helper,
  )
  let symtab = @project.ProjectDisassemblySymtab::empty()
    .add_symbol(main)
    .add_symbol(odd)
  let cfg = @project.ProjectDisassemblyCfg::create(nodes=[entry, body, tail], edges=[
    @project.ProjectDisassemblyCfgEdge::create(src=entry, dst=tail),
    @project.ProjectDisassemblyCfgEdge::create(src=tail, dst=body),
  ])
  inspect(
    @dump_symbols.render_symtab(symtab, cfg),
    content=(
      #|(main 32768 32769)
      #|(main 32800 32800)
      #|(main 32784 32787)
      #|("odd name" 36864 36864)
      #|
    ),
  )
}

///|
test "sexp atoms are quoted when necessary" {
  debug_inspect(
    ["plain", "", "a(b", "tab\there", "q\"uote"].map(@dump_symbols.sexp_atom),
    content=(
      #|["plain", "\"\"", "\"a(b\"", "\"tab\\there\"", "\"q\\\"uote\""]
    ),
  )
}

///|
test "the pass prints to the output callback" {
  let out = StringBuilder()
  debug_inspect(
    @dump_symbols.register(out=s => out.write_string(s)),
    content="Ok(true)",
  )
  debug_inspect(@dump_symbols.register(), content="Ok(false)")
  let project = @project.Project::empty(@core_theory.Target::unknown())
  guard project.run_pass("dump-symbols") is Ok(_) else {
    fail("dump-symbols failed")
  }
  inspect(out.to_string(), content="")
  inspect(@dump_symbols.dump(project), content="")
}
