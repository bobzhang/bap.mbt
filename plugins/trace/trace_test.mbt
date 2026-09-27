///|
fn save_sample(uri : String) -> Unit {
  let tool = @traces.TraceTool::create(name="sample", supported_tags=[
    @traces.TraceEvent::context_switch_tag(),
  ])
  let trace = @traces.Trace::create(tool, events=[
    @traces.TraceEvent::context_switch(1),
    @traces.TraceEvent::context_switch(2),
  ])
  match @traces.Trace::save(uri, trace) {
    Ok(_) => ()
    Err(_) => abort("cannot save the trace")
  }
}

///|
fn run_bap(argv : Array[String]) -> String {
  @bap_main.reset()
  let buf = StringBuilder()
  try {
    @trace.declare_plugin(out=s => buf.write_string(s))
    @bap_main.initialize(argv=["bap", ..argv], out=s => buf.write_string(s), err=s => {
      buf.write_string(s)
    })
  } catch {
    @bap_main.ExitRequested(code) => buf.write_string("[exit \{code}]")
    e => buf.write_string("[error] " + @bap_main.error_to_string(e))
  }
  @bap_main.reset()
  buf.to_string()
}

///|
test "trace dumps a trace" {
  save_sample("memory://sample-1")
  inspect(
    run_bap(["--trace-dump=memory://sample-1"]),
    content=(
      #|events {
      #|  context-switch: 1
      #|  context-switch: 2
      #|}
      #|[exit 0]
    ),
  )
}

///|
test "trace loads traces" {
  save_sample("memory://sample-2")
  let before = @traces.Traces::to_list().length()
  inspect(run_bap(["--trace-load=memory://sample-2"]), content="")
  inspect(@traces.Traces::to_list().length() - before, content="1")
}

///|
test "trace reports errors" {
  inspect(
    run_bap(["--trace-dump=memory://x", "--trace-load=memory://y"]),
    content=(
      #|[error] Incompatible arguments, see usage SYNOPSIS
    ),
  )
  // The underlying IO error differs between native and non-native targets.
  assert_true(
    run_bap(["--trace-load=nothing.binprot"]).has_prefix(
      "[error] Protocol error: ",
    ),
  )
  inspect(
    run_bap(["--trace-load=memory://missing"]),
    content=(
      #|[error] No provider for the given URI
    ),
  )
}
