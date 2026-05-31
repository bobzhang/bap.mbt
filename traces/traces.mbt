///|
pub(all) struct Move[T] {
  cell : T
  data : @types.Word
} derive(Eq, Debug)

///|
pub fn[T] Move::create(cell~ : T, data~ : @types.Word) -> Move[T] {
  { cell, data }
}

///|
pub(all) struct Chunk {
  addr : @types.Word
  data : Bytes
} derive(Eq, Debug)

///|
pub fn Chunk::create(addr~ : @types.Word, data~ : Bytes) -> Chunk {
  { addr, data }
}

///|
pub(all) struct Syscall {
  number : Int
  args : Array[@types.Word]
} derive(Eq, Debug)

///|
pub(all) struct TraceException {
  number : Int
  src : @types.Word?
  dst : @types.Word?
} derive(Eq, Debug)

///|
pub(all) struct Location {
  name : String?
  addr : @types.Word
} derive(Eq, Debug)

///|
pub fn Location::create(
  name? : String? = None,
  addr~ : @types.Word,
) -> Location {
  { name, addr }
}

///|
pub(all) struct Call {
  caller : Location
  callee : Location
  args : Array[@types.Word]
} derive(Eq, Debug)

///|
pub(all) struct Return {
  caller : String
  callee : String
} derive(Eq, Debug)

///|
pub(all) struct Modload {
  name : String
  low : @types.Word
  high : @types.Word
} derive(Eq, Debug)

///|
pub(all) enum TraceEvent {
  MemoryLoad(Move[@types.Word])
  MemoryStore(Move[@types.Word])
  RegisterRead(Move[@types.Var])
  RegisterWrite(Move[@types.Var])
  Timestamp(Int64)
  PcUpdate(@types.Word)
  CodeExec(Chunk)
  ContextSwitch(Int)
  Syscall(Syscall)
  Exception(TraceException)
  Call(Call)
  Return(Return)
  Modload(Modload)
  Mode(String)
} derive(Eq, Debug)

///|
let trace_event_memory_load_tag : String = "memory-load"

///|
let trace_event_memory_store_tag : String = "memory-store"

///|
let trace_event_register_read_tag : String = "register-read"

///|
let trace_event_register_write_tag : String = "register-write"

///|
let trace_event_timestamp_tag : String = "timestamp"

///|
let trace_event_pc_update_tag : String = "pc-update"

///|
let trace_event_code_exec_tag : String = "code-exec"

///|
let trace_event_context_switch_tag : String = "context-switch"

///|
let trace_event_syscall_tag : String = "syscall"

///|
let trace_event_exn_tag : String = "exn"

///|
let trace_event_call_tag : String = "call"

///|
let trace_event_return_tag : String = "return"

///|
let trace_event_modload_tag : String = "modload"

///|
let trace_event_mode_tag : String = "mode"

///|
pub fn TraceEvent::memory_load_tag() -> String {
  trace_event_memory_load_tag
}

///|
pub fn TraceEvent::memory_store_tag() -> String {
  trace_event_memory_store_tag
}

///|
pub fn TraceEvent::register_read_tag() -> String {
  trace_event_register_read_tag
}

///|
pub fn TraceEvent::register_write_tag() -> String {
  trace_event_register_write_tag
}

///|
pub fn TraceEvent::timestamp_tag() -> String {
  trace_event_timestamp_tag
}

///|
pub fn TraceEvent::pc_update_tag() -> String {
  trace_event_pc_update_tag
}

///|
pub fn TraceEvent::code_exec_tag() -> String {
  trace_event_code_exec_tag
}

///|
pub fn TraceEvent::context_switch_tag() -> String {
  trace_event_context_switch_tag
}

///|
pub fn TraceEvent::syscall_tag() -> String {
  trace_event_syscall_tag
}

///|
pub fn TraceEvent::exn_tag() -> String {
  trace_event_exn_tag
}

///|
pub fn TraceEvent::call_tag() -> String {
  trace_event_call_tag
}

///|
pub fn TraceEvent::return_tag() -> String {
  trace_event_return_tag
}

///|
pub fn TraceEvent::modload_tag() -> String {
  trace_event_modload_tag
}

///|
pub fn TraceEvent::mode_tag() -> String {
  trace_event_mode_tag
}

///|
pub fn TraceEvent::common_tags() -> Array[String] {
  [
    trace_event_memory_load_tag, trace_event_memory_store_tag, trace_event_register_read_tag,
    trace_event_register_write_tag, trace_event_timestamp_tag, trace_event_pc_update_tag,
    trace_event_code_exec_tag, trace_event_context_switch_tag, trace_event_syscall_tag,
    trace_event_exn_tag, trace_event_call_tag, trace_event_return_tag, trace_event_modload_tag,
    trace_event_mode_tag,
  ]
}

///|
pub fn TraceEvent::tag(self : TraceEvent) -> String {
  match self {
    MemoryLoad(_) => trace_event_memory_load_tag
    MemoryStore(_) => trace_event_memory_store_tag
    RegisterRead(_) => trace_event_register_read_tag
    RegisterWrite(_) => trace_event_register_write_tag
    Timestamp(_) => trace_event_timestamp_tag
    PcUpdate(_) => trace_event_pc_update_tag
    CodeExec(_) => trace_event_code_exec_tag
    ContextSwitch(_) => trace_event_context_switch_tag
    Syscall(_) => trace_event_syscall_tag
    Exception(_) => trace_event_exn_tag
    Call(_) => trace_event_call_tag
    Return(_) => trace_event_return_tag
    Modload(_) => trace_event_modload_tag
    Mode(_) => trace_event_mode_tag
  }
}

///|
pub fn TraceEvent::memory_load(value : Move[@types.Word]) -> TraceEvent {
  MemoryLoad(value)
}

///|
pub fn TraceEvent::memory_store(value : Move[@types.Word]) -> TraceEvent {
  MemoryStore(value)
}

///|
pub fn TraceEvent::register_read(value : Move[@types.Var]) -> TraceEvent {
  RegisterRead(value)
}

///|
pub fn TraceEvent::register_write(value : Move[@types.Var]) -> TraceEvent {
  RegisterWrite(value)
}

///|
pub fn TraceEvent::timestamp(value : Int64) -> TraceEvent {
  Timestamp(value)
}

///|
pub fn TraceEvent::pc_update(value : @types.Word) -> TraceEvent {
  PcUpdate(value)
}

///|
pub fn TraceEvent::code_exec(value : Chunk) -> TraceEvent {
  CodeExec(value)
}

///|
pub fn TraceEvent::context_switch(value : Int) -> TraceEvent {
  ContextSwitch(value)
}

///|
pub fn TraceEvent::syscall(value : Syscall) -> TraceEvent {
  Syscall(value)
}

///|
pub fn TraceEvent::exn(value : TraceException) -> TraceEvent {
  Exception(value)
}

///|
pub fn TraceEvent::call(value : Call) -> TraceEvent {
  Call(value)
}

///|
pub fn TraceEvent::return_event(value : Return) -> TraceEvent {
  Return(value)
}

///|
pub fn TraceEvent::modload(value : Modload) -> TraceEvent {
  Modload(value)
}

///|
pub fn TraceEvent::mode(value : String) -> TraceEvent {
  Mode(value)
}

///|
pub(all) struct BinaryInfo {
  path : String
  args : Array[String]
  envp : Array[String]
  md5sum : String
} derive(Eq, Debug)

///|
pub(all) struct TracerInfo {
  name : String
  args : Array[String]
  envp : Array[String]
  version : String
} derive(Eq, Debug)

///|
pub(all) struct FileStatsInfo {
  size : Int
  atime : Double
  mtime : Double
  ctime : Double
} derive(Eq, Debug)

///|
pub(all) struct TraceStatsInfo {
  user : String
  host : String
  time : Double
} derive(Eq, Debug)

///|
pub(all) enum TraceAttrValue {
  Binary(BinaryInfo)
  Tracer(TracerInfo)
  Arch(@types.Arch)
  FileStats(FileStatsInfo)
  TraceStats(TraceStatsInfo)
  Text(String)
  Int(Int)
  Bool(Bool)
} derive(Eq, Debug)

///|
pub(all) struct TraceMeta {
  attrs : Map[String, TraceAttrValue]
} derive(Eq, Debug)

///|
let trace_meta_binary_key : String = "binary"

///|
let trace_meta_tracer_key : String = "tracer"

///|
let trace_meta_arch_key : String = "arch"

///|
let trace_meta_binary_file_stats_key : String = "file-stats"

///|
let trace_meta_trace_stats_key : String = "trace-stats"

///|
pub fn TraceMeta::empty() -> TraceMeta {
  { attrs: {} }
}

///|
pub fn TraceMeta::binary_key() -> String {
  trace_meta_binary_key
}

///|
pub fn TraceMeta::tracer_key() -> String {
  trace_meta_tracer_key
}

///|
pub fn TraceMeta::arch_key() -> String {
  trace_meta_arch_key
}

///|
pub fn TraceMeta::binary_file_stats_key() -> String {
  trace_meta_binary_file_stats_key
}

///|
pub fn TraceMeta::trace_stats_key() -> String {
  trace_meta_trace_stats_key
}

///|
pub fn TraceMeta::set(
  self : TraceMeta,
  key : String,
  value : TraceAttrValue,
) -> TraceMeta {
  let attrs = self.attrs.copy()
  attrs[key] = value
  { attrs, }
}

///|
pub fn TraceMeta::remove(self : TraceMeta, key : String) -> TraceMeta {
  let attrs = self.attrs.copy()
  attrs.remove(key)
  { attrs, }
}

///|
pub fn TraceMeta::get(self : TraceMeta, key : String) -> TraceAttrValue? {
  self.attrs.get(key)
}

///|
pub fn TraceMeta::has(self : TraceMeta, key : String) -> Bool {
  self.attrs.contains(key)
}

///|
pub fn TraceMeta::is_empty(self : TraceMeta) -> Bool {
  self.attrs.is_empty()
}

///|
pub fn TraceMeta::length(self : TraceMeta) -> Int {
  self.attrs.length()
}

///|
pub fn TraceMeta::entries(self : TraceMeta) -> Array[(String, TraceAttrValue)] {
  let entries = []
  for entry in self.attrs {
    entries.push(entry)
  }
  entries.sort_by((left, right) => left.0.compare(right.0))
  entries
}

///|
pub fn TraceMeta::keys(self : TraceMeta) -> Array[String] {
  self.entries().map(entry => entry.0)
}

///|
pub fn TraceMeta::set_binary(self : TraceMeta, value : BinaryInfo) -> TraceMeta {
  self.set(trace_meta_binary_key, Binary(value))
}

///|
pub fn TraceMeta::binary(self : TraceMeta) -> BinaryInfo? {
  match self.get(trace_meta_binary_key) {
    Some(Binary(value)) => Some(value)
    _ => None
  }
}

///|
pub fn TraceMeta::set_tracer(self : TraceMeta, value : TracerInfo) -> TraceMeta {
  self.set(trace_meta_tracer_key, Tracer(value))
}

///|
pub fn TraceMeta::tracer(self : TraceMeta) -> TracerInfo? {
  match self.get(trace_meta_tracer_key) {
    Some(Tracer(value)) => Some(value)
    _ => None
  }
}

///|
pub fn TraceMeta::set_arch(self : TraceMeta, value : @types.Arch) -> TraceMeta {
  self.set(trace_meta_arch_key, Arch(value))
}

///|
pub fn TraceMeta::arch(self : TraceMeta) -> @types.Arch? {
  match self.get(trace_meta_arch_key) {
    Some(Arch(value)) => Some(value)
    _ => None
  }
}

///|
pub fn TraceMeta::set_binary_file_stats(
  self : TraceMeta,
  value : FileStatsInfo,
) -> TraceMeta {
  self.set(trace_meta_binary_file_stats_key, FileStats(value))
}

///|
pub fn TraceMeta::binary_file_stats(self : TraceMeta) -> FileStatsInfo? {
  match self.get(trace_meta_binary_file_stats_key) {
    Some(FileStats(value)) => Some(value)
    _ => None
  }
}

///|
pub fn TraceMeta::set_trace_stats(
  self : TraceMeta,
  value : TraceStatsInfo,
) -> TraceMeta {
  self.set(trace_meta_trace_stats_key, TraceStats(value))
}

///|
pub fn TraceMeta::trace_stats(self : TraceMeta) -> TraceStatsInfo? {
  match self.get(trace_meta_trace_stats_key) {
    Some(TraceStats(value)) => Some(value)
    _ => None
  }
}

///|
pub(all) struct TraceTool {
  name : String
  supported_tags : Set[String]
} derive(Eq, Debug)

///|
pub fn TraceTool::create(
  name~ : String,
  supported_tags~ : Array[String],
) -> TraceTool {
  { name, supported_tags: Set::from_array(supported_tags) }
}

///|
pub fn TraceTool::register(
  name~ : String,
  supported_tags~ : Array[String],
) -> TraceTool {
  TraceTool::create(name~, supported_tags~)
}

///|
pub fn TraceTool::supports(self : TraceTool, tag : String) -> Bool {
  self.supported_tags.contains(tag)
}

///|
struct TraceProtocol {
  name : String
  supported_tags : Set[String]
  probe_fn : (String) -> Bool
}

///|
pub fn TraceProtocol::create(
  name~ : String,
  supported_tags? : Array[String] = [],
  probe~ : (String) -> Bool,
) -> TraceProtocol {
  { name, supported_tags: Set::from_array(supported_tags), probe_fn: probe }
}

///|
pub fn TraceProtocol::name(self : TraceProtocol) -> String {
  self.name
}

///|
pub fn TraceProtocol::probe(self : TraceProtocol, uri : String) -> Bool {
  (self.probe_fn)(uri)
}

///|
pub fn TraceProtocol::supports(self : TraceProtocol, tag : String) -> Bool {
  self.supported_tags.is_empty() || self.supported_tags.contains(tag)
}

///|
pub(all) enum TraceStep {
  Stop
  Skip
  Fail
  Make(TraceEvent)
} derive(Eq, Debug)

///|
struct TraceMonitor {
  handle : (String) -> TraceStep
}

///|
pub fn TraceMonitor::ignore_errors() -> TraceMonitor {
  { handle: fn(_) { Skip } }
}

///|
pub fn TraceMonitor::stop_on_error() -> TraceMonitor {
  { handle: fn(_) { Stop } }
}

///|
pub fn TraceMonitor::fail_on_error() -> TraceMonitor {
  { handle: fn(_) { Fail } }
}

///|
pub fn TraceMonitor::pack_errors(pack : (String) -> TraceEvent) -> TraceMonitor {
  { handle: fn(reason) { Make(pack(reason)) } }
}

///|
pub fn TraceMonitor::warn_on_error(warn : (String) -> Unit) -> TraceMonitor {
  {
    handle: fn(reason) {
      warn(reason)
      Skip
    },
  }
}

///|
pub fn TraceMonitor::create(filter : (String) -> TraceStep) -> TraceMonitor {
  { handle: filter }
}

///|
pub(all) suberror TraceError {
  TraceFailure(String)
  NoProvider(String)
  AmbiguousUri(String)
  ProtocolError(String)
} derive(Eq, Debug)

///|
struct Trace {
  id_value : Int
  proto_name : String?
  tool_value : TraceTool
  meta_value : TraceMeta
  source : Array[Result[TraceEvent, String]]
  cursor : Ref[Int]
  monitor : TraceMonitor
  mapper : (TraceEvent) -> TraceEvent?
}

///|
priv struct TraceSnapshot {
  tool : TraceTool
  meta : TraceMeta
  events : Array[TraceEvent]
}

///|
pub(all) struct TraceReader {
  tool : TraceTool
  meta : TraceMeta
  events : Array[Result[TraceEvent, String]]
} derive(Eq, Debug)

///|
let trace_next_id : Ref[Int] = Ref(0)

///|
let trace_loaded_registry : Map[Int, Trace] = {}

///|
let trace_store : Map[String, Bytes] = {}

///|
let trace_protocol_registry : Map[String, TraceProtocol] = {}

///|
let trace_reader_registry : Map[
  String,
  (String) -> Result[TraceReader, TraceError],
] = {}

///|
let trace_writer_registry : Map[
  String,
  (String, Trace) -> Result[Unit, TraceError],
] = {}

///|
let trace_builtin_providers_registered : Ref[Bool] = Ref(false)

///|
let trace_file_uri_prefix : String = "file://"

///|
fn next_trace_id() -> Int {
  trace_next_id.val += 1
  trace_next_id.val
}

///|
pub fn Trace::add_loaded(trace : Trace) -> Unit {
  trace_loaded_registry[trace.id()] = trace
}

///|
pub fn Trace::remove_loaded(trace : Trace) -> Unit {
  trace_loaded_registry.remove(trace.id())
}

///|
pub fn Trace::loaded() -> Array[Trace] {
  let traces : Array[Trace] = []
  for entry in trace_loaded_registry {
    traces.push(entry.1)
  }
  traces.sort_by((left, right) => left.id().compare(right.id()))
  traces
}

///|
pub fn Trace::loaded_iter() -> Iter[Trace] {
  Trace::loaded().iter()
}

///|
pub fn Trace::register_protocol(protocol : TraceProtocol) -> Unit {
  trace_protocol_registry[protocol.name()] = protocol
}

///|
pub fn Trace::register_reader(
  protocol_name : String,
  reader : (String) -> Result[TraceReader, TraceError],
) -> Unit {
  trace_reader_registry[protocol_name] = reader
}

///|
pub fn Trace::register_writer(
  protocol_name : String,
  writer : (String, Trace) -> Result[Unit, TraceError],
) -> Unit {
  trace_writer_registry[protocol_name] = writer
}

///|
fn trace_file_uri_path(uri : String) -> String {
  uri[trace_file_uri_prefix.length():].to_owned()
}

///|
fn ensure_builtin_providers() -> Unit {
  if !trace_builtin_providers_registered.val {
    let memory_protocol = TraceProtocol::create(name="memory", probe=fn(uri) {
      uri.has_prefix("memory://")
    })
    Trace::register_protocol(memory_protocol)
    Trace::register_reader("memory", fn(uri) {
      match trace_store.get(uri) {
        Some(bytes) =>
          match trace_snapshot_from_bytes(bytes) {
            Ok(snapshot) => Ok(snapshot.to_reader())
            Err(error) => Err(error)
          }
        None => Err(NoProvider(uri))
      }
    })
    Trace::register_writer("memory", fn(uri, trace) {
      match trace.to_bytes() {
        Ok(bytes) => {
          trace_store[uri] = bytes
          Ok(())
        }
        Err(error) => Err(error)
      }
    })

    let binprot_protocol = TraceProtocol::create(name="trace.binprot", probe=fn(
      uri,
    ) {
      uri.has_prefix(trace_file_uri_prefix) && uri.has_suffix(".binprot")
    })
    Trace::register_protocol(binprot_protocol)
    Trace::register_reader("trace.binprot", fn(uri) {
      let path = trace_file_uri_path(uri)
      match @native_io.read_file(path) {
        Ok(bytes) =>
          match trace_snapshot_from_bytes(bytes) {
            Ok(snapshot) => Ok(snapshot.to_reader())
            Err(error) => Err(error)
          }
        Err(reason) => Err(ProtocolError(reason))
      }
    })
    Trace::register_writer("trace.binprot", fn(uri, trace) {
      let path = trace_file_uri_path(uri)
      match trace.to_bytes() {
        Ok(bytes) =>
          match @native_io.write_file(path, bytes) {
            Ok(_) => Ok(())
            Err(reason) => Err(ProtocolError(reason))
          }
        Err(error) => Err(error)
      }
    })
    trace_builtin_providers_registered.val = true
  }
}

///|
fn protocols_of_uri(uri : String) -> Array[String] {
  ensure_builtin_providers()
  let protocols : Array[String] = []
  for entry in trace_protocol_registry {
    let (name, protocol) = entry
    if protocol.probe(uri) {
      protocols.push(name)
    }
  }
  protocols
}

///|
fn find_protocol(uri : String) -> Result[String, TraceError] {
  match protocols_of_uri(uri) {
    [] => Err(NoProvider(uri))
    [protocol] => Ok(protocol)
    _ => Err(AmbiguousUri(uri))
  }
}

///|
pub fn Trace::create(
  tool : TraceTool,
  events? : Array[TraceEvent] = [],
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  Trace::from_results(tool, events.map(event => Ok(event)), monitor~)
}

///|
pub fn Trace::from_results(
  tool : TraceTool,
  source : Array[Result[TraceEvent, String]],
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  {
    id_value: next_trace_id(),
    proto_name: None,
    tool_value: tool,
    meta_value: TraceMeta::empty(),
    source: source.copy(),
    cursor: Ref(0),
    monitor,
    mapper: event => Some(event),
  }
}

///|
pub fn Trace::id(self : Trace) -> Int {
  self.id_value
}

///|
pub fn Trace::tool(self : Trace) -> TraceTool {
  self.tool_value
}

///|
pub fn Trace::protocol(self : Trace) -> String? {
  self.proto_name
}

///|
pub fn Trace::meta(self : Trace) -> TraceMeta {
  self.meta_value
}

///|
pub fn Trace::set_meta(self : Trace, meta : TraceMeta) -> Trace {
  { ..self, meta_value: meta }
}

///|
pub fn Trace::set_attr(
  self : Trace,
  key : String,
  value : TraceAttrValue,
) -> Trace {
  { ..self, meta_value: self.meta_value.set(key, value) }
}

///|
pub fn Trace::get_attr(self : Trace, key : String) -> TraceAttrValue? {
  self.meta_value.get(key)
}

///|
pub fn Trace::has_attr(self : Trace, key : String) -> Bool {
  self.meta_value.has(key)
}

///|
pub fn Trace::supports(self : Trace, tag : String) -> Bool {
  let protocol_supports = match self.proto_name {
    Some(name) =>
      match trace_protocol_registry.get(name) {
        Some(protocol) => protocol.supports(tag)
        None => true
      }
    None => true
  }
  self.tool_value.supports(tag) && protocol_supports
}

///|
pub fn Trace::filter_map(
  self : Trace,
  f : (TraceEvent) -> TraceEvent?,
) -> Trace {
  {
    ..self,
    mapper: fn(event) {
      match (self.mapper)(event) {
        Some(mapped) => f(mapped)
        None => None
      }
    },
  }
}

///|
pub fn Trace::next_event(self : Trace) -> Result[TraceEvent?, TraceError] {
  match self.read_events(limit=1) {
    Ok([event]) => Ok(Some(event))
    Ok(_) => Ok(None)
    Err(error) => Err(error)
  }
}

///|
pub fn Trace::next(
  self : Trace,
  tag : String,
) -> Result[TraceEvent?, TraceError] {
  self.next_matching(fn(event) {
    if event.tag() == tag {
      Some(event)
    } else {
      None
    }
  })
}

///|
pub fn[T] Trace::next_matching(
  self : Trace,
  select : (TraceEvent) -> T?,
) -> Result[T?, TraceError] {
  let done = Ref(false)
  let result : Ref[T?] = Ref(None)
  while !done.val {
    match self.next_event() {
      Ok(Some(event)) =>
        match select(event) {
          Some(value) => {
            result.val = Some(value)
            done.val = true
          }
          None => ()
        }
      Ok(None) => done.val = true
      Err(error) => return Err(error)
    }
  }
  Ok(result.val)
}

///|
pub fn Trace::read_events(
  self : Trace,
  limit? : Int = -1,
) -> Result[Array[TraceEvent], TraceError] {
  let out : Array[TraceEvent] = []
  let done = Ref(false)
  while !done.val && self.cursor.val < self.source.length() {
    if limit >= 0 && out.length() >= limit {
      done.val = true
    } else {
      let item = self.source[self.cursor.val]
      self.cursor.val += 1
      match item {
        Ok(event) =>
          match (self.mapper)(event) {
            Some(mapped) => out.push(mapped)
            None => ()
          }
        Err(reason) =>
          match (self.monitor.handle)(reason) {
            Stop => done.val = true
            Skip => ()
            Fail => return Err(TraceFailure(reason))
            Make(event) => out.push(event)
          }
      }
    }
  }
  Ok(out)
}

///|
pub fn Trace::read_all(
  self : Trace,
  tag : String,
) -> Result[Array[TraceEvent], TraceError] {
  self.read_events().map(events => events.filter(event => event.tag() == tag))
}

///|
pub fn[T] Trace::read_all_matching(
  self : Trace,
  select : (TraceEvent) -> T?,
) -> Result[Array[T], TraceError] {
  self.read_events().map(events => events.filter_map(select))
}

///|
pub fn Trace::save(uri : String, trace : Trace) -> Result[Unit, TraceError] {
  match find_protocol(uri) {
    Ok(protocol) =>
      match trace_writer_registry.get(protocol) {
        Some(writer) => writer(uri, trace)
        None => Err(NoProvider(uri))
      }
    Err(error) => Err(error)
  }
}

///|
pub fn Trace::load(uri : String) -> Result[Trace, TraceError] {
  match find_protocol(uri) {
    Ok(protocol) =>
      match trace_reader_registry.get(protocol) {
        Some(reader) =>
          match reader(uri) {
            Ok(trace_reader) =>
              Ok({
                ..Trace::from_results(trace_reader.tool, trace_reader.events).set_meta(
                  trace_reader.meta,
                ),
                proto_name: Some(protocol),
              })
            Err(error) => Err(error)
          }
        None => Err(NoProvider(uri))
      }
    Err(error) => Err(error)
  }
}
