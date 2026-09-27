// Port of `Grammar.eval` of `bap_main.ml`: builds the command-line grammar
// from the common options, the plugin options, and the declared commands,
// then parses and evaluates the command line (the job Cmdliner's
// `Term.eval_choice` does in BAP).

///|
priv struct EvalConfig {
  name : String
  version : String
  man : String
  getenv : (String) -> String?
  out : (String) -> Unit
  err : (String) -> Unit
  default : ((Ctxt) -> Unit raise)?
  command : String?
}

///|
/// The outcome of the evaluation of a term, mirroring Cmdliner's
/// `Error (`Parse | `Term)` versus BAP's stored `term_evaluation_result`.
priv suberror EvalFailure {
  UsageError(String, Bool) // message, print the usage
}

///|
let help_formats : Array[(String, String)] = [
  ("auto", "auto"),
  ("pager", "pager"),
  ("groff", "groff"),
  ("plain", "plain"),
]

///|
fn parse_help_format(s : String) -> Result[String?, String] {
  match trie_find(help_formats, s) {
    Found(v) => Ok(Some(v))
    Ambiguous =>
      Err(err_ambiguous("enum value", s, trie_ambiguities(help_formats, s)))
    NotFound =>
      Err(
        err_invalid_val(s, "expected " + alts_str(help_formats.map(p => p.0))),
      )
  }
}

///|
/// Cmdliner's standard `--help[=FMT]` option.
fn help_term() -> Term[String?] {
  let info = ArgInfo::new(
    names=["help"],
    docv="FMT",
    docs=s_common_options,
    doc="Show this help in format $(docv). The value $(docv) must be one of 'auto', 'pager', 'groff' or 'plain'. With 'auto', the format is 'pager' or 'plain' whenever the TERM env var is 'dumb' or undefined.",
    kind=OptVopt("auto"),
  )
  arg_opt(vopt=Some("auto"), parse_help_format, None, info)
}

///|
fn version_term() -> Term[Bool] {
  arg_flag(
    ArgInfo::new(
      names=["version"],
      docs=s_common_options,
      doc="Show version information.",
      kind=Flag,
    ),
  )
}

///|
fn some_string(s : String) -> Result[String?, String] {
  Ok(Some(s))
}

///|
fn recipe_info() -> ArgInfo {
  ArgInfo::new(names=["recipe"], doc="Load the specified recipe", kind=Opt)
}

///|
/// `Pre.term`: the log directory, plugin search paths, and recipe options.
/// Their values are validated but not used: logging to a directory and
/// plugin search paths have no counterpart in this port, and recipes are
/// expanded by `initialize` before parsing.
fn pre_term() -> Term[Unit] {
  let logdir = arg_opt(
    some_string,
    None,
    ArgInfo::new(
      names=["logdir", "log-dir"],
      doc="A folder for log files.",
      env=("BAP_LOG_DIR", "A folder for log files."),
      kind=Opt,
    ),
  )
  let locations = arg_opt_all(
    s => Ok(s),
    [],
    ArgInfo::new(
      names=["L", "plugin-path", "load-path"],
      doc="Adds folder to the list of plugins search paths",
      kind=Opt,
    ),
  )
  let recipe = arg_opt(some_string, None, recipe_info())
  Term::pure((_ : String?) => (_ : Array[String]) => (_ : String?) => ())
  .app(logdir)
  .app(locations)
  .app(recipe)
}

///|
priv struct Grammars {
  pre : Term[Unit]
  helps : Array[(String, Term[String?])]
  disabled : Array[(String, Term[Bool])]
  help : Term[String?]
  version : Term[Bool]
}

///|
fn Grammars::common_args(self : Grammars) -> Array[ArgInfo] {
  let args = [..self.pre.args]
  for h in self.helps {
    args.append(h.1.args)
  }
  for d in self.disabled {
    args.append(d.1.args)
  }
  for p in main_state.val.loaded {
    for t in p.spec {
      args.append(t.args)
    }
  }
  args.append(self.help.args)
  args.append(self.version.args)
  args
}

///|
fn make_grammars(plugin_names : Array[String]) -> Grammars {
  let helps = plugin_names.map(name => {
    let info = ArgInfo::new(
      names=[name + "-help"],
      docs=s_common_options,
      doc="prints more information about the $(b,\{name}) plugin",
      kind=OptVopt("auto"),
    )
    (name, arg_opt(vopt=Some("auto"), parse_help_format, None, info))
  })
  let disabled = plugin_names.map(name => {
    let info = ArgInfo::new(
      names=["no-" + name],
      docs=s_common_options,
      doc="Disable the " + name + " plugin",
      kind=Flag,
    )
    (name, arg_flag(info))
  })
  {
    pre: pre_term(),
    helps,
    disabled,
    help: help_term(),
    version: version_term(),
  }
}

// Manual pages --------------------------------------------------------------

///|
fn arg_label(a : ArgInfo) -> String {
  if a.is_pos() {
    return "$(i,\{a.docv})"
  }
  let var_name = if a.docv == "" { "VAL" } else { a.docv }
  let fmt = (n : String) => {
    match a.kind {
      Flag => "$(b,\{n})"
      Opt =>
        if n.length() > 2 {
          "$(b,\{n})=$(i,\{var_name})"
        } else {
          "$(b,\{n}) $(i,\{var_name})"
        }
      OptVopt(_) =>
        if n.length() > 2 {
          "$(b,\{n})[=$(i,\{var_name})]"
        } else {
          "$(b,\{n}) [$(i,\{var_name})]"
        }
    }
  }
  let names = a.names.copy()
  sort_strings(names)
  names.rev_in_place()
  names.map(fmt).join(", ")
}

///|
fn arg_doc(a : ArgInfo) -> String {
  let or_env = (value : Bool) => {
    match a.env {
      None => ""
      Some((var_name, _)) =>
        if value {
          " or $(b,\{var_name}) env"
        } else {
          "absent $(b,\{var_name}) env"
        }
    }
  }
  let absent = match a.absent {
    "" => or_env(false)
    v => "absent=\{v}\{or_env(true)}"
  }
  let optvopt = match a.kind {
    OptVopt(v) => "default=\{v}"
    _ => ""
  }
  let argvdoc = match (optvopt, absent) {
    ("", "") => ""
    (s, "") | ("", s) => " (\{s})"
    (s, s2) => " (\{s}) (\{s2})"
  }
  let docv = a.docv
  let doc = subst_markup(a.doc, v => {
    match v {
      "docv" => Some(docv)
      _ => None
    }
  })
  doc + argvdoc
}

///|
fn arg_order_key(a : ArgInfo) -> String {
  if a.is_pos() {
    a.docv.to_lower()
  } else {
    let names = a.names.copy()
    sort_strings(names)
    let k = names[names.length() - 1].to_lower()
    if k.has_prefix("--") {
      k[1:].to_owned()
    } else {
      k
    }
  }
}

///|
fn dedup_args(args : Array[ArgInfo]) -> Array[ArgInfo] {
  let seen : Map[Int, Unit] = Map([])
  let out = []
  for a in args {
    if !seen.contains(a.id) {
      seen[a.id] = ()
      out.push(a)
    }
  }
  out
}

///|
let standard_sections : Array[String] = [
  "NAME", "SYNOPSIS", "DESCRIPTION", "COMMANDS", "ARGUMENTS", "OPTIONS", "COMMON OPTIONS",
  "EXIT STATUS", "ENVIRONMENT", "FILES", "EXAMPLES", "BUGS", "AUTHORS", "SEE ALSO",
]

///|
/// Merges the user manual with the generated sections, placing sections
/// in Cmdliner's standard order.
fn assemble_manpage(
  name_line : String,
  synopsis : String,
  user : Array[ManBlock],
  generated : Array[(String, Array[ManBlock])],
) -> Array[ManBlock] {
  let user = match user {
    [] | [Section(_), ..] => user
    _ => [Section("DESCRIPTION"), ..user]
  }
  // split the user manual into sections
  let sections : Array[(String, Array[ManBlock])] = []
  for b in user {
    match b {
      Section(s) => sections.push((s, []))
      b => sections[sections.length() - 1].1.push(b)
    }
  }
  let out : Array[ManBlock] = [
    Section("NAME"),
    Paragraph(name_line),
    Section("SYNOPSIS"),
    Paragraph(synopsis),
  ]
  let emitted : Map[String, Unit] = Map([])
  let emit_user_tail = (idx : Int) => {
    // non-standard sections that follow the user section at `idx`
    for j in (idx + 1)..<sections.length() {
      let (s, blocks) = sections[j]
      if standard_sections.contains(s) {
        break
      }
      if !emitted.contains(s) {
        emitted[s] = ()
        out.push(Section(s))
        out.append(blocks)
      }
    }
  }
  // leading non-standard user sections
  emit_user_tail(-1)
  for std in standard_sections {
    if std == "NAME" || std == "SYNOPSIS" {
      continue
    }
    let gen = generated
      .iter()
      .find_first(g => g.0 == std)
      .map(g => g.1)
      .unwrap_or([])
    let mut user_idx = -1
    for i, s in sections {
      if s.0 == std {
        user_idx = i
        break
      }
    }
    if user_idx >= 0 {
      out.push(Section(std))
      out.append(sections[user_idx].1)
      out.append(gen)
      emitted[std] = ()
      emit_user_tail(user_idx)
    } else if !gen.is_empty() {
      out.push(Section(std))
      out.append(gen)
    }
  }
  out
}

///|
fn arg_sections(args : Array[ArgInfo]) -> Array[(String, Array[ManBlock])] {
  let args = dedup_args(args).filter(a => a.doc != "")
  args.sort_by((a, b) => {
    match (a.is_pos(), b.is_pos()) {
      (false, true) => -1
      (true, false) => 1
      _ => lex_compare(arg_order_key(a), arg_order_key(b))
    }
  })
  let out : Array[(String, Array[ManBlock])] = []
  for a in args {
    let item = Item(arg_label(a), arg_doc(a))
    match out.iter().find_first(s => s.0 == a.docs) {
      Some(s) => s.1.push(item)
      None => out.push((a.docs, [item]))
    }
  }
  let envs = []
  for a in args {
    if a.env is Some((var_name, doc)) {
      envs.push(Item("$(b,\{var_name})", doc))
    }
  }
  if !envs.is_empty() {
    out.push(("ENVIRONMENT", envs))
  }
  out
}

///|
fn render_manpage(name : String, blocks : Array[ManBlock]) -> String {
  render_plain(blocks, v => {
    match v {
      "tname" | "mname" => Some(name)
      _ => None
    }
  })
}

///|
fn main_synopsis(cfg : EvalConfig, has_commands : Bool) -> String {
  if has_commands {
    "$(b,\{cfg.name}) $(i,COMMAND) ..."
  } else {
    "$(b,\{cfg.name}) [$(i,OPTION)]..."
  }
}

///|
fn command_synopsis(cfg : EvalConfig, cmd : CommandDecl) -> String {
  let pos = cmd.term.args.filter(a => a.is_pos())
  pos.sort_by((a, b) => a.pos.unwrap().start.compare(b.pos.unwrap().start))
  let parts = ["$(b,\{cfg.name}) $(b,\{cmd.name}) [$(i,OPTION)]..."]
  for a in pos {
    let docv = if a.docv == "" { "ARG" } else { a.docv }
    match a.pos {
      Some({ len: Some(1), .. }) => parts.push("[$(i,\{docv})]")
      _ => parts.push("[$(i,\{docv})]...")
    }
  }
  parts.join(" ")
}

///|
fn main_manpage(cfg : EvalConfig, args : Array[ArgInfo]) -> String {
  let cmds = main_state.val.commands.copy()
  cmds.sort_by((a, b) => lex_compare(a.name, b.name))
  let generated = arg_sections(args)
  if !cmds.is_empty() {
    generated.push(("COMMANDS", cmds.map(c => Item("$(b,\{c.name})", c.doc))))
  }
  let blocks = assemble_manpage(
    cfg.name,
    main_synopsis(cfg, !cmds.is_empty()),
    markdown_to_manpage(cfg.man),
    generated,
  )
  render_manpage(cfg.name, blocks)
}

///|
fn command_manpage(
  cfg : EvalConfig,
  cmd : CommandDecl,
  args : Array[ArgInfo],
) -> String {
  let tname = "\{cfg.name}-\{cmd.name}"
  let name_line = if cmd.doc == "" { tname } else { "\{tname} - \{cmd.doc}" }
  let blocks = assemble_manpage(
    name_line,
    command_synopsis(cfg, cmd),
    cmd.man,
    arg_sections(args),
  )
  render_manpage(tname, blocks)
}

///|
fn plain(s : String) -> String {
  subst_markup(s, _ => None)
}

// Evaluation ----------------------------------------------------------------

///|
fn[A] run_term(t : Term[A], ei : EvalEnv, cl : Cline) -> A raise EvalFailure {
  (t.convert)(ei, cl) catch {
    CliError(msg) => raise UsageError(msg, true)
  }
}

///|
fn report_usage_error(
  cfg : EvalConfig,
  cmd : CommandDecl?,
  msg : String,
  with_usage : Bool,
) -> Unit {
  let sb = StringBuilder()
  sb.write_string("\{cfg.name}: \{msg}\n")
  if with_usage {
    let (synopsis, try_help) = match cmd {
      None =>
        (
          main_synopsis(cfg, !main_state.val.commands.is_empty()),
          "Try '\{cfg.name} --help' for more information.",
        )
      Some(c) =>
        (
          command_synopsis(cfg, c),
          "Try '\{cfg.name} \{c.name} --help' or '\{cfg.name} --help' for more information.",
        )
    }
    sb.write_string("Usage: \{plain(synopsis)}\n")
    sb.write_string(try_help + "\n")
  }
  (cfg.err)(sb.to_string())
}

///|
fn run_plugin_codes(disabled : Array[String]) -> Unit raise {
  let st = main_state.val
  context_set_plugins(disabled, st.plugin_infos, st.plugin_cmds)
  let ctxt = context_request()
  for p in st.loaded {
    if disabled.contains(p.name) {
      continue
    }
    for i = p.code.length() - 1; i >= 0; i = i - 1 {
      p.code[i](ctxt)
    }
  }
}

///|
/// Selects the term to evaluate: the main term or a command.
fn choose_command(
  args : Array[String],
) -> Result[(CommandDecl?, Array[String]), String] {
  match args {
    [] => Ok((None, []))
    [maybe, .. rest] =>
      if maybe.length() > 1 && maybe.has_prefix("-") {
        Ok((None, args))
      } else {
        let index = main_state.val.commands.map(c => (c.name, c))
        match trie_find(index, maybe) {
          Found(c) => Ok((Some(c), rest.to_owned()))
          NotFound => {
            let all = index.map(c => c.0)
            Err(err_unknown("command", maybe, suggest(maybe, all)))
          }
          Ambiguous =>
            Err(err_ambiguous("command", maybe, trie_ambiguities(index, maybe)))
        }
      }
  }
}

///|
fn eval(argv : Array[String], cfg : EvalConfig) -> Unit raise {
  let st = main_state.val
  // duplicate commands are a configuration error
  let seen : Map[String, Unit] = Map([])
  for c in st.commands {
    if seen.contains(c.name) {
      (cfg.err)(
        "\{cfg.name}: command \{quote(c.name)} is declared more than once\n",
      )
      raise Configuration
    }
    seen[c.name] = ()
  }
  let plugin_names = registered_plugins()
  let g = make_grammars(plugin_names)
  let argv = match cfg.command {
    None => argv
    Some(cmd) =>
      match argv {
        [prog, arg, .. rest] =>
          if st.commands.iter().any(c => c.name.has_prefix(arg)) {
            argv
          } else {
            [prog, cmd, arg, ..rest]
          }
        _ => argv
      }
  }
  let args = if argv.is_empty() { [] } else { argv[1:].to_owned() }
  let (cmd, args) = match choose_command(args) {
    Ok(r) => r
    Err(msg) => {
      report_usage_error(cfg, None, msg, true)
      raise Configuration
    }
  }
  let common = g.common_args()
  let all_args = match cmd {
    None => common
    Some(c) => [..common, ..c.term.args]
  }
  let ei = { getenv: cfg.getenv, }
  let print_help = () => {
    match cmd {
      None => (cfg.out)(main_manpage(cfg, all_args))
      Some(c) => (cfg.out)(command_manpage(cfg, c, all_args))
    }
  }
  let cl = match Cline::create(all_args, args) {
    Ok(cl) => cl
    Err((msg, partial)) => {
      // `--help` and `--version` win over parse errors
      let help = (g.help.convert)(ei, partial) catch {
        CliError(e) => {
          report_usage_error(cfg, cmd, e, false)
          raise Configuration
        }
      }
      if help is Some(_) {
        print_help()
        return
      }
      let version = (g.version.convert)(ei, partial) catch {
        CliError(e) => {
          report_usage_error(cfg, cmd, e, false)
          raise Configuration
        }
      }
      if version {
        (cfg.out)(cfg.version + "\n")
        return
      }
      report_usage_error(cfg, cmd, msg, true)
      raise Configuration
    }
  }
  let help = (g.help.convert)(ei, cl) catch {
    CliError(e) => {
      report_usage_error(cfg, cmd, e, false)
      raise Configuration
    }
  }
  if help is Some(_) {
    print_help()
    return
  }
  let version = (g.version.convert)(ei, cl) catch {
    CliError(e) => {
      report_usage_error(cfg, cmd, e, false)
      raise Configuration
    }
  }
  if version {
    (cfg.out)(cfg.version + "\n")
    return
  }
  evaluate(cfg, g, cmd, ei, cl) catch {
    UsageError(msg, with_usage) => {
      report_usage_error(cfg, cmd, msg, with_usage)
      raise Configuration
    }
    e => raise e
  }
}

///|
/// Evaluates the terms in BAP's order: pre-options, plugin manuals,
/// disabled plugins, plugin options, extensions, and finally the command
/// (or the default function).
fn evaluate(
  cfg : EvalConfig,
  g : Grammars,
  cmd : CommandDecl?,
  ei : EvalEnv,
  cl : Cline,
) -> Unit raise {
  let st = main_state.val
  run_term(g.pre, ei, cl)
  // `--<plugin>-help`
  let mut served : Error? = None
  for h in g.helps {
    let requested = run_term(h.1, ei, cl)
    if served is None && requested is Some(_) {
      match st.plugin_pages.get(h.0) {
        None => served = Some(UnknownPlugin(h.0))
        Some(page) => {
          (cfg.out)(render_manpage(h.0, page))
          served = Some(ExitRequested(0))
        }
      }
    }
  }
  if served is Some(e) {
    raise e
  }
  // `--no-<plugin>`
  let disabled = []
  for d in g.disabled {
    if run_term(d.1, ei, cl) {
      disabled.push(d.0)
    }
  }
  // plugin options: convert all, then set (oldest declarations first)
  for p in st.loaded {
    let setters = []
    for i = p.spec.length() - 1; i >= 0; i = i - 1 {
      setters.push(run_term(p.spec[i], ei, cl))
    }
    for i = setters.length() - 1; i >= 0; i = i - 1 {
      setters[i]()
    }
  }
  run_plugin_codes(disabled)
  match cmd {
    Some(c) => {
      let ctxt = context_request().refine(provides?=c.requires)
      let f = run_term(c.term, ei, cl)
      f(ctxt)
    }
    None =>
      match cfg.default {
        None => ()
        Some(f) => f(context_request())
      }
  }
}
