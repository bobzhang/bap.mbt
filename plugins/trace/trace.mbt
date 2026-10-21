// The `trace` plugin (upstream `Trace_main`): loads and prints execution
// traces.

///|
/// The name of the plugin.
pub let name : String = "trace"

///|
let doc : String =
  #|
  #|# SYNOPSIS
  #|
  #|```
  #|  bap --trace-dump=URI
  #|  bap BINARY --trace-load=URI...
  #|```
  #|
  #|# DESCRIPTION
  #|
  #|Loads and prints traces. The plugin can be used in two modes. When
  #|called as $(b,--trace-dump) it will just dump the specified trace and
  #|exit. In the second mode, it will load specified traces, so that they
  #|can be used by analysis. The loaded traces must be runs of the analyzed
  #|$(i,BINARY). The loaded traces are accessible via the $(b,Traces) of
  #|the traces library.
  #|
  #|# SEE ALSO
  #|
  #|$(b,bap-trace)(3)
  #|

///|
/// The failures of the plugin (upstream `exitf` messages).
pub(all) suberror TraceCommandError {
  IncompatibleArgs
  LoadFailed(@traces.TraceError)
}

///|
pub fn TraceCommandError::to_string(self : TraceCommandError) -> String {
  match self {
    IncompatibleArgs => "Incompatible arguments, see usage SYNOPSIS"
    LoadFailed(err) =>
      match err {
        ProtocolError(msg) => "Protocol error: \{msg}"
        NoProvider(_) => "No provider for the given URI"
        AmbiguousUri(_) => "More than one provider for a given URI"
        TraceFailure(msg) => "System error: \{msg}"
        DuplicateRegistration(msg) => "System error: \{msg}"
      }
  }
}

///|
/// A URI with the `file` scheme when no scheme is given (upstream
/// `uri_of_string`).
pub fn uri_of_string(s : String) -> String {
  if s.contains("://") {
    s
  } else {
    "file://" + s
  }
}

///|
fn attr_to_string(v : @traces.TraceAttrValue) -> String {
  match v {
    Binary(b) => b.to_string()
    Tracer(t) => t.to_string()
    Arch(a) => a.to_string()
    FileStats(s) => s.to_string()
    TraceStats(s) => s.to_string()
    Text(s) => s
    Int(n) => n.to_string()
    Bool(b) => b.to_string()
  }
}

///|
/// Renders the meta information and the events of the trace (upstream
/// `try_dump`); the trace statistics go first.
pub fn dump(trace : @traces.Trace) -> String raise TraceCommandError {
  let sb = StringBuilder()
  let entries = trace.meta().entries()
  let stats = entries.filter(e => e.1 is TraceStats(_))
  let others = entries.filter(e => !(e.1 is TraceStats(_)))
  for entry in [..stats, ..others] {
    sb.write_string(attr_to_string(entry.1) + "\n")
  }
  sb.write_string("events {\n")
  let events = trace.read_events() catch {
    err => raise LoadFailed(err)
  }
  for event in events {
    sb.write_string("  \{event.to_string()}\n")
  }
  sb.write_string("}\n")
  sb.to_string()
}

///|
fn load(uri : String) -> @traces.Trace raise TraceCommandError {
  match @traces.Trace::load(uri_of_string(uri)) {
    Ok(trace) => trace
    Err(err) => raise LoadFailed(err)
  }
}

///|
/// Dumps the trace at `dump_uri` or loads the traces at `loads` into
/// the `Traces` registry (upstream `main`). Dumping raises
/// `ExitRequested(0)` after printing, as upstream exits.
pub fn run(
  dump_uri : String?,
  loads : Array[String],
  out~ : (String) -> Unit,
) -> Unit raise {
  match (dump_uri, loads) {
    (Some(_), [_, ..]) => raise IncompatibleArgs
    (Some(uri), []) => {
      out(dump(load(uri)))
      raise @bap_main.ExitRequested(0)
    }
    (None, loads) =>
      for uri in loads {
        @traces.Traces::add(load(uri))
      }
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
/// Declares the `trace` plugin (the `--trace-dump` and `--trace-load`
/// options) in the `bap_main` framework. Does nothing if it is already
/// registered.
pub fn declare_plugin(
  out~ : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  if !printer_registered.val {
    printer_registered.val = true
    @bap_main.register_error_printer(e => {
      match e {
        IncompatibleArgs => Some(IncompatibleArgs.to_string())
        LoadFailed(err) => Some(LoadFailed(err).to_string())
        _ => None
      }
    })
  }
  @bap_main.register_plugin(
    name,
    provides=["dynamic", "pass", "printer", "trace"],
    doc="manages execution traces",
    () => {
      @bap_main.Extension::documentation(doc)
      let dump = @bap_main.Configuration::parameter(
        doc="Dump a trace specified by $(docv)",
        @bap_main.Type::some(@bap_main.Type::string()).rename("URI"),
        "dump",
      )
      let load = @bap_main.Configuration::parameters(
        doc="Load trace from the specified $(docv). The option maybe used many times to load several traces",
        @bap_main.Type::string().rename("URI"),
        "load",
      )
      @bap_main.Extension::register(ctxt => {
        run(ctxt.get(dump), ctxt.get(load), out~)
      })
    },
  )
}
