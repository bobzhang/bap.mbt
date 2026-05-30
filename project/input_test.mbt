///|
test "project input from bytes builds raw memory image" {
  let target = @core_theory.Target::unknown()
  let input = @project.ProjectInput::from_bytes(
    target~,
    b"\x01\x02\x03",
    endian=LittleEndian,
    base=0x200UL,
    filename="raw.bin",
  )
  let project = @project.Project::from_input(input)
  assert_true(project.filename() == Some("raw.bin"))
  assert_true(project.memory().lookup(0x201UL).length() == 1)
  assert_true(project.image() is Some(_))
}

///|
test "project raw bytes reject empty input and use target metadata" {
  let target = @core_theory.Target::sparc()
  assert_true(@project.ProjectInput::raw_bytes(target~, b"") is Err(_))
  match
    @project.ProjectInput::raw_bytes(
      target~,
      b"\x01\x02",
      base=0x300UL,
      filename="raw.bin",
    ) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("raw.bin"))
      assert_true(project.memory().lookup(0x300UL).length() == 1)
      match project.image() {
        Some(image) => {
          assert_true(image.endian() == BigEndian)
          let segments = image.segments()
          assert_true(segments.length() == 1)
          assert_true(segments[0].name() == "bap.user")
        }
        None => fail("expected raw image")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input finish hook can finalize project storage" {
  let target = @core_theory.Target::unknown()
  let input = @project.ProjectInput::custom(target~, finish=project => {
    project.set("finished", "true")
  })
  let project = @project.Project::from_input(input)
  assert_true(project.get("finished") == Some("true"))
}

///|
test "project input loaders register and load bytes" {
  let loader = @project.ProjectInputLoader::create(
    name="unit-project-raw",
    description="raw project input",
    extensions=["raw"],
    priority=10,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x40UL,
        ),
      )
    },
  )
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_input_loader("unit-project-raw") is Some(_))
  assert_true(@project.available_input_loaders().contains("unit-project-raw"))
  assert_true(loader.description() == "raw project input")
  assert_true(loader.extensions() == ["raw"])
  assert_true(loader.priority() == 10)
  assert_true(loader.supports_extension("raw"))
  match @project.ProjectInput::load(b"\xff", loader="unit-project-raw") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x40UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_input_loader(loader) is Err(_))
}

///|
fn unit_project_image_backend() -> @image.ImageBackend {
  @image.ImageBackend::create(
    name="unit-project-image-backend",
    description="project image fallback",
    extensions=["pimg"],
    priority=10,
    load=data => {
      let segment = @image.Segment::create(
        name=".image",
        endian=LittleEndian,
        addr=0x440UL,
        data,
        readable=true,
        executable=true,
      )
      Ok(
        (
          @image.Image::from_segments(entry=0x440UL, endian=LittleEndian, [
            segment,
          ]),
          [],
        ),
      )
    },
  )
}

///|
test "project input loading falls back to image backends" {
  let backend = unit_project_image_backend()
  match @image.register_backend(name=backend.name(), backend) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.ProjectInput::load(b"\x7f", loader=backend.name()) {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match
    @project.ProjectInput::load_for_filename(b"\x7f", filename="sample.pimg") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.filename() == Some("sample.pimg"))
      assert_true(project.memory().lookup(0x440UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project input loaders resolve by filename extension priority" {
  let low = @project.ProjectInputLoader::create(
    name="unit-project-low-priority",
    extensions=["unit"],
    priority=1,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x10UL,
        ),
      )
    },
  )
  let high = @project.ProjectInputLoader::create(
    name="unit-project-high-priority",
    extensions=["unit"],
    priority=100,
    load=data => {
      Ok(
        @project.ProjectInput::from_bytes(
          target=@core_theory.Target::unknown(),
          data,
          endian=LittleEndian,
          base=0x90UL,
        ),
      )
    },
  )
  match @project.register_input_loader(low) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_input_loader(high) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.input_loader_names_for_extension("unit") ==
    ["unit-project-high-priority", "unit-project-low-priority"],
  )
  match
    @project.ProjectInput::load_for_filename(b"\x01", filename="sample.UNIT") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x90UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @project.ProjectInput::load_for_filename(b"", filename="no_extension")
    is Err(_),
  )
}

///|
test "project input file loading reports read errors" {
  assert_true(
    @project.ProjectInput::load_file(
      "__bap_mbt_missing_project__",
      loader="unit-project-raw",
    )
    is Err(_),
  )
}
