///|
test "project default reconstructor turns disassembly blocks into named subroutines" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x01\x02\x03\x04",
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1001UL,
    endian=LittleEndian,
    [segment],
    symbols=[
      @image.Symbol::create(
        name="main",
        addr=0x1001UL,
        size=2,
        is_function=true,
      ),
      @image.Symbol::create(name="helper", addr=0x1003UL, size=1),
    ],
    target=@core_theory.Target::unknown(),
  )
  let project = @project.Project::from_image(image)
  match project.disassemble(driver="image-roots") {
    Ok(disassembled) =>
      match disassembled.reconstruct() {
        Ok(reconstructed) => {
          let subs = reconstructed.state().subroutines()
          assert_true(subs.length() == 2)
          assert_true(subs[0].sub_name() == "main")
          assert_true(subs[1].sub_name() == "helper")
          assert_true(reconstructed.program().subs().length() == 2)
          let first_block = subs[0].blks()[0]
          assert_true(
            @types.BlkTerm(first_block).has_address_text("0x1001:32u"),
          )
        }
        Err(reason) => fail(reason)
      }
    Err(reason) => fail(reason)
  }
}

///|
test "project default reconstructor groups blocks by reachable disassembly edges" {
  let target = @core_theory.Target::unknown()
  let entry = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5100UL,
    b"\x01",
  )
  let body = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5110UL,
    b"\x02",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5120UL,
    b"\x03",
  )
  let isolated = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5200UL,
    b"\x04",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(body)
    .add_block(isolated)
    .add_block(exit)
    .add_block(entry)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5100UL,
        target=0x5110UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5110UL,
        target=0x5120UL,
        kind=CondEdge,
      ),
    )
  let project = @project.Project::empty(target).with_disassembly(disassembly)
  match project.reconstruct() {
    Ok(reconstructed) => {
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 2)
      assert_true(subs[0].sub_name() == "sub_0x5100")
      assert_true(subs[0].blks().length() == 3)
      assert_true(subs[0].sub_has_edge(subs[0].blks()[0], subs[0].blks()[1]))
      assert_true(subs[0].sub_has_edge(subs[0].blks()[1], subs[0].blks()[2]))
      assert_true(subs[1].sub_name() == "sub_0x5200")
      assert_true(subs[1].blks().length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project default reconstructor stops groups at known function roots" {
  let target = @core_theory.Target::unknown()
  let entry = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6100UL,
    b"\x01",
  )
  let body = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6110UL,
    b"\x02",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x6120UL,
    b"\x03",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(body)
    .add_block(exit)
    .add_block(entry)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x6100UL,
        target=0x6110UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x6110UL,
        target=0x6120UL,
        kind=FallEdge,
      ),
    )
  let project = @project.Project::empty(target)
    .with_symbols([
      @image.Symbol::create(name="main", addr=0x6100UL, is_function=true),
      @image.Symbol::create(name="helper", addr=0x6110UL, is_function=true),
    ])
    .with_disassembly(disassembly)
  match project.reconstruct() {
    Ok(reconstructed) => {
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 2)
      assert_true(subs[0].sub_name() == "main")
      assert_true(subs[0].blks().length() == 1)
      assert_true(subs[0].blks()[0].jmps().is_empty())
      assert_true(subs[1].sub_name() == "helper")
      assert_true(subs[1].blks().length() == 2)
      assert_true(subs[1].sub_has_edge(subs[1].blks()[0], subs[1].blks()[1]))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project default reconstructor groups unrooted cyclic components" {
  let target = @core_theory.Target::unknown()
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5300UL,
    b"\x01",
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5310UL,
    b"\x02",
  )
  let third = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5400UL,
    b"\x03",
  )
  let fourth = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5410UL,
    b"\x04",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(second)
    .add_block(fourth)
    .add_block(first)
    .add_block(third)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5300UL,
        target=0x5310UL,
        kind=CondEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5310UL,
        target=0x5300UL,
        kind=JumpEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5400UL,
        target=0x5410UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x5410UL,
        target=0x5400UL,
        kind=JumpEdge,
      ),
    )
  let project = @project.Project::empty(target).with_disassembly(disassembly)
  match project.reconstruct() {
    Ok(reconstructed) => {
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 2)
      assert_true(subs[0].sub_name() == "sub_0x5300")
      assert_true(subs[0].blks().length() == 2)
      assert_true(subs[0].sub_has_edge(subs[0].blks()[0], subs[0].blks()[1]))
      assert_true(subs[0].sub_has_edge(subs[0].blks()[1], subs[0].blks()[0]))
      assert_true(subs[1].sub_name() == "sub_0x5400")
      assert_true(subs[1].blks().length() == 2)
      assert_true(subs[1].sub_has_edge(subs[1].blks()[0], subs[1].blks()[1]))
      assert_true(subs[1].sub_has_edge(subs[1].blks()[1], subs[1].blks()[0]))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassemble-and-reconstruct runs explicit driver and custom reconstructor" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x4000UL,
    b"\x10\x20\x30",
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x4001UL,
    endian=LittleEndian,
    [segment],
    symbols=[
      @image.Symbol::create(
        name="entry",
        addr=0x4001UL,
        size=1,
        is_function=true,
      ),
    ],
  )
  let project = @project.Project::from_image(image)
  match project.disassemble_and_reconstruct(driver="image-roots") {
    Ok(reconstructed) => {
      assert_true(reconstructed.get("disassembler") == Some("image-roots"))
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 1)
      assert_true(subs[0].sub_name() == "entry")
      assert_true(reconstructed.program().subs().length() == 1)
    }
    Err(reason) => fail(reason)
  }
  let custom = @project.ProjectReconstructor::create(project => {
    Ok(project.set("reconstructor", "custom"))
  })
  match
    project.disassemble_and_reconstruct(
      driver="entry-point",
      reconstructor=custom,
    ) {
    Ok(reconstructed) => {
      assert_true(reconstructed.get("disassembler") == Some("entry-point"))
      assert_true(reconstructed.get("reconstructor") == Some("custom"))
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    project.disassemble_and_reconstruct(driver="missing-driver") is Err(_),
  )
}

///|
test "project disassemble-and-reconstruct applies brancher before reconstruction" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let entry = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4800UL,
    b"\x01",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4810UL,
    b"\x02",
  )
  let memory = @memory.MemMap::singleton(entry, "code").add(exit, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  let brancher = @project.ProjectBrancher::of_edges([
    @project.ProjectDisassemblyEdge::create(
      source=0x4800UL,
      target=0x4810UL,
      kind=FallEdge,
    ),
  ])
  let reconstructor = @project.ProjectReconstructor::of_blocks([
    ("main", 0x4800UL, 0x4800UL),
    ("main", 0x4810UL, 0x4810UL),
  ])
  match
    project.disassemble_and_reconstruct(
      driver="memory-blocks",
      brancher~,
      reconstructor~,
    ) {
    Ok(reconstructed) => {
      let subs = reconstructed.program().subs()
      assert_true(subs.length() == 1)
      let blocks = subs[0].blks()
      assert_true(blocks.length() == 2)
      assert_true(subs[0].sub_has_edge(blocks[0], blocks[1]))
      assert_true(reconstructed.disassembly().edge_count() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project reconstructors register lookup and named application" {
  match @project.register_builtin_reconstructors() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_reconstructors() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.reconstructor_names().contains("default"))
  assert_true(@project.find_reconstructor("default") is Some(_))
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4a00UL,
    b"\x01",
  )
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_disassembly(
    @project.ProjectDisassemblyState::empty().add_block(block),
  )
  match project.reconstruct_named(reconstructor="default") {
    Ok(reconstructed) =>
      assert_true(reconstructed.program().subs().length() == 1)
    Err(reason) => fail(reason)
  }
  let custom = @project.ProjectReconstructor::create(project => {
    Ok(project.set("reconstructor", "named-custom"))
  })
  match
    @project.register_reconstructor(name="unit-named-reconstructor", custom) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match project.reconstruct_named(reconstructor="unit-named-reconstructor") {
    Ok(reconstructed) =>
      assert_true(reconstructed.get("reconstructor") == Some("named-custom"))
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.register_reconstructor(name="unit-named-reconstructor", custom)
    is Err(_),
  )
  assert_true(project.reconstruct_named(reconstructor="missing") is Err(_))
}

///|
test "project disassemble-and-reconstruct named resolves registered services" {
  match @project.register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let entry = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4b00UL,
    b"\x01",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4b10UL,
    b"\x02",
  )
  let memory = @memory.MemMap::singleton(entry, "code").add(exit, "code")
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    memory,
  )
  let brancher = @project.ProjectBrancher::of_edges([
    @project.ProjectDisassemblyEdge::create(
      source=0x4b00UL,
      target=0x4b10UL,
      kind=FallEdge,
    ),
  ])
  let reconstructor = @project.ProjectReconstructor::of_blocks([
    ("named", 0x4b00UL, 0x4b00UL),
    ("named", 0x4b10UL, 0x4b10UL),
  ])
  match @project.register_brancher(name="unit-named-brancher", brancher) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @project.register_reconstructor(
      name="unit-pipeline-reconstructor",
      reconstructor,
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    project.disassemble_and_reconstruct_named(
      driver="memory-blocks",
      brancher="unit-named-brancher",
      reconstructor="unit-pipeline-reconstructor",
    ) {
    Ok(reconstructed) => {
      let subs = reconstructed.program().subs()
      assert_true(subs.length() == 1)
      let blocks = subs[0].blks()
      assert_true(blocks.length() == 2)
      assert_true(subs[0].sub_has_edge(blocks[0], blocks[1]))
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    project.disassemble_and_reconstruct_named(
      driver="memory-blocks",
      brancher="missing",
    )
    is Err(_),
  )
  assert_true(
    project.disassemble_and_reconstruct_named(
      driver="memory-blocks",
      reconstructor="missing",
    )
    is Err(_),
  )
}

///|
test "project block reconstructor groups serialized block starts by name" {
  let target = @core_theory.Target::unknown()
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2000UL,
    b"\xaa\xbb",
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2010UL,
    b"\xcc",
  )
  let third = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3000UL,
    b"\xdd",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(second)
    .add_block(third)
    .add_block(first)
  let project = @project.Project::empty(target).with_disassembly(disassembly)
  let reconstructor = @project.ProjectReconstructor::of_blocks([
    ("func", 0x2010UL, 0x2010UL),
    ("missing", 0x9999UL, 0x9999UL),
    ("func", 0x2000UL, 0x2001UL),
    ("other", 0x3000UL, 0x3000UL),
  ])
  match project.reconstruct(reconstructor~) {
    Ok(reconstructed) => {
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 2)
      assert_true(subs[0].sub_name() == "func")
      assert_true(subs[1].sub_name() == "other")
      let blocks = subs[0].blks()
      assert_true(blocks.length() == 2)
      assert_true(@types.BlkTerm(blocks[0]).has_address_text("0x2000:32u"))
      assert_true(@types.BlkTerm(blocks[1]).has_address_text("0x2010:32u"))
      assert_true(reconstructed.program().subs().length() == 2)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project reconstructor preserves known intra-subroutine disassembly edges" {
  let target = @core_theory.Target::unknown()
  let entry = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3000UL,
    b"\x01",
  )
  let body = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3010UL,
    b"\x02",
  )
  let exit = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x3020UL,
    b"\x03",
  )
  let disassembly = @project.ProjectDisassemblyState::empty()
    .add_block(entry)
    .add_block(body)
    .add_block(exit)
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x3000UL,
        target=0x3010UL,
        kind=FallEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x3000UL,
        target=0x3020UL,
        kind=CondEdge,
      ),
    )
    .add_edge(
      @project.ProjectDisassemblyEdge::create(
        source=0x3010UL,
        target=0x9999UL,
        kind=JumpEdge,
      ),
    )
  let project = @project.Project::empty(target).with_disassembly(disassembly)
  let reconstructor = @project.ProjectReconstructor::of_blocks([
    ("main", 0x3000UL, 0x3000UL),
    ("main", 0x3010UL, 0x3010UL),
    ("main", 0x3020UL, 0x3020UL),
  ])
  match project.reconstruct(reconstructor~) {
    Ok(reconstructed) => {
      let subs = reconstructed.state().subroutines()
      assert_true(subs.length() == 1)
      let blocks = subs[0].blks()
      assert_true(blocks.length() == 3)
      assert_true(blocks[0].jmps().length() == 2)
      assert_true(blocks[1].jmps().is_empty())
      assert_true(subs[0].sub_has_edge(blocks[0], blocks[1]))
      assert_true(subs[0].sub_has_edge(blocks[0], blocks[2]))
      assert_true(!subs[0].sub_has_edge(blocks[1], blocks[2]))
      let jmp_attrs = [
        for jmp in blocks[0].jmps() => jmp.get_attr("disassembly-edge")
      ]
      assert_true(jmp_attrs.contains(Some("fall")))
      assert_true(jmp_attrs.contains(Some("cond")))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project reconstructor reports missing disassembly blocks" {
  let project = @project.Project::empty(@core_theory.Target::unknown())
  assert_true(project.reconstruct() is Err(_))
  let reconstructor = @project.ProjectReconstructor::of_blocks([
    ("missing", 0x10UL, 0x10UL),
  ])
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x20UL,
    b"\x00",
  )
  assert_true(
    project
    .with_disassembly(
      @project.ProjectDisassemblyState::empty().add_block(block),
    )
    .reconstruct(reconstructor~)
    is Err(_),
  )
}
