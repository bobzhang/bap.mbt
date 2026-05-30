///|
let raw_ogre_spec : String = "(declare arch (name str))" +
  " (declare bits (size int))" +
  " (declare format (name str))" +
  " (declare system (name str))" +
  " (declare abi (name str))" +
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
  " (bits 64)" +
  " (format elf)" +
  " (system linux)" +
  " (abi sysv)" +
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
      let spec = image.spec()
      assert_true(spec.fact_count("entry-point") == 1)
      assert_true(spec.fact_count("arch") == 1)
      assert_true(spec.facts("entry-point")[0].value("addr") == Some("4098"))
      match image.target() {
        Some(target) => {
          assert_true(target.matches("x86_64"))
          assert_true(target.bits() == 64)
          assert_true(target.endianness().to_string() == "little")
          assert_true(target.system().to_string() == "linux")
          assert_true(target.abi().to_string() == "sysv")
          assert_true(target.filetype().to_string() == "elf")
        }
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
test "ogre image specs refine unknown targets from metadata facts" {
  let spec = "(declare bits (size int))" +
    " (declare format (name str))" +
    " (declare system (name str))" +
    " (declare abi (name str))" +
    " (declare entry-point (addr int))" +
    " (declare is-little-endian (flag bool))" +
    " (bits 32)" +
    " (format mach-o)" +
    " (system macos)" +
    " (abi system-v)" +
    " (entry-point 0)" +
    " (is-little-endian false)"
  match @image.Image::of_ogre_string(b"", spec) {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.endian() == BigEndian)
      match image.target() {
        Some(target) => {
          assert_true(target.matches("unknown"))
          assert_true(target.bits() == 32)
          assert_true(target.endianness().to_string() == "big")
          assert_true(target.system().to_string() == "darwin")
          assert_true(target.abi().to_string() == "sysv")
          assert_true(target.filetype().to_string() == "macho")
        }
        None => fail("expected target from metadata")
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "ogre image specs build executable segments from code regions" {
  let spec = "(declare entry-point (addr int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare code-region (addr int) (size int) (off int))" +
    " (entry-point 8192)" +
    " (named-region 8192 3 text)" +
    " (code-region 8192 3 1)"
  match @image.Image::of_ogre_string(b"\x00\x11\x22\x33\x44", spec) {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      let segments = image.segments()
      assert_true(segments.length() == 1)
      assert_true(segments[0].name() == "text")
      assert_true(segments[0].addr() == 8192UL)
      assert_true(segments[0].offset() == 1)
      assert_true(segments[0].is_readable())
      assert_true(!segments[0].is_writable())
      assert_true(segments[0].is_executable())
      inspect(segments[0].memory().hexdump(), content="11 22 33")
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
