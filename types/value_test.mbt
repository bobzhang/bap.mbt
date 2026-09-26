///|
let test_int_tag : @types.Tag[Int] = @types.Tag::register(
  name="test-int",
  uuid="b3f1c2a0-0000-4000-8000-000000000001",
  encode=x => x.to_string(),
  decode=text => {
    try @string.parse_int(text) catch {
      _ => None
    } noraise {
      x => Some(x)
    }
  },
)

///|
let test_string_tag : @types.Tag[String] = @types.Tag::register(
  name="test-string",
  uuid="b3f1c2a0-0000-4000-8000-000000000002",
  encode=x => x,
  decode=x => Some(x),
)

///|
priv struct TestPoint {
  x : Int
  y : Int
}

///|
let test_point_tag : @types.Tag[TestPoint] = @types.Tag::register_with(
  name="test-point",
  uuid="b3f1c2a0-0000-4000-8000-000000000003",
  show=p => "(\{p.x}, \{p.y})",
  compare=(a, b) => {
    let order = a.x.compare(b.x)
    if order != 0 {
      order
    } else {
      a.y.compare(b.y)
    }
  },
)

///|
test "tagged values round trip through their tags" {
  let v = @types.Value::create(test_int_tag, 42)
  assert_eq(v.get(test_int_tag), Some(42))
  assert_eq(v.get(test_string_tag), None)
  assert_true(v.has_tag(test_int_tag))
  assert_true(!v.has_tag(test_string_tag))
  assert_eq(v.get_exn(test_int_tag), 42)
  inspect(v.tagname(), content="test-int")
  inspect(v.typeid(), content="b3f1c2a0-0000-4000-8000-000000000001:test-int")
  inspect(v, content="42")
  let p = @types.Value::create(test_point_tag, { x: 1, y: 2, })
  inspect(p, content="(1, 2)")
  assert_true(p.get(test_point_tag) is Some({ x: 1, y: 2, }))
  assert_true(p.get(test_int_tag) is None)
  // the tag cell is left clean, so nested projections are independent
  let q = @types.Value::create(test_int_tag, 7)
  assert_eq((v.get_exn(test_int_tag), q.get_exn(test_int_tag)), (42, 7))
  inspect(test_int_tag.name(), content="test-int")
  inspect(test_int_tag.pkg(), content="bap")
  assert_true(test_int_tag.same(test_int_tag))
  assert_true(!test_int_tag.same(test_string_tag))
}

///|
test "tagged values compare by tag and payload" {
  let a = @types.Value::create(test_int_tag, 1)
  let b = @types.Value::create(test_int_tag, 2)
  let s = @types.Value::create(test_string_tag, "x")
  assert_true(a < b)
  assert_true(a == @types.Value::create(test_int_tag, 1))
  assert_true(a != s)
  assert_true(a.compare(s) == -s.compare(a))
}

///|
test "tagged values serialize through registered tags" {
  let v = @types.Value::create(test_int_tag, 42)
  let (typeid, data) = v.encode().unwrap()
  inspect(data, content="42")
  match @types.Value::decode(typeid, data) {
    Some(restored) => assert_eq(restored.get(test_int_tag), Some(42))
    None => fail("value was not restored")
  }
  assert_true(@types.Value::decode("unknown:tag", "1") is None)
  // tags without codecs can't be serialized
  let p = @types.Value::create(test_point_tag, { x: 1, y: 2, })
  assert_true(p.encode() is None)
  assert_true(@types.Value::registered_typeids().contains(typeid))
}

///|
test "value match dispatches on tags" {
  let m = @types.ValueMatch::default(() => "other")
    .case(test_int_tag, x => "int \{x}")
    .case(test_string_tag, x => "string \{x}")
  inspect(@types.Value::create(test_int_tag, 3).switch(m), content="int 3")
  inspect(
    m.select(@types.Value::create(test_string_tag, "s")),
    content="string s",
  )
  inspect(
    m.select(@types.Value::create(test_point_tag, { x: 0, y: 0, })),
    content="other",
  )
}

///|
test "dictionaries hold one value per tag" {
  let d = @types.Dict::empty()
  assert_true(d.is_empty())
  let d = d.set(test_int_tag, 1).set(test_string_tag, "one")
  assert_eq(d.length(), 2)
  assert_eq(d.find(test_int_tag), Some(1))
  assert_eq(d.find(test_string_tag), Some("one"))
  assert_true(d.find(test_point_tag) is None)
  assert_true(d.mem(test_int_tag))
  assert_true(d.add(test_int_tag, 2) is None)
  let d2 = d.set(test_int_tag, 2)
  assert_eq(d2.find(test_int_tag), Some(2))
  assert_eq(d.find(test_int_tag), Some(1))
  let d3 = d2.change(test_int_tag, x => x.map(x => x + 10))
  assert_eq(d3.find(test_int_tag), Some(12))
  let d4 = d3.change(test_int_tag, _ => None)
  assert_true(!d4.mem(test_int_tag))
  assert_eq(d4.remove(test_string_tag).length(), 0)
  assert_eq(d.filter(v => v.has_tag(test_string_tag)).length(), 1)
  assert_eq(d.data().length(), 2)
  assert_true(
    d == @types.Dict::empty().set(test_string_tag, "one").set(test_int_tag, 1),
  )
  assert_true(d != d2)
  inspect(d, content="{test-int: 1, test-string: one}")
}

///|
test "terms store typed attributes" {
  let term = @types.Term::create(())
  let term = term.set_tag(test_int_tag, 5)
  assert_eq(term.get_tag(test_int_tag), Some(5))
  assert_eq(term.get_attr("test-int"), Some("5"))
  assert_true(term.has_tag(test_int_tag))
  assert_true(!term.del_tag(test_int_tag).has_tag(test_int_tag))
  // string attributes are visible through a tag of the same name
  let term = term.set_attr(@types.Attr::new(key="test-string", value="hi"))
  assert_eq(term.get_tag(test_string_tag), Some("hi"))
  // tags without decoders store the printed payload
  let term = term.set_tag(test_point_tag, { x: 3, y: 4, })
  assert_eq(term.get_attr("test-point"), Some("(3, 4)"))
  assert_true(term.get_tag(test_point_tag) is None)
}
