///|
test "project input loaders read files on native target" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-file-native",
    extensions=["mod"],
    priority=10,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x1000UL,
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.ProjectInput::load_file_for_filename("moon.mod") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1000UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectInput::file(filename="moon.mod") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1000UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.Project::load_file_for_filename("moon.mod") {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1000UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.Project::file(filename="moon.mod") {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1000UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input path loaders receive filenames on native target" {
  let seen_path : Ref[String] = Ref("")
  match
    @project.ProjectInput::register_file_loader(
      name="unit-project-path-native",
      description="BAP-style filename loader",
      extensions=["missing"],
      priority=20,
      load=path => {
        seen_path.val = path
        Ok(
          @project.ProjectInput::from_bytes(
            target=@core_theory.Target::unknown(),
            b"\x7f",
            endian=LittleEndian,
            base=0x7700UL,
            filename="loaded:" + path,
          ),
        )
      },
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::load_file(
      "does-not-exist.unit-project-path",
      loader="unit-project-path-native",
    ) {
    Ok(input) => {
      assert_true(seen_path.val == "does-not-exist.unit-project-path")
      let project = @project.Project::from_input(input)
      assert_true(
        project.filename() == Some("loaded:does-not-exist.unit-project-path"),
      )
      assert_true(project.memory().lookup(0x7700UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectInput::find_loader("unit-project-path-native") {
    Some(loader) => {
      assert_true(loader.description() == "BAP-style filename loader")
      assert_true(loader.extensions() == ["missing"])
      assert_true(loader.priority() == 20)
      assert_true(loader.load(b"\x00") is Err(_))
    }
    None => fail("expected filename loader")
  }
}

///|
test "project raw file input uses target endian on native target" {
  let target = @core_theory.Target::sparc()
  match
    @project.ProjectInput::raw_file(
      "moon.mod",
      target~,
      base=0x500UL,
      offset=1,
      length=2,
      entry=0x501UL,
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x500UL).length() == 1)
      assert_true(project.memory().lookup(0x502UL).is_empty())
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == BigEndian)
          assert_true(image.entry_point() == 0x501UL)
          assert_true(image.segments()[0].offset() == 1)
          assert_true(image.segments()[0].name() == "bap.user")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
  }
  match
    @project.Project::raw_file(
      "moon.mod",
      target~,
      base=0x500UL,
      offset=1,
      length=2,
      entry=0x501UL,
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x500UL).length() == 1)
      assert_true(project.memory().lookup(0x502UL).is_empty())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project binary input is raw file loading with explicit target" {
  let target = @core_theory.Target::x86_64()
  let arch_sizes = []
  let spec_counts = []
  let arch_stream = @project.ProjectInfo::arch()
  let spec_stream = @project.ProjectInfo::spec()
  let arch_id = arch_stream.subscribe(arch => {
    arch_sizes.push(arch.code_addr_size())
  })
  let spec_id = spec_stream.subscribe(spec => {
    spec_counts.push(spec.declaration_count())
  })
  match
    @project.ProjectInput::binary(target~, filename="moon.mod", base=0x900UL) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      arch_stream.unsubscribe(arch_id)
      spec_stream.unsubscribe(spec_id)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("x86_64"))
      assert_true(project.specification().declaration_count() == 6)
      assert_true(project.memory().lookup(0x900UL).length() == 1)
      assert_true(arch_sizes == [64])
      assert_true(spec_counts == [6])
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == LittleEndian)
          assert_true(image.segments()[0].name() == "bap.user")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => {
      arch_stream.unsubscribe(arch_id)
      spec_stream.unsubscribe(spec_id)
      fail(reason)
    }
  }
  match @project.Project::binary(target~, filename="moon.mod", base=0x900UL) {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("x86_64"))
      assert_true(project.memory().lookup(0x900UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disasm of_file uses explicit loader on native target" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-disasm-file-native",
    extensions=["mod"],
    priority=20,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x1200UL,
          filename="moon.mod",
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectDisasm::of_file(
      "moon.mod",
      loader="unit-project-disasm-file-native",
      backend="raw-bytes",
    ) {
    Ok(disasm) => {
      assert_true(disasm.project().filename() == Some("moon.mod"))
      assert_true(disasm.disassembly().instruction_count() > 0)
      assert_true(disasm.project().get("disassembler") == Some("raw-bytes"))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project create file named uses loader and source registries on native target" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-create-file-native",
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x2600UL,
          filename="moon.mod",
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  @project.register_disassembly_driver_source_value(
    name="unit-project-create-file-driver",
    @project.ProjectDisassemblyDriver::memory_blocks(),
  )
  @project.register_symbolizer_source_value(
    name="unit-project-create-file-symbolizer",
    @project.ProjectSymbolizer::create(addr => {
      if addr == 0x2600UL {
        Some("file_entry")
      } else {
        None
      }
    }).set_path("moon.mod"),
  )
  match
    @project.Project::create_file_named(
      filename="moon.mod",
      loader="unit-project-create-file-native",
      driver_source="unit-project-create-file-driver",
      symbolizer="unit-project-create-file-symbolizer",
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.get("disassembler") == Some("memory-blocks"))
      assert_true(project.program().subs()[0].sub_name() == "file_entry")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project file input loads deduplicated libraries with the same loader" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-library-native",
    load=data => {
      let base = if data.length() > 0 && data[0] == b'#' {
        0x2200UL
      } else {
        0x1100UL
      }
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base~,
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::file(
      filename="moon.mod",
      loader="unit-project-library-native",
      libraries=["README.mbt.md", "README.mbt.md", "moon.mod"],
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1100UL).length() == 1)
      let libraries = project.libraries()
      assert_true(libraries.length() == 1)
      assert_true(libraries[0].name() == "README.mbt.md")
      assert_true(libraries[0].memory().lookup(0x2200UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.Project::file(
      filename="moon.mod",
      loader="unit-project-library-native",
      libraries=["README.mbt.md", "README.mbt.md", "moon.mod"],
    ) {
    Ok(project) => {
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.memory().lookup(0x1100UL).length() == 1)
      let libraries = project.libraries()
      assert_true(libraries.length() == 1)
      assert_true(libraries[0].name() == "README.mbt.md")
      assert_true(libraries[0].memory().lookup(0x2200UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}
