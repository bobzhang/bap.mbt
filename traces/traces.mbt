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
pub(all) struct TraceMode {
  name_value : @knowledge.Name
} derive(Eq, Debug)

///|
let trace_mode_members : Map[String, TraceMode] = {}

///|
fn trace_mode_domain_name() -> @knowledge.Name {
  @knowledge.Name::create("enum")
}

///|
fn trace_mode_slot_name() -> @knowledge.Name {
  @knowledge.Name::create("mode", pkg="bap")
}

///|
pub fn TraceMode::unknown() -> TraceMode {
  { name_value: @knowledge.Name::read(":unknown") }
}

///|
pub fn TraceMode::declare_mode(
  name : String,
  pkg? : String,
) -> Result[TraceMode, String] {
  let full_name = @knowledge.Name::create(name, pkg?)
  let key = full_name.show()
  if full_name.equal(TraceMode::unknown().name()) ||
    trace_mode_members.contains(key) {
    Err("trace mode \{key} is already declared")
  } else {
    let mode = { name_value: full_name }
    trace_mode_members[key] = mode
    Ok(mode)
  }
}

///|
pub fn TraceMode::read(
  name : String,
  pkg? : String,
) -> Result[TraceMode, String] {
  let full_name = @knowledge.Name::read(name, pkg?)
  if full_name.equal(TraceMode::unknown().name()) {
    Ok(TraceMode::unknown())
  } else {
    match trace_mode_members.get(full_name.show()) {
      Some(mode) => Ok(mode)
      None => Err("unknown trace mode \{full_name.show()}")
    }
  }
}

///|
pub fn TraceMode::name(self : TraceMode) -> @knowledge.Name {
  self.name_value
}

///|
pub fn TraceMode::to_string(self : TraceMode) -> String {
  self.name().show()
}

///|
pub fn TraceMode::hash(self : TraceMode) -> Int {
  self.name().hash()
}

///|
pub fn TraceMode::equal(self : TraceMode, other : TraceMode) -> Bool {
  self == other
}

///|
pub fn TraceMode::compare(self : TraceMode, other : TraceMode) -> Int {
  self.name().compare(other.name())
}

///|
pub fn TraceMode::is_unknown(self : TraceMode) -> Bool {
  self.equal(TraceMode::unknown())
}

///|
pub fn TraceMode::members() -> Array[TraceMode] {
  let values = [TraceMode::unknown()]
  for entry in trace_mode_members {
    values.push(entry.1)
  }
  values.sort_by((lhs, rhs) => lhs.compare(rhs))
  values
}

///|
pub fn TraceMode::domain() -> @knowledge.Domain[TraceMode] {
  @knowledge.Domain::flat(
    trace_mode_domain_name(),
    mode => mode.to_string(),
    empty=TraceMode::unknown(),
  )
}

///|
pub fn TraceMode::persistent() -> @knowledge.Persistent[TraceMode] {
  @knowledge.Persistent::convert(
    to_persistent=mode => mode.to_string(),
    of_persistent=text => TraceMode::read(text),
    @knowledge.Persistent::string(),
  )
}

///|
pub fn TraceMode::slot() -> @knowledge.Slot[Unit, TraceMode] {
  @core_theory.Program::cls().property(
    name=trace_mode_slot_name(),
    domain=TraceMode::domain(),
    desc="the CPU execution mode",
    persistent=TraceMode::persistent(),
    public=true,
  )
}

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
pub(all) struct TraceEventTagInfo {
  name : String
  uuid : String
} derive(Eq, Debug)

///|
let trace_event_memory_load_tag : String = "memory-load"

///|
let trace_event_memory_load_uuid : String = "9546a981-de85-4e5c-8d59-73a15bf5c7bd"

///|
let trace_event_memory_store_tag : String = "memory-store"

///|
let trace_event_memory_store_uuid : String = "d5995d83-76be-410d-94a9-b0cfcb91f2de"

///|
let trace_event_register_read_tag : String = "register-read"

///|
let trace_event_register_read_uuid : String = "ded5dc91-dafc-4316-9c6c-4dad4e40a273"

///|
let trace_event_register_write_tag : String = "register-write"

///|
let trace_event_register_write_uuid : String = "395f5f37-5aed-4bd2-a51f-1c7216b5cd7c"

///|
let trace_event_timestamp_tag : String = "timestamp"

///|
let trace_event_timestamp_uuid : String = "0feea5c2-b471-48e4-a10f-c7e18cbf21a9"

///|
let trace_event_pc_update_tag : String = "pc-update"

///|
let trace_event_pc_update_uuid : String = "98ea397e-d726-43be-9ec5-bf226d67578f"

///|
let trace_event_code_exec_tag : String = "code-exec"

///|
let trace_event_code_exec_uuid : String = "b8b3af3a-d1aa-4bf0-a36f-4ea6d0dd2bbf"

///|
let trace_event_context_switch_tag : String = "context-switch"

///|
let trace_event_context_switch_uuid : String = "7f1d322a-d2cc-4e42-8e7a-081080751268"

///|
let trace_event_syscall_tag : String = "syscall"

///|
let trace_event_syscall_uuid : String = "6e0eec5c-2907-4c4c-b9b1-b879d2cbc69b"

///|
let trace_event_exn_tag : String = "exn"

///|
let trace_event_exn_uuid : String = "18ae62d6-aa66-429b-964c-e15b7913d57e"

///|
let trace_event_call_tag : String = "call"

///|
let trace_event_call_uuid : String = "fe9899fe-3b60-4d10-bb50-dbccfc4ee0da"

///|
let trace_event_return_tag : String = "return"

///|
let trace_event_return_uuid : String = "2cae388a-69cb-48a0-8355-d3f9d39ac8eb"

///|
let trace_event_modload_tag : String = "modload"

///|
let trace_event_modload_uuid : String = "7f842d03-6c9f-4745-af39-002f468f7fc8"

///|
let trace_event_mode_tag : String = "mode"

///|
let trace_event_mode_uuid : String = "f7ba0979-c3a9-4509-ba14-01faf577d478"

///|
fn trace_event_tag_info(name : String, uuid : String) -> TraceEventTagInfo {
  { name, uuid }
}

///|
pub fn TraceEvent::memory_load_tag() -> String {
  trace_event_memory_load_tag
}

///|
pub fn TraceEvent::memory_load_uuid() -> String {
  trace_event_memory_load_uuid
}

///|
pub fn TraceEvent::memory_store_tag() -> String {
  trace_event_memory_store_tag
}

///|
pub fn TraceEvent::memory_store_uuid() -> String {
  trace_event_memory_store_uuid
}

///|
pub fn TraceEvent::register_read_tag() -> String {
  trace_event_register_read_tag
}

///|
pub fn TraceEvent::register_read_uuid() -> String {
  trace_event_register_read_uuid
}

///|
pub fn TraceEvent::register_write_tag() -> String {
  trace_event_register_write_tag
}

///|
pub fn TraceEvent::register_write_uuid() -> String {
  trace_event_register_write_uuid
}

///|
pub fn TraceEvent::timestamp_tag() -> String {
  trace_event_timestamp_tag
}

///|
pub fn TraceEvent::timestamp_uuid() -> String {
  trace_event_timestamp_uuid
}

///|
pub fn TraceEvent::pc_update_tag() -> String {
  trace_event_pc_update_tag
}

///|
pub fn TraceEvent::pc_update_uuid() -> String {
  trace_event_pc_update_uuid
}

///|
pub fn TraceEvent::code_exec_tag() -> String {
  trace_event_code_exec_tag
}

///|
pub fn TraceEvent::code_exec_uuid() -> String {
  trace_event_code_exec_uuid
}

///|
pub fn TraceEvent::context_switch_tag() -> String {
  trace_event_context_switch_tag
}

///|
pub fn TraceEvent::context_switch_uuid() -> String {
  trace_event_context_switch_uuid
}

///|
pub fn TraceEvent::syscall_tag() -> String {
  trace_event_syscall_tag
}

///|
pub fn TraceEvent::syscall_uuid() -> String {
  trace_event_syscall_uuid
}

///|
pub fn TraceEvent::exn_tag() -> String {
  trace_event_exn_tag
}

///|
pub fn TraceEvent::exn_uuid() -> String {
  trace_event_exn_uuid
}

///|
pub fn TraceEvent::call_tag() -> String {
  trace_event_call_tag
}

///|
pub fn TraceEvent::call_uuid() -> String {
  trace_event_call_uuid
}

///|
pub fn TraceEvent::return_tag() -> String {
  trace_event_return_tag
}

///|
pub fn TraceEvent::return_uuid() -> String {
  trace_event_return_uuid
}

///|
pub fn TraceEvent::modload_tag() -> String {
  trace_event_modload_tag
}

///|
pub fn TraceEvent::modload_uuid() -> String {
  trace_event_modload_uuid
}

///|
pub fn TraceEvent::mode_tag() -> String {
  trace_event_mode_tag
}

///|
pub fn TraceEvent::mode_uuid() -> String {
  trace_event_mode_uuid
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
pub fn TraceEvent::common_tag_infos() -> Array[TraceEventTagInfo] {
  [
    trace_event_tag_info(
      trace_event_memory_load_tag, trace_event_memory_load_uuid,
    ),
    trace_event_tag_info(
      trace_event_memory_store_tag, trace_event_memory_store_uuid,
    ),
    trace_event_tag_info(
      trace_event_register_read_tag, trace_event_register_read_uuid,
    ),
    trace_event_tag_info(
      trace_event_register_write_tag, trace_event_register_write_uuid,
    ),
    trace_event_tag_info(trace_event_timestamp_tag, trace_event_timestamp_uuid),
    trace_event_tag_info(trace_event_pc_update_tag, trace_event_pc_update_uuid),
    trace_event_tag_info(trace_event_code_exec_tag, trace_event_code_exec_uuid),
    trace_event_tag_info(
      trace_event_context_switch_tag, trace_event_context_switch_uuid,
    ),
    trace_event_tag_info(trace_event_syscall_tag, trace_event_syscall_uuid),
    trace_event_tag_info(trace_event_exn_tag, trace_event_exn_uuid),
    trace_event_tag_info(trace_event_call_tag, trace_event_call_uuid),
    trace_event_tag_info(trace_event_return_tag, trace_event_return_uuid),
    trace_event_tag_info(trace_event_modload_tag, trace_event_modload_uuid),
    trace_event_tag_info(trace_event_mode_tag, trace_event_mode_uuid),
  ]
}

///|
pub fn TraceEvent::tag_info_for_name(name : String) -> TraceEventTagInfo? {
  for info in TraceEvent::common_tag_infos() {
    if info.name == name {
      return Some(info)
    }
  }
  None
}

///|
pub fn TraceEvent::tag_info_for_uuid(uuid : String) -> TraceEventTagInfo? {
  let normalized = uuid.to_lower()
  for info in TraceEvent::common_tag_infos() {
    if info.uuid == normalized {
      return Some(info)
    }
  }
  None
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
pub fn TraceEvent::tag_info(self : TraceEvent) -> TraceEventTagInfo {
  match self {
    MemoryLoad(_) =>
      trace_event_tag_info(
        trace_event_memory_load_tag, trace_event_memory_load_uuid,
      )
    MemoryStore(_) =>
      trace_event_tag_info(
        trace_event_memory_store_tag, trace_event_memory_store_uuid,
      )
    RegisterRead(_) =>
      trace_event_tag_info(
        trace_event_register_read_tag, trace_event_register_read_uuid,
      )
    RegisterWrite(_) =>
      trace_event_tag_info(
        trace_event_register_write_tag, trace_event_register_write_uuid,
      )
    Timestamp(_) =>
      trace_event_tag_info(
        trace_event_timestamp_tag, trace_event_timestamp_uuid,
      )
    PcUpdate(_) =>
      trace_event_tag_info(
        trace_event_pc_update_tag, trace_event_pc_update_uuid,
      )
    CodeExec(_) =>
      trace_event_tag_info(
        trace_event_code_exec_tag, trace_event_code_exec_uuid,
      )
    ContextSwitch(_) =>
      trace_event_tag_info(
        trace_event_context_switch_tag, trace_event_context_switch_uuid,
      )
    Syscall(_) =>
      trace_event_tag_info(trace_event_syscall_tag, trace_event_syscall_uuid)
    Exception(_) =>
      trace_event_tag_info(trace_event_exn_tag, trace_event_exn_uuid)
    Call(_) => trace_event_tag_info(trace_event_call_tag, trace_event_call_uuid)
    Return(_) =>
      trace_event_tag_info(trace_event_return_tag, trace_event_return_uuid)
    Modload(_) =>
      trace_event_tag_info(trace_event_modload_tag, trace_event_modload_uuid)
    Mode(_) => trace_event_tag_info(trace_event_mode_tag, trace_event_mode_uuid)
  }
}

///|
pub fn TraceEvent::tag_uuid(self : TraceEvent) -> String {
  self.tag_info().uuid
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
pub fn TraceEvent::memory_load_value(self : TraceEvent) -> Move[@types.Word]? {
  match self {
    MemoryLoad(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::memory_store_value(self : TraceEvent) -> Move[@types.Word]? {
  match self {
    MemoryStore(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::register_read_value(self : TraceEvent) -> Move[@types.Var]? {
  match self {
    RegisterRead(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::register_write_value(self : TraceEvent) -> Move[@types.Var]? {
  match self {
    RegisterWrite(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::timestamp_value(self : TraceEvent) -> Int64? {
  match self {
    Timestamp(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::pc_update_value(self : TraceEvent) -> @types.Word? {
  match self {
    PcUpdate(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::code_exec_value(self : TraceEvent) -> Chunk? {
  match self {
    CodeExec(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::context_switch_value(self : TraceEvent) -> Int? {
  match self {
    ContextSwitch(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::syscall_value(self : TraceEvent) -> Syscall? {
  match self {
    Syscall(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::exn_value(self : TraceEvent) -> TraceException? {
  match self {
    Exception(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::call_value(self : TraceEvent) -> Call? {
  match self {
    Call(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::return_value(self : TraceEvent) -> Return? {
  match self {
    Return(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::modload_value(self : TraceEvent) -> Modload? {
  match self {
    Modload(value) => Some(value)
    _ => None
  }
}

///|
pub fn TraceEvent::mode_value(self : TraceEvent) -> String? {
  match self {
    Mode(value) => Some(value)
    _ => None
  }
}

///|
pub fn[T] Move::to_string(
  self : Move[T],
  cell_to_string : (T) -> String,
  arrow~ : String,
) -> String {
  "\{cell_to_string(self.cell)} \{arrow} \{self.data.to_string()}"
}

///|
fn trace_word_array_to_string(items : Array[@types.Word]) -> String {
  [ for item in items => item.to_string() ].join(", ")
}

///|
fn trace_bytes_to_hex(data : Bytes) -> String {
  let parts : Array[String] = []
  for byte in data {
    parts.push(byte.to_int().to_string(radix=16).to_upper().pad_start(2, '0'))
  }
  parts.join(" ")
}

///|
pub fn Chunk::to_string(self : Chunk) -> String {
  "@\{self.addr.to_string()}: \{trace_bytes_to_hex(self.data)}"
}

///|
pub fn Syscall::to_string(self : Syscall) -> String {
  "syscall[\{self.number}](\{trace_word_array_to_string(self.args)})"
}

///|
fn trace_optional_addr(prefix : String, value : @types.Word?) -> String {
  match value {
    Some(addr) => " \{prefix} \{addr.to_string()}"
    None => ""
  }
}

///|
pub fn TraceException::to_string(self : TraceException) -> String {
  "exn \{self.number}\{trace_optional_addr("from", self.src)}\{trace_optional_addr("to", self.dst)}"
}

///|
pub fn Location::to_string(self : Location) -> String {
  match self.name {
    Some(name) => "\{name}@ \{self.addr.to_string()}"
    None => self.addr.to_string()
  }
}

///|
pub fn Call::to_string(self : Call) -> String {
  "\{self.caller.to_string()} -> \{self.callee.to_string()}(\{trace_word_array_to_string(self.args)})"
}

///|
pub fn Return::to_string(self : Return) -> String {
  "\{self.caller} <- \{self.callee}"
}

///|
pub fn Modload::to_string(self : Modload) -> String {
  "\{self.name}: \{self.low.to_string()} - \{self.high.to_string()}"
}

///|
pub fn TraceEvent::to_string(self : TraceEvent) -> String {
  match self {
    MemoryLoad(value) => value.to_string(word => word.to_string(), arrow="=>")
    MemoryStore(value) => value.to_string(word => word.to_string(), arrow="<=")
    RegisterRead(value) =>
      value.to_string(variable => variable.to_string(), arrow="=>")
    RegisterWrite(value) =>
      value.to_string(variable => variable.to_string(), arrow="<=")
    Timestamp(value) => "timestamp: \{value}"
    PcUpdate(value) => "pc-update: \{value.to_string()}"
    CodeExec(value) => value.to_string()
    ContextSwitch(value) => "context-switch: \{value}"
    Syscall(value) => value.to_string()
    Exception(value) => value.to_string()
    Call(value) => value.to_string()
    Return(value) => value.to_string()
    Modload(value) => value.to_string()
    Mode(value) => "mode: \{value}"
  }
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
fn trace_pad2(value : Int) -> String {
  value.to_string().pad_start(2, '0')
}

///|
fn trace_pad4(value : Int) -> String {
  value.to_string().pad_start(4, '0')
}

///|
fn trace_time_floor_seconds(time : Double) -> Int {
  let mut seconds = time.to_int()
  if time < 0.0 && seconds.to_double() > time {
    seconds -= 1
  }
  seconds
}

///|
fn trace_leap_year(year : Int) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
fn trace_days_in_year(year : Int) -> Int {
  if trace_leap_year(year) {
    366
  } else {
    365
  }
}

///|
fn trace_days_in_month(year : Int, month : Int) -> Int {
  match month {
    0 | 2 | 4 | 6 | 7 | 9 | 11 => 31
    3 | 5 | 8 | 10 => 30
    1 => if trace_leap_year(year) { 29 } else { 28 }
    _ => 30
  }
}

///|
fn trace_time_to_string(time : Double) -> String {
  let seconds = trace_time_floor_seconds(time)
  let mut days = seconds / 86400
  let mut rem = seconds % 86400
  if rem < 0 {
    rem += 86400
    days -= 1
  }
  let hour = rem / 3600
  rem = rem % 3600
  let minute = rem / 60
  let second = rem % 60

  let mut year = 1970
  let mut day = days
  while day < 0 {
    year -= 1
    day += trace_days_in_year(year)
  }
  while day >= trace_days_in_year(year) {
    day -= trace_days_in_year(year)
    year += 1
  }
  let mut month = 0
  while day >= trace_days_in_month(year, month) {
    day -= trace_days_in_month(year, month)
    month += 1
  }
  // BAP prints Unix.tm_mon directly, so months are zero-based here.
  "\{trace_pad2(hour)}:\{trace_pad2(minute)}:\{trace_pad2(second)} \{trace_pad2(day + 1)}.\{trace_pad2(month)}.\{trace_pad4(year)} GMT"
}

///|
fn trace_args_to_string(args : Array[String]) -> String {
  args.join(" ")
}

///|
fn trace_envp_to_string(envp : Array[String]) -> String {
  [ for item in envp => "  " + item ].join("\n")
}

///|
pub fn TracerInfo::to_string(self : TracerInfo) -> String {
  "tracer {\n  name:    \{self.name}\n  version: \{self.version}\n  args:    \{trace_args_to_string(self.args)}\n  envp:\n\{trace_envp_to_string(self.envp)}\n}"
}

///|
pub fn BinaryInfo::to_string(self : BinaryInfo) -> String {
  "binary {\n  path:   \{self.path}\n  md5sum: \{self.md5sum}\n  args:   \{trace_args_to_string(self.args)}\n  envp:\n\{trace_envp_to_string(self.envp)}\n}"
}

///|
pub fn FileStatsInfo::to_string(self : FileStatsInfo) -> String {
  "trace stats {\n  size: \{self.size}\n  atime: \{trace_time_to_string(self.atime)}\n  mtime: \{trace_time_to_string(self.mtime)}\n  ctime: \{trace_time_to_string(self.ctime)}\n}"
}

///|
pub fn TraceStatsInfo::to_string(self : TraceStatsInfo) -> String {
  "Trace created on \{self.host} by \{self.user} at \{trace_time_to_string(self.time)}"
}

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
pub(all) struct TraceMetaTagInfo {
  name : String
  uuid : String
} derive(Eq, Debug)

///|
let trace_meta_binary_key : String = "binary"

///|
let trace_meta_binary_uuid : String = "391bb6c3-2c93-4592-b292-43e8ec52e786"

///|
let trace_meta_tracer_key : String = "tracer"

///|
let trace_meta_tracer_uuid : String = "6e36c74e-580c-4496-9bf6-32cc0a09ef04"

///|
let trace_meta_arch_key : String = "arch"

///|
let trace_meta_arch_uuid : String = "4bffe6d7-c554-45ec-9fb3-102f18e8f390"

///|
let trace_meta_binary_file_stats_key : String = "file-stats"

///|
let trace_meta_binary_file_stats_uuid : String = "f7cde0f9-633d-4a9a-8e71-28fef521bee5"

///|
let trace_meta_trace_stats_key : String = "trace-stats"

///|
let trace_meta_trace_stats_uuid : String = "c33eea1b-bca3-4cfe-91b5-52949e8f3c6b"

///|
fn trace_meta_tag_info(name : String, uuid : String) -> TraceMetaTagInfo {
  { name, uuid }
}

///|
pub fn TraceMeta::empty() -> TraceMeta {
  { attrs: {} }
}

///|
pub fn TraceMeta::binary_key() -> String {
  trace_meta_binary_key
}

///|
pub fn TraceMeta::binary_uuid() -> String {
  trace_meta_binary_uuid
}

///|
pub fn TraceMeta::tracer_key() -> String {
  trace_meta_tracer_key
}

///|
pub fn TraceMeta::tracer_uuid() -> String {
  trace_meta_tracer_uuid
}

///|
pub fn TraceMeta::arch_key() -> String {
  trace_meta_arch_key
}

///|
pub fn TraceMeta::arch_uuid() -> String {
  trace_meta_arch_uuid
}

///|
pub fn TraceMeta::binary_file_stats_key() -> String {
  trace_meta_binary_file_stats_key
}

///|
pub fn TraceMeta::binary_file_stats_uuid() -> String {
  trace_meta_binary_file_stats_uuid
}

///|
pub fn TraceMeta::trace_stats_key() -> String {
  trace_meta_trace_stats_key
}

///|
pub fn TraceMeta::trace_stats_uuid() -> String {
  trace_meta_trace_stats_uuid
}

///|
pub fn TraceMeta::common_tag_infos() -> Array[TraceMetaTagInfo] {
  [
    trace_meta_tag_info(trace_meta_tracer_key, trace_meta_tracer_uuid),
    trace_meta_tag_info(trace_meta_binary_key, trace_meta_binary_uuid),
    trace_meta_tag_info(trace_meta_arch_key, trace_meta_arch_uuid),
    trace_meta_tag_info(
      trace_meta_binary_file_stats_key, trace_meta_binary_file_stats_uuid,
    ),
    trace_meta_tag_info(trace_meta_trace_stats_key, trace_meta_trace_stats_uuid),
  ]
}

///|
pub fn TraceMeta::tag_info_for_name(name : String) -> TraceMetaTagInfo? {
  for info in TraceMeta::common_tag_infos() {
    if info.name == name {
      return Some(info)
    }
  }
  None
}

///|
pub fn TraceMeta::tag_info_for_uuid(uuid : String) -> TraceMetaTagInfo? {
  let normalized = uuid.to_lower()
  for info in TraceMeta::common_tag_infos() {
    if info.uuid == normalized {
      return Some(info)
    }
  }
  None
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
pub fn TraceTool::name(self : TraceTool) -> String {
  self.name
}

///|
pub fn TraceTool::supported_tags(self : TraceTool) -> Array[String] {
  let tags = self.supported_tags.to_array()
  tags.sort()
  tags
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
pub(all) struct TraceId {
  value : String
} derive(Eq, Hash, Debug)

///|
fn trace_id_is_hex_char(ch : Char) -> Bool {
  ('0' <= ch && ch <= '9') ||
  ('a' <= ch && ch <= 'f') ||
  ('A' <= ch && ch <= 'F')
}

///|
fn trace_id_is_uuid_text(value : String) -> Bool {
  if value.length() != 36 {
    false
  } else {
    let mut valid = true
    for index, ch in value {
      if index == 8 || index == 13 || index == 18 || index == 23 {
        if ch != '-' {
          valid = false
        }
      } else if !trace_id_is_hex_char(ch) {
        valid = false
      }
    }
    valid
  }
}

///|
fn trace_id_counter_tail(value : Int) -> String {
  let padded = value.to_string(radix=16).pad_start(12, '0')
  if padded.length() > 12 {
    padded[padded.length() - 12:].to_owned()
  } else {
    padded
  }
}

///|
fn trace_id_from_counter(value : Int) -> TraceId {
  { value: "00000000-0000-4000-8000-\{trace_id_counter_tail(value)}" }
}

///|
pub fn TraceId::create(value : String) -> Result[TraceId, String] {
  if trace_id_is_uuid_text(value) {
    Ok({ value: value.to_lower() })
  } else {
    Err("invalid trace UUID: \{value}")
  }
}

///|
pub fn TraceId::of_string(value : String) -> Result[TraceId, String] {
  TraceId::create(value)
}

///|
pub fn TraceId::fresh() -> TraceId {
  next_trace_uuid()
}

///|
pub fn TraceId::to_string(self : TraceId) -> String {
  self.value
}

///|
pub fn TraceId::compare(self : TraceId, other : TraceId) -> Int {
  self.value.compare(other.value)
}

///|
struct Trace {
  id_value : TraceId
  proto_name : String?
  tool_value : TraceTool
  meta_value : TraceMeta
  next_source : () -> Result[TraceEvent, String]?
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
pub(all) struct TraceStreamReader {
  tool : TraceTool
  meta : TraceMeta
  next : () -> Result[TraceEvent, String]?
}

///|
let trace_next_id : Ref[Int] = Ref(0)

///|
let trace_loaded_registry : Map[TraceId, Trace] = {}

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
let trace_reader_with_id_registry : Map[
  String,
  (String, TraceId) -> Result[TraceReader, TraceError],
] = {}

///|
let trace_stream_reader_registry : Map[
  String,
  (String) -> Result[TraceStreamReader, TraceError],
] = {}

///|
let trace_stream_reader_with_id_registry : Map[
  String,
  (String, TraceId) -> Result[TraceStreamReader, TraceError],
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
fn next_trace_uuid() -> TraceId {
  trace_id_from_counter(next_trace_id())
}

///|
fn trace_source_once(
  next : () -> Result[TraceEvent, String]?,
) -> () -> Result[TraceEvent, String]? {
  let done = Ref(false)
  fn() {
    if done.val {
      None
    } else {
      match next() {
        Some(item) => Some(item)
        None => {
          done.val = true
          None
        }
      }
    }
  }
}

///|
fn trace_array_source(
  events : Array[Result[TraceEvent, String]],
) -> () -> Result[TraceEvent, String]? {
  let source = events.copy()
  let cursor = Ref(0)
  trace_source_once(fn() {
    if cursor.val >= source.length() {
      None
    } else {
      let item = source[cursor.val]
      cursor.val += 1
      Some(item)
    }
  })
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
pub(all) struct Traces {}

///|
pub fn Traces::add(trace : Trace) -> Unit {
  Trace::add_loaded(trace)
}

///|
pub fn Traces::remove(trace : Trace) -> Unit {
  Trace::remove_loaded(trace)
}

///|
pub fn Traces::to_list() -> Array[Trace] {
  Trace::loaded()
}

///|
pub fn Traces::iter() -> Iter[Trace] {
  Trace::loaded_iter()
}

///|
pub fn Traces::enum_() -> Iter[Trace] {
  Traces::iter()
}

///|
pub fn Trace::register_protocol(protocol : TraceProtocol) -> Unit {
  trace_protocol_registry[protocol.name()] = protocol
}

///|
pub fn Trace::register_proto(protocol : TraceProtocol) -> String {
  Trace::register_protocol(protocol)
  protocol.name()
}

///|
pub fn Trace::register_tool(
  name~ : String,
  supported_tags~ : Array[String],
) -> TraceTool {
  TraceTool::register(name~, supported_tags~)
}

///|
pub fn Trace::register_reader(
  protocol_name : String,
  reader : (String) -> Result[TraceReader, TraceError],
) -> Unit {
  trace_reader_registry[protocol_name] = reader
}

///|
pub fn Trace::register_reader_with_id(
  protocol_name : String,
  reader : (String, TraceId) -> Result[TraceReader, TraceError],
) -> Unit {
  trace_reader_with_id_registry[protocol_name] = reader
}

///|
pub fn Trace::register_stream_reader(
  protocol_name : String,
  reader : (String) -> Result[TraceStreamReader, TraceError],
) -> Unit {
  trace_stream_reader_registry[protocol_name] = reader
}

///|
pub fn Trace::register_stream_reader_with_id(
  protocol_name : String,
  reader : (String, TraceId) -> Result[TraceStreamReader, TraceError],
) -> Unit {
  trace_stream_reader_with_id_registry[protocol_name] = reader
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
pub fn Trace::create_stream(
  tool : TraceTool,
  next : () -> Result[TraceEvent, String]?,
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  Trace::create_stream_with_id(TraceId::fresh(), tool, next, monitor~)
}

///|
fn Trace::create_stream_with_id(
  id : TraceId,
  tool : TraceTool,
  next : () -> Result[TraceEvent, String]?,
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  {
    id_value: id,
    proto_name: None,
    tool_value: tool,
    meta_value: TraceMeta::empty(),
    next_source: trace_source_once(next),
    monitor,
    mapper: event => Some(event),
  }
}

///|
pub fn Trace::from_results(
  tool : TraceTool,
  source : Array[Result[TraceEvent, String]],
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  Trace::create_stream(tool, trace_array_source(source), monitor~)
}

///|
fn Trace::from_results_with_id(
  id : TraceId,
  tool : TraceTool,
  source : Array[Result[TraceEvent, String]],
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Trace {
  Trace::create_stream_with_id(id, tool, trace_array_source(source), monitor~)
}

///|
pub fn TraceStreamReader::create(
  tool : TraceTool,
  next : () -> Result[TraceEvent, String]?,
  meta? : TraceMeta = TraceMeta::empty(),
) -> TraceStreamReader {
  { tool, meta, next: trace_source_once(next) }
}

///|
pub fn TraceStreamReader::from_results(
  tool : TraceTool,
  events : Array[Result[TraceEvent, String]],
  meta? : TraceMeta = TraceMeta::empty(),
) -> TraceStreamReader {
  TraceStreamReader::create(tool, trace_array_source(events), meta~)
}

///|
pub fn Trace::id(self : Trace) -> TraceId {
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
  while !done.val {
    if limit >= 0 && out.length() >= limit {
      done.val = true
    } else {
      match (self.next_source)() {
        Some(Ok(event)) =>
          match (self.mapper)(event) {
            Some(mapped) => out.push(mapped)
            None => ()
          }
        Some(Err(reason)) =>
          match (self.monitor.handle)(reason) {
            Stop => done.val = true
            Skip => ()
            Fail => return Err(TraceFailure(reason))
            Make(event) => out.push(event)
          }
        None => done.val = true
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
pub fn Trace::load(
  uri : String,
  monitor? : TraceMonitor = TraceMonitor::fail_on_error(),
) -> Result[Trace, TraceError] {
  match find_protocol(uri) {
    Ok(protocol) =>
      match trace_stream_reader_with_id_registry.get(protocol) {
        Some(reader) => {
          let trace_id = TraceId::fresh()
          match reader(uri, trace_id) {
            Ok(trace_reader) =>
              Ok({
                ..Trace::create_stream_with_id(
                  trace_id,
                  trace_reader.tool,
                  trace_reader.next,
                  monitor~,
                ).set_meta(trace_reader.meta),
                proto_name: Some(protocol),
              })
            Err(error) => Err(error)
          }
        }
        None =>
          match trace_stream_reader_registry.get(protocol) {
            Some(reader) =>
              match reader(uri) {
                Ok(trace_reader) =>
                  Ok({
                    ..Trace::create_stream(
                      trace_reader.tool,
                      trace_reader.next,
                      monitor~,
                    ).set_meta(trace_reader.meta),
                    proto_name: Some(protocol),
                  })
                Err(error) => Err(error)
              }
            None =>
              match trace_reader_with_id_registry.get(protocol) {
                Some(reader) => {
                  let trace_id = TraceId::fresh()
                  match reader(uri, trace_id) {
                    Ok(trace_reader) =>
                      Ok({
                        ..Trace::from_results_with_id(
                          trace_id,
                          trace_reader.tool,
                          trace_reader.events,
                          monitor~,
                        ).set_meta(trace_reader.meta),
                        proto_name: Some(protocol),
                      })
                    Err(error) => Err(error)
                  }
                }
                None =>
                  match trace_reader_registry.get(protocol) {
                    Some(reader) =>
                      match reader(uri) {
                        Ok(trace_reader) =>
                          Ok({
                            ..Trace::from_results(
                              trace_reader.tool,
                              trace_reader.events,
                              monitor~,
                            ).set_meta(trace_reader.meta),
                            proto_name: Some(protocol),
                          })
                        Err(error) => Err(error)
                      }
                    None => Err(NoProvider(uri))
                  }
              }
          }
      }
    Err(error) => Err(error)
  }
}
