///|
test "names preserve packages and escaped separators" {
  let name = @knowledge.Name::read("core:target\\:x")
  inspect(name.pkg(), content="core")
  inspect(name.unqualified(), content="target:x")
  inspect(name.show(), content="core:target\\:x")
  inspect(
    @knowledge.Name::read("plain", pkg="local").show(),
    content="local:plain",
  )
}

///|
test "flat domains keep bottom and reject conflicting facts" {
  let domain = @knowledge.Domain::flat(
    @knowledge.Name::create("color", pkg="test"),
    value => value,
    empty="",
  )
  assert_true(domain.order("", "red") == Less)
  assert_true(domain.join("", "red") == Ok("red"))
  assert_true(domain.join("red", "red") == Ok("red"))
  assert_true(domain.join("red", "blue") is Err(_))
}

///|
test "optional domains lift base order and joins" {
  let base = @knowledge.Domain::bool(
    @knowledge.Name::create("flag", pkg="test"),
  )
  let opt = @knowledge.Domain::optional(base)
  assert_true(opt.order(None, Some(true)) == Less)
  assert_true(opt.join(None, Some(true)) == Ok(Some(true)))
  assert_true(opt.join(Some(false), Some(true)) == Ok(Some(true)))
}

///|
test "translated BAP powerset domains join facts by union" {
  let domain = @knowledge.Domain::powerset(
    @knowledge.Name::create("aliases", pkg="test"),
    value => value,
  )
  assert_true(domain.order([], ["main"]) == Less)
  assert_true(domain.order(["main"], []) == Greater)
  assert_true(domain.order(["main"], ["helper"]) == Incomparable)
  assert_true(
    domain.join(["main", "start"], ["main", "helper"]) ==
    Ok(["main", "start", "helper"]),
  )
  inspect(domain.inspect(["main", "helper"]), content="[main, helper]")

  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("aliased-program", pkg="test"),
    sort="unit",
  )
  let slot = cls.property(
    name=@knowledge.Name::create("aliases", pkg="test"),
    domain~,
  )
  let object = @knowledge.State::new().create(cls)
  let facts = @knowledge.FactTable::new(slot)
  assert_true(facts.collect(object) == Some([]))
  assert_true(facts.provide(object, ["main", "main"]) == Ok(["main"]))
  assert_true(facts.provide(object, ["entry", "main"]) == Ok(["main", "entry"]))
  assert_true(facts.has(object))
}

///|
test "classes slots and fact tables accumulate monotone facts" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("seen", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("seen", pkg="test"),
    domain~,
  )
  let state = @knowledge.State::new()
  let object = state.create(cls)
  let facts = @knowledge.FactTable::new(slot)
  assert_true(facts.collect(object) == Some(false))
  assert_true(facts.provide(object, true) == Ok(true))
  assert_true(facts.provide(object, false) == Ok(true))
  assert_true(facts.collect(object) == Some(true))
}

///|
test "translated BAP fact require fails on empty values" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("required-fact", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("live", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("live", pkg="test"),
    domain~,
  )
  let facts = @knowledge.FactTable::new(slot)
  let object = @knowledge.State::new().create(cls)
  assert_true(!facts.has(object))
  assert_true(facts.require(object) is Err(_))
  assert_true(facts.provide(object, true) == Ok(true))
  assert_true(facts.has(object))
  assert_true(facts.require(object) == Ok(true))
  let null = @knowledge.Object::null(cls)
  assert_true(!facts.has(null))
  assert_true(facts.require(null) is Err(_))
}

///|
test "translated BAP null objects collect empty facts and discard provides" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("null-object", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("visited", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("visited", pkg="test"),
    domain~,
  )
  let facts = @knowledge.FactTable::new(slot)
  let null = @knowledge.Object::null(cls)
  assert_true(null.is_null())
  assert_true(facts.collect(null) == Some(false))
  assert_true(facts.provide(null, true) == Ok(false))
  assert_true(facts.collect(null) == Some(false))
  let object = @knowledge.State::new().create(cls)
  assert_true(facts.provide(object, true) == Ok(true))
  assert_true(facts.collect(object) == Some(true))
}
