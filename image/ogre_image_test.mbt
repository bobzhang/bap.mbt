///|
let raw_ogre_spec : String = "(declare arch (name str))" +
  " (declare entry-point (addr int))" +
  " (declare is-little-endian (flag bool))" +
  " (declare mapped (addr int) (size int) (off int))" +
  " (declare named-region (addr int) (size int) (name str))" +
  " (declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
  " (declare section (addr int) (size int))" +
  " (declare code-start (addr int))" +
  " (declare named-symbol (addr int) (name str))" +
  " (declare symbol-chunk (addr int) (size int) (root int))" +
  " (arch x86-64)" +
  " (entry-point 4098)" +
  " (is-little-endian true)" +
  " (mapped 4096 4 1)" +
  " (named-region 4096 4 code)" +
  " (segment 4096 4 true false true)" +
  " (section 4096 4)" +
  " (code-start 4097)" +
  " (named-symbol 4097 main)" +
  " (symbol-chunk 4097 2 4097)"

///|
test "ogre image specs build image metadata" {
  match
    @image.Image::of_ogre_string(
      b"\x00\xaa\xbb\xcc\xdd",
      raw_ogre_spec,
      filename="raw.bin",
    ) {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.filename() == Some("raw.bin"))
      assert_true(image.entry_point() == 4098UL)
      assert_true(image.endian() == LittleEndian)
      match image.target() {
        Some(target) => assert_true(target.matches("x86_64"))
        None => fail("expected target from arch fact")
      }
      let segments = image.segments()
      assert_true(segments.length() == 1)
      assert_true(segments[0].name() == "code")
      assert_true(segments[0].addr() == 4096UL)
      assert_true(segments[0].offset() == 1)
      assert_true(segments[0].is_executable())
      inspect(segments[0].memory().hexdump(), content="aa bb cc dd")
      let sections = image.sections()
      assert_true(sections.length() == 1)
      assert_true(sections[0].name() == "code")
      let symbols = image.symbols()
      assert_true(symbols.length() == 1)
      assert_true(symbols[0].name() == "main")
      assert_true(symbols[0].addr() == 4097UL)
      assert_true(symbols[0].size() == 2)
      assert_true(symbols[0].is_function())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "ogre image specs report unmappable regions as warnings" {
  let spec = raw_ogre_spec.replace(
    old="(mapped 4096 4 1)",
    new="(mapped 4096 4 10)",
  )
  match @image.Image::of_ogre_string(b"\x00", spec) {
    Ok((image, warnings)) => {
      assert_true(image.segments().is_empty())
      assert_true(warnings.length() == 1)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "ogre image specs require entry points" {
  assert_true(
    @image.Image::of_ogre_string(
      b"", "(declare segment (addr int) (size int) (r bool) (w bool) (x bool))",
    )
    is Err(_),
  )
}
