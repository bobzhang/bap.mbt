///|
fn word32(value : Int) -> @types.Word raise {
  @types.Word::of_int32(value)
}

///|
fn test_move() -> @traces.Move[@types.Word] raise {
  @traces.Move::create(cell=word32(0xbed), data=word32(0xc0ffee))
}

///|
fn test_var() -> @types.Var {
  @types.Var::new(name="temp", typ=Imm(0xc0ffee), is_virtual=true)
}

///|
fn register_move() -> @traces.Move[@types.Var] raise {
  @traces.Move::create(cell=test_var(), data=word32(0xc0ffee))
}

///|
fn test_events() -> Array[@traces.TraceEvent] raise {
  [
    @traces.TraceEvent::memory_load(test_move()),
    @traces.TraceEvent::memory_store(test_move()),
    @traces.TraceEvent::register_read(register_move()),
    @traces.TraceEvent::register_write(register_move()),
  ]
}

///|
fn memory_events() -> Array[@traces.TraceEvent] raise {
  [
    @traces.TraceEvent::memory_load(test_move()),
    @traces.TraceEvent::memory_store(test_move()),
  ]
}

///|
fn test_tool() -> @traces.TraceTool {
  @traces.TraceTool::register(name="test_tool", supported_tags=[
    "memory-load", "memory-store",
  ])
}

///|
fn new_trace() -> @traces.Trace raise {
  @traces.Trace::create(test_tool(), events=test_events())
}

///|
fn unwrap_events(
  result : Result[Array[@traces.TraceEvent], @traces.TraceError],
) -> Array[@traces.TraceEvent] raise {
  match result {
    Ok(events) => events
    Err(_) => fail("unexpected trace error")
  }
}

///|
fn test_binary() -> @traces.BinaryInfo {
  { path: "home", args: ["go"], envp: ["drink=coffee"], md5sum: "" }
}

///|
fn test_tracer() -> @traces.TracerInfo {
  { name: "coffee", args: ["scent"], envp: ["require=coffee"], version: "0.1" }
}

///|
fn test_meta() -> @traces.TraceMeta {
  @traces.TraceMeta::empty()
  .set("binary", Binary(test_binary()))
  .set("tracer", Tracer(test_tracer()))
}

///|
fn extended_meta() -> @traces.TraceMeta {
  test_meta()
  .set("comment", Text("snapshot"))
  .set("pid", Int(-1))
  .set("complete", Bool(true))
}

///|
fn broad_events() -> Array[@traces.TraceEvent] raise {
  let caller = @traces.Location::{ name: Some("main"), addr: word32(0x401000) }
  let callee = @traces.Location::{ name: None, addr: word32(0x402000) }
  [
    Timestamp(-42L),
    PcUpdate(word32(0x401000)),
    CodeExec(@traces.Chunk::create(addr=word32(0x401000), data=b"\x90\xcc")),
    ContextSwitch(-1),
    Syscall({ number: 60, args: [word32(0)] }),
    Exception({ number: 13, src: Some(word32(1)), dst: None }),
    Call({ caller, callee, args: [word32(1), word32(2)] }),
    Return({ caller: "main", callee: "callee" }),
    Modload({ name: "libc.so", low: word32(0x1000), high: word32(0x1fff) }),
    Mode("thumb"),
  ]
}

///|
fn tool_for_events(events : Array[@traces.TraceEvent]) -> @traces.TraceTool {
  @traces.TraceTool::register(
    name="broad_tool",
    supported_tags=[ for event in events => event.tag() ],
  )
}

///|
test "translated BAP traces preserve ids tools metadata and in-memory save/load" {
  let first = new_trace()
  let second = new_trace()
  assert_true(first.id() != second.id())
  assert_true(first.tool() == test_tool())

  let trace = first.set_attr("binary", Binary(test_binary()))
  assert_true(trace.has_attr("binary"))
  assert_true(trace.get_attr("binary") == Some(Binary(test_binary())))

  let with_meta = trace.set_meta(test_meta())
  assert_true(with_meta.meta() == test_meta())

  match @traces.Trace::save("memory://bap-trace", with_meta) {
    Ok(_) => ()
    Err(_) => fail("save failed")
  }
  match @traces.Trace::load("memory://bap-trace") {
    Ok(loaded) => {
      assert_true(loaded.protocol() == Some("memory"))
      assert_true(loaded.tool() == test_tool())
      assert_true(loaded.meta() == test_meta())
      assert_true(unwrap_events(loaded.read_events()) == test_events())
    }
    Err(_) => fail("load failed")
  }
  match @traces.Trace::load("memory://bap-trace") {
    Ok(loaded) =>
      assert_true(unwrap_events(loaded.read_events()) == test_events())
    Err(_) => fail("second load failed")
  }
}

///|
test "translated BAP trace byte snapshots round trip metadata and event variants" {
  let events = broad_events()
  let meta = extended_meta()
  let trace = @traces.Trace::create(tool_for_events(events), events~).set_meta(
    meta,
  )
  match trace.to_bytes() {
    Ok(bytes) => {
      assert_true(bytes.length() > 0)
      match @traces.Trace::of_bytes(bytes) {
        Ok(loaded) => {
          assert_true(loaded.tool() == tool_for_events(events))
          assert_true(loaded.meta() == meta)
          assert_true(unwrap_events(loaded.read_events()) == events)
        }
        Err(_) => fail("snapshot decode failed")
      }
      match @traces.Trace::of_bytes(bytes) {
        Ok(loaded) => assert_true(unwrap_events(loaded.read_events()) == events)
        Err(_) => fail("second snapshot decode failed")
      }
    }
    Err(_) => fail("snapshot encode failed")
  }
  match @traces.Trace::of_bytes(b"not a trace snapshot") {
    Err(ProtocolError(_)) => ()
    _ => fail("expected protocol error for malformed snapshot")
  }
}

///|
test "translated BAP trace protocol registry selects URI providers" {
  match @traces.Trace::load("unknown://trace") {
    Err(NoProvider("unknown://trace")) => ()
    _ => fail("expected no provider")
  }

  let custom_tool = @traces.TraceTool::register(name="custom_tool", supported_tags=[
    "memory-load", "register-read",
  ])
  let custom_events = [
    Ok(@traces.TraceEvent::memory_load(test_move())),
    Ok(@traces.TraceEvent::register_read(register_move())),
  ]
  let custom_protocol = @traces.TraceProtocol::create(
    name="custom-provider",
    supported_tags=["memory-load"],
    probe=fn(uri) { uri.has_prefix("custom://") },
  )
  @traces.Trace::register_protocol(custom_protocol)
  @traces.Trace::register_reader("custom-provider", fn(uri) {
    if uri == "custom://trace" {
      Ok({ tool: custom_tool, meta: test_meta(), events: custom_events })
    } else {
      Err(NoProvider(uri))
    }
  })
  let saved_custom : Ref[String?] = Ref(None)
  @traces.Trace::register_writer("custom-provider", fn(uri, trace) {
    saved_custom.val = Some(uri)
    match trace.read_events() {
      Ok(_) => Ok(())
      Err(error) => Err(error)
    }
  })
  match @traces.Trace::load("custom://trace") {
    Ok(trace) => {
      assert_true(trace.protocol() == Some("custom-provider"))
      assert_true(trace.tool() == custom_tool)
      assert_true(trace.meta() == test_meta())
      assert_true(trace.supports("memory-load"))
      assert_true(!trace.supports("register-read"))
      assert_true(unwrap_events(trace.read_events()).length() == 2)
    }
    Err(_) => fail("custom provider load failed")
  }
  match @traces.Trace::save("custom://saved", new_trace()) {
    Ok(_) => assert_true(saved_custom.val == Some("custom://saved"))
    Err(_) => fail("custom provider save failed")
  }

  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(name="ambiguous-a", probe=fn(uri) {
      uri.has_prefix("ambiguous://")
    }),
  )
  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(name="ambiguous-b", probe=fn(uri) {
      uri.has_prefix("ambiguous://")
    }),
  )
  match @traces.Trace::load("ambiguous://trace") {
    Err(AmbiguousUri("ambiguous://trace")) => ()
    _ => fail("expected ambiguous URI")
  }
}

///|
test "translated BAP traces read matching events and tool support" {
  let trace = new_trace()
  assert_true(trace.supports("memory-load"))
  assert_true(trace.supports("memory-store"))
  assert_true(!trace.supports("register-read"))

  let categories = unwrap_string_events(
    new_trace().read_all_matching(fn(event) {
      match event {
        MemoryLoad(_) | MemoryStore(_) => "Memory"
        _ => "Unknown"
      }
    }),
  )
  assert_true(categories.filter(value => value == "Memory").length() == 2)

  let memory = unwrap_events(new_trace().read_all("memory-load"))
  assert_true(memory == [@traces.TraceEvent::memory_load(test_move())])

  match new_trace().next("register-read") {
    Ok(Some(RegisterRead(access))) => assert_true(access == register_move())
    _ => fail("expected next register-read event")
  }
  match
    new_trace().next_matching(fn(event) {
      match event {
        MemoryStore(value) => Some(value)
        _ => None
      }
    }) {
    Ok(Some(value)) => assert_true(value == test_move())
    _ => fail("expected next matching memory-store event")
  }

  let filtered = new_trace().filter_map(fn(event) {
    match event {
      MemoryLoad(_) | MemoryStore(_) => Some(event)
      _ => None
    }
  })
  assert_true(unwrap_events(filtered.read_events()) == memory_events())
}

///|
fn unwrap_string_events(
  result : Result[Array[String], @traces.TraceError],
) -> Array[String] raise {
  match result {
    Ok(events) => events
    Err(_) => fail("unexpected trace error")
  }
}

///|
fn events_with_error() -> Array[Result[@traces.TraceEvent, String]] raise {
  let events = test_events()
  [
    Err("syscall failed"),
    Ok(events[0]),
    Ok(events[1]),
    Ok(events[2]),
    Ok(events[3]),
  ]
}

///|
fn trace_with_monitor(monitor : @traces.TraceMonitor) -> @traces.Trace raise {
  @traces.Trace::from_results(test_tool(), events_with_error(), monitor~)
}

///|
test "translated BAP trace monitors handle source errors" {
  let failed = trace_with_monitor(@traces.TraceMonitor::fail_on_error()).read_events()
  assert_true(failed == Err(TraceFailure("syscall failed")))

  let ignored = trace_with_monitor(@traces.TraceMonitor::ignore_errors())
  assert_true(unwrap_events(ignored.read_events()) == test_events())

  let stopped = trace_with_monitor(@traces.TraceMonitor::stop_on_error())
  assert_true(unwrap_events(stopped.read_events()) == [])

  let packed_event = @traces.TraceEvent::memory_load(test_move())
  let packed = trace_with_monitor(
    @traces.TraceMonitor::pack_errors(fn(_) { packed_event }),
  )
  assert_true(
    unwrap_events(packed.read_events()).length() == test_events().length() + 1,
  )

  let warnings = Ref(0)
  let warned = trace_with_monitor(
    @traces.TraceMonitor::warn_on_error(fn(_) { warnings.val += 1 }),
  )
  assert_true(unwrap_events(warned.read_events()) == test_events())
  assert_true(warnings.val == 1)

  let user = trace_with_monitor(@traces.TraceMonitor::create(fn(_) { Skip }))
  assert_true(unwrap_events(user.read_events()) == test_events())
}
