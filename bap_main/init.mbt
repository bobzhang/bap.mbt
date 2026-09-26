// Port of `ConfigFile` and `Bap_main.init`.

///|
/// Parses the contents of a configuration file: `<key> = <value>` lines,
/// `#` starts a comment, empty lines are ignored.
fn parse_config(
  filename : String,
  text : String,
) -> Array[(String, String)] raise {
  let out = []
  let lines = text.split("\n").map(l => l.to_owned()).collect()
  // `In_channel.input_lines` does not report a trailing empty line
  if lines.last() is Some("") {
    lines.pop() |> ignore
  }
  for i, line in lines {
    let line = if line.has_suffix("\r") {
      line[:line.length() - 1].to_owned()
    } else {
      line
    }
    let str = match lsplit2(line, '#') {
      None => line
      Some((s, _)) => s
    }
    if str.iter().all(is_ws) {
      continue
    }
    match lsplit2(str, '=') {
      None =>
        raise Invalid(
          "File \{ocaml_quote(filename)}, line \{i + 1}, characters 1-\{str.length() + 1}\nSyntax error: expects <parameter> = <value>",
        )
      Some((k, v)) => out.push((strip(k), strip(v)))
    }
  }
  out
}

///|
/// The configuration directories: `$HOME/.config/bap`,
/// `$XDG_CONFIG_HOME/bap`, and `Configuration::confdir()`.
fn config_dirs(getenv : (String) -> String?) -> Array[String] {
  let dirs = []
  if getenv("HOME") is Some(home) {
    dirs.push(filename_concat(filename_concat(home, ".config"), "bap"))
  }
  if getenv("XDG_CONFIG_HOME") is Some(dir) {
    dirs.push(filename_concat(dir, "bap"))
  }
  dirs.push(Configuration::confdir())
  dirs
}

///|
/// Reads all configuration files, the most specific first.
fn read_config_files(
  getenv : (String) -> String?,
) -> Array[(String, String)] raise {
  let fs = current_file_system.val
  let out = []
  for dir in config_dirs(getenv) {
    if fs_kind(dir) is Some(Directory) {
      match (fs.read_dir)(dir) {
        None => ()
        Some(entries) => {
          let files = entries.map(e => filename_concat(dir, e))
          sort_strings(files)
          for file in files {
            match fs_kind(file) {
              Some(Directory) | None => ()
              Some(_) =>
                match (fs.read_file)(file) {
                  None =>
                    raise Invalid(
                      "can't access config file \{ocaml_quote(file)}: read error\n",
                    )
                  Some(bytes) =>
                    out.append(parse_config(file, @utf8.decode_lossy(bytes)))
                }
            }
          }
        }
      }
    }
  }
  out
}

///|
/// A recipe, as seen by the command line: an optional command and the
/// arguments that the recipe contributes.
pub(all) struct Recipe {
  command : String?
  args : Array[String]
} derive(Eq, Debug)

///|
pub extend Recipe with Eq::{equal, not_equal}

///|
pub extend Recipe with Debug::{to_repr}

///|
/// `Bap_recipe.argv`: inserts the recipe's command and arguments into the
/// command line (before `--`, if present).
fn recipe_argv(argv : Array[String], recipe : Recipe) -> Array[String] {
  let argv = match recipe.command {
    None => argv
    Some(cmd) =>
      match argv {
        [] | [_] => [..argv, cmd]
        [self_, arg, .. rest] =>
          if cmd.has_prefix(arg) {
            [self_, cmd, ..rest]
          } else {
            [self_, cmd, arg, ..rest]
          }
      }
  }
  let mut dash = -1
  for i, a in argv {
    if a == "--" {
      dash = i
      break
    }
  }
  if dash < 0 {
    [..argv, ..recipe.args]
  } else {
    [..argv[:dash], ..recipe.args, ..argv[dash:]]
  }
}

///|
/// Pre-parses the value of `--recipe` (ignoring all other options).
fn extract_recipe(argv : Array[String]) -> String? {
  let info = recipe_info()
  let args = if argv.is_empty() { [] } else { argv[1:].to_owned() }
  match Cline::create([info], args, peek_opts=true) {
    Err(_) => None
    Ok(cl) =>
      match cl.opt_arg(info) {
        [(_, _, Some(v)), ..] => Some(v)
        _ => None
      }
  }
}

///|
fn default_out(s : String) -> Unit {
  println(if s.has_suffix("\n") { s[:s.length() - 1].to_owned() } else { s })
}

///|
fn default_progname() -> String {
  match @env.args() {
    [prog, ..] => {
      let parts = prog.split("/").map(p => p.to_owned()).collect()
      match parts.last() {
        Some(name) if name != "" => name
        _ => "bap"
      }
    }
    _ => "bap"
  }
}

///|
/// `initialize()` initializes the BAP framework (`Bap_main.init`).
///
/// It loads the registered plugins that are selected by `features` and
/// `requires` (see `register_plugin`), reads the configuration (command
/// line `argv`, the environment through `env`, the configuration files,
/// and the explicit `config` entries, which take precedence over the
/// files), evaluates the extensions, and runs the command selected on the
/// command line (or `default` when no command is given; `default_command`
/// is inserted when the first argument is not a command).
///
/// `argv` includes the program name and defaults to `[name]`, i.e., no
/// arguments. Help and version requests are written to `out`; diagnostics
/// of configuration problems to `err`. `man` is the markdown manual of the
/// host program. Log messages of `main_event` are written to `log` when it
/// is given.
///
/// `recipe` resolves the argument of `--recipe`; without it, `--recipe`
/// fails with `BadRecipe`. `library` (plugin search paths) is accepted for
/// compatibility and ignored, since plugins are statically registered.
///
/// Raises `AlreadyInitialized`/`AlreadyFailed` on repeated calls (use
/// `reset` to start over), `BrokenPlugins` when a plugin fails to load,
/// `Configuration` on command-line errors, and any error raised by an
/// extension or by the command. `ExitRequested(0)` is raised after
/// printing a plugin manual (`--<plugin>-help`).
pub fn initialize(
  features? : Array[String] = [],
  requires? : Array[String],
  library? : Array[String] = [],
  argv? : Array[String],
  env? : (String) -> String? = @env.get_env_var,
  config? : Array[(String, String)] = [],
  log? : (String) -> Unit,
  out? : (String) -> Unit = default_out,
  err? : (String) -> Unit = default_out,
  man? : String = "",
  name? : String,
  version? : String = Configuration::version(),
  default? : (Ctxt) -> Unit raise,
  default_command? : String,
  recipe? : (String) -> Recipe raise,
) -> Unit raise {
  ignore(library)
  let st = main_state.val
  match st.status {
    Loaded(_) => raise AlreadyInitialized
    Failed(e) => raise AlreadyFailed(e)
    Initializing => raise RecursiveInit
    Uninitialized => ()
  }
  let name = match name {
    Some(n) => n
    None => default_progname()
  }
  let argv = match argv {
    Some(a) => a
    None => [name]
  }
  // as in BAP, a bad recipe is reported before the system state changes
  let argv = match extract_recipe(argv) {
    None => argv
    Some(spec) =>
      match recipe {
        None =>
          raise BadRecipe("no recipe loader is available for \{quote(spec)}")
        Some(load) =>
          recipe_argv(argv, load(spec)) catch {
            e => raise BadRecipe(error_to_string(e))
          }
      }
  }
  st.status = Initializing
  let fail = (e : Error) => {
    st.status = Failed(e)
    raise e
  }
  if log is Some(write) {
    st.log_subscription = Some(@main_event.process_log_events(write~))
  }
  let version = if Configuration::build_id() == "" {
    version
  } else {
    "\{version}+\{Configuration::build_id()}"
  }
  let result = try {
    let files = read_config_files(env)
    let config = [..config, ..files]
    let (loaded, failures) = load_plugins(features, requires, config, env)
    if !failures.is_empty() {
      raise BrokenPlugins(failures)
    }
    eval(argv, {
      name,
      version,
      man,
      getenv: env,
      out,
      err,
      default,
      command: default_command,
    })
    loaded
  } catch {
    e => fail(e)
  }
  st.status = Loaded(result)
}

///|
/// The names of the plugins loaded by a successful `init`.
pub fn loaded_plugins() -> Array[String] {
  match main_state.val.status {
    Loaded(names) => names
    _ => []
  }
}
