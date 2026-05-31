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
