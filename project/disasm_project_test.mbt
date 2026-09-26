///|
/// A raw x86-64 project with the code of `driver_test_code` and the
/// symbols `main` (0x1000) and `helper` (0x1010).
fn disasm_project_test() -> @project.Project {
  let code = driver_test_code()
  @project.Project::empty(@core_theory.Target::x86_64())
  .with_memory(@memory.MemMap::singleton(code, "code"))
  .with_symbols([
    @image.Symbol::create(name="main", addr=0x1000UL, is_function=true),
    @image.Symbol::create(name="helper", addr=0x1010UL, is_function=true),
  ])
}

///|
fn disasm_project_edges(
  disassembly : @project.ProjectDisassemblyState,
) -> String {
  disassembly
  .edges()
  .map(edge => {
    let target = match edge.target() {
      Some(target) => target.to_string(radix=16)
      None => "?"
    }
    "\{edge.source().to_string(radix=16)}->\{target}:\{edge.kind().to_string()}"
  })
  .join(" ")
}

///|
test "the recursive driver disassembles, partitions and reconstructs the project" {
  guard @project.register_builtin_disassembly_drivers() is Ok(_) else {
    fail("registration failed")
  }
  guard disasm_project_test().disassemble(driver="recursive") is Ok(project) else {
    fail("the recursive driver failed")
  }
  assert_eq(project.get("disassembler"), Some("recursive"))
  guard project.disassembly_driver_state() is Some(driver) else {
    fail("no driver state")
  }
  // the rooter roots and the call destinations are the subroutines
  inspect(driver_test_hex(driver.subroutines()), content="1000 1010")
  // the materialized disassembly: the blocks reachable from the block
  // starts, their instructions and edges
  let disassembly = project.disassembly()
  inspect(
    driver_test_hex(disassembly.blocks().map(block => block.min_addr())),
    content="1000 1006 100a 100c 100e 1010",
  )
  assert_eq(disassembly.instruction_count(), 11)
  inspect(
    disasm_project_edges(disassembly),
    content=(
      #|1001->1006:fall 1001->1010:jump 1008->100a:fall 1008->100c:cond 100a->100c:fall 100f->1010:fall
    ),
  )
  // the subroutine partition (upstream `Calls.update`)
  let calls = project.disassembly_calls()
  inspect(driver_test_hex(calls.entries()), content="1000 1010")
  assert_true(calls.belongs(entry=0x1000UL, 0x100cUL))
  assert_eq(calls.entry(0x100aUL), 0x1000UL)
  assert_true(!calls.siblings(0x1000UL, 0x1010UL))
  // the symbol table (upstream `Symtab.create`)
  let symtab = project.disassembly_symtab()
  inspect(
    symtab
    .to_sequence()
    .map(fn_ => {
      "\{fn_.name()}@\{fn_.addr().to_string(radix=16)}[\{driver_test_hex(fn_.blocks().map(b => b.addr()))}]"
    })
    .join(" "),
    content=(
      #|main@1000[1000 1006 100a 100c] helper@1010[1010]
    ),
  )
  assert_eq(symtab.explicit_callee(0x1000UL), Some("helper"))
  // the padding at 0x100e is not reachable from a subroutine: it belongs
  // to no function
  assert_eq(symtab.implicit_callee(0x100eUL), None)
  // the program lifted from the symbol table
  guard project.reconstruct() is Ok(reconstructed) else {
    fail("reconstruction failed")
  }
  inspect(
    reconstructed.program().subs().map(sub => sub.sub_name()).join(" "),
    content=(
      #|main helper
    ),
  )
  // changing the disassembly drops the driver state
  let changed = project.with_disassembly(
    project
    .disassembly()
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x1000UL,
        target=0x1010UL,
        kind=JumpEdge,
      ),
    ),
  )
  assert_true(changed.disassembly_driver_state() is None)
}

///|
test "the driver scans regions incrementally and pays the debt of earlier scans" {
  let kb = @knowledge.State::new()
  let unit = @core_theory.ProgramUnit::for_file(
    "driver-regions",
    target=@core_theory.Target::x86_64(),
  )
  // 0x2000: jmp 0x3000 (in the other region)
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2000UL,
    b"\xe9\xfb\x0f\x00\x00",
  )
  // 0x3000: xor eax, eax; ret
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3000UL,
    b"\x31\xc0\xc3",
  )
  @core_theory.Label::unit_slot().promising(promise=(_, _) => Some(unit), () => {
    let driver = @project.ProjectDisassemblyDriverState::init().scan(first, kb)
    // the destination of the jump is outside of the scanned memory
    assert_eq(driver.debt_count(), 2)
    assert_true(!driver.is_block(0x3002UL))
    let driver = driver.scan(second, kb)
    inspect(driver_test_hex(driver.blocks()), content="2000 2005 3000 3003")
    assert_eq(
      driver.jump(0x2000UL).map(j => j.destinations()),
      Some([0x3000UL]),
    )
    assert_eq(driver.memory().length(), 2)
    // merging states unites their knowledge
    let other = @project.ProjectDisassemblyDriverState::init().scan(second, kb)
    let merged = other.merge(driver)
    assert_true(merged.is_block(0x2000UL) && merged.is_block(0x3000UL))
    assert_true(merged.forget_debt().debt_count() == 0)
  })
}

///|
test "the knowledge classifies the addresses of scanned memory" {
  let kb = @knowledge.State::new()
  let unit = @core_theory.ProgramUnit::for_file(
    "driver-data",
    target=@core_theory.Target::x86_64(),
  )
  // xor eax, eax; ret; xor eax, eax; ret
  let code = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4000UL,
    b"\x31\xc0\xc3\x31\xc0\xc3",
  )
  let valid = @core_theory.Label::is_valid_slot()
  @core_theory.Label::unit_slot().promising(promise=(_, _) => Some(unit), () => {
    valid.promising(
      promise=(kb, label) => {
        let addr = kb.collect(@core_theory.Label::addr_slot(), label)
        // the second function is data
        match addr.map(word => word.to_uint64()) {
          Some(0x4003UL) => Some(false)
          _ => None
        }
      },
      () => {
        let driver = @project.ProjectDisassemblyDriverState::init().scan(
          code, kb,
        )
        assert_true(driver.is_data(0x4003UL))
        inspect(driver_test_hex(driver.blocks()), content="4000")
      },
    )
  })
}

///|
test "rooters, symbolizers and branchers provide knowledge" {
  let kb = @knowledge.State::new()
  let project = disasm_project_test()
  let unit = @core_theory.ProgramUnit::for_file(
    "",
    target=@core_theory.Target::x86_64(),
  )
  let label = @core_theory.Label::unit_slot().promising(
    promise=(_, _) => Some(unit),
    () => {
      let rooter = @project.ProjectRooter::create([0x1006UL])
      let symbolizer = @project.ProjectSymbolizer::create(addr => {
        if addr == 0x1006UL {
          Some("after_call")
        } else {
          None
        }
      })
      rooter.providing(() => {
        symbolizer.providing(@project.ProjectSymbolizer::agent(), () => {
          let driver = @project.ProjectDisassemblyDriverState::init().scan(
            driver_test_code(),
            kb,
          )
          assert_true(driver.is_subroutine(0x1006UL))
          @project.ProjectSymbolizer::get_name(kb, 0x1006UL)
        })
      })
    },
  )
  assert_eq(label, "after_call")
  assert_eq(@project.ProjectSymbolizer::get_name(kb, 0x1234UL), "sub_0x1234")
  // the brancher of the lifted semantics gives the fallthroughs and jumps
  let brancher = @project.ProjectBrancher::of_bil(@core_theory.Target::x86_64())
  guard @project.ProjectDisassemblyBasic::create("x86_64") is Ok(dis) &&
    driver_test_code().view(from=0x1008UL) is Ok(mem) &&
    dis.insn_of_mem(mem) is Ok(result) &&
    result.instruction() is Some(je) else {
    fail("decoding failed")
  }
  inspect(
    brancher
    .resolve_insn(result.memory(), je)
    .map(edge => {
      "\{edge.target().unwrap_or(0).to_string(radix=16)}:\{edge.kind().to_string()}"
    })
    .join(" "),
    content="100a:fall 100c:cond",
  )
  // a brancher provided to the project adds destinations
  let extra = @project.ProjectBrancher::of_resolver((mem, insn) => {
    if insn.addr() == 0x1000UL {
      [
        @project.ProjectDisassemblyEdge::create(
          source=mem.min_addr(),
          target=0x100eUL,
          kind=JumpEdge,
        ),
      ]
    } else {
      []
    }
  })
  guard project.disassemble_recursive(brancher=extra) is Ok(branched) &&
    branched.disassembly_driver_state() is Some(driver) else {
    fail("disassembly failed")
  }
  assert_eq(driver.jump(0x1000UL).map(j => j.destinations()), Some([0x100eUL]))
}
