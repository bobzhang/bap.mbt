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

///|
fn[T : Eq] assert_stream_before_eq(
  stream : @future.Stream[T],
  signal : @future.Signal[Unit],
  repeat~ : Int,
  expected : Array[T],
) -> Unit raise {
  let (event, promise) = @future.Future::create()
  let collected = stream.before(event)
  signal.repeat(times=repeat, ())
  promise.fulfill(())
  assert_true(collected.peek() == Some(expected))
}

///|
test "translated BAP stream sends and repeats signals" {
  let (stream, signal) = @future.Stream::create()
  let buffer : Array[Int] = []
  stream.observe(fn(value) { buffer.push(value) })
  signal.send(0)
  signal.send(1)
  signal.send(2)
  assert_true(buffer == [0, 1, 2])

  let (repeated, repeat_signal) = @future.Stream::create()
  let repeated_values : Array[Int] = []
  repeated.observe(fn(value) { repeated_values.push(value) })
  repeat_signal.repeat(times=0, future_magic_value)
  assert_true(repeated_values == [])
  repeat_signal.repeat(times=4, future_magic_value)
  assert_true(
    repeated_values ==
    [
      future_magic_value, future_magic_value, future_magic_value, future_magic_value,
    ],
  )
}

///|
test "translated BAP stream generators feed before futures" {
  let iota = Ref(0)
  let (from_stream, from_signal) = @future.Stream::from(fn() {
    let value = iota.val
    iota.val += 1
    value
  })
  assert_stream_before_eq(from_stream, from_signal, repeat=4, [0, 1, 2, 3])

  let (unfold_stream, unfold_signal) = @future.Stream::unfold(init=0, f=fn(
    value,
  ) {
    (value, value + 1)
  })
  assert_stream_before_eq(unfold_stream, unfold_signal, repeat=4, [0, 1, 2, 3])

  let (finite, finite_signal, finished) = @future.Stream::unfold_until(init=0, f=fn(
    value,
  ) {
    if value > 7 {
      None
    } else {
      Some((value, value + 1))
    }
  })
  assert_stream_before_eq(finite, finite_signal, repeat=9, [
    0, 1, 2, 3, 4, 5, 6, 7,
  ])
  assert_true(finished.is_decided())
}

///|
test "translated BAP stream array and repeat sources are finite or repeated" {
  let values = [0, 1, 2, 3]
  let (stream, signal, finished) = @future.Stream::of_array(values)
  assert_stream_before_eq(stream, signal, repeat=5, values)
  assert_true(finished.is_decided())

  let (repeated, repeat_signal) = @future.Stream::repeat(future_magic_value)
  assert_stream_before_eq(repeated, repeat_signal, repeat=3, [
    future_magic_value, future_magic_value, future_magic_value,
  ])
}

///|
test "translated BAP stream subscriptions hooks and ids" {
  let (stream, signal, _) = @future.Stream::of_array([0, 1, 2, 3, 4, 5, 6, 7])
  assert_true(!stream.has_subscribers())
  let subscribed : Ref[Int?] = Ref(None)
  let unsubscribed : Ref[Int?] = Ref(None)
  let waited = Ref(false)
  stream.on_subscribe(fn(id) { subscribed.val = Some(id) })
  stream.on_unsubscribe(fn(id) { unsubscribed.val = Some(id) })
  stream.on_wait(fn() { waited.val = true })
  stream.wait()
  assert_true(waited.val)

  let called = Ref(0)
  signal.repeat(times=2, ())
  assert_true(called.val == 0)
  let id = stream.subscribe(fn(_) { called.val += 1 })
  assert_true(subscribed.val == Some(id))
  assert_true(stream.has_subscribers())
  signal.repeat(times=2, ())
  assert_true(called.val == 2)
  stream.unsubscribe(id)
  assert_true(unsubscribed.val == Some(id))
  assert_true(!stream.has_subscribers())
  signal.repeat(times=2, ())
  assert_true(called.val == 2)

  let first = stream.subscribe(fn(_) { () })
  let second = stream.subscribe(fn(_) { () })
  assert_true(first != second)
  stream.unsubscribe(first)
  stream.unsubscribe(second)
}

///|
test "translated BAP stream watch receives stable callback ids" {
  let (stream, signal, _) = @future.Stream::of_array([0, 1])
  let first_seen : Ref[Int?] = Ref(None)
  ignore(stream.watch(fn(id, _) { first_seen.val = Some(id) }))
  signal.send(())
  let first_id = match first_seen.val {
    Some(id) => id
    None => fail("expected watch callback")
  }
  signal.send(())
  assert_true(first_seen.val == Some(first_id))

  let (other, other_signal) = @future.Stream::create()
  let left : Ref[Int?] = Ref(None)
  let right : Ref[Int?] = Ref(None)
  ignore(other.watch(fn(id, _) { left.val = Some(id) }))
  ignore(other.watch(fn(id, _) { right.val = Some(id) }))
  other_signal.send(())
  assert_true(left.val is Some(_))
  assert_true(right.val is Some(_))
  assert_true(left.val != right.val)
}
