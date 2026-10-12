// Port of `Bap_cache_main`: the `cache` plugin and the `bap cache`
// command.

///|
/// The name of the plugin and of its command.
pub let name : String = "cache"

///|
let doc : String =
  #|provides caching service
  #|
  #|# DESCRIPTION
  #|
  #|Provide caching service for all data types. The caching entry point is
  #|defined in the [Data] module of the [Regular] library.
  #|
  #|The cache plugin implements lock-free store/loading operations with O(1)
  #|complexity: the same cache folder can be safely shared between different
  #|processes without any performance impact and these operations don't
  #|depend on the cache size.
  #|
  #|Also, the plugin maintains the cache size below the certain level, unless
  #|the garbage collector is manually disabled via $(b,--disable-gc) option.
  #|The maximum occupied size of the cache is controlled by the $(b,size) and
  #|$(b,overhead) parameters and can be expressed as $(b, total-size = size +
  #|overhead * size), where $(b,size) is a cache capacity in Mb and
  #|$(b,overhead) is the percentage of allowed excess. Once the cache size
  #|reaches this maximum, $(b, 2 * capacity * overhead) of entries will be
  #|removed by GC on the next program run.
  #|
  #|GC is also lock-free and removes cache entries randomly with prioritizing
  #|larger ones.
  #|
  #|# SEE ALSO
  #|
  #|$(b,regular)(3)

///|
/// The report printed by `bap cache --info` (upstream `print_info`).
pub fn info_report(cfg : Config, size~ : Int32) -> String {
  let pad = (s : String) => s.pad_start(5, ' ')
  let buf = StringBuilder()
  buf.write_string("Capacity:     \{pad(cfg.capacity.to_string())} MB\n")
  buf.write_string("Current size: \{pad(size.to_string())} MB\n")
  buf.write_string("GC threshold: \{pad(cfg.gc_threshold().to_string())} MB\n")
  buf.write_string("Overhead:     \{pad(cfg.overhead.to_string())} %\n")
  // upstream prints a space after the flag
  buf.write_string("GC enabled:   \{pad(cfg.gc_enabled.to_string())} \n")
  buf.to_string()
}

///|
/// The options of the `cache` command, as listed after it runs without
/// an action (upstream `print_command_options`).
let command_options : Array[(String, String)] = [
  ("--capacity=N", "sets the capacity of the cached data to <N> Mb"),
  ("--clean", "cleanup the cache"),
  ("--disable-gc", "disables garbage collector"),
  ("--enable-gc", "enables garbage collector"),
  ("--info", "prints information about the cache and exits"),
  ("--overhead=P", "sets capacity overhead to <P> percents"),
  ("--run-gc", "runs garbage collector and exits"),
]

///|
/// The text printed by `bap cache` without an action.
pub fn command_options_report() -> String {
  let buf = StringBuilder()
  buf.write_string("Command options:\n")
  for opt in command_options {
    buf.write_string("  \{opt.0.pad_end(24, ' ')} \{opt.1}\n")
  }
  buf.to_string()
}

///|
/// The configuration updated with the `bap cache` options (upstream
/// `update_config`); `None` if no option is set.
pub fn update_config(
  cfg : Config,
  capacity? : Int32,
  overhead? : Int32,
  disable_gc? : Bool,
  enable_gc? : Bool,
) -> Config? {
  if capacity is None &&
    overhead is None &&
    disable_gc is None &&
    enable_gc is None {
    return None
  }
  let cfg = match capacity {
    Some(capacity) => { ..cfg, capacity, }
    None => cfg
  }
  let cfg = match overhead {
    Some(overhead) => { ..cfg, overhead, }
    None => cfg
  }
  let cfg = match disable_gc {
    Some(x) => { ..cfg, gc_enabled: !x, }
    None => cfg
  }
  let cfg = match enable_gc {
    Some(x) => { ..cfg, gc_enabled: x, }
    None => cfg
  }
  Some(cfg)
}

///|
/// Selects the cache root, prepares the cache, and runs the garbage
/// collector if the cache exceeds its threshold (upstream `init`).
pub fn start(dir? : String) -> Unit raise {
  if dir is Some(dir) {
    set_root(dir)
  }
  match initialize() {
    Ok(_) => ()
    Err(err) => fail("failed to initialize the cache: \{err}")
  }
  let cfg = read_config()
  if cfg.gc_enabled {
    ignore(shrink(cfg, by_threshold=true))
  }
}

///|
/// Makes the on-disk cache the caching service of `regular` (upstream
/// `provide_service`).
pub fn provide_service() -> Unit {
  reporter.info(message="caching to \{root()}")
  @regular.provide_cache_service(service())
}

///|
fn default_output(s : String) -> Unit {
  println(s.trim_end(chars="\n"))
}

///|
let output : Ref[(String) -> Unit] = Ref(default_output)

///|
/// Declares the `cache` plugin (the `--cache-dir` and `--cache-clean`
/// options, and the caching service) and the `bap cache` command to
/// `bap_main`. Idempotent: does nothing if the plugin is already
/// declared. `out` receives the output of the command.
pub fn register(out~ : (String) -> Unit = default_output) -> Unit raise {
  output.val = out
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["cache"], doc~, () => {
    let cache_dir = @bap_main.Configuration::parameter(
      doc="Use provided folder as a cache directory",
      @bap_main.Type::some(@bap_main.Type::string()).rename("DIR"),
      "dir",
    )
    let clean_flag = @bap_main.Configuration::flag(
      doc="Cleanup all caches. Deprecated, use $(b, bap cache --clean) instead",
      "clean",
    )
    @bap_main.Extension::register(ctxt => {
      start(dir?=ctxt.get(cache_dir))
      if ctxt.get(clean_flag) {
        ignore(clean())
        raise @bap_main.ExitRequested(0)
      }
      provide_service()
    })
    declare_command(cache_dir)
  })
}

///|
fn declare_command(cache_dir : @bap_main.Parameter[String?]) -> Unit raise {
  let clean = @bap_main.Command::flag(doc="cleanup the cache", "clean")
  let capacity = @bap_main.Command::parameter(
    doc="Set the capacity of cached data in Mb. The option value will persist between different runs of the program",
    aliases=["size"],
    @bap_main.Type::some(@bap_main.Type::int()).rename("N"),
    "capacity",
  )
  let overhead = @bap_main.Command::parameter(
    doc="Controls the aggressiveness of the garbage collector. The higher the number the more space will be wasted but the cache system will run faster. It is expressed as a percentage of the capacity parameter. The option value will persist between different runs of the program",
    @bap_main.Type::some(@bap_main.Type::int()).rename("N"),
    "overhead",
  )
  let run_gc = @bap_main.Command::flag(
    doc="runs garbage collector and exits",
    "run-gc",
  )
  let disable_gc = @bap_main.Command::parameter(
    doc="disables garbage collector. The option value will persist between different runs of the program",
    as_flag=Some(true),
    @bap_main.Type::some(@bap_main.Type::bool()),
    "disable-gc",
  )
  let enable_gc = @bap_main.Command::parameter(
    doc="enables garbage collector. The option value will persist between different runs of the program",
    as_flag=Some(true),
    @bap_main.Type::some(@bap_main.Type::bool()),
    "enable-gc",
  )
  let info = @bap_main.Command::flag(
    doc="prints information about the cache and exits",
    "info",
  )
  let grammar = @bap_main.Command::args()
    .add(clean)
    .add(capacity)
    .add(overhead)
    .add(run_gc)
    .add(disable_gc)
    .add(enable_gc)
    .add(info)
  @bap_main.Command::register(
    name,
    grammar,
    doc="provides options to control cache size and cache garbage collector.",
    clean => {
      capacity => {
        overhead => {
          run_gc => {
            disable_gc => {
              enable_gc => {
                info => {
                  ctxt => {
                    start(dir?=ctxt.get(cache_dir))
                    run_command(
                      clean_cache=clean,
                      capacity?,
                      overhead?,
                      run_gc~,
                      disable_gc?,
                      enable_gc?,
                      info~,
                    )
                  }
                }
              }
            }
          }
        }
      }
    },
  )
}

///|
/// The `bap cache` command, after the cache is started: persists the
/// configuration options if any is given; otherwise performs the first
/// requested action (`--clean`, `--info`, `--run-gc`); otherwise lists
/// the command options.
fn run_command(
  clean_cache~ : Bool,
  capacity? : Int32,
  overhead? : Int32,
  run_gc~ : Bool,
  disable_gc? : Bool,
  enable_gc? : Bool,
  info~ : Bool,
) -> Unit {
  let cfg = read_config()
  match update_config(cfg, capacity?, overhead?, disable_gc?, enable_gc?) {
    Some(cfg) => write_config(cfg)
    None =>
      if clean_cache {
        ignore(clean())
      } else if info {
        (output.val)(info_report(cfg, size=size()))
      } else if run_gc {
        ignore(shrink(cfg))
      } else {
        (output.val)(command_options_report())
      }
  }
}
