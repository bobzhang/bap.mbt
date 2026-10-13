///|
fn visible(text : String) -> String {
  text.replace_all(old="\u{1b}", new="^")
}

///|
fn progress(
  task : String,
  note? : String,
  stage? : Int32,
  total? : Int32,
) -> @main_event.MainEvent {
  @main_event.MainEvent::progress(
    @main_event.MainProgress::create(task~, note?, stage?, total?),
  )
}

///|
test "time splitting" {
  debug_inspect(
    [0.0, 59.9, 61.0, 3725.0, 90061.0].map(@report.to_hms),
    content="[(0, 0, 0), (0, 0, 59), (0, 1, 1), (1, 2, 5), (1, 1, 1)]",
  )
}

///|
test "progress slots are rendered as ANSI lines" {
  let now = Ref(100.0)
  let frames = []
  let report = @report.ProgressReport::new(clock=() => now.val, write=s => {
    frames.push(visible(s))
  })
  report.update(progress("disasm", stage=0, total=4))
  now.val = 102.0
  report.update(progress("disasm/lift", note="main"))
  now.val = 3725.0 + 100.0
  report.update(progress("disasm", stage=1))
  report.update(@main_event.MainEvent::custom(name="other"))
  inspect(frames.length(), content="3")
  inspect(
    frames[0],
    content=(
      #|^[1m^[1;1H^[K[00:00:00]^[1;12Hdisasm:  25% (1/4)^[0m
      #|
    ),
  )
  inspect(
    frames[1],
    content=(
      #|^[1m^[1;1H^[K[00:00:02]^[1;12Hdisasm:  25% (1/4)^[0m
      #|^[1m^[2;1H^[K[00:00:00]^[2;13Hlift: ( | ) - main^[0m
      #|
    ),
  )
  inspect(
    frames[2],
    content=(
      #|^[1m^[1;1H^[K[01:02:05]^[1;12Hdisasm:  50% (2/4)^[0m
      #|^[2;1H^[K[00:00:00]^[2;13Hlift: done^[0m
      #|
    ),
  )
}

///|
test "stage-only and ping renderings" {
  let now = Ref(0.0)
  let report = @report.ProgressReport::new(clock=() => now.val, write=_ => ())
  report.update(progress("a", stage=2))
  report.update(progress("b"))
  now.val = 3.0
  report.update(progress("b"))
  inspect(
    visible(report.render()),
    content=(
      #|^[1;1H^[K[00:00:00]^[1;12Ha: ( 3 )^[0m
      #|^[1m^[2;1H^[K[00:00:03]^[2;12Hb: ( \ )^[0m
      #|
    ),
  )
}

///|
test "event printing" {
  debug_inspect(
    [
      @report.format_event(progress("t", note="n", stage=1, total=2)),
      @report.format_event(progress("t")),
      @report.format_event(@main_event.MainEvent::custom(name="x")),
    ],
    content=(
      #|[Some("t, n, 1, 2\n"), Some("t, , , \n"), None]
    ),
  )
  let lines = []
  let id = @report.print_events(write=s => lines.push(s))
  @main_event.progress("loading", stage=0)
  @main_event.unsubscribe(id)
  @main_event.progress("ignored")
  debug_inspect(
    lines,
    content=(
      #|["loading, , 0, \n"]
    ),
  )
}

///|
test "registration enables the renderer once" {
  let frames = []
  inspect(
    @report.register(progress=true, write=s => frames.push(visible(s)), clock=() => {
      0.0
    }),
    content="true",
  )
  inspect(@report.register(progress=true), content="false")
  @main_event.progress("task", stage=0, total=2)
  inspect(frames[0], content="^[2J^[1;1H")
  inspect(
    frames[frames.length() - 1],
    content=(
      #|^[1m^[1;1H^[K[00:00:00]^[1;12Htask:  50% (1/2)^[0m
      #|
    ),
  )
}
