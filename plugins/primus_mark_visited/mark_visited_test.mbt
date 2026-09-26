///|
test "a system with the mark-visited and report-visited components" {
  assert_true(@primus_mark_visited.register())
  assert_false(@primus_mark_visited.register())
  let r = @types.Var::create("r", Imm(64))
  let b1 = @types.Blk::create(defs=[
    @types.Def::create(r, Int(try! @types.Word::of_int(width=64, 1))),
  ])
  let b2 = @types.Blk::create()
  let b0 = @types.Blk::create(jmps=[@types.Jmp::create_goto(Direct(b1.tid()))])
  let main = @types.Sub::create(name="main", blks=[b0, b1, b2])
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
  let sys = @primus.System::define_("mark-visited-test", components=[
    @primus.System::component("load-binary", pkg="bap"),
    @primus.System::component(@primus_track_visited.component_name, pkg="bap"),
    @primus.System::component(@primus_mark_visited.component_name, pkg="bap"),
  ])
  let events = []
  let id = @main_event.observe_log_messages(notify=_ => ())
  let (status, proj) = sys.run(
    proj,
    init=m => m.observe(@primus_track_visited.progress, p => events.push(p)),
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  @main_event.unsubscribe(id)
  inspect(status, content="Normal")
  debug_inspect(
    events,
    content=(
      #|[(1, 3), (2, 3)]
    ),
  )
  let marks = proj.program().subs()[0]
    .blks()
    .map(b => (b.is_visited(), b.is_dead()))
  debug_inspect(
    marks,
    content=(
      #|[(true, false), (true, false), (false, true)]
    ),
  )
}
