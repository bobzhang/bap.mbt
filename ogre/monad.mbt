// The Ogre monad (upstream `Ogre.S`, instantiated with the identity monad).
//
// Upstream the Ogre monad is a state monad over the document wrapped into an
// error monad, and `Make(M)` lifts it into an arbitrary user monad. MoonBit
// has neither higher-kinded types nor functors, so the port provides:
//
// - a direct-style core: [Context] holds the current document and its
//   methods (`require`, `request`, `foreach`, `collect`, `provide`) read or
//   update it, raising [OgreError] on failure;
// - [Ogre], a first-class computation `(Context) -> A raise OgreError` with
//   the usual monadic combinators, whose [eval] / [exec] / [run] start from a
//   given document.

///|
/// The state of an Ogre computation: the current document.
struct Context {
  mut doc : Doc
}

///|
/// Creates a context over a document.
pub fn Context::new(doc : Doc) -> Context {
  { doc, }
}

///|
/// The current document.
pub fn Context::doc(self : Context) -> Doc {
  self.doc
}

///|
/// `require(attr, that?)`: the one and only value of `attr` that satisfies
/// `that`. It is an error if there are no such values or more than one
/// (upstream `require`).
pub fn[A, K] Context::require(
  self : Context,
  attr : Attribute[A, K],
  that? : (A) -> Bool,
) -> A raise OgreError {
  let name = "required attribute \{attr.name}"
  let values = self.doc.get(attr)
  if values.is_empty() {
    ogre_fail("\{name} is not provided")
  }
  let values = match that {
    None => values
    Some(p) => values.filter(p)
  }
  match values {
    [x] => x
    [] => ogre_fail("\{name} doesn't satisfy the constraint")
    _ => ogre_fail("\{name} values are ambiguous")
  }
}

///|
/// `request(attr, that?)`: at most one value of `attr` that satisfies `that`
/// (upstream `request`). It is an error if there is more than one.
pub fn[A, K] Context::request(
  self : Context,
  attr : Attribute[A, K],
  that? : (A) -> Bool,
) -> A? raise OgreError {
  let values = self.doc.get(attr)
  let values = match that {
    None => values
    Some(p) => values.filter(p)
  }
  match values {
    [x] => Some(x)
    [] => None
    _ => ogre_fail("requested attribute \{attr.name} values are ambiguous")
  }
}

///|
/// Applies `f` to every row selected by `query` (upstream `foreach`).
///
/// Upstream returns a lazy sequence; the port evaluates the query eagerly
/// against the current document and returns the results in the same order.
pub fn[T, B] Context::foreach(
  self : Context,
  query : Query[T],
  f : (T) -> B,
) -> Array[B] raise OgreError {
  query.eval(self.doc, f)
}

///|
/// All rows selected by `query` (upstream `collect`).
pub fn[T] Context::collect(
  self : Context,
  query : Query[T],
) -> Array[T] raise OgreError {
  query.eval(self.doc, x => x)
}

///|
/// Stores an attribute value in the document (upstream `provide`).
pub fn[A, K] Context::provide(
  self : Context,
  attr : Attribute[A, K],
  value : K,
) -> Unit raise OgreError {
  self.doc = self.doc.put(attr, value) catch {
    _ => ogre_fail("failed to save an attribute")
  }
}

///|
/// An Ogre computation producing a value of type `A` (upstream `'a Ogre.t`).
struct Ogre[A] {
  run : (Context) -> A raise OgreError
}

///|
/// Wraps a direct-style computation over a [Context].
pub fn[A] Ogre::make(f : (Context) -> A raise OgreError) -> Ogre[A] {
  { run: f, }
}

///|
/// Runs the computation in an existing context (direct style).
pub fn[A] Ogre::perform(self : Ogre[A], ctx : Context) -> A raise OgreError {
  (self.run)(ctx)
}

///|
/// A computation that returns `value` (upstream `return`).
pub fn[A] Ogre::pure(value : A) -> Ogre[A] {
  { run: _ => value, }
}

///|
/// Upstream `lift`: for the identity base monad it is [Ogre::pure].
pub fn[A] Ogre::lift(value : A) -> Ogre[A] {
  Ogre::pure(value)
}

///|
/// Sequential composition (upstream `>>=`).
pub fn[A, B] Ogre::bind(self : Ogre[A], f : (A) -> Ogre[B]) -> Ogre[B] {
  { run: ctx => (f((self.run)(ctx)).run)(ctx), }
}

///|
/// Maps the result (upstream `>>|`).
pub fn[A, B] Ogre::map(self : Ogre[A], f : (A) -> B) -> Ogre[B] {
  { run: ctx => f((self.run)(ctx)), }
}

///|
/// Runs `self`, discards its result and runs `next` (upstream `>>`).
pub fn[A, B] Ogre::then(self : Ogre[A], next : Ogre[B]) -> Ogre[B] {
  {
    run: ctx => {
      ignore((self.run)(ctx))
      (next.run)(ctx)
    },
  }
}

///|
/// Flattens a nested computation (upstream `join`).
pub fn[A] Ogre::join(self : Ogre[Ogre[A]]) -> Ogre[A] {
  { run: ctx => ((self.run)(ctx).run)(ctx), }
}

///|
/// Discards the result (upstream `ignore_m`).
pub fn[A] Ogre::ignore(self : Ogre[A]) -> Ogre[Unit] {
  self.map(_ => ())
}

///|
/// Runs both computations, left to right (upstream `both`).
pub fn[A, B] Ogre::both(self : Ogre[A], other : Ogre[B]) -> Ogre[(A, B)] {
  {
    run: ctx => {
      let a = (self.run)(ctx)
      (a, (other.run)(ctx))
    },
  }
}

///|
/// Runs all computations in order, collecting the results (upstream
/// `all`).
pub fn[A] Ogre::all(ms : Array[Ogre[A]]) -> Ogre[Array[A]] {
  let ms = ms.copy()
  {
    run: ctx => {
      let result = []
      for m in ms {
        result.push((m.run)(ctx))
      }
      result
    },
  }
}

///|
/// Runs all computations in order (upstream `all_unit`).
pub fn Ogre::all_unit(ms : Array[Ogre[Unit]]) -> Ogre[Unit] {
  Ogre::all(ms).ignore()
}

///|
/// Monadic left fold over an array (upstream `List.fold`).
pub fn[A, B] Ogre::fold(
  xs : Array[A],
  init~ : B,
  f : (B, A) -> Ogre[B],
) -> Ogre[B] {
  let xs = xs.copy()
  {
    run: ctx => {
      let mut acc = init
      for x in xs {
        acc = (f(acc, x).run)(ctx)
      }
      acc
    },
  }
}

///|
/// Monadic iteration over an array (upstream `List.iter`).
pub fn[A] Ogre::iter(xs : Array[A], f : (A) -> Ogre[Unit]) -> Ogre[Unit] {
  Ogre::fold(xs, init=(), (_, x) => f(x))
}

///|
/// Monadic map over an array (upstream `List.map`).
pub fn[A, B] Ogre::map_array(
  xs : Array[A],
  f : (A) -> Ogre[B],
) -> Ogre[Array[B]] {
  Ogre::all(xs.map(f))
}

///|
/// See [Context::require].
pub fn[A, K] require(attr : Attribute[A, K], that? : (A) -> Bool) -> Ogre[A] {
  { run: ctx => ctx.require(attr, that?), }
}

///|
/// See [Context::request].
pub fn[A, K] request(attr : Attribute[A, K], that? : (A) -> Bool) -> Ogre[A?] {
  { run: ctx => ctx.request(attr, that?), }
}

///|
/// See [Context::foreach].
pub fn[T, B] foreach(query : Query[T], f : (T) -> B) -> Ogre[Array[B]] {
  { run: ctx => ctx.foreach(query, f), }
}

///|
/// See [Context::collect].
pub fn[T] collect(query : Query[T]) -> Ogre[Array[T]] {
  { run: ctx => ctx.collect(query), }
}

///|
/// See [Context::provide]. Upstream `provide attr v1 ... vn` is variadic;
/// here the field values are passed as the scheme's tuple.
pub fn[A, K] provide(attr : Attribute[A, K], value : K) -> Ogre[Unit] {
  { run: ctx => ctx.provide(attr, value), }
}

///|
/// Aborts the computation with an error (upstream `fail`).
pub fn[A] Ogre::fail(error : OgreError) -> Ogre[A] {
  { run: _ => raise error, }
}

///|
/// Aborts the computation with a message (upstream `failf`; use string
/// interpolation for formatting).
pub fn[A] Ogre::failf(message : String) -> Ogre[A] {
  Ogre::fail(OgreError(message))
}

///|
/// Runs a computation on a document, returning its result and the final
/// document (upstream `run`).
pub fn[A] run(m : Ogre[A], doc : Doc) -> (A, Doc) raise OgreError {
  let ctx = Context::new(doc)
  let a = (m.run)(ctx)
  (a, ctx.doc)
}

///|
/// Infers a value from the facts of a document (upstream `eval`).
pub fn[A] eval(m : Ogre[A], doc : Doc) -> A raise OgreError {
  run(m, doc).0
}

///|
/// Runs a computation for its effect on the document and returns the
/// updated document (upstream `exec`).
pub fn[A] exec(m : Ogre[A], doc : Doc) -> Doc raise OgreError {
  run(m, doc).1
}
