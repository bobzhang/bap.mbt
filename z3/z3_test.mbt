///|
test "an unavailable solver is reported, not fatal" {
  if @z3.is_available() {
    // covered by the native tests
    assert_true(@z3.version() is Some(_))
    return
  }
  assert_true(@z3.version() is None)
  assert_true(@z3.unavailable_reason() != "")
  let msg = try @z3.Context::new() catch {
    Unavailable(m) => m
    e => "unexpected: \{e}"
  } noraise {
    _ => "created"
  }
  assert_true(msg.has_prefix("SMT solver unavailable"))
}
