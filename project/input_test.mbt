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
  let loader = @project.ProjectInputLoader::create(name="unit-project-raw", load=data => {
    Ok(
      @project.ProjectInput::from_bytes(
        target=@core_theory.Target::unknown(),
        data,
        endian=LittleEndian,
        base=0x40UL,
      ),
    )
  })
  match @project.register_input_loader(loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.find_input_loader("unit-project-raw") is Some(_))
  assert_true(@project.available_input_loaders().contains("unit-project-raw"))
  match @project.ProjectInput::load(b"\xff", loader="unit-project-raw") {
    Ok(input) => {
      let project = @project.Project::from_input(input)
      assert_true(project.memory().lookup(0x40UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_input_loader(loader) is Err(_))
}
