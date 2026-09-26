///|
test "enumerations declare, read and order their elements" {
  let e = @knowledge.Enum::new()
  let red = e.declare_element("red", pkg="color")
  assert_eq(red.show(), "color:red")
  assert_true(e.read("color:red").equal(red))
  assert_true(e.read("red", pkg="color").equal(red))
  assert_true(e.is_unknown(e.unknown()))
  assert_eq(e.members().map(x => x.show()), [":unknown", "color:red"])
  let failed = try e.declare_element("red", pkg="color") catch {
    @knowledge.Failure(_) => true
    _ => false
  } noraise {
    _ => false
  }
  assert_true(failed)
  let unknown_read = try e.read("blue") catch {
    @knowledge.Failure(_) => true
    _ => false
  } noraise {
    _ => false
  }
  assert_true(unknown_read)
  let dom = e.domain()
  assert_true(dom.is_empty(e.unknown()))
  assert_true(dom.order(e.unknown(), red) == Less)
  assert_eq(e.persistent().encode(red), "color:red")
}

///|
test "refining a class keeps its identity" {
  let cls = kb_class("refined")
  let slot = cls.property(name=kb_name("refined-v"), domain=int_domain("v"))
  let refined : @knowledge.Class[Unit, String] = cls.refine(sort="bits")
  assert_true(refined.same(cls))
  let kb = @knowledge.State::new()
  let obj = kb.create(refined)
  kb.provide(slot, obj, 3)
  assert_eq(kb.collect(slot, obj), 3)
  assert_eq(kb.objects(cls).length(), 1)
}
