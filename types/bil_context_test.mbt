///|
fn context_var(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(8))
}

///|
fn context_result(value : Int, id : UInt64) -> @types.BilResult {
  @types.BilResult::word(
    try! @types.Word::of_int(width=8, value),
    @types.BilResultId::of_uint64(id),
  )
}

///|
fn context_binding_names(
  bindings : Array[(@types.Var, @types.BilResult)],
) -> Array[String] {
  bindings.map(entry => entry.0.name())
}

///|
test "BAP-style BIL context lookup and update are persistent" {
  let x = context_var("x")
  let result = context_result(1, 1UL)
  let empty = @types.BilContext::new()
  let updated = empty.update(x, result)
  assert_true(empty.lookup(x) == None)
  assert_true(updated.lookup(x) == Some(result))
}

///|
test "BAP-style BIL context update replaces an existing variable binding" {
  let x = context_var("x")
  let first = context_result(1, 1UL)
  let second = context_result(2, 2UL)
  let updated = @types.BilContext::new().update(x, first).update(x, second)
  assert_true(updated.lookup(x) == Some(second))
  assert_true(updated.bindings().length() == 1)
}

///|
test "BAP-style BIL context bindings are deterministic by variable name" {
  let z = context_var("z")
  let a = context_var("a")
  let b = context_var("b")
  let context = @types.BilContext::new()
    .update(z, context_result(3, 3UL))
    .update(a, context_result(1, 1UL))
    .update(b, context_result(2, 2UL))
  assert_true(context_binding_names(context.bindings()) == ["a", "b", "z"])
}
