///|
fn fresh_dir(name : String) -> String {
  @native_io.mkdir_p("_build/cache-plugin-tests").unwrap()
  @native_io.make_temp_dir(dir="_build/cache-plugin-tests", prefix=name).unwrap()
}

///|
fn entries_of(root : String) -> Array[String] {
  @native_io.read_dir(@cache.data_dir(root~)).unwrap()
}

///|
test "initialize creates the cache layout" {
  let dir = fresh_dir("init")
  let root = dir + "/.cache/bap"
  @cache.initialize(root~).unwrap()
  debug_inspect(
    @native_io.read_dir(root),
    content=(
      #|Ok(["config.3", "data"])
    ),
  )
  // the temporary folder is gone
  debug_inspect(
    @native_io.read_dir(dir + "/.cache"),
    content=(
      #|Ok(["bap"])
    ),
  )
  inspect(
    @native_io.stat(@cache.config_file(root~)).unwrap().perm,
    content="292",
  )
  assert_eq(@cache.read_config(root~), @cache.Config::default())
  let cfg = @cache.Config::new(capacity=100, overhead=10, gc_enabled=false)
  @cache.write_config(cfg, root~)
  assert_eq(@cache.read_config(root~), cfg)
  // initialization is idempotent and keeps the configuration
  @cache.initialize(root~).unwrap()
  assert_eq(@cache.read_config(root~), cfg)
  @native_io.remove_tree(dir).unwrap()
}

///|
test "an existing root gets the missing parts, old indexes are dropped" {
  let dir = fresh_dir("existing")
  let root = dir + "/bap"
  @native_io.mkdir_p(root).unwrap()
  @native_io.write_file(root + "/other-tool", b"x").unwrap()
  @native_io.write_file(root + "/index.2", b"old").unwrap()
  @cache.initialize(root~).unwrap()
  debug_inspect(
    @native_io.read_dir(root),
    content=(
      #|Ok(["config.3", "data", "other-tool"])
    ),
  )
  @native_io.remove_tree(dir).unwrap()
}

///|
test "entries are stored atomically and read back" {
  let dir = fresh_dir("entries")
  let root = dir + "/.cache/bap"
  @cache.initialize(root~).unwrap()
  let key = @regular.digest(namespace_name="test", "entry")
  assert_true(@cache.load(key, root~) is None)
  @cache.save(key, b"first", root~)
  assert_true(@cache.load(key, root~) == Some(b"first"))
  inspect(
    @native_io.stat(@cache.entry_path(key, root~)).unwrap().perm,
    content="292",
  )
  // a read-only entry can still be replaced
  @cache.save(key, b"second", root~)
  assert_true(@cache.load(key, root~) == Some(b"second"))
  assert_true(entries_of(root) == [key.to_string()])
  // the service stores the values of requested caches under the root
  @cache.set_root(dir)
  @regular.provide_cache_service(@cache.service())
  let cache = @regular.Cache::request(of_bytes=b => Some(b.length()), to_bytes=n => {
    Bytes::make(n, 0)
  })
  let other = @regular.digest(namespace_name="test", "other")
  cache.save(other, 3)
  debug_inspect(cache.load(other), content="Some(3)")
  inspect(entries_of(root).length(), content="2")
  @native_io.write_file(root + "/data/big", Bytes::make(3 * 1024 * 1024, 0)).unwrap()
  inspect(@cache.size(root~), content="3")
  @regular.provide_cache_service(@regular.CacheService::oblivion())
  @cache.reset_root()
  @native_io.remove_tree(dir).unwrap()
}

///|
test "the garbage collector shrinks the cache to its lower bound" {
  let dir = fresh_dir("gc")
  let root = dir + "/.cache/bap"
  @cache.initialize(root~).unwrap()
  for i in 0..<20 {
    @native_io.write_file(
      root + "/data/entry\{i}",
      Bytes::make((i + 1) * 20 * 1024, 0),
    ).unwrap()
  }
  // 20 entries of 20..400 Kb: 4200 Kb in total
  let total = () => {
    @cache.total_size(@cache.read_entries(@cache.data_dir(root~)))
  }
  inspect(total(), content="4200")
  // below the threshold nothing happens
  let cfg = @cache.Config::new(capacity=3, overhead=50)
  inspect(cfg.gc_threshold(), content="4")
  inspect(@cache.shrink(cfg, by_threshold=true, root~) > 0, content="true")
  assert_true(total() <= cfg.lower_bound())
  let remaining = total()
  inspect(
    @cache.shrink(@cache.Config::new(capacity=10), by_threshold=true, root~),
    content="0",
  )
  inspect(total() == remaining, content="true")
  // a collection in progress in another process is not disturbed
  let lock = @native_io.lock_file(root + "/gc.lock").unwrap()
  inspect(@cache.shrink(@cache.Config::new(capacity=0), root~), content="0")
  lock.unlock().unwrap()
  inspect(
    @cache.shrink(@cache.Config::new(capacity=0), root~) > 0,
    content="true",
  )
  inspect(total(), content="0")
  @native_io.write_file(root + "/data/x", b"x").unwrap()
  inspect(@cache.clean(root~), content="1")
  debug_inspect(entries_of(root), content="[]")
  @native_io.remove_tree(dir).unwrap()
}

///|
test "the cache command and plugin" {
  let dir = fresh_dir("plugin")
  let root = dir + "/.cache/bap"
  let run = (args : Array[String]) => {
    @bap_main.reset()
    let out = StringBuilder()
    @cache.register(out=s => out.write_string(s))
    // registering twice is harmless
    @cache.register(out=s => out.write_string(s))
    @bap_main.initialize(
      argv=["bap", ..args, "--cache-dir=\{dir}"],
      name="bap",
      env=_ => None,
      out=_ => (),
      err=_ => (),
    )
    out.to_string()
  }
  inspect(
    run(["cache", "--info"]),
    content=(
      #|Capacity:      4096 MB
      #|Current size:     0 MB
      #|GC threshold:  5120 MB
      #|Overhead:        25 %
      #|GC enabled:    true 
      #|
    ),
  )
  inspect(run(["cache", "--size=100", "--disable-gc"]), content="")
  debug_inspect(
    @cache.read_config(root~),
    content=(
      #|{ capacity: 100, overhead: 25, gc_enabled: false }
    ),
  )
  inspect(
    run(["cache"]).has_prefix("Command options:\n  --capacity=N"),
    content="true",
  )
  @cache.save(@regular.digest(namespace_name="t", "x"), b"data", root~)
  inspect(run(["cache", "--clean"]), content="")
  debug_inspect(entries_of(root), content="[]")
  // the deprecated `--cache-clean` cleans and exits
  @cache.save(@regular.digest(namespace_name="t", "y"), b"data", root~)
  let err = try run(["--cache-clean"]) catch {
    e => e
  } noraise {
    _ => fail("expected an exit request")
  }
  inspect(err, content="All is good.")
  debug_inspect(entries_of(root), content="[]")
  // otherwise the on-disk cache becomes the caching service
  ignore(run([]))
  let key = @regular.digest(namespace_name="t", "z")
  (@regular.current_cache_service().save)(key, b"z")
  assert_true(entries_of(root) == [key.to_string()])
  @bap_main.reset()
  @cache.reset_root()
  @regular.provide_cache_service(@regular.CacheService::oblivion())
  @native_io.remove_tree(dir).unwrap()
}
