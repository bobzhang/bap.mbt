///|
test "project rooter creates unions and keeps path metadata" {
  let left = @project.ProjectRooter::create(
    [0x10UL, 0x20UL, 0x10UL],
    path="left.bin",
    biased=true,
  )
  let right = @project.ProjectRooter::create([0x20UL, 0x30UL]).set_path(
    "right.bin",
  )
  let combined = left.union(right)
  let roots = combined.roots()
  assert_true(roots.length() == 3)
  assert_true(roots[0] == 0x10UL)
  assert_true(roots[1] == 0x20UL)
  assert_true(roots[2] == 0x30UL)
  assert_true(combined.contains(0x30UL))
  assert_true(combined.path() == Some("left.bin"))
  assert_true(combined.is_biased())
  assert_true(@project.ProjectRooter::empty().roots().is_empty())
}

///|
test "project rooter builds BAP-style image roots" {
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x01\x02\x03\x04\x05",
    executable=true,
  )
  let function_symbol = @image.Symbol::create(
    name="main",
    addr=0x1002UL,
    size=2,
    is_function=true,
  )
  let data_symbol = @image.Symbol::create(name="table", addr=0x1004UL, size=1)
  let image = @image.Image::from_segments(
    entry=0x1001UL,
    endian=LittleEndian,
    [segment],
    symbols=[function_symbol, data_symbol],
    filename="unit.bin",
  )
  let rooter = @project.ProjectRooter::of_image(image)
  let roots = rooter.roots()
  assert_true(roots.length() == 3)
  assert_true(roots[0] == 0x1001UL)
  assert_true(roots[1] == 0x1002UL)
  assert_true(roots[2] == 0x1004UL)
  assert_true(rooter.path() == Some("unit.bin"))
  assert_true(rooter.is_biased())
  match rooter.image_blocks(image) {
    Ok(blocks) => {
      assert_true(blocks.length() == 3)
      assert_true(blocks[0].min_addr() == 0x1001UL)
      inspect(blocks[0].hexdump(), content="02 03 04 05")
      assert_true(blocks[2].min_addr() == 0x1004UL)
      inspect(blocks[2].hexdump(), content="05")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project rooter builds roots from symbol arrays and projects" {
  let symbols = [
    @image.Symbol::create(name="alpha", addr=0x1200UL),
    @image.Symbol::create(name="beta", addr=0x1210UL),
  ]
  let rooter = @project.ProjectRooter::of_symbols(
    symbols,
    entry=0x1100UL,
    path="symbols.bin",
    biased=true,
  )
  symbols.push(@image.Symbol::create(name="mutated", addr=0x1220UL))
  let roots = rooter.roots()
  assert_true(roots.length() == 3)
  assert_true(roots[0] == 0x1100UL)
  assert_true(roots[1] == 0x1200UL)
  assert_true(roots[2] == 0x1210UL)
  assert_true(rooter.path() == Some("symbols.bin"))
  assert_true(rooter.is_biased())
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1300UL,
    b"\x01\x02\x03",
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1300UL,
    endian=LittleEndian,
    [segment],
    filename="image.bin",
  )
  let replacement = [
    @image.Symbol::create(name="replacement", addr=0x1302UL, size=1),
  ]
  let project = @project.Project::from_image(image).with_symbols(replacement)
  let project_rooter = project.rooter()
  let project_roots = project_rooter.roots()
  assert_true(project_roots.length() == 2)
  assert_true(project_roots[0] == 0x1300UL)
  assert_true(project_roots[1] == 0x1302UL)
  assert_true(project_rooter.path() == Some("image.bin"))
  assert_true(project_rooter.is_biased())
}

///|
test "project rooter builds roots from named block starts" {
  let rooter = @project.ProjectRooter::of_blocks([
    ("foo", 0x30UL, 0x40UL),
    ("bar", 0x80UL, 0x90UL),
    ("foo", 0x20UL, 0x40UL),
  ])
  let roots = rooter.roots()
  assert_true(roots.length() == 2)
  assert_true(roots[0] == 0x20UL)
  assert_true(roots[1] == 0x80UL)
}
