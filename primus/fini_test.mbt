///|
test "fini runs once even when it schedules frames" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project([]),
    start=_ => log.push("start"),
    fini=m => {
      log.push("fini \{m.current()}")
      m.schedule(_ => log.push("scheduled by fini"))
    },
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["start", "fini 0", "scheduled by fini"]
    ),
  )
}

///|
test "resumable system_fini and system_stop observers run once" {
  let log = []
  let sys = @primus.System::define_("fini-once-test", pkg="test")
  let (status, _) = sys.run(
    project([]),
    init=m => {
      ignore(
        m.subscribe_resumable(@primus.system_fini, (_, _) => {
          log.push("fini observer")
        }),
      )
      ignore(
        m.subscribe_resumable(@primus.system_stop, (_, s) => {
          log.push("stop observer \{s}")
        }),
      )
    },
    fini=_ => log.push("fini"),
  )
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["fini", "fini observer", "stop observer test:fini-once-test"]
    ),
  )
}

///|
test "fini runs once per machine after forks" {
  let log = []
  let (status, _) = @primus.Machine::run(project([]), start=m => m.fork(), fini=m => {
    log.push("fini \{m.current()}")
    if m.current() != @primus.Id::global() &&
      m.status(@primus.Id::global()) is Live {
      m.switch(@primus.Id::global())
    }
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|["fini 1", "fini 0"]
    ),
  )
}
