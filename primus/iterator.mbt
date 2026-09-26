///|
/// An infinite iterator over a domain `D` with state `T`
/// (upstream `Primus.Iterator.Infinite.S`, a first-class module).
pub(all) struct Infinite[T, D] {
  min : D
  max : D
  value : (T) -> D
  next : (T) -> T
}

///|
/// A finite iterator (upstream `Primus.Iterator.Finite.S`).
pub(all) struct Finite[T, D] {
  min : D
  max : D
  value : (T) -> D
  next : (T) -> T?
}

///|
/// An iterator (upstream `('a,'e) Primus.Iterator.t`).
pub enum Iterator[T, D] {
  Fin(Finite[T, D])
  Inf(Infinite[T, D])
}

///|
pub fn[T, D] Iterator::finite(it : Finite[T, D]) -> Iterator[T, D] {
  Fin(it)
}

///|
pub fn[T, D] Iterator::infinite(it : Infinite[T, D]) -> Iterator[T, D] {
  Inf(it)
}

///|
/// Enumerates the values of the iterator starting from `init`
/// (upstream `Iterator.enum`). Infinite iterators produce infinite
/// sequences; use `Iter::take` to bound them.
pub fn[T, D] Iterator::to_iter(self : Iterator[T, D], init : T) -> Iter[D] {
  match self {
    Inf(it) => {
      let mut state = init
      Iter::new(() => {
        let v = (it.value)(state)
        state = (it.next)(state)
        Some(v)
      })
    }
    Fin(it) => {
      let mut state : T? = Some(init)
      Iter::new(() => {
        match state {
          None => None
          Some(s) => {
            state = (it.next)(s)
            Some((it.value)(s))
          }
        }
      })
    }
  }
}

///|
pub fn[T, D] Iterator::min(self : Iterator[T, D]) -> D {
  match self {
    Fin(it) => it.min
    Inf(it) => it.min
  }
}

///|
pub fn[T, D] Iterator::max(self : Iterator[T, D]) -> D {
  match self {
    Fin(it) => it.max
    Inf(it) => it.max
  }
}

///|
pub fn[T, D] Iterator::value(self : Iterator[T, D], state : T) -> D {
  match self {
    Fin(it) => (it.value)(state)
    Inf(it) => (it.value)(state)
  }
}
