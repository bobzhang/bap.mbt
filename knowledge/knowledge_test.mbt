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
  assert_true(@knowledge.Name::of_string(name.show()).equal(name))
  assert_eq(@knowledge.Name::str()(name), name.show())
  assert_true(
    name.hash() == @knowledge.Name::create("target:x", pkg="core").hash(),
  )
  assert_true(
    name.hash() != @knowledge.Name::create("target:x", pkg="other").hash(),
  )
  assert_true(name.equal(@knowledge.Name::create("target:x", pkg="core")))
  assert_eq(name.compare(@knowledge.Name::create("target:x", pkg="core")), 0)
  assert_true(
    name.compare(@knowledge.Name::create("target:x", pkg="other")) < 0,
  )
  assert_true(name.compare(@knowledge.Name::create("aaa", pkg="core")) > 0)
}

///|
test "names preserve BAP keyword package normalization" {
  let keyword = @knowledge.Name::read(":unknown")
  assert_eq(keyword.pkg(), "keyword")
  assert_eq(keyword.unqualified(), ":unknown")
  assert_eq(keyword.show(), ":unknown")
  assert_true(@knowledge.Name::of_string(keyword.show()).equal(keyword))
  assert_true(@knowledge.Name::read("keyword:unknown").equal(keyword))
  assert_true(@knowledge.Name::create("unknown", pkg="keyword").equal(keyword))
  assert_eq(@knowledge.Name::read("plain", pkg="").pkg(), "user")
  assert_eq(@knowledge.Name::create("plain", pkg="").pkg(), "user")
}

///|
test "persistent codecs round trip strings names and arrays" {
  let string_codec = @knowledge.Persistent::string()
  assert_eq(string_codec.encode("a:b"), "a:b")
  assert_true(string_codec.decode("a:b") == Ok("a:b"))

  let name_codec = @knowledge.Persistent::name()
  let name = @knowledge.Name::create("target:x", pkg="core")
  assert_true(name_codec.decode(name_codec.encode(name)) == Ok(name))

  let int_codec = @knowledge.Persistent::int()
  assert_true(int_codec.decode(int_codec.encode(42)) == Ok(42))
  assert_true(int_codec.decode("forty-two") is Err(_))

  let bool_codec = @knowledge.Persistent::bool()
  assert_true(bool_codec.decode(bool_codec.encode(true)) == Ok(true))
  assert_true(bool_codec.decode(bool_codec.encode(false)) == Ok(false))
  assert_true(bool_codec.decode("yes") is Err(_))

  let bytes_codec = @knowledge.Persistent::bytes()
  assert_eq(bytes_codec.encode(b"\x00\xff:"), "00ff3a")
  assert_true(
    bytes_codec.decode(bytes_codec.encode(b"\x00\xff:")) == Ok(b"\x00\xff:"),
  )
  assert_true(bytes_codec.decode("abc") is Err(_))
  assert_true(bytes_codec.decode("xx") is Err(_))

  let optional_string_codec = @knowledge.Persistent::optional(string_codec)
  let missing : String? = None
  assert_true(
    optional_string_codec.decode(optional_string_codec.encode(missing)) ==
    Ok(missing),
  )
  assert_true(
    optional_string_codec.decode(optional_string_codec.encode(Some("a:b"))) ==
    Ok(Some("a:b")),
  )
  assert_true(optional_string_codec.decode("4:none1:x") is Err(_))
  assert_true(optional_string_codec.decode("4:some1:x") == Ok(Some("x")))
  assert_true(optional_string_codec.decode("3:bad") is Err(_))

  let array_codec = @knowledge.Persistent::array(string_codec)
  let values = ["", "a:b", "moon"]
  assert_true(array_codec.decode(array_codec.encode(values)) == Ok(values))
  assert_true(array_codec.decode("2:a") is Err(_))
  assert_true(array_codec.decode("x:bad") is Err(_))

  let list_codec = @knowledge.Persistent::list(string_codec)
  let list_values = @list.from_array(["first", "", "last"])
  match list_codec.decode(list_codec.encode(list_values)) {
    Ok(decoded) => assert_true(decoded.to_array() == list_values.to_array())
    Err(reason) => fail(reason)
  }

  let decimal_codec = @knowledge.Persistent::convert(
    to_persistent=(value : Int) => value.to_string(),
    of_persistent=(input : String) => {
      try @string.parse_int(input) catch {
        _ => Err("invalid integer")
      } noraise {
        value => Ok(value)
      }
    },
    string_codec,
  )
  assert_true(decimal_codec.decode(decimal_codec.encode(42)) == Ok(42))

  let map_codec = @knowledge.Persistent::map(string_codec, int_codec)
  let mapping : Map[String, Int] = { "b": 2, "a": 1, "colon:key": 3 }
  assert_eq(map_codec.encode(mapping), "1:a1:11:b1:29:colon:key1:3")
  match map_codec.decode(map_codec.encode(mapping)) {
    Ok(decoded) => {
      assert_true(decoded.get("a") == Some(1))
      assert_true(decoded.get("b") == Some(2))
      assert_true(decoded.get("colon:key") == Some(3))
    }
    Err(reason) => fail(reason)
  }
  assert_true(map_codec.decode("1:a1:11:a1:2") is Err(_))
  assert_true(map_codec.decode("1:a1") is Err(_))

  let set_codec = @knowledge.Persistent::set(string_codec)
  let names = Set::from_array(["b", "a", "colon:key"])
  assert_eq(set_codec.encode(names), "1:a1:b9:colon:key")
  assert_true(set_codec.decode(set_codec.encode(names)) == Ok(names))
  assert_true(set_codec.decode("2:a") is Err(_))

  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("persistent-program", pkg="test"),
    sort="unit",
  )
  let slot = cls.property(
    name=@knowledge.Name::create("persistent-name", pkg="test"),
    domain=@knowledge.Domain::string(
      @knowledge.Name::create("persistent-name", pkg="test"),
    ),
    persistent=string_codec,
  )
  match slot.persistent() {
    Some(codec) => assert_true(codec.decode(codec.encode("slot")) == Ok("slot"))
    None => fail("missing persistent codec")
  }
}

///|
test "knowledge rules record BAP-style registry documentation" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("rule-program", pkg="test"),
    sort="unit",
  )
  let bool_domain = @knowledge.Domain::bool(
    @knowledge.Name::create("rule-bool", pkg="test"),
  )
  let input = cls.property(
    name=@knowledge.Name::create("rule-input", pkg="test"),
    domain=bool_domain,
  )
  let output = cls.property(
    name=@knowledge.Name::create("rule-output", pkg="test"),
    domain=bool_domain,
  )
  let rule_def = @knowledge.Rule::create("rule-example", pkg="test")
  let rule_doc = rule_def
    .dynamic(["target", "mode"])
    .require(input)
    .provide(output)
  rule_doc.comment("derive output from input")

  let rules = @knowledge.Documentation::rules()
  match rules.search_by(rule => rule.name().show() == "test:rule-example") {
    Some(index) => {
      let rule = rules[index]
      assert_eq(rule.desc(), "derive output from input")
      assert_true(rule.provides().equal(output.name()))
      let required = rule.requires()
      assert_eq(required.length(), 1)
      assert_true(required[0].equal(input.name()))
      let parameters = rule.parameters()
      assert_eq(parameters.length(), 1)
      assert_true(parameters[0] == ["target", "mode"])
    }
    None => fail("missing registered rule")
  }
}

///|
test "knowledge documentation lists public classes and properties" {
  let public_cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("documented-program", pkg="test"),
    sort="unit",
    desc="documented class",
    public=true,
  )
  let hidden_cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("hidden-program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::string(
    @knowledge.Name::create("documented-domain", pkg="test"),
  )
  let public_slot = public_cls.property(
    name=@knowledge.Name::create("documented-property", pkg="test"),
    domain~,
    desc="documented property",
    public=true,
  )
  ignore(
    public_cls.property(
      name=@knowledge.Name::create("hidden-property", pkg="test"),
      domain~,
    ),
  )
  ignore(
    hidden_cls.property(
      name=@knowledge.Name::create("orphan-public-property", pkg="test"),
      domain~,
      public=true,
    ),
  )

  let classes = @knowledge.Documentation::classes()
  match
    classes.search_by(entry => {
      entry.0.name().show() == "test:documented-program"
    }) {
    Some(index) => {
      let (cls_doc, properties) = classes[index]
      assert_eq(cls_doc.desc(), "documented class")
      assert_eq(properties.length(), 1)
      assert_true(properties[0].name().equal(public_slot.name()))
      assert_eq(properties[0].desc(), "documented property")
    }
    None => fail("missing documented class")
  }
  assert_true(
    !classes.any(entry => entry.0.name().show() == "test:hidden-program"),
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
test "flat and total domains accept custom joins" {
  let flat = @knowledge.Domain::flat(
    @knowledge.Name::create("joined-color", pkg="test"),
    value => value,
    empty="",
    join=(lhs, rhs) => {
      if lhs == "" {
        Ok(rhs)
      } else if rhs == "" || lhs == rhs {
        Ok(lhs)
      } else {
        Ok("\{lhs}+\{rhs}")
      }
    },
  )
  assert_true(flat.order("red", "blue") == Incomparable)
  assert_true(flat.join("red", "blue") == Ok("red+blue"))

  let total = @knowledge.Domain::total(
    @knowledge.Name::create("bounded-confidence", pkg="test"),
    (value : Int) => value.to_string(),
    empty=0,
    compare=(lhs, rhs) => lhs.compare(rhs),
    join=(lhs, rhs) => {
      let upper = if lhs > rhs { lhs } else { rhs }
      if upper <= 10 {
        Ok(upper)
      } else {
        Err("confidence bound exceeded")
      }
    },
  )
  assert_true(total.join(4, 7) == Ok(7))
  assert_true(total.join(4, 12) is Err(_))
}

///|
test "custom domains derive default joins from partial order" {
  let domain = @knowledge.Domain::custom(
    @knowledge.Name::create("partial-level", pkg="test"),
    (value : Int) => value.to_string(),
    empty=0,
    order=(lhs, rhs) => {
      if lhs == rhs {
        Equal
      } else if lhs == 0 {
        Less
      } else if rhs == 0 {
        Greater
      } else {
        Incomparable
      }
    },
  )
  assert_true(domain.is_empty(0))
  assert_true(domain.order(0, 2) == Less)
  assert_true(domain.join(0, 2) == Ok(2))
  assert_true(domain.join(2, 0) == Ok(2))
  assert_true(domain.join(1, 2) is Err(_))
}

///|
test "total domains order values and join by upper bound" {
  let domain = @knowledge.Domain::total(
    @knowledge.Name::create("confidence", pkg="test"),
    (value : Int) => value.to_string(),
    empty=0,
    compare=(lhs, rhs) => lhs.compare(rhs),
  )
  assert_true(domain.is_empty(0))
  assert_true(domain.order(0, 2) == Less)
  assert_true(domain.order(2, 0) == Greater)
  assert_true(domain.order(2, 2) == Equal)
  assert_true(domain.join(1, 3) == Ok(3))
  assert_true(domain.join(3, 1) == Ok(3))
  assert_eq(domain.inspect(3), "3")
}

///|
test "mapping domains merge pointwise facts" {
  let domain = @knowledge.Domain::mapping(
    @knowledge.Name::create("attributes", pkg="test"),
    key => key,
    (value : Int) => value.to_string(),
    equal=(lhs, rhs) => lhs == rhs,
  )
  let empty : Map[String, Int] = {}
  let base : Map[String, Int] = { "a": 1 }
  let same : Map[String, Int] = { "a": 1 }
  let extra : Map[String, Int] = { "b": 2 }
  let extended : Map[String, Int] = { "a": 1, "b": 2 }
  let conflict : Map[String, Int] = { "a": 2 }
  assert_true(domain.is_empty(empty))
  assert_true(domain.order(empty, base) == Less)
  assert_true(domain.order(base, same) == Equal)
  assert_true(domain.order(base, extended) == Less)
  assert_true(domain.order(base, conflict) == Incomparable)
  match domain.join(base, extra) {
    Ok(joined) => {
      assert_eq(joined.length(), 2)
      assert_true(joined.get("a") == Some(1))
      assert_true(joined.get("b") == Some(2))
    }
    Err(reason) => fail(reason)
  }
  assert_true(domain.join(base, conflict) is Err(_))
  assert_eq(domain.inspect(extended), "{a: 1, b: 2}")

  let summing = @knowledge.Domain::mapping(
    @knowledge.Name::create("summed-attributes", pkg="test"),
    key => key,
    (value : Int) => value.to_string(),
    equal=(lhs, rhs) => lhs == rhs,
    join=(lhs, rhs) => Ok(lhs + rhs),
  )
  match summing.join(base, conflict) {
    Ok(joined) => assert_true(joined.get("a") == Some(3))
    Err(reason) => fail(reason)
  }
}

///|
test "object domains use null as bottom" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("object-domain", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::obj(cls)
  let null = @knowledge.Object::null(cls)
  let object = @knowledge.State::new().create(cls)
  match domain.empty() {
    Some(empty) => assert_true(empty.equal(null))
    None => fail("missing object domain bottom")
  }
  assert_true(domain.is_empty(null))
  assert_true(!domain.is_empty(object))
  assert_true(domain.order(null, object) == Less)
  match domain.join(null, object) {
    Ok(joined) => assert_true(joined.equal(object))
    Err(reason) => fail(reason)
  }
  assert_eq(domain.inspect(object), "#<test:object-domain 1>")
}

///|
test "state enumerates objects by class in creation order" {
  let state = @knowledge.State::new()
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("enumerated-object", pkg="test"),
    sort="unit",
  )
  let other : @knowledge.Class[String, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("other-object", pkg="test"),
    sort="unit",
  )
  let first = state.create(cls)
  ignore(state.create(other))
  let second = state.create(cls)
  let objects = state.objects(cls)
  assert_eq(objects.length(), 2)
  assert_true(objects[0].equal(first))
  assert_true(objects[1].equal(second))
  assert_true(state.objects(other).length() == 1)
  let unseen : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("unseen-object", pkg="test"),
    sort="unit",
  )
  assert_true(state.objects(unseen).is_empty())
}

///|
test "state scoped objects are removed from class enumeration" {
  let state = @knowledge.State::new()
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("scoped-object", pkg="test"),
    sort="unit",
  )
  let permanent = state.create(cls)
  let scoped = state.scoped(cls, object => {
    let objects = state.objects(cls)
    (
      object,
      objects.length(),
      objects.any(current => current.equal(object)),
      objects.any(current => current.equal(permanent)),
    )
  })
  assert_eq(scoped.1, 2)
  assert_true(scoped.2)
  assert_true(scoped.3)
  let remaining = state.objects(cls)
  assert_eq(remaining.length(), 1)
  assert_true(remaining[0].equal(permanent))
  assert_true(!remaining.any(object => object.equal(scoped.0)))
}

///|
test "state interns and reads BAP-style symbols by class" {
  let state = @knowledge.State::new()
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("interned-object", pkg="test"),
    sort="unit",
  )
  let other : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("interned-other", pkg="test"),
    sort="unit",
  )
  let name = @knowledge.Name::create("main", pkg="test")
  let first = state.intern(cls, name~)
  let again = state.intern(cls, name~)
  assert_true(first.equal(again))
  assert_eq(state.objects(cls).length(), 1)
  match state.interned_name(first) {
    Some(found) => assert_true(found.equal(name))
    None => fail("missing interned name")
  }
  assert_eq(state.repr(first), "test:main")

  let in_other_class = state.intern(other, name~)
  assert_true(!first.equal(in_other_class))
  assert_eq(state.objects(other).length(), 1)

  match state.read(cls, "test:main") {
    Ok(read) => assert_true(read.equal(first))
    Err(reason) => fail(reason)
  }
  match state.read(cls, "helper", pkg="test") {
    Ok(read) => {
      assert_true(state.repr(read) == "test:helper")
      assert_eq(state.objects(cls).length(), 2)
    }
    Err(reason) => fail(reason)
  }
  let fresh = state.create(cls)
  assert_true(state.interned_name(fresh) is None)
  assert_eq(state.repr(fresh), fresh.repr())
}

///|
test "state current package controls unqualified symbol reads and rendering" {
  let state = @knowledge.State::new()
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("packaged-object", pkg="test"),
    sort="unit",
  )
  assert_eq(state.current_pkg(), "user")
  match state.read(cls, "main") {
    Ok(object) => {
      assert_eq(state.repr(object), "main")
      match state.interned_name(object) {
        Some(name) => assert_eq(name.show(), "user:main")
        None => fail("missing user symbol name")
      }
    }
    Err(reason) => fail(reason)
  }

  state.set_current_pkg("analysis")
  let analysis = state.intern_named(cls, "main")
  assert_eq(state.repr(analysis), "main")
  match state.interned_name(analysis) {
    Some(name) => assert_eq(name.show(), "analysis:main")
    None => fail("missing analysis symbol name")
  }

  let scoped_result = state.with_pkg("scoped", fn() { state.read(cls, "main") })
  assert_eq(state.current_pkg(), "analysis")
  match scoped_result {
    Ok(scoped) => {
      assert_eq(state.repr(scoped), "scoped:main")
      assert_true(!analysis.equal(scoped))
    }
    Err(reason) => fail(reason)
  }
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
fn test_string_set(items : Array[String]) -> Set[String] {
  Set::from_array(items)
}

///|
fn assert_test_string_set_equal(
  actual : Set[String],
  expected : Set[String],
) -> Unit raise {
  assert_true(actual.length() == expected.length())
  for item in expected {
    assert_true(actual.contains(item))
  }
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
test "set domains join facts by set union" {
  let domain = @knowledge.Domain::set(
    @knowledge.Name::create("alias-set", pkg="test"),
    value => value,
  )
  let empty = test_string_set([])
  let main = test_string_set(["main"])
  let helper = test_string_set(["helper"])
  let base = test_string_set(["main", "start"])
  let extra = test_string_set(["main", "helper"])
  assert_true(domain.order(empty, main) == Less)
  assert_true(domain.order(main, empty) == Greater)
  assert_true(domain.order(main, helper) == Incomparable)
  match domain.join(base, extra) {
    Ok(joined) =>
      assert_test_string_set_equal(
        joined,
        test_string_set(["main", "start", "helper"]),
      )
    Err(reason) => fail(reason)
  }
  inspect(
    domain.inspect(test_string_set(["helper", "main"])),
    content="{main, helper}",
  )

  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("set-aliased-program", pkg="test"),
    sort="unit",
  )
  let slot = cls.property(
    name=@knowledge.Name::create("alias-set", pkg="test"),
    domain~,
  )
  let object = @knowledge.State::new().create(cls)
  let facts = @knowledge.FactTable::new(slot)
  match facts.collect(object) {
    Some(value) => assert_true(value.is_empty())
    None => fail("missing set domain bottom")
  }
  match facts.provide(object, test_string_set(["main", "main"])) {
    Ok(value) => assert_test_string_set_equal(value, test_string_set(["main"]))
    Err(reason) => fail(reason)
  }
  match facts.provide(object, test_string_set(["entry", "main"])) {
    Ok(value) =>
      assert_test_string_set_equal(value, test_string_set(["main", "entry"]))
    Err(reason) => fail(reason)
  }
  assert_true(facts.has(object))
}

///|
test "translated BAP opinion domains resolve by agent reliability" {
  let weak = register_test_agent("opinion-weak", Unreliable)
  let weak_peer = register_test_agent("opinion-weak-peer", Unreliable)
  let strong = register_test_agent("opinion-strong", Reliable)
  let mutable = register_test_agent("opinion-mutable", Unreliable)
  assert_true(weak.name().show() == "test:opinion-weak")
  assert_eq(weak.id(), @regular.digest_string(weak.name().show()).to_string())
  assert_true(weak.id() != weak.name().show())
  assert_true(weak.weight() == 1)
  assert_true(mutable.set_reliability(Authorative) == Ok(()))
  assert_true(mutable.weight() == 16)
  let documented = match
    @knowledge.Agent::register(
      "opinion-described",
      pkg="test",
      desc="agent registry entry",
      reliability=Doubtful,
    ) {
    Ok(agent) => agent
    Err(reason) => fail(reason)
  }
  let documented_id = @knowledge.Agent::read(documented.id())
  assert_eq(documented_id.name().show(), "test:opinion-described")
  assert_eq(documented_id.desc(), "agent registry entry")
  assert_true(documented_id.reliability() == Doubtful)
  assert_true(
    @knowledge.Agent::registry().any(agent => agent.id() == documented.id()),
  )
  assert_true(
    @knowledge.Documentation::agents().any(agent => {
      agent.id() == documented.id()
    }),
  )
  assert_eq(
    @knowledge.Agent::read("opaque-agent-id", pkg="ignored").id(),
    "opaque-agent-id",
  )

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
  let listed_opinions = @knowledge.Opinions::of_list(
    [
      (weak, Some("helper")),
      (weak_peer, Some("helper")),
      (strong, Some("main")),
      (weak, None),
    ],
    empty=empty_name,
    equal=optional_string_equal,
    inspect=inspect_optional_string,
  )
  let strong_opinion = weak_opinion.add(strong, Some("main"))
  assert_true(weak_opinion.compare_votes(listed_opinions) < 0)
  assert_true(listed_opinions.compare_votes(weak_opinion) > 0)
  assert_true(listed_opinions.choice() == Some("main"))
  assert_true(weak_opinion.join(listed_opinions).entries().length() == 2)
  match
    listed_opinions.entries().search_by(entry => entry.0 == Some("helper")) {
    Some(index) => assert_true(listed_opinions.entries()[index].1.length() == 2)
    None => fail("missing helper opinion from list")
  }
  assert_true(@knowledge.Agent::read(weak.id()).id() == weak.id())
  match
    @knowledge.Agent::persistent().decode(
      @knowledge.Agent::persistent().encode(strong),
    ) {
    Ok(agent) => assert_true(agent.id() == strong.id())
    Err(reason) => fail(reason)
  }
  let opinion_codec = @knowledge.Opinions::persistent(
    @knowledge.Persistent::optional(@knowledge.Persistent::string()),
    empty=empty_name,
    equal=optional_string_equal,
    inspect=inspect_optional_string,
  )
  match opinion_codec.decode(opinion_codec.encode(listed_opinions)) {
    Ok(decoded) => {
      assert_true(decoded.choice() == Some("main"))
      assert_true(decoded.entries() == listed_opinions.entries())
    }
    Err(reason) => fail(reason)
  }
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
test "translated BAP opinion proposals materialize deferred suggestions" {
  let weak = register_test_agent("opinion-propose-weak", Unreliable)
  let strong = register_test_agent("opinion-propose-strong", Reliable)
  let empty_name : String? = None
  let domain = @knowledge.Domain::opinions(
    @knowledge.Name::create("proposed-name", pkg="test"),
    empty=empty_name,
    equal=optional_string_equal,
    inspect=inspect_optional_string,
  )
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("proposed-program", pkg="test"),
    sort="unit",
  )
  let slot = cls.property(
    name=@knowledge.Name::create("proposed-name", pkg="test"),
    domain~,
  )
  let state = @knowledge.State::new()
  let object = state.create(cls)
  let ranked = state.create(cls)
  let missing = state.create(cls)
  let facts = @knowledge.FactTable::new(slot)
  let calls : Ref[Int] = Ref(0)
  facts.propose(weak, current => {
    calls.val = calls.val + 1
    if current.equal(object) || current.equal(ranked) {
      Ok(Some("helper"))
    } else {
      Ok(None)
    }
  })
  facts.propose(strong, current => {
    if current.equal(ranked) {
      Ok(Some("main"))
    } else {
      Ok(None)
    }
  })
  assert_true(facts.promise_count() == 2)
  assert_true(facts.resolve(object) == Ok(Some("helper")))
  assert_true(calls.val == 1)
  assert_true(facts.resolve(object) == Ok(Some("helper")))
  assert_true(calls.val == 1)
  assert_true(facts.resolve(ranked) == Ok(Some("main")))
  assert_true(calls.val == 2)
  assert_true(facts.resolve(missing) == Ok(None))
  assert_true(calls.val == 3)

  let scoped_facts = @knowledge.FactTable::new(slot)
  let scoped_object = state.create(cls)
  let after_scope = state.create(cls)
  let count_during : Ref[Int] = Ref(-1)
  let scoped_calls : Ref[Int] = Ref(0)
  let scoped_result = scoped_facts.proposing(
    strong,
    current => {
      scoped_calls.val = scoped_calls.val + 1
      if current.equal(scoped_object) {
        Ok(Some("main"))
      } else {
        Ok(None)
      }
    },
    () => {
      count_during.val = scoped_facts.promise_count()
      scoped_facts.resolve(scoped_object)
    },
  )
  assert_true(scoped_result == Ok(Some("main")))
  assert_true(count_during.val == 1)
  assert_true(scoped_calls.val == 1)
  assert_true(scoped_facts.promise_count() == 0)
  assert_true(scoped_facts.resolve(after_scope) == Ok(None))
  assert_true(scoped_calls.val == 1)
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
  assert_true(slot.cls().same(cls))
  assert_eq(slot.cls().name().show(), "test:program")
  assert_eq(slot.desc(), "no description")
  let described = cls.property(
    name=@knowledge.Name::create("described-seen", pkg="test"),
    domain~,
    desc="execution flag",
  )
  assert_eq(described.desc(), "execution flag")
  let state = @knowledge.State::new()
  let object = state.create(cls)
  let facts = @knowledge.FactTable::new(slot)
  assert_true(facts.collect(object) == Some(false))
  assert_true(facts.provide(object, true) == Ok(true))
  assert_true(facts.provide(object, false) == Ok(true))
  assert_true(facts.collect(object) == Some(true))
}

///|
test "translated BAP fact observers receive non-empty provides" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("observed-program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("observed", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("observed", pkg="test"),
    domain~,
  )
  let facts = @knowledge.FactTable::new(slot)
  let mirrored = @knowledge.FactTable::new(slot)
  let calls : Ref[Int] = Ref(0)
  facts.observe((object, value) => {
    calls.val = calls.val + 1
    match mirrored.provide(object, value) {
      Ok(_) => Ok(())
      Err(reason) => Err(reason)
    }
  })
  assert_true(facts.observer_count() == 1)

  let state = @knowledge.State::new()
  let object = state.create(cls)
  let null = @knowledge.Object::null(cls)
  assert_true(facts.provide(null, true) == Ok(false))
  assert_true(facts.provide(object, false) == Ok(false))
  assert_true(calls.val == 0)
  assert_true(facts.provide(object, true) == Ok(true))
  assert_true(calls.val == 1)
  assert_true(mirrored.collect(object) == Some(true))
  assert_true(facts.provide(object, false) == Ok(true))
  assert_true(calls.val == 1)
}

///|
test "translated BAP fact observing is scoped" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("scoped-observed-program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("scoped-observed", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("scoped-observed", pkg="test"),
    domain~,
  )
  let state = @knowledge.State::new()
  let first = state.create(cls)
  let second = state.create(cls)
  let facts = @knowledge.FactTable::new(slot)
  let calls : Ref[Int] = Ref(0)
  let count_during : Ref[Int] = Ref(-1)
  let provided : Ref[Result[Bool, String]] = Ref(Err("not run"))
  let result = facts.observing(
    (_, value) => {
      if value {
        calls.val = calls.val + 1
      }
      Ok(())
    },
    () => {
      count_during.val = facts.observer_count()
      provided.val = facts.provide(first, true)
      42
    },
  )
  assert_true(result == 42)
  assert_true(count_during.val == 1)
  assert_true(provided.val == Ok(true))
  assert_true(calls.val == 1)
  assert_true(facts.observer_count() == 0)
  assert_true(facts.provide(second, true) == Ok(true))
  assert_true(calls.val == 1)
}

///|
test "translated BAP fact promises materialize deferred values" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("promised-program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("promised-live", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("promised-live", pkg="test"),
    domain~,
  )
  let facts = @knowledge.FactTable::new(slot)
  let object = @knowledge.State::new().create(cls)
  let null = @knowledge.Object::null(cls)
  let calls : Ref[Int] = Ref(0)
  facts.promise(current => {
    calls.val = calls.val + 1
    if current.equal(object) {
      Ok(true)
    } else {
      Ok(false)
    }
  })
  assert_true(facts.promise_count() == 1)
  assert_true(facts.collect(object) == Some(false))
  assert_true(facts.collect_promised(null) == Ok(Some(false)))
  assert_true(calls.val == 0)
  assert_true(facts.require(object) == Ok(true))
  assert_true(calls.val == 1)
  assert_true(facts.collect(object) == Some(true))
  assert_true(facts.collect_promised(object) == Ok(Some(true)))
  assert_true(calls.val == 1)
}

///|
test "translated BAP fact promising is scoped" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("scoped-promised-program", pkg="test"),
    sort="unit",
  )
  let domain = @knowledge.Domain::bool(
    @knowledge.Name::create("scoped-promised-live", pkg="test"),
  )
  let slot = cls.property(
    name=@knowledge.Name::create("scoped-promised-live", pkg="test"),
    domain~,
  )
  let state = @knowledge.State::new()
  let first = state.create(cls)
  let second = state.create(cls)
  let facts = @knowledge.FactTable::new(slot)
  let count_during : Ref[Int] = Ref(-1)
  let result = facts.promising(
    current => if current.equal(first) { Ok(true) } else { Ok(false) },
    () => {
      count_during.val = facts.promise_count()
      facts.require(first)
    },
  )
  assert_true(result == Ok(true))
  assert_true(count_during.val == 1)
  assert_true(facts.promise_count() == 0)
  assert_true(facts.require_cached(first) == Ok(true))
  assert_true(facts.require(second) is Err(_))
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

///|
test "knowledge objects expose BAP-style representation helpers" {
  let cls : @knowledge.Class[Unit, String] = @knowledge.Class::create(
    name=@knowledge.Name::create("object-repr", pkg="test"),
    sort="unit",
  )
  let state = @knowledge.State::new()
  let first = state.create(cls)
  let second = state.create(cls)
  assert_eq(first.repr(), "#<test:object-repr 1>")
  assert_true(first.compare(second) < 0)
  assert_true(second.compare(first) > 0)
  match @knowledge.Object::read(cls, first.repr()) {
    Ok(parsed) => {
      assert_true(parsed.equal(first))
      assert_eq(parsed.compare(first), 0)
    }
    Err(reason) => fail(reason)
  }
  let null = @knowledge.Object::null(cls)
  assert_eq(null.repr(), "nil")
  match @knowledge.Object::read(cls, "nil") {
    Ok(parsed) => assert_true(parsed.equal(null))
    Err(reason) => fail(reason)
  }
  assert_true(@knowledge.Object::read(cls, "#<test:object-repr bad>") is Err(_))
}
