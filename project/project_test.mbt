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
}

///|
test "project storage and memory tags are persistent updates" {
  let target = @core_theory.Target::unknown()
  let project = @project.Project::empty(target).set("loader", "raw")
  assert_true(project.has("loader"))
  assert_true(project.get("loader") == Some("raw"))
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
}
