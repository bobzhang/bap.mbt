///|
test "null pointer dereference of a static constant" {
  let x = reg("x")
  let p = reg("p")
  let mem = @types.Var::create("mem", Mem(addr_width=64, value_width=8))
  let body = @types.Blk::create(defs=[
    @types.Def::create(p, Int(w64(0))),
    @types.Def::create(
      x,
      @types.Exp::load(mem=Var(mem), addr=Var(p), LittleEndian, R8),
    ),
  ])
  let main = @types.Sub::create(name="main", blks=[body])
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
  let log : Array[String] = []
  let (status, _) = @primus.Machine::run(
    proj,
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_lisp.init_runtime(m)
      @constant_tracker.install_lisp_primitives(m)
      @constant_tracker.tracker_component(m)
      @primus_test.install_lisp(m)
      @primus_lisp.load_library(
        m,
        features=["core", "check-null-pointers"],
        loader=@primus_lisp.Loader::embedded(["lisp", "constant-tracker"]),
      )
      m.observe(@primus_test.incident, i => log.push("incident \{i.0}"))
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  log.push(status.to_string())
  debug_inspect(
    log,
    content=(
      #|[
      #|  "incident null-pointer-dereference",
      #|  "Exn(Segmentation fault at 0x0000000000000000)",
      #|]
    ),
  )
}
