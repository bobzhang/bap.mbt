// End-to-end tests of the Lisp taint analysis: taint sources, sensitive
// sinks, incidents.

///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn stub(name : String, ret : Int32) -> @types.Term[@types.Sub] {
  let rdi = reg("RDI")
  let rax = reg("RAX")
  @types.Sub::create(
    name~,
    args=[
      @types.Arg::create(reg(name + "_arg"), Var(rdi), intent=In),
      @types.Arg::create(reg(name + "_ret"), Var(rax), intent=Out),
    ],
    blks=[@types.Blk::create(defs=[@types.Def::create(rax, Int(w64(ret)))])],
  )
}

///|
/// `main` calls `getenv(0x1000)` and passes the result to `system`.
fn getenv_system_program(
  sink : String,
) -> (@project.Project, Array[@types.Term[@types.Sub]]) {
  let rdi = reg("RDI")
  let rax = reg("RAX")
  let getenv = stub("getenv", 0x2000)
  let system = stub(sink, 0)
  let done = @types.Blk::create()
  let b1 = @types.Blk::create(defs=[@types.Def::create(rdi, Var(rax))], jmps=[
    @types.Jmp::create_call(
      @types.Call::create(
        target=Direct(system.tid()),
        return_label=Direct(done.tid()),
      ),
    ),
  ])
  let b0 = @types.Blk::create(
    defs=[@types.Def::create(rdi, Int(w64(0x1000)))],
    jmps=[
      @types.Jmp::create_call(
        @types.Call::create(
          target=Direct(getenv.tid()),
          return_label=Direct(b1.tid()),
        ),
      ),
    ],
  )
  let main = @types.Sub::create(name="main", blks=[b0, b1, done])
  let subs = [main, getenv, system]
  (
    @project.Project::empty(@core_theory.Target::x86_64()).with_program(
      @types.Program::create(subs~),
    ),
    subs,
  )
}

///|
fn store_string(m : @primus.Machine, addr : Int32, s : String) -> Unit raise {
  @primus.Memory::allocate(m, w64(addr), 64)
  for i, c in s {
    @primus.Memory::store(
      m,
      w64(addr + i),
      try! @types.Word::of_int(width=8, c.to_int()),
    )
  }
  @primus.Memory::store(
    m,
    w64(addr + s.length()),
    try! @types.Word::of_int(width=8, 0),
  )
}

///|
fn run_taint(sink : String) -> Array[String] {
  let (proj, _) = getenv_system_program(sink)
  let log : Array[String] = []
  let loader = @primus_lisp.Loader::embedded([
    "lisp", "site-lisp", "taint", "primus-test",
  ])
  let (status, _) = @primus.Machine::run(
    proj,
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_lisp.init_runtime(m)
      @primus_taint.install_lisp_primitives(m)
      @primus_taint.install_lisp_signals(m)
      @taint.propagate_by_computation(m)
      @primus_taint.policy_selector(@primus_taint.default_policy)(m)
      @primus_dictionary.install(m)
      @primus_test.record_locations(m)
      @primus_test.install_lisp(m)
      @primus_lisp.load_library(
        m,
        features=["core", "string", "taint-sources", "sensitive-sinks"],
        loader~,
      )
      store_string(m, 0x1000, "PATH")
      store_string(m, 0x2000, "rm -rf")
      m.observe(@primus_test.incident, i => log.push("incident \{i.0}"))
      m.observe(@primus_test.incident_new_class, i => {
        log.push("new class \{i.0} \{i.1}")
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
  )
  match status {
    Normal => ()
    Exn(e) => log.push("error: " + @primus.exn_to_string(e))
  }
  log
}

///|
test "untrusted getenv result reaches system" {
  debug_inspect(
    run_taint("system"),
    content=(
      #|[
      #|  "incident untrusted-argument",
      #|  "new class untrusted-argument 1",
      #|  "incident untrusted-argument",
      #|  "incident untrusted-argument",
      #|  "incident untrusted-argument",
      #|  "incident untrusted-argument",
      #|  "incident untrusted-argument",
      #|]
    ),
  )
  // the value flows to a function that is not a sensitive sink
  debug_inspect(
    run_taint("puts"),
    content=(
      #|[]
    ),
  )
}
