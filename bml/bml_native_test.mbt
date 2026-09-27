///|
test "patterns are read from files" {
  let path = "_build/bml-native-test.scm"
  match @native_io.write_file(path, b"((true) (set-mark))\n; done\n") {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  guard @bml.parse_file(path) is Ok(patterns) else { fail("parse failed") }
  assert_eq(patterns.length(), 1)
  let prog = @types.Program::create(subs=[@types.Sub::create(name="f")])
  match @bml.map_terms([], file=path, prog) {
    Ok(prog) => assert_true(prog.subs()[0].get_attr("mark") is Some(_))
    Err(reason) => fail(reason)
  }
  assert_true(@bml.parse_file("_build/does-not-exist.scm") is Err(_))
}
