///|
fn fullname(demangler : @demangle.Demangler) -> String {
  demangler.fullname().show()
}

///|
test "translated BAP demangler builtins preserve names and behavior" {
  let id = @demangle.Demangler::id()
  assert_eq(id.name(), "id")
  assert_eq(fullname(id), "bap:id")
  assert_eq(id.run("_main"), "_main")

  let strip = @demangle.Demangler::strip_leading_underscore()
  assert_eq(strip.name(), "strip-leading-underscore")
  assert_eq(fullname(strip), "bap:strip-leading-underscore")
  assert_eq(strip.run("main"), "main")
  assert_eq(strip.run("_main"), "main")
  assert_eq(strip.run("__main"), "_main")

  match @demangle.Demanglers::lookup("id", pkg="bap") {
    Some(found) => assert_eq(fullname(found), "bap:id")
    None => fail("missing id demangler")
  }
  let available = @demangle.Demanglers::available().map(fullname)
  assert_true(available.contains("bap:id"))
  assert_true(available.contains("bap:strip-leading-underscore"))
}

///|
test "translated BAP demangler registry rejects duplicate full names" {
  match
    @demangle.Demangler::create("unit-prefix", pkg="test", fn(name) {
      "unit:" + name
    }) {
    Ok(demangler) => {
      assert_eq(demangler.name(), "unit-prefix")
      assert_eq(fullname(demangler), "test:unit-prefix")
      assert_eq(demangler.run("main"), "unit:main")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @demangle.Demangler::create("unit-prefix", pkg="test", fn(name) { name })
    is Err(_),
  )

  match
    @demangle.Demangler::declare_demangler("unit-suffix", pkg="test", fn(name) {
      name + ":unit"
    }) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @demangle.Demanglers::get("unit-suffix", pkg="test") {
    Ok(demangler) => assert_eq(demangler.run("main"), "main:unit")
    Err(reason) => fail(reason)
  }
  assert_true(@demangle.Demanglers::lookup("missing", pkg="test") is None)
  assert_true(@demangle.Demanglers::get("missing", pkg="test") is Err(_))
}

///|
test "translated BAP demanglers install and select per target" {
  let target = @core_theory.Target::x86_64()
  let demangler = match
    @demangle.Demangler::create("x86-strip", pkg="test", fn(name) {
      if name.has_prefix("__") {
        name[2:].to_owned()
      } else {
        name
      }
    }) {
    Ok(demangler) => demangler
    Err(reason) => fail(reason)
  }
  match @demangle.Demanglers::install(target, demangler) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  let selected = @demangle.Demanglers::select(target)
  assert_eq(fullname(selected), "test:x86-strip")
  assert_eq(selected.run("__main"), "main")
  assert_true(
    @demangle.Demanglers::install(target, @demangle.Demangler::id()) is Err(_),
  )

  let unknown = @demangle.Demanglers::select(@core_theory.Target::unknown())
  assert_eq(fullname(unknown), "bap:id")
  assert_eq(unknown.run("_still_mangled"), "_still_mangled")
}
