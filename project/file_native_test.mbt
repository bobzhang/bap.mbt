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
  match
    @project.ProjectInput::binary(target~, filename="moon.mod", base=0x900UL) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("x86_64"))
      assert_true(project.memory().lookup(0x900UL).length() == 1)
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == LittleEndian)
          assert_true(image.segments()[0].name() == "bap.user")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
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
