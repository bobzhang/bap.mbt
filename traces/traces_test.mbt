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
  @traces.TraceMeta::empty().set_binary(test_binary()).set_tracer(test_tracer())
}

///|
fn extended_meta() -> @traces.TraceMeta {
  test_meta()
  .set_arch(X86_64)
  .set_binary_file_stats({ size: 42, atime: 1.25, mtime: 2.5, ctime: 3.75 })
  .set_trace_stats({ user: "me", host: "host", time: 4.5 })
  .set("comment", Text("snapshot"))
  .set("pid", Int(-1))
  .set("complete", Bool(true))
}

///|
fn broad_events() -> Array[@traces.TraceEvent] raise {
  let caller = @traces.Location::{ name: Some("main"), addr: word32(0x401000) }
  let callee = @traces.Location::{ name: None, addr: word32(0x402000) }
  [
    @traces.TraceEvent::timestamp(-42L),
    @traces.TraceEvent::pc_update(word32(0x401000)),
    @traces.TraceEvent::code_exec(
      @traces.Chunk::create(addr=word32(0x401000), data=b"\x90\xcc"),
    ),
    @traces.TraceEvent::context_switch(-1),
    @traces.TraceEvent::syscall({ number: 60, args: [word32(0)] }),
    @traces.TraceEvent::exn({ number: 13, src: Some(word32(1)), dst: None }),
    @traces.TraceEvent::call({ caller, callee, args: [word32(1), word32(2)] }),
    @traces.TraceEvent::return_event({ caller: "main", callee: "callee" }),
    @traces.TraceEvent::modload({
      name: "libc.so",
      low: word32(0x1000),
      high: word32(0x1fff),
    }),
    @traces.TraceEvent::mode("thumb"),
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
fn trace_ids(traces : Array[@traces.Trace]) -> Array[Int] {
  traces.map(trace => trace.id())
}

///|
test "translated BAP common trace event tags match helper constructors" {
  assert_true(
    @traces.TraceEvent::common_tags() ==
    [
      @traces.TraceEvent::memory_load_tag(),
      @traces.TraceEvent::memory_store_tag(),
      @traces.TraceEvent::register_read_tag(),
      @traces.TraceEvent::register_write_tag(),
      @traces.TraceEvent::timestamp_tag(),
      @traces.TraceEvent::pc_update_tag(),
      @traces.TraceEvent::code_exec_tag(),
      @traces.TraceEvent::context_switch_tag(),
      @traces.TraceEvent::syscall_tag(),
      @traces.TraceEvent::exn_tag(),
      @traces.TraceEvent::call_tag(),
      @traces.TraceEvent::return_tag(),
      @traces.TraceEvent::modload_tag(),
      @traces.TraceEvent::mode_tag(),
    ],
  )
  let events = test_events()
  assert_true(
    [
      for event in events => event.tag()
    ] ==
    [
      @traces.TraceEvent::memory_load_tag(),
      @traces.TraceEvent::memory_store_tag(),
      @traces.TraceEvent::register_read_tag(),
      @traces.TraceEvent::register_write_tag(),
    ],
  )
  assert_true(events[0].memory_load_value() == Some(test_move()))
  assert_true(events[1].memory_store_value() == Some(test_move()))
  assert_true(events[2].register_read_value() == Some(register_move()))
  assert_true(events[3].register_write_value() == Some(register_move()))
  assert_true(events[0].register_read_value() == None)
  let broad = broad_events()
  assert_true(
    [
      for event in broad => event.tag()
    ] ==
    [
      @traces.TraceEvent::timestamp_tag(),
      @traces.TraceEvent::pc_update_tag(),
      @traces.TraceEvent::code_exec_tag(),
      @traces.TraceEvent::context_switch_tag(),
      @traces.TraceEvent::syscall_tag(),
      @traces.TraceEvent::exn_tag(),
      @traces.TraceEvent::call_tag(),
      @traces.TraceEvent::return_tag(),
      @traces.TraceEvent::modload_tag(),
      @traces.TraceEvent::mode_tag(),
    ],
  )
  assert_true(broad[0].timestamp_value() == Some(-42L))
  assert_true(broad[1].pc_update_value() == Some(word32(0x401000)))
  assert_true(
    broad[2].code_exec_value() ==
    Some(@traces.Chunk::create(addr=word32(0x401000), data=b"\x90\xcc")),
  )
  assert_true(broad[3].context_switch_value() == Some(-1))
  assert_true(
    broad[4].syscall_value() == Some({ number: 60, args: [word32(0)] }),
  )
  assert_true(
    broad[5].exn_value() ==
    Some({ number: 13, src: Some(word32(1)), dst: None }),
  )
  assert_true(broad[6].call_value() is Some(_))
  assert_true(
    broad[7].return_value() == Some({ caller: "main", callee: "callee" }),
  )
  assert_true(
    broad[8].modload_value() ==
    Some({ name: "libc.so", low: word32(0x1000), high: word32(0x1fff) }),
  )
  assert_true(broad[9].mode_value() == Some("thumb"))
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
test "translated BAP trace metadata dictionaries expose sorted entries and removal" {
  let meta = extended_meta()
  assert_true(!meta.is_empty())
  assert_true(meta.length() == 8)
  assert_true(@traces.TraceMeta::binary_key() == "binary")
  assert_true(@traces.TraceMeta::tracer_key() == "tracer")
  assert_true(@traces.TraceMeta::arch_key() == "arch")
  assert_true(@traces.TraceMeta::binary_file_stats_key() == "file-stats")
  assert_true(@traces.TraceMeta::trace_stats_key() == "trace-stats")
  assert_true(meta.binary() == Some(test_binary()))
  assert_true(meta.tracer() == Some(test_tracer()))
  assert_true(meta.arch() == Some(X86_64))
  assert_true(
    meta.binary_file_stats() ==
    Some({ size: 42, atime: 1.25, mtime: 2.5, ctime: 3.75 }),
  )
  assert_true(
    meta.trace_stats() == Some({ user: "me", host: "host", time: 4.5 }),
  )
  assert_true(
    meta.keys() ==
    [
      "pid", "arch", "binary", "tracer", "comment", "complete", "file-stats", "trace-stats",
    ],
  )
  assert_true(meta.entries().map(entry => entry.0) == meta.keys())
  let removed = meta.remove("pid")
  assert_true(!removed.has("pid"))
  assert_true(removed.length() == 7)
  assert_true(removed.remove("missing").keys() == removed.keys())
}

///|
test "translated BAP loaded trace registry adds lists and removes traces" {
  let first = new_trace()
  let second = new_trace()
  @traces.Trace::remove_loaded(first)
  @traces.Trace::remove_loaded(second)
  let before = @traces.Trace::loaded().length()
  @traces.Trace::add_loaded(second)
  @traces.Trace::add_loaded(first)
  @traces.Trace::add_loaded(first)

  let loaded = @traces.Trace::loaded()
  let ids = trace_ids(loaded)
  assert_true(loaded.length() == before + 2)
  assert_true(ids.contains(first.id()))
  assert_true(ids.contains(second.id()))
  assert_true(
    ids.filter(id => id == first.id() || id == second.id()) ==
    [first.id(), second.id()],
  )
  let iter_ids : Array[Int] = []
  @traces.Trace::loaded_iter().each(trace => {
    if trace.id() == first.id() || trace.id() == second.id() {
      iter_ids.push(trace.id())
    }
  })
  assert_true(iter_ids == [first.id(), second.id()])

  @traces.Trace::remove_loaded(first)
  let after_first_remove = trace_ids(@traces.Trace::loaded())
  assert_true(!after_first_remove.contains(first.id()))
  assert_true(after_first_remove.contains(second.id()))

  @traces.Trace::remove_loaded(second)
  let after_second_remove = trace_ids(@traces.Trace::loaded())
  assert_true(!after_second_remove.contains(first.id()))
  assert_true(!after_second_remove.contains(second.id()))
  assert_true(after_second_remove.length() == before)
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
        MemoryLoad(_) | MemoryStore(_) => Some("Memory")
        _ => None
      }
    }),
  )
  assert_true(categories == ["Memory", "Memory"])

  let memory = unwrap_events(new_trace().read_all("memory-load"))
  assert_true(memory == [@traces.TraceEvent::memory_load(test_move())])
  match new_trace().read_all_matching(fn(event) { event.memory_load_value() }) {
    Ok(loads) => assert_true(loads == [test_move()])
    _ => fail("expected typed memory-load values")
  }
  match
    new_trace().read_all_matching(fn(event) { event.register_read_value() }) {
    Ok(reads) => assert_true(reads == [register_move()])
    _ => fail("expected typed register-read values")
  }

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
