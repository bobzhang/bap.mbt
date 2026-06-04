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
  @traces.Binary::create(
    path="home",
    args=["go"],
    envp=["drink=coffee"],
    md5sum="",
  )
}

///|
fn test_tracer() -> @traces.TracerInfo {
  @traces.Tracer::create(
    name="coffee",
    args=["scent"],
    envp=["require=coffee"],
    version="0.1",
  )
}

///|
fn test_meta() -> @traces.TraceMeta {
  @traces.TraceMeta::empty().set_binary(test_binary()).set_tracer(test_tracer())
}

///|
fn extended_meta() -> @traces.TraceMeta {
  test_meta()
  .set_arch(X86_64)
  .set_binary_file_stats(
    @traces.File_stats::create(size=42, atime=1.25, mtime=2.5, ctime=3.75),
  )
  .set_trace_stats(
    @traces.Trace_stats::create(user="me", host="host", time=4.5),
  )
  .set("comment", Text("snapshot"))
  .set("pid", Int(-1))
  .set("complete", Bool(true))
}

///|
fn broad_events() -> Array[@traces.TraceEvent] raise {
  let caller = @traces.Location::create(
    name=Some("main"),
    addr=word32(0x401000),
  )
  let callee = @traces.Location::create(addr=word32(0x402000))
  [
    @traces.TraceEvent::timestamp(-42L),
    @traces.TraceEvent::pc_update(word32(0x401000)),
    @traces.TraceEvent::code_exec(
      @traces.Chunk::create(addr=word32(0x401000), data=b"\x90\xcc"),
    ),
    @traces.TraceEvent::context_switch(-1),
    @traces.TraceEvent::syscall(
      @traces.Syscall::create(number=60, args=[word32(0)]),
    ),
    @traces.TraceEvent::exn(@traces.Exn::create(number=13, src=Some(word32(1)))),
    @traces.TraceEvent::call(
      @traces.Call::create(caller~, callee~, args=[word32(1), word32(2)]),
    ),
    @traces.TraceEvent::return_event(
      @traces.Return::create(caller="main", callee="callee"),
    ),
    @traces.TraceEvent::modload(
      @traces.Modload::create(
        name="libc.so",
        low=word32(0x1000),
        high=word32(0x1fff),
      ),
    ),
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
fn trace_ids(traces : Array[@traces.Trace]) -> Array[@traces.TraceId] {
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
  assert_true(
    [
      @traces.Event::memory_load(),
      @traces.Event::memory_store(),
      @traces.Event::register_read(),
      @traces.Event::register_write(),
      @traces.Event::timestamp(),
      @traces.Event::pc_update(),
      @traces.Event::code_exec(),
      @traces.Event::context_switch(),
      @traces.Event::syscall(),
      @traces.Event::exn(),
      @traces.Event::call(),
      @traces.Event::return_(),
      @traces.Event::modload(),
      @traces.Event::mode(),
    ] ==
    @traces.TraceEvent::common_tags(),
  )
  let expected_uuids = [
    "9546a981-de85-4e5c-8d59-73a15bf5c7bd", "d5995d83-76be-410d-94a9-b0cfcb91f2de",
    "ded5dc91-dafc-4316-9c6c-4dad4e40a273", "395f5f37-5aed-4bd2-a51f-1c7216b5cd7c",
    "0feea5c2-b471-48e4-a10f-c7e18cbf21a9", "98ea397e-d726-43be-9ec5-bf226d67578f",
    "b8b3af3a-d1aa-4bf0-a36f-4ea6d0dd2bbf", "7f1d322a-d2cc-4e42-8e7a-081080751268",
    "6e0eec5c-2907-4c4c-b9b1-b879d2cbc69b", "18ae62d6-aa66-429b-964c-e15b7913d57e",
    "fe9899fe-3b60-4d10-bb50-dbccfc4ee0da", "2cae388a-69cb-48a0-8355-d3f9d39ac8eb",
    "7f842d03-6c9f-4745-af39-002f468f7fc8", "f7ba0979-c3a9-4509-ba14-01faf577d478",
  ]
  let tag_infos = @traces.TraceEvent::common_tag_infos()
  assert_true(
    [ for info in tag_infos => info.name ] == @traces.TraceEvent::common_tags(),
  )
  assert_true([ for info in tag_infos => info.uuid ] == expected_uuids)
  assert_true(@traces.TraceEvent::memory_load_uuid() == expected_uuids[0])
  assert_true(@traces.TraceEvent::mode_uuid() == expected_uuids[13])
  assert_true(
    @traces.TraceEvent::tag_info_for_name("memory-load") == Some(tag_infos[0]),
  )
  assert_true(@traces.TraceEvent::tag_info_for_name("missing") == None)
  assert_true(
    @traces.TraceEvent::tag_info_for_uuid(expected_uuids[0].to_upper()) ==
    Some(tag_infos[0]),
  )
  assert_true(@traces.TraceEvent::tag_info_for_uuid("not-a-uuid") == None)
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
  assert_true(
    [
      for event in events => event.tag_uuid()
    ] ==
    [expected_uuids[0], expected_uuids[1], expected_uuids[2], expected_uuids[3]],
  )
  assert_true(events[0].tag_info() == tag_infos[0])
  assert_true(events[0].memory_load_value() == Some(test_move()))
  assert_true(events[1].memory_store_value() == Some(test_move()))
  assert_true(events[2].register_read_value() == Some(register_move()))
  assert_true(events[3].register_write_value() == Some(register_move()))
  assert_true(events[0].register_read_value() == None)
  assert_true(events[0].to_string() == "0xBED:32u => 0xC0FFEE:32u")
  assert_true(events[1].to_string() == "0xBED:32u <= 0xC0FFEE:32u")
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
    broad[4].syscall_value() ==
    Some(@traces.Syscall::create(number=60, args=[word32(0)])),
  )
  assert_true(
    broad[5].exn_value() ==
    Some(@traces.Exn::create(number=13, src=Some(word32(1)))),
  )
  let expected_caller = @traces.Location::create(
    name=Some("main"),
    addr=word32(0x401000),
  )
  let expected_callee = @traces.Location::create(addr=word32(0x402000))
  assert_true(
    broad[6].call_value() ==
    Some(
      @traces.Call::create(caller=expected_caller, callee=expected_callee, args=[
        word32(1),
        word32(2),
      ]),
    ),
  )
  assert_true(
    broad[7].return_value() ==
    Some(@traces.Return::create(caller="main", callee="callee")),
  )
  assert_true(
    @traces.TraceEvent::return_(
      @traces.Return::create(caller="main", callee="callee"),
    ) ==
    broad[7],
  )
  assert_true(
    broad[8].modload_value() ==
    Some(
      @traces.Modload::create(
        name="libc.so",
        low=word32(0x1000),
        high=word32(0x1fff),
      ),
    ),
  )
  assert_true(broad[9].mode_value() == Some("thumb"))
  assert_true(broad[0].to_string() == "timestamp: -42")
  assert_true(broad[1].to_string() == "pc-update: 0x401000:32u")
  assert_true(broad[2].to_string() == "@0x401000:32u: 90 CC")
  assert_true(broad[3].to_string() == "context-switch: -1")
  assert_true(broad[4].to_string() == "syscall[60](0:32u)")
  assert_true(broad[5].to_string() == "exn 13 from 1:32u")
  assert_true(
    @traces.Exn::to_string(@traces.Exn::create(number=13, src=Some(word32(1)))) ==
    "exn 13 from 1:32u",
  )
  assert_true(
    broad[6].to_string() == "main@ 0x401000:32u -> 0x402000:32u(1:32u, 2:32u)",
  )
  assert_true(broad[7].to_string() == "main <- callee")
  assert_true(broad[8].to_string() == "libc.so: 0x1000:32u - 0x1FFF:32u")
  assert_true(broad[9].to_string() == "mode: thumb")
}

///|
test "translated BAP trace modes expose Knowledge enum and program slot" {
  let unknown = @traces.TraceMode::unknown()
  assert_true(unknown.is_unknown())
  assert_true(unknown.name().show() == ":unknown")
  assert_true(@traces.TraceMode::members().contains(unknown))
  assert_true(@traces.Mode::unknown().equal(unknown))
  match @traces.TraceMode::declare_mode("unit-thumb", pkg="bap") {
    Ok(mode) => {
      assert_true(mode.name().show() == "bap:unit-thumb")
      assert_true(mode.to_string() == "bap:unit-thumb")
      assert_true(mode.hash() == mode.name().hash())
      assert_true(!mode.is_unknown())
      assert_true(@traces.TraceMode::members().contains(mode))
      match @traces.TraceMode::read("unit-thumb", pkg="bap") {
        Ok(read_mode) => assert_true(read_mode.equal(mode))
        Err(reason) => fail(reason)
      }
      match @traces.TraceMode::persistent().decode("bap:unit-thumb") {
        Ok(decoded) => assert_true(decoded.equal(mode))
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @traces.TraceMode::declare_mode("unit-thumb", pkg="bap") is Err(_),
  )
  assert_true(@traces.TraceMode::read("missing-mode", pkg="bap") is Err(_))
  match @traces.Mode::declare_("unit-mode-facade", pkg="bap") {
    Ok(mode) => {
      assert_true(mode.name().show() == "bap:unit-mode-facade")
      assert_true(@traces.Mode::members().contains(mode))
      match @traces.Mode::read("unit-mode-facade", pkg="bap") {
        Ok(read_mode) => assert_true(read_mode.equal(mode))
        Err(reason) => fail(reason)
      }
      match @traces.Mode::persistent().decode("bap:unit-mode-facade") {
        Ok(decoded) => assert_true(decoded.equal(mode))
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
  assert_true(@traces.Mode::read("missing-mode", pkg="bap") is Err(_))
  let domain = @traces.TraceMode::domain()
  assert_true(domain.name().show() == "enum")
  assert_true(domain.empty() == Some(unknown))
  assert_true(domain.is_empty(unknown))
  let mode_domain = @traces.Mode::domain()
  assert_true(mode_domain.name().show() == "enum")
  assert_true(mode_domain.empty() == Some(unknown))
  assert_true(mode_domain.is_empty(unknown))
  let slot = @traces.TraceMode::slot()
  assert_true(slot.owner().show() == "core:program")
  assert_true(slot.name().show() == "bap:mode")
  assert_true(slot.domain().empty() == Some(unknown))
  let mode_slot = @traces.Mode::slot()
  assert_true(mode_slot.owner().show() == "core:program")
  assert_true(mode_slot.name().show() == "bap:mode")
  assert_true(mode_slot.domain().empty() == Some(unknown))
  match slot.persistent() {
    Some(codec) =>
      match codec.decode(":unknown") {
        Ok(decoded) => assert_true(decoded.equal(unknown))
        Err(reason) => fail(reason)
      }
    None => fail("missing trace mode persistent codec")
  }
}

///|
test "translated BAP traces preserve ids tools metadata and in-memory save/load" {
  let first = new_trace()
  let second = new_trace()
  assert_true(first.id() != second.id())
  assert_true(first.id().to_string().length() == 36)
  assert_true(first.id().to_string().has_prefix("00000000-0000-4000-8000-"))
  assert_true(first.id().hash() == first.id().to_string().hash())
  assert_true(first.id().equal(first.id()))
  assert_true(!first.id().equal(second.id()))
  match @traces.TraceId::of_string(first.id().to_string()) {
    Ok(id) => assert_true(id == first.id())
    Err(_) => fail("expected trace id to parse")
  }
  match @traces.TraceId::of_string(first.id().to_string().to_upper()) {
    Ok(id) => assert_true(id == first.id())
    Err(_) => fail("expected uppercase trace id to parse")
  }
  assert_true(@traces.TraceId::of_string("not-a-uuid") is Err(_))
  assert_true(@traces.Id::to_string(first.id()) == first.id().to_string())
  assert_true(@traces.Id::hash(first.id()) == first.id().hash())
  assert_true(@traces.Id::equal(first.id(), first.id()))
  assert_true(!@traces.Id::equal(first.id(), second.id()))
  assert_true(@traces.Id::compare(first.id(), second.id()) < 0)
  assert_true(@traces.Id::fresh().to_string().length() == 36)
  match @traces.Id::create(first.id().to_string()) {
    Ok(id) => assert_true(id.equal(first.id()))
    Err(_) => fail("expected facade trace id create to parse")
  }
  match @traces.Id::of_string(first.id().to_string().to_upper()) {
    Ok(id) => assert_true(id.equal(first.id()))
    Err(_) => fail("expected facade trace id parse")
  }
  assert_true(@traces.Id::of_string("not-a-uuid") is Err(_))
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
  assert_true(@traces.Meta::tracer() == @traces.TraceMeta::tracer_key())
  assert_true(@traces.Meta::binary() == @traces.TraceMeta::binary_key())
  assert_true(@traces.Meta::arch() == @traces.TraceMeta::arch_key())
  assert_true(
    @traces.Meta::binary_file_stats() ==
    @traces.TraceMeta::binary_file_stats_key(),
  )
  assert_true(
    @traces.Meta::trace_stats() == @traces.TraceMeta::trace_stats_key(),
  )
  let expected_meta_uuids = [
    "6e36c74e-580c-4496-9bf6-32cc0a09ef04", "391bb6c3-2c93-4592-b292-43e8ec52e786",
    "4bffe6d7-c554-45ec-9fb3-102f18e8f390", "f7cde0f9-633d-4a9a-8e71-28fef521bee5",
    "c33eea1b-bca3-4cfe-91b5-52949e8f3c6b",
  ]
  let meta_infos = @traces.TraceMeta::common_tag_infos()
  assert_true(
    [
      for info in meta_infos => info.name
    ] ==
    ["tracer", "binary", "arch", "file-stats", "trace-stats"],
  )
  assert_true([ for info in meta_infos => info.uuid ] == expected_meta_uuids)
  assert_true(@traces.TraceMeta::binary_uuid() == expected_meta_uuids[1])
  assert_true(@traces.TraceMeta::trace_stats_uuid() == expected_meta_uuids[4])
  assert_true(
    @traces.TraceMeta::tag_info_for_name("binary") == Some(meta_infos[1]),
  )
  assert_true(@traces.TraceMeta::tag_info_for_name("missing") == None)
  assert_true(
    @traces.TraceMeta::tag_info_for_uuid(expected_meta_uuids[0].to_upper()) ==
    Some(meta_infos[0]),
  )
  assert_true(@traces.TraceMeta::tag_info_for_uuid("not-a-uuid") == None)
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
test "translated BAP trace metadata values render like source printers" {
  let binary = @traces.Binary::create(
    path="/bin/echo",
    args=["echo", "hello"],
    envp=["LANG=C", "TERM=dumb"],
    md5sum="d41d8cd98f00b204e9800998ecf8427e",
  )
  assert_true(
    binary.to_string() ==
    "binary {\n  path:   /bin/echo\n  md5sum: d41d8cd98f00b204e9800998ecf8427e\n  args:   echo hello\n  envp:\n  LANG=C\n  TERM=dumb\n}",
  )
  assert_true(@traces.Binary::to_string(binary) == binary.to_string())

  let tracer = @traces.Tracer::create(
    name="qemu-user",
    version="8.2",
    args=["-d", "exec"],
    envp=["TRACE=1"],
  )
  assert_true(
    tracer.to_string() ==
    "tracer {\n  name:    qemu-user\n  version: 8.2\n  args:    -d exec\n  envp:\n  TRACE=1\n}",
  )
  assert_true(@traces.Tracer::to_string(tracer) == tracer.to_string())

  let file_stats = @traces.File_stats::create(
    size=42,
    atime=0.0,
    mtime=86400.0,
    ctime=2678400.0,
  )
  assert_true(
    file_stats.to_string() ==
    "trace stats {\n  size: 42\n  atime: 00:00:00 01.00.1970 GMT\n  mtime: 00:00:00 02.00.1970 GMT\n  ctime: 00:00:00 01.01.1970 GMT\n}",
  )
  assert_true(
    @traces.File_stats::to_string(file_stats) == file_stats.to_string(),
  )

  let trace_stats = @traces.Trace_stats::create(
    user="me",
    host="host",
    time=4.5,
  )
  assert_true(
    trace_stats.to_string() ==
    "Trace created on host by me at 00:00:04 01.00.1970 GMT",
  )
  assert_true(
    @traces.Trace_stats::to_string(trace_stats) == trace_stats.to_string(),
  )
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
  let iter_ids : Array[@traces.TraceId] = []
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
test "BAP-style loaded trace facade delegates to the registry" {
  let first = new_trace()
  let second = new_trace()
  @traces.Traces::remove(first)
  @traces.Traces::remove(second)
  let before = @traces.Traces::to_list().length()
  @traces.Traces::add(second)
  @traces.Traces::add(first)
  @traces.Traces::add(first)

  let ids = trace_ids(@traces.Traces::to_list())
  assert_true(
    ids.filter(id => id == first.id() || id == second.id()) ==
    [first.id(), second.id()],
  )
  let iter_ids : Array[@traces.TraceId] = []
  @traces.Traces::iter().each(trace => {
    if trace.id() == first.id() || trace.id() == second.id() {
      iter_ids.push(trace.id())
    }
  })
  assert_true(iter_ids == [first.id(), second.id()])
  let enum_ids : Array[@traces.TraceId] = []
  @traces.Traces::enum_().each(trace => {
    if trace.id() == first.id() || trace.id() == second.id() {
      enum_ids.push(trace.id())
    }
  })
  assert_true(enum_ids == iter_ids)

  @traces.Traces::remove(first)
  @traces.Traces::remove(second)
  assert_true(@traces.Traces::to_list().length() == before)
}

///|
test "translated BAP trace protocol registry selects URI providers" {
  match @traces.Trace::load("unknown://trace") {
    Err(NoProvider("unknown://trace")) => ()
    _ => fail("expected no provider")
  }

  let custom_tool = @traces.Trace::register_tool(name="custom_tool", supported_tags=[
    "memory-load", "register-read",
  ])
  assert_true(custom_tool.name() == "custom_tool")
  assert_true(custom_tool.supported_tags() == ["memory-load", "register-read"])
  let custom_events = [
    Ok(@traces.TraceEvent::memory_load(test_move())),
    Ok(@traces.TraceEvent::register_read(register_move())),
  ]
  let custom_protocol = @traces.TraceProtocol::create(
    name="custom-provider",
    supported_tags=["memory-load"],
    probe=fn(uri) { uri.has_prefix("custom://") },
  )
  assert_true(
    @traces.Trace::register_proto(custom_protocol) == "custom-provider",
  )
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

  let stream_calls = Ref(0)
  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(
      name="stream-provider",
      supported_tags=["memory-load", "register-read"],
      probe=fn(uri) { uri.has_prefix("stream://") },
    ),
  )
  @traces.Trace::register_stream_reader("stream-provider", fn(uri) {
    if uri != "stream://trace" {
      Err(NoProvider(uri))
    } else {
      let index = Ref(0)
      Ok(
        @traces.Reader::create(
          custom_tool,
          fn() {
            stream_calls.val += 1
            if index.val >= custom_events.length() {
              None
            } else {
              let item = custom_events[index.val]
              index.val += 1
              Some(item)
            }
          },
          meta=test_meta(),
        ),
      )
    }
  })
  match @traces.Trace::load("stream://trace") {
    Ok(trace) => {
      assert_true(trace.protocol() == Some("stream-provider"))
      assert_true(trace.meta() == test_meta())
      assert_true(stream_calls.val == 0)
      match trace.next_event() {
        Ok(Some(MemoryLoad(value))) => assert_true(value == test_move())
        _ => fail("expected stream reader first event")
      }
      assert_true(stream_calls.val == 1)
      assert_true(
        unwrap_events(trace.read_events()) ==
        [@traces.TraceEvent::register_read(register_move())],
      )
      assert_true(stream_calls.val == custom_events.length() + 1)
    }
    Err(_) => fail("stream provider load failed")
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
test "translated BAP trace readers receive generated ids" {
  let custom_tool = @traces.TraceTool::register(name="id_tool", supported_tags=[
    "memory-load",
  ])
  let custom_events = [Ok(@traces.TraceEvent::memory_load(test_move()))]
  let seen_reader_id : Ref[@traces.TraceId?] = Ref(None)
  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(name="id-reader-provider", probe=fn(uri) {
      uri.has_prefix("id-reader://")
    }),
  )
  @traces.Trace::register_reader_with_id("id-reader-provider", fn(uri, id) {
    if uri != "id-reader://trace" {
      Err(NoProvider(uri))
    } else {
      seen_reader_id.val = Some(id)
      Ok({ tool: custom_tool, meta: test_meta(), events: custom_events })
    }
  })
  match @traces.Trace::load("id-reader://trace") {
    Ok(trace) => {
      assert_true(seen_reader_id.val == Some(trace.id()))
      assert_true(trace.protocol() == Some("id-reader-provider"))
      assert_true(unwrap_events(trace.read_events()).length() == 1)
    }
    Err(_) => fail("id-aware reader load failed")
  }

  let seen_stream_id : Ref[@traces.TraceId?] = Ref(None)
  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(name="id-stream-provider", probe=fn(uri) {
      uri.has_prefix("id-stream://")
    }),
  )
  @traces.Trace::register_stream_reader_with_id("id-stream-provider", fn(
    uri,
    id,
  ) {
    if uri != "id-stream://trace" {
      Err(NoProvider(uri))
    } else {
      let index = Ref(0)
      seen_stream_id.val = Some(id)
      Ok(
        @traces.Reader::create(
          custom_tool,
          fn() {
            if index.val >= custom_events.length() {
              None
            } else {
              let item = custom_events[index.val]
              index.val += 1
              Some(item)
            }
          },
          meta=test_meta(),
        ),
      )
    }
  })
  match @traces.Trace::load("id-stream://trace") {
    Ok(trace) => {
      assert_true(seen_stream_id.val == Some(trace.id()))
      assert_true(trace.protocol() == Some("id-stream-provider"))
      assert_true(unwrap_events(trace.read_events()).length() == 1)
    }
    Err(_) => fail("id-aware stream reader load failed")
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
test "translated BAP trace filter maps compose and preserve context" {
  let expected_meta = test_meta().set("complete", Bool(true))
  let source = new_trace()
    .set_meta(test_meta())
    .set_attr("complete", Bool(true))
  match @traces.Trace::save("memory://bap-filter-map-context", source) {
    Ok(_) => ()
    Err(_) => fail("filter-map save failed")
  }

  match @traces.Trace::load("memory://bap-filter-map-context") {
    Ok(loaded) => {
      let loaded_id = loaded.id()
      let filtered = loaded
        .filter_map(fn(event) {
          match event {
            MemoryLoad(_) | MemoryStore(_) | RegisterRead(_) => Some(event)
            _ => None
          }
        })
        .filter_map(fn(event) {
          match event {
            MemoryStore(_) => Some(@traces.TraceEvent::mode("store"))
            RegisterRead(_) => Some(@traces.TraceEvent::mode("register"))
            _ => None
          }
        })
      assert_true(filtered.id() == loaded_id)
      assert_true(filtered.protocol() == Some("memory"))
      assert_true(filtered.tool() == test_tool())
      assert_true(filtered.meta() == expected_meta)
      assert_true(filtered.has_attr("complete"))
      assert_true(filtered.get_attr("complete") == Some(Bool(true)))
      assert_true(filtered.supports("memory-store"))
      assert_true(!filtered.supports("register-write"))
      assert_true(
        unwrap_events(filtered.read_events()) ==
        [
          @traces.TraceEvent::mode("store"),
          @traces.TraceEvent::mode("register"),
        ],
      )
    }
    Err(_) => fail("filter-map load failed")
  }
}

///|
test "translated BAP traces create from a lazy next callback" {
  let events = test_events()
  let index = Ref(0)
  let calls = Ref(0)
  let trace = @traces.Trace::create_stream(test_tool(), fn() {
    calls.val += 1
    if index.val >= events.length() {
      None
    } else {
      let event = events[index.val]
      index.val += 1
      Some(Ok(event))
    }
  })
  assert_true(calls.val == 0)
  match trace.next_event() {
    Ok(Some(MemoryLoad(value))) => assert_true(value == test_move())
    _ => fail("expected first lazy event")
  }
  assert_true(calls.val == 1)
  assert_true(
    unwrap_events(trace.read_events()) == [events[1], events[2], events[3]],
  )
  assert_true(calls.val == events.length() + 1)
  assert_true(unwrap_events(trace.read_events()) == [])
  assert_true(calls.val == events.length() + 1)
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

  let facade_failed = trace_with_monitor(@traces.Monitor::fail_on_error()).read_events()
  assert_true(facade_failed == Err(TraceFailure("syscall failed")))

  let facade_ignored = trace_with_monitor(@traces.Monitor::ignore_errors())
  assert_true(unwrap_events(facade_ignored.read_events()) == test_events())

  let facade_stopped = trace_with_monitor(@traces.Monitor::stop_on_error())
  assert_true(unwrap_events(facade_stopped.read_events()) == [])

  let facade_packed = trace_with_monitor(
    @traces.Monitor::pack_errors(fn(_) { packed_event }),
  )
  assert_true(
    unwrap_events(facade_packed.read_events()).length() ==
    test_events().length() + 1,
  )

  let facade_warnings = Ref(0)
  let facade_warned = trace_with_monitor(
    @traces.Monitor::warn_on_error(fn(_) { facade_warnings.val += 1 }),
  )
  assert_true(unwrap_events(facade_warned.read_events()) == test_events())
  assert_true(facade_warnings.val == 1)

  let facade_user = trace_with_monitor(@traces.Monitor::create(fn(_) { Skip }))
  assert_true(unwrap_events(facade_user.read_events()) == test_events())
}

///|
test "BAP-style trace load monitor controls provider stream errors" {
  let events = events_with_error()
  @traces.Trace::register_protocol(
    @traces.TraceProtocol::create(name="load-monitor-provider", probe=fn(uri) {
      uri.has_prefix("load-monitor://")
    }),
  )
  @traces.Trace::register_stream_reader("load-monitor-provider", fn(uri) {
    if uri == "load-monitor://trace" {
      Ok(@traces.Reader::from_results(test_tool(), events))
    } else {
      Err(NoProvider(uri))
    }
  })
  match @traces.Trace::load("load-monitor://trace") {
    Ok(trace) =>
      assert_true(trace.read_events() == Err(TraceFailure("syscall failed")))
    Err(_) => fail("default monitored load failed")
  }
  match
    @traces.Trace::load(
      "load-monitor://trace",
      monitor=@traces.TraceMonitor::ignore_errors(),
    ) {
    Ok(trace) =>
      assert_true(unwrap_events(trace.read_events()) == test_events())
    Err(_) => fail("ignore-error monitored load failed")
  }
}
