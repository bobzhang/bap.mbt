///|
fn expect_ogre_doc(text : String) -> @image.OgreDoc raise {
  match @image.OgreDoc::from_string(text) {
    Ok(doc) => doc
    Err(reason) => fail(reason)
  }
}

///|
fn assert_ogre_error(text : String) -> Unit raise {
  assert_true(@image.OgreDoc::from_string(text) is Err(_))
}

///|
fn expect_scheme_fact(
  attribute : @image.OgreAttribute,
  values : Array[String],
) -> String raise {
  match attribute.fact(values) {
    Ok(fact) => fact
    Err(reason) => fail(reason)
  }
}

///|
test "ogre documents parse named and positional facts" {
  let doc = expect_ogre_doc(
    "(declare student (name str) (gpa float) (active bool) (id int))" +
    " (student (name \"Joe\\nStudent\") (gpa 3.5) (active true) (id 42))" +
    " (student Ann 4.0 false 7)",
  )
  assert_true(doc.declaration_count() == 1)
  assert_true(doc.fact_count("student") == 2)
  match doc.declaration("student") {
    Some(fields) => {
      assert_true(fields.length() == 4)
      assert_true(fields[0].name() == "name")
      assert_true(fields[0].typ().to_string() == "str")
      assert_true(fields[1].name() == "gpa")
      assert_true(fields[1].typ().to_string() == "float")
      assert_true(fields[2].name() == "active")
      assert_true(fields[2].typ().to_string() == "bool")
      assert_true(fields[3].name() == "id")
      assert_true(fields[3].typ().to_string() == "int")
    }
    None => fail("expected student declaration")
  }
  let facts = doc.facts("student")
  assert_true(facts[0].attribute() == "student")
  assert_true(facts[0].value("name") == Some("Joe\nStudent"))
  assert_true(facts[0].value("gpa") == Some("3.5"))
  assert_true(facts[0].value("active") == Some("true"))
  assert_true(facts[0].value("id") == Some("42"))
  assert_true(facts[1].value("name") == Some("Ann"))
  assert_true(facts[1].value("gpa") == Some("4"))
  assert_true(facts[1].value("active") == Some("false"))
  assert_true(facts[1].value("id") == Some("7"))
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
test "ogre scheme facades render BAP image declarations and facts" {
  assert_true(@image.Scheme::off().name() == "off")
  assert_true(@image.Scheme::off().typ() == OgreInt)
  assert_true(@image.Scheme::value().name() == "value")
  assert_true(@image.Scheme::value().typ() == OgreInt)
  assert_true(@image.Scheme::readable().name() == "r")
  assert_true(@image.Scheme::readable().typ() == OgreBool)
  let segment = @image.Scheme::segment()
  assert_true(segment.name() == "segment")
  assert_true(segment.field_names() == ["addr", "size", "r", "w", "x"])
  inspect(
    segment.declaration(),
    content="(declare segment (addr int) (size int) (r bool) (w bool) (x bool))",
  )
  match segment.fact(["4096", "4", "true", "false", "true"]) {
    Ok(fact) => inspect(fact, content="(segment 4096 4 true false true)")
    Err(reason) => fail(reason)
  }
  let symbol_value = @image.Scheme::symbol_value()
  assert_true(symbol_value.field_names() == ["addr", "value"])
  match symbol_value.fact(["4097", "128"]) {
    Ok(fact) => inspect(fact, content="(symbol-value 4097 128)")
    Err(reason) => fail(reason)
  }
  let named_values : Map[String, String] = {
    "addr": "4096",
    "size": "4",
    "r": "true",
    "w": "false",
    "x": "true",
  }
  match segment.named_fact(named_values) {
    Ok(fact) =>
      inspect(
        fact,
        content="(segment (addr 4096) (size 4) (r true) (w false) (x true))",
      )
    Err(reason) => fail(reason)
  }
  assert_true(segment.fact(["4096"]) is Err(_))
  assert_true(segment.fact(["4096", "4", "yes", "false", "true"]) is Err(_))
  let mapped = @image.Scheme::mapped()
  let attrs = [
    @image.Scheme::arch(),
    @image.Scheme::bits(),
    @image.Scheme::is_little_endian(),
    @image.Scheme::entry_point(),
    mapped,
    @image.Scheme::named_region(),
    segment,
    @image.Scheme::section(),
    @image.Scheme::code_start(),
    @image.Scheme::named_symbol(),
    @image.Scheme::symbol_chunk(),
  ]
  let facts = [
    expect_scheme_fact(@image.Scheme::arch(), ["x86-64"]),
    expect_scheme_fact(@image.Scheme::bits(), ["64"]),
    expect_scheme_fact(@image.Scheme::is_little_endian(), ["true"]),
    expect_scheme_fact(@image.Scheme::entry_point(), ["4098"]),
    expect_scheme_fact(mapped, ["4096", "4", "1"]),
    expect_scheme_fact(@image.Scheme::named_region(), ["4096", "4", "code"]),
    expect_scheme_fact(segment, ["4096", "4", "true", "false", "true"]),
    expect_scheme_fact(@image.Scheme::section(), ["4096", "4"]),
    expect_scheme_fact(@image.Scheme::code_start(), ["4097"]),
    expect_scheme_fact(@image.Scheme::named_symbol(), ["4097", "main"]),
    expect_scheme_fact(@image.Scheme::symbol_chunk(), ["4097", "2", "4097"]),
  ]
  match @image.OgreDoc::from_scheme(attrs, facts~) {
    Ok(doc) => {
      assert_true(doc.declaration_count() == attrs.length())
      assert_true(doc.fact_count("segment") == 1)
      assert_true(doc.facts("arch")[0].value("name") == Some("x86-64"))
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
    Err(reason) => fail(reason)
  }
}
