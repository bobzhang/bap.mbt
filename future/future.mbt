///|
pub(all) suberror FutureError {
  AlreadyDecided
  EmptyFuture
} derive(Eq, Debug)

///|
pub(all) enum Either[A, B] {
  Left(A)
  Right(B)
} derive(Eq, Debug)

///|
struct Future[T] {
  value : Ref[T?]
  waiters : Array[(T) -> Unit]
}

///|
struct Promise[T] {
  future : Future[T]
}

///|
pub fn[T] Future::create() -> (Future[T], Promise[T]) {
  let future = { value: Ref(None), waiters: [] }
  (future, { future, })
}

///|
pub fn[T] Future::resolved(value : T) -> Future[T] {
  { value: Ref(Some(value)), waiters: [] }
}

///|
pub fn[T] Future::full(value : T) -> Future[T] {
  Future::resolved(value)
}

///|
pub fn[T] Future::is_decided(self : Future[T]) -> Bool {
  self.value.val is Some(_)
}

///|
pub fn[T] Promise::is_fulfilled(self : Promise[T]) -> Bool {
  self.future.is_decided()
}

///|
pub fn[T] Future::peek(self : Future[T]) -> T? {
  self.value.val
}

///|
pub fn[T] Future::peek_exn(self : Future[T]) -> T raise FutureError {
  match self.value.val {
    Some(value) => value
    None => raise EmptyFuture
  }
}

///|
pub fn[T] Promise::try_fulfill(self : Promise[T], value : T) -> Bool {
  match self.future.value.val {
    Some(_) => false
    None => {
      self.future.value.val = Some(value)
      for waiter in self.future.waiters {
        waiter(value)
      }
      true
    }
  }
}

///|
pub fn[T] Promise::fulfill(
  self : Promise[T],
  value : T,
) -> Unit raise FutureError {
  if !self.try_fulfill(value) {
    raise AlreadyDecided
  }
}

///|
pub fn[T] Future::upon(self : Future[T], action : (T) -> Unit) -> Unit {
  match self.value.val {
    Some(value) => action(value)
    None => self.waiters.push(action)
  }
}

///|
pub fn[A, B] Future::bind(
  self : Future[A],
  next : (A) -> Future[B],
) -> Future[B] {
  let (out, promise) = Future::create()
  self.upon(fn(value) {
    next(value).upon(fn(result) { ignore(promise.try_fulfill(result)) })
  })
  out
}

///|
pub fn[A, B] Future::map(self : Future[A], f : (A) -> B) -> Future[B] {
  let (out, promise) = Future::create()
  self.upon(fn(value) { ignore(promise.try_fulfill(f(value))) })
  out
}

///|
pub fn[A, B] Future::apply(
  functions : Future[(A) -> B],
  values : Future[A],
) -> Future[B] {
  functions.bind(fn(f) { values.map(f) })
}

///|
pub fn[A, B, C] Future::map2(
  left : Future[A],
  right : Future[B],
  f : (A, B) -> C,
) -> Future[C] {
  left.bind(fn(l) { right.map(fn(r) { f(l, r) }) })
}

///|
pub fn[A, B] Future::both(
  left : Future[A],
  right : Future[B],
) -> Future[(A, B)] {
  Future::map2(left, right, fn(l, r) { (l, r) })
}

///|
pub fn[A, B, C, D] Future::map3(
  first : Future[A],
  second : Future[B],
  third : Future[C],
  f : (A, B, C) -> D,
) -> Future[D] {
  Future::map2(first, second, fn(a, b) { fn(c) { f(a, b, c) } }).apply(third)
}

///|
pub fn[A, B, C, D, E] Future::map4(
  first : Future[A],
  second : Future[B],
  third : Future[C],
  fourth : Future[D],
  f : (A, B, C, D) -> E,
) -> Future[E] {
  Future::map3(first, second, third, fn(a, b, c) { fn(d) { f(a, b, c, d) } }).apply(
    fourth,
  )
}

///|
pub fn[A, B, C, D, E, F] Future::map5(
  first : Future[A],
  second : Future[B],
  third : Future[C],
  fourth : Future[D],
  fifth : Future[E],
  f : (A, B, C, D, E) -> F,
) -> Future[F] {
  Future::map4(first, second, third, fourth, fn(a, b, c, d) {
    fn(e) { f(a, b, c, d, e) }
  }).apply(fifth)
}

///|
pub fn[A, B, C] Future::apply2(
  functions : Future[(A, B) -> C],
  left : Future[A],
  right : Future[B],
) -> Future[C] {
  functions.bind(fn(f) { Future::map2(left, right, f) })
}

///|
pub fn[A, B, C, D] Future::apply3(
  functions : Future[(A, B, C) -> D],
  first : Future[A],
  second : Future[B],
  third : Future[C],
) -> Future[D] {
  functions.bind(fn(f) { Future::map3(first, second, third, f) })
}

///|
pub fn[A, B, C, D, E] Future::apply4(
  functions : Future[(A, B, C, D) -> E],
  first : Future[A],
  second : Future[B],
  third : Future[C],
  fourth : Future[D],
) -> Future[E] {
  functions.bind(fn(f) { Future::map4(first, second, third, fourth, f) })
}

///|
pub fn[A, B, C, D, E, F] Future::apply5(
  functions : Future[(A, B, C, D, E) -> F],
  first : Future[A],
  second : Future[B],
  third : Future[C],
  fourth : Future[D],
  fifth : Future[E],
) -> Future[F] {
  functions.bind(fn(f) { Future::map5(first, second, third, fourth, fifth, f) })
}

///|
struct FutureArgs[F, R] {
  run : (Future[F]) -> Future[R]
}

///|
pub fn[R] FutureArgs::nil() -> FutureArgs[R, R] {
  { run: fn(functions) { functions } }
}

///|
pub fn[A, F, R] FutureArgs::cons(
  arg : Future[A],
  args : FutureArgs[F, R],
) -> FutureArgs[(A) -> F, R] {
  { run: fn(functions) { (args.run)(Future::apply(functions, arg)) } }
}

///|
pub fn[F1, F2, R] FutureArgs::step(
  args : FutureArgs[F1, R],
  f : (F2) -> F1,
) -> FutureArgs[F2, R] {
  { run: fn(functions) { (args.run)(functions.map(f)) } }
}

///|
pub fn[F, R] FutureArgs::applyN(
  functions : Future[F],
  args : FutureArgs[F, R],
) -> Future[R] {
  (args.run)(functions)
}

///|
pub fn[F, R] FutureArgs::mapN(f : F, args : FutureArgs[F, R]) -> Future[R] {
  FutureArgs::applyN(Future::resolved(f), args)
}

///|
pub fn[T] Future::all(futures : Array[Future[T]]) -> Future[Array[T]] {
  let (out, promise) = Future::create()
  let count = futures.length()
  if count == 0 {
    let empty : Array[T] = []
    ignore(promise.try_fulfill(empty))
  } else {
    let values : Array[T?] = []
    for _ in 0..<count {
      values.push(None)
    }
    let remaining = Ref(count)
    let finish = fn() {
      if remaining.val == 0 {
        let result : Array[T] = []
        for value in values {
          match value {
            Some(item) => result.push(item)
            None => ()
          }
        }
        ignore(promise.try_fulfill(result))
      }
    }
    for index in 0..<count {
      let slot = index
      futures[slot].upon(fn(value) {
        match values[slot] {
          Some(_) => ()
          None => {
            values[slot] = Some(value)
            remaining.val -= 1
            finish()
          }
        }
      })
    }
  }
  out
}

///|
pub fn[T] Future::all_list(
  futures : @list.List[Future[T]],
) -> Future[@list.List[T]] {
  Future::all(futures.to_array()).map(fn(values) { @list.from_array(values) })
}

///|
pub fn Future::all_unit(futures : Array[Future[Unit]]) -> Future[Unit] {
  Future::all(futures).map(fn(_) { () })
}

///|
pub fn Future::all_unit_list(
  futures : @list.List[Future[Unit]],
) -> Future[Unit] {
  Future::all_list(futures).map(fn(_) { () })
}

///|
struct Signal[T] {
  send_fn : (T) -> Unit
}

///|
struct Stream[T] {
  subscribers : Map[Int, (Int, T) -> Unit]
  last_id : Ref[Int]
  on_subscribe_callbacks : Array[(Int) -> Unit]
  on_unsubscribe_callbacks : Array[(Int) -> Unit]
  waiters : Array[() -> Unit]
}

///|
pub fn[T] Signal::send(self : Signal[T], value : T) -> Unit {
  (self.send_fn)(value)
}

///|
pub fn[T] Signal::repeat(self : Signal[T], times~ : Int, value : T) -> Unit {
  for _ in 0..<times {
    self.send(value)
  }
}

///|
fn[T] Stream::publish(self : Stream[T], value : T) -> Unit {
  let callbacks : Array[(Int, (Int, T) -> Unit)] = []
  for entry in self.subscribers {
    callbacks.push(entry)
  }
  for item in callbacks {
    let (id, notify) = item
    notify(id, value)
  }
}

///|
pub fn[T] Stream::create() -> (Stream[T], Signal[T]) {
  let stream = {
    subscribers: {},
    last_id: Ref(0),
    on_subscribe_callbacks: [],
    on_unsubscribe_callbacks: [],
    waiters: [],
  }
  let signal = { send_fn: fn(value) { stream.publish(value) } }
  (stream, signal)
}

///|
fn[T] Stream::add(self : Stream[T], notify : (Int, T) -> Unit) -> Int {
  self.last_id.val += 1
  let id = self.last_id.val
  self.subscribers[id] = notify
  for callback in self.on_subscribe_callbacks {
    callback(id)
  }
  id
}

///|
pub fn[T] Stream::subscribe(self : Stream[T], notify : (T) -> Unit) -> Int {
  self.add(fn(_, value) { notify(value) })
}

///|
pub fn[T] Stream::watch_id(self : Stream[T], notify : (Int, T) -> Unit) -> Int {
  self.add(notify)
}

///|
pub fn[T] Stream::watch(self : Stream[T], notify : (Int, T) -> Unit) -> Unit {
  ignore(self.watch_id(notify))
}

///|
pub fn[T] Stream::observe(self : Stream[T], notify : (T) -> Unit) -> Unit {
  ignore(self.subscribe(notify))
}

///|
pub fn[T] Stream::unsubscribe(self : Stream[T], id : Int) -> Unit {
  self.subscribers.remove(id)
  for callback in self.on_unsubscribe_callbacks {
    callback(id)
  }
}

///|
pub fn[T] Stream::has_subscribers(self : Stream[T]) -> Bool {
  !self.subscribers.is_empty()
}

///|
pub fn[T] Stream::wait(self : Stream[T]) -> Unit {
  for waiter in self.waiters {
    waiter()
  }
}

///|
pub fn[T] Stream::on_wait(self : Stream[T], callback : () -> Unit) -> Unit {
  self.waiters.push(callback)
}

///|
pub fn[T] Stream::on_subscribe(
  self : Stream[T],
  callback : (Int) -> Unit,
) -> Unit {
  self.on_subscribe_callbacks.push(callback)
}

///|
pub fn[T] Stream::on_unsubscribe(
  self : Stream[T],
  callback : (Int) -> Unit,
) -> Unit {
  self.on_unsubscribe_callbacks.push(callback)
}

///|
pub fn[T] Stream::from(generator : () -> T) -> (Stream[T], Signal[Unit]) {
  let (stream, signal) = Stream::create()
  let signal = { send_fn: fn(_) { signal.send(generator()) } }
  (stream, signal)
}

///|
pub fn[T] Stream::repeat(value : T) -> (Stream[T], Signal[Unit]) {
  Stream::from(fn() { value })
}

///|
pub fn[S, T] Stream::unfold(
  init~ : S,
  f~ : (S) -> (T, S),
) -> (Stream[T], Signal[Unit]) {
  let state = Ref(init)
  Stream::from(fn() {
    let (value, next) = f(state.val)
    state.val = next
    value
  })
}

///|
pub fn[S, T] Stream::unfold_many(
  init~ : S,
  f~ : (S) -> (Array[T], S),
) -> (Stream[T], Signal[Unit]) {
  let state = Ref(init)
  let (stream, signal) = Stream::create()
  let signal = {
    send_fn: fn(_) {
      let (values, next) = f(state.val)
      state.val = next
      for value in values {
        signal.send(value)
      }
    },
  }
  (stream, signal)
}

///|
pub fn[S, T] Stream::unfold_prime(
  init~ : S,
  f~ : (S) -> (Array[T], S),
) -> (Stream[T], Signal[Unit]) {
  Stream::unfold_many(init~, f~)
}

///|
pub fn[S, T] Stream::unfold_until(
  init~ : S,
  f~ : (S) -> (T, S)?,
) -> (Stream[T], Signal[Unit], Future[Unit]) {
  let (stream, signal) = Stream::create()
  let (finished, promise) = Future::create()
  let state = Ref(init)
  let done = Ref(false)
  let signal = {
    send_fn: fn(_) {
      if !done.val {
        match f(state.val) {
          Some((value, next)) => {
            state.val = next
            signal.send(value)
          }
          None => {
            done.val = true
            ignore(promise.try_fulfill(()))
          }
        }
      }
    },
  }
  (stream, signal, finished)
}

///|
pub fn[T] Stream::of_array(
  values : Array[T],
) -> (Stream[T], Signal[Unit], Future[Unit]) {
  let values = values.copy()
  Stream::unfold_until(init=0, f=fn(index) {
    if index < values.length() {
      Some((values[index], index + 1))
    } else {
      None
    }
  })
}

///|
pub fn[T] Stream::of_list(
  values : @list.List[T],
) -> (Stream[T], Signal[Unit], Future[Unit]) {
  Stream::of_array(values.to_array())
}

///|
pub fn[T] Stream::of_iter(
  values : Iter[T],
) -> (Stream[T], Signal[Unit], Future[Unit]) {
  Stream::unfold_until(init=values, f=fn(iter) {
    match iter.next() {
      Some(value) => Some((value, iter))
      None => None
    }
  })
}

///|
pub fn[T] Stream::of_sequence(
  values : Iter[T],
) -> (Stream[T], Signal[Unit], Future[Unit]) {
  Stream::of_iter(values)
}

///|
pub fn[T, E] Stream::before(
  self : Stream[T],
  event : Future[E],
) -> Future[Array[T]] {
  let (future, promise) = Future::create()
  let buffer : Array[T] = []
  let id = self.subscribe(fn(value) { buffer.push(value) })
  event.upon(fn(_) {
    self.unsubscribe(id)
    ignore(promise.try_fulfill(buffer.copy()))
  })
  future
}

///|
pub fn[T, E] Stream::before_list(
  self : Stream[T],
  event : Future[E],
) -> Future[@list.List[T]] {
  self.before(event).map(fn(values) { @list.from_array(values) })
}

///|
fn[A, B] Stream::link(
  self : Stream[A],
  target : Stream[B],
  step : (A) -> Unit,
) -> Unit {
  let key : Ref[Int?] = Ref(None)
  target.on_subscribe(fn(_) {
    match key.val {
      Some(_) => ()
      None => key.val = Some(self.subscribe(step))
    }
  })
  target.on_unsubscribe(fn(_) {
    if !target.has_subscribers() {
      match key.val {
        Some(id) => {
          self.unsubscribe(id)
          key.val = None
        }
        None => ()
      }
    }
  })
  target.on_wait(fn() { self.wait() })
}

///|
pub fn[A, B] Stream::map_many(
  self : Stream[A],
  f : (A) -> Array[B],
) -> Stream[B] {
  let (target, signal) = Stream::create()
  self.link(target, fn(value) {
    for mapped in f(value) {
      signal.send(mapped)
    }
  })
  target
}

///|
pub fn[A, B] Stream::map_prime(
  self : Stream[A],
  f : (A) -> Array[B],
) -> Stream[B] {
  self.map_many(f)
}

///|
pub fn[A, B] Stream::filter_map(self : Stream[A], f : (A) -> B?) -> Stream[B] {
  self.map_many(fn(value) {
    match f(value) {
      Some(mapped) => [mapped]
      None => []
    }
  })
}

///|
pub fn[T] Stream::filter(self : Stream[T], f : (T) -> Bool) -> Stream[T] {
  self.filter_map(fn(value) { if f(value) { Some(value) } else { None } })
}

///|
pub fn[A, B] Stream::map(self : Stream[A], f : (A) -> B) -> Stream[B] {
  self.map_many(fn(value) { [f(value)] })
}

///|
pub fn[A, B, C] Stream::merge(
  self : Stream[A],
  other : Stream[B],
  f : (A, B) -> C,
) -> Stream[C] {
  let (target, signal) = Stream::create()
  let left : Array[A] = []
  let right : Array[B] = []
  let process = fn() {
    while left.length() > 0 && right.length() > 0 {
      let l = left.remove(0)
      let r = right.remove(0)
      signal.send(f(l, r))
    }
  }
  self.link(target, fn(value) {
    left.push(value)
    process()
  })
  other.link(target, fn(value) {
    right.push(value)
    process()
  })
  target
}

///|
pub fn[A, B] Stream::either(
  self : Stream[A],
  other : Stream[B],
) -> Stream[Either[A, B]] {
  let (target, signal) = Stream::create()
  self.link(target, fn(value) { signal.send(Left(value)) })
  other.link(target, fn(value) { signal.send(Right(value)) })
  target
}

///|
pub fn[A, B] Stream::apply(
  functions : Stream[(A) -> B],
  values : Stream[A],
) -> Stream[B] {
  functions.merge(values, fn(f, value) { f(value) })
}

///|
pub fn[A, B, C] Stream::map2(
  left : Stream[A],
  right : Stream[B],
  f : (A, B) -> C,
) -> Stream[C] {
  left.merge(right, f)
}

///|
pub fn[A, B, C, D] Stream::map3(
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
  f : (A, B, C) -> D,
) -> Stream[D] {
  first
  .zip(second)
  .merge(third, fn(pair, c) {
    let (a, b) = pair
    f(a, b, c)
  })
}

///|
pub fn[A, B, C, D, E] Stream::map4(
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
  fourth : Stream[D],
  f : (A, B, C, D) -> E,
) -> Stream[E] {
  first
  .zip(second)
  .zip(third)
  .merge(fourth, fn(pair, d) {
    let ((a, b), c) = pair
    f(a, b, c, d)
  })
}

///|
pub fn[A, B, C, D, E, F] Stream::map5(
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
  fourth : Stream[D],
  fifth : Stream[E],
  f : (A, B, C, D, E) -> F,
) -> Stream[F] {
  first
  .zip(second)
  .zip(third)
  .zip(fourth)
  .merge(fifth, fn(pair, e) {
    let (((a, b), c), d) = pair
    f(a, b, c, d, e)
  })
}

///|
pub fn[A, B, C] Stream::apply2(
  functions : Stream[(A, B) -> C],
  left : Stream[A],
  right : Stream[B],
) -> Stream[C] {
  Stream::map3(functions, left, right, fn(f, l, r) { f(l, r) })
}

///|
pub fn[A, B, C, D] Stream::apply3(
  functions : Stream[(A, B, C) -> D],
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
) -> Stream[D] {
  functions
  .zip(first)
  .zip(second)
  .merge(third, fn(pair, c) {
    let ((f, a), b) = pair
    f(a, b, c)
  })
}

///|
pub fn[A, B, C, D, E] Stream::apply4(
  functions : Stream[(A, B, C, D) -> E],
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
  fourth : Stream[D],
) -> Stream[E] {
  functions
  .zip(first)
  .zip(second)
  .zip(third)
  .merge(fourth, fn(pair, d) {
    let (((f, a), b), c) = pair
    f(a, b, c, d)
  })
}

///|
pub fn[A, B, C, D, E, F] Stream::apply5(
  functions : Stream[(A, B, C, D, E) -> F],
  first : Stream[A],
  second : Stream[B],
  third : Stream[C],
  fourth : Stream[D],
  fifth : Stream[E],
) -> Stream[F] {
  functions
  .zip(first)
  .zip(second)
  .zip(third)
  .zip(fourth)
  .merge(fifth, fn(pair, e) {
    let ((((f, a), b), c), d) = pair
    f(a, b, c, d, e)
  })
}

///|
struct StreamArgs[F, R] {
  run : (F) -> Stream[R]
}

///|
pub fn[A, R] StreamArgs::args(arg : Stream[A]) -> StreamArgs[(A) -> R, R] {
  { run: fn(f) { arg.map(f) } }
}

///|
pub fn[F, A, R] StreamArgs::add(
  self : StreamArgs[F, (A) -> R],
  arg : Stream[A],
) -> StreamArgs[F, R] {
  { run: fn(f) { Stream::apply((self.run)(f), arg) } }
}

///|
pub fn[F1, F2, R] StreamArgs::step(
  self : StreamArgs[F1, R],
  f : (F2) -> F1,
) -> StreamArgs[F2, R] {
  { run: fn(function) { (self.run)(f(function)) } }
}

///|
pub fn[F, R] StreamArgs::apply(f : F, args : StreamArgs[F, R]) -> Stream[R] {
  (args.run)(f)
}

///|
pub fn[A, B] Stream::zip(self : Stream[A], other : Stream[B]) -> Stream[(A, B)] {
  self.merge(other, fn(left, right) { (left, right) })
}

///|
pub fn[A, B, C] Stream::split(
  self : Stream[A],
  f : (A) -> (B, C),
) -> (Stream[B], Stream[C]) {
  let (left, left_signal) = Stream::create()
  let (right, right_signal) = Stream::create()
  self.link(left, fn(value) {
    let (l, _) = f(value)
    left_signal.send(l)
  })
  self.link(right, fn(value) {
    let (_, r) = f(value)
    right_signal.send(r)
  })
  (left, right)
}

///|
pub fn[A, B] Stream::unzip(self : Stream[(A, B)]) -> (Stream[A], Stream[B]) {
  self.split(fn(value) { value })
}

///|
pub fn[T] Stream::once(self : Stream[T]) -> Stream[T] {
  let (target, signal) = Stream::create()
  let key : Ref[Int?] = Ref(None)
  target.on_subscribe(fn(_) {
    match key.val {
      Some(_) => ()
      None => {
        let id = self.watch_id(fn(id, value) {
          signal.send(value)
          self.unsubscribe(id)
          key.val = None
        })
        key.val = Some(id)
      }
    }
  })
  target.on_unsubscribe(fn(_) {
    if !target.has_subscribers() {
      match key.val {
        Some(id) => {
          self.unsubscribe(id)
          key.val = None
        }
        None => ()
      }
    }
  })
  target.on_wait(fn() { self.wait() })
  target
}

///|
pub fn[S, A, B] Stream::parse(
  self : Stream[A],
  init~ : S,
  f~ : (S, A) -> (B?, S),
) -> Stream[B] {
  let state = Ref(init)
  self.filter_map(fn(value) {
    let (result, next) = f(state.val, value)
    state.val = next
    result
  })
}

///|
fn[A, B] Stream::resolve_and_unsubscribe(
  self : Stream[A],
  id : Int,
  value : B,
  promise : Promise[B],
) -> Unit {
  self.unsubscribe(id)
  ignore(promise.try_fulfill(value))
}

///|
pub fn[T, E] Stream::upon(self : Stream[T], event : Future[E]) -> Future[T] {
  let latest : Ref[T?] = Ref(None)
  self.observe(fn(value) { latest.val = Some(value) })
  let (future, promise) = Future::create()
  event.upon(fn(_) {
    match latest.val {
      Some(value) => ignore(promise.try_fulfill(value))
      None => ()
    }
  })
  future
}

///|
pub fn[T, E] Stream::last_before(
  self : Stream[T],
  event : Future[E],
  count : Int,
) -> Future[Array[T]] {
  let buffer : Array[T] = []
  let id = self.subscribe(fn(value) {
    if buffer.length() >= count && buffer.length() > 0 {
      ignore(buffer.remove(0))
    }
    buffer.push(value)
  })
  let (future, promise) = Future::create()
  event.upon(fn(_) { self.resolve_and_unsubscribe(id, buffer.copy(), promise) })
  future
}

///|
pub fn[T, E] Stream::last_before_list(
  self : Stream[T],
  event : Future[E],
  count : Int,
) -> Future[@list.List[T]] {
  self.last_before(event, count).map(fn(values) { @list.from_array(values) })
}

///|
pub fn[T] Stream::take(self : Stream[T], count : Int) -> Future[Array[T]] {
  let buffer : Array[T] = []
  let (future, promise) = Future::create()
  ignore(
    self.watch_id(fn(id, value) {
      if buffer.length() < count {
        buffer.push(value)
      }
      if buffer.length() == count {
        self.resolve_and_unsubscribe(id, buffer.copy(), promise)
      }
    }),
  )
  future
}

///|
pub fn[T] Stream::take_list(
  self : Stream[T],
  count : Int,
) -> Future[@list.List[T]] {
  self.take(count).map(fn(values) { @list.from_array(values) })
}

///|
pub fn[T] Stream::nth(self : Stream[T], index : Int) -> Future[T] {
  let seen = Ref(0)
  let (future, promise) = Future::create()
  ignore(
    self.watch_id(fn(id, value) {
      if seen.val == index {
        self.resolve_and_unsubscribe(id, value, promise)
      }
      seen.val += 1
    }),
  )
  future
}

///|
pub fn[T] Stream::find(self : Stream[T], f : (T) -> Bool) -> Future[T] {
  let (future, promise) = Future::create()
  ignore(
    self.watch_id(fn(id, value) {
      if f(value) {
        self.resolve_and_unsubscribe(id, value, promise)
      }
    }),
  )
  future
}

///|
pub fn[A, B] Stream::find_map(self : Stream[A], f : (A) -> B?) -> Future[B] {
  let (future, promise) = Future::create()
  ignore(
    self.watch_id(fn(id, value) {
      match f(value) {
        Some(result) => self.resolve_and_unsubscribe(id, result, promise)
        None => ()
      }
    }),
  )
  future
}

///|
pub fn[T] Stream::hd(self : Stream[T]) -> Future[T] {
  self.nth(0)
}

///|
pub fn[T] Stream::tl(self : Stream[T]) -> Stream[T] {
  let skipped = Ref(false)
  let (target, signal) = Stream::create()
  self.link(target, fn(value) {
    if skipped.val {
      signal.send(value)
    } else {
      skipped.val = true
    }
  })
  target
}

///|
pub fn[T] Stream::concat(streams : Array[Stream[T]]) -> Stream[T] {
  let (target, signal) = Stream::create()
  for stream in streams {
    stream.observe(fn(value) { signal.send(value) })
  }
  target
}

///|
pub fn[T] Stream::concat_list(streams : @list.List[Stream[T]]) -> Stream[T] {
  Stream::concat(streams.to_array())
}

///|
pub fn[T] Stream::concat_merge(
  streams : Array[Stream[T]],
  f : (T, T) -> T,
) -> Stream[T] {
  Stream::concat(streams).parse(init=None, f=fn(previous, value) {
    match previous {
      Some(prev) => {
        let merged = f(value, prev)
        (Some(merged), Some(merged))
      }
      None => (Some(value), Some(value))
    }
  })
}

///|
pub fn[T] Stream::concat_merge_list(
  streams : @list.List[Stream[T]],
  f : (T, T) -> T,
) -> Stream[T] {
  Stream::concat_merge(streams.to_array(), f)
}

///|
fn[T] drop_front(buffer : Array[T], count : Int) -> Int {
  let dropped = Ref(0)
  while dropped.val < count && buffer.length() > 0 {
    ignore(buffer.remove(0))
    dropped.val += 1
  }
  dropped.val
}

///|
pub fn[A, B] Stream::foldw(
  self : Stream[A],
  width : Int,
  init~ : B,
  f~ : (B, A) -> B,
  stride? : Int = 1,
) -> Stream[B] {
  let buffer : Array[A] = []
  let is_enough = fn() { buffer.length() == width }
  let estimate_drop = fn(pushed : Bool) {
    if stride == 0 {
      0
    } else if pushed {
      stride
    } else {
      stride - 1
    }
  }
  let publish = fn(pushed : Bool) {
    let result = buffer.fold(init~, f)
    let remaining_drop = estimate_drop(pushed) -
      drop_front(buffer, estimate_drop(pushed))
    (Some(result), remaining_drop)
  }
  let add = fn(value : A) {
    buffer.push(value)
    if is_enough() {
      publish(true)
    } else {
      (None, 0)
    }
  }
  let try_publish = fn(value : A) {
    if is_enough() {
      publish(false)
    } else {
      add(value)
    }
  }
  self.parse(init=0, f=fn(drop, value) {
    if drop == 0 {
      try_publish(value)
    } else {
      (None, drop - 1)
    }
  })
}

///|
fn[T] Stream::sync(self : Stream[T], clk : Stream[Unit]) -> Stream[Array[T]] {
  let buffer : Array[T] = []
  let (target, signal) = Stream::create()
  self.link(target, fn(value) { buffer.push(value) })
  clk.link(target, fn(_) {
    signal.send(buffer.copy())
    buffer.clear()
  })
  target
}

///|
pub fn[A, B] Stream::frame(
  self : Stream[A],
  clk~ : Stream[Unit],
  init~ : B,
  f~ : (B, A) -> B,
) -> Stream[B] {
  self.sync(clk).map(fn(values) { values.fold(init~, f) })
}

///|
pub fn[T] Stream::sample(self : Stream[T], clk~ : Stream[Unit]) -> Stream[T?] {
  self
  .sync(clk)
  .map(fn(values) { if values.length() == 0 { None } else { Some(values[0]) } })
}
