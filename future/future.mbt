///|
pub(all) suberror FutureError {
  AlreadyDecided
  EmptyFuture
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
pub fn[T] Stream::watch(self : Stream[T], notify : (Int, T) -> Unit) -> Int {
  self.add(notify)
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
