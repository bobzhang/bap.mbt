///|
/// The plugin name.
pub let name : String = "report"

///|
let doc : String =
  #|reports program status using progress bars

///|
/// The state of a reported task (`slot`).
pub(all) struct ProgressSlot {
  note : String?
  stage : Int32?
  total : Int32?
  created : Double
  updated : Double
  active : Bool
} derive(Eq, Debug)

///|
pub extend ProgressSlot with Eq::{not_equal, equal}

///|
pub extend ProgressSlot with Debug::{to_repr}

///|
/// A progress bar renderer over the main event stream.
pub struct ProgressReport {
  tasks : Map[String, ProgressSlot]
  priv clock : () -> Double
  priv write : (String) -> Unit
  priv mut rendering : Bool
  priv mut last_tick : Double
}

///|
/// The interval, in seconds, between periodic re-renderings.
pub let interval : Int32 = 1

///|
let ping_frames = "|/-\\|/-\\"

///|
/// The wall clock in seconds.
pub fn wall_clock() -> Double {
  @env.now().to_double() / 1000.0
}

///|
fn default_write(text : String) -> Unit {
  println(text.trim_end(chars="\n"))
}

///|
/// Creates a renderer; `clock` returns the current time in seconds and
/// `write` receives the rendered (ANSI) text.
pub fn ProgressReport::new(
  clock~ : () -> Double = wall_clock,
  write~ : (String) -> Unit = default_write,
) -> ProgressReport {
  { tasks: Map([]), clock, write, rendering: false, last_tick: clock(), }
}

///|
fn duration(x : Double, y : Double) -> Int32 {
  (y - x).to_int()
}

///|
/// Splits a duration in seconds into hours, minutes, and seconds (`to_hms`).
pub fn to_hms(t : Double) -> (Int32, Int32, Int32) {
  let minute = 60.0
  let hour = 60.0 * minute
  let day = 24.0 * hour
  let secs = t.mod(minute)
  let mins = (t - secs).mod(hour)
  let hours = (t - mins).mod(day)
  ((hours / hour).to_int(), (mins / minute).to_int(), secs.to_int())
}

///|
fn pos(x : Int32, y : Int32) -> String {
  "\u{1b}[\{y};\{x}H"
}

///|
let ansi_clear = "\u{1b}[2J"

///|
let ansi_kill = "\u{1b}[K"

///|
let ansi_em = "\u{1b}[1m"

///|
let ansi_reset = "\u{1b}[0m"

///|
fn pad(n : Int32, width : Int32, fill : Char) -> String {
  let s = n.to_string()
  if s.length() >= width {
    s
  } else {
    String::make(width - s.length(), fill) + s
  }
}

///|
fn render_duration(sb : StringBuilder, line : Int32, d : Double) -> Unit {
  let (h, m, s) = to_hms(d)
  sb.write_string(pos(1, line + 1))
  sb.write_string(ansi_kill)
  sb.write_string("[\{pad(h, 2, '0')}:\{pad(m, 2, '0')}:\{pad(s, 2, '0')}]")
}

///|
fn ProgressReport::render_times(
  self : ProgressReport,
  sb : StringBuilder,
  line : Int32,
  slot : ProgressSlot,
) -> Unit {
  if slot.active {
    sb.write_string(ansi_em)
  }
  render_duration(
    sb,
    line,
    if slot.active {
      (self.clock)() - slot.created
    } else {
      slot.updated - slot.created
    },
  )
}

///|
fn render_percentbar(sb : StringBuilder, s : Int32, total : Int32) -> Unit {
  let percent = (s + 1) * 100 / total
  sb.write_string("\{pad(percent, 3, ' ')}% (\{s + 1}/\{total})")
}

///|
fn render_ping(sb : StringBuilder, slot : ProgressSlot) -> Unit {
  if slot.active {
    let frames = ping_frames.length()
    let i = (duration(slot.created, slot.updated) % frames + frames) % frames
    sb.write_string("( \{ping_frames.unsafe_get(i).unsafe_to_char()} )")
  } else {
    sb.write_string("done")
  }
}

///|
fn render_progress_bar(sb : StringBuilder, slot : ProgressSlot) -> Unit {
  match (slot.total, slot.stage) {
    (None | Some(0), Some(s)) => sb.write_string("( \{s + 1} )")
    // a zero total without a stage would divide by zero upstream
    (Some(t), None) if t != 0 => render_percentbar(sb, -1, t)
    (Some(t), Some(s)) => render_percentbar(sb, s, t)
    _ => render_ping(sb, slot)
  }
}

///|
fn ProgressReport::render_slot(
  self : ProgressReport,
  sb : StringBuilder,
  line : Int32,
  level : Int32,
  path : Array[String],
  slot : ProgressSlot,
) -> Unit {
  self.render_times(sb, line, slot)
  sb.write_string(pos(level + 12, line + 1))
  sb.write_string("\{path.get(level).unwrap_or("")}: ")
  render_progress_bar(sb, slot)
  match slot {
    { note: Some(n), active: true, .. } => sb.write_string(" - \{n}")
    _ => ()
  }
  sb.write_string(ansi_reset)
  sb.write_string("\n")
}

///|
/// Renders all tasks, one line per task sorted by name
/// (`do_render_progress`).
pub fn ProgressReport::render(self : ProgressReport) -> String {
  let names = self.tasks.keys().collect()
  names.sort_by(String::lexical_compare)
  let sb = StringBuilder()
  for line, task in names {
    let level = task.iter().filter(c => c == '/').count()
    let path = task.split("/").map(s => s.to_owned()).collect()
    match self.tasks.get(task) {
      Some(slot) => self.render_slot(sb, line, level, path, slot)
      None => ()
    }
  }
  sb.to_string()
}

///|
/// Writes the rendering unless a rendering is already in progress
/// (`render_progress`).
pub fn ProgressReport::render_progress(self : ProgressReport) -> Unit {
  if !self.rendering {
    self.rendering = true
    (self.write)(self.render())
    self.rendering = false
  }
}

///|
/// Updates the task slots with a progress event and re-renders
/// (`update_slots`); other events are ignored.
pub fn ProgressReport::update(
  self : ProgressReport,
  event : @main_event.MainEvent,
) -> Unit {
  guard event is MainLogProgress(progress) else { return }
  let task = progress.task()
  let note = progress.note()
  let stage = progress.stage()
  let total = progress.total()
  for key, slot in self.tasks {
    self.tasks[key] = { ..slot, active: false, }
  }
  let now = (self.clock)()
  self.tasks[task] = match self.tasks.get(task) {
    None => { note, stage, total, created: now, updated: now, active: true, }
    Some(slot) =>
      {
        ..slot,
        stage,
        note: first_some(note, slot.note),
        total: first_some(total, slot.total),
        updated: (self.clock)(),
        active: true,
      }
  }
  for key, slot in self.tasks {
    if task.has_prefix(key) && task != key {
      self.tasks[key] = { ..slot, updated: now, active: true, }
    }
  }
  self.render_progress()
}

///|
/// Re-renders when at least `interval` seconds passed since the last tick
/// (the sampled tick stream).
pub fn ProgressReport::tick(self : ProgressReport) -> Unit {
  let now = (self.clock)()
  if duration(self.last_tick, now) >= interval {
    self.last_tick = now
    self.render_progress()
  }
}

///|
/// Clears the screen and starts rendering progress events from the main
/// event stream (`enable`). Returns the subscription identifier.
pub fn ProgressReport::enable(self : ProgressReport) -> Int32 {
  (self.write)(ansi_clear + pos(1, 1))
  let id = @main_event.stream().subscribe(event => {
    self.update(event)
    self.tick()
  })
  self.render_progress()
  id
}

///|
/// Formats a progress event as `task, note, stage, total`.
pub fn format_event(event : @main_event.MainEvent) -> String? {
  match event {
    MainLogProgress(p) => {
      let opt = (x : String?) => x.unwrap_or("")
      let int = (x : Int32?) => x.map(n => n.to_string()).unwrap_or("")
      Some(
        "\{p.task()}, \{opt(p.note())}, \{int(p.stage())}, \{int(p.total())}\n",
      )
    }
    _ => None
  }
}

///|
/// Prints every progress event (`print_events`). Returns the subscription
/// identifier.
pub fn print_events(write~ : (String) -> Unit = default_write) -> Int32 {
  @main_event.stream().subscribe(event => {
    match format_event(event) {
      Some(text) => write(text)
      None => ()
    }
  })
}

///|
let registered : Ref[Bool] = Ref(false)

///|
/// Enables the progress bars and/or the event printer once. Returns `false`
/// if the plugin was already registered.
pub fn register(
  progress~ : Bool = false,
  events~ : Bool = false,
  write~ : (String) -> Unit = default_write,
  clock~ : () -> Double = wall_clock,
) -> Bool {
  if registered.val {
    return false
  }
  registered.val = true
  if progress {
    ignore(ProgressReport::new(clock~, write~).enable())
  }
  if events {
    ignore(print_events(write~))
  }
  true
}

///|
/// Declares the `report` plugin to `bap_main` with its `progress` and
/// `events` flags. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["report", "visualization"], doc~, () => {
    let progress = @bap_main.Configuration::flag(
      doc="Show progress bars",
      "progress",
    )
    let events = @bap_main.Configuration::flag(
      doc="Output progress events",
      "events",
    )
    @bap_main.Extension::register(ctxt => {
      ignore(register(progress=ctxt.get(progress), events=ctxt.get(events)))
    })
  })
}

///|
fn[T] first_some(x : T?, y : T?) -> T? {
  match x {
    Some(_) => x
    None => y
  }
}
