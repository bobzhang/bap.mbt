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
}

///|
test "project raw file input uses target endian on native target" {
  let target = @core_theory.Target::sparc()
  match @project.ProjectInput::raw_file("moon.mod", target~, base=0x500UL) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("moon.mod"))
      assert_true(project.target().matches("sparc"))
      assert_true(project.memory().lookup(0x500UL).length() == 1)
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == BigEndian)
          assert_true(image.entry_point() == 0x500UL)
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
  }
}
