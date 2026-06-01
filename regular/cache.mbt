///|
struct Cache[T] {
  load_fn : (Digest) -> T?
  save_fn : (Digest, T) -> Unit
}

///|
pub fn[T] Cache::create(
  load~ : (Digest) -> T?,
  save~ : (Digest, T) -> Unit,
) -> Cache[T] {
  { load_fn: load, save_fn: save }
}

///|
pub fn[T] Cache::oblivion() -> Cache[T] {
  { load_fn: _ => None, save_fn: (_, _) => () }
}

///|
pub fn[T] Cache::load(self : Cache[T], key : Digest) -> T? {
  (self.load_fn)(key)
}

///|
pub fn[T] Cache::save(self : Cache[T], key : Digest, value : T) -> Unit {
  (self.save_fn)(key, value)
}
