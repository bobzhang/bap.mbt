///|
fn symtab_test_block(
  start : UInt64,
  bytes : Bytes,
  assembly~ : String = "nop",
) -> @project.ProjectDisassemblyBlock raise {
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  match
    @project.ProjectDisassemblyBlock::create(memory, [
      @project.ProjectDisassemblyInstruction::create(memory, assembly~),
    ]) {
    Ok(block) => block
    Err(reason) => fail(reason)
  }
}

///|
fn symtab_test_state(
  blocks : Array[@project.ProjectDisassemblyBlock],
) -> @project.ProjectDisassemblyState {
  let mut state = @project.ProjectDisassemblyState::empty()
  for block in blocks {
    state = state.add_block(block.memory())
    for instruction in block.instructions() {
      state = state.add_instruction(instruction)
    }
  }
  state
}

///|
test "project disassembly symtab exposes BAP symbol lookup and ownership queries" {
  let main = symtab_test_block(0x8000UL, b"\x01\x02")
  let body = symtab_test_block(0x8010UL, b"\x03\x04")
  let helper = symtab_test_block(0x9000UL, b"\x05")
  let main_fn = @project.ProjectDisassemblyFunction::create(
    name="main",
    entry=main,
    blocks=[body, main, body],
  )
  let helper_fn = @project.ProjectDisassemblyFunction::create(
    name="helper",
    entry=helper,
  )
  assert_true(main_fn.name() == "main")
  assert_true(main_fn.addr() == 0x8000UL)
  assert_true(main_fn.entry().addr() == 0x8000UL)
  assert_true(main_fn.block_count() == 2)
  assert_true(main_fn.blocks()[0].addr() == 0x8000UL)
  assert_true(main_fn.blocks()[1].addr() == 0x8010UL)
  let span = main_fn.span()
  assert_true(span.lookup(0x8001UL).length() == 1)
  assert_true(span.lookup(0x8011UL).length() == 1)
  assert_true(span.lookup(0x9000UL).is_empty())
  let symtab = @project.ProjectDisassemblySymtab::empty()
    .add_symbol(main_fn)
    .add_symbol(helper_fn)
  let functions = symtab.to_sequence()
  assert_true(functions.length() == 2)
  assert_true(functions[0].name() == "main")
  assert_true(functions[1].name() == "helper")
  match symtab.find_by_name("main") {
    Some(function) => assert_true(function.addr() == 0x8000UL)
    None => fail("missing main")
  }
  match symtab.find_by_start(0x9000UL) {
    Some(function) => assert_true(function.name() == "helper")
    None => fail("missing helper")
  }
  assert_true(symtab.find_by_name("missing") is None)
  let owners = symtab.owners(0x8011UL)
  assert_true(owners.length() == 1)
  assert_true(owners[0].name() == "main")
  let dominated = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x8011UL,
    b"\xff",
  )
  let dominators = symtab.dominators(dominated)
  assert_true(dominators.length() == 1)
  assert_true(dominators[0].name() == "main")
  let intersecting = symtab.intersecting(
    @memory.Memory::from_bytes(endian=LittleEndian, start=0x9000UL, b"\xff\xff"),
  )
  assert_true(intersecting.length() == 1)
  assert_true(intersecting[0].name() == "helper")
}

///|
test "project disassembly symtab records BAP-style call maps and removal" {
  let main = symtab_test_block(0x8200UL, b"\x01")
  let body = symtab_test_block(0x8210UL, b"\x02")
  let helper = symtab_test_block(0x8300UL, b"\x03")
  let main_fn = @project.ProjectDisassemblyFunction::create(
    name="main",
    entry=main,
    blocks=[main, body],
  )
  let helper_fn = @project.ProjectDisassemblyFunction::create(
    name="helper",
    entry=helper,
  )
  let symtab = @project.ProjectDisassemblySymtab::create(functions=[
      main_fn, helper_fn,
    ])
    .insert_call(body, "helper")
    .insert_call(main, "fallthrough", implicit=true)
    .insert_call(helper, "extern")
  assert_true(symtab.explicit_callee(0x8210UL) == Some("helper"))
  assert_true(symtab.implicit_callee(0x8200UL) == Some("fallthrough"))
  assert_true(symtab.callee(0x8210UL) == Some("helper"))
  assert_true(symtab.callee(0x8200UL) == Some("fallthrough"))
  let replaced = symtab.insert_call(body, "replacement")
  assert_true(replaced.explicit_callee(0x8210UL) == Some("replacement"))
  let removed = symtab.remove(helper_fn)
  assert_true(removed.find_by_name("helper") is None)
  assert_true(removed.explicit_callee(0x8210UL) is None)
  assert_true(removed.explicit_callee(0x8300UL) is None)
  assert_true(removed.implicit_callee(0x8200UL) == Some("fallthrough"))
}

///|
test "project disassembly symtab derives functions and cross calls from project state" {
  let main = symtab_test_block(0x8400UL, b"\x01")
  let body = symtab_test_block(0x8410UL, b"\x02\x03")
  let helper = symtab_test_block(0x8500UL, b"\x04")
  let helper_body = symtab_test_block(0x8510UL, b"\x05")
  let disassembly = symtab_test_state([helper_body, body, main, helper])
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x8400UL,
        target=0x8410UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x8411UL,
        target=0x8500UL,
        kind=JumpEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x8500UL,
        target=0x8510UL,
        kind=FallEdge,
      ),
    )
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_symbols([
      @image.Symbol::create(name="main", addr=0x8400UL, is_function=true),
      @image.Symbol::create(name="helper", addr=0x8500UL, is_function=true),
    ])
    .with_disassembly(disassembly)
  let symtab = project.disassembly_symtab()
  let functions = symtab.to_sequence()
  assert_true(functions.length() == 2)
  assert_true(functions[0].name() == "main")
  assert_true(functions[0].block_count() == 2)
  assert_true(functions[1].name() == "helper")
  assert_true(functions[1].block_count() == 2)
  assert_true(symtab.explicit_callee(0x8410UL) == Some("helper"))
  assert_true(symtab.callee(0x8410UL) == Some("helper"))
  assert_true(symtab.callee(0x8400UL) is None)
  assert_true(symtab.owners(0x8510UL)[0].name() == "helper")
}
