///|
test "image reads files on native target" {
  match @image.Image::of_file("moon.mod") {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.data().length() > 0)
      assert_true(image.data()[0] == (47).to_byte())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "image BAP top-level create reads files on native target" {
  match @image.create("moon.mod") {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(@image.data(image).length() > 0)
      assert_true(@image.data(image)[0] == (47).to_byte())
    }
    Err(reason) => fail(reason)
  }
}

///|
test "image named loaders can derive Ogre docs from file paths" {
  let spec = "(declare entry-point (addr int))" +
    " (declare mapped (addr int) (size int) (off int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
    " (entry-point 32)" +
    " (mapped 32 2 0)" +
    " (named-region 32 2 header)" +
    " (segment 32 2 true false false)"
  let loader = @image.ImageLoader::create(from_data=_ => Ok(None), from_file=path => {
    if path != "moon.mod" {
      Err("unexpected loader path")
    } else {
      match parse_spec(spec) {
        Ok(doc) => Ok(Some(doc))
        Err(reason) => Err(reason)
      }
    }
  })
  match @image.register_loader(name="unit-native-ogre-loader", loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.Image::of_file("moon.mod", backend="unit-native-ogre-loader") {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.filename() == Some("moon.mod"))
      assert_true(image.entry_point() == 32UL)
      assert_true(image.segments().length() == 1)
      assert_true(image.segments()[0].addr() == 32UL)
      inspect(image.segments()[0].memory().hexdump(), content="2f 2f")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "image KB loaders can derive Ogre docs from file paths" {
  let spec = "(declare entry-point (addr int))" +
    " (declare mapped (addr int) (size int) (off int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
    " (entry-point 64)" +
    " (mapped 64 2 0)" +
    " (named-region 64 2 kb-file)" +
    " (segment 64 2 true false false)"
  match
    @image.KB::register_loader(
      name="unit-native-kb-ogre-loader",
      from_data=_ => Ok(None),
      from_file=path => {
        if path != "moon.mod" {
          Err("unexpected loader path")
        } else {
          match parse_spec(spec) {
            Ok(doc) => Ok(Some(doc))
            Err(reason) => Err(reason)
          }
        }
      },
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match
    @image.Image::of_file("moon.mod", backend="unit-native-kb-ogre-loader") {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.filename() == Some("moon.mod"))
      assert_true(image.entry_point() == 64UL)
      assert_true(image.segments().length() == 1)
      assert_true(image.segments()[0].name() == "kb-file")
      inspect(image.segments()[0].memory().hexdump(), content="2f 2f")
    }
    Err(reason) => fail(reason)
  }
}
