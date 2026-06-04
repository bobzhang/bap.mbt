///|
test "project builtin service registration is idempotent and complete" {
  match @project.register_builtin_services() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_services() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.available_input_loaders().contains("raw"))
  assert_true(@project.input_loader_names_for_extension("elf").contains("elf"))
  assert_true(@project.brancher_names().contains("empty"))
  assert_true(@project.disassembly_driver_names().contains("memory-blocks"))
  assert_true(@project.disassembly_driver_names().contains("image-roots"))
  assert_true(@project.disassembly_driver_names().contains("raw-bytes"))
  assert_true(@project.reconstructor_names().contains("default"))
  assert_true(@project.find_pass("ssa") is Some(_))
  assert_true(@project.find_pass("flatten") is Some(_))
  assert_true(@project.find_pass("stub-resolver") is Some(_))
}

///|
test "project builtin services support default disassemble reconstruct pipeline" {
  match @project.register_builtin_services() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7000UL,
    b"\x90\x90",
  )
  let memory = @memory.MemMap::singleton(block, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_memory(memory)
    .with_symbols([@image.Symbol::create(name="main", addr=0x7000UL, size=2)])
  match
    project.disassemble_and_reconstruct_named(
      driver="memory-blocks",
      brancher="empty",
      reconstructor="default",
    ) {
    Ok(reconstructed) => {
      assert_true(reconstructed.get("disassembler") == Some("memory-blocks"))
      assert_true(reconstructed.disassembly().block_count() == 1)
      let subs = reconstructed.program().subs()
      assert_true(subs.length() == 1)
      assert_true(subs[0].sub_name() == "main")
    }
    Err(reason) => fail(reason)
  }
}
