// The `analyze` command (upstream `Analyze_main`): executes the analysis
// commands and directives on the knowledge base.

///|
/// The name of the plugin.
pub let name : String = "analyze"

///|
/// The manual of the `analyze` command.
pub let doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Analyses the knowledge base. Loads the knowledge base and executes the
  #|specified commands or run the REPL if no commands or script files were
  #|specified.
  #|
  #|The knowledge base is not saved until the $(b,save) directive is
  #|issued. The knowledge base itself is optional and can be specified
  #|using the $(b,--project) parameter, which defaults to $(b,a.proj). The
  #|knowledge base is created with $(b,bap disassemble --project=<FILE>
  #|--update).
  #|
  #|The commands can be entered via the REPL (lines of the standard
  #|input). Alternatively, commands could be specified via a script file
  #|(see $(b,--script)), with one command per line, or using the
  #|command-line itself, with each command delimited with quotes, e.g.,
  #|
  #|```
  #|    bap analyze commands # prints all commands
  #|    bap analyze --project=test.proj 'subroutines :unit echo'
  #|```
  #|
  #|# GRAMMAR
  #|
  #|The expected input is a list of commands or directives separated with
  #|the newline characters. The directive $(b,directives) will output the
  #|list of available directives and corresponding descriptions. The
  #|$(b,commands) directive will list all available commands, and $(b,help
  #|<command>) will provide detailed information about $(b,<command>) its
  #|syntax and semantics.
  #|
  #|The syntax rules for commands are described in the
  #|$(b,Project.Analysis) API documentation but in general it follows the
  #|common command line syntax, i.e., each command is a sequence of words
  #|separated by whitespaces, with keyworded arguments prefixed with
  #|$(b,:) instead of $(b,-) or $(b,--), e.g.,
  #|
  #|```
  #|     subroutines :unit echo :matches malloc
  #|```
  #|

///|
/// The failures of the command (upstream `problem`).
pub(all) suberror AnalyzeError {
  UnknownCommand(pkg~ : String, name~ : String)
  Conflict(String, String, Array[String])
  BadDirective(dir~ : String, msg~ : String)
  SysErrorOnLoad(String)
}

///|
pub fn AnalyzeError::to_string(self : AnalyzeError) -> String {
  match self {
    UnknownCommand(pkg~, name~) =>
      "Can't find a command \"\{name}\" in the package \"\{pkg}\""
    Conflict(err, cmd, _) => "Command \{cmd} failed with \{err}"
    BadDirective(msg~, ..) => "Error: \{msg}"
    SysErrorOnLoad(msg) => "Failed to load a script: \{msg}"
  }
}

///|
/// The state of the session (upstream `ctxt`).
priv struct Session {
  path : String
  mut pkg : String
  mut quit : Bool
  write_file : (String, String) -> Result[Unit, String]
}

///|
fn break_line(s : String) -> Array[String] {
  s.split(" ").map(w => w.to_owned()).filter(w => w != "").collect()
}

///|
fn short(s : String) -> String {
  let len = match s.find(".") {
    Some(p) if p < s.length() => p
    _ => if s.length() < 40 { s.length() } else { 40 }
  }
  String::from_array(s.to_array()[:len]).to_lower()
}

///|
let help_msg : String =
  #|Type `commands' for the list of available commands or `directives' for the list of directives. Commands, unlike directives, are properly namespaced (packaged), the name of the currently opened namesapce (package) is displayed in the prompt. Most of the commands accept required or optional arguments. Some arguments are keyworded, i.e., them must be prefixed with the specified keyword, e.g.,
  #|
  #|instruction /bin/ls:0x8080 :semantics bil
  #|
  #|Type `help <command> ...` for the detailed description of the <command>. If more than one command is specified, then the detailed description will be printed for each.
  #|

///|
/// The directives: name, implementation, and description.
fn directives() -> Array[
  (String, (Array[String], Session) -> Unit raise AnalyzeError, String),
] {
  [
    ("in-package", set_package, "sets the default package"),
    ("save", save_base, "saves the knowledge base on disk"),
    (
      "quit",
      no_args("quit", s => s.quit = true),
      "quits the interactive session",
    ),
    (
      "clear",
      no_args("clear", _ => out("\u{1b}[H\u{1b}[2J")),
      "clears the screen",
    ),
    (
      "commands",
      no_args("commands", _ => list_commands()),
      "lists known commands",
    ),
    ("help", help, "prints the help message"),
    (
      "directives",
      no_args("directives", _ => list_directives()),
      "lists directives",
    ),
  ]
}

///|
fn no_args(
  dir : String,
  f : (Session) -> Unit,
) -> (Array[String], Session) -> Unit raise AnalyzeError {
  (args, session) => {
    if !args.is_empty() {
      raise BadDirective(dir~, msg="doesn't accept arguments")
    }
    f(session)
  }
}

///|
fn set_package(
  args : Array[String],
  session : Session,
) -> Unit raise AnalyzeError {
  match args {
    [pkg] => session.pkg = pkg
    _ =>
      raise BadDirective(dir="in-package", msg="expects exactly one argument")
  }
}

///|
fn save_base(
  args : Array[String],
  session : Session,
) -> Unit raise AnalyzeError {
  let path = match args {
    [] => session.path
    [path] => path
    _ => raise BadDirective(dir="save", msg="takes at most one argument")
  }
  match current.val {
    None => ()
    Some(proj) =>
      match
        (session.write_file)(path, @project.Project::persistent().encode(proj)) {
        Ok(_) => ()
        Err(msg) => raise BadDirective(dir="save", msg~)
      }
  }
}

///|
fn list_commands() -> Unit {
  for info in @project.registered_analyses() {
    out(
      "\{pad_right(info.qualified_name().show(), 40)} \{short(info.desc())}\n",
    )
  }
}

///|
fn list_directives() -> Unit {
  let dirs = directives().map(d => (d.0, d.2))
  dirs.sort_by((a, b) => lex_compare(a.0, b.0))
  for d in dirs {
    out("\{pad_right(d.0, 40)} \{d.1}\n")
  }
}

///|
fn help(args : Array[String], session : Session) -> Unit raise AnalyzeError {
  match args {
    [] => out(help_msg)
    [cmd] =>
      match directives().search_by(d => d.0 == cmd) {
        Some(i) => out(directives()[i].2 + "\n")
        None =>
          match @project.find_analysis(cmd, pkg=session.pkg) {
            None =>
              raise BadDirective(
                dir="help",
                msg="no such command \{cmd} in package \{session.pkg}",
              )
            Some(analysis) =>
              out(
                "SYNOPSIS\n\n\{cmd} \{analysis.grammar_string()}\n\nDESCRIPTION\n\{analysis.desc()}\n",
              )
          }
      }
    _ => raise BadDirective(dir="help", msg="expects zero or one argument")
  }
}

///|
fn exec_command(
  pkg : String,
  cmd : String,
  args : Array[String],
) -> Unit raise AnalyzeError {
  let pkg_name = @knowledge.Name::read(cmd, pkg~)
  match @project.find_analysis(pkg_name.unqualified(), pkg=pkg_name.pkg()) {
    None => raise UnknownCommand(pkg~, name=cmd)
    Some(analysis) =>
      match analysis.apply(args) {
        Ok(_) => ()
        Err(err) => raise Conflict(err, cmd, args)
      }
  }
}

///|
/// Executes a command or a directive (upstream `dispatch`).
fn dispatch(line : String, session : Session) -> Unit raise AnalyzeError {
  match break_line(line) {
    [] => ()
    [cmd, .. args] =>
      match directives().search_by(d => d.0 == cmd) {
        Some(i) => (directives()[i].1)(args.to_owned(), session)
        None => exec_command(session.pkg, cmd, args.to_owned())
      }
  }
}

///|
/// Runs the analysis session (the body of the `analyze` command).
///
/// Loads the knowledge base from `project` (if it exists), then executes
/// the `commands` and the lines of the `script`; if there are neither,
/// reads the commands with `read_line` until the end of the input or the
/// `quit` directive, reporting the errors to `err` and continuing.
pub fn run(
  project? : String = "a.proj",
  commands? : Array[String] = [],
  script? : String,
  read_line? : () -> String? = () => None,
  out? : (String) -> Unit,
  err? : (String) -> Unit = _ => (),
  write_file? : (String, String) -> Result[Unit, String] = (path, _) => {
    Err("can't write \{path}")
  },
) -> Unit raise AnalyzeError {
  register_core_commands()
  match out {
    Some(f) => output.val = f
    None => ()
  }
  current.val = match (@bap_main.file_system().read_file)(project) {
    None => None
    Some(bytes) =>
      match @project.Project::persistent().decode(@utf8.decode_lossy(bytes)) {
        Ok(proj) => Some(proj)
        Err(_) => None
      }
  }
  let session = { path: project, pkg: "bap", quit: false, write_file, }
  match (commands, script) {
    ([], None) =>
      while !session.quit {
        (output.val)("\{session.pkg}> ")
        match read_line() {
          None => break
          Some(line) =>
            dispatch(line, session) catch {
              e => err(e.to_string() + "\n")
            }
        }
      }
    _ => {
      for cmd in commands {
        dispatch(cmd, session)
      }
      match script {
        None => ()
        Some(path) => {
          let text = match (@bap_main.file_system().read_file)(path) {
            Some(bytes) => @utf8.decode_lossy(bytes)
            None => raise SysErrorOnLoad("can't read the file \{path}")
          }
          for line in text.split("\n") {
            dispatch(line.to_owned(), session)
          }
        }
      }
    }
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
/// Declares the `analyze` plugin and command in the `bap_main`
/// framework. Does nothing if it is already registered.
pub fn declare_plugin(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  err? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  read_line? : () -> String? = () => None,
  write_file? : (String, String) -> Result[Unit, String] = (path, _) => {
    Err("can't write \{path}")
  },
) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  if !printer_registered.val {
    printer_registered.val = true
    @bap_main.register_error_printer(e => {
      match e {
        UnknownCommand(pkg~, name~) =>
          Some(UnknownCommand(pkg~, name~).to_string())
        Conflict(err, cmd, args) => Some(Conflict(err, cmd, args).to_string())
        BadDirective(dir~, msg~) => Some(BadDirective(dir~, msg~).to_string())
        SysErrorOnLoad(msg) => Some(SysErrorOnLoad(msg).to_string())
        _ => None
      }
    })
  }
  @bap_main.register_plugin(name, doc="analyses the knowledge base", () => {
    let knowledge = @bap_main.Command::parameter(
      doc="The path to a knowledge base.",
      aliases=["k"],
      @bap_main.Type::string().with_default("a.proj").rename("knowledge-base"),
      "project",
    )
    let commands = @bap_main.Command::arguments(
      doc="The command to execute.",
      @bap_main.Type::string().rename("command"),
    )
    let script = @bap_main.Command::parameter(
      doc="The path to a script file with commands.",
      aliases=["s"],
      @bap_main.Type::some(@bap_main.Type::file()).rename("path"),
      "script",
    )
    let history = @bap_main.Command::parameter(
      doc="The path to the history file (the history is not recorded).",
      aliases=["H"],
      @bap_main.Type::string().with_default(".bap_history").rename("path"),
      "history",
    )
    @bap_main.Command::register(
      doc~,
      name,
      @bap_main.Command::args()
      .add(knowledge)
      .add(commands)
      .add(script)
      .add(history),
      project => {
        commands => {
          script => {
            _history => {
              _ctxt => {
                run(
                  project~,
                  commands~,
                  script?,
                  read_line~,
                  out~,
                  err~,
                  write_file~,
                )
              }
            }
          }
        }
      },
    )
    @bap_main.Extension::register(doc~, _ => ())
  })
}

///|
/// OCaml's `String.compare`: the lexicographic order (MoonBit's `String`
/// comparison orders by length first).
fn lex_compare(a : String, b : String) -> Int {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let c = a[i].compare(b[i])
    if c != 0 {
      return c
    }
  }
  a.length().compare(b.length())
}
