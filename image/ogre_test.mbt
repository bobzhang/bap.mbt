///|
fn expect_ogre_doc(text : String) -> @image.OgreDoc raise {
  match parse_spec(text) {
    Ok(doc) => doc
    Err(reason) => fail(reason)
  }
}

///|
fn assert_ogre_error(text : String) -> Unit raise {
  assert_true(parse_spec(text) is Err(_))
}

///|
test "ogre documents parse named and positional facts" {
  let doc = expect_ogre_doc(
    "(declare student (name str) (gpa float) (active bool) (id int))" +
    " (student (name \"Joe\\nStudent\") (gpa 3.5) (active true) (id 42))" +
    " (student Ann 4.0 false 7)",
  )
  assert_true(doc.declarations() == 1)
  assert_true(doc.facts("student").length() == 2)
  match doc.declaration("student") {
    Some(fields) => {
      assert_true(fields.length() == 4)
      assert_true(fields[0].name == "name")
      assert_true(fields[0].typ.to_string() == "str")
      assert_true(fields[1].name == "gpa")
      assert_true(fields[1].typ.to_string() == "float")
      assert_true(fields[2].name == "active")
      assert_true(fields[2].typ.to_string() == "bool")
      assert_true(fields[3].name == "id")
      assert_true(fields[3].typ.to_string() == "int")
    }
    None => fail("expected student declaration")
  }
  // Ogre lists facts newest first
  let facts = doc.facts("student")
  assert_true(facts[1].get("name") == Some("Joe\nStudent"))
  assert_true(facts[1].get("gpa") == Some("3.5"))
  assert_true(facts[1].get("active") == Some("true"))
  assert_true(facts[1].get("id") == Some("42"))
  assert_true(facts[0].get("name") == Some("Ann"))
  assert_true(facts[0].get("gpa") == Some("4"))
  assert_true(facts[0].get("active") == Some("false"))
  assert_true(facts[0].get("id") == Some("7"))
}

///|
test "ogre documents validate declarations and facts" {
  assert_ogre_error("(student Joe)")
  assert_ogre_error("(declare student (id int))" + " (student nope)")
  assert_ogre_error("(declare student str bool)" + " (student only-one)")
  assert_ogre_error(
    "(declare student (name str) (id int))" + " (student (name Joe) (name Ann))",
  )
  assert_ogre_error("(declare student str)" + " (declare student int)")
}

///|
test "ogre scheme facades describe BAP image attributes" {
  assert_true(@image.Scheme::off().name() == "off")
  assert_true(@image.Scheme::off().header().typ == Int)
  assert_true(@image.Scheme::value().name() == "value")
  assert_true(@image.Scheme::value().header().typ == Int)
  assert_true(@image.Scheme::readable().name() == "r")
  assert_true(@image.Scheme::readable().header().typ == Bool)
  let segment = @image.Scheme::segment()
  assert_true(segment.name() == "segment")
  assert_true(
    segment.signature().map(header => header.name) ==
    ["addr", "size", "r", "w", "x"],
  )
  let doc = @ogre.Doc::empty()
    .put(segment, (4096L, 4L, true, false, true))
    .put(@image.Scheme::symbol_value(), (4097L, 128L))
  inspect(
    doc.to_string(),
    content=(
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(declare symbol-value (addr int) (value int))
      #|
      #|(segment 4096 4 true false true)
      #|(symbol-value 4097 128)
      #|
    ),
  )
  debug_inspect(
    doc.get(segment),
    content=(
      #|[{ addr: 4096, size: 4, info: (true, false, true) }]
    ),
  )
  let provide_all = @ogre.Ogre::all_unit([
    @ogre.provide(@image.Scheme::arch(), "x86-64"),
    @ogre.provide(@image.Scheme::bits(), 64L),
    @ogre.provide(@image.Scheme::is_little_endian(), true),
    @ogre.provide(@image.Scheme::entry_point(), 4098L),
    @ogre.provide(@image.Scheme::mapped(), (4096L, 4L, 1L)),
    @ogre.provide(@image.Scheme::named_region(), (4096L, 4L, "code")),
    @ogre.provide(segment, (4096L, 4L, true, false, true)),
    @ogre.provide(@image.Scheme::section(), (4096L, 4L)),
    @ogre.provide(@image.Scheme::code_start(), 4097L),
    @ogre.provide(@image.Scheme::named_symbol(), (4097L, "main")),
    @ogre.provide(@image.Scheme::symbol_chunk(), (4097L, 2L, 4097L)),
  ])
  let doc = @ogre.exec(provide_all, @ogre.Doc::empty())
  assert_true(doc.declarations() == 11)
  assert_true(doc.facts("segment").length() == 1)
  assert_true(doc.facts("arch")[0].get("name") == Some("x86-64"))
  match @image.Image::from_spec(b"\x00\xaa\xbb\xcc\xdd", doc) {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.entry_point() == 4098UL)
      assert_true(image.segments().length() == 1)
      assert_true(image.segments()[0].name() == "code")
      assert_true(image.symbols()[0].name() == "main")
      inspect(image.segments()[0].memory().hexdump(), content="aa bb cc dd")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "images built from metadata describe themselves with upstream facts" {
  let segment = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x90\x90\xc3",
    offset=16,
    readable=true,
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1001UL,
    endian=LittleEndian,
    [segment],
    sections=[@image.Section::create(name=".text", addr=0x1000UL, size=3)],
    symbols=[
      @image.Symbol::create(
        name="main",
        addr=0x1001UL,
        size=2,
        is_function=true,
      ),
    ],
    target=@core_theory.Target::x86_64(),
  )
  inspect(
    image.spec().to_string(),
    content=(
      #|(declare arch (name str))
      #|(declare bits (size int))
      #|(declare code-start (addr int))
      #|(declare entry-point (addr int))
      #|(declare is-little-endian (flag bool))
      #|(declare mapped (addr int) (size int) (off int))
      #|(declare named-region (addr int) (size int) (name str))
      #|(declare named-symbol (addr int) (name str))
      #|(declare section (addr int) (size int))
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(declare symbol-chunk (addr int) (size int) (root int))
      #|
      #|(arch x86_64)
      #|(bits 64)
      #|(code-start 4097)
      #|(entry-point 4097)
      #|(is-little-endian true)
      #|(mapped 4096 3 16)
      #|(named-region 4096 3 .text)
      #|(named-symbol 4097 main)
      #|(section 4096 3)
      #|(segment 4096 3 true false true)
      #|(symbol-chunk 4097 2 4097)
      #|
    ),
  )
  // the description round-trips through the Ogre loader
  match @image.Image::from_spec(b"", image.spec()) {
    Ok((derived, _)) => {
      assert_true(derived.entry_point() == 0x1001UL)
      assert_true(derived.sections()[0].name() == ".text")
      assert_true(derived.symbols()[0].name() == "main")
      assert_true(derived.symbols()[0].size() == 2)
    }
    Err(reason) => fail(reason)
  }
}
