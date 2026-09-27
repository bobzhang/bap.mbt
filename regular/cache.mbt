///|
/// A cache of values of type `T`, indexed by digests (upstream
/// `Data.Cache.t`).
struct Cache[T] {
  load_fn : (Digest) -> T?
  save_fn : (Digest, T) -> Unit
}

///|
pub fn[T] Cache::create(
  load~ : (Digest) -> T?,
  save~ : (Digest, T) -> Unit,
) -> Cache[T] {
  { load_fn: load, save_fn: save, }
}

///|
pub fn[T] Cache::oblivion() -> Cache[T] {
  { load_fn: _ => None, save_fn: (_, _) => (), }
}

///|
pub fn[T] Cache::load(self : Cache[T], key : Digest) -> T? {
  (self.load_fn)(key)
}

///|
pub fn[T] Cache::save(self : Cache[T], key : Digest, value : T) -> Unit {
  (self.save_fn)(key, value)
}

///|
/// A caching service (upstream `Data.Cache.Service`): a store of
/// serialized values indexed by digests. Upstream services are
/// polymorphic in the cached type and receive the reader and writer of
/// each cache; here a service stores bytes and `Cache::request` does the
/// (de)serialization.
pub(all) struct CacheService {
  /// the serialized value stored under a digest, if any
  load : (Digest) -> Bytes?
  /// stores a serialized value under a digest
  save : (Digest, Bytes) -> Unit
}

///|
/// The service that stores nothing (the default).
pub fn CacheService::oblivion() -> CacheService {
  { load: _ => None, save: (_, _) => (), }
}

///|
let cache_service : Ref[CacheService] = Ref(CacheService::oblivion())

///|
/// Installs the caching service (upstream `Data.Cache.Service.provide`),
/// e.g., the on-disk cache of the `cache` plugin.
pub fn provide_cache_service(service : CacheService) -> Unit {
  cache_service.val = service
}

///|
/// The currently provided caching service.
pub fn current_cache_service() -> CacheService {
  cache_service.val
}

///|
/// A cache backed by the provided caching service (upstream
/// `Data.Cache.Service.request reader writer`). Values are serialized with
/// `to_bytes` and deserialized with `of_bytes`; a value that fails to
/// deserialize is a cache miss.
///
/// The service is looked up on each access, so a cache requested before
/// a service is provided uses that service once it is.
pub fn[T] Cache::request(
  of_bytes~ : (Bytes) -> T?,
  to_bytes~ : (T) -> Bytes,
) -> Cache[T] {
  {
    load_fn: key => {
      match (cache_service.val.load)(key) {
        Some(bytes) => of_bytes(bytes)
        None => None
      }
    },
    save_fn: (key, value) => (cache_service.val.save)(key, to_bytes(value)),
  }
}
