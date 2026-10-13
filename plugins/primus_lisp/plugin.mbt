// The `primus-lisp` plugin (upstream `plugins/primus_lisp/primus_lisp_main.ml`):
// installs the Primus Lisp library, the Lisp runtime components, the
// type checker, the documentation generator, and the Lisp semantics
// lifter.

///|
/// The name of the plugin.
pub let name : String = "primus-lisp"

///|
/// The configuration of the plugin (the plugin options).
pub(all) struct Config {
  /// `--primus-lisp-documentation`: outputs the documentation
  documentation : Bool
  /// `--primus-lisp-dump`: dumps the program
  dump : Bool
  /// `--primus-lisp-typecheck`: type checks the program
  typecheck : Bool
  /// `--primus-lisp-add`: folders with Lisp libraries (native only)
  paths : Array[String]
  /// `--primus-lisp-load`: features to load (`core` is always loaded)
  features : Array[String]
  /// `--primus-lisp-semantics`: folders with semantic definitions, or
  /// `["disable"]` to disable the Lisp lifter
  semantics : Array[String]
  /// `--primus-lisp-channel-redirect`: `(<emulated>, <host>)` pairs
  redirects : Array[(String, String)]
}

///|
/// The default configuration: loads the `posix` library, the Lisp lifter
/// is enabled.
pub fn Config::default() -> Config {
  {
    documentation: false,
    dump: false,
    typecheck: false,
    paths: [],
    features: ["posix"],
    semantics: [],
    redirects: [],
  }
}

///|
/// The standard channels that can be redirected (upstream
/// `Primus_lisp_io.standard_channels`).
pub let standard_channels : Array[String] = @lisp.standard_channels

///|
/// Parses a channel redirection `<old>:<new>` (upstream
/// `Redirection.parse`).
pub fn parse_redirection(s : String) -> Result[(String, String), String] {
  let parts : Array[String] = s.split(":").map(p => p.to_owned()).collect()
  match parts {
    [old, new] =>
      if old == "" || new == "" {
        Err("bad redirection: expected two non-empty names")
      } else if old.has_prefix("<") && !standard_channels.contains(old) {
        Err(
          "unknown channel \{old}, expected one of \{standard_channels.join(", ")}",
        )
      } else {
        Ok((old, new))
      }
    _ => Err("bad redirection, expected <old>:<new> got \{s}")
  }
}

///|
/// The library loader of the configuration: the current folder and the
/// user folders (native backend only), then the embedded library.
pub fn Config::loader(self : Config) -> @lisp.Loader {
  @lisp.Loader::chain([
    @lisp.Loader::paths(["."] + self.paths),
    @lisp.Loader::embedded(@lisp.library_dirs),
  ])
}

///|
/// The features loaded by the configuration.
pub fn Config::all_features(self : Config) -> Array[String] {
  ["core"] + self.features.filter(f => f != "core")
}

///|
/// Applies the channel redirections (see `@primus_lisp.set_redirections`):
/// the standard channels are associated with host files, other emulated
/// paths can be opened with `channel-open` (native backend only).
pub fn redirect_channels(
  m : @primus.Machine,
  redirects : Array[(String, String)],
) -> Unit {
  @lisp.set_redirections(m, redirects)
}

///|
/// The message printed by the `lisp-type-checker` component (upstream
/// `TypeErrorSummary`).
pub fn type_error_summary(errors : Int32) -> String {
  if errors == 0 {
    "Primus Lisp code is well-typed"
  } else {
    "Primus Lisp code is ill-typed. Found \{errors} error\{if errors > 1 { "s" } else { "" }}."
  }
}

///|
let output : Ref[(String) -> Unit] = Ref(s => println(s))

///|
/// Sets the function that receives the output of the plugin (the
/// documentation, the type error summary, the type errors, and the dumped
/// program); `println` by default.
pub fn set_output(out : (String) -> Unit) -> Unit {
  output.val = out
}

///|
/// Runs a machine with the Lisp runtime and the configured library, and
/// passes it to `f` after initialization.
fn with_lisp_machine(
  proj : @project.Project,
  f : (@primus.Machine) -> Unit raise,
) -> Unit raise {
  let (status, _) = @primus.Machine::run(proj, init=m => {
    @lisp.init_runtime(m)
    @lisp.load_library(m)
    f(m)
  })
  match status {
    Normal => ()
    Exn(e) => raise e
  }
}

///|
/// The documentation of the Lisp program for the project in the Org-mode
/// format (upstream `--primus-lisp-documentation`).
pub fn documentation(proj : @project.Project) -> String raise {
  let out = Ref("")
  with_lisp_machine(proj, m => {
    out.val = @lisp.documentation_to_org(@lisp.documentation(@lisp.program(m)))
  })
  out.val
}

///|
/// Type checks the Lisp program for the project: returns the summary and
/// the type errors (upstream `--primus-lisp-typecheck`).
pub fn typecheck(proj : @project.Project) -> (String, Array[String]) raise {
  let errors : Array[String] = []
  let n = Ref(0)
  with_lisp_machine(proj, m => {
    m.observe(@lisp.type_error, e => errors.push(e.to_string()))
    n.val = @lisp.typecheck(m)
  })
  (type_error_summary(n.val), errors)
}

///|
/// The functions of the Lisp program for the project, pretty-printed
/// (upstream `--primus-lisp-dump`).
pub fn dump(proj : @project.Project) -> String raise {
  let out = StringBuilder()
  with_lisp_machine(proj, m => {
    let prog = @lisp.program(m)
    for pkg in prog.packages() {
      let defs = prog.with_package(pkg.0).get(@lisp.func)
      if !defs.is_empty() {
        out.write_string("(in-package \{pkg.0})\n")
        for d in defs {
          let args = d.code.args.map(a => a.name.unqualified()).join(" ")
          out.write_string(
            "(defun \{d.name} (\{args}) \{d.code.body.to_string_in(pkg=pkg.0)})\n",
          )
        }
      }
    }
  })
  out.to_string()
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Enables the plugin with the configuration (upstream extension body):
/// configures the library, registers the components `bap:lisp-core`,
/// `bap:load-lisp-library`, `bap:lisp-type-checker`, and
/// `bap:lisp-type-error-printer`, adds the core components to the legacy
/// main system, and, unless disabled, registers the Lisp semantics
/// lifters. Idempotent with respect to the registrations.
pub fn enable(config~ : Config = Config::default()) -> Unit raise {
  @lisp.configure_library(
    features=config.all_features(),
    loader=config.loader(),
  )
  @lisp.register_components()
  @primus.Components::register_generic(
    "lisp-type-error-printer",
    pkg="bap",
    desc="Prints Primus Lisp type errors into the standard output.",
    m => m.observe(@lisp.type_error, e => (output.val)(e.to_string())),
  ) catch {
    _ => ()
  }
  if !enabled.val {
    enabled.val = true
    let redirects = config.redirects
    @primus.Machine::add_component(m => {
      @lisp.init_runtime(m)
      redirect_channels(m, redirects)
    })
    @primus.Machine::add_component(m => {
      m.observe(@lisp.type_error, e => (output.val)(e.to_string()))
    })
    @primus.Machine::add_component(m => @lisp.load_library(m))
    if config.typecheck {
      @primus.Machine::add_component(m => {
        (output.val)(type_error_summary(@lisp.typecheck(m)))
      })
    }
  }
  if config.semantics != ["disable"] {
    @lisp.check_folders(config.semantics)
    @lisp.register_semantics_providers(paths=config.semantics)
  }
}

///|
fn parse_list(s : String) -> Array[String] {
  s.split(",").map(x => x.trim().to_owned()).filter(x => x != "").collect()
}

///|
/// Declares the plugin and its options in the `bap_main` registry
/// (`--primus-lisp-documentation`, `--primus-lisp-dump`,
/// `--primus-lisp-typecheck`, `--primus-lisp-add`, `--primus-lisp-load`,
/// `--primus-lisp-semantics`, `--primus-lisp-channel-redirect`).
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "lisp", "semantics", "lifter"],
    doc="loads and manages Primus Lisp sources",
    () => {
      let documentation = @bap_main.Configuration::flag(
        doc="outputs Primus Lisp documentation",
        "documentation",
      )
      let dump = @bap_main.Configuration::flag(
        doc="dumps generated AST",
        "dump",
      )
      let typecheck = @bap_main.Configuration::flag(
        doc="typechecks the program and prints erros if they exist",
        aliases=["type-check"],
        "typecheck",
      )
      let add = @bap_main.Configuration::parameter(
        doc="paths to lisp libraries",
        @bap_main.Type::string(),
        "add",
      )
      let load = @bap_main.Configuration::parameters(
        doc="load specified module",
        @bap_main.Type::string(),
        "load",
      )
      let semantics = @bap_main.Configuration::parameter(
        doc="prepend the specified folders to the list of folders where semantics files are searched, or disable the Lisp lifter with disable",
        @bap_main.Type::string(),
        "semantics",
      )
      let redirects = @bap_main.Configuration::parameter(
        doc="establishes a redirection between an emulated file path and a file path on a host system",
        @bap_main.Type::string(),
        "channel-redirect",
      )
      @bap_main.Extension::register(ctxt => {
        let features = ctxt
          .get(load)
          .map(parse_list)
          .fold(init=[], (acc, x) => acc + x)
        let redirs = []
        for r in parse_list(ctxt.get(redirects)) {
          match parse_redirection(r) {
            Ok(x) => redirs.push(x)
            Err(msg) => fail(msg)
          }
        }
        enable(config={
          documentation: ctxt.get(documentation),
          dump: ctxt.get(dump),
          typecheck: ctxt.get(typecheck),
          paths: parse_list(ctxt.get(add)),
          features: if features.is_empty() {
            ["posix"]
          } else {
            features
          },
          semantics: parse_list(ctxt.get(semantics)),
          redirects: redirs,
        })
      })
    },
  )
}
