///|
test "project info streams observe input realization" {
  let files = []
  let arch_sizes = []
  let code_counts = []
  let data_counts = []
  let spec_counts = []
  let file_stream = @project.ProjectInfo::file()
  let arch_stream = @project.ProjectInfo::arch()
  let code_stream = @project.ProjectInfo::code()
  let data_stream = @project.ProjectInfo::data()
  let spec_stream = @project.ProjectInfo::spec()
  let file_id = file_stream.subscribe(file => files.push(file))
  let arch_id = arch_stream.subscribe(target => {
    arch_sizes.push(target.code_addr_size())
  })
  let code_id = code_stream.subscribe(memory => {
    code_counts.push(memory.length())
  })
  let data_id = data_stream.subscribe(memory => {
    data_counts.push(memory.length())
  })
  let spec_id = spec_stream.subscribe(spec => {
    spec_counts.push(spec.declaration_count())
  })
  let code_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7000UL,
    b"\x90",
  )
  let data_memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7100UL,
    b"\x01\x02",
  )
  let input = @project.ProjectInput::create(
    target=@core_theory.Target::x86_64(),
    filename="info.bin",
    code=@memory.MemMap::singleton(code_memory, ".text"),
    data=@memory.MemMap::singleton(data_memory, ".rodata"),
  )
  let project = @project.Project::from_input(input)
  file_stream.unsubscribe(file_id)
  arch_stream.unsubscribe(arch_id)
  code_stream.unsubscribe(code_id)
  data_stream.unsubscribe(data_id)
  spec_stream.unsubscribe(spec_id)
  assert_true(project.filename() == Some("info.bin"))
  assert_true(files == ["info.bin"])
  assert_true(arch_sizes == [64])
  assert_true(code_counts == [1])
  assert_true(data_counts == [1])
  assert_true(spec_counts.length() == 1)
}

///|
test "project info file stream reports unnamed inputs as empty filenames" {
  let files = []
  let file_stream = @project.ProjectInfo::file()
  let file_id = file_stream.subscribe(file => files.push(file))
  let input = @project.ProjectInput::custom(
    target=@core_theory.Target::unknown(),
  )
  let project = @project.Project::from_input(input)
  file_stream.unsubscribe(file_id)
  assert_true(project.filename() is None)
  assert_true(files == [""])
}

///|
test "project info streams observe source-driven reconstruction" {
  let cfg_counts = []
  let symtab_counts = []
  let program_counts = []
  let cfg_stream = @project.ProjectInfo::cfg()
  let symtab_stream = @project.ProjectInfo::symtab()
  let program_stream = @project.ProjectInfo::program()
  let cfg_id = cfg_stream.subscribe(cfg => cfg_counts.push(cfg.node_count()))
  let symtab_id = symtab_stream.subscribe(symtab => {
    symtab_counts.push(symtab.to_sequence().length())
  })
  let program_id = program_stream.subscribe(program => {
    program_counts.push(program.subs().length())
  })
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x7200UL,
    b"\x55",
  )
  let input = @project.ProjectInput::custom(
    target=@core_theory.Target::unknown(),
    memory=@memory.MemMap::singleton(block, "code"),
  )
  let driver_source : @project.ProjectDisassemblySource[
    @project.ProjectDisassemblyDriver,
  ] = @project.ProjectDisassemblySource::single(
    @project.ProjectDisassemblyDriver::raw_bytes(),
  )
  let symbolizer_source : @project.ProjectDisassemblySource[
    @project.ProjectSymbolizer,
  ] = @project.ProjectDisassemblySource::single(
    @project.ProjectSymbolizer::create(addr => {
      if addr == 0x7200UL {
        Some("info_entry")
      } else {
        None
      }
    }),
  )
  match
    @project.Project::create_from_input(
      input,
      driver_source~,
      symbolizer=symbolizer_source,
    ) {
    Ok(project) => {
      cfg_stream.unsubscribe(cfg_id)
      symtab_stream.unsubscribe(symtab_id)
      program_stream.unsubscribe(program_id)
      assert_true(project.disassembly_cfg().node_count() == 1)
      assert_true(project.disassembly_symtab().to_sequence().length() == 1)
      assert_true(project.program().subs().length() == 1)
      assert_true(cfg_counts == [1])
      assert_true(symtab_counts == [1])
      assert_true(program_counts == [1])
    }
    Err(reason) => fail(reason)
  }
}
