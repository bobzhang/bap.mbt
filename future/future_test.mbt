///|
let future_magic_value = 42

///|
test "translated BAP future fulfill and peek" {
  let (future, promise) = @future.Future::create()
  assert_true(!future.is_decided())
  assert_true(!promise.is_fulfilled())
  assert_true(future.peek() == None)
  promise.fulfill(future_magic_value)
  assert_true(future.is_decided())
  assert_true(promise.is_fulfilled())
  assert_true(future.peek() == Some(future_magic_value))
  assert_true(future.peek_exn() == future_magic_value)
}

///|
test "translated BAP future rejects double fulfillment" {
  let (future, promise) = @future.Future::create()
  promise.fulfill(future_magic_value)
  assert_true(future.peek_exn() == future_magic_value)
  try promise.fulfill(future_magic_value + 1) catch {
    AlreadyDecided => ()
    _ => fail("expected already-decided future")
  } noraise {
    _ => fail("double fulfillment should fail")
  }
  assert_true(future.peek_exn() == future_magic_value)
}

///|
test "translated BAP future peek_exn rejects empty futures" {
  let (future, _) : (@future.Future[Int], @future.Promise[Int]) = @future.Future::create()
  try future.peek_exn() catch {
    EmptyFuture => ()
    _ => fail("expected empty future")
  } noraise {
    _ => fail("empty future should fail")
  }
}

///|
test "translated BAP future upon fires after and after fulfillment" {
  let (future, promise) = @future.Future::create()
  let result : Ref[Int?] = Ref(None)
  future.upon(fn(value) { result.val = Some(value) })
  assert_true(result.val == None)
  promise.fulfill(future_magic_value)
  assert_true(result.val == Some(future_magic_value))
  let late : Ref[Int?] = Ref(None)
  future.upon(fn(value) { late.val = Some(value + 1) })
  assert_true(late.val == Some(future_magic_value + 1))
}

///|
test "translated BAP future bind map and apply propagate decided values" {
  let (future, promise) = @future.Future::create()
  let bound = future.bind(fn(value) { @future.Future::resolved(value + 1) })
  let mapped = future.map(fn(value) { value * 2 })
  let function_future = @future.Future::resolved(fn(value) { value + 3 })
  let applied = @future.Future::apply(function_future, future)
  promise.fulfill(future_magic_value)
  assert_true(bound.peek_exn() == future_magic_value + 1)
  assert_true(mapped.peek_exn() == future_magic_value * 2)
  assert_true(applied.peek_exn() == future_magic_value + 3)
}

///|
test "translated BAP future resolved values are immediately decided" {
  let future = @future.Future::resolved(future_magic_value)
  assert_true(future.is_decided())
  assert_true(future.peek_exn() == future_magic_value)
  assert_true(
    @future.Future::full(future_magic_value).peek_exn() == future_magic_value,
  )
}
