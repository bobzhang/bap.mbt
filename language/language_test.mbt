///|
test "translated BAP languages preserve names and unique handles" {
  let ocaml = @language.Language::create(name="ocaml")
  let ocaml_again = @language.Language::create(name="ocaml")
  let c = @language.Language::create(name="c")
  assert_eq(ocaml.name(), "ocaml")
  assert_eq(ocaml.to_string(), "ocaml")
  assert_true(!ocaml.equal(ocaml_again))
  assert_true(ocaml.compare(ocaml_again) != 0)
  assert_true(ocaml.compare(c) != 0)
}

///|
test "translated BAP language properties are keyed by handle identity" {
  let ocaml = @language.Language::create(name="ocaml")
  let ocaml_same_name = @language.Language::create(name="ocaml")
  let c = @language.Language::create(name="c")
  let passes : @language.LanguageProperty[String] = @language.LanguageProperty::create()
  passes.set(ocaml, "resolve-apply")
  passes.set(c, "lower-c-abi")
  assert_true(passes.get(ocaml) == Some("resolve-apply"))
  assert_true(passes.get(c) == Some("lower-c-abi"))
  assert_true(passes.get(ocaml_same_name) is None)
  assert_true(passes.contains(ocaml))
  assert_true(!passes.contains(ocaml_same_name))
}
