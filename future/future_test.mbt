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
test "translated BAP future multi-argument applicative helpers" {
  let (left, left_promise) = @future.Future::create()
  let (right, right_promise) = @future.Future::create()
  let mapped2 = @future.Future::map2(left, right, fn(l, r) { l * 10 + r })
  let applied2 = @future.Future::apply2(
    @future.Future::resolved(fn(l, r) { l + r }),
    left,
    right,
  )
  right_promise.fulfill(2)
  assert_true(!mapped2.is_decided())
  left_promise.fulfill(4)
  assert_true(mapped2.peek_exn() == 42)
  assert_true(applied2.peek_exn() == 6)

  let (first, first_promise) = @future.Future::create()
  let (second, second_promise) = @future.Future::create()
  let (third, third_promise) = @future.Future::create()
  let mapped3 = @future.Future::map3(first, second, third, fn(a, b, c) {
    a * 100 + b * 10 + c
  })
  let applied3 = @future.Future::apply3(
    @future.Future::resolved(fn(a, b, c) { a + b + c }),
    first,
    second,
    third,
  )
  second_promise.fulfill(2)
  third_promise.fulfill(3)
  assert_true(!mapped3.is_decided())
  first_promise.fulfill(1)
  assert_true(mapped3.peek_exn() == 123)
  assert_true(applied3.peek_exn() == 6)

  let (one, one_promise) = @future.Future::create()
  let (two, two_promise) = @future.Future::create()
  let (three, three_promise) = @future.Future::create()
  let (four, four_promise) = @future.Future::create()
  let mapped4 = @future.Future::map4(one, two, three, four, fn(a, b, c, d) {
    a * 1000 + b * 100 + c * 10 + d
  })
  let applied4 = @future.Future::apply4(
    @future.Future::resolved(fn(a, b, c, d) { a + b + c + d }),
    one,
    two,
    three,
    four,
  )
  two_promise.fulfill(2)
  four_promise.fulfill(4)
  assert_true(!mapped4.is_decided())
  one_promise.fulfill(1)
  three_promise.fulfill(3)
  assert_true(mapped4.peek_exn() == 1234)
  assert_true(applied4.peek_exn() == 10)

  let (five_a, five_a_promise) = @future.Future::create()
  let (five_b, five_b_promise) = @future.Future::create()
  let (five_c, five_c_promise) = @future.Future::create()
  let (five_d, five_d_promise) = @future.Future::create()
  let (five_e, five_e_promise) = @future.Future::create()
  let mapped5 = @future.Future::map5(five_a, five_b, five_c, five_d, five_e, fn(
    a,
    b,
    c,
    d,
    e,
  ) {
    a * 10000 + b * 1000 + c * 100 + d * 10 + e
  })
  let applied5 = @future.Future::apply5(
    @future.Future::resolved(fn(a, b, c, d, e) { a + b + c + d + e }),
    five_a,
    five_b,
    five_c,
    five_d,
    five_e,
  )
  five_e_promise.fulfill(5)
  five_b_promise.fulfill(2)
  five_d_promise.fulfill(4)
  assert_true(!mapped5.is_decided())
  five_a_promise.fulfill(1)
  five_c_promise.fulfill(3)
  assert_true(mapped5.peek_exn() == 12345)
  assert_true(applied5.peek_exn() == 15)
}

///|
test "BAP-style future args apply curried functions" {
  let (first, first_promise) = @future.Future::create()
  let (second, second_promise) = @future.Future::create()
  let (third, third_promise) = @future.Future::create()
  let args : @future.FutureArgs[(Int) -> (Int) -> (Int) -> Int, Int] = @future.FutureArgs::cons(
    first,
    @future.FutureArgs::cons(
      second,
      @future.FutureArgs::cons(third, @future.FutureArgs::nil()),
    ),
  )
  let mapped = @future.FutureArgs::mapN(
    fn(a) { fn(b) { fn(c) { a * 100 + b * 10 + c } } },
    args,
  )
  third_promise.fulfill(3)
  second_promise.fulfill(2)
  assert_true(!mapped.is_decided())
  first_promise.fulfill(1)
  assert_true(mapped.peek_exn() == 123)

  let (left, left_promise) = @future.Future::create()
  let (right, right_promise) = @future.Future::create()
  let pair_args : @future.FutureArgs[(Int) -> (Int) -> Int, Int] = @future.FutureArgs::cons(
    left,
    @future.FutureArgs::cons(right, @future.FutureArgs::nil()),
  )
  let applied = @future.FutureArgs::applyN(
    @future.Future::resolved(fn(a) { fn(b) { a * 10 + b } }),
    pair_args,
  )
  left_promise.fulfill(4)
  assert_true(!applied.is_decided())
  right_promise.fulfill(2)
  assert_true(applied.peek_exn() == 42)
}

///|
test "BAP-style future args step adapts a function input" {
  let (value, promise) = @future.Future::create()
  let args : @future.FutureArgs[(String) -> Int, Int] = @future.FutureArgs::step(
    @future.FutureArgs::cons(value, @future.FutureArgs::nil()),
    fn(f : (String) -> Int) { fn(number : Int) { f(number.to_string()) } },
  )
  let mapped = @future.FutureArgs::mapN(
    fn(text : String) { text.length() + 1 },
    args,
  )
  assert_true(!mapped.is_decided())
  promise.fulfill(1234)
  assert_true(mapped.peek_exn() == 5)
}

///|
test "BAP-style future collection helpers preserve input order" {
  let empty_inputs : Array[@future.Future[Int]] = []
  let empty = @future.Future::all(empty_inputs)
  assert_true(empty.is_decided())
  assert_true(empty.peek_exn() == [])

  let (left, left_promise) = @future.Future::create()
  let (right, right_promise) = @future.Future::create()
  let pair = @future.Future::both(left, right)
  right_promise.fulfill(2)
  assert_true(!pair.is_decided())
  left_promise.fulfill(1)
  assert_true(pair.peek_exn() == (1, 2))

  let (first, first_promise) = @future.Future::create()
  let (second, second_promise) = @future.Future::create()
  let (third, third_promise) = @future.Future::create()
  let all = @future.Future::all([first, second, third])
  third_promise.fulfill(3)
  first_promise.fulfill(1)
  assert_true(!all.is_decided())
  second_promise.fulfill(2)
  assert_true(all.peek_exn() == [1, 2, 3])

  let (unit_first, unit_first_promise) = @future.Future::create()
  let (unit_second, unit_second_promise) = @future.Future::create()
  let all_unit = @future.Future::all_unit([unit_first, unit_second])
  unit_second_promise.fulfill(())
  assert_true(!all_unit.is_decided())
  unit_first_promise.fulfill(())
  assert_true(all_unit.is_decided())
}

///|
test "BAP-style future list helpers preserve input order" {
  let empty_inputs : @list.List[@future.Future[Int]] = @list.from_array([])
  let empty = @future.Future::all_list(empty_inputs)
  assert_true(empty.is_decided())
  assert_true(empty.peek_exn().to_array() == [])

  let (first, first_promise) = @future.Future::create()
  let (second, second_promise) = @future.Future::create()
  let (third, third_promise) = @future.Future::create()
  let all = @future.Future::all_list(@list.from_array([first, second, third]))
  third_promise.fulfill(3)
  first_promise.fulfill(1)
  assert_true(!all.is_decided())
  second_promise.fulfill(2)
  assert_true(all.peek_exn().to_array() == [1, 2, 3])

  let (unit_first, unit_first_promise) = @future.Future::create()
  let (unit_second, unit_second_promise) = @future.Future::create()
  let all_unit = @future.Future::all_unit_list(
    @list.from_array([unit_first, unit_second]),
  )
  unit_second_promise.fulfill(())
  assert_true(!all_unit.is_decided())
  unit_first_promise.fulfill(())
  assert_true(all_unit.is_decided())
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
test "translated BAP stream iterator and sequence sources are finite" {
  let values = [10, 20, 30]
  let (iter_stream, iter_signal, iter_finished) = @future.Stream::of_iter(
    values.iter(),
  )
  assert_stream_before_eq(iter_stream, iter_signal, repeat=4, values)
  assert_true(iter_finished.is_decided())

  let (sequence_stream, sequence_signal, sequence_finished) = @future.Stream::of_sequence(
    [0, 1, 2, 3].iter().map(fn(value) { value * 2 }),
  )
  assert_stream_before_eq(sequence_stream, sequence_signal, repeat=5, [
    0, 2, 4, 6,
  ])
  assert_true(sequence_finished.is_decided())
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
test "translated BAP stream lifecycle hooks run newest first" {
  let (stream, _) : (@future.Stream[Unit], @future.Signal[Unit]) = @future.Stream::create()
  let events : Array[String] = []
  stream.on_wait(fn() { events.push("wait:first") })
  stream.on_wait(fn() { events.push("wait:last") })
  stream.on_subscribe(fn(id) { events.push("sub:first:\{id}") })
  stream.on_subscribe(fn(id) { events.push("sub:last:\{id}") })
  stream.on_unsubscribe(fn(id) { events.push("unsub:first:\{id}") })
  stream.on_unsubscribe(fn(id) { events.push("unsub:last:\{id}") })

  stream.wait()
  let id = stream.subscribe(fn(_) { () })
  stream.unsubscribe(id)

  assert_true(
    events ==
    [
      "wait:last",
      "wait:first",
      "sub:last:\{id}",
      "sub:first:\{id}",
      "unsub:last:\{id}",
      "unsub:first:\{id}",
    ],
  )
}

///|
test "translated BAP stream watch receives stable callback ids" {
  let (stream, signal, _) = @future.Stream::of_array([0, 1])
  let first_seen : Ref[Int?] = Ref(None)
  stream.watch(fn(id, _) { first_seen.val = Some(id) })
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
  other.watch(fn(id, _) { left.val = Some(id) })
  other.watch(fn(id, _) { right.val = Some(id) })
  other_signal.send(())
  assert_true(left.val is Some(_))
  assert_true(right.val is Some(_))
  assert_true(left.val != right.val)

  let returned = other.watch_id(fn(_, _) { () })
  assert_true(returned > 0)
}

///|
fn stream_values() -> Array[Int] {
  [0, 1, 2, 3, 4, 5, 6, 7]
}

///|
fn is_even(value : Int) -> Bool {
  value % 2 == 0
}

///|
fn even_opt(value : Int) -> Int? {
  if is_even(value) {
    Some(value)
  } else {
    None
  }
}

///|
test "translated BAP stream map filter merge apply split and zip" {
  let values = stream_values()
  let (source, source_signal, _) = @future.Stream::of_array(values)
  let mapped = source.map(fn(value) { value + 1 })
  source_signal.repeat(times=2, ())
  assert_stream_before_eq(mapped, source_signal, repeat=4, [3, 4, 5, 6])

  let (many_source, many_signal, _) = @future.Stream::of_array([0, 1, 2])
  let many = many_source.map_many(fn(value) { [value, value] })
  assert_stream_before_eq(many, many_signal, repeat=3, [0, 0, 1, 1, 2, 2])

  let (prime_source, prime_signal, _) = @future.Stream::of_array([0, 1])
  let prime = prime_source.map_prime(fn(value) { [value, value + 10] })
  assert_stream_before_eq(prime, prime_signal, repeat=2, [0, 10, 1, 11])

  let (filtered_source, filtered_signal, _) = @future.Stream::of_array(values)
  let filtered = filtered_source.filter_map(even_opt)
  assert_stream_before_eq(filtered, filtered_signal, repeat=values.length(), [
    0, 2, 4, 6,
  ])

  let (kept_source, kept_signal, _) = @future.Stream::of_array(values)
  let kept = kept_source.filter(is_even)
  assert_stream_before_eq(kept, kept_signal, repeat=values.length(), [
    0, 2, 4, 6,
  ])

  let (left, left_signal, _) = @future.Stream::of_array([0, 1, 2, 3])
  let (right, right_signal, _) = @future.Stream::of_array([0, 1, 2, 3, 4, 5])
  let merged = left.merge(right, fn(l, r) { l * 10 + r })
  let merged_values : Array[Int] = []
  merged.observe(fn(value) { merged_values.push(value) })
  left_signal.repeat(times=6, ())
  right_signal.repeat(times=6, ())
  assert_true(merged_values == [0, 11, 22, 33])

  let functions : Array[(Int) -> Int] = [
    fn(value) { value + 0 },
    fn(value) { value + 1 },
    fn(value) { value + 2 },
    fn(value) { value + 3 },
  ]
  let (function_stream, function_signal, _) = @future.Stream::of_array(
    functions,
  )
  let (value_stream, value_signal, _) = @future.Stream::of_array([0, 1, 2, 3])
  let applied = @future.Stream::apply(function_stream, value_stream)
  let applied_values : Array[Int] = []
  applied.observe(fn(value) { applied_values.push(value) })
  function_signal.repeat(times=4, ())
  value_signal.repeat(times=4, ())
  assert_true(applied_values == [0, 2, 4, 6])

  let (split_source, split_signal, _) = @future.Stream::of_array([0, 1, 2, 3])
  let (split_left, split_right) = split_source.split(fn(value) {
    (value, value + 1)
  })
  let split_left_values : Array[Int] = []
  let split_right_values : Array[Int] = []
  split_left.observe(fn(value) { split_left_values.push(value) })
  split_right.observe(fn(value) { split_right_values.push(value) })
  split_signal.repeat(times=4, ())
  assert_true(split_left_values == [0, 1, 2, 3])
  assert_true(split_right_values == [1, 2, 3, 4])

  let (zip_left, zip_left_signal, _) = @future.Stream::of_array([0, 1, 2, 3])
  let (zip_right, zip_right_signal, _) = @future.Stream::of_array([4, 5])
  let zipped = zip_left.zip(zip_right)
  let zipped_values : Array[(Int, Int)] = []
  zipped.observe(fn(value) { zipped_values.push(value) })
  zip_left_signal.repeat(times=4, ())
  zip_right_signal.repeat(times=4, ())
  assert_true(zipped_values == [(0, 4), (1, 5)])

  let (unzip_source, unzip_signal, _) = @future.Stream::of_array([
    (0, "0"),
    (1, "1"),
    (2, "2"),
  ])
  let (unzipped_left, unzipped_right) = unzip_source.unzip()
  let unzipped_left_values : Array[Int] = []
  let unzipped_right_values : Array[String] = []
  unzipped_left.observe(fn(value) { unzipped_left_values.push(value) })
  unzipped_right.observe(fn(value) { unzipped_right_values.push(value) })
  unzip_signal.repeat(times=3, ())
  assert_true(unzipped_left_values == [0, 1, 2])
  assert_true(unzipped_right_values == ["0", "1", "2"])
}

///|
test "translated BAP stream multi-argument applicative helpers" {
  let (left, left_signal, _) = @future.Stream::of_array([1, 2])
  let (right, right_signal, _) = @future.Stream::of_array([10, 20])
  let mapped2 = @future.Stream::map2(left, right, fn(l, r) { l + r })
  let mapped2_values : Array[Int] = []
  mapped2.observe(fn(value) { mapped2_values.push(value) })
  left_signal.repeat(times=2, ())
  right_signal.repeat(times=2, ())
  assert_true(mapped2_values == [11, 22])

  let functions2 : Array[(Int, Int) -> Int] = [
    fn(l, r) { l + r },
    fn(l, r) { l * r },
  ]
  let (function2_stream, function2_signal, _) = @future.Stream::of_array(
    functions2,
  )
  let (apply2_left, apply2_left_signal, _) = @future.Stream::of_array([1, 2])
  let (apply2_right, apply2_right_signal, _) = @future.Stream::of_array([10, 20])
  let applied2 = @future.Stream::apply2(
    function2_stream, apply2_left, apply2_right,
  )
  let applied2_values : Array[Int] = []
  applied2.observe(fn(value) { applied2_values.push(value) })
  function2_signal.repeat(times=2, ())
  apply2_left_signal.repeat(times=2, ())
  apply2_right_signal.repeat(times=2, ())
  assert_true(applied2_values == [11, 40])

  let (first, first_signal, _) = @future.Stream::of_array([1, 2])
  let (second, second_signal, _) = @future.Stream::of_array([10, 20])
  let (third, third_signal, _) = @future.Stream::of_array([100, 200])
  let mapped3 = @future.Stream::map3(first, second, third, fn(a, b, c) {
    a + b + c
  })
  let mapped3_values : Array[Int] = []
  mapped3.observe(fn(value) { mapped3_values.push(value) })
  first_signal.repeat(times=2, ())
  second_signal.repeat(times=2, ())
  third_signal.repeat(times=2, ())
  assert_true(mapped3_values == [111, 222])

  let functions3 : Array[(Int, Int, Int) -> Int] = [
    fn(a, b, c) { a + b + c },
    fn(a, b, c) { a * b + c },
  ]
  let (function3_stream, function3_signal, _) = @future.Stream::of_array(
    functions3,
  )
  let (apply3_first, apply3_first_signal, _) = @future.Stream::of_array([1, 2])
  let (apply3_second, apply3_second_signal, _) = @future.Stream::of_array([
    10, 20,
  ])
  let (apply3_third, apply3_third_signal, _) = @future.Stream::of_array([
    100, 200,
  ])
  let applied3 = @future.Stream::apply3(
    function3_stream, apply3_first, apply3_second, apply3_third,
  )
  let applied3_values : Array[Int] = []
  applied3.observe(fn(value) { applied3_values.push(value) })
  function3_signal.repeat(times=2, ())
  apply3_first_signal.repeat(times=2, ())
  apply3_second_signal.repeat(times=2, ())
  apply3_third_signal.repeat(times=2, ())
  assert_true(applied3_values == [111, 240])

  let (map4_first, map4_first_signal, _) = @future.Stream::of_array([1, 2])
  let (map4_second, map4_second_signal, _) = @future.Stream::of_array([10, 20])
  let (map4_third, map4_third_signal, _) = @future.Stream::of_array([100, 200])
  let (map4_fourth, map4_fourth_signal, _) = @future.Stream::of_array([
    1000, 2000,
  ])
  let mapped4 = @future.Stream::map4(
    map4_first,
    map4_second,
    map4_third,
    map4_fourth,
    fn(a, b, c, d) { a + b + c + d },
  )
  let mapped4_values : Array[Int] = []
  mapped4.observe(fn(value) { mapped4_values.push(value) })
  map4_first_signal.repeat(times=2, ())
  map4_second_signal.repeat(times=2, ())
  map4_third_signal.repeat(times=2, ())
  map4_fourth_signal.repeat(times=2, ())
  assert_true(mapped4_values == [1111, 2222])

  let functions4 : Array[(Int, Int, Int, Int) -> Int] = [
    fn(a, b, c, d) { a + b + c + d },
    fn(a, b, c, d) { a * b + c + d },
  ]
  let (function4_stream, function4_signal, _) = @future.Stream::of_array(
    functions4,
  )
  let (apply4_first, apply4_first_signal, _) = @future.Stream::of_array([1, 2])
  let (apply4_second, apply4_second_signal, _) = @future.Stream::of_array([
    10, 20,
  ])
  let (apply4_third, apply4_third_signal, _) = @future.Stream::of_array([
    100, 200,
  ])
  let (apply4_fourth, apply4_fourth_signal, _) = @future.Stream::of_array([
    1000, 2000,
  ])
  let applied4 = @future.Stream::apply4(
    function4_stream, apply4_first, apply4_second, apply4_third, apply4_fourth,
  )
  let applied4_values : Array[Int] = []
  applied4.observe(fn(value) { applied4_values.push(value) })
  function4_signal.repeat(times=2, ())
  apply4_first_signal.repeat(times=2, ())
  apply4_second_signal.repeat(times=2, ())
  apply4_third_signal.repeat(times=2, ())
  apply4_fourth_signal.repeat(times=2, ())
  assert_true(applied4_values == [1111, 2240])

  let (map5_first, map5_first_signal, _) = @future.Stream::of_array([1, 2])
  let (map5_second, map5_second_signal, _) = @future.Stream::of_array([10, 20])
  let (map5_third, map5_third_signal, _) = @future.Stream::of_array([100, 200])
  let (map5_fourth, map5_fourth_signal, _) = @future.Stream::of_array([
    1000, 2000,
  ])
  let (map5_fifth, map5_fifth_signal, _) = @future.Stream::of_array([
    10000, 20000,
  ])
  let mapped5 = @future.Stream::map5(
    map5_first,
    map5_second,
    map5_third,
    map5_fourth,
    map5_fifth,
    fn(a, b, c, d, e) { a + b + c + d + e },
  )
  let mapped5_values : Array[Int] = []
  mapped5.observe(fn(value) { mapped5_values.push(value) })
  map5_first_signal.repeat(times=2, ())
  map5_second_signal.repeat(times=2, ())
  map5_third_signal.repeat(times=2, ())
  map5_fourth_signal.repeat(times=2, ())
  map5_fifth_signal.repeat(times=2, ())
  assert_true(mapped5_values == [11111, 22222])

  let functions5 : Array[(Int, Int, Int, Int, Int) -> Int] = [
    fn(a, b, c, d, e) { a + b + c + d + e },
    fn(a, b, c, d, e) { a * b + c + d + e },
  ]
  let (function5_stream, function5_signal, _) = @future.Stream::of_array(
    functions5,
  )
  let (apply5_first, apply5_first_signal, _) = @future.Stream::of_array([1, 2])
  let (apply5_second, apply5_second_signal, _) = @future.Stream::of_array([
    10, 20,
  ])
  let (apply5_third, apply5_third_signal, _) = @future.Stream::of_array([
    100, 200,
  ])
  let (apply5_fourth, apply5_fourth_signal, _) = @future.Stream::of_array([
    1000, 2000,
  ])
  let (apply5_fifth, apply5_fifth_signal, _) = @future.Stream::of_array([
    10000, 20000,
  ])
  let applied5 = @future.Stream::apply5(
    function5_stream, apply5_first, apply5_second, apply5_third, apply5_fourth, apply5_fifth,
  )
  let applied5_values : Array[Int] = []
  applied5.observe(fn(value) { applied5_values.push(value) })
  function5_signal.repeat(times=2, ())
  apply5_first_signal.repeat(times=2, ())
  apply5_second_signal.repeat(times=2, ())
  apply5_third_signal.repeat(times=2, ())
  apply5_fourth_signal.repeat(times=2, ())
  apply5_fifth_signal.repeat(times=2, ())
  assert_true(applied5_values == [11111, 22240])
}

///|
test "BAP-style stream args apply curried functions" {
  let (first, first_signal, _) = @future.Stream::of_array([1, 2])
  let (second, second_signal, _) = @future.Stream::of_array([10, 20])
  let (third, third_signal, _) = @future.Stream::of_array([100, 200])
  let args : @future.StreamArgs[(Int) -> (Int) -> (Int) -> Int, Int] = @future.StreamArgs::args(
      first,
    )
    .add(second)
    .add(third)
  let mapped = @future.StreamArgs::apply(
    fn(a) { fn(b) { fn(c) { a + b + c } } },
    args,
  )
  let values : Array[Int] = []
  mapped.observe(fn(value) { values.push(value) })
  first_signal.repeat(times=2, ())
  second_signal.repeat(times=2, ())
  third_signal.repeat(times=2, ())
  assert_true(values == [111, 222])
}

///|
test "BAP-style stream args step adapts a function input" {
  let (numbers, signal, _) = @future.Stream::of_array([7, 42])
  let args : @future.StreamArgs[(String) -> Int, Int] = @future.StreamArgs::args(
    numbers,
  ).step(fn(f : (String) -> Int) { fn(number : Int) { f(number.to_string()) } })
  let mapped = @future.StreamArgs::apply(
    fn(text : String) { text.length() + 1 },
    args,
  )
  let values : Array[Int] = []
  mapped.observe(fn(value) { values.push(value) })
  signal.repeat(times=2, ())
  assert_true(values == [2, 3])
}

///|
fn fulfill_after_signals(
  promise : @future.Promise[Unit],
  after~ : Int,
  max~ : Int,
  signal : @future.Signal[Unit],
) -> Unit raise {
  for index in 0..<(max + 1) {
    signal.send(())
    if index == after {
      promise.fulfill(())
    }
  }
}

///|
test "translated BAP stream once parse and selector futures" {
  let values = stream_values()

  let (once_source, once_signal, _) = @future.Stream::of_array(values)
  let once = once_source.once()
  assert_stream_before_eq(once, once_signal, repeat=values.length(), [0])

  let (parse_source, parse_signal, _) = @future.Stream::of_array(values)
  let parsed = parse_source.parse(init=0, f=fn(_, value) {
    if is_even(value) {
      (Some(value), value + 1)
    } else {
      (None, value + 1)
    }
  })
  assert_stream_before_eq(parsed, parse_signal, repeat=values.length(), [
    0, 2, 4, 6,
  ])

  let (hd_source, hd_signal, _) = @future.Stream::of_array(values)
  let hd = hd_source.hd()
  hd_signal.repeat(times=2, ())
  assert_true(hd.peek() == Some(0))

  let (empty_hd_source, empty_hd_signal, _) = @future.Stream::of_array([])
  let empty_hd : @future.Future[Int] = empty_hd_source.hd()
  empty_hd_signal.repeat(times=2, ())
  assert_true(!empty_hd.is_decided())

  let (tl_source, tl_signal, _) = @future.Stream::of_array(values)
  let tail = tl_source.tl()
  assert_stream_before_eq(tail, tl_signal, repeat=values.length(), [
    1, 2, 3, 4, 5, 6, 7,
  ])

  let (find_source, find_signal, _) = @future.Stream::of_array(values)
  let found = find_source.find(fn(value) { value == 3 })
  find_signal.repeat(times=values.length() + 1, ())
  assert_true(found.peek() == Some(3))

  let (missing_source, missing_signal, _) = @future.Stream::of_array(values)
  let missing = missing_source.find(fn(value) { value == 10 })
  missing_signal.repeat(times=values.length() + 1, ())
  assert_true(!missing.is_decided())

  let (find_map_source, find_map_signal, _) = @future.Stream::of_array(values)
  let found_map = find_map_source.find_map(fn(value) {
    if value == 3 {
      Some(value + 1)
    } else {
      None
    }
  })
  find_map_signal.repeat(times=values.length() + 1, ())
  assert_true(found_map.peek() == Some(4))

  let (take_source, take_signal, _) = @future.Stream::of_array(values)
  let taken = take_source.take(3)
  take_signal.repeat(times=values.length() + 1, ())
  assert_true(taken.peek() == Some([0, 1, 2]))

  let (take_zero_source, take_zero_signal, _) = @future.Stream::of_array(values)
  let taken_zero = take_zero_source.take(0)
  take_zero_signal.repeat(times=values.length() + 1, ())
  assert_true(taken_zero.peek() == Some([]))

  let (nth_source, nth_signal, _) = @future.Stream::of_array(values)
  let nth = nth_source.nth(3)
  nth_signal.repeat(times=4, ())
  assert_true(nth.peek() == Some(3))

  let (nth_missing_source, nth_missing_signal, _) = @future.Stream::of_array(
    values,
  )
  let nth_missing = nth_missing_source.nth(10)
  nth_missing_signal.repeat(times=11, ())
  assert_true(!nth_missing.is_decided())

  let (upon_source, upon_signal, _) = @future.Stream::of_array(values)
  let (event, promise) = @future.Future::create()
  let upon = upon_source.upon(event)
  fulfill_after_signals(promise, after=3, max=values.length(), upon_signal)
  assert_true(upon.peek() == Some(3))

  let (upon_missing_source, upon_missing_signal, _) = @future.Stream::of_array(
    values,
  )
  let (missing_event, _) : (@future.Future[Unit], @future.Promise[Unit]) = @future.Future::create()
  let upon_missing = upon_missing_source.upon(missing_event)
  upon_missing_signal.repeat(times=values.length() + 1, ())
  assert_true(!upon_missing.is_decided())

  let (last_source, last_signal, _) = @future.Stream::of_array(values)
  let (last_event, last_promise) = @future.Future::create()
  let last = last_source.last_before(last_event, 3)
  fulfill_after_signals(last_promise, after=2, max=values.length(), last_signal)
  assert_true(last.peek() == Some([0, 1, 2]))

  let (last_short_source, last_short_signal, _) = @future.Stream::of_array(
    values,
  )
  let (last_short_event, last_short_promise) = @future.Future::create()
  let last_short = last_short_source.last_before(last_short_event, 2)
  fulfill_after_signals(
    last_short_promise,
    after=4,
    max=values.length(),
    last_short_signal,
  )
  assert_true(last_short.peek() == Some([3, 4]))
}

///|
fn append_int(acc : Array[Int], value : Int) -> Array[Int] {
  let out = acc.copy()
  out.push(value)
  out
}

///|
fn run_time_line(
  signal : @future.Signal[Unit],
  clk_signal : @future.Signal[Unit],
  timeline : Array[Int],
) -> Unit {
  let index = Ref(0)
  let cursor = Ref(0)
  while cursor.val < timeline.length() {
    if timeline[cursor.val] == index.val {
      clk_signal.send(())
      cursor.val += 1
    } else {
      signal.send(())
      index.val += 1
    }
  }
}

///|
test "translated BAP stream batched unfold either concat and concat merge" {
  let (batched, batched_signal) = @future.Stream::unfold_many(init=0, f=fn(
    value,
  ) {
    ([value, value], value + 1)
  })
  assert_stream_before_eq(batched, batched_signal, repeat=3, [0, 0, 1, 1, 2, 2])

  let (prime_batched, prime_batched_signal) = @future.Stream::unfold_prime(
    init=1,
    f=fn(value) { ([value, value * 2], value + 1) },
  )
  assert_stream_before_eq(prime_batched, prime_batched_signal, repeat=2, [
    1, 2, 2, 4,
  ])

  let (left, left_signal, _) = @future.Stream::of_array([0, 1])
  let (right, right_signal, _) = @future.Stream::of_array(["a"])
  let either = left.either(right)
  let either_values : Array[@future.Either[Int, String]] = []
  either.observe(fn(value) { either_values.push(value) })
  left_signal.repeat(times=2, ())
  right_signal.send(())
  assert_true(either_values == [Left(0), Left(1), Right("a")])

  let (first, first_signal, _) = @future.Stream::of_array([1, 2])
  let (second, second_signal, _) = @future.Stream::of_array([10])
  let concatenated = @future.Stream::concat([first, second])
  let concatenated_values : Array[Int] = []
  concatenated.observe(fn(value) { concatenated_values.push(value) })
  first_signal.repeat(times=2, ())
  second_signal.send(())
  assert_true(concatenated_values == [1, 2, 10])

  let (merge_first, merge_first_signal, _) = @future.Stream::of_array([1, 2])
  let (merge_second, merge_second_signal, _) = @future.Stream::of_array([10])
  let merged = @future.Stream::concat_merge([merge_first, merge_second], fn(
    value,
    previous,
  ) {
    value + previous
  })
  let merged_values : Array[Int] = []
  merged.observe(fn(value) { merged_values.push(value) })
  merge_first_signal.repeat(times=2, ())
  merge_second_signal.send(())
  assert_true(merged_values == [1, 3, 13])
}

///|
test "BAP-style stream list adapters mirror list-facing OCaml APIs" {
  let values = @list.from_array([0, 1, 2, 3])
  let (list_stream, list_signal, list_finished) = @future.Stream::of_list(
    values,
  )
  assert_stream_before_eq(list_stream, list_signal, repeat=5, [0, 1, 2, 3])
  assert_true(list_finished.is_decided())

  let (before_source, before_signal, _) = @future.Stream::of_list(values)
  let (before_event, before_promise) = @future.Future::create()
  let before = before_source.before_list(before_event)
  before_signal.repeat(times=2, ())
  before_promise.fulfill(())
  assert_true(before.peek_exn().to_array() == [0, 1])

  let (last_source, last_signal, _) = @future.Stream::of_list(values)
  let (last_event, last_promise) = @future.Future::create()
  let last = last_source.last_before_list(last_event, 2)
  last_signal.repeat(times=3, ())
  last_promise.fulfill(())
  assert_true(last.peek_exn().to_array() == [1, 2])

  let (take_source, take_signal, _) = @future.Stream::of_list(values)
  let taken = take_source.take_list(3)
  take_signal.repeat(times=4, ())
  assert_true(taken.peek_exn().to_array() == [0, 1, 2])

  let (first, first_signal, _) = @future.Stream::of_list(
    @list.from_array([1, 2]),
  )
  let (second, second_signal, _) = @future.Stream::of_list(
    @list.from_array([10]),
  )
  let concatenated = @future.Stream::concat_list(
    @list.from_array([first, second]),
  )
  let concatenated_values : Array[Int] = []
  concatenated.observe(fn(value) { concatenated_values.push(value) })
  first_signal.repeat(times=2, ())
  second_signal.send(())
  assert_true(concatenated_values == [1, 2, 10])

  let (merge_first, merge_first_signal, _) = @future.Stream::of_list(
    @list.from_array([1, 2]),
  )
  let (merge_second, merge_second_signal, _) = @future.Stream::of_list(
    @list.from_array([10]),
  )
  let merged = @future.Stream::concat_merge_list(
    @list.from_array([merge_first, merge_second]),
    fn(value, previous) { value + previous },
  )
  let merged_values : Array[Int] = []
  merged.observe(fn(value) { merged_values.push(value) })
  merge_first_signal.repeat(times=2, ())
  merge_second_signal.send(())
  assert_true(merged_values == [1, 3, 13])
}

///|
test "translated BAP stream foldw frame and sample" {
  let values = stream_values()

  let (fold_source, fold_signal, _) = @future.Stream::of_array(values)
  let folded = fold_source.foldw(3, init=0, f=fn(acc, value) { acc + value })
  assert_stream_before_eq(folded, fold_signal, repeat=values.length() + 1, [
    3, 6, 9, 12, 15, 18,
  ])

  let (stride_source, stride_signal, _) = @future.Stream::of_array(values)
  let stride_folded = stride_source.foldw(
    3,
    init=0,
    f=fn(acc, value) { acc + value },
    stride=2,
  )
  assert_stream_before_eq(
    stride_folded,
    stride_signal,
    repeat=values.length() + 1,
    [3, 9, 15],
  )

  let (zero_source, zero_signal, _) = @future.Stream::of_array([0, 1, 2])
  let zero_width = zero_source.foldw(
    0,
    init=[1],
    f=fn(acc, value) { append_int(acc, value) },
    stride=0,
  )
  assert_stream_before_eq(zero_width, zero_signal, repeat=4, [[1], [1], [1]])

  let (frame_source, frame_signal, _) = @future.Stream::of_array(values)
  let (clock, clock_signal) = @future.Stream::from(fn() { () })
  let framed = frame_source.frame(clk=clock, init=[], f=append_int)
  let frames : Array[Array[Int]] = []
  framed.observe(fn(value) { frames.push(value) })
  run_time_line(frame_signal, clock_signal, [1, 1, 3])
  assert_true(frames == [[0], [], [1, 2]])

  let (sample_source, sample_signal, _) = @future.Stream::of_array(values)
  let (sample_clock, sample_clock_signal) = @future.Stream::from(fn() { () })
  let sampled = sample_source.sample(clk=sample_clock)
  let samples : Array[Int?] = []
  sampled.observe(fn(value) { samples.push(value) })
  run_time_line(sample_signal, sample_clock_signal, [0, 0, 1, 2])
  assert_true(samples == [None, None, Some(0), Some(1)])
}
