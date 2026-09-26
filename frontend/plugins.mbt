// The statically linked plugins of the `bap` executable.
//
// Upstream BAP discovers the installed plugin bundles and loads them with
// `Dynlink`. Here every plugin is linked into the executable and declared
// in `bap_main`'s static registry by `declare_plugins`; to add a plugin,
// add one line to `plugin_table`.

///|
/// The input and output channels of the executable.
pub(all) struct Io {
  /// The standard output (receives complete text, with newlines).
  out : (String) -> Unit
  /// The standard error.
  err : (String) -> Unit
  /// Reads a line from the standard input (`None` at the end of input).
  read_line : () -> String?
  /// Writes a text file.
  write_file : (String, String) -> Result[Unit, String]
  /// The command line of the process.
  argv : Array[String]
}

///|
/// A plugin of the executable: its name and its declaration.
pub(all) struct StaticPlugin {
  name : String
  load : (Io) -> Unit raise
}

///|
/// All plugins linked into the executable, in no particular order (the
/// framework loads them in the alphabetical order of their names).
pub fn plugin_table() -> Array[StaticPlugin] {
  [
    // commands
    {
      name: "disassemble",
      load: io => {
        @disassemble.declare_plugin(out=io.out, write_file=io.write_file)
      },
    },
    {
      name: "mc",
      load: io => @mc.declare_plugin(out=io.out, read_line=io.read_line),
    },
    {
      name: "specification",
      load: io => @specification.declare_plugin(out=io.out),
    },
    {
      name: "recipe-command",
      load: io => {
        @recipe_command.declare_plugin(out=io.out, err=io.err, argv=io.argv)
      },
    },
    {
      name: "dependencies",
      load: io => @dependencies.declare_plugin(out=io.out),
    },
    { name: "cache", load: io => @cache.register(out=io.out), },
    // printers and analyses
    { name: "print", load: _ => @print.declare_plugin(), },
    {
      name: "callgraph-collator",
      load: _ => @callgraph_collator.declare_plugin(),
    },
    { name: "callsites", load: _ => @callsites.declare_plugin(), },
    { name: "constant-tracker", load: _ => @constant_tracker.declare_plugin(), },
    { name: "dump-symbols", load: _ => @dump_symbols.declare_plugin(), },
    { name: "emit-ida-script", load: _ => @emit_ida_script.declare_plugin(), },
    { name: "glibc-runtime", load: _ => @glibc_runtime.declare_plugin(), },
    { name: "optimization", load: _ => @optimization.declare_plugin(), },
    { name: "phoenix", load: _ => @phoenix.declare_plugin(), },
    { name: "read-symbols", load: _ => @read_symbols.declare_plugin(), },
    { name: "relocatable", load: _ => @relocatable.declare_plugin(), },
    { name: "report", load: _ => @report.declare_plugin(), },
    { name: "run", load: _ => @run.declare_plugin(), },
    { name: "strings", load: io => @strings.declare_plugin(out=io.out), },
    { name: "trace", load: io => @trace.declare_plugin(out=io.out), },
    { name: "byteweight", load: _ => @byteweight.declare_plugin(), },
    { name: "warn-unused", load: _ => @warn_unused.declare_plugin(), },
    { name: "taint", load: _ => declare_taint(), },
    { name: "propagate-taint", load: _ => declare_propagate_taint(), },
    // primus components
    {
      name: "primus-dictionary",
      load: _ => @primus_dictionary.declare_plugin(),
    },
    { name: "primus-exploring", load: _ => @primus_exploring.declare_plugin(), },
    { name: "primus-greedy", load: _ => @primus_greedy.declare_plugin(), },
    { name: "primus-limit", load: _ => @primus_limit.declare_plugin(), },
    { name: "primus-loader", load: _ => @primus_loader.declare_plugin(), },
    {
      name: "primus-mark-visited",
      load: _ => @primus_mark_visited.declare_plugin(),
    },
    { name: "primus-powerpc", load: _ => @primus_powerpc.declare_plugin(), },
    { name: "primus-print", load: _ => @primus_print.declare_plugin(), },
    {
      name: "primus-promiscuous",
      load: _ => @primus_promiscuous.declare_plugin(),
    },
    { name: "primus-random", load: _ => @primus_random.declare_plugin(), },
    { name: "primus-region", load: _ => @primus_region.declare_plugin(), },
    {
      name: "primus-round-robin",
      load: _ => @primus_round_robin.declare_plugin(),
    },
    { name: "primus-systems", load: _ => @primus_systems.declare_plugin(), },
    { name: "primus-wandering", load: _ => @primus_wandering.declare_plugin(), },
    { name: "primus-x86", load: _ => @primus_x86.declare_plugin(), },
    { name: "primus-taint", load: _ => declare_primus_taint(), },
    {
      name: "primus-propagate-taint",
      load: _ => declare_primus_propagate_taint(),
    },
  ]
}

///|
let services_registered : Ref[Bool] = Ref(false)

///|
/// Registers the services that upstream BAP provides through its core
/// plugins (loaders, disassembler, lifters, reconstructor, IR passes) and
/// the Primus components and Lisp semantics that do not depend on
/// command-line options. Done once per process.
pub fn register_services() -> Unit raise {
  if services_registered.val {
    return
  }
  services_registered.val = true
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_builtin_services() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  @disassemble.register_recursive_driver()
  @primus_track_visited.register() |> ignore
  @primus_lisp.register_components()
  @primus_lisp.register_semantics_providers()
}

// Declarations of the plugins whose packages expose only the registration
// function (the counterparts of their upstream `Config.declare_extension`).

///|
fn declare_taint() -> Unit raise {
  @bap_main.register_plugin(
    "taint",
    provides=["taint", "analysis", "dataflow"],
    doc="marks terms as taint sources",
    () => {
      let strain = @bap_main.Type::create(
        name="STRAIN",
        parse=s => {
          match @taint.parse_strain(s) {
            Ok(strain) => strain
            Err(msg) => fail(msg)
          }
        },
        print=s => @taint.strain_to_string(s),
        [],
      )
      let regs = @bap_main.Configuration::parameters(
        doc="Taints the values stored in the registers defined by the terms that satisfy the specified strain",
        strain,
        "reg",
      )
      let ptrs = @bap_main.Configuration::parameters(
        doc="Taints the memory pointed by the values of the terms that satisfy the specified strain",
        strain,
        "ptr",
      )
      @bap_main.Extension::register(ctxt => {
        match @taint.register(regs=ctxt.get(regs), ptrs=ctxt.get(ptrs)) {
          Ok(_) => ()
          Err(msg) => fail(msg)
        }
      })
    },
  )
}

///|
fn declare_propagate_taint() -> Unit raise {
  @bap_main.register_plugin(
    "propagate-taint",
    provides=["taint", "pass"],
    doc="propagates taint with the microexecution",
    () => {
      @bap_main.Extension::register(_ => {
        match @propagate_taint.register() {
          Ok(_) => ()
          Err(msg) => fail(msg)
        }
      })
    },
  )
}

///|
fn declare_primus_taint() -> Unit raise {
  @bap_main.register_plugin(
    "primus-taint",
    provides=["dataflow", "pass", "taint", "primus", "primus-lisp"],
    doc="a taint analysis control interface",
    () => {
      let policy = @bap_main.Configuration::parameter(
        doc="Sets the default tainting policy",
        @bap_main.Type::string().with_default(@primus_taint.default_policy),
        "default-policy",
      )
      let gc = @bap_main.Configuration::parameter(
        doc="Enables the taint garbage collector",
        @bap_main.Type::enumeration([("none", false), ("conservative", true)]),
        "gc",
      )
      @bap_main.Extension::register(ctxt => {
        @primus_taint.register(default_policy=ctxt.get(policy)) |> ignore
        @primus_taint.enable(default_policy=ctxt.get(policy), gc=ctxt.get(gc))
        |> ignore
      })
    },
  )
}

///|
fn declare_primus_propagate_taint() -> Unit raise {
  @bap_main.register_plugin(
    "primus-propagate-taint",
    provides=["dataflow", "pass", "analysis", "taint", "primus"],
    doc="a compatibility layer between different taint analysis frameworks",
    () => {
      let from_attributes = @bap_main.Configuration::flag(
        doc="Enables the injection of taints from the term attributes",
        "from-attributes",
      )
      let to_attributes = @bap_main.Configuration::flag(
        doc="Enables the projection of taints to the term attributes",
        "to-attributes",
      )
      let run = @bap_main.Configuration::flag(
        doc="Enables the propagation of taints with Primus",
        "run",
      )
      let no_marks = @bap_main.Configuration::flag(
        doc="Disables the marking of terms",
        "no-marks",
      )
      @bap_main.Extension::register(ctxt => {
        @primus_propagate_taint.register() |> ignore
        @primus_propagate_taint.enable(
          from_attributes=ctxt.get(from_attributes),
          to_attributes=ctxt.get(to_attributes),
          run=ctxt.get(run),
          no_marks=ctxt.get(no_marks),
        )
      })
    },
  )
}
