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
fn optional_string_equal(lhs : String?, rhs : String?) -> Bool {
  lhs == rhs
}

///|
fn inspect_optional_string(value : String?) -> String {
  match value {
    Some(text) => "some(\{text})"
    None => "none"
  }
}

///|
fn register_test_agent(
  name : String,
  reliability : @knowledge.AgentReliability,
) -> @knowledge.Agent raise {
  match @knowledge.Agent::register(name, pkg="test", reliability~) {
    Ok(agent) => agent
    Err(reason) => fail(reason)
  }
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
test "translated BAP opinion domains resolve by agent reliability" {
  let weak = register_test_agent("opinion-weak", Unreliable)
  let weak_peer = register_test_agent("opinion-weak-peer", Unreliable)
  let strong = register_test_agent("opinion-strong", Reliable)
  let mutable = register_test_agent("opinion-mutable", Unreliable)
  assert_true(weak.name().show() == "test:opinion-weak")
  assert_true(weak.weight() == 1)
  assert_true(mutable.set_reliability(Authorative) == Ok(()))
  assert_true(mutable.weight() == 16)

  let empty_name : String? = None
  let domain = @knowledge.Domain::opinions(
    @knowledge.Name::create("possible-name", pkg="test"),
    empty=empty_name,
    equal=optional_string_equal,
    inspect=inspect_optional_string,
  )
  let weak_opinion = @knowledge.Opinions::empty(
    empty=empty_name,
    equal=optional_string_equal,
    inspect=inspect_optional_string,
  ).add(weak, Some("helper"))
  let strong_opinion = weak_opinion.add(strong, Some("main"))
  assert_true(domain.order(weak_opinion, strong_opinion) == Less)
  assert_true(strong_opinion.choice() == Some("main"))
  inspect(strong_opinion.inspect(), content="[some(helper), some(main)]")

  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("opinion-program", pkg="test"),
    sort="unit",
  )
  let slot = cls.property(
    name=@knowledge.Name::create("possible-name", pkg="test"),
    domain~,
  )
  let object = @knowledge.State::new().create(cls)
  let facts = @knowledge.FactTable::new(slot)
  assert_true(facts.resolve(object) == Ok(None))
  match facts.suggest(weak, object, None) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(facts.resolve(object) == Ok(None))
  match facts.suggest(weak, object, Some("helper")) {
    Ok(opinions) => assert_true(opinions.entries().length() == 1)
    Err(reason) => fail(reason)
  }
  match facts.suggest(weak_peer, object, Some("helper")) {
    Ok(opinions) =>
      match opinions.entries().search_by(entry => entry.0 == Some("helper")) {
        Some(index) => assert_true(opinions.entries()[index].1.length() == 2)
        None => fail("missing helper opinion")
      }
    Err(reason) => fail(reason)
  }
  assert_true(facts.resolve(object) == Ok(Some("helper")))
  match facts.suggest(strong, object, Some("main")) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(facts.resolve(object) == Ok(Some("main")))
  match facts.suggest(mutable, object, Some("helper")) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(facts.resolve(object) == Ok(Some("helper")))
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
