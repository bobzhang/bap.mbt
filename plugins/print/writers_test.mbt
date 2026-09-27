///|
fn sample_symtab() -> (@project.Project, @project.ProjectDisassemblySymtab) raise {
  let m1 = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x55",
  )
  let i1 = @project.ProjectDisassemblyInstruction::create(
    m1,
    assembly="push rbp",
    name="PUSH64r",
    operands=[@project.ProjectInstructionOperand::register(name="RBP")],
  )
  let m2 = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1001UL,
    b"\xe8\x00\x00\x00\x00",
  )
  let i2 = @project.ProjectDisassemblyInstruction::create(
    m2,
    assembly="call 0x1006",
    name="CALL64pcrel32",
    operands=[@project.ProjectInstructionOperand::immediate(-6L)],
    kinds=[ProjectCall],
  )
  let code = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x55\xe8\x00\x00\x00\x00",
  )
  let blk = @project.ProjectDisassemblyBlock::create(code, [i1, i2]).unwrap()
  let main = @project.ProjectDisassemblyFunction::create(name="main", entry=blk)
  let symtab = @project.ProjectDisassemblySymtab::empty().add_symbol(main)
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_memory(@memory.MemMap::singleton(code, ".text"))
    .with_program(sample_program())
  (project, symtab)
}

///|
test "symbols are printed with the selected columns" {
  let (project, symtab) = sample_symtab()
  let fmt = @text_tags.Formatter::new()
  @print.pp_symbols(fmt, project, symtab~, formats=[
    WithName,
    WithAddr,
    WithSize,
  ])
  inspect(
    fmt.flush_str(),
    content=(
      #|main 1000  6 
      #|
    ),
  )
  @print.pp_symbols(fmt, project, symtab~, demangle=s => "_" + s)
  inspect(fmt.flush_str(), content="_main \n")
  @print.pp_symbols(
    fmt,
    project,
    symtab~,
    patterns=@print.compile_patterns(patterns=["subroutine:foo"]).unwrap(),
  )
  inspect(fmt.flush_str(), content="")
}

///|
test "disassembly listing in the asm and decoded formats" {
  let (project, symtab) = sample_symtab()
  let fmt = @text_tags.Formatter::new()
  @print.pp_disasm(fmt, project, @print.insn_printer("asm"), symtab~)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|Disassembly of section .section@0x1000
      #|
      #|1000: <main>
      #|1000:
      #|1000: 55                                          push rbp
      #|1001: e8 00 00 00 00                              call 0x1006 # 1000
      #|
    ),
  )
  @print.pp_disasm(fmt, project, @print.insn_printer("pretty"), symtab~)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|Disassembly of section .section@0x1000
      #|
      #|1000: <main>
      #|1000:
      #|1000: 55                                          PUSH64r(RBP)
      #|1001: e8 00 00 00 00                              CALL64pcrel32(-0x6) # 1000
      #|
    ),
  )
  @print.pp_disasm(fmt, project, @print.insn_printer("adt"), symtab~)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|Disassembly of section .section@0x1000
      #|
      #|1000: <main>
      #|1000:
      #|1000: 55                                          PUSH64r(Reg("RBP"), Props())
      #|1001: e8 00 00 00 00                              CALL64pcrel32(Imm(0xfffffffffffffffa), Props(:call)) # 1000
      #|
    ),
  )
}

///|
test "memory is printed as a hexdump when it is large" {
  let bytes = Bytes::makei(20, i => (0x41 + i).to_byte())
  let mem = @memory.Memory::from_bytes(endian=LittleEndian, start=0x10UL, bytes)
  inspect(
    @print.memory_to_string(mem),
    content=(
      #|00000010  41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 |ABCDEFGHIJKLMNOP|
      #|00000020  51 52 53 54                                     |QRST            |
      #|
    ),
  )
}

///|
test "register installs the upstream writers" {
  let (project, _) = sample_symtab()
  @print.register().unwrap()
  // registering twice does not duplicate writers
  @print.register(symbols=["foo"]).unwrap()
  debug_inspect(
    @print.writers().map(w => w.name()),
    content=(
      #|[
      #|  "symbols",
      #|  "bir",
      #|  "adt",
      #|  "callgraph",
      #|  "cfg",
      #|  "graph",
      #|  "asm",
      #|  "asm.adt",
      #|  "asm.decoded",
      #|  "asm.sexp",
      #|  "bil",
      #|  "bil.adt",
      #|  "bil.sexp",
      #|  "ogre",
      #|]
    ),
  )
  inspect(
    @print.write("bir", project).unwrap(),
    content=(
      #|00000001: program
      #|
    ),
  )
  @print.register().unwrap()
  inspect(
    @print.write("callgraph", project).unwrap(),
    content=(
      #|
      #|digraph  {
      #|  "@main"
      #|  "@foo"
      #|  "@main" -> "@foo"
      #|}
      #|
    ),
  )
  assert_true(@print.write("nope", project) is Err(_))
  assert_true(@print.register(demangler="no-such-demangler") is Err(_))
}

///|
test "the plugin is declared in the bap_main framework" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @print.declare_plugin()
  @bap_main.initialize(argv=[
    "bap", "--print-bir-attr=address", "--print-symbol=main", "--print-symbol-format=addr",
  ])
  debug_inspect(
    @bap_main.loaded_plugins(),
    content=(
      #|["print"]
    ),
  )
  @bap_main.reset()
  let (project, _) = sample_symtab()
  let project = project.with_symbols([
    @image.Symbol::create(name="main", addr=0x400000UL, size=16),
  ])
  inspect(
    @print.write("bir", project).unwrap(),
    content=(
      #|00000001: program
      #|.address 0x400000:64u
      #|00000010: sub main(main_argc)
      #|00000011: main_argc :: in u32 = low:32[RDI]
      #|
      #|00000020:
      #|.address 0x400000:64u
      #|00000021: RSP := RSP - 800000022: mem := mem with [RSP, el]:u64 <- RBP
      #|00000023: call @foo with return %00000030 
      #|00000030:
      #|00000031: when ZF goto %00000020
      #|00000032: return RAX
      #|
    ),
  )
  @text_tags.attr_hide("address")
  @print.register().unwrap()
}

///|
test "bil listing in the pretty, adt, and sexp formats" {
  let (project, symtab) = sample_symtab()
  let fmt = @text_tags.Formatter::new()
  @print.pp_disasm(fmt, project, @print.bil_printer("pretty"), symtab~)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|Disassembly of section .section@0x1000
      #|
      #|1000: <main>
      #|1000:
      #|1000: push rbp
      #|{
      #|  mem := mem with [RSP - 8, el]:u64 <- RBP
      #|  RSP := RSP - 8
      #|}
      #|1001: call 0x1006
      #|{
      #|  RSP := RSP - 8
      #|  mem := mem with [RSP, el]:u64 <- 0x1006
      #|  call(0x1000)
      #|  jmp 0x1000
      #|}
      #|
    ),
  )
  @print.pp_disasm(fmt, project, @print.bil_printer("adt"), symtab~)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|Disassembly of section .section@0x1000
      #|
      #|1000: <main>
      #|1000:
      #|1000: push rbp
      #|(Move(Var("mem",Mem(64,8)),Store(Var("mem",Mem(64,8)),MINUS(Var("RSP",Imm(64)),Int(8,64)),Var("RBP",Imm(64)),LittleEndian(),64)), Move(Var("RSP",Imm(64)),MINUS(Var("RSP",Imm(64)),Int(8,64))))
      #|1001: call 0x1006
      #|(Move(Var("RSP",Imm(64)),MINUS(Var("RSP",Imm(64)),Int(8,64))), Move(Var("mem",Mem(64,8)),Store(Var("mem",Mem(64,8)),Var("RSP",Imm(64)),Int(4102,64),LittleEndian(),64)), Special("@attribute:(bap:call 0x1000)"), Jmp(Int(4096,64)))
      #|
    ),
  )
}
