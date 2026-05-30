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
