///|
test "project disassembly source context checks path applicability" {
  match
    @project.ProjectDisassemblySourceContext::create(size=32, path="unit.bin") {
    Ok(context) => {
      assert_true(context.path() == Some("unit.bin"))
      assert_true(context.bias() == None)
      assert_true(context.size() == 32)
      assert_true(context.is_applicable())
      assert_true(context.is_applicable(path="unit.bin"))
      assert_true(!context.is_applicable(path="other.bin"))
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectDisassemblySourceContext::create(size=32) {
    Ok(context) => {
      assert_true(context.is_applicable())
      assert_true(!context.is_applicable(path="unit.bin"))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly source context converts biased label addresses" {
  let target = @core_theory.Target::x86_64()
  let base = @types.Word::of_uint64(width=64, 0x400000UL)
  let unit = @core_theory.ProgramUnit::for_file("main.o", target~, bias=base)
  let address = @types.Word::of_uint64(width=64, 0x401234UL)
  let label = @core_theory.Label::for_addr(address, target~).with_unit(unit)
  match @project.ProjectDisassemblySourceContext::for_label(label) {
    Ok(context) => {
      assert_true(context.path() == Some("main.o"))
      assert_true(context.bias() == Some(base))
      assert_true(context.size() == 64)
      match context.create_addr(0x401234UL) {
        Ok(word) => assert_true(word.to_string() == "0x401234:64u")
        Err(reason) => fail(reason)
      }
      match context.create_addr(0x401234UL, unbiased=true) {
        Ok(word) => assert_true(word.to_string() == "0x1234:64u")
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly source context normalizes word widths" {
  let bias = @types.Word::of_uint64(width=32, 0x1000UL)
  match @project.ProjectDisassemblySourceContext::create(size=64, bias~) {
    Ok(context) => {
      assert_true(context.bias().map(word => word.bitwidth()) == Some(64))
      let wide = @types.Word::of_uint64(width=128, 0x1100UL)
      match context.create_word_addr(wide, unbiased=true) {
        Ok(word) => assert_true(word.to_string() == "0x100:64u")
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectDisassemblySourceContext::create(size=0) {
    Err(reason) =>
      assert_true(
        reason ==
        "project disassembly source context requires positive address size",
      )
    Ok(_) => fail("unexpected zero-width source context")
  }
}

///|
test "project disassembly source keeps values and errors" {
  let rooter = @project.ProjectRooter::create([0x10UL])
  let source : @project.ProjectDisassemblySource[@project.ProjectRooter] = @project.ProjectDisassemblySource::create([
      Ok(rooter),
      Err("rooter source failed"),
    ],
  )
  assert_true(!source.is_empty())
  assert_true(source.length() == 2)
  assert_true(source.items().length() == 2)
  let values = source.values()
  assert_true(values.length() == 1)
  assert_true(values[0].roots()[0] == 0x10UL)
  let errors = source.errors()
  assert_true(errors.length() == 1)
  assert_true(errors[0] == "rooter source failed")
}

///|
test "project disassembly source rooter registry overwrites by name" {
  @project.register_rooter_source_value(
    name="unit-source-rooter",
    @project.ProjectRooter::create([0x10UL]),
  )
  assert_true(@project.rooter_source_names().contains("unit-source-rooter"))
  match @project.find_rooter_source("unit-source-rooter") {
    Some(source) => {
      let rooters = source.values()
      assert_true(rooters.length() == 1)
      assert_true(rooters[0].roots()[0] == 0x10UL)
      assert_true(source.errors().is_empty())
    }
    None => fail("missing rooter source")
  }
  @project.register_rooter_source_value(
    name="unit-source-rooter",
    @project.ProjectRooter::create([0x20UL]),
  )
  match @project.find_rooter_source("unit-source-rooter") {
    Some(source) => {
      let rooters = source.values()
      assert_true(rooters.length() == 1)
      assert_true(rooters[0].roots()[0] == 0x20UL)
    }
    None => fail("missing overwritten rooter source")
  }
}

///|
test "project disassembly source brancher registry keeps checked streams" {
  let block = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x2100UL,
    b"\x01",
  )
  let edge = @project.ProjectDisassemblyEdge::create(
    source=0x2100UL,
    target=0x2110UL,
    kind=JumpEdge,
  )
  @project.register_brancher_source_value(
    name="unit-source-brancher",
    @project.ProjectBrancher::of_edges([edge]),
  )
  assert_true(@project.brancher_source_names().contains("unit-source-brancher"))
  match @project.find_brancher_source("unit-source-brancher") {
    Some(source) => {
      let branchers = source.values()
      assert_true(branchers.length() == 1)
      let edges = branchers[0].resolve(block)
      assert_true(edges.length() == 1)
      assert_true(edges[0].source() == 0x2100UL)
    }
    None => fail("missing brancher source")
  }
  @project.register_brancher_source(
    name="unit-source-brancher",
    @project.ProjectDisassemblySource::error("brancher unavailable"),
  )
  match @project.find_brancher_source("unit-source-brancher") {
    Some(source) => {
      assert_true(source.values().is_empty())
      assert_true(source.errors() == ["brancher unavailable"])
    }
    None => fail("missing overwritten brancher source")
  }
}

///|
test "project disassembly source symbolizer registry keeps checked streams" {
  let symbolizer = @project.ProjectSymbolizer::create(addr => {
    if addr == 0x3000UL {
      Some("main")
    } else {
      None
    }
  })
  @project.register_symbolizer_source_value(
    name="unit-source-symbolizer",
    symbolizer,
  )
  assert_true(
    @project.symbolizer_source_names().contains("unit-source-symbolizer"),
  )
  match @project.find_symbolizer_source("unit-source-symbolizer") {
    Some(source) => {
      let symbolizers = source.values()
      assert_true(symbolizers.length() == 1)
      assert_true(symbolizers[0].resolve(0x3000UL) == "main")
      assert_true(symbolizers[0].resolve(0x3010UL) == "sub_0x3010")
    }
    None => fail("missing symbolizer source")
  }
  @project.register_symbolizer_source(
    name="unit-source-symbolizer",
    @project.ProjectDisassemblySource::error("symbolizer unavailable"),
  )
  match @project.find_symbolizer_source("unit-source-symbolizer") {
    Some(source) => {
      assert_true(source.values().is_empty())
      assert_true(source.errors() == ["symbolizer unavailable"])
    }
    None => fail("missing overwritten symbolizer source")
  }
}

///|
test "project disassembly source driver registry keeps checked streams" {
  let driver = @project.ProjectDisassemblyDriver::create(
    name="unit-source-driver",
    run=project => Ok(project.set("source-driver", "ran")),
  )
  @project.register_disassembly_driver_source_value(
    name="unit-source-driver",
    driver,
  )
  assert_true(
    @project.disassembly_driver_source_names().contains("unit-source-driver"),
  )
  match @project.find_disassembly_driver_source("unit-source-driver") {
    Some(source) => {
      let drivers = source.values()
      assert_true(drivers.length() == 1)
      assert_true(drivers[0].name() == "unit-source-driver")
      match
        drivers[0].run(@project.Project::empty(@core_theory.Target::unknown())) {
        Ok(project) => assert_true(project.get("source-driver") == Some("ran"))
        Err(reason) => fail(reason)
      }
    }
    None => fail("missing disassembly driver source")
  }
  @project.register_disassembly_driver_source(
    name="unit-source-driver",
    @project.ProjectDisassemblySource::error("driver unavailable"),
  )
  match @project.find_disassembly_driver_source("unit-source-driver") {
    Some(source) => {
      assert_true(source.values().is_empty())
      assert_true(source.errors() == ["driver unavailable"])
    }
    None => fail("missing overwritten disassembly driver source")
  }
}

///|
test "project disassembly source reconstructor registry keeps checked streams" {
  let reconstructor = @project.ProjectReconstructor::create(project => {
    Ok(project.set("source-reconstructor", "ran"))
  })
  @project.register_reconstructor_source_value(
    name="unit-source-reconstructor",
    reconstructor,
  )
  assert_true(
    @project.reconstructor_source_names().contains("unit-source-reconstructor"),
  )
  match @project.find_reconstructor_source("unit-source-reconstructor") {
    Some(source) => {
      let reconstructors = source.values()
      assert_true(reconstructors.length() == 1)
      match
        reconstructors[0].run(
          @project.Project::empty(@core_theory.Target::unknown()),
        ) {
        Ok(project) =>
          assert_true(project.get("source-reconstructor") == Some("ran"))
        Err(reason) => fail(reason)
      }
    }
    None => fail("missing reconstructor source")
  }
  @project.register_reconstructor_source(
    name="unit-source-reconstructor",
    @project.ProjectDisassemblySource::error("reconstructor unavailable"),
  )
  match @project.find_reconstructor_source("unit-source-reconstructor") {
    Some(source) => {
      assert_true(source.values().is_empty())
      assert_true(source.errors() == ["reconstructor unavailable"])
    }
    None => fail("missing overwritten reconstructor source")
  }
}
