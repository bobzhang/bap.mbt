///|
pub(all) enum MainLogLevel {
  MainLogDebug
  MainLogInfo
  MainLogWarning
  MainLogError
} derive(Eq, Debug)

///|
pub extend MainLogLevel with Eq::{not_equal, equal}

///|
pub extend MainLogLevel with Debug::{to_repr}

///|
struct MainLogInfo {
  level_value : MainLogLevel
  section_value : String
  message_value : String
} derive(Eq, Debug)

///|
pub extend MainLogInfo with Eq::{not_equal, equal}

///|
pub extend MainLogInfo with Debug::{to_repr}

///|
struct MainProgress {
  task_value : String
  note_value : String?
  stage_value : Int32?
  total_value : Int32?
} derive(Eq, Debug)

///|
pub extend MainProgress with Eq::{not_equal, equal}

///|
pub extend MainProgress with Debug::{to_repr}

///|
pub(all) enum MainEvent {
  MainLogMessage(MainLogInfo)
  MainLogProgress(MainProgress)
  MainCustomEvent(String, String?)
} derive(Eq, Debug)

///|
pub extend MainEvent with Eq::{not_equal, equal}

///|
pub extend MainEvent with Debug::{to_repr}

///|
struct MainLogReporter {
  section_value : String
  debug_enabled_value : Bool
}

///|
pub(all) struct Log {}

///|
let main_event_pair : (@future.Stream[MainEvent], @future.Signal[MainEvent]) = @future.Stream::create()

///|
let main_event_printers : Array[(MainEvent) -> String?] = []

///|
let main_progress_last_total : Map[String, Int32] = Map([])

///|
fn main_progress_total(task : String, total : Int32?) -> Int32? {
  match total {
    Some(total) => {
      main_progress_last_total[task] = total
      Some(total)
    }
    None => main_progress_last_total.get(task)
  }
}

///|
pub fn stream() -> @future.Stream[MainEvent] {
  main_event_pair.0
}

///|
pub fn send(event : MainEvent) -> Unit {
  main_event_pair.1.send(event)
}

///|
pub fn register_printer(printer : (MainEvent) -> String?) -> Unit {
  main_event_printers.push(printer)
}

///|
pub fn MainLogLevel::to_string(self : MainLogLevel) -> String {
  match self {
    MainLogDebug => "debug"
    MainLogInfo => "info"
    MainLogWarning => "warning"
    MainLogError => "error"
  }
}

///|
pub fn MainLogInfo::create(
  level~ : MainLogLevel,
  section~ : String,
  message~ : String,
) -> MainLogInfo {
  { level_value: level, section_value: section, message_value: message, }
}

///|
pub fn MainLogInfo::level(self : MainLogInfo) -> MainLogLevel {
  self.level_value
}

///|
pub fn MainLogInfo::section(self : MainLogInfo) -> String {
  self.section_value
}

///|
pub fn MainLogInfo::message(self : MainLogInfo) -> String {
  self.message_value
}

///|
pub fn MainLogInfo::to_string(self : MainLogInfo) -> String {
  self.section() + "." + self.level().to_string() + "> " + self.message()
}

///|
pub fn MainProgress::create(
  task~ : String,
  note? : String,
  stage? : Int32,
  total? : Int32,
) -> MainProgress {
  {
    task_value: task,
    note_value: note,
    stage_value: stage,
    total_value: total,
  }
}

///|
pub fn MainProgress::task(self : MainProgress) -> String {
  self.task_value
}

///|
pub fn MainProgress::note(self : MainProgress) -> String? {
  self.note_value
}

///|
pub fn MainProgress::stage(self : MainProgress) -> Int32? {
  self.stage_value
}

///|
pub fn MainProgress::total(self : MainProgress) -> Int32? {
  self.total_value
}

///|
pub fn MainProgress::to_string(self : MainProgress) -> String {
  let note = match self.note() {
    Some(note) => " " + note
    None => ""
  }
  let stage = match (self.stage(), self.total()) {
    (Some(stage), Some(total)) =>
      " [" + stage.to_string() + "/" + total.to_string() + "]"
    (Some(stage), None) => " [" + stage.to_string() + "]"
    (None, Some(total)) => " [/" + total.to_string() + "]"
    (None, None) => ""
  }
  "progress." + self.task() + ">" + stage + note
}

///|
pub fn MainEvent::custom(name~ : String, payload? : String) -> MainEvent {
  MainCustomEvent(name, payload)
}

///|
pub fn MainEvent::log(info : MainLogInfo) -> MainEvent {
  MainLogMessage(info)
}

///|
pub fn MainEvent::progress(progress : MainProgress) -> MainEvent {
  MainLogProgress(progress)
}

///|
fn default_event_string(event : MainEvent) -> String {
  match event {
    MainLogMessage(info) => info.to_string()
    MainLogProgress(progress) => progress.to_string()
    MainCustomEvent(name, Some(payload)) => name + ": " + payload
    MainCustomEvent(name, None) => name
  }
}

///|
pub fn MainEvent::to_string(self : MainEvent) -> String {
  let len = main_event_printers.length()
  for offset in 0..<len {
    let printer = main_event_printers[len - offset - 1]
    match printer(self) {
      Some(text) => return text
      None => ()
    }
  }
  default_event_string(self)
}

///|
pub fn pp(event : MainEvent) -> String {
  event.to_string()
}

///|
pub fn observe_log_messages(notify~ : (MainLogInfo) -> Unit) -> Int32 {
  stream().subscribe(event => {
    match event {
      MainLogMessage(info) => notify(info)
      _ => ()
    }
  })
}

///|
pub fn process_log_events(
  write~ : (String) -> Unit,
  error? : (String) -> Unit,
) -> Int32 {
  observe_log_messages(notify=info => {
    write(info.to_string())
    if info.level() == MainLogError {
      match error {
        Some(error) => error(info.message())
        None => ()
      }
    }
  })
}

///|
pub fn process_events(
  write~ : (String) -> Unit,
  error? : (String) -> Unit,
) -> Int32 {
  process_log_events(write~, error?)
}

///|
pub fn unsubscribe(id : Int32) -> Unit {
  stream().unsubscribe(id)
}

///|
pub fn message(
  level : MainLogLevel,
  section~ : String,
  message~ : String,
) -> Unit {
  send(MainLogMessage(MainLogInfo::create(level~, section~, message~)))
}

///|
pub fn progress(
  task : String,
  note? : String,
  stage? : Int32,
  total? : Int32,
) -> Unit {
  let total = main_progress_total(task, total)
  send(MainLogProgress(MainProgress::create(task~, note?, stage?, total?)))
}

///|
pub fn Log::message(
  level : MainLogLevel,
  section~ : String,
  message~ : String,
) -> Unit {
  send(MainLogMessage(MainLogInfo::create(level~, section~, message~)))
}

///|
pub fn Log::progress(
  task : String,
  note? : String,
  stage? : Int32,
  total? : Int32,
) -> Unit {
  progress(task, note?, stage?, total?)
}

///|
pub fn Log::create(
  section~ : String,
  debug_enabled~ : Bool = false,
) -> MainLogReporter {
  MainLogReporter::create(section~, debug_enabled~)
}

///|
pub fn MainLogReporter::create(
  section~ : String,
  debug_enabled~ : Bool = false,
) -> MainLogReporter {
  { section_value: section, debug_enabled_value: debug_enabled, }
}

///|
pub fn MainLogReporter::section(self : MainLogReporter) -> String {
  self.section_value
}

///|
pub fn MainLogReporter::debug_enabled(self : MainLogReporter) -> Bool {
  self.debug_enabled_value
}

///|
pub fn MainLogReporter::message(
  self : MainLogReporter,
  level : MainLogLevel,
  message~ : String,
) -> Unit {
  send(
    MainLogMessage(
      MainLogInfo::create(level~, section=self.section_value, message~),
    ),
  )
}

///|
pub fn MainLogReporter::debug(
  self : MainLogReporter,
  message~ : String,
) -> Unit {
  if self.debug_enabled_value {
    self.message(MainLogDebug, message~)
  }
}

///|
pub fn MainLogReporter::info(self : MainLogReporter, message~ : String) -> Unit {
  self.message(MainLogInfo, message~)
}

///|
pub fn MainLogReporter::warning(
  self : MainLogReporter,
  message~ : String,
) -> Unit {
  self.message(MainLogWarning, message~)
}

///|
pub fn MainLogReporter::error(
  self : MainLogReporter,
  message~ : String,
) -> Unit {
  self.message(MainLogError, message~)
}

///|
pub fn MainLogReporter::report_progress(
  self : MainLogReporter,
  task? : String,
  note? : String,
  stage? : Int32,
  total? : Int32,
) -> Unit {
  let task = match task {
    Some(task) => self.section_value + "/" + task
    None => self.section_value
  }
  progress(task, note?, stage?, total?)
}
