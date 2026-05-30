///|
test "project symbolizer resolves custom names and fallback names" {
  let symbolizer = @project.ProjectSymbolizer::create(addr => {
    if addr == 0x10UL {
      Some("start")
    } else {
      None
    }
  }).set_path("unit.bin")
  assert_true(symbolizer.path() == Some("unit.bin"))
  assert_true(!symbolizer.is_biased())
  assert_true(symbolizer.run(0x10UL) == Some("start"))
  assert_true(symbolizer.run(0x20UL) == None)
  assert_true(symbolizer.resolve(0x10UL) == "start")
  assert_true(symbolizer.resolve(0x20UL) == "sub_0x20")
  assert_true(@project.ProjectSymbolizer::name_of_addr(0x30UL) == "sub_0x30")
  assert_true(@project.ProjectSymbolizer::name_is_empty("sub_0x30"))
  assert_true(!@project.ProjectSymbolizer::name_is_empty("main"))
}

///|
test "project symbolizer chains first matching source" {
  let first = @project.ProjectSymbolizer::create(addr => {
    if addr == 0x10UL {
      Some("first")
    } else {
      None
    }
  })
  let second = @project.ProjectSymbolizer::create(addr => {
    if addr == 0x10UL {
      Some("second")
    } else if addr == 0x20UL {
      Some("other")
    } else {
      None
    }
  })
  let chain = @project.ProjectSymbolizer::chain([first, second])
  assert_true(chain.resolve(0x10UL) == "first")
  assert_true(chain.resolve(0x20UL) == "other")
  assert_true(chain.resolve(0x40UL) == "sub_0x40")
}

///|
test "project symbolizer builds BAP-style image names" {
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x01\x02\x03",
    executable=true,
  )
  let main_symbol = @image.Symbol::create(
    name="main",
    addr=0x1000UL,
    size=2,
    is_function=true,
  )
  let generated_symbol = @image.Symbol::create(
    name="sub_0x1001",
    addr=0x1001UL,
    size=1,
    is_function=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    symbols=[main_symbol, generated_symbol],
    filename="unit.bin",
  )
  let symbolizer = @project.ProjectSymbolizer::of_image(image)
  assert_true(symbolizer.path() == Some("unit.bin"))
  assert_true(symbolizer.is_biased())
  assert_true(symbolizer.resolve(0x1000UL) == "main")
  assert_true(symbolizer.resolve(0x1001UL) == "sub_0x1001")
}

///|
test "project symbolizer builds names from symbol arrays and projects" {
  let symbols = [
    @image.Symbol::create(name="alpha", addr=0x1200UL),
    @image.Symbol::create(name="beta", addr=0x1210UL),
  ]
  let symbolizer = @project.ProjectSymbolizer::of_symbols(
    symbols,
    path="symbols.bin",
  )
  symbols.push(@image.Symbol::create(name="mutated", addr=0x1220UL))
  assert_true(symbolizer.path() == Some("symbols.bin"))
  assert_true(!symbolizer.is_biased())
  assert_true(symbolizer.resolve(0x1200UL) == "alpha")
  assert_true(symbolizer.resolve(0x1220UL) == "sub_0x1220")
  let project = @project.Project::create(
    target=@core_theory.Target::unknown(),
    filename="manual.bin",
    symbols=[@image.Symbol::create(name="manual", addr=0x1300UL)],
  )
  let project_symbolizer = project.symbolizer()
  assert_true(project_symbolizer.path() == Some("manual.bin"))
  assert_true(!project_symbolizer.is_biased())
  assert_true(project_symbolizer.resolve(0x1300UL) == "manual")
}

///|
test "project symbolizer skips ambiguous image names" {
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x2000UL,
    b"\x01\x02\x03",
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x2000UL,
    endian=LittleEndian,
    [segment],
    symbols=[
      @image.Symbol::create(name="same_addr_a", addr=0x2000UL),
      @image.Symbol::create(name="same_addr_b", addr=0x2000UL),
      @image.Symbol::create(name="same_name", addr=0x2001UL),
      @image.Symbol::create(name="same_name", addr=0x2002UL),
      @image.Symbol::create(name="unique", addr=0x2003UL),
    ],
  )
  let symbolizer = @project.ProjectSymbolizer::of_image(image)
  assert_true(symbolizer.resolve(0x2000UL) == "sub_0x2000")
  assert_true(symbolizer.resolve(0x2001UL) == "sub_0x2001")
  assert_true(symbolizer.resolve(0x2002UL) == "sub_0x2002")
  assert_true(symbolizer.resolve(0x2003UL) == "unique")
}

///|
test "project symbolizer builds roots from named block starts" {
  let symbolizer = @project.ProjectSymbolizer::of_blocks([
    ("foo", 0x30UL, 0x40UL),
    ("bar", 0x80UL, 0x90UL),
    ("foo", 0x20UL, 0x40UL),
    ("same", 0xa0UL, 0xb0UL),
    ("same", 0xc0UL, 0xd0UL),
    ("left", 0xe0UL, 0xf0UL),
    ("right", 0xe0UL, 0xf0UL),
  ])
  assert_true(symbolizer.resolve(0x20UL) == "foo")
  assert_true(symbolizer.resolve(0x80UL) == "bar")
  assert_true(symbolizer.resolve(0xa0UL) == "same")
  assert_true(symbolizer.resolve(0xc0UL) == "sub_0xc0")
  assert_true(symbolizer.resolve(0xe0UL) == "sub_0xe0")
}
