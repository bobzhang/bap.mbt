///|
/// # Printing of Primus observations (upstream `plugins/primus_print`)
///
/// Monitors a Primus execution:
///
/// - the selected observations are printed as `(<name> <value>)`, one per
///   line (`observations`: a list of provider names, `all` selects all
///   providers, `-<name>` removes a provider, `+<name>` is the same as
///   `<name>`);
/// - BARE rules (`rules`: files with rules) are applied to the stream of
///   observations of the providers mentioned in their left-hand sides (a
///   pattern whose head is a variable matches any provider); the derived
///   facts are printed and fed back into the rule;
/// - with `traceback`, the `bap:observation-printer` component records
///   every position a machine enters and prints the trace (the most recent
///   position first) when the system stops. As upstream, the optional
///   length of the traceback is accepted but does not limit the trace.
///
/// The output goes to a sink: standard output by default, or a file
/// (written when a system stops and on `flush`).
pub let component_name : String = "observation-printer"

///|
/// Errors of the monitor specification.
pub suberror PrintError {
  UnknownProvider(String)
  BadRules(String)
} derive(Debug)

///|
pub impl Show for PrintError with fn output(self, logger) {
  match self {
    UnknownProvider(name) =>
      logger.write_string("An unknown observation provider `\{name}'")
    BadRules(msg) => logger.write_string(msg)
  }
}

///|
/// The default sink: prints the text to the standard output (the text
/// produced by the monitors is newline-terminated).
pub fn stdout_sink(s : String) -> Unit {
  if s.is_empty() {
    return
  }
  if s.has_suffix("\n") {
    println(s.view(end_offset=s.length() - 1))
  } else {
    println(s)
  }
}

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-print",
)

///|
fn starts_with(name : String, c : Char) -> Bool {
  name.length() > 1 && name.get_char(0) == Some(c)
}

///|
fn strip(name : String) -> String {
  if starts_with(name, '+') || starts_with(name, '-') {
    name.view(start_offset=1).to_owned()
  } else {
    name
  }
}

///|
fn has_name(name : String, p : @primus.Provider) -> Bool {
  @knowledge.Name::read(name, pkg="primus") == p.fullname()
}

///|
/// Selects the providers to monitor (upstream `parse_monitors`).
pub fn parse_monitors(
  names : Array[String],
) -> Array[@primus.Provider] raise PrintError {
  let mut ps : Array[@primus.Provider] = []
  for name in names {
    if name == "all" {
      ps = [..ps, ..@primus.Observation::list_providers()]
    } else if starts_with(name, '-') {
      let n = strip(name)
      ps = ps.filter(p => !has_name(n, p))
    } else {
      let n = strip(name)
      match
        @primus.Observation::list_providers()
        .iter()
        .find_first(p => has_name(n, p)) {
        None => raise UnknownProvider(n)
        Some(p) => ps = [p, ..ps]
      }
    }
  }
  ps
}

///|
/// Prints the observations of the providers to the sink (upstream
/// `print_event`). The listeners are global and cannot be removed.
pub fn monitor(
  providers : Array[@primus.Provider],
  out : (String) -> Unit,
) -> Unit {
  for p in providers {
    log.info(message="monitoring \{p.name()}")
    let name = p.name()
    p.on_data(ev => out("(\{name} \{ev})\n"))
  }
}

///|
fn bare_of_sexp(s : @primus.Sexp) -> @bare.BareTerm {
  match s {
    Atom(a) => BareAtom(a)
    List(xs) => BareList(xs.map(bare_of_sexp))
  }
}

///|
/// The names of the providers whose observations the rule matches.
fn rule_providers(rule : @bare.Rule) -> Array[String] {
  let out = []
  for pat in rule.lhs() {
    match pat {
      BareAtom(x) | BareList([BareAtom(x), ..]) =>
        if x.has_prefix("?") {
          for p in @primus.Observation::list_providers() {
            out.push(p.name())
          }
        } else {
          out.push(x)
        }
      _ =>
        log.warning(
          message="Rule \{rule.spec()} won't match with any observation",
        )
    }
  }
  out
}

///|
/// Applies the rule to the observations of the providers it mentions and
/// prints the derived facts (upstream `process_rule`). Derived facts are
/// fed back into the rule after the current fact is processed.
pub fn process_rule(rule : @bare.Rule, out : (String) -> Unit) -> Unit {
  let observing = rule_providers(rule)
  let current = Ref(rule)
  let queue : Array[@bare.BareTerm] = []
  let busy = Ref(false)
  let feed = (fact : @bare.BareTerm) => {
    queue.push(fact)
    if busy.val {
      return
    }
    busy.val = true
    while !queue.is_empty() {
      let fact = queue.remove(0)
      let (next, facts) = current.val.apply(fact)
      current.val = next
      for f in facts {
        out("\{f.to_string()}\n")
      }
      queue.append(facts)
    }
    busy.val = false
  }
  for p in @primus.Observation::list_providers() {
    let name = p.name()
    if observing.contains(name) {
      p.on_data(ev => feed(BareList([BareAtom(name), bare_of_sexp(ev)])))
    }
  }
}

///|
/// Reads the rules from the files and processes them (upstream
/// `setup_rules_processor`).
pub fn setup_rules(
  files : Array[String],
  out : (String) -> Unit,
) -> Unit raise PrintError {
  for file in files {
    let rules = match @bare.Rule::from_file(file) {
      Ok(rules) => rules
      Err(e) => raise BadRules("\{file}: \{e.to_string()}")
    }
    for rule in rules {
      process_rule(rule, out)
    }
  }
}

///|
/// Renders a position of the trace (upstream `print_pos`).
pub fn pos_to_string(pos : @primus.Pos) -> String {
  match pos {
    Top(_) => ""
    Sub(s) => "\{pos.tid().to_string()}: <\{@types.Sub::name(s.me)}>\n"
    Blk(_) => "\{pos.tid().to_string()}:\n"
    Arg(a) => a.me.arg_to_string()
    Phi(p) => p.me.phi_to_string()
    Def(d) => d.me.def_to_string()
    Jmp(j) => j.me.jmp_to_string()
  }
}

///|
let trace_state : @primus.State[@list.List[@primus.Pos]] = @primus.State::declare_(
  uuid="2fdb0758-3233-4d69-b2e6-704b303ac03a",
  name="primus-debug",
  _ => @list.empty(),
)

///|
/// The positions entered by the current machine, the most recent first.
pub fn trace(m : @primus.Machine) -> Array[@primus.Pos] {
  m.get_local(trace_state).to_array()
}

///|
/// Initializes the tracing in the machine (the `bap:observation-printer`
/// component body): when `traceback` is set, every entered position is
/// recorded and the trace is printed when the system stops.
pub fn install(
  m : @primus.Machine,
  traceback? : Int,
  out? : (String) -> Unit = stdout_sink,
) -> Unit {
  if traceback is Some(_) {
    m.observe(@primus.enter_pos, p => {
      m.update_local(trace_state, t => t.prepend(p))
    })
    m.observe(@primus.system_stop, _ => {
      for p in m.get_local(trace_state) {
        out(pos_to_string(p))
      }
    })
  }
}

///|
/// A sink that accumulates the output and writes it to a file when a
/// system stops (and on `FileSink::flush`).
pub struct FileSink {
  path : String
  priv buffer : StringBuilder
}

///|
/// Creates a file sink; the file is written when a system stops.
pub fn FileSink::new(path : String) -> FileSink {
  let sink = { path, buffer: StringBuilder(), }
  @primus.system_stop.provider().on_data(_ => sink.flush())
  sink
}

///|
/// Appends text to the sink.
pub fn FileSink::write(self : FileSink, s : String) -> Unit {
  self.buffer.write_string(s)
}

///|
/// Writes the accumulated output to the file.
pub fn FileSink::flush(self : FileSink) -> Unit {
  match
    @native_io.write_file(self.path, @utf8.encode(self.buffer.to_string())) {
    Ok(_) => ()
    Err(msg) => log.error(message="failed to write \{self.path}: \{msg}")
  }
}

///|
let started : Ref[Bool] = { val: false, }

///|
/// Starts monitoring (the body of the upstream extension): registers the
/// `bap:observation-printer` component, adds it to the legacy main system,
/// sets up the rules and the printing of the selected observations. The
/// output goes to `output` (a file) or to `out` (standard output by
/// default). Does nothing if monitoring was already started.
pub fn start_monitoring(
  observations? : Array[String] = [],
  output? : String,
  rules? : Array[String] = [],
  traceback? : Int,
  out? : (String) -> Unit = stdout_sink,
) -> Unit raise PrintError {
  if started.val {
    return
  }
  started.val = true
  let out = match output {
    None => out
    Some(path) => {
      let sink = FileSink::new(path)
      s => sink.write(s)
    }
  }
  setup_rules(rules, out)
  @primus.Machine::add_component(m => install(m, traceback?, out~))
  @primus.Components::register_generic(
    component_name,
    m => install(m, traceback?, out~),
    pkg="bap",
    desc="Prints the specified set of observations. Controlled via the primus-print plugin.",
  ) catch {
    _ => ()
  }
  monitor(parse_monitors(observations), out)
}

///|
/// The name of the plugin.
pub let name : String = "primus-print"

///|
/// Declares the `primus-print` plugin to `bap_main` with its
/// `observations`, `output`, `rules` and `traceback` parameters. Does
/// nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "printer", "observations"],
    doc="prints Primus states and observations\n\nMonitors a Lisp Machine execution.",
    () => {
      let observations = @bap_main.Configuration::parameter(
        @bap_main.Type::string().list(),
        "observations",
        doc="A list of observations to print. A keyword `all` can be use to select all events. To ignore a particular event, add `-' before the name. An optional + is allowed for the consistency.",
      )
      let output = @bap_main.Configuration::parameter(
        @bap_main.Type::string().some(),
        "output",
        doc="A name of a file in which to store the monitor output. If not specified, then outputs result into stdout",
      )
      let rules = @bap_main.Configuration::parameter(
        @bap_main.Type::string().list(),
        "rules",
      )
      let traceback = @bap_main.Configuration::parameter(
        @bap_main.Type::int().some(),
        "traceback",
        as_flag=Some(16),
        doc="Stores and outputs a trace of execution. Takes an optional argument that limits the traceback length to the specified number of terms.",
      )
      @bap_main.Extension::register(ctxt => {
        start_monitoring(
          observations=ctxt.get(observations),
          output?=ctxt.get(output),
          rules=ctxt.get(rules),
          traceback?=ctxt.get(traceback),
        )
      })
    },
  )
}
