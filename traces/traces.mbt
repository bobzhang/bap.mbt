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
pub fn TraceEvent::tag(self : TraceEvent) -> String {
  match self {
    MemoryLoad(_) => "memory-load"
    MemoryStore(_) => "memory-store"
    RegisterRead(_) => "register-read"
    RegisterWrite(_) => "register-write"
    Timestamp(_) => "timestamp"
    PcUpdate(_) => "pc-update"
    CodeExec(_) => "code-exec"
    ContextSwitch(_) => "context-switch"
    Syscall(_) => "syscall"
    Exception(_) => "exn"
    Call(_) => "call"
    Return(_) => "return"
    Modload(_) => "modload"
    Mode(_) => "mode"
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
pub(all) enum TraceAttrValue {
  Binary(BinaryInfo)
  Tracer(TracerInfo)
  Text(String)
  Int(Int)
  Bool(Bool)
} derive(Eq, Debug)

///|
pub(all) struct TraceMeta {
  attrs : Map[String, TraceAttrValue]
} derive(Eq, Debug)

///|
pub fn TraceMeta::empty() -> TraceMeta {
  { attrs: {} }
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
pub fn TraceMeta::get(self : TraceMeta, key : String) -> TraceAttrValue? {
  self.attrs.get(key)
}

///|
pub fn TraceMeta::has(self : TraceMeta, key : String) -> Bool {
  self.attrs.contains(key)
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
let trace_memory_provider_registered : Ref[Bool] = Ref(false)

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
fn ensure_memory_provider() -> Unit {
  if !trace_memory_provider_registered.val {
    let protocol = TraceProtocol::create(name="memory", probe=fn(uri) {
      uri.has_prefix("memory://")
    })
    Trace::register_protocol(protocol)
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
    trace_memory_provider_registered.val = true
  }
}

///|
fn protocols_of_uri(uri : String) -> Array[String] {
  ensure_memory_provider()
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
  select : (TraceEvent) -> T,
) -> Result[Array[T], TraceError] {
  self.read_events().map(events => events.map(select))
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
