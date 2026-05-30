///|
test "project disassembly drivers register lookup and run" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x500UL,
    b"\x90\x90",
  )
  let driver = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-direct",
    description="unit disassembler",
    priority=10,
    run=project => {
      Ok(
        project
        .with_disassembly(project.disassembly().add_block(block))
        .set("disasm", "direct"),
      )
    },
  )
  match @project.register_disassembly_driver(driver) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_disassembly_driver("unit-disasm-direct") is Some(_))
  assert_true(
    @project.disassembly_driver_names().contains("unit-disasm-direct"),
  )
  assert_true(driver.description() == "unit disassembler")
  assert_true(driver.priority() == 10)
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.disassemble(driver="unit-disasm-direct") {
    Ok(next) => {
      assert_true(next.get("disasm") == Some("direct"))
      assert_true(next.disassembly().block_count() == 1)
      assert_true(next.disassembly().blocks()[0].min_addr() == 0x500UL)
    }
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_disassembly_driver(driver) is Err(_))
}

///|
test "project disassembly drivers fall back by priority" {
  let failing = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-priority-high",
    priority=100,
    run=_ => Err("not this driver"),
  )
  let fallback = @project.ProjectDisassemblyDriver::create(
    name="unit-disasm-priority-low",
    priority=90,
    run=project => Ok(project.set("disasm-fallback", "yes")),
  )
  match @project.register_disassembly_driver(failing) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_disassembly_driver(fallback) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.disassembly_driver_names().contains("unit-disasm-priority-high"),
  )
  let project = @project.Project::empty(@core_theory.Target::unknown())
  match project.disassemble_with_available() {
    Ok(next) => assert_true(next.get("disasm-fallback") == Some("yes"))
    Err(reason) => fail(reason)
  }
  assert_true(project.disassemble(driver="unit-disasm-missing") is Err(_))
}
