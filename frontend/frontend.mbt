// The `bap` command-line frontend (upstream `src/bap_frontend.ml`).

///|
/// The manual of the `bap` executable.
pub let man : String =
  #|
  #|# DESCRIPTION
  #|
  #|The main command line utility of the Binary Analysis platform used to
  #|invoke BAP analysis from the command line. The utility loads all
  #|plugins, parses command line arguments, and runs the specified
  #|command. The default command is $(b,disassemble), which disassembles
  #|and analyzes the specified file.
  #|
  #|# PLUGINS
  #|
  #|The BAP frontend does nothing by itself and all the functionality
  #|comes from various BAP plugins. There are many extension points in
  #|BAP, but writing a disassembler pass is probably the easiest to start
  #|with. See $(b,bap dis --help) for more details.
  #|
  #|# BUGS
  #|
  #|Report bugs to
  #|  https://github.com/BinaryAnalysisPlatform/bap/issues
  #|
  #|# SEE ALSO
  #|
  #|$(b,bapbundle)(1), $(b,bapbuild)(1), $(b,bap)(3)
  #|

///|
fn pad_right(s : String, width : Int32) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

///|
/// `  <name>   <doc>` lines (upstream `pp_info`).
fn pp_info(infos : Array[@bap_main.Info]) -> String {
  let sb = StringBuilder()
  for info in infos {
    sb.write_string("  \{pad_right(info.name(), 24)} \{info.doc()}\n")
  }
  sb.to_string()
}

///|
/// The usage message printed when `bap` is called without arguments
/// (upstream `print_info`).
pub fn usage(ctxt : @bap_main.Ctxt) -> String {
  let text =
    $|
    $|Usage:
    $|  bap <COMMAND> [<OPTIONS>]
    $|
    $|Common options:
    $|  --version                prints the version number and exits;
    $|  --plugin-path <DIR>      adds <DIR> to the plugins search path;
    $|  --logdir <DIR>           creates a log file in <DIR>;
    $|  --recipe <VAL>           extracts command line arguments from the recipe.
    $|
    $|Commands:
    $|\{pp_info(ctxt.commands())}
    $|Plugins:
    $|\{pp_info(ctxt.plugins())}
    $|If no command line options or arguments are specified, then this
    $|message is printed. To hush this message specify the `.' command,
    $|e.g., `bap .'. The command could be omitted altogether, in that case the
    $|`disassemble' command is assumed, e.g., `bap /bin/ls' is the same
    $|as `bap disassemble /bin/ls'. Not that the default command is
    $|subject to change, so it is better not to rely on this behavior in
    $|your automation tools.
    $|
    $|Run 'bap <COMMAND> --help' for more information a command.
    $|Run 'bap --<PLUGIN>-help for more information about a plugin.
    $|Run 'bap --help' for the detailed manual.
    $|
  text
}

///|
/// Loads a recipe for the `--recipe` option.
fn load_recipe(spec : String) -> @bap_main.Recipe raise {
  let r = @recipe.load(paths=@recipe_command.recipe_paths(), spec) catch {
    err => fail(err.to_string())
  }
  { command: r.command(), args: r.args(), }
}

///|
/// Runs the `bap` executable with the command line `argv` (including the
/// program name) and returns the exit code: `0` on success, the requested
/// code on `ExitRequested`, and `1` on errors (which are reported to
/// `err`).
///
/// `fs` is the file system seen by the commands (the host file system by
/// default); `read_line` reads the standard input; `write_file` writes the
/// output files; `plugins` are the plugins linked into the executable
/// (`plugin_table()` by default).
pub fn run(
  argv : Array[String],
  env~ : (String) -> String? = _ => None,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
  out~ : (String) -> Unit = _ => (),
  err~ : (String) -> Unit = _ => (),
  read_line~ : () -> String? = () => None,
  write_file~ : (String, String) -> Result[Unit, String] = @disassemble.default_write_file,
  plugins~ : Array[StaticPlugin] = plugin_table(),
) -> Int32 {
  let io = { out, err, read_line, write_file, argv, }
  @bap_main.reset()
  @bap_main.set_file_system(fs)
  let result = try {
    register_services()
    declare_commands(io)
    for p in plugins {
      (p.load)(io)
    }
    @bap_main.initialize(
      argv~,
      env~,
      out~,
      err~,
      man~,
      name="bap",
      default=ctxt => out(usage(ctxt)),
      default_command="disassemble",
      recipe=load_recipe,
    )
  } catch {
    @bap_main.ExitRequested(code) => code
    @bap_main.Configuration => 1
    e => {
      err(@bap_main.error_to_string(e) + "\n")
      1
    }
  } noraise {
    _ => 0
  }
  @bap_main.reset()
  result
}
