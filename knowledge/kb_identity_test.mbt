///|
test "redeclaring a property with the same domain yields the same slot" {
  let cls = kb_class("ident")
  let dom = int_domain("ident-v")
  let first = cls.property(name=kb_name("ident-v"), domain=dom)
  let again = cls.property(name=kb_name("ident-v"), domain=dom)
  ignore(again.promise((_, _) => 7))
  // rules and facts are shared between the declarations
  assert_eq(first.promise_count(), 1)
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  assert_eq(kb.collect(first, obj), 7)
  kb.provide(again, obj, 9)
  assert_eq(kb.current(first, obj), 9)
  assert_eq(@knowledge.Value::empty(cls).put(first, 3).get(again), 3)
  // redeclaring through a class value with a different sort is the same
  let refined : @knowledge.Class[Unit, String] = cls.refine(sort="s")
  let third = refined.property(name=kb_name("ident-v"), domain=dom)
  assert_eq(kb.current(third, obj), 9)
  // a different domain object cannot be proven to have the same type: the
  // new declaration shadows the previous one with a fresh slot
  let shadow = cls.property(
    name=kb_name("ident-v"),
    domain=int_domain("ident-v"),
  )
  assert_eq(shadow.promise_count(), 0)
  assert_eq(kb.current(shadow, obj), 0)
  assert_eq(kb.current(first, obj), 9)
}

///|
test "class equality witnesses cast objects" {
  let cls = kb_class("castable")
  let same : @knowledge.Class[String, Int] = @knowledge.Class::create(
    name=kb_name("castable"),
    sort=1,
  )
  let other = kb_class("not-castable")
  assert_true(cls.equal(other) is None)
  let witness = cls.assert_equal(same)
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  let cast : @knowledge.Object[String] = @knowledge.Object::cast(witness, obj)
  assert_eq(cast.id(), obj.id())
  let back = @knowledge.Object::cast(witness.invert(), cast)
  assert_true(back == obj)
  // objects are comparable, hashable and persistent
  let second = kb.create(cls)
  assert_true(obj < second)
  let table : Map[@knowledge.Object[Unit], String] = Map([])
  table[obj] = "first"
  table[second] = "second"
  assert_eq(table.get(obj), Some("first"))
  let io = @knowledge.Object::persistent(cls)
  assert_true(io.decode(io.encode(second)).unwrap() == second)
  assert_true(
    io.decode(io.encode(@knowledge.Object::null(cls))).unwrap().is_null(),
  )
}
