///|
let trace_snapshot_magic : Bytes = b"BAPMBTTRACE\x01"

///|
priv struct TraceSnapshotInput {
  data : BytesView
  pos : Ref[Int32]
}

///|
fn TraceSnapshotInput::create(data : BytesView) -> TraceSnapshotInput {
  { data, pos: Ref(0), }
}

///|
fn trace_write_byte(out : Array[Byte], value : Int32) -> Unit {
  out.push((value & 0xff).to_byte())
}

///|
fn trace_write_bool(out : Array[Byte], value : Bool) -> Unit {
  trace_write_byte(out, if value { 1 } else { 0 })
}

///|
fn trace_write_i32(out : Array[Byte], value : Int32) -> Unit {
  for i in 0..<4 {
    trace_write_byte(out, value >> (i * 8))
  }
}

///|
fn trace_write_i64(out : Array[Byte], value : Int64) -> Unit {
  trace_write_u64(out, value.reinterpret_as_uint64())
}

///|
fn trace_write_u64(out : Array[Byte], bits : UInt64) -> Unit {
  for i in 0..<8 {
    out.push(((bits >> (i * 8)) & 0xffUL).to_int().to_byte())
  }
}

///|
fn trace_write_double(out : Array[Byte], value : Double) -> Unit {
  trace_write_u64(out, value.reinterpret_as_uint64())
}

///|
fn trace_write_raw(out : Array[Byte], bytes : BytesView) -> Unit {
  for byte in bytes {
    out.push(byte)
  }
}

///|
fn trace_write_bytes(out : Array[Byte], bytes : BytesView) -> Unit {
  trace_write_i32(out, bytes.length())
  trace_write_raw(out, bytes)
}

///|
fn trace_write_string(out : Array[Byte], text : String) -> Unit {
  trace_write_bytes(out, @utf8.encode(text))
}

///|
fn trace_write_string_option(out : Array[Byte], text : String?) -> Unit {
  match text {
    Some(value) => {
      trace_write_byte(out, 1)
      trace_write_string(out, value)
    }
    None => trace_write_byte(out, 0)
  }
}

///|
fn trace_write_string_array(out : Array[Byte], values : Array[String]) -> Unit {
  trace_write_i32(out, values.length())
  for value in values {
    trace_write_string(out, value)
  }
}

///|
fn trace_write_word(out : Array[Byte], value : @types.Word) -> Unit {
  trace_write_string(out, value.to_string())
}

///|
fn trace_write_word_option(out : Array[Byte], value : @types.Word?) -> Unit {
  match value {
    Some(word) => {
      trace_write_byte(out, 1)
      trace_write_word(out, word)
    }
    None => trace_write_byte(out, 0)
  }
}

///|
fn trace_write_word_array(
  out : Array[Byte],
  values : Array[@types.Word],
) -> Unit {
  trace_write_i32(out, values.length())
  for value in values {
    trace_write_word(out, value)
  }
}

///|
fn trace_write_value_type(out : Array[Byte], typ : @types.ValueType) -> Unit {
  match typ {
    Imm(width) => {
      trace_write_byte(out, 0)
      trace_write_i32(out, width)
    }
    Mem(addr_width~, value_width~) => {
      trace_write_byte(out, 1)
      trace_write_i32(out, addr_width)
      trace_write_i32(out, value_width)
    }
  }
}

///|
fn trace_write_var(out : Array[Byte], value : @types.Var) -> Unit {
  trace_write_string(out, value.name())
  trace_write_value_type(out, value.typ())
  trace_write_bool(out, value.is_virtual())
}

///|
fn[T] trace_write_move(
  out : Array[Byte],
  value : Move[T],
  write_cell : (Array[Byte], T) -> Unit,
) -> Unit {
  write_cell(out, value.cell)
  trace_write_word(out, value.data)
}

///|
fn trace_write_chunk(out : Array[Byte], value : Chunk) -> Unit {
  trace_write_word(out, value.addr)
  trace_write_bytes(out, value.data)
}

///|
fn trace_write_location(out : Array[Byte], value : Location) -> Unit {
  trace_write_string_option(out, value.name)
  trace_write_word(out, value.addr)
}

///|
fn trace_write_syscall(out : Array[Byte], value : Syscall) -> Unit {
  trace_write_i32(out, value.number)
  trace_write_word_array(out, value.args)
}

///|
fn trace_write_exception(out : Array[Byte], value : TraceException) -> Unit {
  trace_write_i32(out, value.number)
  trace_write_word_option(out, value.src)
  trace_write_word_option(out, value.dst)
}

///|
fn trace_write_call(out : Array[Byte], value : Call) -> Unit {
  trace_write_location(out, value.caller)
  trace_write_location(out, value.callee)
  trace_write_word_array(out, value.args)
}

///|
fn trace_write_return(out : Array[Byte], value : Return) -> Unit {
  trace_write_string(out, value.caller)
  trace_write_string(out, value.callee)
}

///|
fn trace_write_modload(out : Array[Byte], value : Modload) -> Unit {
  trace_write_string(out, value.name)
  trace_write_word(out, value.low)
  trace_write_word(out, value.high)
}

///|
fn trace_write_event(out : Array[Byte], event : TraceEvent) -> Unit {
  match event {
    MemoryLoad(value) => {
      trace_write_byte(out, 0)
      trace_write_move(out, value, trace_write_word)
    }
    MemoryStore(value) => {
      trace_write_byte(out, 1)
      trace_write_move(out, value, trace_write_word)
    }
    RegisterRead(value) => {
      trace_write_byte(out, 2)
      trace_write_move(out, value, trace_write_var)
    }
    RegisterWrite(value) => {
      trace_write_byte(out, 3)
      trace_write_move(out, value, trace_write_var)
    }
    Timestamp(value) => {
      trace_write_byte(out, 4)
      trace_write_i64(out, value)
    }
    PcUpdate(value) => {
      trace_write_byte(out, 5)
      trace_write_word(out, value)
    }
    CodeExec(value) => {
      trace_write_byte(out, 6)
      trace_write_chunk(out, value)
    }
    ContextSwitch(value) => {
      trace_write_byte(out, 7)
      trace_write_i32(out, value)
    }
    Syscall(value) => {
      trace_write_byte(out, 8)
      trace_write_syscall(out, value)
    }
    Exception(value) => {
      trace_write_byte(out, 9)
      trace_write_exception(out, value)
    }
    Call(value) => {
      trace_write_byte(out, 10)
      trace_write_call(out, value)
    }
    Return(value) => {
      trace_write_byte(out, 11)
      trace_write_return(out, value)
    }
    Modload(value) => {
      trace_write_byte(out, 12)
      trace_write_modload(out, value)
    }
    Mode(value) => {
      trace_write_byte(out, 13)
      trace_write_string(out, value)
    }
  }
}

///|
fn trace_write_attr_value(out : Array[Byte], value : TraceAttrValue) -> Unit {
  match value {
    Binary(info) => {
      trace_write_byte(out, 0)
      trace_write_string(out, info.path)
      trace_write_string_array(out, info.args)
      trace_write_string_array(out, info.envp)
      trace_write_string(out, info.md5sum)
    }
    Tracer(info) => {
      trace_write_byte(out, 1)
      trace_write_string(out, info.name)
      trace_write_string_array(out, info.args)
      trace_write_string_array(out, info.envp)
      trace_write_string(out, info.version)
    }
    Arch(arch) => {
      trace_write_byte(out, 2)
      trace_write_string(out, arch.to_string())
    }
    FileStats(info) => {
      trace_write_byte(out, 3)
      trace_write_i32(out, info.size)
      trace_write_double(out, info.atime)
      trace_write_double(out, info.mtime)
      trace_write_double(out, info.ctime)
    }
    TraceStats(info) => {
      trace_write_byte(out, 4)
      trace_write_string(out, info.user)
      trace_write_string(out, info.host)
      trace_write_double(out, info.time)
    }
    Text(text) => {
      trace_write_byte(out, 5)
      trace_write_string(out, text)
    }
    Int(value) => {
      trace_write_byte(out, 6)
      trace_write_i32(out, value)
    }
    Bool(value) => {
      trace_write_byte(out, 7)
      trace_write_bool(out, value)
    }
  }
}

///|
fn trace_write_meta(out : Array[Byte], meta : TraceMeta) -> Unit {
  let entries = meta.entries()
  trace_write_i32(out, entries.length())
  for entry in entries {
    trace_write_string(out, entry.0)
    trace_write_attr_value(out, entry.1)
  }
}

///|
fn trace_write_tool(out : Array[Byte], tool : TraceTool) -> Unit {
  trace_write_string(out, tool.name)
  let tags = tool.supported_tags.to_array()
  tags.sort_by((left, right) => left.compare(right))
  trace_write_string_array(out, tags)
}

///|
fn trace_encode_snapshot(snapshot : TraceSnapshot) -> Bytes {
  let out : Array[Byte] = []
  trace_write_raw(out, trace_snapshot_magic)
  trace_write_tool(out, snapshot.tool)
  trace_write_meta(out, snapshot.meta)
  trace_write_i32(out, snapshot.events.length())
  for event in snapshot.events {
    trace_write_event(out, event)
  }
  Bytes::from_array(out)
}

///|
fn TraceSnapshotInput::read_byte(
  self : TraceSnapshotInput,
) -> Int32 raise TraceError {
  if self.pos.val >= self.data.length() {
    raise ProtocolError("truncated trace snapshot")
  }
  let value = self.data[self.pos.val].to_int()
  self.pos.val += 1
  value
}

///|
fn TraceSnapshotInput::read_bool(
  self : TraceSnapshotInput,
) -> Bool raise TraceError {
  match self.read_byte() {
    0 => false
    1 => true
    value =>
      raise ProtocolError("invalid boolean tag in trace snapshot: \{value}")
  }
}

///|
fn TraceSnapshotInput::read_u32_bits(
  self : TraceSnapshotInput,
) -> UInt64 raise TraceError {
  let mut value = 0UL
  for i in 0..<4 {
    value = value | (self.read_byte().to_uint64() << (i * 8))
  }
  value
}

///|
fn TraceSnapshotInput::read_i32(
  self : TraceSnapshotInput,
) -> Int32 raise TraceError {
  self.read_u32_bits().to_int()
}

///|
fn TraceSnapshotInput::read_len(
  self : TraceSnapshotInput,
  what : String,
) -> Int32 raise TraceError {
  let value = self.read_u32_bits()
  if value > 0x7fffffffUL {
    raise ProtocolError("\{what} length is too large")
  }
  value.to_int()
}

///|
fn TraceSnapshotInput::read_i64(
  self : TraceSnapshotInput,
) -> Int64 raise TraceError {
  self.read_u64().reinterpret_as_int64()
}

///|
fn TraceSnapshotInput::read_u64(
  self : TraceSnapshotInput,
) -> UInt64 raise TraceError {
  let mut value = 0UL
  for i in 0..<8 {
    value = value | (self.read_byte().to_uint64() << (i * 8))
  }
  value
}

///|
fn TraceSnapshotInput::read_double(
  self : TraceSnapshotInput,
) -> Double raise TraceError {
  self.read_u64().reinterpret_as_double()
}

///|
fn TraceSnapshotInput::read_bytes(
  self : TraceSnapshotInput,
  what : String,
) -> Bytes raise TraceError {
  let len = self.read_len(what)
  let start = self.pos.val
  let stop = start + len
  if stop > self.data.length() {
    raise ProtocolError("truncated \{what} payload")
  }
  self.pos.val = stop
  self.data[start:stop].to_owned()
}

///|
fn TraceSnapshotInput::read_string(
  self : TraceSnapshotInput,
  what : String,
) -> String raise TraceError {
  let bytes = self.read_bytes(what)
  try @utf8.decode(bytes) catch {
    _ => raise ProtocolError("invalid UTF-8 in \{what}")
  } noraise {
    text => text
  }
}

///|
fn TraceSnapshotInput::read_string_option(
  self : TraceSnapshotInput,
  what : String,
) -> String? raise TraceError {
  match self.read_byte() {
    0 => None
    1 => Some(self.read_string(what))
    value =>
      raise ProtocolError("invalid optional string tag in \{what}: \{value}")
  }
}

///|
fn TraceSnapshotInput::read_word(
  self : TraceSnapshotInput,
) -> @types.Word raise TraceError {
  let text = self.read_string("word")
  try @types.Word::from_string(text) catch {
    _ => raise ProtocolError("invalid word in trace snapshot: \{text}")
  } noraise {
    word => word
  }
}

///|
fn TraceSnapshotInput::read_word_option(
  self : TraceSnapshotInput,
) -> @types.Word? raise TraceError {
  match self.read_byte() {
    0 => None
    1 => Some(self.read_word())
    value =>
      raise ProtocolError(
        "invalid optional word tag in trace snapshot: \{value}",
      )
  }
}

///|
fn TraceSnapshotInput::read_value_type(
  self : TraceSnapshotInput,
) -> @types.ValueType raise TraceError {
  match self.read_byte() {
    0 => Imm(self.read_i32())
    1 => Mem(addr_width=self.read_i32(), value_width=self.read_i32())
    value =>
      raise ProtocolError("unknown value type tag in trace snapshot: \{value}")
  }
}

///|
fn TraceSnapshotInput::read_var(
  self : TraceSnapshotInput,
) -> @types.Var raise TraceError {
  @types.Var::new(
    name=self.read_string("variable name"),
    typ=self.read_value_type(),
    is_virtual=self.read_bool(),
  )
}

///|
fn[T] TraceSnapshotInput::read_array(
  self : TraceSnapshotInput,
  what : String,
  read : (TraceSnapshotInput) -> T raise TraceError,
) -> Array[T] raise TraceError {
  let len = self.read_len(what)
  let values : Array[T] = []
  for _ in 0..<len {
    values.push(read(self))
  }
  values
}

///|
fn TraceSnapshotInput::read_string_array(
  self : TraceSnapshotInput,
  what : String,
) -> Array[String] raise TraceError {
  self.read_array(what, input => input.read_string(what))
}

///|
fn TraceSnapshotInput::read_word_array(
  self : TraceSnapshotInput,
  what : String,
) -> Array[@types.Word] raise TraceError {
  self.read_array(what, input => input.read_word())
}

///|
fn[T] TraceSnapshotInput::read_move(
  self : TraceSnapshotInput,
  read_cell : (TraceSnapshotInput) -> T raise TraceError,
) -> Move[T] raise TraceError {
  Move::create(cell=read_cell(self), data=self.read_word())
}

///|
fn TraceSnapshotInput::read_chunk(
  self : TraceSnapshotInput,
) -> Chunk raise TraceError {
  Chunk::create(addr=self.read_word(), data=self.read_bytes("code bytes"))
}

///|
fn TraceSnapshotInput::read_location(
  self : TraceSnapshotInput,
) -> Location raise TraceError {
  { name: self.read_string_option("location name"), addr: self.read_word(), }
}

///|
fn TraceSnapshotInput::read_syscall(
  self : TraceSnapshotInput,
) -> Syscall raise TraceError {
  { number: self.read_i32(), args: self.read_word_array("syscall args"), }
}

///|
fn TraceSnapshotInput::read_exception(
  self : TraceSnapshotInput,
) -> TraceException raise TraceError {
  {
    number: self.read_i32(),
    src: self.read_word_option(),
    dst: self.read_word_option(),
  }
}

///|
fn TraceSnapshotInput::read_call(
  self : TraceSnapshotInput,
) -> Call raise TraceError {
  {
    caller: self.read_location(),
    callee: self.read_location(),
    args: self.read_word_array("call args"),
  }
}

///|
fn TraceSnapshotInput::read_return(
  self : TraceSnapshotInput,
) -> Return raise TraceError {
  {
    caller: self.read_string("return caller"),
    callee: self.read_string("return callee"),
  }
}

///|
fn TraceSnapshotInput::read_modload(
  self : TraceSnapshotInput,
) -> Modload raise TraceError {
  {
    name: self.read_string("module name"),
    low: self.read_word(),
    high: self.read_word(),
  }
}

///|
fn TraceSnapshotInput::read_event(
  self : TraceSnapshotInput,
) -> TraceEvent raise TraceError {
  match self.read_byte() {
    0 => MemoryLoad(self.read_move(input => input.read_word()))
    1 => MemoryStore(self.read_move(input => input.read_word()))
    2 => RegisterRead(self.read_move(input => input.read_var()))
    3 => RegisterWrite(self.read_move(input => input.read_var()))
    4 => Timestamp(self.read_i64())
    5 => PcUpdate(self.read_word())
    6 => CodeExec(self.read_chunk())
    7 => ContextSwitch(self.read_i32())
    8 => Syscall(self.read_syscall())
    9 => Exception(self.read_exception())
    10 => Call(self.read_call())
    11 => Return(self.read_return())
    12 => Modload(self.read_modload())
    13 => Mode(self.read_string("mode"))
    value =>
      raise ProtocolError("unknown event tag in trace snapshot: \{value}")
  }
}

///|
fn TraceSnapshotInput::read_attr_value(
  self : TraceSnapshotInput,
) -> TraceAttrValue raise TraceError {
  match self.read_byte() {
    0 =>
      Binary({
        path: self.read_string("binary path"),
        args: self.read_string_array("binary args"),
        envp: self.read_string_array("binary envp"),
        md5sum: self.read_string("binary md5sum"),
      })
    1 =>
      Tracer({
        name: self.read_string("tracer name"),
        args: self.read_string_array("tracer args"),
        envp: self.read_string_array("tracer envp"),
        version: self.read_string("tracer version"),
      })
    2 => {
      let text = self.read_string("architecture")
      match @types.Arch::of_string(text) {
        Some(arch) => Arch(arch)
        None => raise ProtocolError("unknown trace architecture: \{text}")
      }
    }
    3 =>
      FileStats({
        size: self.read_i32(),
        atime: self.read_double(),
        mtime: self.read_double(),
        ctime: self.read_double(),
      })
    4 =>
      TraceStats({
        user: self.read_string("trace user"),
        host: self.read_string("trace host"),
        time: self.read_double(),
      })
    5 => Text(self.read_string("text attribute"))
    6 => Int(self.read_i32())
    7 => Bool(self.read_bool())
    value =>
      raise ProtocolError(
        "unknown metadata value tag in trace snapshot: \{value}",
      )
  }
}

///|
fn TraceSnapshotInput::read_meta(
  self : TraceSnapshotInput,
) -> TraceMeta raise TraceError {
  let len = self.read_len("metadata")
  let mut meta = TraceMeta::empty()
  for _ in 0..<len {
    let key = self.read_string("metadata key")
    meta = meta.set(key, self.read_attr_value())
  }
  meta
}

///|
fn TraceSnapshotInput::read_tool(
  self : TraceSnapshotInput,
) -> TraceTool raise TraceError {
  TraceTool::create(
    name=self.read_string("tool name"),
    supported_tags=self.read_string_array("tool supported tags"),
  )
}

///|
fn TraceSnapshotInput::read_magic(
  self : TraceSnapshotInput,
) -> Unit raise TraceError {
  for i in 0..<trace_snapshot_magic.length() {
    if self.read_byte() != trace_snapshot_magic[i].to_int() {
      raise ProtocolError("invalid trace snapshot header")
    }
  }
}

///|
fn TraceSnapshotInput::expect_eof(
  self : TraceSnapshotInput,
) -> Unit raise TraceError {
  if self.pos.val != self.data.length() {
    raise ProtocolError("trailing trace snapshot bytes")
  }
}

///|
fn trace_decode_snapshot(data : BytesView) -> TraceSnapshot raise TraceError {
  let input = TraceSnapshotInput::create(data)
  input.read_magic()
  let tool = input.read_tool()
  let meta = input.read_meta()
  let events = input.read_array("events", input => input.read_event())
  input.expect_eof()
  { tool, meta, events, }
}

///|
fn trace_snapshot_from_bytes(
  data : BytesView,
) -> Result[TraceSnapshot, TraceError] {
  try trace_decode_snapshot(data) catch {
    error => Err(error)
  } noraise {
    snapshot => Ok(snapshot)
  }
}

///|
fn TraceSnapshot::to_reader(self : TraceSnapshot) -> TraceReader {
  {
    tool: self.tool,
    meta: self.meta,
    events: self.events.map(event => Ok(event)),
  }
}

///|
pub fn Trace::to_bytes(self : Trace) -> Result[Bytes, TraceError] {
  match self.read_events() {
    Ok(events) =>
      Ok(
        trace_encode_snapshot({
          tool: self.tool_value,
          meta: self.meta_value,
          events,
        }),
      )
    Err(error) => Err(error)
  }
}

///|
pub fn Trace::of_bytes(data : BytesView) -> Result[Trace, TraceError] {
  match trace_snapshot_from_bytes(data) {
    Ok(snapshot) =>
      Ok(
        Trace::from_results(
          snapshot.tool,
          snapshot.events.map(event => Ok(event)),
        ).set_meta(snapshot.meta),
      )
    Err(error) => Err(error)
  }
}
