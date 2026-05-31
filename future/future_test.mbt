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
