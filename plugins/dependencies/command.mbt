///|
/// Runs the `dependencies` command and returns the rendered output.
///
/// `ldconfig` is a command whose output is an ldconfig-like cache; since the
/// port cannot spawn processes, it is executed by `run_command` (by default
/// no command can be run and a warning is reported).
pub fn run(
  input : String,
  root? : String,
  ldconfig? : String,
  run_command? : (String) -> String? = _ => None,
  format? : DependencyFormat = Yaml,
  recursive? : Bool = false,
  paths? : Array[String] = [],
  context? : String = "",
  cache? : DependencyCache,
  fs? : @bap_main.FileSystem = @bap_main.file_system(),
) -> String {
  let ldconfig = match ldconfig {
    None => None
    Some(command) =>
      match run_command(command) {
        Some(text) => Some(LdconfigCache::parse(text))
        None => {
          warning("unable to run the ldconfig command: \{command}")
          None
        }
      }
  }
  DependencyState::load(
    input,
    recursive~,
    root?,
    ldconfig?,
    paths~,
    context~,
    cache?,
    fs~,
  ).render(format)
}

///|
let command_cache : DependencyCache = DependencyCache::new()

///|
/// Declares the `dependencies` plugin and command to `bap_main`. Does nothing
/// if already declared.
pub fn declare_plugin(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["depedencies", "command"], doc~, () => {
    let input = @bap_main.Command::argument(
      doc="The input file",
      @bap_main.Type::string().with_default("a.out").rename("FILE"),
    )
    let paths = @bap_main.Command::parameters(
      doc="Specify a list of directories where to search for libraries.",
      @bap_main.Type::list(@bap_main.Type::string()),
      "library-paths",
    )
    let recursive = @bap_main.Command::flag(
      doc="Calls the commmand recursively on the obtained dependencies.",
      aliases=["r"],
      "recursive",
    )
    let ldconfig = @bap_main.Command::parameter(
      doc="A command that returns an ldconfig-like cache.",
      as_flag=Some("ldconfig -p"),
      @bap_main.Type::some(@bap_main.Type::string()),
      "ldconfig",
    )
    let root = @bap_main.Command::parameter(
      doc="Specify the default root directory.",
      aliases=["R"],
      @bap_main.Type::some(@bap_main.Type::string()),
      "root",
    )
    let format = @bap_main.Command::parameter(
      aliases=["o"],
      @bap_main.Type::enumeration([
        ("yaml", Yaml),
        ("sexp", Sexp),
        ("json", Json),
        ("graph", Graph),
      ]),
      "format",
    )
    let grammar = @bap_main.Command::args()
      .add(root)
      .add(ldconfig)
      .add(format)
      .add(recursive)
      .add(paths)
      .add(input)
    @bap_main.Command::register(
      name,
      grammar,
      doc~,
      requires=["loader", "cache"],
      root => {
        ldconfig => {
          format => {
            recursive => {
              paths => {
                input => {
                  ctxt => {
                    let paths = paths.fold(init=[], (acc, xs) => acc + xs)
                    out(
                      run(
                        input,
                        root?,
                        ldconfig?,
                        format~,
                        recursive~,
                        paths~,
                        context=ctxt.digest(),
                        cache=command_cache,
                      ),
                    )
                  }
                }
              }
            }
          }
        }
      },
    )
  })
}
