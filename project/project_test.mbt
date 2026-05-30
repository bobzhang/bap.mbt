///|
fn raw_segment() -> @image.Segment {
  @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x90\xc3",
    executable=true,
  )
}

///|
test "project can be created from image memory" {
  let target = @core_theory.Target::unknown()
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    filename="tiny.bin",
    target~,
  )
  let project = @project.Project::from_image(image)
  assert_true(project.target().is_unknown())
  assert_true(project.filename() == Some("tiny.bin"))
  assert_true(project.image() is Some(_))
  assert_true(project.memory().lookup(0x1000UL).length() == 1)
  assert_true(project.specification().fact_count("arch") == 1)
}

///|
test "project preserves image loader specifications" {
  let target = @core_theory.Target::unknown()
  let spec = @image.OgreDoc::from_target(@core_theory.Target::x86_64())
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [raw_segment()],
    target~,
    spec~,
  )
  let project = @project.Project::from_image(image)
  assert_true(project.specification().fact_count("bits") == 1)
  assert_true(
    project.specification().facts("bits")[0].value("size") == Some("64"),
  )
}

///|
test "project storage and memory tags are persistent updates" {
  let target = @core_theory.Target::unknown()
  let project = @project.Project::empty(target).set("loader", "raw")
  assert_true(project.has("loader"))
  assert_true(project.get("loader") == Some("raw"))
  let replacement = { "filename": "tiny.bin", "loader": "ogre" }
  let replaced = project.with_storage(replacement)
  replacement["loader"] = "mutated"
  assert_true(replaced.get("filename") == Some("tiny.bin"))
  assert_true(replaced.get("loader") == Some("ogre"))
  let cleared = project.del("loader")
  assert_true(!cleared.has("loader"))
  let tagged = cleared.tag_memory(raw_segment().memory(), "code")
  assert_true(tagged.memory().lookup(0x1001UL).length() == 1)
}

///|
test "project maps programs and stores libraries" {
  let target = @core_theory.Target::unknown()
  let sub = @types.Sub::create(name="main")
  let program = @types.Program::create().append_sub(sub)
  let project = @project.Project::empty(target).map_program(_ => program)
  assert_true(project.program().subs().length() == 1)
  let library = @project.Library::create(
    name="libc",
    target~,
    memory=@memory.MemMap::singleton(raw_segment().memory(), "lib-code"),
  )
  let with_library = project.add_library(library)
  assert_true(with_library.libraries().length() == 1)
  assert_true(with_library.libraries()[0].name() == "libc")
  assert_true(
    with_library.libraries()[0].specification().fact_count("arch") == 1,
  )
}

///|
test "project and libraries carry disassembly state" {
  let target = @core_theory.Target::unknown()
  let block = raw_segment().memory()
  let sub = @types.Sub::create(name="entry")
  let disassembly = @project.ProjectDisassemblyState::empty().add_block(block)
  let state = @project.ProjectState::empty()
    .with_disassembly(disassembly)
    .add_subroutine(sub)
  let project = @project.Project::empty(target).with_state(state)
  assert_true(project.state().subroutines().length() == 1)
  assert_true(project.disassembly().block_count() == 1)
  assert_true(project.disassembly().blocks()[0].min_addr() == 0x1000UL)
  let cleared = project.with_disassembly(
    @project.ProjectDisassemblyState::empty(),
  )
  assert_true(cleared.disassembly().block_count() == 0)
  let library = @project.Library::create(name="libstate", target~, state~)
  assert_true(library.state().subroutines().length() == 1)
  assert_true(library.disassembly().block_count() == 1)
}
