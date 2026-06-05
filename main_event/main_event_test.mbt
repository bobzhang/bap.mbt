///|
test "main event stream sends log progress and custom events" {
  let observed : Array[@main_event.MainEvent] = []
  let id = @main_event.stream().subscribe(event => observed.push(event))
  @main_event.Log::message(MainLogInfo, section="loader", message="loaded")
  @main_event.Log::progress("decode", note="block", stage=1, total=3)
  @main_event.send(
    @main_event.MainEvent::custom(name="unit", payload="payload"),
  )
  @main_event.stream().unsubscribe(id)
  @main_event.message(MainLogWarning, section="loader", message="ignored")
  assert_true(observed.length() == 3)
  match observed[0] {
    MainLogMessage(info) => {
      assert_true(info.level() == MainLogInfo)
      assert_true(info.section() == "loader")
      assert_true(info.message() == "loaded")
      assert_true(observed[0].to_string() == "loader.info> loaded")
    }
    _ => fail("expected log message")
  }
  match observed[1] {
    MainLogProgress(progress) => {
      assert_true(progress.task() == "decode")
      assert_true(progress.note() == Some("block"))
      assert_true(progress.stage() == Some(1))
      assert_true(progress.total() == Some(3))
      assert_true(observed[1].to_string() == "progress.decode> [1/3] block")
    }
    _ => fail("expected progress event")
  }
  assert_true(observed[2].to_string() == "unit: payload")
  assert_true(@main_event.pp(observed[2]) == "unit: payload")
}

///|
test "main event printers use last registered precedence" {
  let custom = @main_event.MainEvent::custom(name="printer-test", payload="x")
  @main_event.register_printer(event => {
    match event {
      MainCustomEvent("printer-test", _) => Some("first")
      _ => None
    }
  })
  assert_true(custom.to_string() == "first")
  @main_event.register_printer(event => {
    match event {
      MainCustomEvent("printer-test", Some(payload)) => Some("last:" + payload)
      _ => None
    }
  })
  assert_true(custom.to_string() == "last:x")
  assert_true(@main_event.pp(custom) == "last:x")
  assert_true(
    @main_event.MainEvent::custom(name="other").to_string() == "other",
  )
}

///|
test "main log reporter emits level-specific messages and progress" {
  let events : Array[@main_event.MainEvent] = []
  let id = @main_event.stream().subscribe(event => events.push(event))
  let quiet = @main_event.Log::create(section="quiet")
  quiet.debug(message="hidden")
  quiet.info(message="ready")
  quiet.warning(message="careful")
  quiet.error(message="failed")
  quiet.report_progress(task="phase", note="parse", stage=2, total=4)
  let noisy = @main_event.Log::create(section="noisy", debug_enabled=true)
  noisy.debug(message="visible")
  @main_event.stream().unsubscribe(id)
  assert_true(events.length() == 5)
  assert_true(events[0].to_string() == "quiet.info> ready")
  assert_true(events[1].to_string() == "quiet.warning> careful")
  assert_true(events[2].to_string() == "quiet.error> failed")
  assert_true(events[3].to_string() == "progress.quiet/phase> [2/4] parse")
  assert_true(events[4].to_string() == "noisy.debug> visible")
}

///|
test "main event log processors filter messages and report errors" {
  let infos : Array[@main_event.MainLogInfo] = []
  let log_id = @main_event.observe_log_messages(notify=info => infos.push(info))
  let lines : Array[String] = []
  let errors : Array[String] = []
  let process_id = @main_event.process_log_events(
    write=line => lines.push(line),
    error=message => errors.push(message),
  )
  @main_event.send(@main_event.MainEvent::custom(name="ignored"))
  @main_event.progress("ignored-progress")
  @main_event.message(MainLogWarning, section="processor", message="careful")
  @main_event.message(MainLogError, section="processor", message="failed")
  @main_event.unsubscribe(log_id)
  @main_event.unsubscribe(process_id)
  @main_event.message(MainLogInfo, section="processor", message="after")
  assert_true(infos.length() == 2)
  assert_true(infos[0].to_string() == "processor.warning> careful")
  assert_true(infos[1].level() == MainLogError)
  assert_true(
    lines == ["processor.warning> careful", "processor.error> failed"],
  )
  assert_true(errors == ["failed"])
}
