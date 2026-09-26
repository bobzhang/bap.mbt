///|
test "configuration defaults and bounds" {
  let cfg = @cache.Config::default()
  debug_inspect(
    cfg,
    content=(
      #|{ capacity: 4096, overhead: 25, gc_enabled: true }
    ),
  )
  inspect(cfg.gc_threshold(), content="5120")
  inspect(cfg.lower_bound(), content="3145728")
  let tiny = @cache.Config::new(capacity=10, overhead=200, gc_enabled=false)
  inspect(tiny.gc_threshold(), content="30")
  inspect(tiny.lower_bound(), content="0")
  inspect(@cache.config_file_name, content="config.3")
}

///|
test "configuration files use bin_prot" {
  let cfg = @cache.Config::default()
  // 4096 = 0xfe (int16) 00 10; 25; true
  inspect(
    @cache.Config::default().to_bytes(),
    content=(
      #|b"\xfe\x00\x10\x19\x01"
    ),
  )
  debug_inspect(
    @cache.Config::of_bytes(cfg.to_bytes()),
    content=(
      #|Some({ capacity: 4096, overhead: 25, gc_enabled: true })
    ),
  )
  for
    c in [
      @cache.Config::new(capacity=0, overhead=127, gc_enabled=false),
      @cache.Config::new(capacity=128, overhead=-1, gc_enabled=true),
      @cache.Config::new(capacity=40000, overhead=-200, gc_enabled=false),
      @cache.Config::new(capacity=0x7fffffff, overhead=-40000, gc_enabled=true),
    ] {
    assert_eq(@cache.Config::of_bytes(c.to_bytes()), Some(c))
  }
  inspect(
    @cache.Config::new(capacity=40000, overhead=-200, gc_enabled=false).to_bytes(),
    content=(
      #|b"\xfd@\x9c\x00\x00\xfe8\xff\x00"
    ),
  )
  assert_true(@cache.Config::of_bytes(b"") is None)
  assert_true(@cache.Config::of_bytes(b"\x01\x02") is None)
  assert_true(@cache.Config::of_bytes(b"\x01\x02\x05") is None)
  assert_true(@cache.Config::of_bytes(b"\xfe\x01") is None)
}

///|
test "updating the configuration" {
  let cfg = @cache.Config::default()
  debug_inspect(@cache.update_config(cfg), content="None")
  debug_inspect(
    @cache.update_config(cfg, capacity=100, overhead=10),
    content=(
      #|Some({ capacity: 100, overhead: 10, gc_enabled: true })
    ),
  )
  debug_inspect(
    @cache.update_config(cfg, disable_gc=true),
    content=(
      #|Some({ capacity: 4096, overhead: 25, gc_enabled: false })
    ),
  )
  // enable wins over disable, as upstream applies it last
  debug_inspect(
    @cache.update_config(cfg, disable_gc=true, enable_gc=true),
    content=(
      #|Some({ capacity: 4096, overhead: 25, gc_enabled: true })
    ),
  )
}

///|
/// A deterministic "random" generator cycling through `values`.
fn cycling(values : Array[Int]) -> (Int) -> Int {
  let i = Ref(0)
  limit => {
    let v = values[i.val % values.length()] % limit
    i.val += 1
    v
  }
}

///|
test "entries are selected by their cumulative size" {
  // sizes {4, 6, 3, 1, 6}: intervals [0,4) [4,10) [10,14) [14,18) [18,24)
  let sizes = [4, 6, 3, 1, 6]
  debug_inspect(
    @cache.select(sizes, total=20, to_free=10, cycling([5, 0, 19, 7])),
    content="[1, 0]",
  )
  debug_inspect(
    @cache.select(sizes, total=20, to_free=11, cycling([5, 0, 19, 7])),
    content="[1, 0, 4]",
  )
  // repeated draws are ignored
  debug_inspect(
    @cache.select(sizes, total=20, to_free=1, cycling([13, 13])),
    content="[2]",
  )
  debug_inspect(
    @cache.select(sizes, total=20, to_free=0, cycling([0])),
    content="[]",
  )
  debug_inspect(
    @cache.select([], total=0, to_free=5, cycling([0])),
    content="[]",
  )
}

///|
test "selection terminates when draws stop making progress" {
  // tiny entries make intervals start beyond the total size: the last
  // entries can never be drawn, so they are taken largest first
  let sizes = [1, 1, 2, 3, 5]
  debug_inspect(
    @cache.select(sizes, total=12, to_free=12, cycling([0])),
    content="[0, 4, 3, 2, 1]",
  )
}

///|
test "reports" {
  inspect(
    @cache.info_report(@cache.Config::default(), size=12),
    content=(
      #|Capacity:      4096 MB
      #|Current size:    12 MB
      #|GC threshold:  5120 MB
      #|Overhead:        25 %
      #|GC enabled:    true 
      #|
    ),
  )
  inspect(
    @cache.command_options_report(),
    content=(
      #|Command options:
      #|  --capacity=N             sets the capacity of the cached data to <N> Mb
      #|  --clean                  cleanup the cache
      #|  --disable-gc             disables garbage collector
      #|  --enable-gc              enables garbage collector
      #|  --info                   prints information about the cache and exits
      #|  --overhead=P             sets capacity overhead to <P> percents
      #|  --run-gc                 runs garbage collector and exits
      #|
    ),
  )
}

///|
test "the cache layout" {
  @cache.set_root("/work")
  inspect(@cache.root(), content="/work/.cache/bap")
  inspect(@cache.data_dir(), content="/work/.cache/bap/data")
  inspect(@cache.config_file(root="/r/"), content="/r/config.3")
  let key = @regular.digest(namespace_name="test", "key")
  inspect(
    @cache.entry_path(key, root="/r") == "/r/data/" + key.to_string(),
    content="true",
  )
  @cache.reset_root()
  inspect(@cache.root() == @bap_main.Configuration::cachedir(), content="true")
}
