///|
fn bare_rule(text : String) -> @bare.Rule raise {
  match @bare.Rule::of_string(text) {
    Ok(rule) => rule
    Err(reason) => fail(reason.to_string())
  }
}

///|
fn bare_fact(text : String) -> @bare.BareFact raise {
  match @bare.BareTerm::parse(text) {
    Ok(term) => term
    Err(reason) => fail(reason.to_string())
  }
}

///|
test "translated BARE parser exposes lhs rhs and spec" {
  let rule = bare_rule(
    "(((acquire ?site ?ptr ?) (release ?site2 ?ptr ?)) ((freed ?site ?site2 ?ptr)))",
  )
  assert_eq(rule.lhs().length(), 2)
  assert_eq(rule.rhs().length(), 1)
  assert_eq(
    rule.spec(),
    "(((acquire ?site ?ptr ?) (release ?site2 ?ptr ?)) ((freed ?site ?site2 ?ptr)))",
  )
}

///|
test "translated BARE parses multiple rule specifications" {
  match @bare.Rule::from_string("(((a)) ((b))) (((c)) ((d)))") {
    Ok(rules) => {
      assert_eq(rules.length(), 2)
      assert_eq(rules[0].spec(), "(((a)) ((b)))")
      assert_eq(rules[1].spec(), "(((c)) ((d)))")
    }
    Err(reason) => fail(reason.to_string())
  }
}

///|
test "translated BARE applies streaming nonlinear facts" {
  let mut rule = bare_rule(
    "(((acquire ?asite ?ptr ?) (release ?rsite ?ptr ?) (violate ?vsite ?ptr ?kind)) ((?kind ?asite ?rsite ?vsite)))",
  )
  let (next, first) = rule.apply(bare_fact("(acquire L10 0xBAD 10)"))
  rule = next
  assert_eq(first.length(), 0)

  let (next, second) = rule.apply(bare_fact("(release L20 0xBAD 10)"))
  rule = next
  assert_eq(second.length(), 0)

  let (next, third) = rule.apply(
    bare_fact("(violate L30 0xBAD use-after-free)"),
  )
  rule = next
  assert_true(
    third.map(fn(fact) { fact.to_string() }) == ["(use-after-free L10 L20 L30)"],
  )

  let (_, fourth) = rule.apply(bare_fact("(violate L40 0xBAD double-free)"))
  assert_true(
    fourth.map(fn(fact) { fact.to_string() }) == ["(double-free L10 L20 L40)"],
  )
}

///|
test "translated BARE rejects invalid rhs variables" {
  assert_true(@bare.Rule::of_string("(((seen ?x)) ((?)))") is Err(BareWildcard))
  assert_true(
    @bare.Rule::of_string("(((seen ?x)) ((out ?y)))") is Err(BareUnbound("?y")),
  )
}

///|
test "translated BARE reset discards partial matches" {
  let rule = bare_rule(
    "(((acquire ?site ?ptr ?) (release ?site2 ?ptr ?)) ((freed ?site ?site2 ?ptr)))",
  )
  let (partial, first) = rule.apply(bare_fact("(acquire L10 0xBAD 10)"))
  assert_eq(first.length(), 0)
  let reset = partial.reset()
  let (next, second) = reset.apply(bare_fact("(release L20 0xBAD 10)"))
  assert_eq(second.length(), 0)
  let (_, third) = next.apply(bare_fact("(violate L30 0xBAD use-after-free)"))
  assert_eq(third.length(), 0)
}
