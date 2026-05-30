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
